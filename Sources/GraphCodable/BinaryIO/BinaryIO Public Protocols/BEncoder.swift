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
	
	mutating func withUnderlyingType<T>( _: (inout BinaryIOEncoder) throws -> T ) rethrows -> T
}
