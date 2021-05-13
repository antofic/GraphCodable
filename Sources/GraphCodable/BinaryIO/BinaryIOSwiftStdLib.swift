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
//	Uses Version: NO

extension Int : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.read() as Int ) }
	public func write(to writer: inout BinaryWriter) throws		{ try writer.write( self ) }
}

extension Int8 : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.read() as Int8 ) }
	public func write(to writer: inout BinaryWriter) throws		{ try writer.write( self ) }
}

extension Int16 : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.read() as Int16 ) }
	public func write(to writer: inout BinaryWriter) throws		{ try writer.write( self ) }
}

extension Int32 : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.read() as Int32 ) }
	public func write(to writer: inout BinaryWriter) throws		{ try writer.write( self ) }
}

extension Int64 : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.read() as Int64 ) }
	public func write(to writer: inout BinaryWriter) throws		{ try writer.write( self ) }
}

// UInt ------------------------------------------------------
//	Uses Version: NO

extension UInt : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.read() as UInt ) }
	public func write(to writer: inout BinaryWriter) throws		{ try writer.write( self ) }
}

extension UInt8 : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.read() as UInt8 ) }
	public func write(to writer: inout BinaryWriter) throws		{ try writer.write( self ) }
}

extension UInt16 : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.read() as UInt16 ) }
	public func write(to writer: inout BinaryWriter) throws		{ try writer.write( self ) }
}

extension UInt32 : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.read() as UInt32 ) }
	public func write(to writer: inout BinaryWriter) throws		{ try writer.write( self ) }
}

extension UInt64 : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.read() as UInt64 ) }
	public func write(to writer: inout BinaryWriter) throws		{ try writer.write( self ) }
}

// Float & Double ------------------------------------------------------
//	Uses Version: NO

extension Float : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.read() as Float ) }
	public func write(to writer: inout BinaryWriter) throws		{ try writer.write( self ) }
}

extension Double : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.read() as Double ) }
	public func write(to writer: inout BinaryWriter) throws		{ try writer.write( self ) }
}

// Bool ------------------------------------------------------
//	Uses Version: NO

extension Bool : BinaryIOType {
	public init(from reader: inout BinaryReader) throws			{ self.init( try reader.read() as Bool ) }
	public func write(to writer: inout BinaryWriter) throws		{ try writer.write( self ) }
}


// String ------------------------------------------------------
//	Uses Version: NO

extension String : BinaryIOType {
	public func write( to writer: inout BinaryWriter ) throws {
		try writer.write( self )
	}
	public init( from reader: inout BinaryReader ) throws {
		self = try reader.read()
	}
}

// Optional ------------------------------------------------------
//	Uses Version: NO

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
//	Uses Version: NO

extension RawRepresentable where Self.RawValue : BinaryIOType {
	public func write( to writer: inout BinaryWriter ) throws {
		try writer.write( self.rawValue )
	}
	public init( from reader: inout BinaryReader ) throws {
		let rawValue	= try Self.RawValue(from: &reader)
		guard let value = Self(rawValue: rawValue ) else {
			throw BinaryIOError.initTypeError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Invalid rawValue = \(rawValue) for \(Self.self)"
				)
			)
		}
		self = value
	}
}

// Character ------------------------------------------------------
//	Uses Version: NO
extension Character : BinaryIOType {
	public func write( to writer: inout BinaryWriter ) throws {
		try writer.write( String(self) )
	}
	public init( from reader: inout BinaryReader ) throws {
		let string	= try reader.read() as String
		guard let character = string.first else {
			throw BinaryIOError.initTypeError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Invalida character string \(string) for \(Self.self)"
				)
			)
		}
		self = character
	}
}

// Array ------------------------------------------------------
//	Uses Version: NO

extension Array : BinaryIOType where Element : BinaryIOType {
	public func write( to writer: inout BinaryWriter ) throws {
		try writer.write( count )
		for element in self {
			try writer.write( element )
		}
	}
	public init( from reader: inout BinaryReader ) throws {
		var array = [Element]()
		let count = try reader.read() as Int
		array.reserveCapacity( count )
		for _ in 0..<count {
			array.append( try reader.read() as Element )
		}
		self = array
	}
}

// ContiguousArray ------------------------------------------------------
//	Uses Version: NO

extension ContiguousArray : BinaryIOType where Element : BinaryIOType {
	public func write( to writer: inout BinaryWriter ) throws {
		try writer.write( count )
		for element in self {
			try writer.write( element )
		}
	}
	public init( from reader: inout BinaryReader ) throws {
		var array = ContiguousArray<Element>()
		let count = try reader.read() as Int
		array.reserveCapacity( count )
		for _ in 0..<count {
			array.append( try reader.read() as Element )
		}
		self = array
	}
}

// Set ------------------------------------------------------
//	Uses Version: NO

extension Set : BinaryIOType where Element : BinaryIOType {
	public func write( to writer: inout BinaryWriter ) throws {
		try writer.write( Array( self ) )
	}
	public init( from reader: inout BinaryReader ) throws {
		self = Set( try reader.read() as Array )
	}
}

// Dictionary ------------------------------------------------------
//	Uses Version: NO

extension Dictionary : BinaryIOType where Key : BinaryIOType, Value : BinaryIOType {
	public func write( to writer: inout BinaryWriter ) throws {
		try writer.write( Array( self.keys ) )
		try writer.write( Array( self.values ) )
	}

	public init( from reader: inout BinaryReader ) throws {
		let keys	= try reader.read() as [Key]
		let values	= try reader.read() as [Value]

		self.init(uniqueKeysWithValues: zip(keys, values))
	}
}

// Range ------------------------------------------------------
//	Uses Version: NO

extension Range: BinaryIOType where Bound: BinaryIOType {
	public init( from reader: inout BinaryReader ) throws {
		let lowerBound	= try reader.read() as Bound
		let upperBound	= try reader.read() as Bound
		self.init(uncheckedBounds: (lowerBound,upperBound) )
	}

	public func write( to writer: inout BinaryWriter ) throws {
		try writer.write( lowerBound )
		try writer.write( upperBound )
	}
}

// ClosedRange ------------------------------------------------------
//	Uses Version: NO

extension ClosedRange: BinaryIOType where Bound: BinaryIOType {
	public init( from reader: inout BinaryReader ) throws {
		let lowerBound	= try reader.read() as Bound
		let upperBound	= try reader.read() as Bound
		self.init(uncheckedBounds: (lowerBound,upperBound) )
	}

	public func write( to writer: inout BinaryWriter ) throws {
		try writer.write( lowerBound )
		try writer.write( upperBound )
	}
}

// PartialRangeFrom ------------------------------------------------------
//	Uses Version: NO

extension PartialRangeFrom: BinaryIOType where Bound: BinaryIOType {
	public init( from reader: inout BinaryReader ) throws {
		self.init( try reader.read() as Bound )
	}

	public func write( to writer: inout BinaryWriter ) throws {
		try writer.write( lowerBound )
	}
}

// PartialRangeUpTo ------------------------------------------------------
//	Uses Version: NO

extension PartialRangeUpTo: BinaryIOType where Bound: BinaryIOType {
	public init( from reader: inout BinaryReader ) throws {
		self.init( try reader.read() as Bound )
	}

	public func write( to writer: inout BinaryWriter ) throws {
		try writer.write( upperBound )
	}
}

// PartialRangeFrom ------------------------------------------------------
//	Uses Version: NO

extension PartialRangeThrough: BinaryIOType where Bound: BinaryIOType {
	public init( from reader: inout BinaryReader ) throws {
		self.init( try reader.read() as Bound )
	}

	public func write( to writer: inout BinaryWriter ) throws {
		try writer.write( upperBound )
	}
}

// CollectionDifference.Change ------------------------------------------------------
//	Uses Version: NO (is frozen)

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension CollectionDifference.Change : BinaryIOType where ChangeElement : BinaryIOType {
	private enum ChangeType : UInt8, BinaryIOType { case insert, remove }

	public init( from reader: inout BinaryReader ) throws {
		let changeType		= try reader.read() as ChangeType
		let offset			= try reader.read() as Int
		let element			= try reader.read() as ChangeElement
		let associatedWith	= try reader.read() as Int?
		
		switch changeType {
		case .insert:	self = .insert(offset: offset, element: element, associatedWith: associatedWith)
		case .remove:	self = .remove(offset: offset, element: element, associatedWith: associatedWith)
		}
	}
	
	public func write( to writer: inout BinaryWriter ) throws {
		switch self {
		case .insert(let offset, let element, let associatedWith ):
			try writer.write( ChangeType.insert )
			try writer.write( offset )
			try writer.write( element )
			try writer.write( associatedWith )
		case .remove(let offset, let element, let associatedWith ):
			try writer.write( ChangeType.remove )
			try writer.write( offset )
			try writer.write( element )
			try writer.write( associatedWith )
		}
	}
}

// CollectionDifference ------------------------------------------------------
//	Uses Version: NO

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension CollectionDifference : BinaryIOType where ChangeElement:BinaryIOType {
	public init( from reader: inout BinaryReader ) throws {
		var changes	= [CollectionDifference<ChangeElement>.Change]()
		
		let count	= try reader.read() as Int
		for _ in 0..<count {
			changes.append( try reader.read() as CollectionDifference.Change )
		}
		guard let value = Self(changes) else {
			throw BinaryIOError.initTypeError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Can't initialize \(Self.self) with \(changes)"
				)
			)
		}
		
		self = value
	}
	
	public func write( to writer: inout BinaryWriter ) throws {
		try writer.write( count )
		for element in self {
			try writer.write( element )
		}
	}
}
