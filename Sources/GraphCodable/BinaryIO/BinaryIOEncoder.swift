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
 BinaryIOEncoder data format uses always:
 • little-endian
 • store Int, UInt as Int64, UInt64
*/

///	A value that encodes instances of a **BEncodable** type
///	into a data buffer that uses **BinaryIO** format.
public struct BinaryIOEncoder: BEncoder {
	private var _data 				: Bytes
	private var _position			: Int
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
	
	private var _enableCompression	: Bool

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
}

extension BinaryIOEncoder {
	/// Creates a new instance of `BinaryIODecoder`.
	///
	/// - Parameter userVersion: An user definde version for its data.
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

	/// Disable integers packing for the duration of the closure
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

	public mutating func within<T>(
		position encodePosition: Int,
		encodeFunc: ( inout BinaryIOEncoder ) throws -> T
	) rethrows -> T {
		let savePosition	= position
		defer{ position 	= savePosition }
		position	= encodePosition
		return try encodeFunc( &self )
	}
	
	/// Use this method when you want to encode data **B** in front of data **A**, but **B** depends (or is)
	/// on the archived size of **A**. This function shifts the byte representation of **A**.
	///
	/// - Parameter firstEncode: closure that receive self as paramater and encode **A**.
	/// - Parameter thenInsertInFront: closure that receive self and the size of **A** size
	/// in encoded bytes as paramaters and encode **B**.
	/// - Returns: the `firstEncode` return value
	///
	/// - Note: The bytes representing **A** are shifted to put **B** in front of **A**.
	///
	/// - Note: This method is only necessary in case of **non-sequential** encoding/decoding
	/// of the archive.
	public mutating func insert<T>(
		firstEncode			encodeFunc: ( inout BinaryIOEncoder ) throws -> T,
		thenInsertInFront	insertFunc: ( inout BinaryIOEncoder, _ encodeSize: Int ) throws -> ()
	) rethrows -> T {
		let initialPos	= position
		let result 		= try encodeFunc( &self )
		let finalPos	= position
		position		= initialPos
		do {
			insertMode = true
			defer { insertMode = false }
			try insertFunc( &self, finalPos - initialPos )
		}
		let valuePos	= position
		position		= finalPos + (valuePos - initialPos)
		return result
	}
	
	/// Use this method when you want to encode data **B** in front of data **A**, but **B** depends (or is)
	/// on the archived size of **A**. This function **don't** shifts the byte representation of **A**.
	///
	/// - Parameter dummyEncode: closure that receive self as paramater and encode
	/// dummy data of the same size of **B**
	/// - Parameter thenEncode: closure that receive self as paramater and encode **A**.
	/// - Parameter thenOverwriteDummy: closure that receive self and the size of **A** size
	/// in encoded bytes as paramaters and encode **B**.
	/// - Returns: the `thenEncode` return value
	///
	/// Example:
	/// ```
	/// try encoder.prepend(
	///	   dummyEncode: { try $0.encode( 0 ) },
	///	   thenEncode: { try $0.encode( myValueOfUnknownSize ) },
	///	   thenOverwriteDummy: { try $0.encode( $1 ) ) }
	///	)
	/// ```
	/// - Note: During `dummyEncode` and `thenOverwriteDummy` compression **is always disabled**
	/// to make integers encode size do not depend by their values.
	/// During decoding **it is therefore necessary to disable compression** to decode
	/// data encoded by `thenOverwriteDummy`. For example with the `BinaryIODecoder` function
	/// ```
	/// func withCompressionDisabled<T>(
	///		decodeFunc: ( inout BinaryIODecoder ) throws -> T
	///		) rethrows -> T
	/// ```
	///
	/// - Note: `thenOverwriteDummy` must exactly overwrite the dummy data encoded with `dummyEncode`.
	/// The exception `BinaryIOError.prependingFails` is generated otherwise.
	///
	/// - Note: This method is only necessary in case of **non-sequential** encoding/decoding
	/// of the archive.
	public mutating func prepend<T>(
		dummyEncode			dummyFunc: 		( inout BinaryIOEncoder ) throws -> (),
		thenEncode 			encodeFunc: 	( inout BinaryIOEncoder ) throws -> T,
		thenOverwriteDummy 	overwriteFunc:	( inout BinaryIOEncoder, _ encodeSize: Int ) throws -> ()
	) throws -> T {
		let initialPos	= position
		try withCompressionDisabled {
			try dummyFunc( &$0 )
		}
		
		let bodyPos		= position
		let result		= try encodeFunc( &self )
		let finalPos	= position
		
		position		= initialPos
		try withCompressionDisabled {
			try overwriteFunc( &$0, finalPos - bodyPos )
		}
		let newbodyPos	= position
		position		= finalPos
		
		if newbodyPos != bodyPos {
			position = initialPos	// like no encoding at all
			throw BinaryIOError.prependingFails(
				Self.self, BinaryIOError.Context(
					debugDescription:
						"\(Self.self): overwrite size \(newbodyPos - initialPos) is not equal to dummy size \(bodyPos - initialPos)."
				)
			)
		}
		return result
	}
	
}

// private section ---------------------------------------------------------
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
			throw BinaryIOError.outOfBounds(
				Self.self, BinaryIOError.Context(
					debugDescription: "\(Self.self): file position out of data bounds."
				)
			)
		}
		position += source.count
	}

	/// write a pod value
	private mutating func writePODValue<T>( _ value:T ) throws {
		/*
		guard _isPOD(T.self) else {
			throw BinaryIOError.notPODType(
				Self.self, BinaryIOError.Context(
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


// public protocol section ---------------------------------------------------------
extension BinaryIOEncoder {
	public mutating func withUnderlyingType<T>( _ apply: (inout BinaryIOEncoder) throws -> T ) rethrows -> T {
		try apply( &self )
	}
	
	public mutating func encode<Value>(_ value: Value)
	throws where Value : BEncodable {
		try value.encode(to: &self)
	}
}


// internal section ---------------------------------------------------------
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
			throw BinaryIOError.libDecodingError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Int \(value) can't be converted to UInt64."
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
			throw BinaryIOError.libDecodingError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Int \(value) can't be converted to Int64."
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

