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

final class BinaryEncoder<Output:MutableDataProtocol> : FileBlockEncoder {
	weak var			delegate			: FileBlockEncoderDelegate?
	private var			fileHeader			: FileHeader
	private var			wbuffer				: BinaryWriteBuffer
	private var 		sectionMap			= SectionMap()
	private var			sectionMapPosition	= 0
	
	init( binaryWriteBuffer:BinaryWriteBuffer, fileHeader:FileHeader ) {
		self.wbuffer	= binaryWriteBuffer
		self.fileHeader	= fileHeader
	}
	
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
	
	func appendEnd() throws {
		try writeInit()
		try FileBlock.writeEnd(to: &wbuffer, fileHeader: fileHeader)
	}
	
	func appendNil(keyID: KeyID?) throws {
		try writeInit()
		try FileBlock.writeNil(
			keyID: keyID,
			to: &wbuffer, fileHeader: fileHeader
		)
	}
	
	func appendPtr(keyID: KeyID?, objID: ObjID, conditional: Bool) throws {
		try writeInit()
		try FileBlock.writePtr(
			keyID: keyID, objID: objID, conditional:conditional,
			to: &wbuffer, fileHeader: fileHeader
		)
	}
	
	func appendVal(keyID: KeyID?, typeID: TypeID?, objID: ObjID?, binaryValue: BinaryOType?) throws {
		try writeInit()
		try FileBlock.writeVal(
			keyID: keyID,objID: objID, typeID: typeID, binaryValue:binaryValue,
			to: &wbuffer, fileHeader: fileHeader
		)
	}

	func output() throws -> Output {
		try writeInit()
		
		var bounds	= (sectionMap[.body]!.startIndex,wbuffer.position)
		sectionMap[.body]	= Range( uncheckedBounds:bounds )
		
		// referenceMap:
		let classDataMap	= delegate!.classDataMap
		try classDataMap.write(to: &wbuffer)
		bounds	= ( bounds.1,wbuffer.position )
		sectionMap[ FileSection.classDataMap ] = Range( uncheckedBounds:bounds )
		
		// keyStringMap:
		let keyStringMap	= delegate!.keyStringMap
		try keyStringMap.write(to: &wbuffer)
		bounds	= ( bounds.1,wbuffer.position )
		sectionMap[ FileSection.keyStringMap ] = Range( uncheckedBounds:bounds )
		
		do {
			//	sovrascrivo la sectionMapPosition
			//	ora che ho tutti i valori
			defer { wbuffer.setPositionToEnd() }
			wbuffer.position	= sectionMapPosition
			try sectionMap.write(to: &wbuffer)
		}
		
		return wbuffer.data()
	}
}
