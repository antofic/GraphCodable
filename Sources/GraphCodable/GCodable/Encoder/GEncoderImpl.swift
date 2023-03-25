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


//---------------------------------------------------------------------------------------------
//	Encoder Structure:
//		GraphEncoder	(public interface)
//		⤷	GEncoderImpl : GEncoder, FileBlockEncoderDelegate
//			⤷	AnyIdentifierMap	(ObjID → Identifier)
//					• manage Identity
//			⤷	ReferenceMap		(ObjectIdentifier → TypeID → ClassData )
//					• manage Inheritance (reference types only)
//			⤷	KeyMap				(KeyID ↔︎ keystring)
//					• manage keystring (keyed encoding / KeyID==0 → unkeyed encoding)
//			⤷	any DataEncoder
//					• a protocol for converting values into their representation
//
//		FileBlockEncoder protocol
//			BinaryEncoder : FileBlockEncoder
//			⤷	delegate = GEncoderImpl
//				• generate a binary rapresentation of values for encoding
//
//			StringEncoder : FileBlockEncoder
//			⤷	delegate = GEncoderImpl
//				• generate readable/not decodable string rapresentation of values
//
//	Both data encoders produce their output as they receive the input values (single pass)
//---------------------------------------------------------------------------------------------


///	A class that implements the GEncoder protocol
///
/// GEncoderImpl produces:
/// - a data representation of the rootValue to encode
/// - eventualy, a readable string that described this data representation
final class GEncoderImpl : FileBlockEncoderDelegate {
	var userInfo							= [String:Any]()
	private let 		encodeOptions		: GraphEncoder.Options
	private let 		fileHeader			: FileHeader
	private var 		currentKeys			= Set<String>()
	private var			identityMap			= IdentityMap()
	private var			referenceMap		= ReferenceMap()
	private var			keyMap				= KeyMap()
	
	private var			dataEncoder			: FileBlockEncoder! {
		willSet {
			self.dataEncoder?.delegate	= nil
		}
		didSet {
			self.currentKeys			= Set<String>()
			self.identityMap			= IdentityMap()
			self.referenceMap			= ReferenceMap()
			self.keyMap					= KeyMap()
			self.dataEncoder?.delegate	= self
		}
	}
	
	var classDataMap: ClassDataMap 	{ referenceMap.classDataMap }
	var keyStringMap: KeyStringMap 	{ keyMap.keyStringMap }
	
	private func writeBuffer() -> BinaryWriteBuffer {
		BinaryWriteBuffer( userVersion: fileHeader.userVersion, userData: self )
	}
	
	init( _ options: GraphEncoder.Options, userVersion:UInt32 ) {
		#if DEBUG
		self.encodeOptions	= [options, .printWarnings]
		#else
		self.encodeOptions	= options
		#endif
		// packBinSize or not???
		self.fileHeader = FileHeader(
			userVersion: userVersion,
			binaryIOVersion: BinaryWriteBuffer.binaryIOVersion,
			flags: .packBinSize
		)
	}

	func encodeRoot<T,Q>( _ value: T ) throws -> Q where T:GEncodable, Q:MutableDataProtocol {
		defer { self.dataEncoder = nil }
		let binaryWriteBuffer	= writeBuffer()
		let dataEncoder			= BinaryEncoder<Q>( binaryWriteBuffer: binaryWriteBuffer, fileHeader: fileHeader )
		self.dataEncoder 		= dataEncoder
		try encode( value )
		return try dataEncoder.output()
	}
	
	func dumpRoot<T>( _ value: T, options: GraphDumpOptions ) throws -> String where T:GEncodable {
		defer { self.dataEncoder = nil }
		let dataEncoder		= StringEncoder(
			fileHeader:			fileHeader,
			dumpOptions:		options,
			dataSize: 			nil	// no data size during encode
		)
		self.dataEncoder	= dataEncoder
		try encode( value )
		return dataEncoder.dump()
	}
}

// MARK: GEncoderImpl conformance to GEncoder protocol
extension GEncoderImpl : GEncoder, GEncoderView {
	var	userVersion	: UInt32 {
		return fileHeader.userVersion
	}
	
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
}

// MARK: GEncoderImpl private section
extension GEncoderImpl {
	private func encodeAnyValue(_ anyValue: Any, forKey key: String?, conditional:Bool ) throws {
		//	anyValue cam really be a value, an Optional(value), an Optional(Optional(value)), etc…
		//	Optional(fullUnwrapping:_) turns anyValue into an one-level Optional(value)
		let value	= Optional(fullUnwrapping: anyValue)
	
		// if keyID != nil <=> key != nil (keyed values)
		let keyID	= try createKeyID( for: key )
		
		// if value is nil, encode nil and return
		guard let value = value else {
			try dataEncoder.appendNil(keyID: keyID)
			return
		}
		// now value is not nil
		if let trivialValue = value as? GPackEncodable {
			if encodeOptions.contains( .printWarnings ) {
				if conditional {
					print( "### Warning: can't conditionally encode the type '\( type(of:value) )' without identity. It will be encoded unconditionally." )
				}
			}
			try dataEncoder.appendVal(keyID: keyID, typeID:nil, objID:nil, binaryValue: trivialValue )
		} else if let value = value as? GEncodable {
			if let identity = identity( of:value ) {	// IDENTITY
				if let objID = identityMap.strongID( for:identity ) {
					// already encoded value: we encode a pointer
					try dataEncoder.appendPtr(keyID: keyID, objID: objID, conditional: conditional)
				} else if conditional {
					// conditional encoding: we encode only a pointer
					
					// Anyway we check if the reference class can be constructed from its name
					try throwIfNotConstructibleType( of:value )

					let objID	= identityMap.createWeakID( for: identity )
					try dataEncoder.appendPtr(keyID: keyID, objID: objID, conditional: conditional)
				} else {
					// not encoded value: we encode it
					// INHERITANCE: only classes have a typeID (value typeID == nil)
					let typeID	= try createTypeIDIfNeeded( for: value )
					let objID	= identityMap.createStrongID( for: identity )

					if let binaryValue = value as? GBinaryEncodable {
						// BinaryEncodable type
						try dataEncoder.appendVal(keyID: keyID, typeID: typeID, objID: objID, binaryValue: binaryValue)
					} else {
						// Encodable type
						try dataEncoder.appendVal(keyID: keyID, typeID: typeID, objID: objID, binaryValue: nil)
						try encodeValue( value )
						try dataEncoder.appendEnd()
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
				
				if let binaryValue = value as? GBinaryEncodable {
					// BinaryEncodable type
					try dataEncoder.appendVal(keyID: keyID, typeID: typeID, objID: nil, binaryValue: binaryValue)
				} else {
					try dataEncoder.appendVal(keyID: keyID, typeID: typeID, objID: nil, binaryValue: nil)
					try encodeValue( value )
					try dataEncoder.appendEnd()
				}
			}
		} else {
			throw GraphCodableError.internalInconsistency(
				Self.self, GraphCodableError.Context(
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
	
	private func identity( of value:GEncodable ) -> Identity? {
		if	encodeOptions.contains( .disableIdentity ) {
			return nil
		}
		
		if	encodeOptions.contains( .tryHashableIdentityAtFirst ) {
			if let value = value as? (any Hashable) {
				return Identity( value )
			}
		}
		
		if let value = value as? any (GEncodable & GIdentifiable) {
			if let id = value.gcodableID {
				return Identity( id )
			}
			// let's give .tryHashableIdentityAtLast a chance
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
		 
	private func createKeyID( for key: String? ) throws -> KeyID? {
		if let key = key {
			defer { currentKeys.insert( key ) }
			if currentKeys.contains( key ) {
				throw GraphCodableError.duplicateKey(
					Self.self, GraphCodableError.Context(
						debugDescription: "Key \(key) already used."
					)
				)
			}
			return keyMap.createKeyIDIfNeeded(key: key)
		} else {
			return nil
		}
	}
	
	private func createTypeIDIfNeeded( for value:any GEncodable ) throws -> TypeID? {
		guard
			!encodeOptions.contains( .disableInheritance ),
			value.inheritanceEnabled,
			let object = value as? any (AnyObject & GEncodable) else {
			return nil
		}
		
		return try referenceMap.createTypeIDIfNeeded( type: type(of:object) )
	}
	
	private func throwIfNotConstructibleType( of value:any GEncodable ) throws {
		if	!encodeOptions.contains( .disableInheritance ),
			value.inheritanceEnabled,
			let object = value as? any (AnyObject & GEncodable) {
			try ClassData.throwIfNotConstructible( type: type(of:object) )
		}
	}
		
}




