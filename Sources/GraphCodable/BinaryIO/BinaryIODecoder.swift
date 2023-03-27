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
 BinaryIODecoder:
 • convert from file little-endian format to the machine format
 • convert Int, UInt stored as Int64, UInt64 to Int, UInt in machine size
 (throws an error if it is not possible)
 */
/// Buffer to read instances of BDecodable types from.
///
///
///
public struct BinaryIODecoder: BDecoder {
	private let base					: Bytes
	private var bytes					: Bytes.SubSequence
	let startOfFile						: Int
	//	readed version for library types
	public let	encodedBinaryIOVersion	: UInt32
	//	public readed version for user defined types
	public let	encodedUserVersion		: UInt32
	public var	dataSize				: Int 	{ base.count }
	public let	userData				: Any?
}

//	MAKE THIS EXTENSION PUBLIC IF YOU WANT TO USE BinaryIO
//	AS A STANDALONE LIBRARY WITH ADVANCED FUNCTIONALITIES
extension BinaryIODecoder {
	var isEndOfFile	: Bool			{ bytes.count == 0 }
	var fullRegion	: Range<Int>	{ startOfFile ..< base.endIndex }
	
	init( bytes base: Bytes, userData:Any? = nil ) throws {
		var bytes					= base[...]
		self.encodedBinaryIOVersion	= try Self.readValue(from: &bytes)
		self.encodedUserVersion		= try Self.readValue(from: &bytes)
		self.base					= base
		self.bytes					= bytes
		self.startOfFile			= bytes.startIndex
		self.userData				= userData
	}
	
	init<Q>( data: Q, userData:Any? = nil ) throws where Q:DataProtocol {
		if let bytes = data as? Bytes {
			try self.init( bytes: bytes, userData:userData )
		} else {
			try self.init( bytes: Bytes(data), userData:userData )
		}
	}
	
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
	
	var regionRange: Range<Int> {
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

// private section ---------------------------------------------------------
extension BinaryIODecoder {
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
extension BinaryIODecoder {
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
	
}

// private section ----------------------------

extension BinaryIODecoder {
	//	Bool
	private mutating func readBool() throws -> Bool 	{ return try readValue() }
	
	//	Integers
	private mutating func readFixedSizeInteger<T> () throws -> T where T:FixedWidthInteger {
		// Integers are always archived in littleEndian format
		try T( littleEndian: readValue() )
	}
	
	private mutating func readFixedSizeInteger() throws -> Int 	{
		// Int are always archived as Int64
		let value64 = try readFixedSizeInteger() as Int64
		guard let value = Int( exactly: value64 ) else {
			throw BinaryIOError.libDecodingError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Int64 \(value64) can't be converted to Int."
				)
			)
		}
		return value
	}
	
	private mutating func readFixedSizeInteger() throws -> UInt {
		// UInt are always archived as UInt64
		let value64 = try readFixedSizeInteger() as UInt64
		guard let value = UInt( exactly: value64 ) else {
			throw BinaryIOError.libDecodingError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Int64 \(value64) can't be converted to Int."
				)
			)
		}
		return value
	}
	//	Floats
	
	private mutating func readFloat() throws -> Float {
		try Float(bitPattern: readFixedSizeInteger())
	}
	
	private mutating func readDouble() throws -> Double	{
		try Double(bitPattern: readFixedSizeInteger())
	}
	
	// read a null terminated utf8 string
	private mutating func readString<T>() throws -> T where T:StringProtocol {
		var inSize = 0
		
		let string = try bytes.withUnsafeBytes {
			try $0.withMemoryRebound( to: Int8.self ) { buffer in
				for char in buffer {
					inSize += 1
					if char == 0 {	// ho trovato NULL
						return T( cString: buffer.baseAddress! )
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
	
	//	Data
	private mutating func readData<T>() throws -> T where T:MutableDataProtocol {
		let count	= try readFixedSizeInteger() as Int
		let inSize	= count * MemoryLayout<UInt8>.size
		try checkRemainingSize( size: inSize )
		defer { bytes.removeFirst( inSize ) }
		
		return bytes.withUnsafeBytes { source in
			return T( source.prefix( inSize ) )
		}
	}
}

extension BinaryIODecoder {
	public mutating func decode<Value>() throws -> Value where Value : BDecodable { try Value(from: &self) }
	
	public mutating func decodeBool()	throws -> Bool		{ try readBool() }
	
	public mutating func decodeInt()	throws -> Int		{ try readFixedSizeInteger() }
	public mutating func decodeInt8()	throws -> Int8		{ try readFixedSizeInteger() }
	public mutating func decodeInt16()	throws -> Int16		{ try readFixedSizeInteger() }
	public mutating func decodeInt32()	throws -> Int32		{ try readFixedSizeInteger() }
	public mutating func decodeInt64()	throws -> Int64		{ try readFixedSizeInteger() }
	
	public mutating func decodeUInt()	throws -> UInt		{ try readFixedSizeInteger() }
	public mutating func decodeUInt8()	throws -> UInt8		{ try readFixedSizeInteger() }
	public mutating func decodeUInt16()	throws -> UInt16	{ try readFixedSizeInteger() }
	public mutating func decodeUInt32()	throws -> UInt32	{ try readFixedSizeInteger() }
	public mutating func decodeUInt64()	throws -> UInt64	{ try readFixedSizeInteger() }
	
	public mutating func decodeFloat()	throws -> Float		{ try readFloat() }
	public mutating func decodeDouble()	throws -> Double	{ try readDouble() }
	public mutating func decodeString()	throws -> String	{ try readString() }
	public mutating func decodeData()	throws -> Data		{ try readData() }
	
	public mutating func peek<Value>( _ accept:( Value ) -> Bool ) -> Value?
	where Value : BDecodable {
		let position	= regionStart
		do {
			let value = try decode() as Value
			if accept( value ) { return value }
		}
		catch {}
		
		regionStart	= position
		return nil
	}
}

