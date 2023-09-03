//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

///	A value that encodes instances of a **BEncodable** type
///	into a data buffer that uses **BinaryIO** format.
public struct BinaryIOEncoder: BEncoder {
	private var _data 				: Bytes
	private var _position			: Int
	private var _enableCompression	: Bool
	private var	insertMode			: Bool

	///	The first bytes of the file are reserved so the file
	///	data section begins from `startOfFile` offset.
	public private(set) var startOfFile 	: Int
	
	/// Actual version for BinaryIO library types
	///
	///	Reserved for package use.
	let	binaryIOFlags				: BinaryIOFlags
	
	/// Actual version for BinaryIO library types
	///
	///	Reserved for package use.
	let binaryIOVersion				: UInt16
	
	/// A sting that identifies the archive
	///
	///	You supply this value in the `init` method.
	public let archiveIdentifier	: String?
	
	/// Current version for user defined types for
	///	decoding strategies.
	///
	///	This variable must be set in the init method.
	public let userVersion			: UInt32
	
	///	User defined data for encoding strategies.
	///
	///	This variable can be set in the init method.
	///	By default it is `nil`.
	public let userData				: Any?
}

// MARK: public section

extension BinaryIOEncoder {
	/// Creates a new instance of `BinaryIODecoder`.
	///
	/// - Parameter userVersion: An user defined version for its data. It is recommended
	/// to start at 0 and increment this value by 1 each time a type change requires a
	/// different encoding so that you can continue to decode previously encoded types.
	///
	/// - Parameter archiveIdentifier: An optional string that will be encoded to identify
	/// the archive. If specified, decoding occurs only if the decoder is instantiated by
	/// specifying the same string.
	/// By default, both encoder and decoder use the string:
	/// `defaultBinaryIOArchiveIdentifier = "binaryIO"`
	/// If `nil` is specified, no `archiveIdentifier` string will be encoded. A `nil`
	/// archiveIdentifier should be used only to create temporary data internal to
	/// the application that will not be saved on disk.
	///	The GraphCodable package uses
	///	`defaultGraphCodableArchiveIdentifier = "graphCodable"`
	/// as default archive identifier string.
	///
	///	- Parameter userData: User defined data for encoding strategies.
	///	GraphCodable uses this parameter to store the `encoderView` property accessible
	///	from `GBinaryEncodable` types.
	///
	///	- Parameter enableCompression: compress integer values to reduce file size. Compression
	///	is enabled by default.
	///
	public init( userVersion: UInt32, archiveIdentifier: String? = defaultBinaryIOArchiveIdentifier, userData:Any? = nil, enableCompression:Bool = true ) {
		self.userVersion			= userVersion
		self._data					= Bytes()
		self._position				= 0
		self.startOfFile			= 0
		self.binaryIOFlags			= [ enableCompression ? .compressionEnabled : [], archiveIdentifier != nil ? .hasArchiveIdentifier : [] ]
		self.archiveIdentifier		= archiveIdentifier
		self.binaryIOVersion		= 0
		self.insertMode				= false
		self.userData				= userData
		self._enableCompression		= false
		// encode BinaryIOFlags
		try! self.encodeUInt16( self.binaryIOFlags.rawValue )	// NO compression
		self._enableCompression		= enableCompression
		// encode archiveIdentifier
		if let archiveIdentifier { try! self.encode( archiveIdentifier ) }
		// encode binaryIOVersion (compressed if enableCompression)
		try! self.encodeUInt16( self.binaryIOVersion )
		// encode userVersion (compressed if enableCompression)
		try! self.encodeUInt32( self.userVersion )
		self.startOfFile			= position
		self.enabledCompression		= enableCompression
	}

	///	Get the encoded data.
	public func data<Q>() -> Q where Q:MutableDataProtocol {
		if let data = _data as? Q {
			return data
		} else {
			return Q( _data )
		}
	}
	
	/// Enable/Disable compression
	///
	///	You can temporarily disable and then re-enable compression by setting this variable
	///	only if compression has been enabled in the encoder's `init` method.
	///	If it has not been enabled, setting this variable has no effect.
	///
	///	Instead of setting this variable directly, it is preferable to use the method:
	///	```
	///	func withCompressionDisabled<T>(
	///	  encodeFunc: ( inout BinaryIOEncoder ) throws -> T
	///	  ) rethrows -> T
	///	```
	/// Note: During decoding, compression must be enabled or disabled accordingly.
	public var enabledCompression : Bool {
		get { _enableCompression }
		set { _enableCompression = newValue && binaryIOFlags.contains( .compressionEnabled ) }
	}

	///	The current end of file position
	public var endOfFile	: Int { _data.endIndex }
	
	///	Get and sets the the position in the file in which data will be encoded.
	///
	///	If `position < endOfFile`, each coding operation **overwrites** the data present
	///	starting from position. Use `withInsertionEnabled` if you want to **insert**
	///	them instead.
	///
	///	- Note: `position` cannot be less than `startOfFile`.
	///
	///	- Note: `position` cannot be greater than the current end of the
	///	file (i.e. `endOfFile`).
	///
	/// - Note: This method is only necessary in case of **non-sequential** encoding/decoding
	/// of the archive.
	public var position: Int {
		get { _position }
		set {
			precondition( (startOfFile...endOfFile).contains( newValue ),"\(Self.self): outOfBounds position." )
			_position	= newValue
		}
	}

	/// Disable compression for the duration of the closure
	///
	/// - parameter encodeFunc: The closure
	/// - Returns: the `encodeFunc` return value
	public mutating func withCompressionDisabled<T>(
		encodeFunc: ( inout BinaryIOEncoder ) throws -> T
	) rethrows -> T {
		let saveCompression	= enabledCompression
		defer{ enabledCompression = saveCompression }
		enabledCompression = false
		return try encodeFunc( &self )
	}
	
	/// Enable **insertMode** for the duration of the closure
	///
	/// Normally the encoder writes the data adding them
	/// to those already present (if `position == endOfFile`)
	/// or otherwise overwriting them. This function allows
	/// the closure to insert data at the current position,
	/// moving forward any subsequent ones that may already
	/// be present.
	///
	/// - parameter encodeFunc: The closure
	/// - Returns: the `encodeFunc` return value
	public mutating func withInsertionEnabled<T>(
		encodeFunc: ( inout BinaryIOEncoder ) throws -> T
	) rethrows -> T {
		let saveInsertMode	= insertMode
		defer{ insertMode = saveInsertMode }
		insertMode = true
		return try encodeFunc( &self )
	}
	
	/// Encode the size of the data encoded by a closure before the data encoded by
	/// that closure.
	///
	/// Use this method when you need to know in advance the size of certain
	/// encoded data in order to decode it.
	///
	///	The encoded size type is `Int`
	///
	/// - Parameter encodeFunc: closure that encode the data.
	/// - Returns: the `encodeFunc` return value
	/// - Note: This method is only necessary in case of **non-sequential**
	/// encoding/decoding of the archive.
	public mutating func withEncodedIntSizeBefore<T>(
		encodeFunc: ( inout BinaryIOEncoder ) throws -> T
	) rethrows -> T {
		// if binaryIOFlags.contains( .compressionEnabled ) {
		if enabledCompression {
			// size verrà certamente compresso
			let initialPos	= position
			let result 		= try encodeFunc( &self )
			let finalPos	= position
			position		= initialPos
			try withInsertionEnabled {
				try $0.encode( finalPos - initialPos )
			}
			position		= finalPos + (position - initialPos)
			return result
		} else {
			let initialPos	= position
			try withCompressionDisabled {
				try $0.encode( 0 )
			}
			let bodyPos		= position
			let result		= try encodeFunc( &self )
			let finalPos	= position
			
			position		= initialPos
			try withCompressionDisabled {
				try $0.encode( finalPos - bodyPos )
			}
			position		= finalPos
			return result
		}
	}

	public mutating func withUnderlyingEncoder<T>(
		_ encodeFunc: (inout BinaryIOEncoder) throws -> T
	) rethrows -> T {
		try encodeFunc( &self )
	}
	
	public mutating func encode<Value>(_ value: Value)
	throws where Value : BEncodable {
		try value.encode(to: &self)
	}
}

// MARK:  internal section

extension BinaryIOEncoder {
	/// Encodes a `Bool` value
	mutating func encodeBool( _ value:Bool ) throws {
		try encodePODValue( value )
	}
	
	/// Encodes a `UInt8` value
	mutating func encodeUInt8( _ value:UInt8 ) throws {
		try encodePODValue( value )
	}
	
	/// Encodes a `UInt16` value
	mutating func encodeUInt16( _ value:UInt16 ) throws {
		if enabledCompression {
			try compressAndEncode( value )
		} else {
			try encodePODValue( value.littleEndian )
		}
	}
	
	/// Encodes a `UInt32` value
	mutating func encodeUInt32( _ value:UInt32 ) throws {
		if enabledCompression {
			try compressAndEncode( value )
		} else {
			try encodePODValue( value.littleEndian )
		}
	}
	
	/// Encodes a `UInt64` value
	mutating func encodeUInt64( _ value:UInt64 ) throws {
		if enabledCompression {
			try compressAndEncode( value )
		} else {
			try encodePODValue( value.littleEndian )
		}
	}

	/// Encodes a `UInt` value
	mutating func encodeUInt( _ value:UInt ) throws {
		// UInt are always archived as UInt64
		guard let value64 = UInt64( exactly: value ) else {
			throw Errors.BinaryIO.libDecodingError(
				Self.self, Errors.Context(
					debugDescription: "Int |\(value)| can't be converted to UInt64."
				)
			)
		}
		try encode( value64 )
	}

	/// Encodes a `Int8` value
	mutating func encodeInt8( _ value:Int8 ) throws {
		try encodePODValue( value )
	}

	
	/// Encodes a `Int16` value
	mutating func encodeInt16( _ value:Int16 ) throws {
		if enabledCompression {
			try encode( ZigZag.encode( value ) )
		}
		else {
			try encodePODValue( value.littleEndian )
		}
	}
	
	/// Encodes a `Int32` value
	mutating func encodeInt32( _ value:Int32 ) throws {
		if enabledCompression {
			try encode( ZigZag.encode( value ) )
		}
		else {
			try encodePODValue( value.littleEndian )
		}
	}
	
	/// Encodes a `Int64` value
	mutating func encodeInt64( _ value:Int64 ) throws {
		if enabledCompression {
			try encode( ZigZag.encode( value ) )
		}
		else {
			try encodePODValue( value.littleEndian )
		}
	}
	
	/// Encodes a `Int` value
	mutating func encodeInt( _ value:Int ) throws {
		// Int are always archived as Int64
		guard let value64 = Int64( exactly: value ) else {
			throw Errors.BinaryIO.libDecodingError(
				Self.self, Errors.Context(
					debugDescription: "Int |\(value)| can't be converted to Int64."
				)
			)
		}
		try encode( value64 )
	}
		
	/// Encodes a `Float` value
	mutating func encodeFloat( _ value:Float ) throws {
		let saveCompression = enabledCompression
		defer { enabledCompression = saveCompression }
		enabledCompression = false
		
		try encode( value.bitPattern )
	}
	
	/// Encodes a `Double` value
	mutating func encodeDouble( _ value:Double ) throws {
		let saveCompression = enabledCompression
		defer { enabledCompression = saveCompression }
		enabledCompression = false
		
		try encode( value.bitPattern )
	}
	
	/// Encodes a `String` value
	///
	/// Strings are encoded as null terminated sequences
	/// of utf8 values
	mutating func encodeString( _ value:String ) throws {
		try value.withCString() { ptr in
			var endptr	= ptr
			while endptr.pointee != 0 { endptr += 1 }	// null terminated
			let size = endptr - ptr + 1
			try ptr.withMemoryRebound(to: UInt8.self, capacity: size ) {
				try encode( contentsOf: UnsafeBufferPointer( start: $0, count: size ) )
			}
		}
	}

	/// Encodes a `Data` value
	mutating func encodeData( _ value:Data ) throws {
		try encode( value.count )
		//	try encode( contentsOf:value ) // slower
		
		for region in value.regions {
			try region.withUnsafeBytes { source in
				try encode(contentsOf: source)
			}
		}
	}
}

// MARK: private section

extension BinaryIOEncoder {
	/// Encodes a bytes collection
	private mutating func encode<C>( contentsOf source:C ) throws
	where C:RandomAccessCollection, C.Element == UInt8 {
		if position == _data.endIndex {
			_data.append( contentsOf: source )
		} else if position >= _data.startIndex {
			if insertMode { // insert
				_data.insert( contentsOf: source, at: position )
			} else { // overwrite
				_data.replaceSubrange(
					Range( uncheckedBounds: (position, position + source.count)
					).clamped(to: _data.indices), with: source
				)
			}
		} else {
			throw Errors.BinaryIO.outOfBounds(
				Self.self, Errors.Context(
					debugDescription: "|\(Self.self)|: file position out of data bounds."
				)
			)
		}
		position += source.count
	}

	/// Encodes a pod value
	private mutating func encodePODValue<T>( _ value:T ) throws {
		try withUnsafePointer(to: value) { source in
			let size = MemoryLayout<T>.size
			try source.withMemoryRebound(to: UInt8.self, capacity: size ) {
				try encode( contentsOf: UnsafeBufferPointer( start: $0, count: size ) )
			}
		}
	}

	///	Transforms an **unsigned integer** of size n into at most n+1 bytes
	///	(worst case) but much less for small numbers, and then encodes them.
	///
	///	It usually greatly reduces the size of the generated archive.
	private mutating func compressAndEncode<T>( _ value:T )
	throws where T:FixedWidthInteger, T:UnsignedInteger {
		assert(
			MemoryLayout<T>.size > 1,
			"\(#function) the unsigned integer value must be at least 2 bytes."
		)

		var	val		= value
		var byte	= UInt8( val & 0x7F )
		
		while val & (~0x7F) != 0 {
			byte 	|= 0x80
			try 	encodePODValue( byte )
			val 	&>>= 7
			byte	= UInt8( val & 0x7F )
		}
		try encodePODValue( byte )
	}
}


