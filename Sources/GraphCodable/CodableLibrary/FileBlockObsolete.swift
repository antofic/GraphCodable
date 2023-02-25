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

//	-------------------------------------------------
//	-- ObsoleteFileBlock - only support for old file format
//	-------------------------------------------------

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

extension FileBlockObsolete {
	var level : FileBlock.Level { .same }
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

extension FileBlockObsolete {
	func readableOutput(
		options:			GraphEncoder.DumpOptions,
		binaryValue: 		BinaryOType?,
		classDataMap:		ClassDataMap?,
				keyStringMap: 		KeyStringMap?
		) -> String {
	
		func typeString( _ options:GraphEncoder.DumpOptions, _ classData:ClassData ) -> String {
			var string	= "\(classData.readableTypeName) V\(classData.encodeVersion)"
			if options.contains( .showMangledClassNames ) {
				string.append( "\n\t\t\tMangledName = \( classData.mangledTypeName ?? "nil" )"  )
				string.append( "\n\t\t\tNSTypeName  = \( classData.objcTypeName )"  )
			}
			return string
		}
		
		switch self {
		case .keyStringMap	( let keyID, let keyName ):
			return "KEY\( keyID ):\t\"\( keyName )\""
		case .classDataMap	( let typeID, let classData ):
			return	"TYPE\( typeID ):\t\( typeString( options, classData ) )"
		}
	}
}
