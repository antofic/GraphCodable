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

public protocol BinaryIOType {
	func write( to writer: inout BinaryWriter ) throws
	init( from reader: inout BinaryReader ) throws
}

extension BinaryIOType {
	public func data<Q>() throws -> Q where Q:MutableDataProtocol {
		var writer = BinaryWriter()
		try write( to:&writer )
		return writer.data()
	}

	public init<Q>( data: Q ) throws where Q:Sequence, Q.Element==UInt8 {
		var reader = BinaryReader( data:data )
		try self.init( from: &reader )
	}
}

// Minimal support: -----------------------------------------
// Int ------------------------------------------------------

extension Int : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.readInt() ) }
	public func write(to writer: inout BinaryWriter) throws		{ try writer.writeInt( self ) }
}

extension Int8 : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.readInt8() ) }
	public func write(to writer: inout BinaryWriter) throws		{ writer.writeInt8( self ) }
}

extension Int16 : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.readInt16() ) }
	public func write(to writer: inout BinaryWriter) throws		{ writer.writeInt16( self ) }
}

extension Int32 : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.readInt32() ) }
	public func write(to writer: inout BinaryWriter) throws		{ writer.writeInt32( self ) }
}

extension Int64 : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.readInt64() ) }
	public func write(to writer: inout BinaryWriter) throws		{ writer.writeInt64( self ) }
}

// UInt ------------------------------------------------------

extension UInt : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.readUInt() ) }
	public func write(to writer: inout BinaryWriter) throws		{ try writer.writeUInt( self ) }
}

extension UInt8 : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.readUInt8() ) }
	public func write(to writer: inout BinaryWriter) throws		{ writer.writeUInt8( self ) }
}

extension UInt16 : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.readUInt16() ) }
	public func write(to writer: inout BinaryWriter) throws		{ writer.writeUInt16( self ) }
}

extension UInt32 : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.readUInt32() ) }
	public func write(to writer: inout BinaryWriter) throws		{ writer.writeUInt32( self ) }
}

extension UInt64 : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.readUInt64() ) }
	public func write(to writer: inout BinaryWriter) throws		{ writer.writeUInt64( self ) }
}

// Float & Double ------------------------------------------------------

extension Float : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.readFloat() ) }
	public func write(to writer: inout BinaryWriter) throws		{ writer.writeFloat( self ) }
}

extension Double : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.readDouble() ) }
	public func write(to writer: inout BinaryWriter) throws		{ writer.writeDouble( self ) }
}

// Bool ------------------------------------------------------

extension Bool : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.readBool() ) }
	public func write(to writer: inout BinaryWriter) throws		{ writer.writeBool( self ) }
}


// String ------------------------------------------------------

extension String : BinaryIOType {
	public func write( to writer: inout BinaryWriter ) throws {
		writer.writeString( self )
	}
	public init( from reader: inout BinaryReader ) throws {
		self = try reader.readString()
	}
}


// -- Data support (BinaryIOType) -------------------------------------------------------

extension Data : BinaryIOType {
	public func write( to writer: inout BinaryWriter ) throws {
		writer.writeData( self )
	}
	public init( from reader: inout BinaryReader ) throws {
		self = try reader.readData()
	}
}


