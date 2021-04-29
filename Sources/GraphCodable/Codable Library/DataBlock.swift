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

//	enum BlockType { case header, typeMap, graph, keyMap }

/*
BINARY FILE FORMAT:
••••••PHASE 1: Header	// only one!
······^·|·HeaderID·|·Version·|·Module·|·Unused1|·Unused2      .Header
······0·|·1········|·2···········|·3······|·4······
••••••PHASE 2: Types table
······#·|·typeID···|·typeVersion·|·typeName      .TypeMap
••••••PHASE 3: Graph
······0·|·keyID                                  .Nil
······N·|·keyID····|·typeID······|·VALUE         .Native
······S·|·keyID····|·typeID                      .Struct
······C·|·keyID····|·typeID······|·objID         .Object
······P·|·keyID····|·typeID······|·objID         .ObjSPtr (STRONG POINTER)
······p·|·keyID····|·objID                       .ObjWPtr (WEAK POINTER)
······.                                          .End
••••••PHASE 4: Keys table
······*·|·keyID·|·keyName                        .KeyMap

Note:
Module = mainModuleName
Struct, Object open a new level, end closes it
keyID = 0 -> unkeyed
*/


typealias IntID	= UInt32

enum HeaderID : UInt64 {
	case gcodable	= 0x67636F6461626C65	// 'gcodable'
}

enum DataBlock {
	case Header		( version:UInt32, module:String, unused1:UInt32, unused2:UInt64 )
	case TypeMap	( typeID:IntID, typeVersion:UInt32, typeName:String )
	case Nil		( keyID:IntID )
	case Native		( keyID:IntID, typeID:IntID, value:GNativeCodable )
	case Struct		( keyID:IntID, typeID:IntID )
	case Object		( keyID:IntID, typeID:IntID, objID:IntID )
	case ObjSPtr	( keyID:IntID, objID:IntID )
	case ObjWPtr	( keyID:IntID, objID:IntID )
	case End
	case KeyMap		( keyID:IntID, keyName:String )
}

//	-------------------------------------------------
//	--Binary i/o
//	-------------------------------------------------
extension DataBlock {
	private enum Code : UInt8 {
		case header		= 0x5E	// '^' ascii
		case typeMap	= 0x23	// '#' ascii
		case Nil		= 0x30	// '0' ascii
		case Native		= 0x4E	// 'N' ascii
		case Struct		= 0x53	// 'S' ascii
		case Object		= 0x43	// 'C' ascii
		case ObjSPtr	= 0x50	// 'P' ascii
		case ObjWPtr	= 0x70	// 'p' ascii
		case end		= 0x2E	// '.' ascii
		case keyMap		= 0x2A	// '*' ascii
	}

	func write( to writer: inout BinaryWriter ) throws {
		switch self {
		case .Header	( let version, let module, let unused1, let unused2 ):	// 5
			writer.write( Code.header )
			writer.write( HeaderID.gcodable )
			writer.write( version )
			writer.write( module )
			writer.write( unused1 )
			writer.write( unused2 )
		case .TypeMap	( let typeID, let typeVersion, let typeName  ):	// 4
			writer.write( Code.typeMap )
			writer.write( typeID )
			writer.write( typeVersion )
			writer.write( typeName )
		case .Nil		( let keyID ):	// 2
			writer.write( Code.Nil )
			writer.write( keyID )
		case .Native	( let keyID, let typeID, let value ):	// 4
			writer.write( Code.Native )
			writer.write( keyID )
			writer.write( typeID )
			try value.write(to: &writer)
		case .Struct	( let keyID, let typeID ):	// 3
			writer.write( Code.Struct )
			writer.write( keyID )
			writer.write( typeID )
		case .Object	( let keyID, let typeID, let objID ):	// 4
			writer.write( Code.Object )
			writer.write( keyID )
			writer.write( typeID )
			writer.write( objID )
		case .ObjSPtr	( let keyID, let objID ):	// 3
			writer.write( Code.ObjSPtr )
			writer.write( keyID )
			writer.write( objID )
		case .ObjWPtr	( let keyID, let objID ):	// 3
			writer.write( Code.ObjWPtr )
			writer.write( keyID )
			writer.write( objID )
		case .End:
			writer.write( Code.end )
		case .KeyMap	( let keyID, let keyName ):	// 3
			writer.write( Code.keyMap )
			writer.write( keyID )
			writer.write( keyName )
		}
	}
	
	private static func contruct( from reader:inout BinaryReader, typeID : IntID, typeIDtoName:[IntID:TypeNameVersion]  ) throws -> GNativeCodable {
		guard let typeName = typeIDtoName[typeID]?.typeName else {
			throw GCodableError.parsingError
		}
		guard let nativeType = GTypesRepository.shared.nativeType(typeName: typeName) else {
			throw GCodableError.typeNotFoundInRegister( typeName: typeName )
		}
		return try nativeType.read(from: &reader)
	}
	
	static func read( from reader:inout BinaryReader, typeIDtoName:[IntID:TypeNameVersion]  ) throws -> DataBlock {
		let code : Code = try reader.read()
		
		switch code {
		case .header:	// 5
			let _		: HeaderID	= try reader.read()
			let version	: UInt32	= try reader.read()
			let module	: String	= try reader.read()
			let unused1	: UInt32	= try reader.read()
			let unused2	: UInt64	= try reader.read()
			return .Header(version: version, module:module, unused1: unused1, unused2: unused2)
		case .typeMap:	// 4
			let typeID	: IntID		= try reader.read()
			let version	: UInt32	= try reader.read()
			let name	: String	= try reader.read()
			return .TypeMap(typeID: typeID, typeVersion: version, typeName: name )
		case .Nil:	// 2
			let keyID	: IntID		= try reader.read()
			return .Nil(keyID: keyID)
		case .Native:	// 4
			let keyID	: IntID		= try reader.read()
			let typeID	: IntID		= try reader.read()
			let nativeValue			= try contruct( from: &reader, typeID : typeID, typeIDtoName:typeIDtoName  )
			return .Native(keyID: keyID, typeID: typeID, value: nativeValue)
		case .Struct:	// 3
			let keyID	: IntID		= try reader.read()
			let typeID	: IntID		= try reader.read()
			return .Struct(keyID: keyID, typeID: typeID)
		case .Object:	// 4
			let keyID	: IntID		= try reader.read()
			let typeID	: IntID		= try reader.read()
			let objID	: IntID		= try reader.read()
			return .Object(keyID: keyID, typeID: typeID, objID: objID)
		case .ObjSPtr:	// 3
			let keyID	: IntID		= try reader.read()
			let objID	: IntID		= try reader.read()
			return .ObjSPtr(keyID: keyID, objID: objID)
		case .ObjWPtr:	// 3
			let keyID	: IntID		= try reader.read()
			let objID	: IntID		= try reader.read()
			return .ObjWPtr(keyID: keyID, objID: objID)
		case .end:
			return .End
		case .keyMap:	// 3
			let keyID	: IntID		= try reader.read()
			let keyName	: String	= try reader.read()
			return .KeyMap(keyID: keyID, keyName: keyName)
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
		case .Struct:		return .enter
		case .Object:		return .enter
		case .End:			return .exit
		default:			return .same
		}
	}
	
	enum BlockType { case header, typeMap, graph, keyMap }
	
	var blockType : BlockType {
		switch self {
		case .Header:		return .header
		case .TypeMap:		return .typeMap
		case .KeyMap:		return .keyMap
		default:			return .graph
		}
	}
	
	var keyID : IntID? {
		switch self {
		case .Nil		( let keyID ):			return	keyID > 0 ? keyID : nil
		case .Native	( let keyID, _, _ ):	return	keyID > 0 ? keyID : nil
		case .Struct	( let keyID, _ ):		return	keyID > 0 ? keyID : nil
		case .Object	( let keyID, _, _ ):	return	keyID > 0 ? keyID : nil
		case .ObjSPtr	( let keyID, _ ):		return	keyID > 0 ? keyID : nil
		case .ObjWPtr	( let keyID, _ ):		return	keyID > 0 ? keyID : nil
		default:								return	nil
		}
	}
	
	var typeID : IntID? {
		switch self {
		case .Native	( _, let typeID, _ ):	return	typeID
		case .Struct	( _, let typeID ):		return	typeID
		case .Object	( _, let typeID, _ ):	return	typeID
		default:								return	nil
		}
	}
	
}

struct DumpInfo {
	let 	options: 		DumpOptions
	let		typeIDtoName:	[IntID:TypeNameVersion]?
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
				return "+ Key\(keyID): \(string)"
			}
		}
		
		func small( _ value: GNativeCodable ) -> String {
			let phase1	= String(describing: value)
			let maxLength	= 48
			let phase2	= phase1.count > maxLength ?
				phase1.prefix(maxLength).appending("…") : phase1
			
			return value is String ? "\"\(phase2)\"" : phase2
		}
		
		func typeString( _ typeID:UInt32, _ info: DumpInfo ) -> String {
			if let tnv	= info.typeIDtoName?[typeID] {
				if info.options.contains( .showTypeVersion ) {
					return "\(tnv.typeName) V\(tnv.version)"
				} else {
					return tnv.typeName
				}
			} else {
				return "Type\(typeID)"
			}
		}
		
		switch self {
		case .Header( let version, let module, let unused1, let unused2 ):
			return "^ Filetype = \(HeaderID.gcodable) V\(version), * = \(module), U1 = \(unused1), U2 = \(unused2)"
		case .TypeMap	( let typeID, let typeVersion, let typeName ):
			return	"# Type\( typeID ): V\( typeVersion ) \( typeName )"
		case .Nil		( let keyID ):
			return format( keyID, info, "nil")
		case .Native	( let keyID, let typeID, let value ):
			let string	= "\( typeString( typeID,info ) ) \( small(value) )"
			return format( keyID, info, string )
		case .Struct	( let keyID, let typeID ):
			let string	= "STRUCT \( typeString( typeID,info ) )"
			return format( keyID, info, string )
		case .Object	( let keyID, let typeID, let objID ):
			let string	= "CLASS \( typeString( typeID,info ) ) Obj\(objID)"
			return format( keyID, info, string )
		case .ObjSPtr	( let keyID, let objID ):
			let string	= "POINTER Obj\(objID)"
			return format( keyID, info, string )
		case .ObjWPtr	( let keyID, let objID ):
			let string	= "POINTER? Obj\(objID)"
			return format( keyID, info, string )
		case .End:
			return 	"."
		case .KeyMap	( let keyID, let keyName ):
			return "# Key\( keyID ): \"\( keyName )\""
		}
	}
}

extension DataBlock : CustomStringConvertible {
	var description: String {
		return readableOutput(
			info: DumpInfo(options: .readable, typeIDtoName: nil, keyIDtoKey: nil)
		)
	}
}
