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
	private var 			_data 			: Bytes
	private var 			_position		: Int
	private var				insertMode		: Bool

	///	The first bytes of the file are reserved so the file
	///	data section begins from `startOfFile` offset.
	public private(set) var startOfFile 	: Int
	
	/// Actual version for BinaryIO library types
	///
	///	Accessible for information only.
	static public let		binaryIOVersion	: UInt32 = 0

	/// Current version for user defined types for
	///	decoding strategies.
	///
	///	This variable must be set in the init method.
	public let				userVersion		: UInt32
	
	///	User defined data for encoding strategies.
	///
	///	This variable can be set in the init method.
	///	By default it is `nil`.
	public let				userData		: Any?
}

extension BinaryIOEncoder {
	/// Creates a new instance of `BinaryIODecoder`.
	///
	/// - Parameter userVersion: An user definde version for its data.
	///	- Parameter userData: User defined data for decoding strategies.
	public init( userVersion: UInt32, userData:Any? = nil ) {
		self.userVersion	= userVersion
		self._data			= Bytes()
		self._position		= 0
		self.startOfFile	= 0
		self.insertMode		= false
		self.userData		= userData
		// really can't throw
		try! self.writeValue( Self.binaryIOVersion )
		try! self.writeValue( userVersion )
		self.startOfFile	= position
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
	
	/// Use this method when you want to encode data **B** in front of data **A**, but **B** depends (or is)
	/// on the archived size of **A**. This function shifts the byte representation of **A**.
	///
	/// - Parameter firstEncode: closure that receive self as paramater and encode **A**.
	/// - Parameter thenInsertInFront: closure that receive self and the size of **A** size
	/// in encoded bytes as paramaters and encode **B**.
	///
	/// - Note: The bytes representing **A** are shifted to put **B** in front of **A**.
	///
	/// - Note: This method is only necessary in case of **non-sequential** encoding/decoding
	/// of the archive.
	public mutating func insert(
		firstEncode			encodeFunc: ( inout BinaryIOEncoder ) throws -> (),
		thenInsertInFront	insertFunc: ( inout BinaryIOEncoder, _ encodeSize: Int ) throws -> ()
	) throws {
		let initialPos	= position
		try encodeFunc( &self )
		let finalPos	= position
		position		= initialPos
		do {
			insertMode = true
			defer { insertMode = false }
			try insertFunc( &self, finalPos - initialPos )
		}
		let valuePos	= position
		position		= finalPos + (valuePos - initialPos)
	}
	
	/// Use this method when you want to encode data **B** in front of data **A**, but **B** depends (or is)
	/// on the archived size of **A**. This function **don't** shifts the byte representation of **A**.
	///
	/// - Parameter dummyEncode: closure that receive self as paramater and encode
	/// dummy data of the same size of **B**
	/// - Parameter thenEncode: closure that receive self as paramater and encode **A**.
	/// - Parameter thenOverwriteDummy: closure that receive self and the size of **A** size
	/// in encoded bytes as paramaters and encode **B**.
	///
	/// Example:
	/// ```
	/// try encoder.prepend(
	///	   dummyEncode: { try $0.encode( 0 ) },
	///	   thenEncode: { try $0.encode( myValueOfUnknownSize ) },
	///	   thenOverwriteDummy: { try $0.encode( $1 ) ) }
	///	)
	/// ```
	///
	/// - Note: `thenOverwriteDummy` must exactly overwrite the dummy data encoded with `dummyEncode`.
	/// The exception `BinaryIOError.prependingFails` is generated otherwise.
	///
	/// - Note: This method is only necessary in case of **non-sequential** encoding/decoding
	/// of the archive.
	public mutating func prepend(
		dummyEncode			dummyFunc: 		( inout BinaryIOEncoder ) throws -> (),
		thenEncode 			encodeFunc: 	( inout BinaryIOEncoder ) throws -> (),
		thenOverwriteDummy 	overwriteFunc:	( inout BinaryIOEncoder, _ encodeSize: Int ) throws -> ()
	) throws {
		let initialPos	= position
		try dummyFunc( &self )
		let bodyPos		= position
		try encodeFunc( &self )
		let finalPos	= position
		
		position		= initialPos
		try overwriteFunc( &self, finalPos - bodyPos )
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
	}
}

// private section ---------------------------------------------------------
extension BinaryIOEncoder {
	private mutating func write<C>( contentsOf source:C ) throws
	where C:RandomAccessCollection, C.Element == UInt8 {
		if position == _data.endIndex {
			_data.append( contentsOf: source )
		} else if position >= _data.startIndex {
			let endIndex	= _data.index( position, offsetBy: insertMode ? 0 : source.count )
			let range		= position ..< Swift.min( _data.endIndex, endIndex )
			_data.replaceSubrange( range, with: source )
		} else {
			throw BinaryIOError.outOfBounds(
				Self.self, BinaryIOError.Context(
					debugDescription: "\(Self.self): file position out of data bounds."
				)
			)
		}
		position += source.count
	}
	
	private mutating func writeValue<T>( _ value:T ) throws {
		guard _isPOD(T.self) else {
			throw BinaryIOError.notPODType(
				Self.self, BinaryIOError.Context(
					debugDescription: "\(T.self) must be a POD type."
				)
			)
		}
		
		try withUnsafePointer(to: value) { source in
			let size = MemoryLayout<T>.size
			try source.withMemoryRebound(to: UInt8.self, capacity: size ) {
				try write( contentsOf: UnsafeBufferPointer( start: $0, count: size ) )
			}
		}
	}

	//	Bool
	private mutating func writeBool( _ value:Bool ) throws {
		try writeValue( value )
	}
	
	//	Integers
	private mutating func writeFixedWidthInteger<T>( _ value:T ) throws
	where T:FixedWidthInteger {
		// Integers are always archived in littleEndian format
		try writeValue( value.littleEndian )
	}
	
	private mutating func writeFixedWidthInteger( _ value:Int ) throws {
		// Int are always archived as Int64
		guard let value64 = Int64( exactly: value ) else {
			throw BinaryIOError.libDecodingError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Int \(value) can't be converted to Int64."
				)
			)
		}
		try writeFixedWidthInteger( value64 )
	}
	
	private mutating func writeFixedWidthInteger( _ value:UInt ) throws {
		// UInt are always archived as UInt64
		guard let value64 = UInt64( exactly: value ) else {
			throw BinaryIOError.libDecodingError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Int \(value) can't be converted to UInt64."
				)
			)
		}
		try writeFixedWidthInteger( value64 )
	}
	
	//	Floats
	private mutating func writeFloat( _ value:Float ) throws {
		try writeFixedWidthInteger( value.bitPattern )
	}
	
	private mutating func writeDouble( _ value:Double ) throws {
		try writeFixedWidthInteger( value.bitPattern )
	}
	
	//	Strings
	private mutating func writeString<T>( _ value:T, insert:Bool = false ) throws
	where T:StringProtocol {
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
	private mutating func writeData<T>( _ value:T, insert:Bool = false ) throws
	where T:MutableDataProtocol {
		try writeFixedWidthInteger( value.count )
		for region in value.regions {
			try region.withUnsafeBytes { source in
				try write(contentsOf: source)
			}
		}
	}
}

extension BinaryIOEncoder {
	public mutating func encode<Value>	(_ value: Value) 	throws where Value : BEncodable { try value.encode(to: &self) }
	
	public mutating func encodeBool		(_ value: Bool) 	throws { try writeBool( value ) }
	
	public mutating func encodeInt		(_ value: Int)		throws { try writeFixedWidthInteger( value ) }
	public mutating func encodeInt8		(_ value: Int8)		throws { try writeFixedWidthInteger( value ) }
	public mutating func encodeInt16	(_ value: Int16)	throws { try writeFixedWidthInteger( value ) }
	public mutating func encodeInt32	(_ value: Int32)	throws { try writeFixedWidthInteger( value ) }
	public mutating func encodeInt64	(_ value: Int64)	throws { try writeFixedWidthInteger( value ) }
	
	public mutating func encodeUInt		(_ value: UInt)		throws { try writeFixedWidthInteger( value ) }
	public mutating func encodeUInt8	(_ value: UInt8)	throws { try writeFixedWidthInteger( value ) }
	public mutating func encodeUInt16	(_ value: UInt16)	throws { try writeFixedWidthInteger( value ) }
	public mutating func encodeUInt32	(_ value: UInt32)	throws { try writeFixedWidthInteger( value ) }
	public mutating func encodeUInt64	(_ value: UInt64)	throws { try writeFixedWidthInteger( value ) }
	
	public mutating func encodeFloat	(_ value: Float)	throws { try writeFloat( value ) }
	public mutating func encodeDouble	(_ value: Double)	throws { try writeDouble( value ) }
	
	public mutating func encodeString	(_ value: String)	throws { try writeString( value ) }
	public mutating func encodeData		(_ value: Data)		throws { try writeData( value ) }
}

