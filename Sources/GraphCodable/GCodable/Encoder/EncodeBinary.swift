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

final class EncodeBinary<Output:MutableDataProtocol> : EncodeFileBlocks {
	weak var			delegate			: EncodeFileBlocksDelegate?
	private var			fileHeader			: FileHeader
	private var			ioEncoder			: BinaryIOEncoder
	private var 		sectionMap			= SectionMap()
	private var			sectionMapPosition	= 0
	
	init( ioEncoder:BinaryIOEncoder, fileHeader:FileHeader ) {
		self.ioEncoder	= ioEncoder
		self.fileHeader	= fileHeader
	}
	
	private func writeInit() throws {
		if sectionMap.isEmpty {
			// entriamo la prima volta e quindi scriviamo header e section map.
			
			// write header:
			try ioEncoder.encode( fileHeader )
			sectionMapPosition	= ioEncoder.position
			
			//	write a dummy section map. Let's write a dummy sectionmap.
			//	We will overwrite it when the positions of the sections are
			//	known.
			//	we need to disable packIntegers, because the sectionMap
			//	write size must be fixed.
			try ioEncoder.withoutPackingIntegers { ioEncoder in
				for section in FileSection.allCases {
					sectionMap[ section ] = Range(uncheckedBounds: (0,0))
				}
				try ioEncoder.encode( sectionMap )
			}
			 
			let bounds	= (ioEncoder.position,ioEncoder.position)
			sectionMap[ FileSection.body ] = Range( uncheckedBounds:bounds )
		}
	}
	
	func appendEnd() throws {
		try writeInit()
		try FileBlock.writeEnd(to: &ioEncoder, fileHeader: fileHeader)
	}
	
	func appendNil(keyID: KeyID?) throws {
		try writeInit()
		try FileBlock.writeNil(
			keyID: keyID,
			to: &ioEncoder, fileHeader: fileHeader
		)
	}
	
	func appendPtr(keyID: KeyID?, objID: ObjID, conditional: Bool) throws {
		try writeInit()
		try FileBlock.writePtr(
			keyID: keyID, objID: objID, conditional:conditional,
			to: &ioEncoder, fileHeader: fileHeader
		)
	}
	
	func appendVal(keyID: KeyID?, typeID: TypeID?, objID: ObjID?, binaryValue: BEncodable?) throws {
		try writeInit()
		try FileBlock.writeVal(
			keyID: keyID,objID: objID, typeID: typeID, binaryValue:binaryValue,
			to: &ioEncoder, fileHeader: fileHeader
		)
	}

	func output() throws -> Output {
		try writeInit()
		
		var bounds	= (sectionMap[.body]!.startIndex,ioEncoder.position)
		sectionMap[.body]	= Range( uncheckedBounds:bounds )
		
		// referenceMap:
		let classDataMap	= delegate!.classDataMap
		try ioEncoder.encode(classDataMap)
		bounds	= ( bounds.1,ioEncoder.position )
		sectionMap[ FileSection.classDataMap ] = Range( uncheckedBounds:bounds )
		
		// keyStringMap:
		let keyStringMap	= delegate!.keyStringMap
		try ioEncoder.encode(keyStringMap)
		bounds	= ( bounds.1,ioEncoder.position )
		sectionMap[ FileSection.keyStringMap ] = Range( uncheckedBounds:bounds )
		
		//	Now the sectionmap contains the positions of all sections:
		//	I can overwrite it. Therefore I need to put off packIntegers.
		try ioEncoder.withoutPackingIntegers { ioEncoder in
			ioEncoder.position		= sectionMapPosition
			try ioEncoder.encode(sectionMap)
			ioEncoder.position		= ioEncoder.endOfFile
		}

		return ioEncoder.data()
	}
}
