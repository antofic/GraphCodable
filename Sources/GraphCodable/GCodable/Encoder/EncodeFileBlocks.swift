//	MIT License
//
//	Copyright (c) 2021-2023 Antonino Ficarra
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//	SOFTWARE.


protocol EncodeFileBlocksDelegate : AnyObject {
	var	classDataMap:		ClassDataMap { get }
	var	keyStringMap:		KeyStringMap { get }
	
	var referenceMapDescription: String? { get }
}

extension EncodeFileBlocksDelegate {
	var referenceMapDescription: String? { nil }
}
 
protocol EncodeFileBlocks : AnyObject {
	var delegate	: EncodeFileBlocksDelegate? { get set }
	
	func appendEnd() throws
	func appendNil( keyID:KeyID? ) throws
	func appendPtr( keyID:KeyID?, objID:ObjID, conditional:Bool ) throws
	func appendVal( keyID:KeyID?, typeID:TypeID?, objID:ObjID?, binaryValue:BEncodable? ) throws
}