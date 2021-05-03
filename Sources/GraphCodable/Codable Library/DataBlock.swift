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
···code·|·HeaderID·|·Version·|·Module·|·Unused1|·Unused2      code = .header
······0·|·1········|·2···········|·3······|·4······
••••••PHASE 2: Types table
···code·|·typeID···|·typeVersion·|·typeName      code = .typeMap
••••••PHASE 3: Graphcode =
···code·|·keyID                                  code = .nilValue
···code·|·keyID····|·typeID······|·VALUE         code = .native( _ nativeCode:NativeCode )
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
	private enum Code : RawRepresentable, BinaryIOType {
		static var header 		: BlockCode { return .header 		}
		static var typeMap	 	: BlockCode { return .typeMap	  	}
		static var nilValue	 	: BlockCode { return .nilValue	  	}
		static var valueType	: BlockCode { return .valueType		}
		static var objectType	: BlockCode { return .objectType	}
		static var objectSPtr	: BlockCode { return .objectSPtr	}
		static var objectWPtr	: BlockCode { return .objectWPtr	}
		static var end	 		: BlockCode { return .end	 		}
		static var keyMap	 	: BlockCode { return .keyMap	  	}
		
		fileprivate enum BlockCode : UInt8, BinaryIOType {
			case header	= 0xF0	// start from 240
			case typeMap
			case nilValue
			case valueType
			case objectType
			case objectSPtr
			case objectWPtr
			case end
			case keyMap
		}
		
		// be aware: BlockCode.rawValue and NativeCode.rawValue
		// must not overlap. We use:
		//		NativeCode.rawValue	< 240
		//		BlockCode.rawValue	≥ 240
		case block( _ blockCode:BlockCode )
		case native( _ nativeCode:NativeCode )

		init?(rawValue: UInt8) {
			if let code = NativeCode(rawValue: rawValue) {
				self = .native( code )
			} else if let code = BlockCode(rawValue: rawValue) {
				self = .block( code )
			} else {
				return nil
			}
		}
		var rawValue: UInt8 {
			switch self {
			case .block( let code ):	return code.rawValue
			case .native( let code ):	return code.rawValue
			}
		}
	}

	private enum HeaderID : UInt64, BinaryIOType {
		case gcodable	= 0x67636F6461626C65	// ascii = 'gcodable'
	}

	case header		( version:UInt32, module:String, unused1:UInt32, unused2:UInt64 )
	case typeMap	( typeID:IntID, typeVersion:UInt32, typeName:String )
	case nilValue	( keyID:IntID )
	case nativeType	( keyID:IntID, value:GNativeCodable )
	case valueType	( keyID:IntID )
	case objectType	( keyID:IntID, typeID:IntID, objID:IntID )
	case objectSPtr	( keyID:IntID, objID:IntID )
	case objectWPtr	( keyID:IntID, objID:IntID )
	case end
	case keyMap		( keyID:IntID, keyName:String )
}

//	-------------------------------------------------
//	--Binary i/o
//	-------------------------------------------------
extension DataBlock {
	func write( to writer: inout BinaryWriter ) throws {
		switch self {
		case .header	( let version, let module, let unused1, let unused2 ):
			try Code.header.write(to: &writer)
			try HeaderID.gcodable.write(to: &writer)
			try version.write(to: &writer)
			try module.write(to: &writer)
			try unused1.write(to: &writer)
			try unused2.write(to: &writer)
		case .typeMap	( let typeID, let typeVersion, let typeName  ):
			try Code.typeMap.write(to: &writer)
			try typeID.write(to: &writer)
			try typeVersion.write(to: &writer)
			try typeName.write(to: &writer)
		case .nilValue	( let keyID ):
			try Code.nilValue.write(to: &writer)
			try keyID.write(to: &writer)
		case .nativeType( let keyID, let value ):
			try Code.native( type(of:value).nativeCode ).write(to: &writer)
			try keyID.write(to: &writer)
			try value.write(to: &writer)
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

	static func read( from reader:inout BinaryReader, typeIDtoName:[IntID:TypeNameVersion]  ) throws -> DataBlock {
		let code = try Code(from: &reader)

		switch code {
		case .native( let nativeCode ):
			let keyID		= try IntID( from: &reader )
			let nativeValue	= try nativeCode.readNativeType(from: &reader)
			return .nativeType(keyID: keyID, value: nativeValue)
		case .block( let blockCode ):
			switch blockCode {
			case .header:
				let _		= try HeaderID	( from: &reader )
				let version	= try UInt32	( from: &reader )
				let module	= try String	( from: &reader )
				let unused1	= try UInt32	( from: &reader )
				let unused2	= try UInt64	( from: &reader )
				return .header(version: version, module:module, unused1: unused1, unused2: unused2)
			case .typeMap:
				let typeID	= try IntID		( from: &reader )
				let version	= try UInt32	( from: &reader )
				let name	= try String	( from: &reader )
				return .typeMap(typeID: typeID, typeVersion: version, typeName: name )
			case .nilValue:
				let keyID	= try IntID		( from: &reader )
				return .nilValue(keyID: keyID)
			case .valueType:
				let keyID	= try IntID		( from: &reader )
				return .valueType(keyID: keyID)
			case .objectType:
				let keyID	= try IntID		( from: &reader )
				let typeID	= try IntID		( from: &reader )
				let objID	= try IntID		( from: &reader )
				return .objectType(keyID: keyID, typeID: typeID, objID: objID)
			case .objectSPtr:
				let keyID	= try IntID		( from: &reader )
				let objID	= try IntID		( from: &reader )
				return .objectSPtr(keyID: keyID, objID: objID)
			case .objectWPtr:
				let keyID	= try IntID		( from: &reader )
				let objID	= try IntID		( from: &reader )
				return .objectWPtr(keyID: keyID, objID: objID)
			case .end:
				return .end
			case .keyMap:
				let keyID	= try IntID		( from: &reader )
				let keyName	= try String	( from: &reader )
				return .keyMap(keyID: keyID, keyName: keyName)
			}
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
		case .valueType:		return .enter
		case .objectType:		return .enter
		case .end:			return .exit
		default:			return .same
		}
	}
	
	enum BlockType { case header, typeMap, graph, keyMap }
	
	var blockType : BlockType {
		switch self {
		case .header:		return .header
		case .typeMap:		return .typeMap
		case .keyMap:		return .keyMap
		default:			return .graph
		}
	}
	
	var keyID : IntID? {
		switch self {
		case .nilValue		( let keyID ):			return	keyID > 0 ? keyID : nil
		case .nativeType	( let keyID, _ ):		return	keyID > 0 ? keyID : nil
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
		
		func small( _ value: GNativeCodable, _ info:DumpInfo ) -> String {
			let phase1		= String(describing: value)
			if info.options.contains( .noTruncation ) {
				return phase1
			} else {
				let maxLength	= 48
				let phase2	= phase1.count > maxLength ?
					phase1.prefix(maxLength).appending("…") : phase1
				
				return value is String ? "\"\(phase2)\"" : phase2
			}
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
		case .header	( let version, let module, let unused1, let unused2 ):
			return "Filetype = \(HeaderID.gcodable) V\(version), * = \(module), U1 = \(unused1), U2 = \(unused2)"
		case .typeMap	( let typeID, let typeVersion, let typeName ):
			return	"Type\( typeID ): V\( typeVersion ) \( typeName )"
		case .nilValue	( let keyID ):
			return format( keyID, info, "nil")
		case .nativeType	( let keyID, let value ):
			return format( keyID, info, small( value, info ) )
		case .valueType	( let keyID ):
			let string	= "STRUCT"
			return format( keyID, info, string )
		case .objectType( let keyID, let typeID, let objID ):
			let string	= "CLASS \( typeString( typeID,info ) ) Obj\(objID)"
			return format( keyID, info, string )
		case .objectSPtr( let keyID, let objID ):
			let string	= "POINTER Obj\(objID)"
			return format( keyID, info, string )
		case .objectWPtr( let keyID, let objID ):
			let string	= "POINTER? Obj\(objID)"
			return format( keyID, info, string )
		case .end:
			return 	"."
		case .keyMap	( let keyID, let keyName ):
			return "Key\( keyID ): \"\( keyName )\""
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
