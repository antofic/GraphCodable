//	MIT License
//
//	Copyright (c) 2021 Antonino Ficarra
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


protocol DataEncoderDelegate : AnyObject {
	var	classDataMap:	ClassDataMap { get }
	var	keyStringMap:	KeyStringMap { get }
	var dumpOptions:	GraphDumpOptions { get }
}

protocol DataEncoder : AnyObject {
	associatedtype	Output
	
	var delegate	: DataEncoderDelegate? { get set }
	
	func append( _ fileBlock: FileBlock, binaryValue:BinaryOType? ) throws
	func output() throws -> Output
	
	func appendNil( keyID:UIntID ) throws
	func appendValue( keyID:UIntID ) throws
	func appendBinValue( keyID:UIntID, binaryValue:BinaryOType ) throws
	func appendRef( keyID:UIntID, typeID:UIntID ) throws
	func appendBinRef( keyID:UIntID, typeID:UIntID, binaryValue:BinaryOType ) throws
	func appendIdValue( keyID:UIntID, objID:UIntID ) throws
	func appendIdBinValue( keyID:UIntID, objID:UIntID, binaryValue:BinaryOType ) throws
	func appendIdRef( keyID:UIntID, typeID:UIntID, objID:UIntID ) throws
	func appendIdBinRef( keyID:UIntID,  typeID:UIntID, objID:UIntID, binaryValue:BinaryOType ) throws
	func appendStrongPtr( keyID:UIntID, objID:UIntID ) throws
	func appendConditionalPtr( keyID:UIntID, objID:UIntID ) throws
	func appendEnd() throws
	
}

extension DataEncoder {
	func appendNil( keyID:UIntID ) throws {
		try append( .Nil(keyID: keyID), binaryValue:nil )
	}
	func appendValue( keyID:UIntID ) throws {
		try append( .value(keyID: keyID), binaryValue:nil )
	}
	func appendBinValue( keyID:UIntID, binaryValue:BinaryOType ) throws {
		let bytes	= try binaryValue.binaryData() as Bytes
		try append( .binValue(keyID: keyID, bytes: bytes), binaryValue:binaryValue  )
	}
	func appendRef( keyID:UIntID, typeID:UIntID ) throws {
		try append( .ref(keyID: keyID, typeID:typeID ), binaryValue:nil )
	}
	func appendBinRef( keyID:UIntID, typeID:UIntID, binaryValue:BinaryOType ) throws {
		let bytes	= try binaryValue.binaryData() as Bytes
		try append( .binRef(keyID: keyID, typeID:typeID, bytes: bytes), binaryValue:binaryValue  )
	}
	func appendIdValue( keyID:UIntID, objID:UIntID ) throws {
		try append( .idValue(keyID: keyID, objID: objID), binaryValue:nil )
	}
	func appendIdBinValue( keyID:UIntID, objID:UIntID, binaryValue:BinaryOType ) throws {
		let bytes	= try binaryValue.binaryData() as Bytes
		try append( .idBinValue(keyID: keyID, objID: objID, bytes: bytes), binaryValue:binaryValue )
	}
	func appendIdRef( keyID:UIntID, typeID:UIntID, objID:UIntID )throws {
		try append( .idRef(keyID: keyID, typeID: typeID, objID: objID), binaryValue:nil )
	}
	func appendIdBinRef( keyID:UIntID,  typeID:UIntID, objID:UIntID, binaryValue:BinaryOType ) throws {
		let bytes	= try binaryValue.binaryData() as Bytes
		try append( .idBinRef(keyID: keyID, typeID:typeID, objID: objID, bytes: bytes), binaryValue:binaryValue )
	}
	func appendStrongPtr( keyID:UIntID, objID:UIntID ) throws {
		try append( .strongPtr(keyID: keyID, objID: objID), binaryValue:nil )
	}
	func appendConditionalPtr( keyID:UIntID, objID:UIntID ) throws {
		try append( .conditionalPtr(keyID: keyID, objID: objID), binaryValue:nil )
	}
	func appendEnd() throws {
		try append( .end, binaryValue:nil )
	}
}


