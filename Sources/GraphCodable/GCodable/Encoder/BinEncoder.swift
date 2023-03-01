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

// -------------------------------------------------
// ----- BinEncoder
// -------------------------------------------------

final class BinEncoder<Output:MutableDataProtocol> : DataEncoder {
	weak var			delegate			: DataEncoderDelegate?
	let					fileHeader			= FileHeader()
	private var			wbuffer				= BinaryWriteBuffer()
	private var 		sectionMap			= SectionMap()
	private var			sectionMapPosition	= 0
	
	private func writeInit() throws {
		if sectionMap.isEmpty {
			// entriamo la prima volta e quindi scriviamo header e section map.
			
			// write header:
			try fileHeader.write(to: &wbuffer)
			sectionMapPosition	= wbuffer.position
			
			// write section map:
			for section in FileSection.allCases {
				sectionMap[ section ] = Range(uncheckedBounds: (0,0))
			}
			try sectionMap.write(to: &wbuffer)
			let bounds	= (wbuffer.position,wbuffer.position)
			sectionMap[ FileSection.body ] = Range( uncheckedBounds:bounds )
		}
	}
	
	func append(_ fileBlock: FileBlock, binaryValue: BinaryOType?) throws {
		try writeInit()
		try fileBlock.write(to: &wbuffer)
	}
	
	func output() throws -> Output {
		try writeInit()
		
		var bounds	= (sectionMap[.body]!.startIndex,wbuffer.position)
		sectionMap[.body]	= Range( uncheckedBounds:bounds )
		
		// referenceMap:
		try delegate!.classDataMap.write(to: &wbuffer)
		bounds	= ( bounds.1,wbuffer.position )
		sectionMap[ FileSection.classDataMap ] = Range( uncheckedBounds:bounds )
		
		// keyStringMap:
		try delegate!.keyStringMap.write(to: &wbuffer)
		bounds	= ( bounds.1,wbuffer.position )
		sectionMap[ FileSection.keyStringMap ] = Range( uncheckedBounds:bounds )
		
		do {
			//	sovrascrivo la sectionMapPosition
			//	ora che ho tutti i valori
			defer { wbuffer.setEof() }
			wbuffer.position	= sectionMapPosition
			try sectionMap.write(to: &wbuffer)
		}
		
		return wbuffer.data()
	}
}
