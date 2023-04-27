//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

final class EncodeBody : EncodeFileBlocks {
	weak var			delegate	: (any EncodeFileBlocksDelegate)?
	private(set) var	fileBlocks	: [FileBlock]
	
	init() {
		self.fileBlocks = [FileBlock]()
	}
	
	func appendEnd() throws {
		fileBlocks.append( .End )
	}
	
	func appendNil(keyID: KeyID?) throws {
		fileBlocks.append( .Nil(keyID: keyID) )
	}
	
	func appendPtr(keyID: KeyID?, idnID: IdnID, conditional: Bool) throws {
		fileBlocks.append( .Ptr(keyID: keyID, idnID: idnID, conditional: conditional) )
	}
	
	func appendVal(keyID: KeyID?, refID: RefID?, idnID: IdnID?, value: some GEncodable) throws {
		fileBlocks.append( .Val(keyID: keyID, idnID: idnID, refID: refID)   )
	}
	
	func appendBin(keyID: KeyID?, refID: RefID?, idnID: IdnID?, value: some GBinaryEncodable) throws {
		fileBlocks.append( .Bin(keyID: keyID, idnID: idnID, refID: refID, binSize: 0) )
	}
}

