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


///	A value that decodes instances of a **BDecodable** type
///	from a data buffer that uses **BinaryIO** format.
public struct BinaryIODecoder: BDecoder {
	///	The full data to decode from
	private let data					: Bytes
	
	///	The region of the data from which the current
	///	decoding occurs.
	///
	///	It is automatically updated during decoding.
	///
	///	It can be changed with X and Y.
	private var dataRegion				: Bytes.SubSequence
	
	///	The first bytes of the file are reserved so the file
	///	data section begins from `startOfFile` offset.
	public let	startOfFile				: Int
	
	///	Encoded flags.
	///
	///	Accessible for information only.
	public let	encodedBinaryIOFlags	: BinaryIOFlags

	///	Encoded version for library types.
	///
	///	Accessible for information only.
	public let	encodedBinaryIOVersion	: UInt16
	
	///	Encoded version for user defined types for
	///	decoding strategies.
	///
	///	Use for your decoding strategies.
	public let	encodedUserVersion		: UInt32
	
	///	User defined data for decoding strategies.
	///
	///	This variable can be set in the init method.
	///	By default it is `nil`.
	public let	userData				: Any?
	
	///	The total file dimension in bytes, including
	///	the reserved initial bytes.
	///
	///	The real size in bytes of encoded data is
	///	`fileSize - startOfFile`
	public var	fileSize				: Int 	{ data.count }
}

extension BinaryIODecoder {
	/// Creates a new instance of `BinaryIODecoder`.
	///
	/// - Parameter data: The data to read from.
	///	- Parameter userData: User defined data for decoding strategies.
	public init<Q>( data: Q, userData:Any? = nil ) throws where Q:DataProtocol {
		if let data = data as? Bytes {
			try self.init( data, userData:userData )
		} else {
			try self.init( Bytes(data), userData:userData )
		}
	}

	///	Check if the end of the current region has been reached.
	///
	/// If no region has been set, return `true` if the end of the
	/// file has been reached.
	/// - returns: `true` if the end of the current region has been reached,
	/// `false` otherwise.
	public var isEndOfRegion	: Bool			{ dataRegion.count == 0 }
	
	///	Returns the maximum region that can be set.
	///
	/// The maximum region that can be set starts from `startOfFile`
	/// and ends at the end of the file.
	public var fullFileRegion	: Range<Int>	{ startOfFile ..< data.endIndex }

	///	Reads and sets the start of region, i.e. the position in
	///	the file from which data will be decoded.
	///
	///	`position` and `regionRange.startIndex` are the same thing.
	///
	///	`position` cannot be less than `startOfFile`.
	///
	///	`position` cannot be greater than the end of the
	///	current region (i.e. `regionRange.endIndex`).
	///
	/// To change the end of the current region, use `regionRange`.
	///
	/// - Note: This method is only necessary in case of **non-sequential** encoding/decoding
	/// of the archive.
	public var position: Int {
		get { dataRegion.startIndex }
		set { regionRange = newValue ..< regionRange.endIndex }
	}
	
	///	Reads and sets the current region range.
	///
	///	`regionRange` is the area of the file where the data decoding
	///	starts and ends.
	///
	///	`regionRange.startIndex` and `position` are the same thing.
	///
	///	`regionRange.startIndex` cannot be less than `startOfFile`.
	///
	///	`regionRange.endIndex` cannot be more than `fullFileRegion.endIndex`.
	///
	///	When using regions it is often convenient to save the current region,
	///	set the desired region, and restore the saved region when finished
	///	reading, as in the following example:
	///	```
	///	let saveRegion = myDecoder.regionRange
	///	defer { myDecoder.regionRange = saveRegion }
	///	/* ... */
	///
	///	```
	/// To restore reading of the entire file starting from `startOfFile`,
	/// use `myDecoder.regionRange = myDecoder.fullFileRegion`.
	///
	/// - Note: This method is only necessary in case of **non-sequential** encoding/decoding
	/// of the archive.
	public var regionRange: Range<Int> {
		get { dataRegion.indices }
		set {
			precondition(
				newValue.startIndex >= startOfFile &&
				newValue.endIndex <= data.endIndex,
				"\(Self.self): region \(newValue) not cointaned in \(data.indices)"
			)
			dataRegion	= data[ newValue ]
		}
	}
}

// private init ---------------------------------------------------------
extension BinaryIODecoder {
	private init( _ data: Bytes, userData:Any? = nil ) throws {
		var dataRegion				= data[...]
		self.encodedBinaryIOFlags	= try Self.readValue(from: &dataRegion)
		self.encodedBinaryIOVersion	= try Self.readValue(from: &dataRegion)
		self.encodedUserVersion		= try Self.readValue(from: &dataRegion)
		self.data					= data
		self.dataRegion				= dataRegion
		self.startOfFile			= dataRegion.startIndex
		self.userData				= userData
	}
}

// private static section ----------------------------------------------------
extension BinaryIODecoder {
	private static func readValue<T>( from dataRegion:inout Bytes.SubSequence ) throws  -> T {
		let inSize	= MemoryLayout<T>.size
		try checkRemainingSize( dataRegion, size:inSize )
		defer { dataRegion.removeFirst( inSize ) }
		
		return dataRegion.withUnsafeBytes { source in
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
	
	private static func checkRemainingSize( _ dataRegion:Bytes.SubSequence, size:Int ) throws {
		if dataRegion.count < size {
			throw BinaryIOError.outOfBounds(
				Self.self, BinaryIOError.Context(
					debugDescription: "\(size) bytes requested; \(dataRegion.count) bytes remaining."
				)
			)
		}
	}
}

// private section ----------------------------
extension BinaryIODecoder {
	// read a pod type
	private mutating func readValue<T>() throws  -> T {
		guard _isPOD(T.self) else {
			throw BinaryIOError.notPODType(
				Self.self, BinaryIOError.Context(
					debugDescription: "\(T.self) must be a POD type."
				)
			)
		}
		return try Self.readValue( from:&dataRegion )
	}
	
	private func checkRemainingSize( size:Int ) throws {
		try Self.checkRemainingSize( dataRegion, size: size )
	}
	
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
					debugDescription: "UInt64 \(value64) can't be converted to UInt."
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
		
		let string = try dataRegion.withUnsafeBytes {
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
		dataRegion.removeFirst( inSize )
		return string
	}
	
	//	Data
	private mutating func readData<T>() throws -> T where T:MutableDataProtocol {
		let count	= try readFixedSizeInteger() as Int
		let inSize	= count * MemoryLayout<UInt8>.size
		try checkRemainingSize( size: inSize )
		defer { dataRegion.removeFirst( inSize ) }
		
		return dataRegion.withUnsafeBytes { source in
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
		let initialPos	= position
		do {
			let value = try decode() as Value
			if accept( value ) { return value }
		}
		catch {}
		
		position	= initialPos
		return nil
	}
}

