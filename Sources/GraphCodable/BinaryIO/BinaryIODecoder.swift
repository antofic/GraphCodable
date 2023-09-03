//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

///	A value that decodes instances of a **BDecodable** type
///	from a data buffer that uses **BinaryIO** format.
public struct BinaryIODecoder: BDecoder {
	///	The full data to decode from
	private let data					: Bytes

	///	The region of the data from which the current
	///	decoding occurs.
	private var dataRegion				: Bytes.SubSequence

	/// Use `enableCompression` instead
	private var _enableCompression		: Bool

	///	Encoded flags.
	///
	///	Reserved for package use.
	let	encodedBinaryIOFlags			: BinaryIOFlags
	
	///	Encoded version for library types.
	///
	///	Reserved for package use.
	let	encodedBinaryIOVersion			: UInt16
	
	public let encodedArchiveIdentifier	: String?

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
}

// MARK: public section

extension BinaryIODecoder {
	/// Creates a new instance of `BinaryIODecoder`.
	///
	/// - Parameter data: The data to read from.
	/// - Parameter archiveIdentifier: An optional string to match the encoded identifier
	/// of the archive. A `nil` string match with any encoded `archiveIdentifier`
	/// string.
	///	- Parameter userData: User defined data for decoding strategies.
	///	GraphCodable uses this parameter to store the `decoderView` property accessible
	///	from `GBinaryDecodable` types.
	public init<Q>( data: Q, archiveIdentifier: String? = defaultBinaryIOArchiveIdentifier, userData:Any? = nil ) throws where Q:DataProtocol {
		if let data = data as? Bytes {
			try self.init( data, archiveIdentifier:archiveIdentifier, userData:userData )
		} else {
			try self.init( Bytes(data), archiveIdentifier:archiveIdentifier, userData:userData )
		}
	}

	/// Enable/Disable compression
	///
	///	You can temporarily disable and then re-enable compression by setting this variable
	///	only if compression has been enabled in the encoder's `init` method when the
	///	archive was created. If it has not been enabled, setting this variable has no effect.
	///
	///	Instead of setting this variable directly, it is preferable to use the method:
	///	```
	///	func withCompressionDisabled<T>(
	///	  decodeFunc: ( inout BinaryIODecoder ) throws -> T
	///	  ) rethrows -> T
	///	```
	/// Note: The compression must be set as it was set during encoding.
	public var enabledCompression : Bool {
		get { _enableCompression }
		set { _enableCompression = newValue && encodedBinaryIOFlags.contains( .compressionEnabled ) }
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
	
	/// Disable compression for the duration of the closure
	///
	/// - parameter decodeFunc: The closure
	/// - returns: the return value of `decodeFunc`
	public mutating func withCompressionDisabled<T>(
		decodeFunc: ( inout BinaryIODecoder ) throws -> T
	) rethrows -> T {
		let saveCompression	= enabledCompression
		defer{ enabledCompression = saveCompression }
		enabledCompression = false
		return try decodeFunc( &self )
	}

	/// Set `regionRange` for the duration of the closure
	///
	/// - parameter range: The regionRange to sets
	/// - parameter decodeFunc: The closure
	/// - returns: the return value of `decodeFunc`
	public mutating func withinRegion<T>(
		range: Range<Int>,
		decodeFunc: ( inout BinaryIODecoder ) throws -> T
	) throws -> T {
		let saveRegion	= regionRange
		defer{ regionRange = saveRegion }
		regionRange	= range
		let result	= try decodeFunc( &self )
		guard position == range.endIndex else {
			throw Errors.BinaryIO.outOfBounds(
				Self.self, Errors.Context(
					debugDescription: "|\(Self.self)|: decode do not consume exactly the requested region."
				)
			)
		}
		return result
	}
	
	/// Try peeking a value from the `decoder`.
	///
	///	`peek(_:)` try to decode a `BDecodable` value from the `decoder`.
	///	If decoding throws an error, the error is catched, the decoder
	///	cursor doesn't move and the function returns `nil`.
	/// If decoding is successful, it pass the decoded value to
	/// the `isValid` closure.
	/// If `isValid` returns `true`, the value is considered good,
	/// the `decoder` cursor moves to the next value, and `peek`
	/// returns the value.
	/// If `isValid` returns `false`, the value is not considered good,
	/// the `decoder` cursor doesn't move and `peek` returns `nil`.
	///
	/// - parameter type: The type of the value to decode
	/// - parameter isValid: A function to check the decoded value
	/// - returns: The decoded and valid value, `nil` otherwise.
	public mutating func peek<Value>(
		_ type:Value.Type, _ isValid:( Value ) -> Bool
	) -> Value?
	where Value : BDecodable {
		let initialPos	= position
		do {
			let value = try decode() as Value
			if isValid( value ) { return value }
		}
		catch {}
		
		position	= initialPos
		return nil
	}
	
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
	/// - parameter isValid: A function to check the decoded value
	/// - returns: The accepted value, `nil` otherwise.
	mutating func peek<Value:BDecodable>( _ isValid:( Value ) -> Bool ) -> Value? {
		peek( Value.self, isValid )
	}
	
	public mutating func decode<Value>( _ type:Value.Type ) throws -> Value
	where Value : BDecodable {
		try Value(from: &self)
	}
	
	public mutating func withUnderlyingDecoder<T>(
		_ decodeFunc: (inout BinaryIODecoder) throws -> T
	) rethrows -> T {
		try decodeFunc( &self )
	}
}

// MARK: internal section - primitive value decoding
extension BinaryIODecoder {
	///	Decodes a `Bool` value
	mutating func decodeBool() throws -> Bool {
		try Self.decodeBool( from: &dataRegion )
	}
	
	///	Decodes a `UInt8` value
	mutating func decodeUInt8() throws -> UInt8	{
		try Self.decodeUInt8( from: &dataRegion )
	}
	
	///	Decodes a `UInt16` value
	mutating func decodeUInt16() throws -> UInt16 {
		try Self.decodeUInt16( compress: enabledCompression, from: &dataRegion )
	}
	
	///	Decodes a `UInt32` value
	mutating func decodeUInt32() throws -> UInt32 {
		try Self.decodeUInt32( compress: enabledCompression, from: &dataRegion )
	}
	
	///	Decodes a `UInt64` value
	mutating func decodeUInt64() throws -> UInt64 {
		try Self.decodeUInt64( compress: enabledCompression, from: &dataRegion )
	}

	///	Decodes a `UInt` value
	mutating func decodeUInt() throws -> UInt {
		try Self.decodeUInt( compress: enabledCompression, from: &dataRegion )
	}
	
	///	Decodes a `Int8` value
	mutating func decodeInt8() throws -> Int8 {
		try Self.decodeInt8( from: &dataRegion )
	}
	
	///	Decodes a `Int16` value
	mutating func decodeInt16() throws -> Int16 {
		try Self.decodeInt16( compress: enabledCompression, from: &dataRegion )
	}
	
	///	Decodes a `Int32` value
	mutating func decodeInt32() throws -> Int32 {
		try Self.decodeInt32( compress: enabledCompression, from: &dataRegion )
	}

	///	Decodes a `Int64` value
	mutating func decodeInt64() throws -> Int64 {
		try Self.decodeInt64( compress: enabledCompression, from: &dataRegion )
	}

	///	Decodes a `Int` value
	mutating func decodeInt() throws -> Int {
		try Self.decodeInt( compress: enabledCompression, from: &dataRegion )
	}

	///	Decodes a `Float` value
	mutating func decodeFloat() throws -> Float {
		try Self.decodeFloat( from: &dataRegion )
	}
	
	///	Decodes a `Double` value
	mutating func decodeDouble() throws -> Double	{
		try Self.decodeDouble( from: &dataRegion )
	}
	
	/// Decodes a `String` value
	mutating func decodeString() throws -> String {
		try Self.decodeString( from: &dataRegion )
	}
	
	/// Decodes a `Data` value
	mutating func decodeData() throws -> Data {
		try Self.decodeData(compress: enabledCompression, from: &dataRegion)
	}
}

// MARK: private section

extension BinaryIODecoder {
	/// `BinaryIODecoder` "true" init method
	private init( _ data: Bytes, archiveIdentifier: String?, userData:Any?) throws {
		var dataRegion					= data[...]
		
		// decode BinaryIOFlags
		let binaryIOFlags = BinaryIOFlags( rawValue: try Self.decodeUInt16(compress: false, from: &dataRegion) )
		guard binaryIOFlags.isValid else {
			throw Errors.BinaryIO.malformedArchive(
				Self.self, Errors.Context(
					debugDescription: "Invalid encoded BinaryIOFlags |\(binaryIOFlags.rawValue)|."
				)
			)
		}
		self.encodedBinaryIOFlags 		= binaryIOFlags
		 
		// decode archiveIdentifier
		if binaryIOFlags.contains( .hasArchiveIdentifier ) {
			self.encodedArchiveIdentifier = try Self.decodeString( from: &dataRegion )
		} else {
			self.encodedArchiveIdentifier = nil
		}
		self._enableCompression			= binaryIOFlags.contains( .compressionEnabled )
		if let archiveIdentifier, archiveIdentifier != self.encodedArchiveIdentifier {
			throw Errors.BinaryIO.archiveIdentifierDontMatch(
				Self.self, Errors.Context(
					debugDescription: "Encoded archiveIdentifier |\(encodedArchiveIdentifier ?? "nil" )| doesn't match the requested identifier |\(archiveIdentifier)|."
				)
			)
		}
		// decode binaryIOVersion (compressed if enableCompression)
		self.encodedBinaryIOVersion		= try Self.decodeUInt16(compress: _enableCompression, from: &dataRegion)
		// decode userVersion (compressed if enableCompression)
		self.encodedUserVersion			= try Self.decodeUInt32(compress: _enableCompression, from: &dataRegion)
		self.data						= data
		self.dataRegion					= dataRegion
		self.startOfFile				= dataRegion.startIndex
		self.userData					= userData
	}

	/// Decodes a pod value
	private mutating func decodePODValue<T>() throws  -> T {
		return try Self.decodePODValue( from:&dataRegion )
	}
	
	/// Checks if the `dataRegion` buffer contains at least `size` bytes
	private func checkRemainingSize( size:Int ) throws {
		try Self.checkRemainingSize( dataRegion, size: size )
	}

	///	Decodes and decompress the integer encoded by
	///	BinaryIOEncoder `compressAndEncode` function.
	private mutating func decodeAndDecompress<T>() throws -> T
	where T:FixedWidthInteger, T:UnsignedInteger {
		assert( MemoryLayout<T>.size > 1, "\(#function) the unsigned integer value must be at least 2 bytes." )
		
		return try Self.decodeAndDecompress( from:&dataRegion )
	}
}

// MARK: private static section

extension BinaryIODecoder {
	/// Decodes a pod value
	///
	///	static version
	private static func decodePODValue<T>( from dataRegion:inout Bytes.SubSequence ) throws  -> T {
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
	
	/// Checks if the `dataRegion` buffer contains at least `size` bytes
	///
	///	static version
	private static func checkRemainingSize( _ dataRegion:Bytes.SubSequence, size:Int ) throws {
		if dataRegion.count < size {
			throw Errors.BinaryIO.outOfBounds(
				Self.self, Errors.Context(
					debugDescription: "|\(size)| bytes requested; |\(dataRegion.count)| bytes remaining."
				)
			)
		}
	}
	
	///	Decodes and decompress the integer encoded by
	///	BinaryIOEncoder `compressAndEncode` function.
	///
	///	static version
	private static func decodeAndDecompress<T>( from dataRegion:inout Bytes.SubSequence ) throws -> T
	where T:FixedWidthInteger, T:UnsignedInteger {
		var	byte	= try decodePODValue( from:&dataRegion ) as UInt8
		var	val		= T( byte & 0x7F )
		
		for index in 1...MemoryLayout<Self>.size {
			guard byte & 0x80 != 0 else {
				return val
			}
			byte	= 	try decodePODValue( from:&dataRegion ) as UInt8
			val		|=	T( byte & 0x7F ) &<< (index*7)
		}
		return val
	}

	///	Decodes a `Bool` value
	///
	///	static version
	private static func decodeBool( from dataRegion:inout Bytes.SubSequence ) throws -> Bool {
		return try decodePODValue( from:&dataRegion )
	}
	
	///	Decodes a `UInt8` value
	///
	///	static version
	private static func decodeUInt8( from dataRegion:inout Bytes.SubSequence ) throws -> UInt8	{
		try decodePODValue( from:&dataRegion )
	}
	
	///	Decodes a `UInt16` value
	///
	///	static version
	private static func decodeUInt16( compress:Bool, from dataRegion:inout Bytes.SubSequence ) throws -> UInt16 {
		if compress {
			return try decodeAndDecompress( from:&dataRegion )
		}
		else {
			return try UInt16( littleEndian: decodePODValue( from:&dataRegion ) )
		}
	}
	
	///	Decodes a `UInt32` value
	///
	///	static version
	private static func decodeUInt32( compress:Bool, from dataRegion:inout Bytes.SubSequence ) throws -> UInt32 {
		if compress {
			return try decodeAndDecompress( from:&dataRegion )
		}
		else {
			return try UInt32( littleEndian: decodePODValue( from:&dataRegion ) )
		}
	}
	
	///	Decodes a `UInt64` value
	///
	///	static version
	private static func decodeUInt64( compress:Bool, from dataRegion:inout Bytes.SubSequence ) throws -> UInt64 {
		if compress {
			return try decodeAndDecompress( from:&dataRegion )
		}
		else {
			return try UInt64( littleEndian: decodePODValue( from:&dataRegion ) )
		}
	}

	///	Decodes a `UInt` value
	///
	///	static version
	private static func decodeUInt( compress:Bool, from dataRegion:inout Bytes.SubSequence ) throws -> UInt {
		// UInt are always archived as UInt64
		let value64 = try decodeUInt64( compress:compress, from:&dataRegion )
		guard let value = UInt( exactly: value64 ) else {
			throw Errors.BinaryIO.libDecodingError(
				Self.self, Errors.Context(
					debugDescription: "UInt64 |\(value64)| can't be converted to UInt."
				)
			)
		}
		return value
	}
	
	///	Decodes a `Int8` value
	///
	///	static version
	private static func decodeInt8( from dataRegion:inout Bytes.SubSequence ) throws -> Int8	{
		try decodePODValue( from:&dataRegion )
	}
	
	///	Decodes a `Int16` value
	///
	///	static version
	private static func decodeInt16( compress:Bool, from dataRegion:inout Bytes.SubSequence ) throws -> Int16 {
		if compress {
			return ZigZag.decode( try decodeUInt16(compress: compress, from: &dataRegion) )
		} else {
			return try Int16( littleEndian: decodePODValue( from: &dataRegion ) )
		}
	}
	
	///	Decodes a `Int32` value
	///
	///	static version
	private static func decodeInt32( compress:Bool, from dataRegion:inout Bytes.SubSequence ) throws -> Int32 {
		if compress {
			return ZigZag.decode( try decodeUInt32(compress: compress, from: &dataRegion) )
		} else {
			return try Int32( littleEndian: decodePODValue( from: &dataRegion ) )
		}
	}

	///	Decodes a `Int64` value
	///
	///	static version
	private static func decodeInt64( compress:Bool, from dataRegion:inout Bytes.SubSequence ) throws -> Int64 {
		if compress {
			return ZigZag.decode( try decodeUInt64(compress: compress, from: &dataRegion) )
		} else {
			return try Int64( littleEndian: decodePODValue( from: &dataRegion ) )
		}
	}

	///	Decodes a `Int` value
	///
	///	static version
	private static func decodeInt( compress:Bool, from dataRegion:inout Bytes.SubSequence ) throws -> Int {
		// Int are always encoded as Int64
		let value64 = try decodeInt64( compress:compress, from: &dataRegion )
		guard let value = Int( exactly: value64 ) else {
			throw Errors.BinaryIO.libDecodingError(
				Self.self, Errors.Context(
					debugDescription: "Int64 |\(value64)| can't be converted to Int."
				)
			)
		}
		return value
	}

	///	Decodes a `Float` value
	///
	///	static version
	private static func decodeFloat( from dataRegion:inout Bytes.SubSequence ) throws -> Float {
		return try Float(bitPattern: decodeUInt32(compress: false, from: &dataRegion))
	}
	
	///	Decodes a `Double` value
	///
	///	static version
	private static func decodeDouble( from dataRegion:inout Bytes.SubSequence ) throws -> Double	{
		return try Double(bitPattern: decodeUInt64(compress: false, from: &dataRegion))
	}
	
	/// Decode a null terminated utf8 string
	///
	///	static version
	private static func decodeString( from dataRegion:inout Bytes.SubSequence ) throws -> String {
		var inSize = 0
		
		let string = try dataRegion.withUnsafeBytes {
			try $0.withMemoryRebound( to: Int8.self ) { buffer in
				for char in buffer {
					inSize += 1
					if char == 0 {	// ho trovato NULL
						return String( cString: buffer.baseAddress! )
					}
				}
				
				throw Errors.BinaryIO.outOfBounds(
					Self.self, Errors.Context(
						debugDescription: "No more bytes available for a null terminated string."
					)
				)
			}
		}
		// ci deve essere almeno un carattere: null
		guard inSize > 0 else {
			throw Errors.BinaryIO.outOfBounds(
				Self.self, Errors.Context(
					debugDescription: "No more bytes available for a null terminated string."
				)
			)
		}
		dataRegion.removeFirst( inSize )
		return string
	}
		
	/// Decodes a `Data` value
	///
	///	static version
	private static func decodeData( compress:Bool, from dataRegion:inout Bytes.SubSequence ) throws -> Data {
		let inSize	= try decodeInt( compress: compress, from: &dataRegion )
		try checkRemainingSize( dataRegion, size: inSize )
		defer { dataRegion.removeFirst( inSize ) }
		
		//	return Data( dataRegion.prefix( inSize ) ) // slower
		return dataRegion.withUnsafeBytes { source in
			return Data(bytes: source.baseAddress!, count: inSize)
		}
	}

}


