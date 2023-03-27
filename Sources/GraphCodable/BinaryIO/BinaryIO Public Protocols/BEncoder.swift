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
	mutating func encode<Value> (_ value: Value ) throws where Value : BEncodable
	
	///	For package use only. Use `userVersion` instead.
	static var binaryIOVersion: UInt32 { get }
	
	///	For package use only. Use `encode( _ :Value)` instead.
	mutating func encodeBool	(_ value: Bool) 	throws
	
	///	For package use only. Use `encode( _ :Value)` instead.
	mutating func encodeInt		(_ value: Int)		throws
	///	For package use only. Use `encode( _ :Value)` instead.
	mutating func encodeInt8	(_ value: Int8)		throws
	///	For package use only. Use `encode( _ :Value)` instead.
	mutating func encodeInt16	(_ value: Int16)	throws
	///	For package use only. Use `encode( _ :Value)` instead.
	mutating func encodeInt32	(_ value: Int32)	throws
	///	For package use only. Use `encode( _ :Value)` instead.
	mutating func encodeInt64	(_ value: Int64)	throws
	
	///	For package use only. Use `encode( _ :Value)` instead.
	mutating func encodeUInt	(_ value: UInt)		throws
	///	For package use only. Use `encode( _ :Value)` instead.
	mutating func encodeUInt8	(_ value: UInt8)	throws
	///	For package use only. Use `encode( _ :Value)` instead.
	mutating func encodeUInt16	(_ value: UInt16)	throws
	///	For package use only. Use `encode( _ :Value)` instead.
	mutating func encodeUInt32	(_ value: UInt32)	throws
	///	For package use only. Use `encode( _ :Value)` instead.
	mutating func encodeUInt64	(_ value: UInt64)	throws
	
	///	For package use only. Use `encode( _ :Value)` instead.
	mutating func encodeFloat	(_ value: Float)	throws
	///	For package use only. Use `encode( _ :Value)` instead.
	mutating func encodeDouble	(_ value: Double)	throws
	
	///	For package use only. Use `encode( _ :Value)` instead.
	mutating func encodeString	(_ value: String)	throws
	///	For package use only. Use `encode( _ :Value)` instead.
	mutating func encodeData	(_ value: Data)		throws
}
