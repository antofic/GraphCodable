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

/*
BINARY FILE FORMAT:
••••••PHASE 1: Header	// only one!
···code·|·Header···                              code = .header
······0·|·1········|·2···········|·3······|·4······
••••••PHASE 2: Types table
···code·|·typeID···|·classData                   code = .referenceMap
••••••PHASE 3: Bodycode =
···code·|·keyID                                  code = .nilValue
···code·|·keyID····|·VALUE                       code = .native( _ nativeCode:NativeCode )
···code·|·keyID····|·[UInt8]                     code = .binaryType
···code·|·keyID                                  code = .valueType
···code·|·keyID····|·typeID······|·objID         code = .objectType
···code·|·keyID····|·typeID······|·objID         code = .objectSPtr (STRONG POINTER)
···code·|·keyID····|·objID                       code = .objectWPtr (WEAK POINTER)
···code                                          code = .end
••••••PHASE 4: Keys table
···code·|·keyID·|·keyName                        code = .keyMap

Note:
Struct, Object open a new level, end closes it
keyID = 0 -> unkeyed
*/

typealias IntID	= UInt32

struct FileHeader : CustomStringConvertible, BinaryIOType, Codable {
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
	
	init( version: UInt32, unused0: UInt32 = 0, unused1: UInt64 = 0 ) {
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




enum FileBlock: Codable {
	private enum Code : UInt8 {
		case referenceMap	= 0x24	// '$'
		case nilValue		= 0x30	// '0'
		case binaryData		= 0x3E	// '>'	// No Identity
		case valueType		= 0x25	// '%'	// No Identity
		case iBinaryData	= 0x2B	// '+'	// Identity
		case iValueType		= 0x2F	// '/'	// Identity
		case referenceType	= 0x40	// '@'	// Identity
		case strongPtr		= 0x21	// '!'	// Identity
		case conditionalPtr	= 0x3F	// '?'	// Identity
		case end			= 0x2E	// '.'
		case keyMap			= 0x2A	// '*'
	}
	//	body
	//	without Identity
	case nilValue		( keyID:IntID )
	case binaryData		( keyID:IntID, bytes:Bytes )						// binary
	case valueType		( keyID:IntID )										// value type without identity
	//	with Identity
	case iBinaryData	( keyID:IntID, objID:IntID, bytes:Bytes )			// binary
	case iValueType		( keyID:IntID, objID:IntID )						// value type with identity (iValue)
	case referenceType	( keyID:IntID, typeID:IntID, objID:IntID )			// reference Type
	case strongPtr		( keyID:IntID, objID:IntID )						// strong pointer to iValue/reference
	case conditionalPtr	( keyID:IntID, objID:IntID )						// conditional pointer to iValue/reference
	
	case end
	//	keyMap
	case keyMap			( keyID:IntID, keyName:String )	
	//	referenceMap
	case referenceMap	( typeID:IntID, classData:ClassData )
}

extension FileBlock {
	enum Section : UInt16, CaseIterable, BinaryIOType, Codable {
		case body = 100, keyMap = 200, referenceMap = 300
	}
	
	var section : Section {
		switch self {
		case .referenceMap:	return .referenceMap
		case .keyMap:		return .keyMap
		default:			return .body
		}
	}

	enum Level { case exit, same, enter }
	var level : Level {
		switch self {
		case .valueType:		return .enter
		case .iValueType:		return .enter
		case .referenceType:	return .enter
		case .end:				return .exit
		default:				return .same
		}
	}

	var keyID : IntID? {
		switch self {
		case .nilValue			( let keyID ):			return	keyID > 0 ? keyID : nil
		case .binaryData		( let keyID, _ ):		return	keyID > 0 ? keyID : nil
		case .valueType			( let keyID ):			return	keyID > 0 ? keyID : nil
		case .iBinaryData		( let keyID, _ , _ ):	return	keyID > 0 ? keyID : nil
		case .iValueType		( let keyID, _ ):		return	keyID > 0 ? keyID : nil
		case .referenceType		( let keyID, _, _ ):	return	keyID > 0 ? keyID : nil
		case .strongPtr			( let keyID, _ ):		return	keyID > 0 ? keyID : nil
		case .conditionalPtr	( let keyID, _ ):		return	keyID > 0 ? keyID : nil
		default:										return	nil
		}
	}
}

extension FileBlock : BinaryIOType {
	func write( to writer: inout BinaryWriter ) throws {
		switch self {
		case .nilValue	( let keyID ):
			try Code.nilValue.write(to: &writer)
			try keyID.write(to: &writer)
		case .binaryData( let keyID, let bytes ):
			try Code.binaryData.write(to: &writer)	// <----- ••••••
			try keyID.write(to: &writer)
			try writer.writeData( bytes )
		case .valueType	( let keyID ):
			try Code.valueType.write(to: &writer)
			try keyID.write(to: &writer)
		case .iBinaryData( let keyID,  let objID,  let bytes ):
			try Code.iBinaryData.write(to: &writer)	// <----- ••••••
			try keyID.write(to: &writer)
			try objID.write(to: &writer)
			try writer.writeData( bytes )
		case .iValueType( let keyID, let objID ):
			try Code.iValueType.write(to: &writer)
			try keyID.write(to: &writer)
			try objID.write(to: &writer)
		case .referenceType( let keyID, let typeID, let objID ):
			try Code.referenceType.write(to: &writer)
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
		case .keyMap	( let keyID, let keyName ):
			try Code.keyMap.write(to: &writer)
			try keyID.write(to: &writer)
			try keyName.write(to: &writer)
		case .referenceMap( let typeID, let classData ):
			try Code.referenceMap.write(to: &writer)
			try typeID.write(to: &writer)
			try classData.write(to: &writer)
		}
	}

	init(from reader: inout BinaryReader) throws {
		let code = try Code(from: &reader)

		switch code {
		case .nilValue:
			let keyID	= try IntID		( from: &reader )
			self = .nilValue(keyID: keyID)
		case .binaryData:
			let keyID	= try IntID		( from: &reader )
			let bytes	= try reader.readData() as Bytes
			self = .binaryData(keyID: keyID, bytes: bytes)
		case .valueType:
			let keyID	= try IntID		( from: &reader )
			self = .valueType(keyID: keyID)
		case .iBinaryData:
			let keyID	= try IntID		( from: &reader )
			let objID	= try IntID		( from: &reader )
			let bytes	= try reader.readData() as Bytes
			self = .iBinaryData(keyID: keyID, objID: objID, bytes: bytes)
		case .iValueType:
			let keyID	= try IntID		( from: &reader )
			let objID	= try IntID		( from: &reader )
			self = .iValueType(keyID: keyID, objID: objID)
		case .referenceType:
			let keyID	= try IntID		( from: &reader )
			let typeID	= try IntID		( from: &reader )
			let objID	= try IntID		( from: &reader )
			self = .referenceType(keyID: keyID, typeID: typeID, objID: objID)
		case .strongPtr:
			let keyID	= try IntID		( from: &reader )
			let objID	= try IntID		( from: &reader )
			self = .strongPtr(keyID: keyID, objID: objID)
		case .conditionalPtr:
			let keyID	= try IntID		( from: &reader )
			let objID	= try IntID		( from: &reader )
			self = .conditionalPtr(keyID: keyID, objID: objID)
		case .end:
			self = .end
		case .keyMap:
			let keyID	= try IntID		( from: &reader )
			let keyName	= try String	( from: &reader )
			self = .keyMap(keyID: keyID, keyName: keyName)
		case .referenceMap:
			let typeID	= try IntID		( from: &reader )
			let data	= try ClassData	( from: &reader )
			self = .referenceMap(typeID: typeID, classData: data )
		}
	}
}

//	-------------------------------------------------
//	-- Readable output
//	-------------------------------------------------

extension FileBlock {
	func readableOutput(
		options:			GraphEncoder.DumpOptions,
		binaryValue: 		BinaryIOType?,
		classDataMap:		[IntID:ClassData]?,
		keyIDtoKey: 		[IntID:String]?
		) -> String {
		func format( _ keyID:IntID, _ keyIDtoKey: [IntID:String]?, _ string:String ) -> String {
			if keyID == 0 {	// unkeyed
				return "- \(string)"
			} else if let key = keyIDtoKey?[keyID] {
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
		
		func objectString( _ typeID:UInt32, _ options:GraphEncoder.DumpOptions, _ classDataMap:[IntID:ClassData]? ) -> String {
			if let classData	= classDataMap?[typeID] {
				if options.contains( .showTypeVersion ) {
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
		case .nilValue	( let keyID ):
			return format( keyID, keyIDtoKey, "nil")
		case .binaryData( let keyID, let bytes ):
			let string : String
			if let value = binaryValue {
				string	= small( value, options )
			} else {
				string	= "BIN \(bytes.count) bytes"
			}
			return format( keyID, keyIDtoKey, string )
		case .valueType	( let keyID ):
			let string	= "VAL"
			return format( keyID, keyIDtoKey, string )
		case .iBinaryData( let keyID, let objID, let bytes ):
			let string : String
			if let value = binaryValue {
				string	= "BIN\(objID) \( small( value, options ) )"
			} else {
				string	= "BIN\(objID) \(bytes.count) bytes"
			}
			return format( keyID, keyIDtoKey, string )
		case .iValueType( let keyID, let objID):
			let string	= "VAL\(objID)"
			return format( keyID, keyIDtoKey, string )
		case .referenceType( let keyID, let typeID, let objID ):
			let string	= "REF\(objID) \( objectString( typeID,options,classDataMap ) )"
			return format( keyID, keyIDtoKey, string )
		case .strongPtr( let keyID, let objID ):
			let string	= "PTR\(objID)"
			return format( keyID, keyIDtoKey, string )
		case .conditionalPtr( let keyID, let objID ):
			let string	= "PTR\(objID)?"
			return format( keyID, keyIDtoKey, string )
		case .end:
			return 	"."
		case .keyMap	( let keyID, let keyName ):
			return "KEY\( keyID ):\t\"\( keyName )\""
		case .referenceMap	( let typeID, let classData ):
			return	"TYPE\( typeID ):\t\( typeString( options, classData ) )"
		}
	}
}

extension FileBlock : CustomStringConvertible {
	var description: String {
		return readableOutput(
			options: .readable, binaryValue: nil, classDataMap:nil, keyIDtoKey: nil
		)
	}
}

struct SwiftCodableFile : Codable {
	let fileHeader	: FileHeader
	let blockMap	: [FileBlock.Section : [FileBlock]]
}
