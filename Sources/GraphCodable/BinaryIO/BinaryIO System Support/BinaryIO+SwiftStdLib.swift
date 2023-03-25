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


extension Int : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readInt() ) }
}
extension Int : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeInt( self ) }
}

extension Int8 : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readInt8() ) }
}
extension Int8 : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeInt8( self ) }
}

extension Int16 : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readInt16() ) }
}
extension Int16 : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeInt16( self ) }
}

extension Int32 : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readInt32() ) }
}
extension Int32 : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeInt32( self ) }
}

extension Int64 : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readInt64() ) }
}
extension Int64 : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeInt64( self ) }
}

// UInt ------------------------------------------------------

extension UInt : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readUInt() ) }
}
extension UInt : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeUInt( self ) }
}

extension UInt8 : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readUInt8() ) }
}
extension UInt8 : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeUInt8( self ) }
}

extension UInt16 : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readUInt16() ) }
}
extension UInt16 : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeUInt16( self ) }
}

extension UInt32 : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readUInt32() ) }
}
extension UInt32 : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeUInt32( self ) }
}

extension UInt64 : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readUInt64() ) }
}
extension UInt64 : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeUInt64( self ) }
}

// Float & Double ------------------------------------------------------

extension Float : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readFloat() ) }
}
extension Float : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeFloat( self ) }
}

extension Double : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readDouble() ) }
}
extension Double : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeDouble( self ) }
}

// Bool ------------------------------------------------------

extension Bool : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws			{ self.init( try rbuffer.readBool() ) }
}
extension Bool : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws		{ try wbuffer.writeBool( self ) }
}


// String ------------------------------------------------------

extension String : BinaryOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try wbuffer.writeString( self )
	}
}
extension String : BinaryIType {
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		self = try rbuffer.readString()
	}
}

// Optional ------------------------------------------------------

extension Optional : BinaryOType where Wrapped : BinaryOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		switch self {
		case .none:
			try false.write(to: &wbuffer)
		case .some( let wrapped ):
			try true.write(to: &wbuffer)
			try wrapped.write(to: &wbuffer)
		}
	}
}
extension Optional : BinaryIType where Wrapped : BinaryIType {
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

extension RawRepresentable where Self.RawValue : BinaryOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try self.rawValue.write(to: &wbuffer)
	}
}
extension RawRepresentable where Self.RawValue : BinaryIType {
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		let rawValue	= try Self.RawValue(from: &rbuffer)
		guard let value = Self(rawValue: rawValue ) else {
			throw BinaryIOError.libDecodingError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Invalid rawValue = \(rawValue)"
				)
			)
		}
		self = value
	}
}

// Array ------------------------------------------------------

extension Array : BinaryOType where Element : BinaryOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try count.write(to: &wbuffer)
		for element in self {
			try element.write(to: &wbuffer)
		}
	}
}
extension Array : BinaryIType where Element : BinaryIType {
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		self.init()
		let count = try Int( from: &rbuffer )
		self.reserveCapacity( count )
		for _ in 0..<count {
			self.append( try Element(from: &rbuffer) )
		}
	}
}

// ContiguousArray ------------------------------------------------------

extension ContiguousArray : BinaryOType where Element : BinaryOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try count.write(to: &wbuffer)
		for element in self {
			try element.write(to: &wbuffer)
		}
	}
}
extension ContiguousArray : BinaryIType where Element : BinaryIType {
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		self.init()
		let count = try Int( from: &rbuffer )
		self.reserveCapacity( count )
		for _ in 0..<count {
			self.append( try Element(from: &rbuffer) )
		}
	}
}


// Set ------------------------------------------------------

extension Set : BinaryOType where Element : BinaryOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try Array( self ).write(to: &wbuffer)
	}
}
extension Set : BinaryIType where Element : BinaryIType {
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		self = Set( try Array(from: &rbuffer) )
	}
}

// Dictionary ------------------------------------------------------

extension Dictionary : BinaryOType where Key : BinaryOType, Value : BinaryOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try count.write(to: &wbuffer)
		for (key,value) in self {
			try key.write(to: &wbuffer)
			try value.write(to: &wbuffer)
		}
	}
}
extension Dictionary : BinaryIType where Key : BinaryIType, Value : BinaryIType {
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

extension Range: BinaryIType where Bound: BinaryIType {
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		let lowerBound	= try Bound(from: &rbuffer)
		let upperBound	= try Bound(from: &rbuffer)
		self.init(uncheckedBounds: (lowerBound,upperBound) )
	}
}
extension Range: BinaryOType where Bound: BinaryOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try lowerBound.write(to: &wbuffer )
		try upperBound.write(to: &wbuffer )
	}
}

// ClosedRange ------------------------------------------------------

extension ClosedRange: BinaryIType where Bound: BinaryIType {
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		let lowerBound	= try Bound(from: &rbuffer)
		let upperBound	= try Bound(from: &rbuffer)
		self.init(uncheckedBounds: (lowerBound,upperBound) )
	}
}
extension ClosedRange: BinaryOType where Bound: BinaryOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try lowerBound.write(to: &wbuffer )
		try upperBound.write(to: &wbuffer )
	}
}

// PartialRangeFrom ------------------------------------------------------

extension PartialRangeFrom: BinaryIType where Bound: BinaryIType {
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		self.init( try Bound(from: &rbuffer) )
	}
}
extension PartialRangeFrom: BinaryOType where Bound: BinaryOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try lowerBound.write(to: &wbuffer )
	}
}

// PartialRangeUpTo ------------------------------------------------------

extension PartialRangeUpTo: BinaryIType where Bound: BinaryIType {
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		self.init( try Bound(from: &rbuffer) )
	}
}
extension PartialRangeUpTo: BinaryOType where Bound: BinaryOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try upperBound.write(to: &wbuffer )
	}
}

// PartialRangeFrom ------------------------------------------------------

extension PartialRangeThrough: BinaryIType where Bound: BinaryIType {
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		self.init( try Bound(from: &rbuffer) )
	}
}
extension PartialRangeThrough: BinaryOType where Bound: BinaryOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try upperBound.write(to: &wbuffer )
	}
}

// CollectionDifference.Change ------------------------------------------------------

extension CollectionDifference.Change {
	private enum ChangeType : UInt8, BinaryIOType { case insert, remove }
}

extension CollectionDifference.Change : BinaryIType where ChangeElement : BinaryIType {
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
}
extension CollectionDifference.Change : BinaryOType where ChangeElement : BinaryOType {
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

extension CollectionDifference : BinaryIType where ChangeElement:BinaryIType {
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		var changes	= [CollectionDifference<ChangeElement>.Change]()
		
		let count	= try Int( from:&rbuffer )
		for _ in 0..<count {
			changes.append( try CollectionDifference.Change(from: &rbuffer) )
		}
		guard let value = Self(changes) else {
			throw BinaryIOError.libDecodingError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Invalid \(changes)"
				)
			)
		}
		
		self = value
	}
}
extension CollectionDifference : BinaryOType where ChangeElement:BinaryOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try self.count.write(to: &wbuffer)
		for element in self {
			try element.write(to: &wbuffer)
		}
	}
}



