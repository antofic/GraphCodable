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
···code·|·typeID···|·classData                   code = .typeMap
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

struct FileHeader : CustomStringConvertible, BinaryIOType {
	static var INITIAL_FILE_VERSION	: UInt32 { 0 }
	static var VALUEID_FILE_VERSION	: UInt32 { 1 }
	static var CURRENT_FILE_VERSION	: UInt32 { VALUEID_FILE_VERSION }

	var currentVersionSupportsValueIDs : Bool { version >= Self.VALUEID_FILE_VERSION }
	
	// *******************************
	
	private enum HeaderID : UInt64 {
		case gcodable	= 0x67636F6461626C65	// ascii = 'gcodable'
	}

	let version : UInt32
	let unused0 : UInt32
	let unused1 : UInt64
	let unused2 : UInt8
	
	var description: String {
		"FILETYPE = \(HeaderID.gcodable) V\(version), U0 = \"\(unused0)\", U1 = \(unused1), U2 = \(unused2)"
	}
	
	init( version: UInt32 = CURRENT_FILE_VERSION, unused0: UInt32 = 0, unused1: UInt64 = 0, unused2: UInt8 = 0 ) {
		self.version = version
		self.unused0 = unused0
		self.unused1 = unused1
		self.unused2 = unused2
	}

	private enum ObsoleteCode : UInt8, BinaryIOType {
		case header		= 0x5E	// '^'
	}

	init(from reader: inout BinaryReader) throws {
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
		self.unused2	= try UInt8		( from: &reader )
	}
	
	func write(to writer: inout BinaryWriter) throws {
		try HeaderID.gcodable.write(to: &writer)
		try version.write(to: &writer)
		try unused0.write(to: &writer)
		try unused1.write(to: &writer)
		try unused2.write(to: &writer)
	}
}


enum FileBlock {
	private enum Code : UInt8 {
		case typeMap		= 0x24	// '$'
		case nilValue		= 0x30	// '0'
		case binaryIN		= 0x3C	// '<'	// No Identity
		case binaryOUT		= 0x3E	// '>'	// No Identity
		case valueType		= 0x25	// '%'	// No Identity
		case iBinaryIN		= 0x2D	// '-'	// Identity
		case iBinaryOUT		= 0x2B	// '+'	// Identity
		case iValueType		= 0x2F	// '/'	// Identity
		case referenceType	= 0x40	// '@'	// Identity
		case strongPtr		= 0x21	// '!'	// Identity
		case conditionalPtr	= 0x3F	// '?'	// Identity
		case end			= 0x2E	// '.'
		case keyMap			= 0x2A	// '*'
	}
	//	typeMap
	case typeMap		( typeID:IntID, classData:ClassData )
	//	body
		//	without Identity
	case nilValue		( keyID:IntID )
	case binaryIN		( keyID:IntID, value:BinaryIOType )					// binary (input only)
	case binaryOUT		( keyID:IntID, bytes:[UInt8] )						// binary (output only)
	case valueType		( keyID:IntID )										// value type without identity
		//	with Identity
	case iBinaryIN		( keyID:IntID, objID:IntID, value:BinaryIOType )	// binary (input only)
	case iBinaryOUT		( keyID:IntID, objID:IntID, bytes:[UInt8] )			// binary (output only)
	case iValueType		( keyID:IntID, objID:IntID )						// value type with identity (iValue)
	case referenceType	( keyID:IntID, typeID:IntID, objID:IntID )			// reference Type
	case strongPtr		( keyID:IntID, objID:IntID )						// strong pointer to iValue/reference
	case conditionalPtr	( keyID:IntID, objID:IntID )						// conditional pointer to iValue/reference
	
	case end
	//	keyMap
	case keyMap		( keyID:IntID, keyName:String )
}

extension FileBlock {
	enum Section { case body, typeMap, keyMap }
	var section : Section {
		switch self {
		case .typeMap:	return .typeMap
		case .keyMap:	return .keyMap
		default:		return .body
		}
	}

	enum Level : Int { case exit = -1, same, enter }
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
		case .binaryIN			( let keyID, _ ):		return	keyID > 0 ? keyID : nil
		case .binaryOUT			( let keyID, _ ):		return	keyID > 0 ? keyID : nil
		case .valueType			( let keyID ):			return	keyID > 0 ? keyID : nil
		case .iBinaryIN			( let keyID, _ , _ ):	return	keyID > 0 ? keyID : nil
		case .iBinaryOUT		( let keyID, _ , _ ):	return	keyID > 0 ? keyID : nil
		case .iValueType		( let keyID, _ ):		return	keyID > 0 ? keyID : nil
		case .referenceType		( let keyID, _, _ ):	return	keyID > 0 ? keyID : nil
		case .strongPtr			( let keyID, _ ):		return	keyID > 0 ? keyID : nil
		case .conditionalPtr	( let keyID, _ ):		return	keyID > 0 ? keyID : nil
		default:										return	nil
		}
	}
	
	var typeID : IntID? {
		switch self {
		case .referenceType	( _, let typeID, _ ):	return	typeID
		default:									return	nil
		}
	}
}

extension FileBlock {
	func write( to writer: inout BinaryWriter ) throws {
		switch self {
		case .typeMap( let typeID, let classData ):
			try Code.typeMap.write(to: &writer)
			try typeID.write(to: &writer)
			try classData.write(to: &writer)
		case .nilValue	( let keyID ):
			try Code.nilValue.write(to: &writer)
			try keyID.write(to: &writer)
		case .binaryIN( let keyID, let value ):
			// ••••• SALVO COME outBinType ••••••••••
			let bytes	= try value.binaryData() as [UInt8]
			try Code.binaryOUT.write(to: &writer)	// <----- ••••••
			try keyID.write(to: &writer)
			try writer.writeData( bytes )
		case .binaryOUT( _, _ ):
			// non deve mai arrivare qui
			throw GCodableError.internalInconsistency(
				Self.self, GCodableError.Context(
					debugDescription: "Encoding .binaryOUT not allowed."
				)
			)
		case .valueType	( let keyID ):
			try Code.valueType.write(to: &writer)
			try keyID.write(to: &writer)
		case .iBinaryIN(keyID: let keyID, objID: let objID, value: let value):
			// ••••• SALVO COME iBinaryOUT ••••••••••
			let bytes	= try value.binaryData() as [UInt8]
			try Code.iBinaryOUT.write(to: &writer)	// <----- ••••••
			try keyID.write(to: &writer)
			try objID.write(to: &writer)
			try writer.writeData( bytes )
		case .iBinaryOUT( _, _, _ ):
			// non deve mai arrivare qui
			throw GCodableError.internalInconsistency(
				Self.self, GCodableError.Context(
					debugDescription: "Encoding .iBinaryOUT not allowed."
				)
			)
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
		}
	}

	init(from reader: inout BinaryReader, header:FileHeader) throws {
		let code = try Code(from: &reader)

		switch code {
		case .typeMap:
			let typeID	= try IntID		( from: &reader )
			let data	= try ClassData	( from: &reader )
			self = .typeMap(typeID: typeID, classData: data )
		case .nilValue:
			let keyID	= try IntID		( from: &reader )
			self = .nilValue(keyID: keyID)
		//	case .binaryIN: invalid -> default
		case .binaryOUT:
			let keyID	= try IntID		( from: &reader )
			let bytes	= try reader.readData() as [UInt8]
			self = .binaryOUT(keyID: keyID, bytes: bytes)
		case .valueType:
			let keyID	= try IntID		( from: &reader )
			self = .valueType(keyID: keyID)
		case .iBinaryOUT:
			let keyID	= try IntID		( from: &reader )
			let objID	= try IntID		( from: &reader )
			let bytes	= try reader.readData() as [UInt8]
			self = .iBinaryOUT(keyID: keyID, objID: objID, bytes: bytes)
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
		default:
			// include binaryIN e iBinaryIN
			throw GCodableError.decodingError(
				Self.self, GCodableError.Context(
					debugDescription: "Decoding an invalid DataBlock code \(code)."
				)
			)
		}
	}
}

struct DumpInfo {
	let 	options: 		GraphEncoder.DumpOptions
	let		classDataMap:	[IntID:ClassData]?
	let		keyIDtoKey:		[IntID:String]?
}

//	-------------------------------------------------
//	-- Readable output
//	-------------------------------------------------

extension FileBlock {
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
			let phase1 = String(describing: value)
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
			if let classData	= info.classDataMap?[typeID] {
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
		case .typeMap	( let typeID, let classData ):
			return	"TYPE\( typeID ):\t\( typeString( info, classData ) )"
		case .nilValue	( let keyID ):
			return format( keyID, info, "nil")
		case .binaryIN( let keyID, let value ):
			return format( keyID, info, small( value, info ) )
		case .binaryOUT( let keyID, let bytes ):
			let string	= "BIN \(bytes.count) bytes"
			return format( keyID, info, string )
		case .valueType	( let keyID ):
			let string	= "VAL"
			return format( keyID, info, string )
		case .iBinaryIN( let keyID, let objID, let value ):
			let string = "BIN\(objID) \( small( value, info ) )"
			return	format( keyID, info, string )
		case .iBinaryOUT( let keyID, let objID, let bytes ):
			let string	= "BIN\(objID) \(bytes.count) bytes"
			return format( keyID, info, string )
		case .iValueType( let keyID, let objID):
			let string	= "VAL\(objID)"
			return format( keyID, info, string )
		case .referenceType( let keyID, let typeID, let objID ):
			let string	= "REF\(objID) \( objectString( typeID,info ) )"
			return format( keyID, info, string )
		case .strongPtr( let keyID, let objID ):
			let string	= "PTR\(objID)"
			return format( keyID, info, string )
		case .conditionalPtr( let keyID, let objID ):
			let string	= "PTR\(objID)?"
			return format( keyID, info, string )
		case .end:
			return 	"."
		case .keyMap	( let keyID, let keyName ):
			return "KEY\( keyID ):\t\"\( keyName )\""
		}
	}
}

extension FileBlock : CustomStringConvertible {
	var description: String {
		return readableOutput(
			info: DumpInfo(options: .readable, classDataMap: nil, keyIDtoKey: nil)
		)
	}
}

