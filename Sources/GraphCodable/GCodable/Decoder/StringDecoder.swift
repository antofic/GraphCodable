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

final class StringDecoder: FileBlockEncoderDelegate {
	let	dataSize		: Int
	let fileHeader		: FileHeader
	let rFileBlocks		: ReadBlocks
	let classDataMap	: ClassDataMap
	let keyStringMap	: KeyStringMap
	let dumpOptions		: GraphDumpOptions
	
	init( from readBuffer:BinaryReadBuffer, options:GraphDumpOptions ) throws {
		var readBlockDecoder	= try ReadBlockDecoder( from: readBuffer )
		
		self.dataSize			= readBuffer.dataSize
		self.fileHeader			= readBlockDecoder.fileHeader
		self.rFileBlocks		= try readBlockDecoder.readBlocks()
		self.classDataMap		= try readBlockDecoder.classDataMap()
		self.keyStringMap		= try readBlockDecoder.keyStringMap()
		self.dumpOptions		= options
	}

	func dump() throws -> String {
		let stringEncoder	= StringEncoder(
			fileHeader:			fileHeader,
			dumpOptions:		dumpOptions,
			dataSize: 			dataSize
		)
		stringEncoder.delegate	= self
		try rFileBlocks.forEach { try stringEncoder.append($0.fileBlock, binaryValue: nil) }
		if dumpOptions.contains( .showFlattenedBody ) {
			let (rootElement,elementMap)	= try FlattenedElement.rootElement(
				rFileBlocks:	rFileBlocks,
				keyStringMap:	keyStringMap,
				reverse:		true
			)
			let string = rootElement.dump(
				elementMap:		elementMap,
				classDataMap:	classDataMap,
				keyStringMap:	keyStringMap,
				options: 		dumpOptions
			)
			try stringEncoder.append( string )
		}
		return try stringEncoder.output()
	}
}

