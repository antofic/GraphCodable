//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation


struct DecodeBinary {
	let fileHeader			: FileHeader
	let	classInfoMap		: ClassInfoMap
	let rootElement 		: FlattenedElement
	private var	elementMap	: ElementMap
	
	init( from ioDecoder:BinaryIODecoder, classNameMap:ClassNameMap? ) throws {
		var readBlockDecoder	= try DecodeReadBlocks( from: ioDecoder )
		let fileHeader			= readBlockDecoder.fileHeader
		let readBlocks			= try readBlockDecoder.readBlocks()
		let classInfoMap		= try ClassInfo.classInfoMap(
			classDataMap: readBlockDecoder.classDataMap(), classNameMap: classNameMap
		)
		let keyStringMap		= try readBlockDecoder.keyStringMap()
		
		self.fileHeader			= fileHeader
		self.classInfoMap		= classInfoMap
		(self.rootElement,self.elementMap)	= try FlattenedElement.rootElement(
			readBlocks:	readBlocks,
			keyStringMap:	keyStringMap,
			reverse:		true
		)
	}
	
	mutating func pop( idnID:IdnID ) -> FlattenedElement? {
		elementMap.removeValue( forKey: idnID )
	}
	
}


