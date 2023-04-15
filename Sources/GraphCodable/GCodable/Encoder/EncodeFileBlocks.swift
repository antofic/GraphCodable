//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra


protocol EncodeFileBlocksDelegate : AnyObject {
	var	encodedClassMap:		EncodedClassMap { get }
	var	keyStringMap:		KeyStringMap { get }
	
	var referenceMapDescription: String? { get }
}

extension EncodeFileBlocksDelegate {
	var referenceMapDescription: String? { nil }
}

protocol EncodeFileBlocks : AnyObject {
	var delegate	: (any EncodeFileBlocksDelegate)? { get set }
	
	func appendEnd() throws
	func appendNil( keyID:KeyID? ) throws
	func appendPtr( keyID:KeyID?, idnID:IdnID, conditional:Bool ) throws
	func appendVal(keyID: KeyID?, refID: RefID?, idnID: IdnID?, value: some GEncodable ) throws
	func appendBin(keyID: KeyID?, refID: RefID?, idnID: IdnID?, binaryValue: some GBinaryEncodable ) throws
}
