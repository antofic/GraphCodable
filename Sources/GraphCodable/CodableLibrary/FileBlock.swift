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

import Foundation

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

struct FileHeader : CustomStringConvertible, BinaryIOType {
	static var INITIAL_FILE_VERSION	: UInt32 { 0 }
	static var VALUEID_FILE_VERSION	: UInt32 { 1 }
	static var RMUNUS2_FILE_VERSION	: UInt32 { 2 }
	static var SECTION_FILE_VERSION	: UInt32 { 3 }
	static var CURRENT_FILE_VERSION	: UInt32 { SECTION_FILE_VERSION }

	var supportsValueIDs		: Bool { version >= Self.VALUEID_FILE_VERSION }
	var supportsFileSections	: Bool { version >= Self.SECTION_FILE_VERSION }

	// *******************************
	
	private enum HeaderID : UInt64 {
		case gcodable	= 0x67636F6461626C65	// ascii = 'gcodable'
	}

	let version : UInt32
	let unused0 : UInt32
	let unused1 : UInt64
	
	var description: String {
		"FILETYPE = \(HeaderID.gcodable) V\(version), U0 = \(unused0), U1 = \(unused1)"
	}
	
	init( version: UInt32 = CURRENT_FILE_VERSION, unused0: UInt32 = 0, unused1: UInt64 = 0 ) {
		self.version = version	// Self.CURRENT_FILE_VERSION
		self.unused0 = unused0
		self.unused1 = unused1
	}

	private enum ObsoleteCode : UInt8, BinaryIOType {
		case header		= 0x5E	// '^'
	}

	init(from reader: inout BinaryReader) throws {
		do {
			_ = ObsoleteCode.peek( from: &reader ) {
				$0 == .header
			}
			
			let headerID	= try HeaderID	( from: &reader )
			guard headerID == .gcodable else {
				throw GCodableError.decodingError(
					Self.self, GCodableError.Context(
						debugDescription: "Not a gcodable file."
					)
				)
			}
			
			self.version	= try UInt32	( from: &reader )
			self.unused0	= try UInt32	( from: &reader )
			self.unused1	= try UInt64	( from: &reader )
			if version < Self.RMUNUS2_FILE_VERSION {
				_	= try UInt8( from: &reader )	// removed unused2 from SECTION_FILE_VERSION
			}
		} catch( let error ) {
			throw GCodableError.invalidHeader(
				Self.self, GCodableError.Context(
					debugDescription: "Invalid gcodable header.",
					underlyingError: error
				)
			)
		}
	}

	func write(to writer: inout BinaryWriter) throws {
		try HeaderID.gcodable.write(to: &writer)
		try version.write(to: &writer)
		try unused0.write(to: &writer)
		try unused1.write(to: &writer)
	}
}

/// the body of a GCodable file is a sequence of FileBlock's
enum FileBlock {
	private enum Code : UInt8 {
		case Nil			= 0x30	// '0'
		case valueRef		= 0x25	// '%'	// No Identity
		case binValueRef	= 0x3E	// '>'	// No Identity
		case idValue		= 0x2F	// '/'	// Identity
		case idBinValue		= 0x2B	// '+'	// Identity
		case idRef			= 0x40	// '@'	// Identity
		case idBinRef		= 0x3D	// '='	// Identity
		case strongPtr		= 0x21	// '!'	// Identity
		case conditionalPtr	= 0x3F	// '?'	// Identity
		case end			= 0x2E	// '.'
	}
	///	a nil optional value or reference
	case Nil			( keyID:UIntID )
	///	store a value or reference without identity -- GCodable standard encoding/decoding
	case valueRef		( keyID:UIntID )
	///	store a value or reference without identity -- BinaryIO fast encoding/decoding
	case binValueRef	( keyID:UIntID, bytes:Bytes )
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
	enum Level { case exit, same, enter }
	var level : Level {
		switch self {
		case .valueRef:		return .enter
		case .idValue:		return .enter
		case .idRef:		return .enter
		case .end:			return .exit
		default:			return .same
		}
	}

	var keyID : UIntID? {
		switch self {
		case .Nil			( let keyID ):				return	keyID > 0 ? keyID : nil
		case .binValueRef		( let keyID, _ ):			return	keyID > 0 ? keyID : nil
		case .valueRef			( let keyID ):				return	keyID > 0 ? keyID : nil
		case .idBinValue		( let keyID, _ , _ ):		return	keyID > 0 ? keyID : nil
		case .idValue		( let keyID, _ ):			return	keyID > 0 ? keyID : nil
		case .idBinRef		( let keyID, _ , _ , _):	return	keyID > 0 ? keyID : nil
		case .idRef			( let keyID, _, _ ):		return	keyID > 0 ? keyID : nil
		case .strongPtr			( let keyID, _ ):			return	keyID > 0 ? keyID : nil
		case .conditionalPtr	( let keyID, _ ):			return	keyID > 0 ? keyID : nil
		default:											return	nil
		}
	}
}

extension FileBlock : BinaryOType {
	func write( to writer: inout BinaryWriter ) throws {
		switch self {
		case .Nil	( let keyID ):
			try Code.Nil.write(to: &writer)
			try keyID.write(to: &writer)
		case .binValueRef( let keyID, let bytes ):
			try Code.binValueRef.write(to: &writer)
			try keyID.write(to: &writer)
			try writer.writeData( bytes )
		case .valueRef	( let keyID ):
			try Code.valueRef.write(to: &writer)
			try keyID.write(to: &writer)
		case .idBinValue( let keyID,  let objID,  let bytes ):
			try Code.idBinValue.write(to: &writer)
			try keyID.write(to: &writer)
			try objID.write(to: &writer)
			try writer.writeData( bytes )
		case .idValue( let keyID, let objID ):
			try Code.idValue.write(to: &writer)
			try keyID.write(to: &writer)
			try objID.write(to: &writer)
		case .idBinRef( let keyID, let typeID, let objID,  let bytes ):
			try Code.idBinRef.write(to: &writer)
			try keyID.write(to: &writer)
			try typeID.write(to: &writer)
			try objID.write(to: &writer)
			try writer.writeData( bytes )
		case .idRef( let keyID, let typeID, let objID ):
			try Code.idRef.write(to: &writer)
			try keyID.write(to: &writer)
			try typeID.write(to: &writer)
			try objID.write(to: &writer)
		case .strongPtr( let keyID, let objID ):
			try Code.strongPtr.write(to: &writer)
			try keyID.write(to: &writer)
			try objID.write(to: &writer)
		case .conditionalPtr( let keyID, let objID ):
			try Code.conditionalPtr.write(to: &writer)
			try keyID.write(to: &writer)
			try objID.write(to: &writer)
		case .end:
			try Code.end.write(to: &writer)
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
		case .binValueRef:
			let keyID	= try UIntID		( from: &reader )
			let bytes	= try reader.readData() as Bytes
			self = .binValueRef(keyID: keyID, bytes: bytes)
		case .valueRef:
			let keyID	= try UIntID		( from: &reader )
			self = .valueRef(keyID: keyID)
		case .idBinValue:
			let keyID	= try UIntID		( from: &reader )
			let objID	= try UIntID		( from: &reader )
			let bytes	= try reader.readData() as Bytes
			self = .idBinValue(keyID: keyID, objID: objID, bytes: bytes)
		case .idValue:
			let keyID	= try UIntID		( from: &reader )
			let objID	= try UIntID		( from: &reader )
			self = .idValue(keyID: keyID, objID: objID)
		case .idBinRef:
			let keyID	= try UIntID		( from: &reader )
			let typeID	= try UIntID		( from: &reader )
			let objID	= try UIntID		( from: &reader )
			let bytes	= try reader.readData() as Bytes
			self = .idBinRef(keyID: keyID, typeID: typeID, objID: objID, bytes: bytes)
		case .idRef:
			let keyID	= try UIntID		( from: &reader )
			let typeID	= try UIntID		( from: &reader )
			let objID	= try UIntID		( from: &reader )
			self = .idRef(keyID: keyID, typeID: typeID, objID: objID)
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
		case .binValueRef( let keyID, let bytes ):
			let string : String
			if let value = binaryValue {
				string	= small( value, options )
			} else {
				string	= "BIN \(bytes.count) bytes"
			}
			return format( keyID, keyStringMap, string )
		case .valueRef	( let keyID ):
			let string	= "VAL"
			return format( keyID, keyStringMap, string )
		case .idBinValue( let keyID, let objID, let bytes ):
			let string : String
			if let value = binaryValue {
				string	= "BIN\(objID) \( small( value, options ) )"
			} else {
				string	= "BIN\(objID) \(bytes.count) bytes"
			}
			return format( keyID, keyStringMap, string )
		case .idValue( let keyID, let objID):
			let string	= "VAL\(objID)"
			return format( keyID, 		keyStringMap, string )
		case .idBinRef(keyID: let keyID, typeID: let typeID, objID: let objID, bytes: let bytes):
			let string : String
			if let value = binaryValue {
				string	= "BIN\(objID) \( objectString( typeID,options,classDataMap ) ) \( small( value, options ) )"
			} else {
				string	= "BIN\(objID) \( objectString( typeID,options,classDataMap ) ) \(bytes.count) bytes"
			}
			return format( keyID, keyStringMap, string )
		case .idRef( let keyID, let typeID, let objID ):
			let string	= "REF\(objID) \( objectString( typeID,options,classDataMap ) )"
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


