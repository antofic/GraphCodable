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

protocol NativeIOType : GCodable {
	func write( to: inout BinaryWriter ) throws
	init( from: inout BinaryReader ) throws
}

protocol FixedSizeIOType : NativeIOType {}

extension NativeIOType {
	public func encode(to encoder: GEncoder) throws	{
		throw GCodableError.binaryIOEncodeError
	}
	
	public init(from decoder: GDecoder) throws {
		throw GCodableError.binaryIODecodeError
	}

	func bytesArray() throws -> [UInt8] {
		var writer = BinaryWriter()
		try write( to:&writer )
		return writer.bytes
	}
	init( bytesArray: [UInt8] ) throws {
		var reader = BinaryReader( data:bytesArray )
		try self.init( from: &reader )
	}
}

// -- BinaryInteger support (FixedSizeIOType) -------------------------------------------------------

extension NativeIOType where Self : FixedSizeIOType, Self : BinaryInteger {
	func write( to writer: inout BinaryWriter ) throws {
		writer.writeValue( self )
	}
	init( from reader: inout BinaryReader ) throws {
		var value = Self.zero
		try reader.readValue( &value )
		self = value
	}
}

extension Int		: FixedSizeIOType {}
extension Int8		: FixedSizeIOType {}
extension Int16		: FixedSizeIOType {}
extension Int32		: FixedSizeIOType {}
extension Int64		: FixedSizeIOType {}
extension UInt		: FixedSizeIOType {}
extension UInt8		: FixedSizeIOType {}
extension UInt16	: FixedSizeIOType {}
extension UInt32	: FixedSizeIOType {}
extension UInt64	: FixedSizeIOType {}

// -- BinaryFloatingPoint support (FixedSizeIOType) -------------------------------------------------------

extension NativeIOType where Self : FixedSizeIOType, Self : BinaryFloatingPoint {
	func write( to writer: inout BinaryWriter ) throws {
		writer.writeValue( self )
	}
	init( from reader: inout BinaryReader ) throws {
		var value = Self.zero
		try reader.readValue( &value )
		self = value
	}
}

extension Float		: FixedSizeIOType {}
extension Double	: FixedSizeIOType {}

// -- Bool support (FixedSizeIOType) -------------------------------------------------------

extension Bool : NativeIOType, FixedSizeIOType {
	func write( to writer: inout BinaryWriter ) throws {
		writer.writeValue( self )
	}
	init( from reader: inout BinaryReader ) throws {
		var value = false
		try reader.readValue( &value )
		self = value
	}
}

// -- String & Character support (BinaryIOType) --------------------------------------------

extension String : NativeIOType {
	func write( to writer: inout BinaryWriter ) throws {
		writer.writeString( self )
	}
	init( from reader: inout BinaryReader ) throws {
		self = try reader.readString()
	}
}

extension Character : NativeIOType {
	func write( to writer: inout BinaryWriter ) throws {
		writer.writeString( String(self) )
	}
	init( from reader: inout BinaryReader ) throws {
		guard let character = try reader.readString().first else {
			throw GCodableError.binaryIODecodeError
		}
		self = character
	}
}

// -- Data support (BinaryIOType) -------------------------------------------------------

extension Data : NativeIOType {
	func write( to writer: inout BinaryWriter ) throws {
		writer.writeData( self )
	}
	init( from reader: inout BinaryReader ) throws {
		self = try reader.readData()
	}
}


// -- Optional support (BinaryIOType) -------------------------------------------

extension Optional : GCodable where Wrapped : GCodable {
	public func encode(to encoder: GEncoder) throws {
		throw GCodableError.optionalEncodeError
	}
	
	public init(from decoder: GDecoder) throws {
		throw GCodableError.optionalDecodeError
	}
}

extension Optional : NativeIOType where Wrapped : NativeIOType {
	func write( to writer: inout BinaryWriter ) throws {
		switch self {
		case .none:
			try false.write(to: &writer)
		case .some( let wrapped ):
			try true.write(to: &writer)
			try wrapped.write(to: &writer)
		}
	}
	init( from reader: inout BinaryReader ) throws {
		switch try Bool(from: &reader) {
		case false:
			self = .none
		case true:
			self = .some( try Wrapped(from: &reader)  )
		}
	}
}
