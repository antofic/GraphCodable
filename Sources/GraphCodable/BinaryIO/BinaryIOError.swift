//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

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
	/// BinaryIO implements the `BDecodable` protocol for
	/// many system types. This error is eventually raised
	/// in their `init(from: inout some BDecoder) throws` method.
	///
	/// It can happen **while reading** only
	case archiveIdentifierDontMatch( Any.Type, BinaryIOError.Context )


	/// Indicate an error occurring while reading a system type
	///
	/// BinaryIO implements the `BDecodable` protocol for
	/// many system types. This error is eventually raised
	/// in their `init(from: inout some BDecoder) throws` method.
	///
	/// It can happen **while reading** only
	case libDecodingError( Any.Type, BinaryIOError.Context )

	/// Indicate an error occurring while writing a system type
	///
	/// BinaryIO implements the `BEncodable` protocol for
	/// many system types. This error is eventually raised
	/// in their `func write( to: inout some BEncoder ) throws`
	/// method.
	///
	/// It can happen **while writing** only
	case libEncodingError( Any.Type, BinaryIOError.Context )
/*
	///	Indicates that you are trying to write or read a non-trivial
	///	type in one go, which is not allowed.
	///
	///	This error can only occur in case of a logical inconsistency
	///	of the BinaryIO code.
	///
	/// It can potentially happen **while writing** and **while reading**
	case notPODType( Any.Type, BinaryIOError.Context )
*/
	///	Indicates that something went wrong in reading or writing.
	///
	/// This is the error usually reported if the read archive
	/// is corrupted.
	///
	/// It can happen **while writing** and **while reading**
	case outOfBounds( Any.Type, BinaryIOError.Context )
	
	/// Indicate an error occurring while using the
	/// `BinaryIOEncoder` `prependingWrite( ... )` function
	///
	/// It happens only using the `BinaryIOEncoder` function:
	///	```
	///	 func prependingWrite(
	///	 	dummyWrite: ( _: inout BinaryIOEncoder ) throws -> (),
	///	 	thenWrite: ( _: inout BinaryIOEncoder ) throws -> (),
	///		thenOverwriteDummy: ( inout BinaryIOEncoder, _: Int ) throws -> ()
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


