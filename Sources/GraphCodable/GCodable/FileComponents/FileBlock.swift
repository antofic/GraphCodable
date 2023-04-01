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
		
		private static let	hasKeyID:		Self = [ b3 ]		// catNil, catVal, catPtr
		private static let	hasObjID:		Self = [ b4 ]		// catVal, catPtr
		private static let	hasTypeID:		Self = [ b5 ]		// catVal
		private static let	isBinary:		Self = [ b6 ]		// catVal
		
		private static let	conditional:	Self = hasTypeID	// conditional (!= hasObjID,hasKeyID ) may overlap hasTypeID

		private static let	ptr:			Self = [ catPtr, hasObjID ]	// ptr always has objID

		//	b2, b7	= future use
		
		enum Category {
			case End, Nil, Ptr, Val
		}
		
		var category : Category {
			get throws {
				let cat = self.intersection( Self.catMask )
				switch cat {
				case Self.catEnd:	return .End
				case Self.catNil:	return .Nil
				case Self.catPtr:	return .Ptr
				case Self.catVal:	return .Val
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
		var hasObjID		: Bool { self.contains( Self.hasObjID ) }
		var hasTypeID		: Bool { self.contains( Self.hasTypeID ) }
		var isBinary		: Bool { self.contains( Self.isBinary ) }
		var isConditional	: Bool { self.contains( Self.conditional ) }
	
		//	-----------------------------------------------------------------------
		//	keyID == nil	fileBlock is an unkeyed field of its parent value
		//	keyID != nil	fileBlock is a keyed field of its parent value
		//	objID == nil	fileBlock don't have Identity
		//	objID != nil	fileBlock have Identity
		//	typeID == nil	fileBlock don't supports inheritance (value type)
		//	typeID != nil	fileBlock supports inheritance (reference type) (*)
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
		
		static func Ptr( keyID:KeyID?, objID:ObjID, conditional:Bool ) -> Self {
			var code	= ptr
			if keyID	!= nil	{ code.formUnion( hasKeyID ) }
			if conditional 		{ code.formUnion( Self.conditional ) }
			return code
		}
		
		static func  Val( keyID:KeyID?, objID:ObjID?, typeID:TypeID?, isBinary bin:Bool ) -> Self {
			var code	= catVal
			if keyID	!= nil	{ code.formUnion( hasKeyID ) }
			if typeID	!= nil	{ code.formUnion( hasTypeID ) }
			if objID	!= nil	{ code.formUnion( hasObjID ) }
			if bin				{ code.formUnion( isBinary ) }
			return code
		}
	}
	// END
	case End
	// NIL
	case Nil( keyID:KeyID? )
	// PTS<ObjID>, PTC<ObjID>
	case Ptr( keyID:KeyID?, objID:ObjID, conditional:Bool )
	//	VAL<objID?>, BIV<objID?>, REF<objID?>, BIR<objID?>
	case Val( keyID:KeyID?, objID:ObjID?, typeID:TypeID?, binSize:BinSize? )
}


extension FileBlock {
	var keyID : KeyID? {
		switch self {
		case .Nil( let keyID ):				return	keyID
		case .Ptr( let keyID, _, _ ):		return	keyID
		case .Val( let keyID, _, _, _ ):	return	keyID
		default:							return	nil
		}
	}
/*
	var objID : ObjID? {
		switch self {
		case .Ptr( _, let objID, _ ):		return	objID
		case .Val( _, let objID, _ ):		return	objID
		default:							return	nil
		}
	}

	var typeID : TypeID? {
		switch self {
		case .Val( _, _ ,let typeID ):		return	typeID
		default:							return	nil
		}
	}

	var conditional : Bool {
		switch self {
		case .Ptr( _, _, let conditional ):	return	conditional
		default:							return	false
		}
	}
*/
	var binarySize : Int {
		switch self {
		case .Val( _, _ , _ , let binSize ):	return	binSize?.size ?? 0
			default:	return 0
		}
	}
}

extension FileBlock {
	enum Level { case exit, same, enter }
	var level : Level {
		switch self {
		case .Val( _, _ , _ , let size ):	return	size != nil ? .same : .enter
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
		keyID:KeyID?, objID:ObjID, conditional:Bool,
		to encoder: inout BinaryIOEncoder, fileHeader:FileHeader
	) throws {
		try encoder.encode( Code.Ptr(keyID: keyID, objID: objID, conditional:conditional ) )
		if let keyID 	{ try encoder.encode( keyID ) }
		try encoder.encode( objID )
	}
	
	static func writeVal(
		keyID:KeyID?, objID:ObjID?, typeID:TypeID?, binaryValue:BEncodable?,
		to encoder: inout BinaryIOEncoder, fileHeader:FileHeader
	) throws {
		try encoder.encode( Code.Val(keyID: keyID, objID: objID, typeID: typeID, isBinary: binaryValue != nil ) )
		if let keyID	{ try encoder.encode( keyID ) }
		if let objID	{ try encoder.encode( objID ) }
		if let typeID	{ try encoder.encode( typeID ) }
		if let binaryValue {
			if fileHeader.flags.contains( .useBinaryIOInsert ) {
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
					dummyEncode: { encoder in
						let savePack = encoder.packIntegers
						defer { encoder.packIntegers = savePack }
						encoder.packIntegers	= false
						try encoder.encode( BinSize() )
					},
					thenEncode: { encoder in
						try encoder.encode( binaryValue )
					},
					thenOverwriteDummy: { encoder, size in
						let savePack = encoder.packIntegers
						defer { encoder.packIntegers = savePack }
						encoder.packIntegers	= false
						try encoder.encode( BinSize( size ) )
					}
				)
			}
		}
	}
}

extension FileBlock {
	init(from decoder: inout BinaryIODecoder, fileHeader:FileHeader ) throws {
		let code	= try Code(from: &decoder)
		
		switch try code.category {
			case .End:
				self			= .End
			case .Nil:
				let keyID		= code.hasKeyID ? try KeyID(from: &decoder) : nil
				self			= .Nil(keyID: keyID)
			case .Ptr:
				let keyID		= code.hasKeyID	? try KeyID(from: &decoder) : nil
				let objID		= try ObjID(from: &decoder)
				self			= .Ptr( keyID: keyID, objID: objID, conditional: code.isConditional )
			case .Val:
				let keyID		= code.hasKeyID	 ?	try KeyID(from: &decoder)  : nil
				let objID		= code.hasObjID	 ?	try ObjID(from: &decoder)  : nil
				let typeID		= code.hasTypeID ?	try TypeID(from: &decoder) : nil
				let binSize		: BinSize?
				if code.isBinary {
					if fileHeader.flags.contains( .useBinaryIOInsert ) {
						binSize	= try BinSize(from: &decoder)
					} else {
						let savePack = decoder.packIntegers
						defer { decoder.packIntegers = savePack }
						decoder.packIntegers	= false
						binSize	= try BinSize(from: &decoder)
					}
				} else {
					binSize		= nil
				}
				self 			= .Val( keyID: keyID, objID: objID, typeID: typeID, binSize: binSize )
		}
	}
}

extension FileBlock : CustomStringConvertible {
	var description: String {
		description(options: .readable, binaryValue: nil, classDataMap: nil, keyStringMap: nil)
	}
	
	func description(
		options:			GraphDumpOptions,
		binaryValue: 		BEncodable?,
		classDataMap cdm:	ClassDataMap?,
		keyStringMap ksm: 	KeyStringMap?
	) -> String {
		func typeName( _ typeID:TypeID, _ options:GraphDumpOptions, _ classDataMap:ClassDataMap? ) -> String {
			if let classData	= classDataMap?[typeID] {
				if options.contains( .showClassVersionsInBody ) {
					return "\(classData.qualifiedName) V\(classData.encodedClassVersion)"
				} else {
					return classData.qualifiedName
				}
			} else {
				return "TYPE\(typeID)"
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
		case .Ptr( let keyID, let objID, let conditional ):
			string.append( keyName( keyID, keyStringMap ) )
			string.append( conditional ? "PTC" : "PTS" )
			string.append( objID.description )
		case .Val( let keyID, let objID, let typeID, let binSize ):
			//	VAL			= []
			//	BIV			= [bytes]
			//	REF			= [typeID]
			//	BIR			= [typeID,bytes]
			//	VAL<objID>	= [objID]
			//	BIV<objID>	= [objID,bytes]
			//	REF<objID>	= [objID,typeID]
			//	BIR<objID>	= [objID,typeID,bytes]

			string.append( keyName( keyID, keyStringMap ) )
			switch (typeID != nil, binSize != nil ) {
			case (false, false)	: string.append( "VAL" )	//	Codable value
			case (false, true)	: string.append( "BIV" )	//	BinaryCodable value
			case (true,  false)	: string.append( "REF" )	//	Codable reference
			case (true,  true)	: string.append( "BIR" )	//	BinaryCodable reference
			}
			if let objID	{ string.append( objID.description ) }
			if let typeID	{ string.append( " \( typeName( typeID,options,classDataMap ) )") }
			if let binSize {
				if let binaryValue {
					string.append( " \( small( binaryValue, options ) )")
				} else if binSize != BinSize() {
					string.append( " { \(binSize.size) bytes }")
				}
			}
		}
		return string
	}
}

