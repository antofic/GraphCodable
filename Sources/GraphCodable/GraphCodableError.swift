//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/

public enum GraphCodableError : Error {
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
	
	/// Indicate an error occurring while decoding a system type
	///
	/// GraphCodable implements the GDecodable protocol for
	/// many system types. This error is eventually raised
	/// in their `init(from: GDecoder) throws` method.
	///
	/// It can happen **while decoding** only
	case libDecodingError( Any.Type, Context )

	/// Indicate an error occurring while enconding a system type
	///
	/// GraphCodable implements the GEncodable protocol for
	/// many system types. This error is eventually raised
	/// in their `func encode(to encoder: some GEncoder) throws`
	/// method.
	///
	/// It can happen **while encoding** only
	case libEncodingError( Any.Type, Context )

	/// Indicates that there is a logical error in the package.
	/// **Should never occur.**
	///
	///	It can happen during **both encoding and decoding**
	case internalInconsistency( Any.Type, Context )
	
	/// Indicates that a reference type cannot be constructed
	/// from its name.
	///
	/// It can happen **while encoding** if the type visibility is
	/// not at least internal. Private reference types can only
	/// be encoded/decoded by disabling inheritance.
	///
	/// It can happen **while decoding** if the reference type is
	/// removed or its name changed.
	case cantConstructClass( Any.Type, Context )

	///	Indicates that the value being decoded **does not exist**
	///	of **does not exist anymore** in the archive.
	///
	///	It can happen if the value is not archived at all.
	///
	///	It can happen if you are about to extract an already
	///	extracted value (for example using the same key twice)
	///	as in this example:
	///	```
	///	init(from decoder: some GDecoder) throws {
	///		self.pivot = try decoder.decode(for: Key.pivot)
	///		//                               same key here:
	///		self.array = try decoder.decode(for: Key.pivot)
	///	}
	///	```
	///
	/// It can happen **while decoding** only
	case valueNotFound( Any.Type, Context )

	///	Indicates that the same key is being used more than once
	///	to encode fields of a type.
	///
	///	Example:
	///	```
	///	func encode(to encoder: some GEncoder) throws {
	///		try encoder.encode(pivot, for: Key.pivot)
	///		//                          same key here:
	///		try encoder.encode(array, for: Key.pivot)
	///	}
	///	```
	///
	/// It can happen **while encoding** only
	case duplicateKey( Any.Type, Context )
	
	///	Indicates that you are trying to get information not
	///	available to value types
	///
	///	Example: Ii Self is not a reference type, both calls
	///	to decodeder properties `encodedClassVersion` and
	///	`replacedClass` throw this error:
	///	```
	///	init(from decoder: some GDecoder) throws {
	///		let classVersion	= try decoder.encodedClassVersion
	///		let replacedClass	= try decoder.replacedClass
	///		/* ... */
	///	}
	///	```
	///
	/// It can happen **while decoding** only
	case referenceTypeRequired( Any.Type, Context )
	
	///	Indicates that the archive is not a valid
	///	GraphCodable archive
	///
	///	Refer to `context.debugDescription` for a
	///	description of why the archive is invalid.
	///
	/// It can happen **while decoding** only
	case malformedArchive( Any.Type, Context )
	
	///	Indicates that the archive is not decodable
	///	possibly because the reference types are
	///	connected in a cyclic graph.
	///
	///	To avoid this error it is necessary to "break"
	///	the cycle or cycles by properly using
	///	`deferDecode()` during encoding.
	///
	///	**See the UserGuide**
	///
	/// It can happen **while decoding** only
	case possibleCyclicGraphDetected( Any.Type, Context )

	///	Indicates inappropriate use of the `GObsolete`
	///	protocol.
	///
	///	**See the UserGuide**
	///
	///	It can happen during **both encoding and decoding**
	case misuseOfGObsoleteProtocol( Any.Type, Context )
}


