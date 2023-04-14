//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation


//---------------------------------------------------------------------------------------------
//	Encoder Structure:
//		GraphEncoder	(public interface)
//		⤷	GEncoderImpl : GEncoder, EncodeFileBlocksDelegate
//			⤷	IdentityMap			(IdnID → Identifier)
//					• manage Identity
//			⤷	ReferenceMap		(ObjectIdentifier → RefID → ClassData )
//					• manage Inheritance (reference types only)
//			⤷	KeyMap				(KeyID ↔︎ keystring)
//					• manage keystring (keyed encoding / KeyID==nil → unkeyed encoding)
//			⤷	EncodeFileBlocks
//					• a protocol for converting values into their representation
//
//		EncodeFileBlocks protocol
//			EncodeBinary : EncodeFileBlocks
//			⤷	delegate = GEncoderImpl
//				• generate a binary rapresentation of values for encoding
//
//			EncodeDump : EncodeFileBlocks
//			⤷	delegate = GEncoderImpl
//				• generate readable/not decodable string rapresentation of values
//
//	Both EncodeBinary and EncodeDump produce their output as they receive the
//	input values (single pass)
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
	
	private var manglingFunction : ManglingFunction {
		encodeOptions.contains( .useNSClassFromStringMangling ) ?
			.nsClassFromString : .mangledTypeName
	}
	
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
			gcoadableFlags: []
		)
		return (ioEncoder,fileHeader)
	}
	
	func encodeRoot<Q>( _ value: some GEncodable ) throws -> Q where Q:MutableDataProtocol {
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
	
	func dumpRoot( _ value: some GEncodable, options: GraphDumpOptions ) throws -> String {
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
	func isCodableClass(_ type: (AnyObject & GEncodable).Type) -> Bool {
		ClassData.isConstructible( type: type, manglingFunction: manglingFunction )
	}
	
	func encode<Value>(_ value: Value) throws where Value:GEncodable {
		try level1_encodeValue( value, keyID: nil, conditional:false )
	}
	
	func encodeConditional<Value>(_ value: Value?) throws where Value:GEncodable {
		try level1_encodeValue( value, keyID: nil, conditional:true )
	}
	
	func encode<Key, Value>(_ value: Value, for key: Key) throws
	where Key : RawRepresentable, Value : GEncodable, Key.RawValue == String
	{
		try level1_encodeValue( value, keyID: try createKeyID( for:key.rawValue ), conditional:false )
	}
	
	func encodeConditional<Key, Value>(_ value: Value?, for key: Key) throws
	where Key : RawRepresentable, Value : GEncodable, Key.RawValue == String
	{
		try level1_encodeValue( value, keyID: try createKeyID( for:key.rawValue ), conditional:true )
	}
}

// MARK: GEncoderImpl private section
extension GEncoderImpl {
	private func level1_encodeValue(_ value: some GEncodable, keyID: KeyID?, conditional:Bool ) throws {
		if let value = value._fullOptionalUnwrappedValue {
			try level2_encodeValue( value, keyID: keyID, conditional:conditional )
		} else { // if value is nil, encode nil and return
			try blockEncoder.appendNil(keyID: keyID)
		}
	}
	
	private func level2_encodeValue(_ value: some GEncodable, keyID: KeyID?, conditional:Bool ) throws {
		// now value is not nil
		if let trivialValue = value as? any GPackEncodable {
			if encodeOptions.contains( .printWarnings ) {
				if conditional {
					print( "### Warning: can't conditionally encode the type '\( type(of:value) )' without identity. It will be encoded unconditionally." )
				}
			}
			try blockEncoder.appendBin(keyID: keyID, refID:nil, idnID:nil, binaryValue: trivialValue )
		} else {
			if let identity = identity( of:value ) {	// IDENTITY
				if let idnID = identityMap.strongID( for:identity ) {
					// already encoded value: we encode a pointer
					try blockEncoder.appendPtr(keyID: keyID, idnID: idnID, conditional: conditional)
				} else if conditional {
					// Anyway we check if the reference class can be constructed from its name
					try throwIfNotConstructible( typeOf:value )

					// conditional encoding: we encode only a pointer
					let idnID	= identityMap.createWeakID( for: identity )
					try blockEncoder.appendPtr(keyID: keyID, idnID: idnID, conditional: conditional)
				} else {
					// not encoded value: we encode it
					// INHERITANCE: only classes have a refID (value refID == nil)
					let refID	= try createRefIDIfNeeded( for: value )
					let idnID	= identityMap.createStrongID( for: identity )

					if let binaryValue = value as? any GBinaryEncodable {
						// BinaryEncodable type
						try blockEncoder.appendBin(keyID: keyID, refID: refID, idnID: idnID, binaryValue: binaryValue)
					} else {
						// Encodable type
						try blockEncoder.appendVal(keyID: keyID, refID: refID, idnID: idnID, value: value)
						try level3_encodeValue( value )
						try blockEncoder.appendEnd()
					}
				}
			} else {	// NO IDENTITY
				// INHERITANCE: only classes have a refID (value refID == nil)
				let refID	= try createRefIDIfNeeded( for: value )

				if encodeOptions.contains( .printWarnings ) {
					if conditional {
						print( "### Warning: can't conditionally encode the type '\( type(of:value) )' without identity. It will be encoded unconditionally." )
					}
				}
				
				if let binaryValue = value as? any GBinaryEncodable {
					// BinaryEncodable type
					try blockEncoder.appendBin(keyID: keyID, refID: refID, idnID: nil, binaryValue: binaryValue)
				} else {
					try blockEncoder.appendVal(keyID: keyID, refID: refID, idnID: nil, value: value )
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
		} else if let value = value as? any (AnyObject & GEncodable) {
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
			throw Errors.GraphCodable.duplicateKey(
				Self.self, Errors.Context(
					debugDescription: "Key |\(key)| already used."
				)
			)
		}
		return keyMap.createKeyIDIfNeeded(key: key)
	}

	private func createRefIDIfNeeded( for value:some GEncodable ) throws -> RefID? {
		guard
			!encodeOptions.contains( .disableInheritance ),
			value.inheritanceEnabled,
			let object = value as? any (AnyObject & GEncodable) else {
			return nil
		}
		return try referenceMap.createRefIDIfNeeded( for: object, manglingFunction: manglingFunction )
	}

	
	private func throwIfNotConstructible( typeOf value:some GEncodable ) throws {
		if	!encodeOptions.contains( .disableInheritance ),
			value.inheritanceEnabled,
			let object = value as? any (AnyObject & GEncodable) {
			try ClassData.throwIfNotConstructible( type: type(of:object), manglingFunction: manglingFunction )
		}
	}
}




