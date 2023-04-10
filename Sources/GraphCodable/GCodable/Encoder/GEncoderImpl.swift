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
//			⤷	FileBlockEncoder
//					• a protocol for converting values into their representation
//
//		FileBlockEncoder protocol
//			DecodeDump : FileBlockEncoder
//			⤷	delegate = GEncoderImpl
//				• generate a binary rapresentation of values for encoding
//
//			EncodeDump : FileBlockEncoder
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
final class GEncoderImpl : EncodeFileBlocksDelegate {
	var userInfo							= [String:Any]()
	private let 		encodeOptions		: GraphEncoder.Options
	let 				userVersion			: UInt32
	let 				archiveIdentifier	: String?
	
	private var 		currentKeys			= Set<String>()
	private var			identityMap			= IdentityMap()
	private var			referenceMap		= ReferenceMap()
	private var			keyMap				= KeyMap()
	
	private var			blockEncoder		: (any EncodeFileBlocks)! {
		willSet {
			self.blockEncoder?.delegate	= nil
		}
		didSet {
			self.currentKeys			= Set<String>()
			self.identityMap			= IdentityMap()
			self.referenceMap			= ReferenceMap()
			self.keyMap					= KeyMap()
			self.blockEncoder?.delegate	= self
		}
	}
	
	var classDataMap: ClassDataMap 	{ referenceMap.classDataMap }
	var keyStringMap: KeyStringMap 	{ keyMap.keyStringMap }
	
	init( _ options: GraphEncoder.Options, userVersion:UInt32, archiveIdentifier: String? ) {
		#if DEBUG
		self.encodeOptions		= [options, .printWarnings]
		#else
		self.encodeOptions		= options
		#endif
		self.userVersion		= userVersion
		self.archiveIdentifier	= archiveIdentifier
	}

	private func ioEncoderAndHeader() -> (BinaryIOEncoder, FileHeader) {
		let ioEncoder		= BinaryIOEncoder(
			userVersion: userVersion,
			archiveIdentifier: archiveIdentifier,
			userData: self,
			enableCompression: !encodeOptions.contains( .disableCompression )
		)
		let fileHeader		= FileHeader(
			binaryIOEncoder: ioEncoder,
			gcoadableFlags: encodeOptions.contains( .dontMoveEncodedData ) ? [] : .useBinaryIOInsert
		)
		return (ioEncoder,fileHeader)
	}
	
	func encodeRoot<T,Q>( _ value: T ) throws -> Q where T:GEncodable, Q:MutableDataProtocol {
		defer { self.blockEncoder = nil }
		
		let (ioEncoder,fileHeader)	= ioEncoderAndHeader()
		
		let blockEncoder	= EncodeBinary<Q>(
			ioEncoder: 		ioEncoder,
			fileHeader: 	fileHeader
		)
		self.blockEncoder 	= blockEncoder
		try encode( value )
		return try blockEncoder.output()
	}
	
	func dumpRoot<T>( _ value: T, options: GraphDumpOptions ) throws -> String where T:GEncodable {
		defer { self.blockEncoder = nil }
		
		let (_,fileHeader)	= ioEncoderAndHeader()
		let blockEncoder	= EncodeDump(
			fileHeader:		fileHeader,
			dumpOptions:	options,
			fileSize: 		nil	// no data size during encode
		)
		self.blockEncoder	= blockEncoder
		try encode( value )
		return blockEncoder.dump()
	}
}

// MARK: GEncoderImpl conformance to GEncoder/GEncoderView protocol
extension GEncoderImpl : GEncoder, GEncoderView {
	func encode<Value>(_ value: Value) throws where Value:GEncodable {
		try level2_encodeValue( value, keyID: nil, conditional:false )
	}
	
	func encodeConditional<Value>(_ value: Value?) throws where Value:GEncodable {
		if let value {
			try level2_encodeValue( value, keyID: nil, conditional:true )
		} else {
			let pippo = Optional<Value>.none
			try level2_encodeValue( pippo, keyID: nil, conditional:true )
		}
		/*
		if let value {
			try level1_encodeValue( value, keyID: nil, conditional:true )
		} else {
			try blockEncoder.appendNil(keyID: nil)
		}
		 */
	}
	
	func encode<Key, Value>(_ value: Value, for key: Key) throws
	where Key : RawRepresentable, Value : GEncodable, Key.RawValue == String
	{
		try level2_encodeValue( value, keyID: try createKeyID( for:key.rawValue ), conditional:false )
	}
	
	func encodeConditional<Key, Value>(_ value: Value?, for key: Key) throws
	where Key : RawRepresentable, Value : GEncodable, Key.RawValue == String
	{
		if let value {
			try level2_encodeValue( value, keyID: try createKeyID( for:key.rawValue ), conditional:true )
		} else {
			let pippo = Optional<Value>.none
			try level2_encodeValue( pippo, keyID: try createKeyID( for:key.rawValue ), conditional:true )
		}


		/*
		let keyID	= try createKeyID( for:key.rawValue )
		if let value {
			try level1_encodeValue( value, keyID: keyID, conditional:true )
		} else {
			try blockEncoder.appendNil(keyID: keyID)
		}
		*/
	}
}

// MARK: GEncoderImpl private section
extension GEncoderImpl {
	/*
	private func level1_encodeValue(_ possiblyManyLevelOptionalValue: some GEncodable, keyID: KeyID?, conditional:Bool ) throws {
		//	possiblyManyLevelOptionalValue can really be a value, an Optional(value), an Optional(Optional(value)), etc…
		//	Optional(fullUnwrapping:_) turns anyValue into an one-level Optional(value)
		let optionalValue	= Optional(fullUnwrapping: possiblyManyLevelOptionalValue) as! (any GEncodable)?
	
		if let value = optionalValue {
			try level2_encodeValue( value, keyID: keyID, conditional:conditional )
		} else {
			// if value is nil, encode nil and return
			try blockEncoder.appendNil(keyID: keyID)
		}
	}
	*/
	private func level2_encodeValue(_ value: some GEncodable, keyID: KeyID?, conditional:Bool ) throws {
		// now value is not nil
		if let trivialValue = value as? any GPackEncodable {
			if encodeOptions.contains( .printWarnings ) {
				if conditional {
					print( "### Warning: can't conditionally encode the type '\( type(of:value) )' without identity. It will be encoded unconditionally." )
				}
			}
			try blockEncoder.appendBin(keyID: keyID, typeID:nil, objID:nil, binaryValue: trivialValue )
		} else {
			if let identity = identity( of:value ) {	// IDENTITY
				if let objID = identityMap.strongID( for:identity ) {
					// already encoded value: we encode a pointer
					try blockEncoder.appendPtr(keyID: keyID, objID: objID, conditional: conditional)
				} else if conditional {
					// conditional encoding: we encode only a pointer
					
					// Anyway we check if the reference class can be constructed from its name
					try throwIfNotConstructible( typeOf:value )

					let objID	= identityMap.createWeakID( for: identity )
					try blockEncoder.appendPtr(keyID: keyID, objID: objID, conditional: conditional)
				} else {
					// not encoded value: we encode it
					// INHERITANCE: only classes have a typeID (value typeID == nil)
					let typeID	= try createTypeIDIfNeeded( for: value )
					let objID	= identityMap.createStrongID( for: identity )

					if let binaryValue = value as? any GBinaryEncodable {
						// BinaryEncodable type
						try blockEncoder.appendBin(keyID: keyID, typeID: typeID, objID: objID, binaryValue: binaryValue)
					} else {
						// Encodable type
						try blockEncoder.appendVal(keyID: keyID, typeID: typeID, objID: objID)
						try level3_encodeValue( value )
						try blockEncoder.appendEnd()
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
					try blockEncoder.appendBin(keyID: keyID, typeID: typeID, objID: nil, binaryValue: binaryValue)
				} else {
					try blockEncoder.appendVal(keyID: keyID, typeID: typeID, objID: nil )
					try level3_encodeValue( value )
					try blockEncoder.appendEnd()
				}
			}
		}
	}

	private func level3_encodeValue( _ value:some GEncodable ) throws {
		let savedKeys	= currentKeys
		defer { currentKeys = savedKeys }
		currentKeys.removeAll()
		
		try value.encode(to: self)
	}
	
	private func identity( of value:some GEncodable ) -> Identity? {
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

	private func createTypeIDIfNeeded( for value:some GEncodable ) throws -> TypeID? {
		guard
			!encodeOptions.contains( .disableInheritance ),
			value.inheritanceEnabled,
			let object = value as? any (AnyObject & GEncodable) else {
			return nil
		}
		return try referenceMap.createTypeIDIfNeeded( for: object )
	}

	
	private func throwIfNotConstructible( typeOf value:some GEncodable ) throws {
		if	!encodeOptions.contains( .disableInheritance ),
			value.inheritanceEnabled,
			let object = value as? any (AnyObject & GEncodable) {
			try ClassData.throwIfNotConstructible( type: type(of:object) )
		}
	}
		
}




