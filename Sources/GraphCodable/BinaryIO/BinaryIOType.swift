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

/// The bytes container used by `BinaryReadBuffer` and `BinaryWriteBuffer`
///
/// The container must conform to `MutableDataProtocol`, i.e `Data`, `[UInt8]`, `ContiguousArray<UInt8>`
public typealias Bytes	= [UInt8]

/// A type that can write itself into a `BinaryWriteBuffer` istance
public protocol BinaryOType {
	/// Writes this value into the given istance of `BinaryWriteBuffer`.
	///
	/// This function throws an error if any values are invalid for the given
	/// istance of `BinaryWriteBuffer`.
	///
	/// - Parameter wbuffer: The `BinaryWriteBuffer` istance
	/// to write data to.
	func write( to wbuffer: inout BinaryWriteBuffer ) throws
}

public extension BinaryOType {
	///	Write the value in a byte buffer
	///
	///	The root value must conform to the BinaryOType protocol
	/// - returns: The byte buffer.
	func binaryData<Q>( version:UInt16, userInfo:[String:Any] = [:] ) throws -> Q where Q:MutableDataProtocol {
		var wbuffer = BinaryWriteBuffer( version:version,userInfo:userInfo )
		try write( to:&wbuffer )
		return wbuffer.data()
	}
}

/// A type that can read itself from a `BinaryReadBuffer` istance
public protocol BinaryIType {
	/// Creates a new instance by reading it from the given
	/// istance of `BinaryReadBuffer`.
	///
	/// This initializer throws an error if reading fails, or
	/// if the data read is corrupted or otherwise invalid.
	/// - Parameter rbuffer: The `BinaryReadBuffer` istance
	/// to read data from.
	init( from rbuffer: inout BinaryReadBuffer ) throws
}

public extension BinaryIType {
	///	Decode the root value from the byte buffer
	///
	///	The root value must conform to the `BinaryIType` protocol
	init<Q>( binaryData: Q, userInfo:[String:Any] = [:] ) throws where Q:Sequence, Q.Element==UInt8 {
		var rbuffer = try BinaryReadBuffer( data:binaryData,userInfo:userInfo )
		try self.init( from: &rbuffer )
	}
	
	/// Try peeking a value of type `Self` from the `rbuffer`.
	///
	///	Peek try to read a value of type `Self` from the `rbuffer`.
	///	If reading throws an error, the error is catched, the `rbuffer`
	///	cursor doesn't move and the function returns `nil`.
	/// If reading is successful, it pass the value to the `accept`
	/// function.
	/// If accept returns `true`, the value is considered good,
	/// the `rbuffer` cursor moves to the next value, and the function
	/// returns the value.
	/// If accept returns `false`, the value is not considered good,
	/// the `rbuffer` cursor doesn't move, and the function returns `nil`.
	///
	/// - parameter rbuffer: The BinaryReadBuffer istance to read data from.
	/// - parameter accept: A function to check the readed value
	/// - returns: The accepted value, `nil` otherwise.
	static func peek( from rbuffer: inout BinaryReadBuffer, _ accept:( Self ) -> Bool ) -> Self? {
		let position	= rbuffer.regionStart
		do {
			let value = try Self(from: &rbuffer)
			if accept( value ) { return value }
		}
		catch {}

		rbuffer.regionStart	= position
		return nil
	}
}

/// A type that can write itself to a byte buffer
///	and read itself from a byte buffer.
public typealias BinaryIOType	= BinaryIType & BinaryOType


