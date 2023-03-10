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

// Int ------------------------------------------------------
//	Uses Version: NO

extension Int : BinaryIOType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readInt() ) }
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeInt( self ) }
}

extension Int8 : BinaryIOType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readInt8() ) }
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeInt8( self ) }
}

extension Int16 : BinaryIOType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readInt16() ) }
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeInt16( self ) }
}

extension Int32 : BinaryIOType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readInt32() ) }
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeInt32( self ) }
}

extension Int64 : BinaryIOType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readInt64() ) }
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeInt64( self ) }
}

// UInt ------------------------------------------------------
//	Uses Version: NO

extension UInt : BinaryIOType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readUInt() ) }
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeUInt( self ) }
}

extension UInt8 : BinaryIOType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readUInt8() ) }
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeUInt8( self ) }
}

extension UInt16 : BinaryIOType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readUInt16() ) }
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeUInt16( self ) }
}

extension UInt32 : BinaryIOType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readUInt32() ) }
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeUInt32( self ) }
}

extension UInt64 : BinaryIOType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readUInt64() ) }
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeUInt64( self ) }
}

// Float & Double ------------------------------------------------------
//	Uses Version: NO

extension Float : BinaryIOType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readFloat() ) }
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeFloat( self ) }
}

extension Double : BinaryIOType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readDouble() ) }
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeDouble( self ) }
}

// Bool ------------------------------------------------------
//	Uses Version: NO

extension Bool : BinaryIOType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readBool() ) }
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeBool( self ) }
}


// String ------------------------------------------------------
//	Uses Version: NO

extension String : BinaryIOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try wbuffer.writeString( self )
	}
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		self = try rbuffer.readString()
	}
}

// Optional ------------------------------------------------------
//	Uses Version: NO

extension Optional : BinaryIOType where Wrapped : BinaryIOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		switch self {
		case .none:
			try false.write(to: &wbuffer)
		case .some( let wrapped ):
			try true.write(to: &wbuffer)
			try wrapped.write(to: &wbuffer)
		}
	}
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		switch try Bool(from: &rbuffer) {
		case false:
			self = .none
		case true:
			self = .some( try Wrapped(from: &rbuffer)  )
		}
	}
}

// RawRepresentable ------------------------------------------------------
//	Uses Version: NO

extension RawRepresentable where Self.RawValue : BinaryIOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try self.rawValue.write(to: &wbuffer)
	}
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		let rawValue	= try Self.RawValue(from: &rbuffer)
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

// Array ------------------------------------------------------
//	Uses Version: NO

/*
extension BinaryIType where Self:RangeReplaceableCollection, Self.Element: BinaryIType {
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		self.init()
		let count = try Int( from: &rbuffer )
		self.reserveCapacity( count )
		for _ in 0..<count {
			self.append( try Element.init(from: &rbuffer) )
		}
	}
}


extension BinaryOType where Self:RandomAccessCollection, Self.Element: BinaryOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try count.write(to: &wbuffer)
		for element in self {
			try element.write(to: &wbuffer)
		}
	}
}

extension Array : BinaryIOType where Element : BinaryIOType {}
extension ContiguousArray : BinaryIOType where Element : BinaryIOType {}
*/


extension Array : BinaryIOType where Element : BinaryIOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try count.write(to: &wbuffer)
		for element in self {
			try element.write(to: &wbuffer)
		}
	}
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		self.init()
		let count = try Int( from: &rbuffer )
		self.reserveCapacity( count )
		for _ in 0..<count {
			self.append( try Element.init(from: &rbuffer) )
		}
	}
}

// ContiguousArray ------------------------------------------------------
//	Uses Version: NO

extension ContiguousArray : BinaryIOType where Element : BinaryIOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try count.write(to: &wbuffer)
		for element in self {
			try element.write(to: &wbuffer)
		}
	}
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		self.init()
		let count = try Int( from: &rbuffer )
		self.reserveCapacity( count )
		for _ in 0..<count {
			self.append( try Element.init(from: &rbuffer) )
		}
	}
}


// Set ------------------------------------------------------
//	Uses Version: NO

extension Set : BinaryIOType where Element : BinaryIOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try Array( self ).write(to: &wbuffer)
	}
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		self = Set( try Array(from: &rbuffer) )
	}
}

// Dictionary ------------------------------------------------------
//	Uses Version: NO

extension Dictionary : BinaryIOType where Key : BinaryIOType, Value : BinaryIOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try count.write(to: &wbuffer)
		for (key,value) in self {
			try key.write(to: &wbuffer)
			try value.write(to: &wbuffer)
		}
	}

	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		self.init()
		let count = try Int( from: &rbuffer )
		self.reserveCapacity(count)
		for _ in 0..<count {
			let key		= try Key( from: &rbuffer )
			let value	= try Value( from: &rbuffer )
			self[key] = value
		}
	}
}
 
// Range ------------------------------------------------------
//	Uses Version: NO

extension Range: BinaryIOType where Bound: BinaryIOType {
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		let lowerBound	= try Bound(from: &rbuffer)
		let upperBound	= try Bound(from: &rbuffer)
		self.init(uncheckedBounds: (lowerBound,upperBound) )
	}

	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try lowerBound.write(to: &wbuffer )
		try upperBound.write(to: &wbuffer )
	}
}

// ClosedRange ------------------------------------------------------
//	Uses Version: NO

extension ClosedRange: BinaryIOType where Bound: BinaryIOType {
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		let lowerBound	= try Bound(from: &rbuffer)
		let upperBound	= try Bound(from: &rbuffer)
		self.init(uncheckedBounds: (lowerBound,upperBound) )
	}

	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try lowerBound.write(to: &wbuffer )
		try upperBound.write(to: &wbuffer )
	}
}

// PartialRangeFrom ------------------------------------------------------
//	Uses Version: NO

extension PartialRangeFrom: BinaryIOType where Bound: BinaryIOType {
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		self.init( try Bound(from: &rbuffer) )
	}

	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try lowerBound.write(to: &wbuffer )
	}
}

// PartialRangeUpTo ------------------------------------------------------
//	Uses Version: NO

extension PartialRangeUpTo: BinaryIOType where Bound: BinaryIOType {
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		self.init( try Bound(from: &rbuffer) )
	}

	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try upperBound.write(to: &wbuffer )
	}
}

// PartialRangeFrom ------------------------------------------------------
//	Uses Version: NO

extension PartialRangeThrough: BinaryIOType where Bound: BinaryIOType {
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		self.init( try Bound(from: &rbuffer) )
	}

	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try upperBound.write(to: &wbuffer )
	}
}

// CollectionDifference.Change ------------------------------------------------------
//	Uses Version: NO (is frozen)

extension CollectionDifference.Change : BinaryIOType where ChangeElement : BinaryIOType {
	private enum ChangeType : UInt8, BinaryIOType { case insert, remove }

	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		let changeType		= try ChangeType( from:&rbuffer )
		let offset			= try Int( from:&rbuffer )
		let element			= try ChangeElement( from:&rbuffer )
		let associatedWith	= try Int?( from:&rbuffer )
		
		switch changeType {
		case .insert:	self = .insert(offset: offset, element: element, associatedWith: associatedWith)
		case .remove:	self = .remove(offset: offset, element: element, associatedWith: associatedWith)
		}
	}
	
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		switch self {
		case .insert(let offset, let element, let associatedWith ):
			try ChangeType.insert.write(to: &wbuffer)
			try offset.write(to: &wbuffer)
			try element.write(to: &wbuffer)
			try associatedWith.write(to: &wbuffer)
		case .remove(let offset, let element, let associatedWith ):
			try ChangeType.remove.write(to: &wbuffer)
			try offset.write(to: &wbuffer)
			try element.write(to: &wbuffer)
			try associatedWith.write(to: &wbuffer)
		}
	}
}

// CollectionDifference ------------------------------------------------------
//	Uses Version: NO

extension CollectionDifference : BinaryIOType where ChangeElement:BinaryIOType {
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		var changes	= [CollectionDifference<ChangeElement>.Change]()
		
		let count	= try Int( from:&rbuffer )
		for _ in 0..<count {
			changes.append( try CollectionDifference.Change(from: &rbuffer) )
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
	
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try self.count.write(to: &wbuffer)
		for element in self {
			try element.write(to: &wbuffer)
		}
	}
}



