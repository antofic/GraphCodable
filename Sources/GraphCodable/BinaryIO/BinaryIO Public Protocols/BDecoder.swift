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
	///	  	value = try decoder.decode()
	///		...
	///	}
	///	```
	///	- returns: A value of the requested type, if convertible
	/// to the requested type.
	mutating func decode<Value>() 	throws -> Value where Value : BDecodable
	
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
	mutating func peek<Value>( _ accept:( Value ) -> Bool ) -> Value? where Value : BDecodable
	
	///	For package use only. Use `encodedUserVersion` instead.
	var encodedBinaryIOVersion: UInt32	{ get }
	
	///	For package use only. Use `decode()` instead.
	mutating func decodeBool()		throws -> Bool
	
	///	For package use only. Use `decode()` instead.
	mutating func decodeInt()		throws -> Int
	///	For package use only. Use `decode()` instead.
	mutating func decodeInt8()		throws -> Int8
	///	For package use only. Use `decode()` instead.
	mutating func decodeInt16()		throws -> Int16
	///	For package use only. Use `decode()` instead.
	mutating func decodeInt32()		throws -> Int32
	///	For package use only. Use `decode()` instead.
	mutating func decodeInt64()		throws -> Int64
	
	///	For package use only. Use `decode()` instead.
	mutating func decodeUInt()		throws -> UInt
	///	For package use only. Use `decode()` instead.
	mutating func decodeUInt8()		throws -> UInt8
	///	For package use only. Use `decode()` instead.
	mutating func decodeUInt16()	throws -> UInt16
	///	For package use only. Use `decode()` instead.
	mutating func decodeUInt32()	throws -> UInt32
	///	For package use only. Use `decode()` instead.
	mutating func decodeUInt64()	throws -> UInt64
	
	///	For package use only. Use `decode()` instead.
	mutating func decodeFloat()		throws -> Float
	///	For package use only. Use `decode()` instead.
	mutating func decodeDouble()	throws -> Double
	///	For package use only. Use `decode()` instead.
	mutating func decodeString()	throws -> String
	///	For package use only. Use `decode()` instead.
	mutating func decodeData()		throws -> Data
}
