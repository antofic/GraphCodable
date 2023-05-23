//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

final class EncodeBinary<Output:MutableBinaryDataProtocol> : EncodeFileBlocks {
	weak var			delegate			: (any EncodeFileBlocksDelegate)?
	private var			fileHeader			: FileHeader
	private var			ioEncoder			: BinaryIOEncoder<Output>
	private var 		sectionMap			= SectionMap()
	private var			sectionMapPosition	= 0
	
	init( ioEncoder:BinaryIOEncoder<Output>, fileHeader:FileHeader ) {
		self.ioEncoder	= ioEncoder
		self.fileHeader	= fileHeader
	}
	
	private func writeInit() throws {
		if sectionMap.isEmpty {
			// entriamo la prima volta e quindi scriviamo header e section map.
			
			// encode the header:
			try ioEncoder.encode( fileHeader )
			
			//	save the section map position
			sectionMapPosition	= ioEncoder.position
			//	Let's encode a dummy sectionmap.
			//	We will overwrite it when the positions of the sections are
			//	known.
			//	We need to disable compression, because the sectionMap
			//	encoded size must be fixed.
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
		try FileBlock.encodeEnd(to: &ioEncoder)
	}
	
	func appendNil(keyID: KeyID?) throws {
		try writeInit()
		try FileBlock.encodeNil(
			keyID: keyID,
			to: &ioEncoder
		)
	}
	
	func appendPtr(keyID: KeyID?, idnID: IdnID, conditional: Bool) throws {
		try writeInit()
		try FileBlock.encodePtr(
			keyID: keyID, idnID: idnID, conditional:conditional,
			to: &ioEncoder
		)
	}
	
	func appendVal(keyID: KeyID?, refID: RefID?, idnID: IdnID?, value: some GEncodable) throws {
		try writeInit()
		try FileBlock.encodeVal(
			keyID: keyID,idnID: idnID, refID: refID,
			to: &ioEncoder
		)
	}

	func appendBin(keyID: KeyID?, refID: RefID?, idnID: IdnID?, value: some GBinaryEncodable) throws {
		try writeInit()
		try FileBlock.encodeBin(
			keyID: keyID,idnID: idnID, refID: refID, value:value,
			to: &ioEncoder
		)
	}
	
	func output() throws -> Output {
		try writeInit()
		
		var bounds	= (sectionMap[.body]!.startIndex,ioEncoder.position)
		sectionMap[.body]	= Range( uncheckedBounds:bounds )
		
		// encoding referenceMap
		let encodedClassMap	= delegate!.encodedClassMap
		try ioEncoder.encode(encodedClassMap)
		bounds	= ( bounds.1,ioEncoder.position )
		sectionMap[ FileSection.encodedClassMap ] = Range( uncheckedBounds:bounds )
		
		// encoding keyStringMap
		let keyStringMap	= delegate!.keyStringMap
		try ioEncoder.encode(keyStringMap)
		bounds	= ( bounds.1,ioEncoder.position )
		sectionMap[ FileSection.keyStringMap ] = Range( uncheckedBounds:bounds )
		
		//	Now the sectionmap contains the positions of all sections:
		//	I can overwrite the dummy one.
		//	Therefore I need to put off compression.
		try ioEncoder.withCompressionDisabled {
			$0.position		= sectionMapPosition
			try $0.encode(sectionMap)
			$0.position		= $0.endOfFile
		}

		return ioEncoder.data
	}
}
