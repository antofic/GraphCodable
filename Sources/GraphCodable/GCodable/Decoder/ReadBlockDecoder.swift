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

/// this struct encapsulate a FileBlock and the immediate file
/// position (regionStart) after the end of the FileBlock in
/// the BinaryReadBuffer.
///
/// Needed for binaryValues
struct ReadBlock {
	let fileBlock			: FileBlock
	private let regionStart	: Int
	
	fileprivate init(from rbuffer: inout BinaryReadBuffer, fileHeader:FileHeader ) throws {
		self.fileBlock	= try FileBlock(from: &rbuffer, fileHeader: fileHeader)
		//	memorizzo la posizione della fine del fileBlock
		self.regionStart	= rbuffer.regionStart
		//	sposto avanti la posizione della dimensione di binaryValue
		//	in modo che la posizione del BinaryReadBuffer punti al
		//	FileBlock successivo
		//	(binarySize = 0 for non binary values)
		rbuffer.regionStart += self.fileBlock.binarySize
	}

	init( with fileBlock:FileBlock, copying readBlock:ReadBlock ) {
		self.fileBlock		= fileBlock
		self.regionStart	= readBlock.regionStart
	}
	
	///	Only binaryValues have a value region size > 0
	///
	///	whe size > 0 this is the region of the BinaryReadBuffer that contains
	///	the "binaryEncoded" value.
	var valueRegion : Range<Int> { regionStart ..< (regionStart + fileBlock.binarySize) }
}

typealias ReadBlocks		= [ReadBlock]

/// Decoding Pass 1
///
/// read the BinaryReadBuffer content.
/// FileBlocks are updated in ReadBlocks
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
	
	/// decode the class data of reference types
	/// from the BinaryReadBuffer
	mutating func classDataMap() throws -> ClassDataMap {
		if let classDataMap = self._classDataMap { return classDataMap }
		
		let saveRegion	= try setReaderRegionRangeTo(section: .classDataMap)
		defer { rbuffer.regionRange = saveRegion }

		let classDataMap	= try ClassDataMap(from: &rbuffer)
		self._classDataMap	= classDataMap
		return classDataMap
	}

	/// decode fileblocks from the BinaryReadBuffer
	/// and trasform them in ReadBlock's
	mutating func readBlocks() throws -> ReadBlocks {
		if let fileBlocks = self._readBlocks { return fileBlocks }

		let saveRegion	= try setReaderRegionRangeTo(section: .body)
		defer { rbuffer.regionRange = saveRegion }

		var fileBlocks	= [ReadBlock]()
		while rbuffer.isEndOfFile == false {
			let readBlock	= try ReadBlock(from: &rbuffer, fileHeader: fileHeader)
			fileBlocks.append( readBlock )
		}
		
		self._readBlocks	= fileBlocks
		return fileBlocks
	}

	/// decode the keyString map from the BinaryReadBuffer
	mutating func keyStringMap() throws -> KeyStringMap {
		if let keyStringMap = self._keyStringMap { return keyStringMap }

		let saveRegion		= try setReaderRegionRangeTo(section: .keyStringMap)
		defer { rbuffer.regionRange = saveRegion }
		
		let keyStringMap 	= try KeyStringMap(from: &rbuffer)
		self._keyStringMap	= keyStringMap
		return keyStringMap
	}
	
	private mutating func setReaderRegionRangeTo( section:FileSection ) throws -> Range<Int> {
		guard let range = sectionMap[ section ] else {
			throw GraphCodableError.malformedArchive(
				Self.self, GraphCodableError.Context(
					debugDescription: "File section \(section) not found."
				)
			)
		}
		defer { rbuffer.regionRange = range }
		return rbuffer.regionRange
	}
}

