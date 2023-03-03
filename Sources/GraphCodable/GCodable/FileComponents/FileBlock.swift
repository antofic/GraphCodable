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
enum FileBlock {
	private enum Code : UInt8 {
		case Nil			= 0x30	// '0'
		case value			= 0x25	// '%'	// No Identity, No Inheritance, No Binary
		case binValue		= 0x3E	// '>'	// No Identity, No Inheritance, Binary
		case ref			= 0x2A	// '*'	// No Identity, Inheritance, No Binary
		case binRef			= 0x24	// '$'	// No Identity, Inheritance
		case idValue		= 0x2F	// '/'	// Identity, No Binary
		case idBinValue		= 0x2B	// '+'	// Identity, Binary
		case idRef			= 0x40	// '@'	// Identity, Inheritance, No Binary
		case idBinRef		= 0x3D	// '='	// Identity, Inheritance, Binary
		case strongPtr		= 0x21	// '!'
		case conditionalPtr	= 0x3F	// '?'
		case end			= 0x2E	// '.'
	}
	
	
	private var code : Code {
		switch self {
		case .Nil				: return .Nil
		case .value				: return .value
		case .binValue			: return .binValue
		case .ref				: return .ref
		case .binRef			: return .binRef
		case .idValue			: return .idValue
		case .idBinValue		: return .idBinValue
		case .idRef				: return .idRef
		case .idBinRef			: return .idBinRef
		case .strongPtr			: return .strongPtr
		case .conditionalPtr	: return .conditionalPtr
		case .end				: return .end
		}
	}
	
	///	a nil optional value or reference
	case Nil			( keyID:UIntID )
	///	store a value without identity or reference without identity, inheritance -- GCodable standard encoding/decoding
	case value			( keyID:UIntID )
	///	store a value without identity or reference without identity, inheritance -- BinaryIO fast encoding/decoding
	case binValue		( keyID:UIntID, bytes:Bytes )
	///	store reference with inheritance, without identity -- GCodable standard encoding/decoding
	case ref			( keyID:UIntID, typeID:UIntID )
	///	store reference with inheritance, without identity -- BinaryIO fast encoding/decoding
	case binRef			( keyID:UIntID, typeID:UIntID, bytes:Bytes )
	///	store a value with identity -- GCodable standard encoding/decoding
	case idValue		( keyID:UIntID, objID:UIntID )
	///	store a value with identity -- BinaryIO fast encoding/decoding
	case idBinValue		( keyID:UIntID, objID:UIntID, bytes:Bytes )
	///	store a reference with identity, inheritance -- GCodable standard encoding/decoding
	case idRef			( keyID:UIntID, typeID:UIntID, objID:UIntID )
	///	store a reference with identity, inheritance -- BinaryIO fast encoding/decoding
	case idBinRef		( keyID:UIntID, typeID:UIntID, objID:UIntID, bytes:Bytes )
	///	store a string pointer to a value or reference type with identity
	case strongPtr		( keyID:UIntID, objID:UIntID )
	///	store a string pointer to a value or reference type with identity
	case conditionalPtr	( keyID:UIntID, objID:UIntID )
	///	end valueRef/idValue/idRef encoding/decoding fields
	case end
}

extension FileBlock {
	/*
	var objID : UIntID? {
		switch self {
		case .idValue			( _, let objID ):		return	objID
		case .idBinValue		( _, let objID, _ ):	return	objID
		case .idRef				( _, _, let objID ):	return	objID
		case .idBinRef			( _, _, let objID, _ ):	return	objID
		case .strongPtr			( _, let objID ):		return	objID
		case .conditionalPtr	( _, let objID ):		return	objID
		default:										return	nil
		}
	}

	var typeID : UIntID? {
		switch self {
		case .ref			( _, let typeID ):			return	typeID
		case .binRef		( _, let typeID,_ ):		return	typeID
		case .idRef			( _, let typeID,_  ):		return	typeID
		case .idBinRef		( _, let typeID,_ , _):		return	typeID
		default:										return	nil
		}
	}

	var bytes : Bytes? {
		switch self {
		case .binValue		( _, let bytes ):			return	bytes
		case .binRef		( _, _ , let bytes ):		return	bytes
		case .idBinValue	( _, _ , let bytes ):		return	bytes
		case .idBinRef		( _, _ , _ , let bytes ):	return	bytes
		default:										return	nil
		}
	}
	 */
	var keyID : UIntID? {
		switch self {
		case .Nil				( let keyID ):				return	keyID > 0 ? keyID : nil
		case .binValue			( let keyID, _ ):			return	keyID > 0 ? keyID : nil
		case .value				( let keyID ):				return	keyID > 0 ? keyID : nil
		case .binRef			( let keyID, _, _ ):		return	keyID > 0 ? keyID : nil
		case .ref				( let keyID, _ ):			return	keyID > 0 ? keyID : nil
		case .idBinValue		( let keyID, _ , _ ):		return	keyID > 0 ? keyID : nil
		case .idValue			( let keyID, _ ):			return	keyID > 0 ? keyID : nil
		case .idBinRef			( let keyID, _ , _ , _):	return	keyID > 0 ? keyID : nil
		case .idRef				( let keyID, _, _ ):		return	keyID > 0 ? keyID : nil
		case .strongPtr			( let keyID, _ ):			return	keyID > 0 ? keyID : nil
		case .conditionalPtr	( let keyID, _ ):			return	keyID > 0 ? keyID : nil
		default:											return	nil
		}
	}
}

extension FileBlock {
	enum Level { case exit, same, enter }
	var level : Level {
		switch self {
		case .value:		return .enter
		case .ref:			return .enter
		case .idValue:		return .enter
		case .idRef:		return .enter
		case .end:			return .exit
		default:			return .same
		}
	}
}

extension FileBlock {
	private struct Token : BinaryIOType {
		let code	: Code
		let keyID	: UIntID
		
		init( code : Code, keyID : UIntID = 0 ) {
			self.code	= code
			self.keyID	= keyID
		}
		
		func write(to wbuffer: inout BinaryWriteBuffer) throws {
			let rawValue	= code.rawValue
			switch code {
			case .end:
				try rawValue.write(to: &wbuffer)
			default:
				if keyID == 0 {
					try (rawValue | 0x80).write(to: &wbuffer)
				} else {
					try rawValue.write(to: &wbuffer)
					try keyID.write(to: &wbuffer)
				}
			}
		}
		
		init(from rbuffer: inout BinaryReadBuffer) throws {
			let token	= try Code.RawValue.init(from: &rbuffer)
			switch token {
			case Code.end.rawValue:
				self.code	= .end
				self.keyID	= 0
			default:
				let rawValue	= token & ~0x80
				guard let code = Code(rawValue: rawValue ) else {
					throw GCodableError.decodingError(
						Self.self, GCodableError.Context(
							debugDescription: "Invalid code rawValue \(rawValue)"
						)
					)
				}
				self.code	= code
				if (token & 0x80) == 0 {
					self.keyID	= try UIntID(from: &rbuffer)
				} else {
					self.keyID	= 0
				}
			}
		}
	}
}

extension FileBlock : BinaryOType {
	func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		switch self {
		case .Nil	( let keyID ):
			try Token(code: .Nil, keyID:keyID).write(to: &wbuffer)
		case .value	( let keyID ):
			try Token(code: .value, keyID:keyID).write(to: &wbuffer)
		case .binValue( let keyID, let bytes ):
			try Token(code: .binValue, keyID:keyID).write(to: &wbuffer)
			try wbuffer.writeData( bytes )
		case .ref(keyID: let keyID, let typeID):
			try Token(code: .ref, keyID:keyID).write(to: &wbuffer)
			try typeID.write(to: &wbuffer)
		case .binRef(keyID: let keyID, let typeID, bytes: let bytes):
			try Token(code: .binRef, keyID:keyID).write(to: &wbuffer)
			try typeID.write(to: &wbuffer)
			try wbuffer.writeData( bytes )
		case .idValue( let keyID, let objID ):
			try Token(code: .idValue, keyID:keyID).write(to: &wbuffer)
			try objID.write(to: &wbuffer)
		case .idBinValue( let keyID,  let objID,  let bytes ):
			try Token(code: .idBinValue, keyID:keyID).write(to: &wbuffer)
			try objID.write(to: &wbuffer)
			try wbuffer.writeData( bytes )
		case .idRef( let keyID, let typeID, let objID ):
			try Token(code: .idRef, keyID:keyID).write(to: &wbuffer)
			try typeID.write(to: &wbuffer)
			try objID.write(to: &wbuffer)
		case .idBinRef( let keyID, let typeID, let objID,  let bytes ):
			try Token(code: .idBinRef, keyID:keyID).write(to: &wbuffer)
			try typeID.write(to: &wbuffer)
			try objID.write(to: &wbuffer)
			try wbuffer.writeData( bytes )
		case .strongPtr( let keyID, let objID ):
			try Token(code: .strongPtr, keyID:keyID).write(to: &wbuffer)
			try objID.write(to: &wbuffer)
		case .conditionalPtr( let keyID, let objID ):
			try Token(code: .conditionalPtr, keyID:keyID).write(to: &wbuffer)
			try objID.write(to: &wbuffer)
		case .end:
			try Token(code: .end).write(to: &wbuffer)
		}
	}
}

extension FileBlock {
	init(from rbuffer: inout BinaryReadBuffer, fileHeader:FileHeader ) throws {
		let token	= try Token(from: &rbuffer)
				
		switch token.code {
		case .Nil:
			self = .Nil(keyID: token.keyID)
		case .value:
			self = .value(keyID: token.keyID)
		case .binValue:
			let bytes	= try rbuffer.readData() as Bytes
			self = .binValue(keyID: token.keyID, bytes: bytes)
		case .ref:
			let typeID	= try UIntID		( from: &rbuffer )
			self = .ref(keyID: token.keyID, typeID: typeID)
		case .binRef:
			let typeID	= try UIntID		( from: &rbuffer )
			let bytes	= try rbuffer.readData() as Bytes
			self = .binRef(keyID: token.keyID, typeID: typeID, bytes: bytes)
		case .idValue:
			let objID	= try UIntID		( from: &rbuffer )
			self = .idValue(keyID: token.keyID, objID: objID)
		case .idBinValue:
			let objID	= try UIntID		( from: &rbuffer )
			let bytes	= try rbuffer.readData() as Bytes
			self = .idBinValue(keyID: token.keyID, objID: objID, bytes: bytes)
		case .idRef:
			let typeID	= try UIntID		( from: &rbuffer )
			let objID	= try UIntID		( from: &rbuffer )
			self = .idRef(keyID: token.keyID, typeID: typeID, objID: objID)
		case .idBinRef:
			let typeID	= try UIntID		( from: &rbuffer )
			let objID	= try UIntID		( from: &rbuffer )
			let bytes	= try rbuffer.readData() as Bytes
			self = .idBinRef(keyID: token.keyID, typeID: typeID, objID: objID, bytes: bytes)
		case .strongPtr:
			let objID	= try UIntID		( from: &rbuffer )
			self = .strongPtr(keyID: token.keyID, objID: objID)
		case .conditionalPtr:
			let objID	= try UIntID		( from: &rbuffer )
			self = .conditionalPtr(keyID: token.keyID, objID: objID)
		case .end:
			self = .end
		}
	}
}

//	-------------------------------------------------
//	-- Readable output
//	-------------------------------------------------

extension FileBlock {
	func readableOutput(
		options:			GraphDumpOptions,
		binaryValue: 		BinaryOType?,
		classDataMap cdm:	ClassDataMap?,
		keyStringMap ksm: 	KeyStringMap?
		) -> String {
		func format( _ keyID:UIntID, _ keyStringMap: [UIntID:String]?, _ string:String ) -> String {
			if keyID == 0 {	// unkeyed
				return "- \(string)"
			} else if let key = keyStringMap?[keyID] {
				return "+ \"\(key)\": \(string)"
			} else {
				return "+ KEY\(keyID): \(string)"
			}
		}
		
		func small( _ value: Any, _ options:GraphDumpOptions ) -> String {
			let phase1 = String(describing: value)
			if options.contains( .noTruncation ) {
				return phase1
			} else {
				let maxLength	= 64
				let phase2	= phase1.count > maxLength ?
					phase1.prefix(maxLength).appending("…") : phase1
				
				return value is String ? "\"\(phase2)\"" : phase2
			}
		}
		
		func objectString( _ typeID:UInt32, _ options:GraphDumpOptions, _ classDataMap:[UIntID:ClassData]? ) -> String {
			if let classData	= classDataMap?[typeID] {
				if options.contains( .showReferenceVersion ) {
					return "\(classData.readableTypeName) V\(classData.encodeVersion)"
				} else {
					return classData.readableTypeName
				}
			} else {
				return "TYPE\(typeID)"
			}
		}
		/*
		func typeString( _ options:GraphDumpOptions, _ classData:ClassData ) -> String {
			var string	= "\(classData.readableTypeName) V\(classData.encodeVersion)"
			if options.contains( .showMangledClassNames ) {
				string.append( "\n\t\t\tMangledName = \( classData.mangledTypeName ?? "nil" )"  )
				string.append( "\n\t\t\tNSTypeName  = \( classData.objcTypeName )"  )
			}
			return string
		}
		*/
		let classDataMap = options.contains( .resolveTypeIDs ) ? cdm : nil
		let keyStringMap = options.contains( .resolveKeyIDs ) ? ksm : nil
			
		switch self {
		case .Nil	( let keyID ):
			return format( keyID, keyStringMap, "nil")
		case .value	( let keyID ):
			let string	= "VAL"
			return format( keyID, keyStringMap, string )
		case .binValue( let keyID, let bytes ):
			let string : String
			if let value = binaryValue {
				string	= small( value, options )
			} else {
				string	= "BIV {\(bytes.count) bytes}"
			}
			return format( keyID, keyStringMap, string )
		case .ref(keyID: let keyID, typeID: let typeID):
			let string	= "REF \( objectString( typeID,options,classDataMap ) )"
			return format( keyID, keyStringMap, string )
		case .binRef(keyID: let keyID, typeID: let typeID, bytes: let bytes):
			let string : String
			if let value = binaryValue {
				string	= "BIR \( objectString( typeID,options,classDataMap ) ) \( small( value, options ) )"
			} else {
				string	= "BIR \( objectString( typeID,options,classDataMap ) ) {\(bytes.count) bytes}"
			}
			return format( keyID, keyStringMap, string )
		case .idValue( let keyID, let objID):
			let string	= "VAL\(objID)"
			return format( keyID, 		keyStringMap, string )
		case .idBinValue( let keyID, let objID, let bytes ):
			let string : String
			if let value = binaryValue {
				string	= "BIV\(objID) \( small( value, options ) )"
			} else {
				string	= "BIV\(objID) {\(bytes.count) bytes}"
			}
			return format( keyID, keyStringMap, string )
		case .idRef( let keyID, let typeID, let objID ):
			let string	= "REF\(objID) \( objectString( typeID,options,classDataMap ) )"
			return format( keyID, keyStringMap, string )
		case .idBinRef(keyID: let keyID, typeID: let typeID, objID: let objID, bytes: let bytes):
			let string : String
			if let value = binaryValue {
				string	= "BIR\(objID) \( objectString( typeID,options,classDataMap ) ) \( small( value, options ) )"
			} else {
				string	= "BIR\(objID) \( objectString( typeID,options,classDataMap ) ) {\(bytes.count) bytes}"
			}
			return format( keyID, keyStringMap, string )
		case .strongPtr( let keyID, let objID ):
			let string	= "PTR\(objID)"
			return format( keyID, keyStringMap, string )
		case .conditionalPtr( let keyID, let objID ):
			let string	= "PTR\(objID)?"
			return format( keyID, keyStringMap, string )
		case .end:
			return 	"."
		}
	}
}

extension FileBlock : CustomStringConvertible {
	var description: String {
		return readableOutput(
			options: .readable, binaryValue: nil, classDataMap:nil, keyStringMap: nil
		)
	}
}

///	Obsolete FileBlock: mantained to read old file format
enum FileBlockObsolete {
	enum Code : UInt8 {
		case keyStringMap	= 0x2A	// '*'
		case classDataMap	= 0x24	// '$'
	}
	//	keyStringMap
	case keyStringMap( keyID:UIntID, keyName:String )
	//	classDataMap
	case classDataMap( typeID:UIntID, classData:ClassData )
}

extension FileBlockObsolete : BinaryIType {
	init(from rbuffer: inout BinaryReadBuffer) throws {
		let code = try Code(from: &rbuffer)

		switch code {
		case .keyStringMap:
			let keyID	= try UIntID	( from: &rbuffer )
			let keyName	= try String	( from: &rbuffer )
			self = .keyStringMap(keyID: keyID, keyName: keyName)
		case .classDataMap:
			let typeID	= try UIntID		( from: &rbuffer )
			let data	= try ClassData	( from: &rbuffer )
			self = .classDataMap(typeID: typeID, classData: data )
		}
	}
}

