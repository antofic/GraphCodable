//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

struct DecodeClassNames {
	let fileHeader				: FileHeader
	let	encodedClassMap			: EncodedClassMap
	
	init( from ioDecoder:BinaryIODecoder ) throws {
		var readBlockDecoder	= try DecodeReadBlocks( from: ioDecoder )
		fileHeader				= readBlockDecoder.fileHeader
		encodedClassMap			= try readBlockDecoder.encodedClassMap()
	}
}

