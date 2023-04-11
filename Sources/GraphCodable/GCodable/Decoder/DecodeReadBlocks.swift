//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

/// this struct encapsulate a FileBlock and the immediate file
/// position (position) after the end of the FileBlock in
/// the BinaryIODecoder.
///
/// Needed for binaryValues
struct ReadBlock {
	let fileBlock	: FileBlock
	let position	: Int
	
	fileprivate init(from ioDecoder: inout BinaryIODecoder, fileHeader:FileHeader ) throws {
		self.fileBlock	= try FileBlock(from: &ioDecoder, fileHeader: fileHeader)
		//	store the fileblock terminal position
		self.position	= ioDecoder.position
		//	advance the cursor to the next fileblock
		//	(only .Bin fileblocks are distance more than 0 bytes)
		ioDecoder.position += self.fileBlock.nextFileBlockDistance
	}

	init( strongPointerKeyID keyID:KeyID?, idnID:IdnID, position:Int ) {
		self.fileBlock	= .Ptr(keyID: keyID, idnID: idnID, conditional: false)
		self.position	= position
	}
	
	///	The regionRange of a BinaryIO type
	///
	///	- `fileBlock.nextFileBlockDistance` return the size (>=0) of .Bin fileBlock
	///	- `fileBlock.nextFileBlockDistance` return always 0 for not .Bin fileBlocks
	///
	/// then:
	///
	///	- `binaryIORegionRange` contains the file region of a BinaryIO type
	/// - `binaryIORegionRange` contains the starting position of not BinaryIO types
	var binaryIORegionRange : Range<Int> {
		return position ..< (position + fileBlock.nextFileBlockDistance)
	}
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

