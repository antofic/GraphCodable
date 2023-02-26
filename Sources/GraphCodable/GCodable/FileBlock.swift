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

typealias UIntID = UInt32

enum FileSection : UInt16, CaseIterable, BinaryIOType {
	case body = 0x0010, classDataMap = 0x0020, keyStringMap = 0x0030
}

//	NEW FILE FORMAT:
//		A) fileHeader		= FileHeader
//		B) sectionMap		= SectionMap	= [FileSection : Range<Int>]
//		C) bodyBlocks		= BodyBlocks	= [FileBlock]
//	then, in any order:
//		D) classDataMap		= ClassDataMap	= [UIntID : ClassData]
//		E) keyStringMap		= KeyStringMap	= [UIntID : String]
//	sectionMap[section] contains the range of the related section in the file
typealias SectionMap		= [FileSection : Range<Int>]
typealias BodyBlocks		= [FileBlock]
typealias ClassDataMap		= [UIntID : ClassData]
typealias KeyStringMap		= [UIntID : String]


/// the body of a GCodable file is a sequence of FileBlock's
enum FileBlock {
	/*
	private struct IOFlags: OptionSet {
		let rawValue: UInt8
		
		init(rawValue: UInt8) {
			self.rawValue	= rawValue
		}
		
		///	show file header
		private static let	keyID			= Self( rawValue: 1 << 0 )
		private static let	typeID			= Self( rawValue: 1 << 1 )
		private static let	objID			= Self( rawValue: 1 << 2 )
		private static let	bytes			= Self( rawValue: 1 << 3 )

		static let	Nil				: Self = [ keyID ]
		static let	value			: Self = [ keyID ]
		static let	binValue		: Self = [ keyID, bytes ]
		static let	ref				: Self = [ keyID, typeID ]
		static let	binRef			: Self = [ keyID, typeID, bytes ]
		static let	idValue			: Self = [ keyID, objID ]
		static let	idBinValue		: Self = [ keyID, objID, bytes ]
		static let	idRef			: Self = [ keyID, typeID, objID ]
		static let	idBinRef		: Self = [ keyID, typeID, objID, bytes ]
		static let	strongPtr		: Self = [ keyID, objID ]
		static let	conditionalPtr	: Self = [ keyID, objID ]
		static let	end				: Self = []
	}
	*/
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
		/*
		private var code : IOFlags {
			switch self {
			case .Nil				: return IOFlags.Nil
			case .value				: return IOFlags.value
			case .binValue			: return IOFlags.binValue
			case .ref				: return IOFlags.ref
			case .binRef			: return IOFlags.binRef
			case .idValue			: return IOFlags.idValue
			case .idBinValue		: return IOFlags.idBinValue
			case .idRef				: return IOFlags.idRef
			case .idBinRef			: return IOFlags.idBinRef
			case .strongPtr			: return IOFlags.strongPtr
			case .conditionalPtr	: return IOFlags.conditionalPtr
			case .end				: return IOFlags.end
			}
		}
		*/
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
	///	end of encoding/decoding of a valueRef/idValue/idRef
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

extension FileBlock : BinaryOType {
	func write( to writer: inout BinaryWriter ) throws {
		try code.write(to: &writer)
		
		switch self {
		case .Nil	( let keyID ):
			try keyID.write(to: &writer)
		case .value	( let keyID ):
			try keyID.write(to: &writer)
		case .binValue( let keyID, let bytes ):
			try keyID.write(to: &writer)
			try writer.writeData( bytes )
		case .ref(keyID: let keyID, let typeID):
			try keyID.write(to: &writer)
			try typeID.write(to: &writer)
		case .binRef(keyID: let keyID, let typeID, bytes: let bytes):
			try keyID.write(to: &writer)
			try typeID.write(to: &writer)
			try writer.writeData( bytes )
		case .idValue( let keyID, let objID ):
			try keyID.write(to: &writer)
			try objID.write(to: &writer)
		case .idBinValue( let keyID,  let objID,  let bytes ):
			try keyID.write(to: &writer)
			try objID.write(to: &writer)
			try writer.writeData( bytes )
		case .idRef( let keyID, let typeID, let objID ):
			try keyID.write(to: &writer)
			try typeID.write(to: &writer)
			try objID.write(to: &writer)
		case .idBinRef( let keyID, let typeID, let objID,  let bytes ):
			try keyID.write(to: &writer)
			try typeID.write(to: &writer)
			try objID.write(to: &writer)
			try writer.writeData( bytes )
		case .strongPtr( let keyID, let objID ):
			try keyID.write(to: &writer)
			try objID.write(to: &writer)
		case .conditionalPtr( let keyID, let objID ):
			try keyID.write(to: &writer)
			try objID.write(to: &writer)
		case .end:
			break
		}
	}
}

extension FileBlock : BinaryIType {
	init(from reader: inout BinaryReader) throws {
		let code = try Code(from: &reader)

		switch code {
		case .Nil:
			let keyID	= try UIntID		( from: &reader )
			self = .Nil(keyID: keyID)
		case .value:
			let keyID	= try UIntID		( from: &reader )
			self = .value(keyID: keyID)
		case .binValue:
			let keyID	= try UIntID		( from: &reader )
			let bytes	= try reader.readData() as Bytes
			self = .binValue(keyID: keyID, bytes: bytes)
		case .ref:
			let keyID	= try UIntID		( from: &reader )
			let typeID	= try UIntID		( from: &reader )
			self = .ref(keyID: keyID, typeID: typeID)
		case .binRef:
			let keyID	= try UIntID		( from: &reader )
			let typeID	= try UIntID		( from: &reader )
			let bytes	= try reader.readData() as Bytes
			self = .binRef(keyID: keyID, typeID: typeID, bytes: bytes)
		case .idValue:
			let keyID	= try UIntID		( from: &reader )
			let objID	= try UIntID		( from: &reader )
			self = .idValue(keyID: keyID, objID: objID)
		case .idBinValue:
			let keyID	= try UIntID		( from: &reader )
			let objID	= try UIntID		( from: &reader )
			let bytes	= try reader.readData() as Bytes
			self = .idBinValue(keyID: keyID, objID: objID, bytes: bytes)
		case .idRef:
			let keyID	= try UIntID		( from: &reader )
			let typeID	= try UIntID		( from: &reader )
			let objID	= try UIntID		( from: &reader )
			self = .idRef(keyID: keyID, typeID: typeID, objID: objID)
		case .idBinRef:
			let keyID	= try UIntID		( from: &reader )
			let typeID	= try UIntID		( from: &reader )
			let objID	= try UIntID		( from: &reader )
			let bytes	= try reader.readData() as Bytes
			self = .idBinRef(keyID: keyID, typeID: typeID, objID: objID, bytes: bytes)
		case .strongPtr:
			let keyID	= try UIntID		( from: &reader )
			let objID	= try UIntID		( from: &reader )
			self = .strongPtr(keyID: keyID, objID: objID)
		case .conditionalPtr:
			let keyID	= try UIntID		( from: &reader )
			let objID	= try UIntID		( from: &reader )
			self = .conditionalPtr(keyID: keyID, objID: objID)
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
		options:			GraphEncoder.DumpOptions,
		binaryValue: 		BinaryOType?,
		classDataMap:		ClassDataMap?,
		keyStringMap: 		KeyStringMap?
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
		
		func small( _ value: Any, _ options:GraphEncoder.DumpOptions ) -> String {
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
		
		func objectString( _ typeID:UInt32, _ options:GraphEncoder.DumpOptions, _ classDataMap:[UIntID:ClassData]? ) -> String {
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
		
		func typeString( _ options:GraphEncoder.DumpOptions, _ classData:ClassData ) -> String {
			var string	= "\(classData.readableTypeName) V\(classData.encodeVersion)"
			if options.contains( .showMangledClassNames ) {
				string.append( "\n\t\t\tMangledName = \( classData.mangledTypeName ?? "nil" )"  )
				string.append( "\n\t\t\tNSTypeName  = \( classData.objcTypeName )"  )
			}
			return string
		}
		
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
				string	= "BIV \(bytes.count) bytes"
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
				string	= "BIR \( objectString( typeID,options,classDataMap ) ) \(bytes.count) bytes"
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
				string	= "BIV\(objID) \(bytes.count) bytes"
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
				string	= "BIR\(objID) \( objectString( typeID,options,classDataMap ) ) \(bytes.count) bytes"
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
	init(from reader: inout BinaryReader) throws {
		let code = try Code(from: &reader)

		switch code {
		case .keyStringMap:
			let keyID	= try UIntID	( from: &reader )
			let keyName	= try String	( from: &reader )
			self = .keyStringMap(keyID: keyID, keyName: keyName)
		case .classDataMap:
			let typeID	= try UIntID		( from: &reader )
			let data	= try ClassData	( from: &reader )
			self = .classDataMap(typeID: typeID, classData: data )
		}
	}
}

