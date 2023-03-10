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

/*
BinaryReadBuffer:
	• convert from file little-endian format to the machine format
	• convert Int, UInt stored as Int64, UInt64 to Int, UInt in machine size
		(throws an error if it is not possible)
*/


/// Buffer to read instances of BinaryIType types from.
///
///
///
public struct BinaryReadBuffer {
	// private version for library types
	let	privateVersion		: UInt16
	
	private let base		: Bytes
	private var bytes		: Bytes.SubSequence
	
	//	public version for user defined types
	public	let	version 	: UInt16
	public	var	dataSize	: Int 			{ base.count }
}

//	MAKE THIS EXTENSION PUBLIC IF YOU WANT TO USE BinaryIO AS A STANDALONE LIBRARY
//	public extension BinaryReadBuffer {
extension BinaryReadBuffer {
	//	MAKE THIS PROPERTY PUBLIC IF YOU WANT TO USE BinaryIO AS A STANDALONE LIBRARY
	var startOfFile			: Int			{ MemoryLayout.size(ofValue: privateVersion) + MemoryLayout.size(ofValue: version) }
	
	//	MAKE THIS PROPERTY PUBLIC IF YOU WANT TO USE BinaryIO AS A STANDALONE LIBRARY
	var isEndOfFile			: Bool			{ bytes.count == 0 }
	
	//	MAKE THIS PROPERTY PUBLIC IF YOU WANT TO USE BinaryIO AS A STANDALONE LIBRARY
	var fullRegion			: Range<Int>	{ startOfFile ..< base.endIndex }
	
	//	MAKE THIS FUNCTION PUBLIC IF YOU WANT TO USE BinaryIO AS A STANDALONE LIBRARY
	init( bytes base: Bytes ) throws {
		var bytes			= base[...]
		self.privateVersion	= try Self.readValue(from: &bytes)
		self.version		= try Self.readValue(from: &bytes)
		self.base			= base
		self.bytes			= bytes
	}
	
	//	MAKE THIS FUNCTION PUBLIC IF YOU WANT TO USE BinaryIO AS A STANDALONE LIBRARY
	init<Q>( data: Q ) throws where Q:Sequence, Q.Element==UInt8 {
		if let bytes = data as? Bytes {
			try self.init( bytes: bytes )
		} else {
			try self.init( bytes: Bytes(data) )
		}
	}
	
	//	MAKE THIS FUNCTION PUBLIC IF YOU WANT TO USE BinaryIO AS A STANDALONE LIBRARY
	///	regionStart can precede the current region start
	///	but cannot exceed the current region end
	var regionStart: Int {
		get { bytes.startIndex }
		set {
			precondition(
				(startOfFile...bytes.endIndex).contains( newValue ),
				"\(Self.self): regionStart \(newValue) beyond current region end \(bytes.endIndex)"
			)
			bytes	= base[ newValue..<bytes.endIndex ]
		}
	}
	
	//	MAKE THIS FUNCTION PUBLIC IF YOU WANT TO USE BinaryIO AS A STANDALONE LIBRARY
	var region: Range<Int> {
		get { bytes.indices }
		set {
			precondition(
				newValue.startIndex >= startOfFile &&
				newValue.endIndex <= base.endIndex,
				"\(Self.self): region \(newValue) not cointaned in \(base.indices)"
			)
			bytes	= base[ newValue ]
		}
	}
}

// internal section ---------------------------------------------------------
extension BinaryReadBuffer {
	mutating func readData<T>() throws -> T where T:MutableDataProtocol, T:ContiguousBytes {
		let count = try readInt64()
		
		let inSize	= Int(count) * MemoryLayout<UInt8>.size
		try checkRemainingSize( size: inSize )
		defer { bytes.removeFirst( inSize ) }
		
		return bytes.withUnsafeBytes { source in
			return T( source.prefix( inSize ) )
		}
	}
	
	// read a null terminated utf8 string
	mutating func readString() throws -> String {
		return try Self.readString(bytes: &bytes)
	}
}

// private section ---------------------------------------------------------
extension BinaryReadBuffer {
	private mutating func readValue<T>() throws  -> T {
		guard _isPOD(T.self) else {
			throw BinaryIOError.notPODType(
				Self.self, BinaryIOError.Context(
					debugDescription: "\(T.self) must be a POD type."
				)
			)
		}
		return try Self.readValue( from:&bytes )
	}
	
	private func checkRemainingSize( size:Int ) throws {
		try Self.checkRemainingSize(bytes: bytes, size: size)
	}
}

// private static section ----------------------------------------------------
extension BinaryReadBuffer {
	private static func readValue<T>( from bytes:inout Bytes.SubSequence ) throws  -> T {
		let inSize	= MemoryLayout<T>.size
		try checkRemainingSize( bytes: bytes, size:inSize )
		defer { bytes.removeFirst( inSize ) }

		return bytes.withUnsafeBytes { source in
#if swift(>=5.7)
			source.loadUnaligned(as: T.self)
#elseif swift(>=5.6)
			withUnsafeTemporaryAllocation(of: T.self, capacity: 1) {
				let temporary = $0.baseAddress!
				memcpy( temporary, source.baseAddress, inSize )
				return temporary.pointee
			}
#else
#error("Minimum swift version = 5.6")
#endif
		}
	}

	private static func checkRemainingSize( bytes:Bytes.SubSequence, size:Int ) throws {
		if bytes.count < size {
			throw BinaryIOError.outOfBounds(
				Self.self, BinaryIOError.Context(
					debugDescription: "\(size) bytes requested; \(bytes.count) bytes remaining."
				)
			)
		}
	}
	
	// read a null terminated utf8 string
	private static func readString( bytes:inout Bytes.SubSequence ) throws -> String {
		var inSize = 0

		let string = try bytes.withUnsafeBytes {
			try $0.withMemoryRebound( to: UInt8.self ) { buffer in
				for char in buffer {
					inSize += 1
					if char == 0 {	// ho trovato NULL
						return String( cString: buffer.baseAddress! )
					}
				}
				
				throw BinaryIOError.outOfBounds(
					Self.self, BinaryIOError.Context(
						debugDescription: "No more bytes available for a null terminated string."
					)
				)
			}
		}
		// ci deve essere almeno un carattere: null
		guard inSize > 0 else {
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

// internal section: utilities ---------------------------------------------------------
extension BinaryReadBuffer {
	mutating func readBool() throws -> Bool {
		return try readValue()
	}
	
	mutating func readInt8 () throws -> Int8 	{ try Int8 ( littleEndian: readValue() ) }
	mutating func readInt16() throws -> Int16	{ try Int16( littleEndian: readValue() ) }
	mutating func readInt32() throws -> Int32	{ try Int32( littleEndian: readValue() ) }
	mutating func readInt64() throws -> Int64	{ try Int64( littleEndian: readValue() ) }

	mutating func readUInt8 () throws -> UInt8  { try UInt8 ( littleEndian: readValue() ) }
	mutating func readUInt16() throws -> UInt16 { try UInt16( littleEndian: readValue() ) }
	mutating func readUInt32() throws -> UInt32 { try UInt32( littleEndian: readValue() ) }
	mutating func readUInt64() throws -> UInt64 { try UInt64( littleEndian: readValue() ) }

	mutating func readFloat() throws -> Float	{ try Float(bitPattern: readUInt32()) }
	mutating func readDouble() throws -> Double	{ try Double(bitPattern: readUInt64()) }

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
}

