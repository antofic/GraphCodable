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

public enum BinaryIOError : Error {
	public struct Context {
		let debugDescription:	String
		let underlyingError:	Error?
		let function:			String
		let file:				String

		init(
			debugDescription: String,
			underlyingError: Error? = nil,
			function: String = #function,
			file: String = #fileID
		) {
			self.debugDescription	= debugDescription
			self.underlyingError	= underlyingError
			self.function			= function
			self.file				= file
		}
	}

	/// Indicate an error occurring while reading a system type
	///
	/// BinaryIO implements the `BinaryIType` protocol for
	/// many system types. This error is eventually raised
	/// in their `init(from: inout BinaryReadBuffer) throws` method.
	///
	/// It can happen **while reading** only
	case libDecodingError( Any.Type, BinaryIOError.Context )

	/// Indicate an error occurring while writing a system type
	///
	/// BinaryIO implements the `BinaryOType` protocol for
	/// many system types. This error is eventually raised
	/// in their `func write( to: inout BinaryWriteBuffer ) throws`
	/// method.
	///
	/// It can happen **while writing** only
	case libEncodingError( Any.Type, BinaryIOError.Context )

	///	Indicates that you are trying to write or read a non-trivial
	///	type in one go, which is not allowed.
	///
	///	This error can only occur in case of a logical inconsistency
	///	of the BinaryIO code.
	///
	/// It can potentially happen **while writing** and **while reading**
	case notPODType( Any.Type, BinaryIOError.Context )

	///	Indicates that something went wrong in reading or writing.
	///
	/// This is the error usually reported if the read archive
	/// is corrupted.
	///
	/// It can happen **while writing** and **while reading**
	case outOfBounds( Any.Type, BinaryIOError.Context )
	
	/// Indicate an error occurring while using the
	/// `BinaryWriteBuffer` `prependingWrite( ... )` function
	///
	/// It happens only using the `BinaryWriteBuffer` function:
	///	```
	///	 func prependingWrite(
	///	 	dummyWrite: ( _: inout BinaryWriteBuffer ) throws -> (),
	///	 	thenWrite: ( _: inout BinaryWriteBuffer ) throws -> (),
	///		thenOverwriteDummy: ( inout BinaryWriteBuffer, _: Int ) throws -> ()
	///	 ) throws
	///
	///	```
	///
	///	More precisely, it happens when the `thenOverwriteDummy` closure
	///	writes a different number of bytes than writed by `dummyWrite`.
	///
	///	- Note: This error should never occur when the library is used
	///	by GraphCodable
	case prependingFails( Any.Type, BinaryIOError.Context )
}


