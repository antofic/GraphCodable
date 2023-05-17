//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

public protocol BEncoder {
	/// The archiveIdentifier string set by the user.
	var archiveIdentifier: String? { get }

	/// A current version set by the user for encoding.
	var userVersion: UInt32 { get }
	
	/// Any contextual information set by the user for encoding.
	var userData: Any? { get }
	
	/// Encodes the given value.
	///
	///	Value must adopt the `BEncodable` protocol
	///
	/// Example:
	/// ```
	/// func encode(to encoder: BEncoder) throws {
	///		...
	/// 	try encoder.encode( value )
	///		...
	///	}
	/// ```
	/// - parameter value: The value to encode.
	mutating func encode<Value:BEncodable> (_ value: Value ) throws
	
	/// Give access to the underlying type `BinaryIOEncoder` for the
	/// duration of the closure
	///
	/// - parameter encodeFunc: the closure
	/// - returns: the return value of the closure
	mutating func withUnderlyingEncoder<T>( _ encodeFunc: (inout BinaryIOEncoder) throws -> T ) rethrows -> T
}
