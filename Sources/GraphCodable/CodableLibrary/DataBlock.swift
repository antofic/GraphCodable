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
···code·|·HeaderID·|·Version·|·Unused0·|·Unused1|·Unused2      code = .header
······0·|·1········|·2···········|·3······|·4······
••••••PHASE 2: Types table
···code·|·typeID···|·classData                   code = .typeMap
••••••PHASE 3: Graphcode =
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
Module = mainModuleName
Struct, Object open a new level, end closes it
keyID = 0 -> unkeyed
*/

typealias IntID	= UInt32

enum DataBlock {
	private enum Code : UInt8 {
		case header		= 0x5E	// '^'
		case inTypeMap	= 0x23	// '#'
		case outTypeMap	= 0x24	// '$'
		case nilValue	= 0x30	// '0'
		case inBinType	= 0x3C	// '<'
		case outBinType	= 0x3E	// '>'
		case valueType	= 0x25	// '%'
		case objectType	= 0x40	// '@'
		case objectSPtr	= 0x21	// '!'
		case objectWPtr	= 0x3F	// '?'
		case end		= 0x2E	// '.'
		case keyMap		= 0x2A	// '*'
	}
	
	private enum HeaderID : UInt64 {
		case gcodable	= 0x67636F6461626C65	// ascii = 'gcodable'
	}

	case header		( version:UInt32, unused0:String, unused1:UInt32, unused2:UInt64 )
	case inTypeMap	( typeID:IntID, classInfo:ClassInfo )	// input only
	case outTypeMap	( typeID:IntID, classData:ClassData )	// output only
	case nilValue	( keyID:IntID )
	case inBinType	( keyID:IntID, value:BinaryIOType )	// input only
	case outBinType	( keyID:IntID, bytes:[UInt8] )		// output only
	case valueType	( keyID:IntID )
	case objectType	( keyID:IntID, typeID:IntID, objID:IntID )
	case objectSPtr	( keyID:IntID, objID:IntID )
	case objectWPtr	( keyID:IntID, objID:IntID )
	case end
	case keyMap		( keyID:IntID, keyName:String )
}

//	-------------------------------------------------
//	--BinaryIOType conformance
//	-------------------------------------------------

extension DataBlock : BinaryIOType {
	func write( to writer: inout BinaryWriter ) throws {
		switch self {
		case .header	( let version, let unused0, let unused1, let unused2 ):
			try Code.header.write(to: &writer)
			try HeaderID.gcodable.write(to: &writer)
			try version.write(to: &writer)
			try unused0.write(to: &writer)
			try unused1.write(to: &writer)
			try unused2.write(to: &writer)
		case .inTypeMap	( let typeID, let classInfo ):
			// ••••• SALVO COME outTypeMap ••••••••••
			try Code.outTypeMap.write(to: &writer)
			try typeID.write(to: &writer)
			try classInfo.classData.write(to: &writer)	// <----- ••••••
		case .outTypeMap( _, _ ):
			// non deve mai arrivare qui
			throw GCodableError.internalInconsistency(
				Self.self, GCodableError.Context(
					debugDescription: "Program must not reach .outTypeMap."
				)
			)
		case .nilValue	( let keyID ):
			try Code.nilValue.write(to: &writer)
			try keyID.write(to: &writer)
		case .inBinType( let keyID, let value ):
			// ••••• SALVO COME outBinType ••••••••••
			let bytes	= try value.binaryData() as [UInt8]
			try Code.outBinType.write(to: &writer)	// <----- ••••••
			try keyID.write(to: &writer)
			writer.writeData( bytes )
		case .outBinType( _, _ ):
			// non deve mai arrivare qui
			throw GCodableError.internalInconsistency(
				Self.self, GCodableError.Context(
					debugDescription: "Program must not reach .outBinType."
				)
			)
		case .valueType	( let keyID ):
			try Code.valueType.write(to: &writer)
			try keyID.write(to: &writer)
		case .objectType( let keyID, let typeID, let objID ):
			try Code.objectType.write(to: &writer)
			try keyID.write(to: &writer)
			try typeID.write(to: &writer)
			try objID.write(to: &writer)
		case .objectSPtr( let keyID, let objID ):
			try Code.objectSPtr.write(to: &writer)
			try keyID.write(to: &writer)
			try objID.write(to: &writer)
		case .objectWPtr( let keyID, let objID ):
			try Code.objectWPtr.write(to: &writer)
			try keyID.write(to: &writer)
			try objID.write(to: &writer)
		case .end:
			try Code.end.write(to: &writer)
		case .keyMap	( let keyID, let keyName ):
			try Code.keyMap.write(to: &writer)
			try keyID.write(to: &writer)
			try keyName.write(to: &writer)
		}
	}
	
	init(from reader: inout BinaryReader) throws {
		let code = try Code(from: &reader)

		switch code {
		case .header:
			let _		= try HeaderID	( from: &reader )
			let version	= try UInt32	( from: &reader )
			let unused0	= try String	( from: &reader )
			let unused1	= try UInt32	( from: &reader )
			let unused2	= try UInt64	( from: &reader )
			self = .header(version: version, unused0:unused0, unused1: unused1, unused2: unused2)

		case .inTypeMap:
			// non deve mai arrivare qui
			throw GCodableError.internalInconsistency(
				Self.self, GCodableError.Context(
					debugDescription: "Program must not reach .inTypeMap."
				)
			)
		case .outTypeMap:
			let typeID	= try IntID		( from: &reader )
			let data	= try ClassData	( from: &reader )
			self = .outTypeMap(typeID: typeID, classData: data )

		case .nilValue:
			let keyID	= try IntID		( from: &reader )
			self = .nilValue(keyID: keyID)

		case .inBinType:
			// non deve mai arrivare qui
			throw GCodableError.internalInconsistency(
				Self.self, GCodableError.Context(
					debugDescription: "Program must not reach .inBinType."
				)
			)
		case .outBinType:
			let keyID	= try IntID		( from: &reader )
			let bytes	= try reader.readData() as [UInt8]
			self = .outBinType(keyID: keyID, bytes: bytes)
		case .valueType:
			let keyID	= try IntID		( from: &reader )
			self = .valueType(keyID: keyID)
		case .objectType:
			let keyID	= try IntID		( from: &reader )
			let typeID	= try IntID		( from: &reader )
			let objID	= try IntID		( from: &reader )
			self = .objectType(keyID: keyID, typeID: typeID, objID: objID)
		case .objectSPtr:
			let keyID	= try IntID		( from: &reader )
			let objID	= try IntID		( from: &reader )
			self = .objectSPtr(keyID: keyID, objID: objID)
		case .objectWPtr:
			let keyID	= try IntID		( from: &reader )
			let objID	= try IntID		( from: &reader )
			self = .objectWPtr(keyID: keyID, objID: objID)
		case .end:
			self = .end
		case .keyMap:
			let keyID	= try IntID		( from: &reader )
			let keyName	= try String	( from: &reader )
			self = .keyMap(keyID: keyID, keyName: keyName)
		}
	}
}

//	-------------------------------------------------
//	-- Some Utils
//	-------------------------------------------------
extension DataBlock {
	enum Level : Int { case exit = -1, same, enter }
	
	var level : Level {
		switch self {
		case .valueType:	return .enter
		case .objectType:	return .enter
		case .end:			return .exit
		default:			return .same
		}
	}
	
	enum BlockType { case header, typeMap, graph, keyMap }
	
	var blockType : BlockType {
		switch self {
		case .header:		return .header
		case .inTypeMap:	return .typeMap
		case .outTypeMap:	return .typeMap
		case .keyMap:		return .keyMap
		default:			return .graph
		}
	}
	
	var keyID : IntID? {
		switch self {
		case .nilValue		( let keyID ):			return	keyID > 0 ? keyID : nil
		case .inBinType		( let keyID, _ ):		return	keyID > 0 ? keyID : nil
		case .outBinType	( let keyID, _ ):		return	keyID > 0 ? keyID : nil
		case .valueType		( let keyID ):			return	keyID > 0 ? keyID : nil
		case .objectType	( let keyID, _, _ ):	return	keyID > 0 ? keyID : nil
		case .objectSPtr	( let keyID, _ ):		return	keyID > 0 ? keyID : nil
		case .objectWPtr	( let keyID, _ ):		return	keyID > 0 ? keyID : nil
		default:									return	nil
		}
	}
	
	var typeID : IntID? {
		switch self {
		case .objectType	( _, let typeID, _ ):	return	typeID
		default:									return	nil
		}
	}
	
}

struct DumpInfo {
	let 	options: 		DumpOptions
	let		classInfoMap:	[IntID:ClassInfo]?
	let		keyIDtoKey:		[IntID:String]?
}

//	-------------------------------------------------
//	-- Readable output
//	-------------------------------------------------

extension DataBlock {
	func readableOutput( info:DumpInfo ) -> String {
		func format( _ keyID:IntID, _ info: DumpInfo, _ string:String ) -> String {
			if keyID == 0 {	// unkeyed
				return "- \(string)"
			} else if let key = info.keyIDtoKey?[keyID] {
				return "+ \"\(key)\": \(string)"
			} else {
				return "+ KEY\(keyID): \(string)"
			}
		}
		
		func small( _ value: Any, _ info:DumpInfo ) -> String {
			let phase1		= String(describing: value)
			if info.options.contains( .noTruncation ) {
				return phase1
			} else {
				let maxLength	= 64
				let phase2	= phase1.count > maxLength ?
					phase1.prefix(maxLength).appending("…") : phase1
				
				return value is String ? "\"\(phase2)\"" : phase2
			}
		}
		
		func objectString( _ typeID:UInt32, _ info: DumpInfo ) -> String {
			if let classData	= info.classInfoMap?[typeID]?.classData {
				if info.options.contains( .showTypeVersion ) {
					return "\(classData.readableTypeName) V\(classData.encodeVersion)"
				} else {
					return classData.readableTypeName
				}
			} else {
				return "TYPE\(typeID)"
			}
		}
		
		func typeString( _ info: DumpInfo, _ classData:ClassData ) -> String {
			var string	= "\(classData.readableTypeName) V\(classData.encodeVersion)"
			if info.options.contains( .showMangledClassNames ) {
				string.append( "\n\t\t\tMangledName = \( classData.mangledTypeName ?? "nil" )"  )
				string.append( "\n\t\t\tNSTypeName  = \( classData.objcTypeName )"  )
			}
			return string
		}
		
		switch self {
		case .header	( let version, let module, let unused1, let unused2 ):
			return "FILETYPE = \(HeaderID.gcodable) V\(version), U0 = \"\(module)\", U1 = \(unused1), U2 = \(unused2)"
		case .inTypeMap	( let typeID, let classInfo ):
			return	"TYPE\( typeID ):\t\( typeString( info, classInfo.classData ) )"
		case .outTypeMap	( let typeID, let classData ):
			return	"TYPE\( typeID ):\t\( typeString( info, classData ) )"
		case .nilValue	( let keyID ):
			return format( keyID, info, "nil")
		case .inBinType( let keyID, let value ):
			return format( keyID, info, small( value, info ) )
		case .outBinType( let keyID, let bytes ):
			let string	= "BIN \(bytes.count) bytes"
			return format( keyID, info, string )
		case .valueType	( let keyID ):
			let string	= "VAL"
			return format( keyID, info, string )
		case .objectType( let keyID, let typeID, let objID ):
			let string	= "REF\(objID) \( objectString( typeID,info ) )"
			return format( keyID, info, string )
		case .objectSPtr( let keyID, let objID ):
			let string	= "PTR\(objID)"
			return format( keyID, info, string )
		case .objectWPtr( let keyID, let objID ):
			let string	= "PTR\(objID)?"
			return format( keyID, info, string )
		case .end:
			return 	"."
		case .keyMap	( let keyID, let keyName ):
			return "KEY\( keyID ):\t\"\( keyName )\""
		}
	}
}

extension DataBlock : CustomStringConvertible {
	var description: String {
		return readableOutput(
			info: DumpInfo(options: .readable, classInfoMap: nil, keyIDtoKey: nil)
		)
	}
}
