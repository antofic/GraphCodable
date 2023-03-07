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
	private struct Code: OptionSet {
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
		private static let	hasBytes:		Self = [ b6 ]		// catVal
		
		private static let	conditional:	Self = hasTypeID	// conditional (!= hasObjID,hasKeyID )
		
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
					throw GCodableError.decodingError(
						Self.self, GCodableError.Context(
							debugDescription: "Unknown code category \(cat)"
						)
					)
				}
			}
		}
		
		var hasKeyID		: Bool { self.contains( Self.hasKeyID ) }
		var hasObjID		: Bool { self.contains( Self.hasObjID ) }
		var hasTypeID		: Bool { self.contains( Self.hasTypeID ) }
		var hasBytes		: Bool { self.contains( Self.hasBytes ) }
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
			var code	= catPtr.union( hasObjID )
			if keyID	!= nil { code.formUnion( hasKeyID ) }
			if conditional { code.formUnion( Self.conditional ) }
			return code
		}
		
		static func  Val( keyID:KeyID?, objID:ObjID?, typeID:TypeID?, bytes:Bytes? ) -> Self {
			var code	= catVal
			if keyID	!= nil { code.formUnion( hasKeyID ) }
			if typeID	!= nil { code.formUnion( hasTypeID ) }
			if objID	!= nil { code.formUnion( hasObjID ) }
			if bytes	!= nil { code.formUnion( hasBytes ) }
			return code
		}
	}
	
	case End
	case Nil( keyID:KeyID? )
	case Ptr( keyID:KeyID?, objID:ObjID, conditional:Bool )
	case Val( keyID:KeyID?, objID:ObjID?, typeID:TypeID?, bytes:Bytes? )
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
		case .Val( _, let objID, _,  _ ):	return	objID
		default:							return	nil
		}
	}

	var typeID : TypeID? {
		switch self {
		case .Val( _, _ ,let typeID, _):	return	typeID
		default:							return	nil
		}
	}

	var bytes : Bytes? {
		switch self {
		case .Val( _, _ , _ , let bytes ):	return	bytes
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
}

extension FileBlock {
	enum Level { case exit, same, enter }
	var level : Level {
		switch self {
		case .Val( _, _ , _ , let bytes ):	return	bytes == nil ? .enter : .same
		case .End:	return .exit
		default:	return .same
		}
	}
}

extension FileBlock {
	func write( to wbuffer: inout BinaryWriteBuffer, fileHeader:FileHeader ) throws {
		switch self {
		case .End:
			try Code.End().write(to: &wbuffer)
		case .Nil( let keyID ):
			try Code.Nil(keyID: keyID).write(to: &wbuffer)
			try keyID?.write(to: &wbuffer)
		case .Ptr( let keyID, let objID, let conditional ):
			try Code.Ptr(keyID: keyID, objID: objID, conditional:conditional ).write(to: &wbuffer)
			try keyID?.write(to: &wbuffer)
			try objID.write(to: &wbuffer)
		case .Val( let keyID,let objID,  let typeID, let bytes ):
			try Code.Val(keyID: keyID, objID: objID, typeID: typeID, bytes: bytes).write(to: &wbuffer)
			try keyID?.write(to: &wbuffer)
			try objID?.write(to: &wbuffer)
			try typeID?.write(to: &wbuffer)
			if let bytes	{ try bytes.write(to: &wbuffer) }
		}
	}
}

extension FileBlock {
	init(from rbuffer: inout BinaryReadBuffer, fileHeader:FileHeader ) throws {
		let code	= try Code(from: &rbuffer)
		
		switch try code.category {
		case .End:
			self	= .End
		case .Nil:
			let keyID	= code.hasKeyID ? try KeyID(from: &rbuffer) : nil
			self = .Nil(keyID: keyID)
		case .Ptr:
			let keyID	= code.hasKeyID	? try KeyID(from: &rbuffer) : nil
			let objID	= try ObjID(from: &rbuffer)
			self = .Ptr( keyID: keyID, objID: objID, conditional: code.isConditional )
		case .Val:
			let keyID	= code.hasKeyID	?	try KeyID(from: &rbuffer) : nil
			let objID	= code.hasObjID	?	try ObjID(from: &rbuffer) : nil
			let typeID	= code.hasTypeID ?	try TypeID(from: &rbuffer) : nil
			let bytes	= code.hasBytes	?	try Bytes(from: &rbuffer) : nil
			self = .Val( keyID: keyID, objID: objID, typeID: typeID, bytes: bytes )
		}
	}
}

extension FileBlock : CustomStringConvertible {
	var description: String {
		description(options: .readable, binaryValue: nil, classDataMap: nil, keyStringMap: nil)
	}
	
	func description(
		options:			GraphDumpOptions,
		binaryValue: 		BinaryOType?,
		classDataMap cdm:	ClassDataMap?,
		keyStringMap ksm: 	KeyStringMap?
	) -> String {
		func typeName( _ typeID:TypeID, _ options:GraphDumpOptions, _ classDataMap:ClassDataMap? ) -> String {
			if let classData	= classDataMap?[typeID] {
				if options.contains( .showReferenceVersion ) {
					return "\(classData.readableTypeName) V\(classData.encodeVersion)"
				} else {
					return classData.readableTypeName
				}
			} else {
				return "TYPE\(typeID.id.format("04"))"
			}
		}

		func small( _ value: Any, _ options:GraphDumpOptions, maxLength:Int = 64 ) -> String {
			let phase1 = String(describing: value)
			if options.contains( .noTruncation ) {
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
					return "+ KEY\(keyID.id.format("04")): "
				}
			} else {
				return "- "
			}
		}
		
		let classDataMap = options.contains( .resolveTypeIDs ) ? cdm : nil
		let keyStringMap = options.contains( .resolveKeyIDs ) ? ksm : nil
		
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
			string.append( objID.id.format("04") )
		case .Val( let keyID, let objID, let typeID, let bytes ):
			//	VAL			= []
			//	BIV			= [bytes]
			//	REF			= [typeID]
			//	BIR			= [typeID,bytes]
			//	VAL_objID	= [objID]
			//	BIV_objID	= [objID,bytes]
			//	REF_objID	= [objID,typeID]
			//	BIR_objID	= [objID,typeID,bytes]

			string.append( keyName( keyID, keyStringMap ) )
			switch (typeID != nil,bytes != nil) {
			case (false, false)	: string.append( "VAL" )	//	Codable value
			case (false, true)	: string.append( "BIV" )	//	BinaryCodable value
			case (true,  false)	: string.append( "REF" )	//	Codable reference
			case (true,  true)	: string.append( "BIR" )	//	BinaryCodable reference
			}
			if let objID	{ string.append( objID.id.format("04") ) }
			if let typeID	{ string.append( " \( typeName( typeID,options,classDataMap ) )") }
			if let bytes {
				if let binaryValue	{ string.append( " \( small( binaryValue, options ) )") }
				else				{ string.append( " {\(bytes.count) bytes}") }
			}
		}
		return string
	}
}

