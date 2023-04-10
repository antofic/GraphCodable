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


/// the body of a GCodable file is a sequence of FileBlock's
enum FileBlock {	// size = 32 bytes
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
		private static let	catEnd:			Self = []
		private static let	catNil:			Self = [ b0 ]
		private static let	catPtr:			Self = [ b1 ]
		private static let	catVal:			Self = [ b1, b0 ]
		private static let	catBin:			Self = [ b2 ]

		private static let	hasKeyID:		Self = [ b3 ]		// catNil, catVal, catBin, catPtr
		private static let	hasIdnID:		Self = [ b4 ]		// catVal, catBin, catPtr
		private static let	hasRefID:		Self = [ b5 ]		// catVal
//		private static let	isBinary:		Self = [ b6 ]		// catVal
		
		private static let	conditional:	Self = hasRefID	// conditional (!= hasIdnID,hasKeyID ) may overlap hasRefID

		private static let	ptr:			Self = [ catPtr, hasIdnID ]	// ptr always has idnID

		//	b2, b7	= future use
		
		enum Category {
			case End, Nil, Ptr, Val, Bin
		}
		
		var category : Category {
			get throws {
				let cat = self.intersection( Self.catMask )
				switch cat {
				case Self.catEnd:	return .End
				case Self.catNil:	return .Nil
				case Self.catPtr:	return .Ptr
				case Self.catVal:	return .Val
				case Self.catBin:	return .Bin
				default:
					throw GraphCodableError.malformedArchive(
						Self.self, GraphCodableError.Context(
							debugDescription: "Unknown code category \(cat)."
						)
					)
				}
			}
		}
		
		var hasKeyID		: Bool { self.contains( Self.hasKeyID ) }
		var hasIdnID		: Bool { self.contains( Self.hasIdnID ) }
		var hasRefID		: Bool { self.contains( Self.hasRefID ) }
		var isConditional	: Bool { self.contains( Self.conditional ) }
//		var isBinary		: Bool { self.contains( Self.isBinary ) }

		//	-----------------------------------------------------------------------
		//	keyID == nil	fileBlock is an unkeyed field of its parent value
		//	keyID != nil	fileBlock is a keyed field of its parent value
		//	idnID == nil	fileBlock don't have Identity
		//	idnID != nil	fileBlock have Identity
		//	refID == nil	fileBlock don't supports inheritance (value type)
		//	refID != nil	fileBlock supports inheritance (reference type) (*)
		//
		//	(*) a reference can disable inheritance with the GClassName protocol
		//	(*) inheritance can be disabled globally with a GraphEncoder option
		//	-----------------------------------------------------------------------

		static func End() -> Self {
			return catEnd
		}

		static func Nil( keyID:KeyID? ) -> Self {
			var code	= catNil
			if keyID	!= nil { code.formUnion( hasKeyID ) }
			return code
		}
		
		static func Ptr( keyID:KeyID?, idnID:IdnID, conditional:Bool ) -> Self {
			var code	= ptr
			if keyID	!= nil	{ code.formUnion( hasKeyID ) }
			if conditional 		{ code.formUnion( Self.conditional ) }
			return code
		}
		
		static func  Val( keyID:KeyID?, idnID:IdnID?, refID:RefID? ) -> Self {
			var code	= catVal
			if keyID	!= nil	{ code.formUnion( hasKeyID ) }
			if refID	!= nil	{ code.formUnion( hasRefID ) }
			if idnID	!= nil	{ code.formUnion( hasIdnID ) }
			return code
		}

		static func  Bin( keyID:KeyID?, idnID:IdnID?, refID:RefID? ) -> Self {
			var code	= catBin
			if keyID	!= nil	{ code.formUnion( hasKeyID ) }
			if refID	!= nil	{ code.formUnion( hasRefID ) }
			if idnID	!= nil	{ code.formUnion( hasIdnID ) }
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
	case Bin( keyID:KeyID?, idnID:IdnID?, refID:RefID?, binSize:BinSize )
}


extension FileBlock {
	var keyID : KeyID? {
		switch self {
		case .Nil( let keyID ):				return	keyID
		case .Ptr( let keyID, _, _ ):		return	keyID
		case .Val( let keyID, _, _ ):		return	keyID
		case .Bin( let keyID, _, _, _ ):	return	keyID
		default:							return	nil
		}
	}

	var binarySize : Int {
		switch self {
		case .Bin( _, _ , _ , let binSize ):	return	binSize.size
			default:	return 0
		}
	}
}

extension FileBlock {
	enum Level { case exit, same, enter }
	var level : Level {
		switch self {
		case .Val( _, _ , _ ):	return .enter
		case .End:	return .exit
		default:	return .same
		}
	}
}

extension FileBlock {
	static func writeEnd(
		to encoder: inout BinaryIOEncoder, fileHeader:FileHeader
	) throws {
		try encoder.encode( Code.End() )
	}

	static func writeNil(
		keyID:KeyID?,
		to encoder: inout BinaryIOEncoder, fileHeader:FileHeader
	) throws {
		try encoder.encode( Code.Nil(keyID: keyID) )
		if let keyID 	{ try encoder.encode( keyID ) }
	}

	static func writePtr(
		keyID:KeyID?, idnID:IdnID, conditional:Bool,
		to encoder: inout BinaryIOEncoder, fileHeader:FileHeader
	) throws {
		try encoder.encode( Code.Ptr(keyID: keyID, idnID: idnID, conditional:conditional ) )
		if let keyID 	{ try encoder.encode( keyID ) }
		try encoder.encode( idnID )
	}
	
	static func writeVal(
		keyID:KeyID?, idnID:IdnID?, refID:RefID?,
		to encoder: inout BinaryIOEncoder, fileHeader:FileHeader
	) throws {
		try encoder.encode( Code.Val(keyID: keyID, idnID: idnID, refID: refID ) )
		if let keyID	{ try encoder.encode( keyID ) }
		if let idnID	{ try encoder.encode( idnID ) }
		if let refID	{ try encoder.encode( refID ) }
	}
	
	static func writeBin<T:BEncodable>(
		keyID:KeyID?, idnID:IdnID?, refID:RefID?, binaryValue: T,
		to encoder: inout BinaryIOEncoder, fileHeader:FileHeader
	) throws {
		try encoder.encode( Code.Bin(keyID: keyID, idnID: idnID, refID: refID ) )
		if let keyID	{ try encoder.encode( keyID ) }
		if let idnID	{ try encoder.encode( idnID ) }
		if let refID	{ try encoder.encode( refID ) }
		if fileHeader.gcoadableFlags.contains( .useBinaryIOInsert ) {
			//	allows slightly reducing the file size by packing BinSize but
			//	involves shifting a possibly large binSize.size amount of data
			//	by a small offset (1-2-3-4-5 bytes). As much as it doesn't seem
			//	to reduce performance I don't like it.
			try encoder.insert(
				firstEncode: 		{ try $0.encode( binaryValue ) },
				thenInsertInFront:	{ try $0.encode( BinSize( $1 ) ) }
			)
		} else {
			//	we write a bogus binSize = BinSize(), write the data and when
			//	we know their size we update binSize. BinSize must have a known
			//	size, so we can't allow BinaryIO to pack BinSize.
			//	Result: slightly larger files.
			try encoder.prepend(
				dummyEncode: 		{ try $0.encode( BinSize() ) },
				thenEncode: 		{ try $0.encode( binaryValue ) },
				thenOverwriteDummy:	{ try $0.encode( BinSize( $1 ) ) }
			)
		}
	}
}

extension FileBlock {
	init(from decoder: inout BinaryIODecoder, fileHeader:FileHeader ) throws {
		func decodeBinSize( _ decoder: inout BinaryIODecoder ) throws -> BinSize {
			if fileHeader.gcoadableFlags.contains( .useBinaryIOInsert ) {
				return try decoder.decode()
			} else {
				return try decoder.withCompressionDisabled {
					try $0.decode()
				}
			}
		}
		
		let code	= try decoder.decode() as Code
		
		switch try code.category {
			case .End:
				self			= .End
			case .Nil:
				let keyID		= code.hasKeyID ? try decoder.decode() as KeyID : nil
				self			= .Nil(keyID: keyID)
			case .Ptr:
				let keyID		= code.hasKeyID	? try decoder.decode() as KeyID : nil
				let idnID		= try decoder.decode() as IdnID
				self			= .Ptr( keyID: keyID, idnID: idnID, conditional: code.isConditional )
			case .Val:
				let keyID		= code.hasKeyID	 ?	try decoder.decode() as KeyID  : nil
				let idnID		= code.hasIdnID	 ?	try decoder.decode() as IdnID  : nil
				let refID		= code.hasRefID ?	try decoder.decode() as RefID : nil
				self 			= .Val( keyID: keyID, idnID: idnID, refID: refID )
			case .Bin:
				let keyID		= code.hasKeyID	 ?	try decoder.decode() as KeyID  : nil
				let idnID		= code.hasIdnID	 ?	try decoder.decode() as IdnID  : nil
				let refID		= code.hasRefID ?	try decoder.decode() as RefID : nil
				let binSize		= try decodeBinSize( &decoder )
				self 			= .Bin( keyID: keyID, idnID: idnID, refID: refID, binSize: binSize )
		}
	}
}

extension FileBlock : CustomStringConvertible {
	var description: String {
		description(options: .readable, binaryValue: nil, classDataMap: nil, keyStringMap: nil)
	}
	
	func description(
		options:			GraphDumpOptions,
		binaryValue: 		(any BEncodable)?,
		classDataMap cdm:	ClassDataMap?,
		keyStringMap ksm: 	KeyStringMap?
	) -> String {
		func typeName( _ refID:RefID, _ options:GraphDumpOptions, _ classDataMap:ClassDataMap? ) -> String {
			if let classData	= classDataMap?[refID] {
				if options.contains( .showClassVersionsInBody ) {
					return "\(classData.qualifiedName) V\(classData.encodedClassVersion)"
				} else {
					return classData.qualifiedName
				}
			} else {
				return "TYPE\(refID)"
			}
		}
		
		func small( _ value: Any, _ options:GraphDumpOptions, maxLength:Int = 64 ) -> String {
			let phase1 = String(describing: value)
			if options.contains( .dontTruncateValueDescriptionInBody ) {
				return phase1
			} else {
				let phase2	= phase1.count > maxLength ?
				phase1.prefix(maxLength).appending("…") : phase1
				
				return value is String ? "\"\(phase2)\"" : phase2
			}
		}
		
		func keyName( _ keyID:KeyID?, _ keyStringMap: KeyStringMap? ) -> String {
			if let keyID {
				if let key = keyStringMap?[keyID] {
					return "+ \"\(key)\": "
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
				if let refID	{ string.append( " \( typeName( refID,options,classDataMap ) )") }
			case .Bin( let keyID, let idnID, let refID, let binSize ):
				//	BIV			= [bytes]
				//	BIR			= [refID,bytes]
				//	BIV<idnID>	= [idnID,bytes]
				//	BIR<idnID>	= [idnID,refID,bytes]
				string.append( keyName( keyID, keyStringMap ) )
				string.append( refID != nil ? "BIR" : "BIV" )
				if let idnID	{ string.append( idnID.description ) }
				if let refID	{ string.append( " \( typeName( refID,options,classDataMap ) )") }
				if let binaryValue {
					string.append( " \( small( binaryValue, options ) )")
				} else if binSize != BinSize() {
					string.append( " { \(binSize.size) bytes }")
				}
		}
		return string
	}
}

