//	MIT License
//
//	Copyright (c) 2021 Antonino Ficarra
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//	SOFTWARE.

import Foundation

// -------------------------------------------------
// ----- GEncoderImpl
// -------------------------------------------------

final class GEncoderImpl : GEncoder, DataEncoderDelegate {
	var userInfo							= [String:Any]()
	private typealias	IdentifierMap		= AnyIdentifierMap
	
	private let 		encodeOptions		: GraphEncoder.Options
	private var 		currentKeys			= Set<String>()
	private var			identifierMap		= IdentifierMap()
	private var			referenceMap		= ReferenceMap()
	private var			keyMap				= KeyMap()
	private (set) var	dumpOptions			= GraphDumpOptions.readable
	private var			dataEncoder			: (any DataEncoder)! {
		willSet {
			self.dataEncoder?.delegate	= nil
		}
		didSet {
			self.currentKeys			= Set<String>()
			self.identifierMap			= IdentifierMap()
			self.referenceMap			= ReferenceMap()
			self.keyMap					= KeyMap()
			self.dataEncoder?.delegate	= self
		}
	}
	
	var classDataMap: ClassDataMap 	{ referenceMap.classDataMap }
	var keyStringMap: KeyStringMap 	{ keyMap.keyStringMap }

	init( _ options: GraphEncoder.Options ) {
		self.encodeOptions			= options
	}
	
	func encodeRoot<T,Q>( _ value: T ) throws -> Q where T:GEncodable, Q:MutableDataProtocol {
		defer { self.dataEncoder = nil }
		let dataEncoder	= BinEncoder<Q>()
		self.dataEncoder = dataEncoder
		try encode( value )
		return try dataEncoder.output()
	}
	
	func dumpRoot<T>( _ value: T, options: GraphDumpOptions ) throws -> String where T:GEncodable {
		defer { self.dataEncoder = nil }
		let dataEncoder	= StringEncoder()
		self.dataEncoder = dataEncoder
		self.dumpOptions = options
		try encode( value )
		return try dataEncoder.output()
	}
	
	// --------------------------------------------------------
	
	func encode<Value>(_ value: Value) throws where Value:GEncodable {
		try encodeAnyValue( value, forKey: nil, conditional:false )
	}

	func encodeConditional<Value>(_ value: Value?) throws where Value:GEncodable {
		try encodeAnyValue( value as Any, forKey: nil, conditional:true )
	}

	func encode<Key, Value>(_ value: Value, for key: Key) throws
	where Key : RawRepresentable, Value : GEncodable, Key.RawValue == String
	{
		try encodeAnyValue( value, forKey: key.rawValue, conditional:false )
	}

	func encodeConditional<Key, Value>(_ value: Value?, for key: Key) throws
	where Key : RawRepresentable, Value : GEncodable, Key.RawValue == String
	{
		try encodeAnyValue( value as Any, forKey: key.rawValue, conditional:true )
	}
	
	// --------------------------------------------------------
	private func binaryValue( of value:GEncodable ) -> (BinaryOType)? {
		if let value = value as? GBinaryEncodable { return value }
		else if encodeOptions.contains( .enableLibraryBinaryIOTypes ), let value = value as? BinaryOType { return value }
		else { return nil }
	}

	private func identifier( of value:GEncodable ) -> (any Hashable)? {
		if encodeOptions.contains( .disableIdentity ) {
			return nil
		}
		
		if encodeOptions.contains( .ignoreGIdentifiableProtocol ) {
			if	encodeOptions.contains( .disableAutoObjectIdentifierIdentityForReferences ) == false,
				let object = value as? (GEncodable & AnyObject) {
				return ObjectIdentifier( object )
			}
		} else {
			if let identifiable	= value as? any GIdentifiable {
				return identifiable.gcodableID
			} else if
				encodeOptions.contains( .disableAutoObjectIdentifierIdentityForReferences ) == false,
				let object = value as? (GEncodable & AnyObject) {
				return ObjectIdentifier( object )
			}
		}
		return nil
	}

	private func createTypeIDIfNeeded( for value:GEncodable ) throws -> UIntID? {
		if encodeOptions.contains( .disableClassNames ) {
			return nil
		}
		guard let object = value as? GEncodable & AnyObject else {
			return nil
		}
		if encodeOptions.contains( .ignoreGClassNameProtocol ) == false,
		   let typeInfo = object as? (AnyObject & GClassName),
		   typeInfo.disableClassName {
			return nil
		}
		return try referenceMap.createTypeIDIfNeeded( type: type(of:object) )
	}
	
	private func encodeAnyValue(_ anyValue: Any, forKey key: String?, conditional:Bool ) throws {
		//	anyValue cam really be a value, an Optional(value), an Optional(Optional(value)), etc…
		//	Optional(fullUnwrapping:_) turns anyValue into an one-level Optional(value)
		let value	= Optional(fullUnwrapping: anyValue)
		let keyID	= try createKeyID( key: key )
		
		guard let value = value else {
			try dataEncoder.appendNil(keyID: keyID)
			return
		}
		// now value if not nil!
		if let binaryValue = value as? NativeEncodable {
			if conditional {
				throw GCodableError.conditionalWithoutIdentity(
					Self.self, GCodableError.Context(
						debugDescription: "Can't conditionally encode a value \(value) without identity."
					)
				)
			}
			//	NativeEncodable types are:
			//		• Int
			//		• Int8
			//		• Int16
			//		• Int32
			//		• Int64
			//		• UInt
			//		• UInt8
			//		• UInt16
			//		• UInt32
			//		• UInt64
			//		---------
			//		• Float
			//		• Double
			//		• CGFloat
			//		---------
			//		• Bool
			//		---------
			//		• String
			//	String should not really be here, but the Encoder/Decoder
			//	become too slow if String doesn't adopt the NativeEncodable
			//	protocol
			try dataEncoder.appendBinValue(keyID: keyID, binaryValue: binaryValue )
		} else if let value = value as? GEncodable {
			if let identifier = identifier( of:value ) {	// IDENTITY
				if let objID = identifierMap.strongID( identifier ) {
					// already encoded value: we encode a pointer
					if conditional {
						try dataEncoder.appendConditionalPtr(keyID: keyID, objID: objID)
					} else {
						try dataEncoder.appendStrongPtr(keyID: keyID, objID: objID)
					}
				} else if conditional {
					// conditional encoding: we encode only a pointer
					
					if let type	= type(of:value) as? AnyClass {
						// se è un feference verifico che sia reificabile
						try ClassData.throwIfNotConstructible( type: type )
					}
						
					let objID	= identifierMap.createWeakID( identifier )
					try dataEncoder.appendConditionalPtr(keyID: keyID, objID: objID)
				} else {
					// not encoded value: we encode it
					let typeID	= try createTypeIDIfNeeded( for: value )
					let objID	= identifierMap.createStrongID( identifier )

					if let binaryValue = binaryValue( of:value ) {
						if let typeID {	// INHERITANCE
							try dataEncoder.appendIdBinRef(keyID: keyID, typeID: typeID, objID: objID, binaryValue: binaryValue )
						} else {	// NO INHERITANCE
							try dataEncoder.appendIdBinValue(keyID: keyID, objID: objID, binaryValue: binaryValue )
						}
					} else {
						if let typeID {	// INHERITANCE
							try dataEncoder.appendIdRef(keyID: keyID, typeID: typeID, objID: objID)
						} else {	// NO INHERITANCE
							try dataEncoder.appendIdValue(keyID: keyID, objID: objID)
						}
						try encodeValue( value )
						try dataEncoder.appendEnd()
					}
				}
			} else {	// NO IDENTITY
				if conditional {
					throw GCodableError.conditionalWithoutIdentity(
						Self.self, GCodableError.Context(
							debugDescription: "Can't conditionally encode a value \(value) without identity."
						)
					)
				}

				let typeID	= try createTypeIDIfNeeded( for: value )

				if let binaryValue = binaryValue( of:value ) {
					if let typeID {	// INHERITANCE
						try dataEncoder.appendBinRef(keyID: keyID, typeID: typeID, binaryValue: binaryValue )
					} else {
						try dataEncoder.appendBinValue(keyID: keyID, binaryValue: binaryValue )
					}
				} else {
					if let typeID {	// NO INHERITANCE
						try dataEncoder.appendRef( keyID: keyID, typeID: typeID )
					} else {
						try dataEncoder.appendValue( keyID: keyID )
					}
					try encodeValue( value )
					try dataEncoder.appendEnd()
				}
			}
		} else {
			throw GCodableError.internalInconsistency(
				Self.self, GCodableError.Context(
					debugDescription: "Not GEncodable value \(value)."
				)
			)
		}
	}
	
	private func encodeValue( _ value:GEncodable ) throws {
		let savedKeys	= currentKeys
		defer { currentKeys = savedKeys }
		currentKeys.removeAll()
		
		try value.encode(to: self)
	}
	
	private func createKeyID( key: String? ) throws -> UIntID {
		if let key = key {
			defer { currentKeys.insert( key ) }
			if currentKeys.contains( key ) {
				throw GCodableError.duplicateKey(
					Self.self, GCodableError.Context(
						debugDescription: "Key -\(key)- already used."
					)
				)
			}
			return keyMap.createKeyIDIfNeeded(key: key)
		} else {
			return 0	// unkeyed
		}
	}
}


// -------------------------------------------------
// ----- ReferenceMap
// -------------------------------------------------

fileprivate struct ReferenceMap {
	private	var			currentId : UIntID	= 1000	// ATT! 0-999 future use
	private (set) var	classDataMap	= ClassDataMap()
	private var			identifierMap	= [ObjectIdentifier: UIntID]()
	
	mutating func createTypeIDIfNeeded( type:(AnyObject & GEncodable).Type ) throws -> UIntID {
		let objIdentifier	= ObjectIdentifier( type )
		
		if let typeID = identifierMap[ objIdentifier ] {
			return typeID
		} else {
			defer { currentId += 1 }
			
			let typeID = currentId
			classDataMap[ typeID ]	= try ClassData( type: type )
			identifierMap[ objIdentifier ] = typeID
			return typeID
		}
	}
}

// -------------------------------------------------
// ----- KeyMap
// -------------------------------------------------

fileprivate struct KeyMap  {
	private	var			currentId : UIntID	= 1000	// ATT! 0 reserved for unkeyed coding / 1-999 future use
	private (set) var	keyStringMap		= KeyStringMap()
	private var			inverseMap			= [String: UIntID]()
	
	mutating func createKeyIDIfNeeded( key:String ) -> UIntID {
		if let keyID = inverseMap[ key ] {
			return keyID
		} else {
			let keyID = currentId
			defer { currentId += 1 }
			inverseMap[ key ]	= keyID
			keyStringMap[ keyID ] = key
			return keyID
		}
	}
}

// -------------------------------------------------
// ----- AnyIdentifierMap
// -------------------------------------------------
/* THE STANDARD WAY IS SLOWER:
fileprivate struct AnyIdentifierMap {
	private	var actualId : UIntID	= 1000	// <1000 reserved for future use
	private var	strongObjDict		= [AnyHashable:UIntID]()
	private var	weakObjDict			= [AnyHashable:UIntID]()

	func strongID<T:Hashable>( _ identifier: T ) -> UIntID? {
		strongObjDict[ identifier ]
	}

	mutating func createWeakID<T:Hashable>( _ identifier: T ) -> UIntID {
		if let objID = weakObjDict[ identifier ] {
			return objID
		} else {
			let objID = actualId
			defer { actualId += 1 }
			weakObjDict[ identifier ] = objID
			return objID
		}
	}

	mutating func createStrongID<T:Hashable>( _ identifier: T ) -> UIntID {
		if let objID = strongObjDict[ identifier ] {
			return objID
		} else if let objID = weakObjDict[identifier] {
			// se è nel weak dict, lo prendo da lì
			weakObjDict.removeValue(forKey: identifier)
			// e lo metto nello strong dict
			strongObjDict[identifier] = objID
			return objID
		} else {
			// altrimenti creo uno nuovo
			let objID = actualId
			defer { actualId += 1 }
			strongObjDict[identifier] = objID
			return objID
		}
	}
}
*/

fileprivate struct AnyIdentifierMap {
	private struct Key : Hashable {
		private let identifier : any Hashable
		
		init( _ identifier: any Hashable ) {
			self.identifier		= identifier
		}
		
		private static func equal<T,Q>( lhs: T, rhs: Q ) -> Bool where T:Equatable, Q:Equatable {
			guard let rhs = rhs as? T else { return false }
			return lhs == rhs
		}
		
		static func == (lhs: Self, rhs: Self) -> Bool {
			return equal(lhs: lhs.identifier, rhs: rhs.identifier)
		}
		
		func hash(into hasher: inout Hasher) {
			hasher.combine( ObjectIdentifier( type( of:identifier) ) )
			hasher.combine( identifier )
		}
	}
	
	private	var actualId : UIntID	= 1000	// <1000 reserved for future use
	private var	strongObjDict		= [Key:UIntID]()
	private var	weakObjDict			= [Key:UIntID]()
	
	func strongID<T:Hashable>( _ identifier: T ) -> UIntID? {
		strongObjDict[ Key(identifier) ]
	}
	
	mutating func createWeakID<T:Hashable>( _ identifier: T ) -> UIntID {
		let box	= Key(identifier)
		if let objID = weakObjDict[ box ] {
			return objID
		} else {
			let objID = actualId
			defer { actualId += 1 }
			weakObjDict[ box ] = objID
			return objID
		}
	}
	
	mutating func createStrongID<T:Hashable>( _ identifier: T ) -> UIntID {
		let key	= Key(identifier)
		if let objID = strongObjDict[ key ] {
			return objID
		} else if let objID = weakObjDict[key] {
			// se è nel weak dict, lo prendo da lì
			weakObjDict.removeValue(forKey: key)
			// e lo metto nello strong dict
			strongObjDict[key] = objID
			return objID
		} else {
			// altrimenti creo uno nuovo
			let objID = actualId
			defer { actualId += 1 }
			strongObjDict[key] = objID
			return objID
		}
	}
}


