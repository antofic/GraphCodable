//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

final class EncodeBinary<Output:MutableDataProtocol> : EncodeFileBlocks {
	weak var			delegate			: (any EncodeFileBlocksDelegate)?
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
			//	save the section map position
			sectionMapPosition	= ioEncoder.position
			
			//	Let's write a dummy sectionmap.
			//	We will overwrite it when the positions of the sections are
			//	known.
			//	we need to disable compression, because the sectionMap
			//	write size must be fixed.
			try ioEncoder.withCompressionDisabled { ioEncoder in
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
	
	func appendPtr(keyID: KeyID?, idnID: IdnID, conditional: Bool) throws {
		try writeInit()
		try FileBlock.writePtr(
			keyID: keyID, idnID: idnID, conditional:conditional,
			to: &ioEncoder, fileHeader: fileHeader
		)
	}
	
	func appendVal<T:GEncodable>(keyID: KeyID?, refID: RefID?, idnID: IdnID?, value: T) throws {
		try writeInit()
		try FileBlock.writeVal(
			keyID: keyID,idnID: idnID, refID: refID,
			to: &ioEncoder, fileHeader: fileHeader
		)
	}

	func appendBin<T:GBinaryEncodable>(keyID: KeyID?, refID: RefID?, idnID: IdnID?, binaryValue: T) throws {
		try writeInit()
		try FileBlock.writeBin(
			keyID: keyID,idnID: idnID, refID: refID, binaryValue:binaryValue,
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
		//	I can overwrite it. Therefore I need to put off compression.
		try ioEncoder.withCompressionDisabled {
			$0.position		= sectionMapPosition
			try $0.encode(sectionMap)
			$0.position		= $0.endOfFile
		}

		return ioEncoder.data()
	}
}
