//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra


public enum Errors {
	/// A context for package errors.
	public struct Context: CustomStringConvertible {
		let file:				String
		let function:			String
		let line:				Int
		let debugDescription:	String
		let underlyingError:	Error?
		
		init(
			debugDescription: String,
			underlyingError: Error? = nil,
			function: String = #function,
			file: String = #fileID,
			line: Int = #line
		) {
			self.file				= file
			self.function			= function
			self.line				= line
			self.debugDescription	= debugDescription
			self.underlyingError	= underlyingError
		}
		
		public var description: String {
			var string = "\n"
			string.append("\tFile            : \"\(file)\"\n")
			string.append("\tFunction        : \"\(function)\"\n")
			string.append("\tLine            : \(line)\n")
			string.append("\tDescription     : \"\(debugDescription)\"\n")
			if let underlyingError = underlyingError {
				string.append( "\tUnderlyingError : \(underlyingError)\n" )
			}
			return string
		}
	}
	
	public enum BinaryIO: Error {
		///	Indicates that the archive is not a BinaryIO archive.
		///
		/// This is the error usually reported if the decoded archive
		/// is corrupted.
		///
		/// It can happen **while decoding**
		case malformedArchive( Any.Type, Context )
		
		/// Indicate that the archiveIdentifier specified in the
		/// decoder init method don't match the encoded one.
		///
		/// It can happen **while decoding** only
		case archiveIdentifierDontMatch( Any.Type, Context )
		
		/// Indicate an error occurring while reading a system type
		///
		/// BinaryIO implements the `BDecodable` protocol for
		/// many system types. This error is eventually raised
		/// in their `init(from: inout some BDecoder) throws` method.
		///
		/// It can happen **while decoding** only
		case libDecodingError( Any.Type, Context )
		
		/// Indicate an error occurring while writing a system type
		///
		/// BinaryIO implements the `BEncodable` protocol for
		/// many system types. This error is eventually raised
		/// in their `func write( to: inout some BEncoder ) throws`
		/// method.
		///
		/// It can happen **while encoding** only
		case libEncodingError( Any.Type, Context )
		
		///	Indicates that something went wrong in reading or writing.
		///
		/// This is the error usually reported if the decoded archive
		/// is corrupted.
		///
		/// It can happen **while encoding** and **while decoding**
		case outOfBounds( Any.Type, Context )
	}
}

