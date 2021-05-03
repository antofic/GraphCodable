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


extension BinaryIOType where Self : BinaryInteger {
	func write( to writer: inout BinaryWriter ) throws {
		writer.writeValue( self )
	}
	init( from reader: inout BinaryReader ) throws {
		var value = Self.zero
		try reader.readValue( &value )
		self = value
	}
}

extension Int : BinaryIOType {}
extension Int8 : BinaryIOType {}
extension Int16 : BinaryIOType {}
extension Int32 : BinaryIOType {}
extension Int64 : BinaryIOType {}
extension UInt : BinaryIOType {}
extension UInt8 : BinaryIOType {}
extension UInt16 : BinaryIOType {}
extension UInt32 : BinaryIOType {}
extension UInt64 : BinaryIOType {}

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


extension BinaryIOType where Self : BinaryFloatingPoint {
	func write( to writer: inout BinaryWriter ) throws {
		writer.writeValue( self )
	}
	init( from reader: inout BinaryReader ) throws {
		var value = Self.zero
		try reader.readValue( &value )
		self = value
	}
}


extension Float : BinaryIOType {}
extension Double : BinaryIOType {}


extension Bool : BinaryIOType {
	func write( to writer: inout BinaryWriter ) throws {
		writer.writeValue( self )
	}
	init( from reader: inout BinaryReader ) throws {
		var value = false
		try reader.readValue( &value )
		self = value
	}
}


extension String : BinaryIOType {
	func write( to writer: inout BinaryWriter ) throws {
		writer.writeString( self )
	}
	init( from reader: inout BinaryReader ) throws {
		self = try reader.readString()
	}
}

extension Data : BinaryIOType {
	func write( to writer: inout BinaryWriter ) throws {
		writer.writeData( self )
	}
	init( from reader: inout BinaryReader ) throws {
		self = try reader.readData()
	}
}


extension Array : BinaryIOType where Element : BinaryIOType {
	func write( to writer: inout BinaryWriter ) throws {
		writer.writeArray( self )
	}
	init( from reader: inout BinaryReader ) throws {
		self = try reader.readArray()
	}
}

extension Set : BinaryIOType where Element : BinaryIOType {
	func write( to writer: inout BinaryWriter ) throws {
		writer.writeArray( Array( self ) )
	}
	init( from reader: inout BinaryReader ) throws {
		self = Set( try reader.readArray() )
	}
}

extension Dictionary : BinaryIOType where Key : BinaryIOType, Value : BinaryIOType {
	func write( to writer: inout BinaryWriter ) throws {
		writer.writeArray( Array( self.keys ) )
		writer.writeArray( Array( self.values ) )
	}

	init( from reader: inout BinaryReader ) throws {
		let keys	= try reader.readArray() as [Key]
		let values	= try reader.readArray() as [Value]

		self.init(uniqueKeysWithValues: zip(keys, values))
	}
}
