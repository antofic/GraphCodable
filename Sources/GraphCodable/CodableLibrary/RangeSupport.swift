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

// Range ------------------------------------------------------

extension Range: GCodable where Bound: GCodable {
	public init(from decoder: GDecoder) throws {
		let lowerBound	= try decoder.decode() as Bound
		let upperBound	= try decoder.decode() as Bound
		self.init(uncheckedBounds: (lowerBound,upperBound) )
	}
	
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( lowerBound )
		try encoder.encode( upperBound )
	}
}

extension Range: NativeIOType where Bound: NativeIOType {
	init( from reader: inout BinaryReader ) throws {
		let lowerBound	= try Bound(from: &reader)
		let upperBound	= try Bound(from: &reader)
		self.init(uncheckedBounds: (lowerBound,upperBound) )
	}

	func write( to writer: inout BinaryWriter ) throws {
		try lowerBound.write(to: &writer )
		try upperBound.write(to: &writer )
	}
}

// ClosedRange ------------------------------------------------------

extension ClosedRange: GCodable where Bound: GCodable {
	public init(from decoder: GDecoder) throws {
		let lowerBound	= try decoder.decode() as Bound
		let upperBound	= try decoder.decode() as Bound
		self.init(uncheckedBounds: (lowerBound,upperBound) )
	}
	
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( lowerBound )
		try encoder.encode( upperBound )
	}
}

extension ClosedRange: NativeIOType where Bound: NativeIOType {
	init( from reader: inout BinaryReader ) throws {
		let lowerBound	= try Bound(from: &reader)
		let upperBound	= try Bound(from: &reader)
		self.init(uncheckedBounds: (lowerBound,upperBound) )
	}

	func write( to writer: inout BinaryWriter ) throws {
		try lowerBound.write(to: &writer )
		try upperBound.write(to: &writer )
	}
}

// PartialRangeFrom ------------------------------------------------------

extension PartialRangeFrom: GCodable where Bound: GCodable {
	public init(from decoder: GDecoder) throws {
		self.init( try decoder.decode() as Bound )
	}
	
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( lowerBound )
	}
}

extension PartialRangeFrom: NativeIOType where Bound: NativeIOType {
	init( from reader: inout BinaryReader ) throws {
		self.init( try Bound(from: &reader) )
	}

	func write( to writer: inout BinaryWriter ) throws {
		try lowerBound.write(to: &writer )
	}
}

// PartialRangeUpTo ------------------------------------------------------

extension PartialRangeUpTo: GCodable where Bound: GCodable {
	public init(from decoder: GDecoder) throws {
		self.init( try decoder.decode() as Bound )
	}
	
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( upperBound )
	}
}

extension PartialRangeUpTo: NativeIOType where Bound: NativeIOType {
	init( from reader: inout BinaryReader ) throws {
		self.init( try Bound(from: &reader) )
	}

	func write( to writer: inout BinaryWriter ) throws {
		try upperBound.write(to: &writer )
	}
}

// PartialRangeFrom ------------------------------------------------------

extension PartialRangeThrough: GCodable where Bound: GCodable {
	public init(from decoder: GDecoder) throws {
		self.init( try decoder.decode() as Bound )
	}
	
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( upperBound )
	}
}

extension PartialRangeThrough: NativeIOType where Bound: NativeIOType {
	init( from reader: inout BinaryReader ) throws {
		self.init( try Bound(from: &reader) )
	}

	func write( to writer: inout BinaryWriter ) throws {
		try upperBound.write(to: &writer )
	}
}

