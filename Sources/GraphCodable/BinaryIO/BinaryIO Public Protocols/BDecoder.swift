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

import Foundation

public protocol BDecoder {
	/// The archiveIdentifier string set by the user.
	var archiveIdentifier: String? { get }

	/// The encoded version of the archive set by the user.
	var encodedUserVersion: UInt32 { get }
	
	/// Any contextual information set by the user for decoding.
	var userData: Any? { get }
	
	/// Try peeking a value from the `decoder`.
	///
	///	`peek(_:)` try to decode a `BDecodable` value from the `decoder`.
	///	If decoding throws an error, the error is catched, the decoder
	///	cursor doesn't move and the function returns `nil`.
	/// If decoding is successful, it pass the value to the `accept`
	/// closure.
	/// If accept returns `true`, the value is considered good,
	/// the `decoder` cursor moves to the next value, and `peek`
	/// returns the value.
	/// If accept returns `false`, the value is not considered good,
	/// the `decoder` cursor doesn't move and `peek` returns `nil`.
	///
	/// - parameter type: The type of the value to decode
	/// - parameter accept: A function to check the decoded value
	/// - returns: The accepted value, `nil` otherwise.
	mutating func peek<Value:BDecodable >( _ type:Value.Type, _ accept:( Value ) -> Bool ) -> Value?

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

	mutating func withUnderlyingType<T>( _: (inout BinaryIODecoder) throws -> T ) rethrows -> T
}

public extension BDecoder {
	/// Try peeking a value from the `decoder`.
	///
	///	`peek(_:)` try to decode a `BDecodable` value from the `decoder`.
	///	If decoding throws an error, the error is catched, the decoder
	///	cursor doesn't move and the function returns `nil`.
	/// If decoding is successful, it pass the value to the `accept`
	/// closure.
	/// If accept returns `true`, the value is considered good,
	/// the `decoder` cursor moves to the next value, and `peek`
	/// returns the value.
	/// If accept returns `false`, the value is not considered good,
	/// the `decoder` cursor doesn't move and `peek` returns `nil`.
	///
	/// - parameter accept: A function to check the decoded value
	/// - returns: The accepted value, `nil` otherwise.
	mutating func peek<Value:BDecodable>( _ accept:( Value ) -> Bool ) -> Value? {
		peek( Value.self, accept )
	}

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
