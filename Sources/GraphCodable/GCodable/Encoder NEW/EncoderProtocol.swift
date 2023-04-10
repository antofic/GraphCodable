//	MIT License
//
//	Copyright (c) 2021-2023 Antonino Ficarra
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


protocol EncoderProtocol : AnyObject, GEncoder, GEncoderView {
	var encodeOptions 	: GraphEncoder.Options { get }
	var	identityMap		: IdentityMap  { get set }
	var	referenceMap	: ReferenceMap  { get set }
	var	keyMap			: KeyMap  { get set }
	var currentKeys		: Set<String>  { get set }

	
	func appendEnd() throws
	func appendNil( keyID:KeyID? ) throws
	func appendPtr( keyID:KeyID?, objID:ObjID, conditional:Bool ) throws
	func appendVal(keyID: KeyID?, typeID: TypeID?, objID: ObjID?) throws
	func appendBin<T:BEncodable>(keyID: KeyID?, typeID: TypeID?, objID: ObjID?, binaryValue: T) throws
}

// MARK: GEncoderProtocol conformance to GEncoder/GEncoderView protocol
extension EncoderProtocol {
	func encode<Value>(_ value: Value) throws where Value:GEncodable {
		try level1_encodeValue( value, keyID: nil, conditional:false )
	}
	
	func encodeConditional<Value>(_ value: Value?) throws where Value:GEncodable {
		if let value {
			try level1_encodeValue( value, keyID: nil, conditional:true )
		} else {
			try appendNil(keyID: nil)
		}
	}
	
	func encode<Key, Value>(_ value: Value, for key: Key) throws
	where Key : RawRepresentable, Value : GEncodable, Key.RawValue == String
	{
		try level1_encodeValue( value, keyID: try createKeyID( for:key.rawValue ), conditional:false )
	}
	
	func encodeConditional<Key, Value>(_ value: Value?, for key: Key) throws
	where Key : RawRepresentable, Value : GEncodable, Key.RawValue == String
	{
		let keyID	= try createKeyID( for:key.rawValue )
		if let value {
			try level1_encodeValue( value, keyID: keyID, conditional:true )
		} else {
			try appendNil(keyID: keyID)
		}
	}
}

// MARK: GEncoderProtocol private methods
extension EncoderProtocol {

	private func level1_encodeValue<T:GEncodable>(_ possiblyManyLevelOptionalValue: T, keyID: KeyID?, conditional:Bool ) throws {
		//	anyValue can really be a value, an Optional(value), an Optional(Optional(value)), etc…
		//	Optional(fullUnwrapping:_) turns anyValue into an one-level Optional(value)
		let optionalValue	= Optional(fullUnwrapping: possiblyManyLevelOptionalValue) as! (any GEncodable)?
	
		if let value = optionalValue {
			try level2_encodeValue( value, keyID: keyID, conditional:conditional )
		} else {
			// if value is nil, encode nil and return
			try appendNil(keyID: keyID)
		}
	}

	private func level2_encodeValue<T:GEncodable>(_ value: T, keyID: KeyID?, conditional:Bool ) throws {
		// now value is not nil
		if let trivialValue = value as? any GPackEncodable {
			if encodeOptions.contains( .printWarnings ) {
				if conditional {
					print( "### Warning: can't conditionally encode the type '\( type(of:value) )' without identity. It will be encoded unconditionally." )
				}
			}
			try appendBin(keyID: keyID, typeID:nil, objID:nil, binaryValue: trivialValue )
		} else {
			if let identity = identity( of:value ) {	// IDENTITY
				if let objID = identityMap.strongID( for:identity ) {
					// already encoded value: we encode a pointer
					try appendPtr(keyID: keyID, objID: objID, conditional: conditional)
				} else if conditional {
					// conditional encoding: we encode only a pointer
					
					// Anyway we check if the reference class can be constructed from its name
					try throwIfNotConstructible( typeOf:value )

					let objID	= identityMap.createWeakID( for: identity )
					try appendPtr(keyID: keyID, objID: objID, conditional: conditional)
				} else {
					// not encoded value: we encode it
					// INHERITANCE: only classes have a typeID (value typeID == nil)
					let typeID	= try createTypeIDIfNeeded( for: value )
					let objID	= identityMap.createStrongID( for: identity )

					if let binaryValue = value as? any GBinaryEncodable {
						// BinaryEncodable type
						try appendBin(keyID: keyID, typeID: typeID, objID: objID, binaryValue: binaryValue)
					} else {
						// Encodable type
						try appendVal(keyID: keyID, typeID: typeID, objID: objID)
						try level3_encodeValue( value )
						try appendEnd()
					}
				}
			} else {	// NO IDENTITY
				// INHERITANCE: only classes have a typeID != 0
				let typeID	= try createTypeIDIfNeeded( for: value )

				if encodeOptions.contains( .printWarnings ) {
					if conditional {
						print( "### Warning: can't conditionally encode the type '\( type(of:value) )' without identity. It will be encoded unconditionally." )
					}
				}
				
				if let binaryValue = value as? any GBinaryEncodable {
					// BinaryEncodable type
					try appendBin(keyID: keyID, typeID: typeID, objID: nil, binaryValue: binaryValue)
				} else {
					try appendVal(keyID: keyID, typeID: typeID, objID: nil )
					try level3_encodeValue( value )
					try appendEnd()
				}
			}
		}
	}

	
	
	private func level3_encodeValue<T:GEncodable>( _ value:T ) throws {
		let savedKeys	= currentKeys
		defer { currentKeys = savedKeys }
		currentKeys.removeAll()
		
		try value.encode(to: self)
	}


	private func identity<T:GEncodable>( of value:T ) -> Identity? {
		if encodeOptions.contains( .disableIdentity ) {
			return nil
		}
		
		if encodeOptions.contains( .tryHashableIdentityAtFirst ) {
			if let value = value as? (any Hashable) {
				return Identity( value )
			}
		}
		
		if let value = value as? any (GEncodable & GIdentifiable) {
			if let id = value.gcodableID {
				return Identity( id )
			}
		} else if let value = value as? any (GEncodable & AnyObject) {
			return Identity( ObjectIdentifier( value ) )
		}
		
		if encodeOptions.contains( .tryHashableIdentityAtLast ) {
			if let value = value as? (any Hashable) {
				return Identity( value )
			}
		}
		
		return nil
	}
	
	private func createKeyID( for key: String ) throws -> KeyID {
		defer { currentKeys.insert( key ) }
		if currentKeys.contains( key ) {
			throw GraphCodableError.duplicateKey(
				Self.self, GraphCodableError.Context(
					debugDescription: "Key \(key) already used."
				)
			)
		}
		return keyMap.createKeyIDIfNeeded(key: key)
	}

	private func createTypeIDIfNeeded<T:GEncodable>( for value:T ) throws -> TypeID? {
		guard
			!encodeOptions.contains( .disableInheritance ),
			value.inheritanceEnabled,
			let object = value as? any (AnyObject & GEncodable) else {
			return nil
		}
		return try referenceMap.createTypeIDIfNeeded( for: object )
	}

	
	private func throwIfNotConstructible<T:GEncodable>( typeOf value:T ) throws {
		if	!encodeOptions.contains( .disableInheritance ),
			value.inheritanceEnabled,
			let object = value as? any (AnyObject & GEncodable) {
			try ClassData.throwIfNotConstructible( type: type(of:object) )
		}
	}
}
