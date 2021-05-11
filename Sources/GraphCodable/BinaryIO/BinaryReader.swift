//	MIT License
//
//	Copyright (c) 2021 Antonino Ficarra
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

/*
BinaryReader:
	• convert from file little-endian format to the machine format
	• convert Int, UInt stored as Int64, UInt64 to Int, UInt in machine size
		(throws an error if it is not possible)
*/

// faster than BinaryReaderBase<Data> even if bytes originally comes from Data
public typealias BinaryReader = BinaryReaderBase<Array<UInt8>>
//	public typealias BinaryReader = BinaryReaderBase<Data>


public struct BinaryReaderBase<T>
where T:MutableDataProtocol, T:ContiguousBytes, T.SubSequence:ContiguousBytes {
	private let base:	T
	private var bytes:	T.SubSequence
	
	init( bytes: T ) {
		self.base	= bytes
		self.bytes	= bytes[ ... ]
	}

	init<Q>( data: Q ) where Q:Sequence, Q.Element==UInt8 {
		if let bytes = data as? T {
			self.init( bytes: bytes )
		} else {
			self.init( bytes: T(data) )
		}
	}

	var eof : Bool {
		return bytes.count == 0
	}

	mutating func readBool() throws -> Bool {
		var value = false
		try readValue( &value )
		return value
	}
	
	mutating func readInt8 () throws -> Int8 	{ return try Int8 ( littleEndian: readInteger() ) }
	mutating func readInt16() throws -> Int16	{ return try Int16( littleEndian: readInteger() ) }
	mutating func readInt32() throws -> Int32	{ return try Int32( littleEndian: readInteger() ) }
	mutating func readInt64() throws -> Int64	{ return try Int64( littleEndian: readInteger() ) }

	mutating func readUInt8 () throws -> UInt8  { return try UInt8 ( littleEndian: readInteger() ) }
	mutating func readUInt16() throws -> UInt16 { return try UInt16( littleEndian: readInteger() ) }
	mutating func readUInt32() throws -> UInt32 { return try UInt32( littleEndian: readInteger() ) }
	mutating func readUInt64() throws -> UInt64 { return try UInt64( littleEndian: readInteger() ) }

	mutating func readFloat() throws -> Float	{ return try Float(bitPattern: readUInt32()) }
	mutating func readDouble() throws -> Double	{ return try Double(bitPattern: readUInt64()) }

	mutating func readInt() throws -> Int		{
		let value64 = try readInt64()
		guard let value = Int( exactly: value64 ) else {
			throw BinaryIOError.initTypeError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Int64 \(value64) can't be converted to Int."
				)
			)
		}
		return value
	}
	
	mutating func readUInt() throws -> UInt		{
		let value64 = try readUInt64()
		guard let value = UInt( exactly: value64 ) else {
			throw BinaryIOError.initTypeError(
				Self.self, BinaryIOError.Context(
					debugDescription: "UInt64 \(value64) can't be converted to UInt."
				)
			)
		}
		return value
	}
	
	// private section ---------------------------------------------------------

	private func checkRemainingSize( size:Int ) throws {
		if bytes.count < size {
			throw BinaryIOError.outOfBounds(
				Self.self, BinaryIOError.Context(
					debugDescription: "\(size) bytes requested; \(bytes.count) bytes remaining."
				)
			)
		}
	}

	private mutating func readInteger<T:BinaryInteger>() throws -> T {
		var value = T()
		try readValue( &value )
		return value
	}

	// usafe section ---------------------------------------------------------
	private mutating func readValue<T>( _ v : inout T ) throws {
		let inSize	= MemoryLayout<T>.size
		try checkRemainingSize( size:inSize )
		defer { bytes.removeFirst( inSize ) }
		
		bytes.withUnsafeBytes { source in
			withUnsafeMutableBytes(of: &v) { target in
				_ = memcpy( target.baseAddress, source.baseAddress, inSize )
			}
		}
	}

	mutating func readData<T>() throws -> T where T:MutableDataProtocol, T:ContiguousBytes {
		let count = try readInt64()

		let inSize	= Int(count) * MemoryLayout<UInt8>.stride
		try checkRemainingSize( size: inSize )
		defer { bytes.removeFirst( inSize ) }

		return bytes.withUnsafeBytes { source in
			return T( source.prefix( inSize ) )
		}
	}

	// read a null terminated utf8 string
	mutating func readString() throws -> String {
		let availableCount	= bytes.count
		
		// ci deve essere almeno un carattere: null
		guard availableCount > 0 else {
			throw BinaryIOError.outOfBounds(
				Self.self, BinaryIOError.Context(
					debugDescription: "No more bytes available for a null terminated string."
				)
			)
		}
		
		var inSize = 0
		let string = try bytes.withUnsafeBytes { source -> String in
			guard let baseAddress = source.baseAddress else {
				throw BinaryIOError.outOfBounds(
					Self.self, BinaryIOError.Context(
						debugDescription: "This should never happen."
					)
				)
			}
			let ptr	= UnsafePointer<UInt8>( OpaquePointer( baseAddress ) )
			// non posso superare bytesCount
			for index in 0..<availableCount {
				if ptr[index] == 0 {	// ho trovato NULL
					inSize = index + 1
					return String(cString: ptr)
				}
			}
			// ho superato bytesCount!
			throw BinaryIOError.outOfBounds(
				Self.self, BinaryIOError.Context(
					debugDescription: "No more bytes available for a null terminated string."
				)
			)
		}
		bytes.removeFirst( inSize )
		return string
	}
}
