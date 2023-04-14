//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

/*
 BinaryIOEncoder data format uses always:
 • little-endian
 • store Int, UInt as Int64, UInt64
*/

///	A value that encodes instances of a **BEncodable** type
///	into a data buffer that uses **BinaryIO** format.
public struct BinaryIOEncoder: BEncoder {
	private var _data 				: Bytes
	private var _position			: Int
	private var _enableCompression	: Bool
	private var	insertMode			: Bool

	// public	let defaultBinaryFileCode = FileCode( "bina" )
	
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
	/// - Parameter userVersion: An user definde version for its data.
	/// - Parameter archiveIdentifier: An optional string to identify the archive.
	///	- Parameter userData: User defined data for decoding strategies.
	///	- Parameter enableCompression: compress integer values to reduce file size.
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
		self._enableCompression		= enableCompression
		// really can't throw
		try! self.writePODValue( self.binaryIOFlags )	// NO compression
		if let archiveIdentifier { try! self.encode( archiveIdentifier ) }
		try! self.encode( self.binaryIOVersion )		// compressed if enableCompression
		try! self.encode( self.userVersion )			// compressed if enableCompression
		self.startOfFile		= position
		self.enableCompression		= enableCompression
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
	public var enableCompression : Bool {
		get { _enableCompression }
		set { _enableCompression = newValue && binaryIOFlags.contains( .compressionEnabled ) }
	}

	///	The current end of file position
	public var endOfFile	: Int { _data.endIndex }
	
	///	Reads and sets the the position in the file in which data will be encoded.
	///
	///	`position` cannot be less than `startOfFile`.
	///
	///	`position` cannot be greater than the current end of the
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
	public mutating func withCompressionDisabled<T>(
		encodeFunc: ( inout BinaryIOEncoder ) throws -> T
	) rethrows -> T {
		let saveCompression	= enableCompression
		defer{ enableCompression = saveCompression }
		enableCompression = false
		return try encodeFunc( &self )
	}
	
	/// Enable insertMode for the duration of the closure
	///
	/// - parameter encodeFunc: The closure
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
	/// - Note: This method is only necessary in case of **non-sequential** encoding/decoding
	/// of the archive.
	public mutating func withEncodedIntSizeBefore<T>(
		encodeFunc: ( inout BinaryIOEncoder ) throws -> T
	) rethrows -> T {
		if binaryIOFlags.contains( .compressionEnabled ) {
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

	public mutating func withUnderlyingType<T>( _ apply: (inout BinaryIOEncoder) throws -> T ) rethrows -> T {
		try apply( &self )
	}
	
	public mutating func encode<Value>(_ value: Value)
	throws where Value : BEncodable {
		try value.encode(to: &self)
	}
}

// MARK:  internal section

extension BinaryIOEncoder {
	//	Bool
	mutating func encodeBool( _ value:Bool ) throws {
		try writePODValue( value )
	}
	
	//	Unsigned Integers
	mutating func encodeUInt8( _ value:UInt8 ) throws {
		try writePODValue( value )
	}
	
	mutating func encodeUInt16( _ value:UInt16 ) throws {
		if enableCompression {
			try packAndWrite( value )
		} else {
			try writePODValue( value.littleEndian )
		}
	}
	
	mutating func encodeUInt32( _ value:UInt32 ) throws {
		if enableCompression {
			try packAndWrite( value )
		} else {
			try writePODValue( value.littleEndian )
		}
	}
	
	mutating func encodeUInt64( _ value:UInt64 ) throws {
		if enableCompression {
			try packAndWrite( value )
		} else {
			try writePODValue( value.littleEndian )
		}
	}

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

	//	Signed Integers
	mutating func encodeInt8( _ value:Int8 ) throws {
		try writePODValue( value )
	}

	
	mutating func encodeInt16( _ value:Int16 ) throws {
		if enableCompression {
			try encode( ZigZag.encode( value ) )
		}
		else {
			try writePODValue( value.littleEndian )
		}
	}
	
	mutating func encodeInt32( _ value:Int32 ) throws {
		if enableCompression {
			try encode( ZigZag.encode( value ) )
		}
		else {
			try writePODValue( value.littleEndian )
		}
	}
	
	mutating func encodeInt64( _ value:Int64 ) throws {
		if enableCompression {
			try encode( ZigZag.encode( value ) )
		}
		else {
			try writePODValue( value.littleEndian )
		}
	}
	
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
	
	//	Floats
	mutating func encodeFloat( _ value:Float ) throws {
		let saveCompression = enableCompression
		defer { enableCompression = saveCompression }
		enableCompression = false
		
		try encode( value.bitPattern )
	}
	
	mutating func encodeDouble( _ value:Double ) throws {
		let saveCompression = enableCompression
		defer { enableCompression = saveCompression }
		enableCompression = false
		
		try encode( value.bitPattern )
	}
	
	//	Strings
	mutating func encodeString( _ value:String ) throws {
		try value.withCString() { ptr in
			var endptr	= ptr
			while endptr.pointee != 0 { endptr += 1 }	// null terminated
			let size = endptr - ptr + 1
			try ptr.withMemoryRebound(to: UInt8.self, capacity: size ) {
				try write( contentsOf: UnsafeBufferPointer( start: $0, count: size ) )
			}
		}
	}
	
	//	Data
	mutating func encodeData( _ value:Data ) throws {
		try encode( value.count )
		for region in value.regions {
			try region.withUnsafeBytes { source in
				try write(contentsOf: source)
			}
		}
	}
}

// MARK: private section

extension BinaryIOEncoder {
	/// write a bytes collection
	private mutating func write<C>( contentsOf source:C ) throws
	where C:RandomAccessCollection, C.Element == UInt8 {
		if position == _data.endIndex {
			_data.append( contentsOf: source )
		} else if position >= _data.startIndex {
			if insertMode {
				_data.insert( contentsOf: source, at: position )
			} else {
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

	/// write a pod value
	private mutating func writePODValue<T>( _ value:T ) throws {
		/*
		guard _isPOD(T.self) else {
			throw Errors.BinaryIOError.notPODType(
				Self.self, Errors.Context(
					debugDescription: "\(T.self) must be a POD type."
				)
			)
		}
		*/
		try withUnsafePointer(to: value) { source in
			let size = MemoryLayout<T>.size
			try source.withMemoryRebound(to: UInt8.self, capacity: size ) {
				try write( contentsOf: UnsafeBufferPointer( start: $0, count: size ) )
			}
		}
	}

	///	Transforms an **unsigned integer** of size n into at most n+1 bytes
	///	(worst case) but much less for small numbers, and then encodes them.
	///
	///	It usually greatly reduces the size of the generated archive.
	private mutating func packAndWrite<T>( _ value:T )
	throws where T:FixedWidthInteger, T:UnsignedInteger {
		assert(
			MemoryLayout<T>.size > 1,
			"\(#function) the unsigned integer value must be at least 2 bytes."
		)

		var	val		= value
		var byte	= UInt8( val & 0x7F )
		
		while val & (~0x7F) != 0 {
			byte 	|= 0x80
			try 	writePODValue( byte )
			val 	&>>= 7
			byte	= UInt8( val & 0x7F )
		}
		try writePODValue( byte )
	}
}


