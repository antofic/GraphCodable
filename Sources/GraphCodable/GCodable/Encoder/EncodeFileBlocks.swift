//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra


protocol EncodeFileBlocksDelegate : AnyObject {
	var	classDataMap:		ClassDataMap { get }
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
	func appendVal<T:GEncodable>(keyID: KeyID?, refID: RefID?, idnID: IdnID?, value: T) throws
	func appendBin<T:GBinaryEncodable>(keyID: KeyID?, refID: RefID?, idnID: IdnID?, binaryValue: T) throws
}
