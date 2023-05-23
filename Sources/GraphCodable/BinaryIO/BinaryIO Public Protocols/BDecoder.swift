//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

public protocol BinaryDataProtocol : DataProtocol
where Self.Indices == Range<Int>, Self.SubSequence: BinaryDataProtocol
{
	func withUnsafeBytes<ResultType>(_ body: (UnsafeRawBufferPointer) throws -> ResultType) rethrows -> ResultType
}

extension Data : BinaryDataProtocol {}
extension Array<UInt8> : BinaryDataProtocol {}
extension Array<UInt8>.SubSequence : BinaryDataProtocol {}
extension ContiguousArray<UInt8> : BinaryDataProtocol {}

public protocol BDecoder {
	associatedtype BinaryData : BinaryDataProtocol
	
	/// The archiveIdentifier string set by the user.
	var encodedArchiveIdentifier: String? { get }

	/// The encoded version of the archive set by the user.
	var encodedUserVersion: UInt32 { get }
	
	/// Any contextual information set by the user for decoding.
	var userData: Any? { get }
	
	/// Decodes a value of the given type.
	///
	///	Value must adopt the `BDecodable` protocol
	///
	///	Example:
	///	```
	///	init(from decoder: BDecoder) throws {
	/// 	...
	///	  	value = try decoder.decode( Int.self )
	///		...
	///	}
	///	```
	/// - parameter type: The type of the value to decode
	///	- returns: A value of the requested type, if convertible
	/// to the requested type.
	mutating func decode<Value:BDecodable>( _ type:Value.Type ) throws -> Value

	/// Give access to the underlying type `BinaryIODecoder` for the
	/// duration of the closure
	///
	/// - parameter decodeFunc: the closure
	/// - returns: the return value of the closure
	mutating func withUnderlyingDecoder<T>( _ decodeFunc: (inout BinaryIODecoder<BinaryData>) throws -> T ) rethrows -> T
}

public extension BDecoder {
	/// Decodes a value of the given type.
	///
	///	Value must adopt the `BDecodable` protocol
	///
	///	Example:
	///	```
	///	init(from decoder: BDecoder) throws {
	/// 	...
	///	  	value = try decoder.decode()
	///		...
	///	}
	///	```
	///	- returns: A value of the requested type, if convertible
	/// to the requested type.
	mutating func decode<Value:BDecodable>() throws -> Value {
		try decode( Value.self )
	}
}
