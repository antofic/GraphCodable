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

protocol BinaryIOType {
	func write( to: inout BinaryWriter ) throws
	init( from: inout BinaryReader ) throws
}

protocol FixedSizeIOType : BinaryIOType {}

extension BinaryIOType {
	func bytes() throws -> [UInt8] {
		var writer = BinaryWriterBase<Array<UInt8>>()
		try write( to:&writer )
		return writer.bytes
	}
	init( bytes: [UInt8] ) throws {
		var reader = BinaryReaderBase<Array<UInt8>>( bytes:bytes )
		try self.init( from: &reader )
	}
}

// -- BinaryInteger support (FixedSizeIOType) -------------------------------------------------------

extension BinaryIOType where Self : FixedSizeIOType, Self : BinaryInteger {
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

extension BinaryIOType where Self : FixedSizeIOType, Self : BinaryFloatingPoint {
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

extension Bool : BinaryIOType, FixedSizeIOType {
	func write( to writer: inout BinaryWriter ) throws {
		writer.writeValue( self )
	}
	init( from reader: inout BinaryReader ) throws {
		var value = false
		try reader.readValue( &value )
		self = value
	}
}

// -- String support (BinaryIOType) -------------------------------------------------------

extension String : BinaryIOType {
	func write( to writer: inout BinaryWriter ) throws {
		writer.writeString( self )
	}
	init( from reader: inout BinaryReader ) throws {
		self = try reader.readString()
	}
}

// -- Data support (BinaryIOType) -------------------------------------------------------

extension Data : BinaryIOType {
	func write( to writer: inout BinaryWriter ) throws {
		writer.writeData( self )
	}
	init( from reader: inout BinaryReader ) throws {
		self = try reader.readData()
	}
}

// -- RawRepresentable support (BinaryIOType) -------------------------------------------

extension BinaryIOType where Self : RawRepresentable, Self.RawValue : BinaryIOType {
	func write( to writer: inout BinaryWriter ) throws {
		try self.rawValue.write(to: &writer)
	}
	init( from reader: inout BinaryReader ) throws {
		guard let value = Self(rawValue: try Self.RawValue(from: &reader) ) else {
			throw BinaryReaderError.cantConstructRawRepresentable
		}
		self = value
	}
}

extension FixedSizeIOType where Self : RawRepresentable, Self.RawValue : FixedSizeIOType {
	func write( to writer: inout BinaryWriter ) throws {
		try self.rawValue.write(to: &writer)
	}
	init( from reader: inout BinaryReader ) throws {
		guard let value = Self(rawValue: try Self.RawValue(from: &reader) ) else {
			throw BinaryReaderError.cantConstructRawRepresentable
		}
		self = value
	}
}


// -- Optional support (BinaryIOType) -------------------------------------------

extension Optional : BinaryIOType where Wrapped : BinaryIOType {
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

// -- Array support (BinaryIOType & FixedSizeIOType ) -------------------------------------------

extension Array : BinaryIOType where Element : BinaryIOType {
	func write( to writer: inout BinaryWriter ) throws {
		try count.write(to: &writer)
		for element in self {
			try element.write(to: &writer)
		}
	}
	init( from reader: inout BinaryReader ) throws {
		var array = [Element]()
		let count = try Int( from: &reader )
		array.reserveCapacity( count )
		for _ in 0..<count {
			array.append( try Element.init(from: &reader) )
		}
		self = array
	}
}

extension Array : FixedSizeIOType where Element : FixedSizeIOType {
	func write( to writer: inout BinaryWriter ) throws {
		writer.writeArray( self )
	}
	init( from reader: inout BinaryReader ) throws {
		self = try reader.readArray()
	}
}

// -- Set support (BinaryIOType & FixedSizeIOType ) -------------------------------------------

extension Set : BinaryIOType where Element : BinaryIOType {
	func write( to writer: inout BinaryWriter ) throws {
		try Array( self ).write(to: &writer)
	}
	init( from reader: inout BinaryReader ) throws {
		self = Set( try Array(from: &reader) )
	}
}

extension Set : FixedSizeIOType where Element : FixedSizeIOType {
	func write( to writer: inout BinaryWriter ) throws {
		try Array( self ).write(to: &writer)
	}
	init( from reader: inout BinaryReader ) throws {
		self = Set( try Array(from: &reader) )
	}
}

// -- Dictionary support (BinaryIOType & FixedSizeIOType ) -------------------------------------------

extension Dictionary : BinaryIOType where Key : BinaryIOType, Value : BinaryIOType {
	func write( to writer: inout BinaryWriter ) throws {
		try Array( self.keys ).write(to: &writer )
		try Array( self.values ).write(to: &writer )
	}

	init( from reader: inout BinaryReader ) throws {
		let keys	= try [Key](from: &reader)
		let values	= try [Value](from: &reader)

		self.init(uniqueKeysWithValues: zip(keys, values))
	}
}

// Ho molti dubbi su questa!!!!
extension Dictionary : FixedSizeIOType where Key : FixedSizeIOType, Value : FixedSizeIOType {
	func write( to writer: inout BinaryWriter ) throws {
		try Array( self.keys ).write(to: &writer )
		try Array( self.values ).write(to: &writer )
	}

	init( from reader: inout BinaryReader ) throws {
		let keys	= try [Key](from: &reader)
		let values	= try [Value](from: &reader)

		self.init(uniqueKeysWithValues: zip(keys, values))
	}
}
