//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

typealias KeyIDMap		= [String : KeyID]

struct DecodeBinary {
	let fileHeader			: FileHeader
	let	decodedClassMap		: DecodedClassMap
	let rootElement 		: BlockElement
	let keyIDMap			: KeyIDMap
	
	private var	elementMap	: ElementMap
	
	init( from ioDecoder:BinaryIODecoder, classNameMap:ClassNameMap? ) throws {
		var readBlockDecoder	= try DecodeReadBlocks( from: ioDecoder )
		let fileHeader			= readBlockDecoder.fileHeader
		let readBlocks			= try readBlockDecoder.readBlocks()
		
		let decodedClassMap		= try DecodedClass.decodedClassMap(
			encodedClassMap: readBlockDecoder.encodedClassMap(), classNameMap: classNameMap
		)

		self.fileHeader			= fileHeader
		self.decodedClassMap	= decodedClassMap
		(self.rootElement,self.elementMap)	= try BlockElement.rootElement(
			readBlocks:	readBlocks
		)

		self.keyIDMap			= Dictionary(
			uniqueKeysWithValues: try readBlockDecoder.keyStringMap().map { ($1,$0) }
		)
	}
	
	mutating func pop( idnID:IdnID ) -> BlockElement? {
		elementMap.removeValue( forKey: idnID )
	}
	
}


