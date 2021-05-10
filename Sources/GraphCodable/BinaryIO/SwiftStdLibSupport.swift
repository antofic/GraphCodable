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

// Character ------------------------------------------------------
extension Character : BinaryIOType {
	public func write( to writer: inout BinaryWriter ) throws {
		writer.writeString( String(self) )
	}
	public init( from reader: inout BinaryReader ) throws {
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

// Array ------------------------------------------------------

extension Array : BinaryIOType where Element : BinaryIOType {
	public func write( to writer: inout BinaryWriter ) throws {
		try count.write(to: &writer)
		for element in self {
			try element.write(to: &writer)
		}
	}
	public init( from reader: inout BinaryReader ) throws {
		var array = [Element]()
		let count = try Int( from: &reader )
		array.reserveCapacity( count )
		for _ in 0..<count {
			array.append( try Element.init(from: &reader) )
		}
		self = array
	}
}

// ContiguousArray ------------------------------------------------------

extension ContiguousArray : BinaryIOType where Element : BinaryIOType {
	public func write( to writer: inout BinaryWriter ) throws {
		try count.write(to: &writer)
		for element in self {
			try element.write(to: &writer)
		}
	}
	public init( from reader: inout BinaryReader ) throws {
		var array = ContiguousArray<Element>()
		let count = try Int( from: &reader )
		array.reserveCapacity( count )
		for _ in 0..<count {
			array.append( try Element.init(from: &reader) )
		}
		self = array
	}
}

// Set ------------------------------------------------------

extension Set : BinaryIOType where Element : BinaryIOType {
	public func write( to writer: inout BinaryWriter ) throws {
		try Array( self ).write(to: &writer)
	}
	public init( from reader: inout BinaryReader ) throws {
		self = Set( try Array(from: &reader) )
	}
}

// Dictionary ------------------------------------------------------

extension Dictionary : BinaryIOType where Key : BinaryIOType, Value : BinaryIOType {
	public func write( to writer: inout BinaryWriter ) throws {
		try Array( self.keys ).write(to: &writer )
		try Array( self.values ).write(to: &writer )
	}

	public init( from reader: inout BinaryReader ) throws {
		let keys	= try [Key](from: &reader)
		let values	= try [Value](from: &reader)

		self.init(uniqueKeysWithValues: zip(keys, values))
	}
}

// Range ------------------------------------------------------

extension Range: BinaryIOType where Bound: BinaryIOType {
	public init( from reader: inout BinaryReader ) throws {
		let lowerBound	= try Bound(from: &reader)
		let upperBound	= try Bound(from: &reader)
		self.init(uncheckedBounds: (lowerBound,upperBound) )
	}

	public func write( to writer: inout BinaryWriter ) throws {
		try lowerBound.write(to: &writer )
		try upperBound.write(to: &writer )
	}
}

// ClosedRange ------------------------------------------------------

extension ClosedRange: BinaryIOType where Bound: BinaryIOType {
	public init( from reader: inout BinaryReader ) throws {
		let lowerBound	= try Bound(from: &reader)
		let upperBound	= try Bound(from: &reader)
		self.init(uncheckedBounds: (lowerBound,upperBound) )
	}

	public func write( to writer: inout BinaryWriter ) throws {
		try lowerBound.write(to: &writer )
		try upperBound.write(to: &writer )
	}
}

// PartialRangeFrom ------------------------------------------------------

extension PartialRangeFrom: BinaryIOType where Bound: BinaryIOType {
	public init( from reader: inout BinaryReader ) throws {
		self.init( try Bound(from: &reader) )
	}

	public func write( to writer: inout BinaryWriter ) throws {
		try lowerBound.write(to: &writer )
	}
}

// PartialRangeUpTo ------------------------------------------------------

extension PartialRangeUpTo: BinaryIOType where Bound: BinaryIOType {
	public init( from reader: inout BinaryReader ) throws {
		self.init( try Bound(from: &reader) )
	}

	public func write( to writer: inout BinaryWriter ) throws {
		try upperBound.write(to: &writer )
	}
}

// PartialRangeFrom ------------------------------------------------------

extension PartialRangeThrough: BinaryIOType where Bound: BinaryIOType {
	public init( from reader: inout BinaryReader ) throws {
		self.init( try Bound(from: &reader) )
	}

	public func write( to writer: inout BinaryWriter ) throws {
		try upperBound.write(to: &writer )
	}
}

