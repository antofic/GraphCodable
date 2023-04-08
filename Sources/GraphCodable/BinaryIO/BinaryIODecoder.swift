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


	///	Encoded flags.
	///
	///	Reserved for package use.
	let	encodedBinaryIOFlags			: BinaryIOFlags
	
	///	Encoded version for library types.
	///
	///	Reserved for package use.
	let	encodedBinaryIOVersion			: UInt16
	
	public let encodedArchiveIdentifier		: String?

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
	
	///	The first bytes of the file are reserved so the file
	///	data section begins from `startOfFile` offset.
	public let	startOfFile				: Int
	
	///	The total file dimension in bytes, including
	///	the reserved initial bytes.
	///
	///	The real size in bytes of encoded data is
	///	`fileSize - startOfFile`
	public var	fileSize				: Int 	{ data.count }
	
	
	private var _enableCompression		: Bool
	public var enableCompression		: Bool {
		get { _enableCompression }
		set { _enableCompression = newValue && encodedBinaryIOFlags.contains( .compressionEnabled ) }
	}
}

extension BinaryIODecoder {
	/// Creates a new instance of `BinaryIODecoder`.
	///
	/// - Parameter data: The data to read from.
	///	- Parameter userData: User defined data for decoding strategies.
	public init<Q>( data: Q, archiveIdentifier: String? = defaultBinaryIOArchiveIdentifier, userData:Any? = nil ) throws where Q:DataProtocol {
		if let data = data as? Bytes {
			try self.init( data, archiveIdentifier:archiveIdentifier, userData:userData )
		} else {
			try self.init( Bytes(data), archiveIdentifier:archiveIdentifier, userData:userData )
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
			guard newValue.startIndex >= startOfFile && newValue.endIndex <= data.endIndex else {
				// no precondition in the decoder
				fatalError( "\(Self.self): region \(newValue) not cointaned in \(data.indices)" )
			}
			dataRegion	= data[ newValue ]
		}
	}
}

// private init ---------------------------------------------------------
extension BinaryIODecoder {
	private init( _ data: Bytes, archiveIdentifier: String?, userData:Any?) throws {
		var dataRegion					= data[...]
		self._enableCompression			= false
		self.encodedBinaryIOFlags		= try Self.readValue(from: &dataRegion)
		if self.encodedBinaryIOFlags.contains( .hasArchiveIdentifier ) {
			self.encodedArchiveIdentifier = try Self.readString( from: &dataRegion )
		} else {
			self.encodedArchiveIdentifier = nil
		}
		if let archiveIdentifier, archiveIdentifier != self.encodedArchiveIdentifier {
			throw BinaryIOError.archiveIdentifierDontMatch(
				Self.self, BinaryIOError.Context(
					debugDescription: "Encoded archiveIdentifier -\(encodedArchiveIdentifier ?? "nil" )- doesn't match the requested identifier -\(archiveIdentifier)-."
				)
			)
		}
		if self.encodedBinaryIOFlags.contains( .compressionEnabled ) {
			self.encodedBinaryIOVersion	= try Self.readAndUnpack(from: &dataRegion)
			self.encodedUserVersion		= try Self.readAndUnpack(from: &dataRegion)
		} else {
			self.encodedBinaryIOVersion	= try Self.readValue(from: &dataRegion)
			self.encodedUserVersion		= try Self.readValue(from: &dataRegion)
		}
		self.data						= data
		self.dataRegion					= dataRegion
		self.startOfFile				= dataRegion.startIndex
		self.userData					= userData
		self.enableCompression			= true
	}
}

// private static section ----------------------------------------------------
extension BinaryIODecoder {
	/// read a pod value
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
	
	private static func readAndUnpack<T>( from dataRegion:inout Bytes.SubSequence ) throws -> T
	where T:FixedWidthInteger, T:UnsignedInteger {
		var	byte	= try readValue( from:&dataRegion ) as UInt8
		var	val		= T( byte & 0x7F )
		
		for index in 1...MemoryLayout<Self>.size {
			guard byte & 0x80 != 0 else {
				return val
			}
			byte	= 	try readValue( from:&dataRegion ) as UInt8
			val		|=	T( byte & 0x7F ) &<< (index*7)
		}
		return val
	}
	
	// read a null terminated utf8 string
	private static func readString( from dataRegion:inout Bytes.SubSequence ) throws -> String {
		var inSize = 0
		
		let string = try dataRegion.withUnsafeBytes {
			try $0.withMemoryRebound( to: Int8.self ) { buffer in
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
		dataRegion.removeFirst( inSize )
		return string
	}
}

// private section ----------------------------
extension BinaryIODecoder {
	/// read a pod value
	private mutating func readPODValue<T>() throws  -> T {
		/*
		guard _isPOD(T.self) else {
			throw BinaryIOError.notPODType(
				Self.self, BinaryIOError.Context(
					debugDescription: "\(T.self) must be a POD type."
				)
			)
		}
		*/
		return try Self.readValue( from:&dataRegion )
	}
	
	private func checkRemainingSize( size:Int ) throws {
		try Self.checkRemainingSize( dataRegion, size: size )
	}

	///	Decodes and reconstructs the integer encoded by
	///	BinaryIOEncoder `readAndUnpack` function.
	private mutating func readAndUnpack<T>() throws -> T
	where T:FixedWidthInteger, T:UnsignedInteger {
		assert( MemoryLayout<T>.size > 1, "\(#function) the unsigned integer value must be at least 2 bytes." )
		
		return try Self.readAndUnpack( from:&dataRegion )
	}
}

// public section ----------------------------
extension BinaryIODecoder {
	/// Disable integers packing for the duration of the closure
	///
	/// - parameter decodeFunc: The closure
	public mutating func withCompressionDisabled<T>(
		decodeFunc: ( inout BinaryIODecoder ) throws -> T
	) rethrows -> T {
		let saveCompression	= enableCompression
		defer{ enableCompression = saveCompression }
		enableCompression = false
		return try decodeFunc( &self )
	}

	public mutating func withinRegion<T>(
		range: Range<Int>,
		decodeFunc: ( inout BinaryIODecoder ) throws -> T
	) throws -> T {
		let saveRegion	= regionRange
		defer{ regionRange = saveRegion }
		regionRange	= range
		let result	= try decodeFunc( &self )
		guard position == range.endIndex else {
			throw BinaryIOError.outOfBounds(
				Self.self, BinaryIOError.Context(
					debugDescription: "\(Self.self): decode do not consume exactly the requested region."
				)
			)
		}
		return result
	}
}

// public section ----------------------------
extension BinaryIODecoder {
	//	Generic
	public mutating func decode<Value>( _ type:Value.Type ) throws -> Value
	where Value : BDecodable {
		try Value(from: &self)
	}
	
	public mutating func peek<Value>( _ type:Value.Type, _ accept:( Value ) -> Bool ) -> Value?
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
	
	public mutating func withUnderlyingType<T>( _ apply: (inout BinaryIODecoder) throws -> T ) rethrows -> T {
		try apply( &self )
	}
}

// internal section ---------------------------------------------------------
extension BinaryIODecoder {
	//	Bool
	mutating func decodeBool() throws -> Bool {
		return try readPODValue()
	}
	
	//	Unsigned Integers
	mutating func decodeUInt8() throws -> UInt8	{
		try readPODValue()
	}
	
	mutating func decodeUInt16() throws -> UInt16 {
		if enableCompression {
			return try readAndUnpack()
		}
		else {
			return try UInt16( littleEndian: readPODValue() )
		}
	}
	mutating func decodeUInt32() throws -> UInt32 {
		if enableCompression {
			return try readAndUnpack()
		}
		else {
			return try UInt32( littleEndian: readPODValue() )
		}
	}
	
	mutating func decodeUInt64() throws -> UInt64	{
		if enableCompression {
			return try readAndUnpack()
		}
		else {
			return try UInt64( littleEndian: readPODValue() )
		}
	}

	mutating func decodeUInt() throws -> UInt {
		// UInt are always archived as UInt64
		let value64 = try decode() as UInt64
		guard let value = UInt( exactly: value64 ) else {
			throw BinaryIOError.libDecodingError(
				Self.self, BinaryIOError.Context(
					debugDescription: "UInt64 \(value64) can't be converted to UInt."
				)
			)
		}
		return value
	}
	
	//	Signed Integers
	mutating func decodeInt8() throws -> Int8 {
		try readPODValue()
	}
	
	mutating func decodeInt16() throws -> Int16 {
		if enableCompression {
			return ZigZag.decode( try decode() )
		} else {
			return try Int16( littleEndian: readPODValue() )
		}
	}
	mutating func decodeInt32() throws -> Int32 {
		if enableCompression {
			return ZigZag.decode( try decode() )
		} else {
			return try Int32( littleEndian: readPODValue() )
		}
	}

	mutating func decodeInt64() throws -> Int64 {
		if enableCompression {
			return ZigZag.decode( try decode() )
		} else {
			return try Int64( littleEndian: readPODValue() )
		}
	}

	mutating func decodeInt() throws -> Int {
		// Int are always archived as Int64
		let value64 = try decode() as Int64
		guard let value = Int( exactly: value64 ) else {
			throw BinaryIOError.libDecodingError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Int64 \(value64) can't be converted to Int."
				)
			)
		}
		return value
	}

	//	Floats
	mutating func decodeFloat() throws -> Float {
		let saveCompression = enableCompression
		defer { enableCompression = saveCompression }
		enableCompression = false

		return try Float(bitPattern: decode())
	}
	
	mutating func decodeDouble() throws -> Double	{
		let saveCompression = enableCompression
		defer { enableCompression = saveCompression }
		enableCompression = false

		return try Double(bitPattern: decode())
	}
	
	// read a null terminated utf8 string
	mutating func decodeString() throws -> String {
		try Self.readString( from: &dataRegion )
	}
	
	//	Data
	mutating func decodeData() throws -> Data {
		let count	= try decode() as Int
		let inSize	= count * MemoryLayout<UInt8>.size
		try checkRemainingSize( size: inSize )
		defer { dataRegion.removeFirst( inSize ) }
		
		return dataRegion.withUnsafeBytes { source in
			return Data( source.prefix( inSize ) )
		}
	}
}

