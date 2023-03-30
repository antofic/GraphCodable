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


// Bool ------------------------------------------------------

extension Bool		: BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encodeBool( self ) } }
extension Bool		: BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decodeBool() } }

// Integers ------------------------------------------------------

extension Int: BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try withUnsafeMutablePointer(to: &encoder) {
			try $0.withMemoryRebound(to: BinaryIOEncoder.self, capacity: 1) {
				try $0.pointee.encodeInt( self )
			}
		}
	}
}

extension Int: BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self = try withUnsafeMutablePointer(to: &decoder) {
			try $0.withMemoryRebound(to: BinaryIODecoder.self, capacity: 1) {
				try $0.pointee.decodeInt()
			}
		}
	}
}



extension Int8		: BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encodeInt8( self ) } }
extension Int16		: BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encodeInt16( self ) } }
extension Int32		: BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encodeInt32( self ) } }
extension Int64		: BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encodeInt64( self ) } }

extension Int8		: BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decodeInt8() } }
extension Int16		: BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decodeInt16() } }
extension Int32		: BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decodeInt32() } }
extension Int64		: BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decodeInt64() } }

extension UInt		: BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encodeUInt( self ) } }
extension UInt8		: BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encodeUInt8( self ) } }
extension UInt16	: BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encodeUInt16( self ) } }
extension UInt32	: BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encodeUInt32( self ) } }
extension UInt64	: BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encodeUInt64( self ) } }

extension UInt		: BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decodeUInt() } }
extension UInt8		: BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decodeUInt8() } }
extension UInt16	: BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decodeUInt16() } }
extension UInt32	: BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decodeUInt32() } }
extension UInt64	: BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decodeUInt64() } }

// Float & Double ------------------------------------------------------

extension Float		: BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encodeFloat( self ) } }
extension Float		: BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decodeFloat() } }

extension Double	: BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encodeDouble( self ) } }
extension Double	: BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decodeDouble() } }

// String ------------------------------------------------------

extension String	: BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encodeString( self ) } }
extension String	: BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decodeString() } }

// Optional ------------------------------------------------------

extension Optional : BEncodable where Wrapped : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		switch self {
			case .none:
				try encoder.encode( false )
			case .some( let wrapped ):
				try encoder.encode( true )
				try encoder.encode( wrapped )
		}
	}
}


extension Optional : BDecodable where Wrapped : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		switch try decoder.decode() as Bool {
			case false:
				self = .none
			case true:
				self = .some( try decoder.decode()  )
				
		}
	}
}

// RawRepresentable ------------------------------------------------------

extension RawRepresentable where Self.RawValue : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( rawValue )
	}
}

extension RawRepresentable where Self.RawValue : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		let rawValue	= try decoder.decode() as RawValue
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

extension Array : BEncodable where Element : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( count )
		for element in self {
			try encoder.encode( element )
		}
	}
}
extension Array : BDecodable where Element : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self.init()
		let count = try decoder.decode() as Int
		self.reserveCapacity( count )
		for _ in 0..<count {
			self.append( try decoder.decode() )
		}
	}
}


// ContiguousArray ------------------------------------------------------

extension ContiguousArray : BEncodable where Element : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( count )
		for element in self {
			try encoder.encode( element )
		}
	}
}

extension ContiguousArray : BDecodable where Element : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self.init()
		let count = try decoder.decode() as Int
		self.reserveCapacity( count )
		for _ in 0..<count {
			self.append( try decoder.decode() )
		}
	}
}


// Set ------------------------------------------------------

extension Set : BEncodable where Element : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( Array( self ) )
	}
}
extension Set : BDecodable where Element : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self = Set( try decoder.decode() as Array<Element> )
	}
}

// Dictionary ------------------------------------------------------

extension Dictionary : BEncodable where Key : BEncodable, Value : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( count )
		for (key,value) in self {
			try encoder.encode( key )
			try encoder.encode( value )
		}
	}
}
extension Dictionary : BDecodable where Key : BDecodable, Value : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self.init()
		let count = try decoder.decode() as Int
		self.reserveCapacity(count)
		for _ in 0..<count {
			let key		= try decoder.decode() as Key
			let value	= try decoder.decode() as Value
			self[key] = value
		}
	}
}

// Range ------------------------------------------------------

extension Range: BEncodable where Bound: BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( lowerBound )
		try encoder.encode( upperBound )
	}
}
extension Range: BDecodable where Bound: BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		let lowerBound	= try decoder.decode() as Bound
		let upperBound	= try decoder.decode() as Bound
		self.init(uncheckedBounds: (lowerBound,upperBound) )
	}
}


// ClosedRange ------------------------------------------------------

extension ClosedRange: BEncodable where Bound: BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( lowerBound )
		try encoder.encode( upperBound )
	}
}
extension ClosedRange: BDecodable where Bound: BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		let lowerBound	= try decoder.decode() as Bound
		let upperBound	= try decoder.decode() as Bound
		self.init(uncheckedBounds: (lowerBound,upperBound) )
	}
}

// PartialRangeFrom ------------------------------------------------------

extension PartialRangeFrom: BEncodable where Bound: BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( lowerBound )
	}
}
extension PartialRangeFrom: BDecodable where Bound: BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self.init( try decoder.decode() as Bound )
	}
}


// PartialRangeUpTo ------------------------------------------------------

extension PartialRangeUpTo: BEncodable where Bound: BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( upperBound )
	}
}
extension PartialRangeUpTo: BDecodable where Bound: BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self.init( try decoder.decode() as Bound )
	}
}

// PartialRangeThrough ------------------------------------------------------

extension PartialRangeThrough: BEncodable where Bound: BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( upperBound )
	}
}
extension PartialRangeThrough: BDecodable where Bound: BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self.init( try decoder.decode() as Bound )
	}
}

// CollectionDifference.Change ------------------------------------------------------

extension CollectionDifference.Change {
	private enum ChangeType : UInt8, BCodable { case insert, remove }
}

extension CollectionDifference.Change : BEncodable where ChangeElement : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		switch self {
			case .insert(let offset, let element, let associatedWith ):
				try encoder.encode( ChangeType.insert )
				try encoder.encode( offset )
				try encoder.encode( element )
				try encoder.encode( associatedWith )
			case .remove(let offset, let element, let associatedWith ):
				try encoder.encode( ChangeType.remove )
				try encoder.encode( offset )
				try encoder.encode( element )
				try encoder.encode( associatedWith )
		}
	}
}

extension CollectionDifference.Change : BDecodable where ChangeElement : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		let changeType		= try decoder.decode() as ChangeType
		let offset			= try decoder.decode() as Int
		let element			= try decoder.decode() as ChangeElement
		let associatedWith	= try decoder.decode() as Int?
		
		switch changeType {
			case .insert:	self = .insert(offset: offset, element: element, associatedWith: associatedWith)
			case .remove:	self = .remove(offset: offset, element: element, associatedWith: associatedWith)
		}
	}
}

// CollectionDifference ------------------------------------------------------

extension CollectionDifference : BEncodable where ChangeElement:BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( count )
		for element in self {
			try encoder.encode( element )
		}
	}
}

extension CollectionDifference : BDecodable where ChangeElement:BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		var changes	= [CollectionDifference<ChangeElement>.Change]()
		
		let count	= try decoder.decode() as Int
		for _ in 0..<count {
			changes.append( try decoder.decode() as CollectionDifference.Change )
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
