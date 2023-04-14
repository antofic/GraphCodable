//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra


/// the body of a GCodable file is a sequence of FileBlock's
enum FileBlock {
	private struct Code: OptionSet, BCodable {
		let rawValue: UInt8
		
		private static let	b0 = Self( rawValue: 1 << 0 )
		private static let	b1 = Self( rawValue: 1 << 1 )
		private static let	b2 = Self( rawValue: 1 << 2 )
		private static let	b3 = Self( rawValue: 1 << 3 )
		private static let	b4 = Self( rawValue: 1 << 4 )
		private static let	b5 = Self( rawValue: 1 << 5 )
		private static let	b6 = Self( rawValue: 1 << 6 )
		private static let	b7 = Self( rawValue: 1 << 7 )
		
		private static let	catMask:		Self = [ b0,b1,b2 ]
		private static let	catEnd:			Self = []			//	0
		private static let	catNil:			Self = [ b0 ]		//	1
		private static let	catPtr:			Self = [ b1 ]		//	2
		private static let	catVal:			Self = [ b1, b0 ]	//	3
		private static let	catBin:			Self = [ b2 ]		//	4

		private static let	hasKeyID:		Self = [ b3 ]		// catVal, catBin, catPtr, catNil
		private static let	hasIdnID:		Self = [ b4 ]		// catVal, catBin, catPtr
		private static let	hasRefID:		Self = [ b5 ]		// catVal, catBin, (catPtr as conditional)
		
		private static let	conditional:	Self = hasRefID	// conditional (!= hasIdnID,hasKeyID ) may overlap hasRefID

		private static let	ptr:			Self = [ catPtr, hasIdnID ]	// ptr always has idnID
		//	b6, b7	= future use
		
		enum Category {
			case End, Nil, Ptr, Val, Bin
		}
		
		var category : Category {
			get throws {
				let cat = intersection( Self.catMask )
				switch cat {
				case .catEnd:	return .End
				case .catNil:	return .Nil
				case .catPtr:	return .Ptr
				case .catVal:	return .Val
				case .catBin:	return .Bin
				default:
					throw GraphCodableError.malformedArchive(
						Self.self, GraphCodableError.Context(
							debugDescription: "Unknown code category \(cat)."
						)
					)
				}
			}
		}
		
		var hasKeyID		: Bool { contains( .hasKeyID ) }
		var hasIdnID		: Bool { contains( .hasIdnID ) }
		var hasRefID		: Bool { contains( .hasRefID ) }
		var isConditional	: Bool { contains( .conditional ) }
		
		//	-----------------------------------------------------------------------
		//	keyID == nil	fileBlock is an unkeyed field of its parent value
		//	keyID != nil	fileBlock is a keyed field of its parent value
		//	idnID == nil	fileBlock don't have Identity
		//	idnID != nil	fileBlock have Identity
		//	refID == nil	fileBlock don't supports inheritance (value type)
		//	refID != nil	fileBlock supports inheritance (reference type) (*)
		//	-----------------------------------------------------------------------

		static func End() -> Self {
			return catEnd
		}

		static func Nil( keyID:KeyID? ) -> Self {
			var code	= catNil
			if keyID	!= nil { code.formUnion( .hasKeyID ) }
			return code
		}
		
		static func Ptr( keyID:KeyID?, idnID:IdnID, conditional:Bool ) -> Self {
			var code = ptr
			if keyID != nil	{ code.formUnion( .hasKeyID ) }
			if conditional 	{ code.formUnion( .conditional ) }
			return code
		}
		
		static func  Val( keyID:KeyID?, idnID:IdnID?, refID:RefID? ) -> Self {
			var code = catVal
			if keyID != nil	{ code.formUnion( .hasKeyID ) }
			if refID != nil	{ code.formUnion( .hasRefID ) }
			if idnID != nil	{ code.formUnion( .hasIdnID ) }
			return code
		}

		static func  Bin( keyID:KeyID?, idnID:IdnID?, refID:RefID? ) -> Self {
			var code = catBin
			if keyID != nil	{ code.formUnion( .hasKeyID ) }
			if refID != nil	{ code.formUnion( .hasRefID ) }
			if idnID != nil	{ code.formUnion( .hasIdnID ) }
			return code
		}
	}
	// END
	case End
	// NIL
	case Nil( keyID:KeyID? )
	// PTS<IdnID>, PTC<IdnID>
	case Ptr( keyID:KeyID?, idnID:IdnID, conditional:Bool )
	//	VAL<idnID?>, REF<idnID?>
	case Val( keyID:KeyID?, idnID:IdnID?, refID:RefID? )
	//	BIV<idnID?>, BIR<idnID?>
	case Bin( keyID:KeyID?, idnID:IdnID?, refID:RefID?, binSize:Int )
}


extension FileBlock {
	var keyID : KeyID? {
		switch self {
		case .Nil( let keyID ):			return	keyID
		case .Ptr( let keyID, _,_ ):	return	keyID
		case .Val( let keyID, _,_ ):	return	keyID
		case .Bin( let keyID, _,_,_ ):	return	keyID
		default:						return	nil
		}
	}

	var nextFileBlockDistance : Int {
		switch self {
			case .Bin( _,_,_, let binSize ): return binSize
			default: return 0
		}
	}

}

extension FileBlock {
	static func encodeEnd(
		to encoder: inout BinaryIOEncoder, fileHeader:FileHeader
	) throws {
		try encoder.encode( Code.End() )
	}

	static func encodeNil(
		keyID:KeyID?,
		to encoder: inout BinaryIOEncoder, fileHeader:FileHeader
	) throws {
		try encoder.encode( Code.Nil(keyID: keyID) )
		if let keyID 	{ try encoder.encode( keyID ) }
	}

	static func encodePtr(
		keyID:KeyID?, idnID:IdnID, conditional:Bool,
		to encoder: inout BinaryIOEncoder, fileHeader:FileHeader
	) throws {
		try encoder.encode( Code.Ptr(keyID: keyID, idnID: idnID, conditional:conditional ) )
		if let keyID 	{ try encoder.encode( keyID ) }
		try encoder.encode( idnID )
	}
	
	static func encodeVal(
		keyID:KeyID?, idnID:IdnID?, refID:RefID?,
		to encoder: inout BinaryIOEncoder, fileHeader:FileHeader
	) throws {
		try encoder.encode( Code.Val(keyID: keyID, idnID: idnID, refID: refID ) )
		if let keyID	{ try encoder.encode( keyID ) }
		if let idnID	{ try encoder.encode( idnID ) }
		if let refID	{ try encoder.encode( refID ) }
	}
	
	static func encodeBin(
		keyID:KeyID?, idnID:IdnID?, refID:RefID?, binaryValue: some GBinaryEncodable,
		to encoder: inout BinaryIOEncoder, fileHeader:FileHeader
	) throws {
		try encoder.encode( Code.Bin(keyID: keyID, idnID: idnID, refID: refID ) )
		if let keyID	{ try encoder.encode( keyID ) }
		if let idnID	{ try encoder.encode( idnID ) }
		if let refID	{ try encoder.encode( refID ) }
		try encoder.withEncodedIntSizeBefore { try $0.encode( binaryValue ) }
	}
}

extension FileBlock {
	init(from decoder: inout BinaryIODecoder, fileHeader:FileHeader ) throws {
		func decode<T:BDecodable>( _ type:T.Type, if test:Bool ) throws -> T? {
			test ? try decoder.decode( type ) : nil
		}
		
		let code = try decoder.decode( Code.self )
		
		switch try code.category {
			case .End:
				self		= .End
			case .Nil:
				let keyID	= try decode( KeyID.self, if: code.hasKeyID )
				self		= .Nil(keyID: keyID)
			case .Ptr:
				let keyID	= try decode( KeyID.self, if: code.hasKeyID )
				let idnID	= try decoder.decode( IdnID.self )
				self		= .Ptr( keyID: keyID, idnID: idnID, conditional: code.isConditional )
			case .Val:
				let keyID	= try decode( KeyID.self, if: code.hasKeyID )
				let idnID	= try decode( IdnID.self, if: code.hasIdnID )
				let refID	= try decode( RefID.self, if: code.hasRefID )
				self 		= .Val( keyID: keyID, idnID: idnID, refID: refID )
			case .Bin:
				let keyID	= try decode( KeyID.self, if: code.hasKeyID )
				let idnID	= try decode( IdnID.self, if: code.hasIdnID )
				let refID	= try decode( RefID.self, if: code.hasRefID )
				let binSize	= try decoder.decode( Int.self )
				self 		= .Bin( keyID: keyID, idnID: idnID, refID: refID, binSize: binSize )
		}
	}
}

extension FileBlock : CustomStringConvertible {
	var description: String {
		description(options: .readable, classDataMap: nil, keyStringMap: nil)
	}

	func description(
		options:		GraphDumpOptions,
		classDataMap:	ClassDataMap?,
		keyStringMap: 	KeyStringMap?
	) -> String {
		description(options: options, classDataMap: classDataMap, keyStringMap: keyStringMap ) { nil }
	}
	
	func description(
		options:			GraphDumpOptions,
		classDataMap cdm:	ClassDataMap?,
		keyStringMap ksm: 	KeyStringMap?,
		valueDescription: 	() -> String?
	) -> String {
		func typeName( _ refID:RefID, _ options:GraphDumpOptions, _ classDataMap:ClassDataMap? ) -> String {
			if let classData	= classDataMap?[refID] {
				let qualified	= options.contains( .qualifiedTypeNames )
				if options.contains( .showClassVersionsInBody ) {
					return "\(classData.className( qualified: qualified )) V\(classData.encodedClassVersion)"
				} else {
					return classData.className( qualified: qualified )
				}
			} else {
				return "TYPE\(refID)"
			}
		}
		
		func truncate( _ valueDescription: String, _ options:GraphDumpOptions, maxLength:Int = 64 ) -> String {
			if options.contains( .dontTruncateValueDescriptionInBody ) {
				return valueDescription
			} else {
				let phase2	= valueDescription.count > maxLength ?
				valueDescription.prefix(maxLength).appending("…") : valueDescription
				
				return phase2
			}
		}

		func keyName( _ keyID:KeyID?, _ keyStringMap: KeyStringMap? ) -> String {
			if let keyID {
				if let key = keyStringMap?[keyID] {
					return "+ KEY(\(key)): "
				} else {
					return "+ KEY\(keyID): "
				}
			} else {
				return "- "
			}
		}
		
		let classDataMap = options.contains( .showClassNamesInBody ) ? cdm : nil
		let keyStringMap = options.contains( .showKeyStringsInBody ) ? ksm : nil
		
		var string	= ""
		switch self {
			case .End:
				string.append( "." )
			case .Nil( let keyID ):
				string.append( keyName( keyID, keyStringMap ) )
				string.append( "NIL" )
			case .Ptr( let keyID, let idnID, let conditional ):
				string.append( keyName( keyID, keyStringMap ) )
				string.append( conditional ? "PTC" : "PTS" )
				string.append( idnID.description )
			case .Val( let keyID, let idnID, let refID ):
				//	VAL			= []
				//	REF			= [refID]
				//	VAL<idnID>	= [idnID]
				//	REF<idnID>	= [idnID,refID]
				string.append( keyName( keyID, keyStringMap ) )
				string.append( refID != nil ? "REF" : "VAL" )
				if let idnID	{ string.append( idnID.description ) }
				if let refID	{ string.append( "(\( typeName( refID,options,classDataMap ) ))") }
				if options.contains( .showNotBinaryValueDescriptionInBody ),
				   let stringDescription = valueDescription() {
					string.append( " \( truncate( stringDescription, options ) )")
				} 
			case .Bin( let keyID, let idnID, let refID, let binSize ):
				//	BIV			= [bytes]
				//	BIR			= [refID,bytes]
				//	BIV<idnID>	= [idnID,bytes]
				//	BIR<idnID>	= [idnID,refID,bytes]
				string.append( keyName( keyID, keyStringMap ) )
				string.append( refID != nil ? "BIR" : "BIV" )
				if let idnID	{ string.append( idnID.description ) }
				if let refID	{ string.append( "(\( typeName( refID,options,classDataMap ) ))") }
				if options.contains( .showBinaryValueDescriptionInBody ) {
					if let stringDescription = valueDescription() {
						string.append( " \( truncate( stringDescription, options ) )")
					} else if binSize >= 0 {
						string.append( " { \(binSize) bytes }")
					}
				}
		}
		return string
	}
}
