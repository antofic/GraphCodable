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
	func write( to writer: inout BinaryWriter ) throws
	init( from reader: inout BinaryReader ) throws
}

extension NativeIOType {
	public func encode(to encoder: GEncoder) throws	{
		throw GCodableError.internalInconsistency(
			Self.self, GCodableError.Context(
				debugDescription: "Program must not reach this point."
			)
		)
	}
	
	public init(from decoder: GDecoder) throws {
		throw GCodableError.internalInconsistency(
			Self.self, GCodableError.Context(
				debugDescription: "Program must not reach this point."
			)
		)
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

// -- Int & UInt support (NativeIOType) --------------------------------------------
//	Su alcune piattaforme Int e UInt hanno 32 bit.
//	Salviamo sempre a 64bit

extension Int : NativeIOType {
	init(from reader: inout BinaryReader) throws {
		self.init( try Int64( from: &reader ) )
	}
	
	func write(to writer: inout BinaryWriter) throws {
		try Int64( self ).write(to: &writer)
	}
}

extension UInt : NativeIOType {
	init(from reader: inout BinaryReader) throws {
		self.init( try UInt64( from: &reader ) )
	}
	
	func write(to writer: inout BinaryWriter) throws {
		try UInt64( self ).write(to: &writer)
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
		let string	= try reader.readString()
		guard let character = string.first else {
			throw GCodableError.initGCodableError(
				Self.self, GCodableError.Context(
					debugDescription: "Invalida character string \(string) for \(Self.self)"
				)
			)
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
	// queste due perché i decoder unwrappano gli optional
	public func encode(to encoder: GEncoder) throws {
		throw GCodableError.internalInconsistency(
			Self.self, GCodableError.Context(
				debugDescription: "Program must not reach this point."
			)
		)
	}
	
	public init(from decoder: GDecoder) throws {
		throw GCodableError.internalInconsistency(
			Self.self, GCodableError.Context(
				debugDescription: "Program must not reach this point."
			)
		)
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

