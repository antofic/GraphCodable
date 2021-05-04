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

import Foundation

enum GCodableError : Error {
	case typeDescriptorError(Int)

	case optionalEncodeError
	case optionalDecodeError
	case enumDecodeError

	case binaryIOEncodeError
	case binaryIODecodeError

	// DataBlock
	case parsingError
	case readingInBinTypeError	
	case writingOutBinTypeError

	// KeyedEncoder
	case notEncodableType( typeName:String )

	// KeyedEncoder and NodeData
	case duplicateTypeID( typeID:IntID )
	case duplicateKey( key:String )
	case keyNotFound( keyID:IntID )

	// NodeData
	case invalidRootLevel
	case unespectedDataBlockInThisPhase

	// Register
	case typeNotFoundInRegister( typeName:String )

	// KeyedDecoder
	case rootNotFound
	case cantDecodeRoot( dataBlock:DataBlock )
	case keyedChildNotFound( parentDataBlock:DataBlock )
	case unkeyedChildNotFound( parentDataBlock:DataBlock )
	case pointerAlreadyExists( dataBlock:DataBlock )
	case objectAlreadyExists( dataBlock:DataBlock )
	case pointerNotFound( dataBlock:DataBlock )
	case typeMismatch( dataBlock:DataBlock )
	case inappropriateDataBlock( dataBlock:DataBlock )
	case deferredTypeMismatch( dataBlock:DataBlock )
	case typeNameNotFound( typeID:IntID )
	
	case unregisteredTypes( typeNames:[String] )
	
	case decodedDataDontContainsTypeName( typeName:String )
}

