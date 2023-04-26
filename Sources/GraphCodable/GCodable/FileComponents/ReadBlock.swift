//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

protocol FileBlockProtocol {
	init?( pointerTo:Self, conditional:Bool )
	
	var fileBlock : FileBlock { get }
}

extension FileBlock : FileBlockProtocol {
	init?( pointerTo source: FileBlock, conditional:Bool ) {
		switch source {
			case .Val( let keyID, let idnID, _ ):
				guard let idnID else { return nil }
				self = .Ptr(keyID: keyID, idnID: idnID, conditional: conditional)
			case .Bin( let keyID, let idnID, _, _ ):
				guard let idnID else { return nil }
				self = .Ptr(keyID: keyID, idnID: idnID, conditional: conditional)
			default:
				return nil
		}
	}
	
	var fileBlock: FileBlock {
		return self
	}
}

/// this struct encapsulate a FileBlock and the immediate file
/// position (position) after the end of the FileBlock in
/// the BinaryIODecoder.
///
/// Needed for binaryValues
struct ReadBlock : FileBlockProtocol {
	let fileBlock	: FileBlock
	let position	: Int
	
	init(from ioDecoder: inout BinaryIODecoder ) throws {
		self.fileBlock	= try FileBlock( from: &ioDecoder )
		//	store the fileblock terminal position
		self.position	= ioDecoder.position
		//	advance the cursor to the next fileblock
		//	(only .Bin fileblocks are distance more than 0 bytes)
		ioDecoder.position += self.fileBlock.nextFileBlockDistance
	}

	init?( pointerTo source: ReadBlock, conditional:Bool ) {
		guard let fileBlock = FileBlock(pointerTo: source.fileBlock, conditional: conditional ) else {
			return nil
		}
		self.fileBlock	= fileBlock
		self.position	= source.position
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
