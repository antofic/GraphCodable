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

// Optional ------------------------------------------------------

extension Optional : BinaryIOType where Wrapped : BinaryIOType {
	public func write( to writer: inout BinaryWriter ) throws {
		switch self {
		case .none:
			try false.write(to: &writer)
		case .some( let wrapped ):
			try true.write(to: &writer)
			try wrapped.write(to: &writer)
		}
	}
	public init( from reader: inout BinaryReader ) throws {
		switch try Bool(from: &reader) {
		case false:
			self = .none
		case true:
			self = .some( try Wrapped(from: &reader)  )
		}
	}
}

// RawRepresentable ------------------------------------------------------
extension RawRepresentable where Self.RawValue : BinaryIOType {
	public func write( to writer: inout BinaryWriter ) throws {
		try self.rawValue.write(to: &writer)
	}
	public init( from reader: inout BinaryReader ) throws {
		let rawValue	= try Self.RawValue(from: &reader)
		guard let value = Self(rawValue: rawValue ) else {
			throw BinaryIOError.initBinaryIOTypeError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Invalid rawValue = \(rawValue) for \(Self.self)"
				)
			)
		}
		self = value
	}
}

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

// CollectionDifference ------------------------------------------------------
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension CollectionDifference.Change : BinaryIOType where ChangeElement : BinaryIOType {
	private enum ChangeType : UInt8, BinaryIOType { case insert, remove }

	public init( from reader: inout BinaryReader ) throws {
		let changeType		= try ChangeType( from:&reader )
		let offset			= try Int( from:&reader )
		let element			= try ChangeElement( from:&reader )
		let associatedWith	= try Int?( from:&reader )
		
		switch changeType {
		case .insert:	self = .insert(offset: offset, element: element, associatedWith: associatedWith)
		case .remove:	self = .remove(offset: offset, element: element, associatedWith: associatedWith)
		}
	}
	
	public func write( to writer: inout BinaryWriter ) throws {
		switch self {
		case .insert(let offset, let element, let associatedWith ):
			try ChangeType.insert.write(to: &writer)
			try offset.write(to: &writer)
			try element.write(to: &writer)
			try associatedWith.write(to: &writer)
		case .remove(let offset, let element, let associatedWith ):
			try ChangeType.remove.write(to: &writer)
			try offset.write(to: &writer)
			try element.write(to: &writer)
			try associatedWith.write(to: &writer)
		}
	}
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension CollectionDifference : BinaryIOType where ChangeElement:BinaryIOType {
	public init( from reader: inout BinaryReader ) throws {
		var changes	= [CollectionDifference<ChangeElement>.Change]()
		
		let count	= try Int( from:&reader )
		for _ in 0..<count {
			changes.append( try CollectionDifference.Change(from: &reader) )
		}
		guard let value = Self(changes) else {
			throw BinaryIOError.initBinaryIOTypeError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Can't initialize \(Self.self) with \(changes)"
				)
			)
		}
		
		self = value
	}
	
	public func write( to writer: inout BinaryWriter ) throws {
		try self.count.write(to: &writer)
		for element in self {
			try element.write(to: &writer)
		}
	}
}
