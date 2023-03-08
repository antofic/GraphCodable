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

struct ReadBlock {
	let fileBlock			: FileBlock
	private let position	: Int
	
	init(from rbuffer: inout BinaryReadBuffer, fileHeader:FileHeader ) throws {
		self.fileBlock	= try FileBlock(from: &rbuffer, fileHeader: fileHeader)
		// memorizzo la posizione della fine del fileBlock
		self.position	= rbuffer.regionStart
		// sposto avanti la posizione della dimensione di binaryValue
		rbuffer.regionStart += self.fileBlock.binarySize
	}
	
	init( fileBlock:FileBlock, position:Int ) {
		self.fileBlock	= fileBlock
		self.position	= position
	}
	
	init( with fileBlock:FileBlock, copying readBlock:ReadBlock ) {
		self.fileBlock	= fileBlock
		self.position	= readBlock.position
	}
	
	var region : Range<Int> { position ..< (position + fileBlock.binarySize) }
}

typealias ReadBlocks		= [ReadBlock]

struct ReadBlockDecoder {
	let 		fileHeader		: FileHeader
	private	var sectionMap		: SectionMap
	private var rbuffer			: BinaryReadBuffer

	private var _classDataMap	: ClassDataMap?
	private var _readBlocks		: ReadBlocks?
	private var _keyStringMap	: KeyStringMap?

	init( from readBuffer:BinaryReadBuffer ) throws {
		self.rbuffer		= readBuffer
		self.fileHeader		= try FileHeader( from: &rbuffer )
		self.sectionMap		= try type(of:sectionMap).init(from: &rbuffer)
	}
	
	mutating func classDataMap() throws -> ClassDataMap {
		if let classDataMap = self._classDataMap { return classDataMap }
		
		let saveRegion	= try setReaderRegionTo(section: .classDataMap)
		defer { rbuffer.region = saveRegion }

		let classDataMap	= try ClassDataMap(from: &rbuffer)
		self._classDataMap	= classDataMap
		return classDataMap
	}
	
	mutating func classInfoMap() throws -> ClassInfoMap {
		try classDataMap().mapValues {  try ClassInfo(classData: $0)  }
	}

	mutating func readBlocks() throws -> ReadBlocks {
		if let fileBlocks = self._readBlocks { return fileBlocks }

		let saveRegion	= try setReaderRegionTo(section: .body)
		defer { rbuffer.region = saveRegion }

		var fileBlocks	= [ReadBlock]()
		while rbuffer.isEof == false {
			let readBlock	= try ReadBlock(from: &rbuffer, fileHeader: fileHeader)
			fileBlocks.append( readBlock )
		}
		
		self._readBlocks	= fileBlocks
		return fileBlocks
	}

	mutating func keyStringMap() throws -> KeyStringMap {
		if let keyStringMap = self._keyStringMap { return keyStringMap }

		let saveRegion		= try setReaderRegionTo(section: .keyStringMap)
		defer { rbuffer.region = saveRegion }
		
		let keyStringMap 	= try KeyStringMap(from: &rbuffer)
		self._keyStringMap	= keyStringMap
		return keyStringMap
	}
	
	private mutating func setReaderRegionTo( section:FileSection ) throws -> Range<Int> {
		guard let range = sectionMap[ section ] else {
			throw GCodableError.decodingError(
				Self.self, GCodableError.Context(
					debugDescription: "File section \(section) not found."
				)
			)
		}
		defer { rbuffer.region = range }
		return rbuffer.region
	}
}

