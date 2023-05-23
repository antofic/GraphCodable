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
	let rootNode 			: ReadNode
	let keyIDMap			: KeyIDMap
	
	private var	nodeMap	: ReadNodeMap
	
	init<Q:BinaryDataProtocol>( from ioDecoder:BinaryIODecoder<Q>, classNameMap:ClassNameMap? ) throws {
		var readBlockDecoder	= try DecodeReadBlocks( from: ioDecoder )
		let fileHeader			= readBlockDecoder.fileHeader
		let readBlocks			= try readBlockDecoder.readBlocks()
		
		let decodedClassMap		= try DecodedClass.decodedClassMap(
			encodedClassMap: readBlockDecoder.encodedClassMap(), classNameMap: classNameMap
		)

		self.fileHeader			= fileHeader
		self.decodedClassMap	= decodedClassMap
		(self.rootNode,self.nodeMap)	= try BlockNode.flatGraph(
			blocks:	readBlocks
		)

		self.keyIDMap			= Dictionary(
			uniqueKeysWithValues: try readBlockDecoder.keyStringMap().map { ($1,$0) }
		)
	}
	
	mutating func pop( idnID:IdnID ) -> ReadNode? {
		nodeMap.removeValue( forKey: idnID )
	}
	
}


