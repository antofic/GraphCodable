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

import Foundation

struct CodableRoot : Codable {
	let	fileHeader		: FileHeader
	let fileBlocks		: FileBlocks
	let classDataMap	: ClassDataMap
	let keyStringMap	: KeyStringMap
}

final class CodableEncoder<Output:MutableDataProtocol> : FileBlockEncoder {
	weak var			delegate			: FileBlockEncoderDelegate?
	let					fileHeader			= FileHeader()
	private var 		fileBlocks			= FileBlocks()
	
	func append(_ fileBlock: FileBlock, binaryValue: BinaryOType?) throws {
		fileBlocks.append( fileBlock )
	}
	
	func output() throws -> Output {
		let root = CodableRoot(
			fileHeader: fileHeader,
			fileBlocks: fileBlocks,
			classDataMap: delegate!.classDataMap,
			keyStringMap:  delegate!.keyStringMap
		)
		
		let json	= JSONEncoder()
		let data	= try json.encode( root )
		
		if let bytes = data as? Output {
			return bytes
		} else {
			return Output( data )
		}
	}
}


