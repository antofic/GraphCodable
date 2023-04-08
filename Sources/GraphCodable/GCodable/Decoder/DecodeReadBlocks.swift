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
/// position (position) after the end of the FileBlock in
/// the BinaryIODecoder.
///
/// Needed for binaryValues
struct ReadBlock {
	let fileBlock			: FileBlock
	private let position	: Int
	
	fileprivate init(from ioDecoder: inout BinaryIODecoder, fileHeader:FileHeader ) throws {
		self.fileBlock	= try FileBlock(from: &ioDecoder, fileHeader: fileHeader)
		//	memorizzo la posizione della fine del fileBlock
		self.position	= ioDecoder.position
		//	sposto avanti la posizione della dimensione di binaryValue
		//	in modo che la posizione del BinaryIODecoder punti al
		//	FileBlock successivo
		//	(binarySize = 0 for non binary values)
		ioDecoder.position += self.fileBlock.binarySize
	}

	init( with fileBlock:FileBlock, copying readBlock:ReadBlock ) {
		self.fileBlock	= fileBlock
		self.position	= readBlock.position
	}
	
	///	The regionRange of a BinaryIO type
	///
	///	- `fileBlock.binarySize` return the size (>=0) of a BinaryIO value fileBlock
	///	- `fileBlock.binarySize` return always 0 for not BinaryIO fileBlocks
	///
	/// then:
	///
	///	- `valueRegion` contains the file region of a BinaryIO type
	/// - `valueRegion` contains the starting position of not BinaryIO types
	var binaryIORegionRange : Range<Int> { position ..< (position + fileBlock.binarySize) }
}

typealias ReadBlocks = [ReadBlock]

/// Decoding Pass 1
///
/// read the BinaryIODecoder content.
/// FileBlocks are updated in ReadBlocks
struct DecodeReadBlocks {
	let 		fileHeader		: FileHeader
	private	var sectionMap		: SectionMap
	private var ioDecoder		: BinaryIODecoder

	private var _classDataMap	: ClassDataMap?
	private var _readBlocks		: ReadBlocks?
	private var _keyStringMap	: KeyStringMap?

	init( from ioDecoder:BinaryIODecoder ) throws {
		var decoder	= ioDecoder
		
		self.fileHeader		= try FileHeader( from: &decoder )
		self.sectionMap		= try decoder.withCompressionDisabled { try SectionMap( from: &$0 ) }
		self.ioDecoder		= decoder
	}
	
	/// decode the class data of reference types
	/// from the BinaryIODecoder
	mutating func classDataMap() throws -> ClassDataMap {
		if let classDataMap = self._classDataMap { return classDataMap }

		let classDataMap	= try ioDecoder.withinRegion( range: regionRange( of:.classDataMap ) ) {
			try ClassDataMap(from: &$0)
		}
		self._classDataMap	= classDataMap
		return classDataMap
	}

	/// decode fileblocks from the BinaryIODecoder
	/// and trasform them in ReadBlock's
	mutating func readBlocks() throws -> ReadBlocks {
		if let readBlocks = self._readBlocks { return readBlocks }

		let fileHeader	= self.fileHeader
		let readBlocks	= try ioDecoder.withinRegion( range: regionRange( of:.body ) ) {
			var readBlocks	= [ReadBlock]()
			while $0.isEndOfRegion == false {
				let readBlock	= try ReadBlock( from: &$0,fileHeader: fileHeader )
				readBlocks.append( readBlock )
			}
			return readBlocks
		}

		self._readBlocks	= readBlocks
		return readBlocks
	}

	/// decode the keyString map from the BinaryIODecoder
	mutating func keyStringMap() throws -> KeyStringMap {
		if let keyStringMap = self._keyStringMap { return keyStringMap }

		let keyStringMap 	= try ioDecoder.withinRegion( range: regionRange( of:.keyStringMap ) ) {
			try KeyStringMap(from: &$0)
		}
		self._keyStringMap	= keyStringMap
		return keyStringMap
	}
	
	private func regionRange( of section:FileSection ) throws -> Range<Int> {
		guard let range = sectionMap[ section ] else {
			throw GraphCodableError.malformedArchive(
				Self.self, GraphCodableError.Context(
					debugDescription: "File section -\(section)- not found."
				)
			)
		}
		return range
	}
}

