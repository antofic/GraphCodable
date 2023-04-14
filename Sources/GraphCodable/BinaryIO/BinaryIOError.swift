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

	/// Indicate that the archiveIdentifier specified in the
	/// decoder init method don't match the encoded one.
	///
	/// It can happen **while decoding** only
	case archiveIdentifierDontMatch( Any.Type, BinaryIOError.Context )

	/// Indicate an error occurring while reading a system type
	///
	/// BinaryIO implements the `BDecodable` protocol for
	/// many system types. This error is eventually raised
	/// in their `init(from: inout some BDecoder) throws` method.
	///
	/// It can happen **while decoding** only
	case libDecodingError( Any.Type, BinaryIOError.Context )

	/// Indicate an error occurring while writing a system type
	///
	/// BinaryIO implements the `BEncodable` protocol for
	/// many system types. This error is eventually raised
	/// in their `func write( to: inout some BEncoder ) throws`
	/// method.
	///
	/// It can happen **while encoding** only
	case libEncodingError( Any.Type, BinaryIOError.Context )

	///	Indicates that something went wrong in reading or writing.
	///
	/// This is the error usually reported if the read archive
	/// is corrupted.
	///
	/// It can happen **while encoding** and **while decoding**
	case outOfBounds( Any.Type, BinaryIOError.Context )
}


