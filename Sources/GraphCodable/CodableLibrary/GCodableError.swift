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
	// RawRepresentableSupport
	case enumDecodeError

	// NativeIOType
	case optionalEncodeError
	case optionalDecodeError
	case binaryIOEncodeError
	case binaryIODecodeError

	// ClassInfo
	case nilClassFromString( typeName:String )
	case nilClassFromStringFromClass( aClass:AnyClass )

	// DataBlock
	case readingInBinTypeError
	case writingOutBinTypeError
	case readingInTypeMapError
	case writingOutTypeMapError

	// GraphEncoder
	case notEncodableType( typeName:String )

	// GraphDecoder
	case duplicateTypeID( typeID:IntID )
	case keyNotFound( keyID:IntID )
	case rootNotFound
	case keyedChildNotFound( parentDataBlock:DataBlock )
	case unkeyedChildNotFound( parentDataBlock:DataBlock )
	case objectAlreadyExists( dataBlock:DataBlock )
	case pointerNotFound( dataBlock:DataBlock )
	case invalidRootLevel
	case unespectedDataBlockInThisPhase
	case typeMismatch( dataBlock:DataBlock )
	case deferredTypeMismatch( dataBlock:DataBlock )
	case inappropriateDataBlock( dataBlock:DataBlock )
	case classTypeNotFound( typeID:IntID )
	case decodedDataDontContainsType( type:(AnyObject & GCodable).Type )

	// GraphDecoder & GraphEncoder
	case duplicateKey( key:String )
}

