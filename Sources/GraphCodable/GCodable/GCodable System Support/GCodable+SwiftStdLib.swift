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



// -- BinaryInteger support -------------------------------------------------------
extension Int		: GTrivialCodable {}
extension Int8		: GTrivialCodable {}
extension Int16		: GTrivialCodable {}
extension Int32		: GTrivialCodable {}
extension Int64		: GTrivialCodable {}
extension UInt		: GTrivialCodable {}
extension UInt8		: GTrivialCodable {}
extension UInt16	: GTrivialCodable {}
extension UInt32	: GTrivialCodable {}
extension UInt64	: GTrivialCodable {}

// -- BinaryFloatingPoint support -------------------------------------------------------
extension Float		: GTrivialCodable {}
extension Double	: GTrivialCodable {}

// -- Bool support -------------------------------------------------------
extension Bool 		: GTrivialCodable {}

//	Optional SUPPORT ------------------------------------------------------
extension Optional: GEncodable where Wrapped: GEncodable {
	//	The encoder always unwraps optional values
	//	and so this function is never called.
	public func encode(to encoder: GEncoder) throws {
		throw GCodableError.internalInconsistency(
			Self.self, GCodableError.Context(
				debugDescription: "Unreachable code."
			)
		)
	}
}

extension Optional: GDecodable where Wrapped: GDecodable {
	//	The encoder always unwraps optional values
	//	and so this function is never called.
	public init(from decoder: GDecoder) throws {
		throw GCodableError.internalInconsistency(
			Self.self, GCodableError.Context(
				debugDescription: "Unreachable code."
			)
		)
	}
}

extension Optional: GBinaryCodable where Wrapped: GBinaryCodable {}
extension Optional: GTrivial where Wrapped: GTrivial {}

//	RawRepresentable SUPPORT ------------------------------------------------------

extension RawRepresentable where Self.RawValue : GEncodable {
	public func encode(to encoder: GEncoder) throws	{
		try encoder.encode( self.rawValue )
	}
}
extension RawRepresentable where Self.RawValue : GDecodable {
	public init(from decoder: GDecoder) throws {
		let rawValue = try decoder.decode() as RawValue
		guard let value = Self.init(rawValue:rawValue ) else {
			throw GCodableError.initTypeError(
				Self.self, GCodableError.Context(
					debugDescription: "Invalid rawValue = \(rawValue)"
				)
			)
		}
		self = value
	}
}

extension RawRepresentable where Self.RawValue : GBinaryCodable {}

//	String SUPPORT ------------------------------------------------------
extension String : GBinaryCodable {}

//	Array SUPPORT ------------------------------------------------------
/*
extension GDecodable where Self:RangeReplaceableCollection, Self.Element: GDecodable {
	public init(from decoder: GDecoder) throws {
		self.init()
		
		self.reserveCapacity( decoder.unkeyedCount )
		while decoder.unkeyedCount > 0 {
			self.append( try decoder.decode() )
		}
	}
}

extension GEncodable where Self:RandomAccessCollection, Self.Element: GEncodable {
	public func encode(to encoder: GEncoder) throws {
		for element in self {
			try encoder.encode( element )
		}
	}
}

extension GBinaryDecodable where Self:RangeReplaceableCollection, Self.Element: GTrivialDecodable {}
extension GBinaryEncodable where Self:RandomAccessCollection, Self.Element: GTrivialEncodable {}

extension Array: GCodable where Element:GCodable {}
extension Array: GBinaryCodable where Element : GTrivialCodable {}

extension ContiguousArray: GCodable where Element:GCodable {}
extension ContiguousArray: GBinaryCodable where Element : GTrivialCodable {}
*/

extension Array: GEncodable where Element:GEncodable {
	public func encode(to encoder: GEncoder) throws {
		for element in self {
			try encoder.encode( element )
		}
	}
}
extension Array: GDecodable where Element:GDecodable {
	public init(from decoder: GDecoder) throws {
		self.init()
		
		self.reserveCapacity( decoder.unkeyedCount )
		while decoder.unkeyedCount > 0 {
			self.append( try decoder.decode() )
		}
	}
}

extension Array : GBinaryCodable where Element : GTrivialCodable {}


//	ContiguousArray SUPPORT ------------------------------------------------------

extension ContiguousArray: GEncodable where Element:GEncodable {
	public func encode(to encoder: GEncoder) throws {
		for element in self {
			try encoder.encode( element )
		}
	}
}
extension ContiguousArray: GDecodable where Element:GDecodable {
	public init(from decoder: GDecoder) throws {
		self.init()
		
		self.reserveCapacity( decoder.unkeyedCount )
		while decoder.unkeyedCount > 0 {
			self.append( try decoder.decode() )
		}
	}
}

extension ContiguousArray : GBinaryCodable where Element : GTrivialCodable {}

//	Set SUPPORT ------------------------------------------------------
extension Set: GEncodable where Element:GEncodable {
	public func encode(to encoder: GEncoder) throws {
		for element in self {
			try encoder.encode( element )
		}
	}
}

extension Set: GDecodable where Element:GDecodable {
	public init(from decoder: GDecoder) throws {
		self.init()
		
		self.reserveCapacity( decoder.unkeyedCount )
		while decoder.unkeyedCount > 0 {
			self.insert( try decoder.decode() )
		}
	}
}

extension Set : GBinaryCodable where Element : GTrivialCodable {}

//	Dictionary SUPPORT ------------------------------------------------------

extension Dictionary: GEncodable where Key:GEncodable, Value:GEncodable {
	public func encode(to encoder: GEncoder) throws {
		for (key,value) in self {
			try encoder.encode( key )
			try encoder.encode( value )
		}
	}
}
extension Dictionary: GDecodable where Key:GDecodable, Value:GDecodable {
	public init(from decoder: GDecoder) throws {
		self.init()
		
		self.reserveCapacity( decoder.unkeyedCount )
		while decoder.unkeyedCount > 0 {
			let key		: Key	= try decoder.decode()
			let value	: Value	= try decoder.decode()
			self[ key ]	= value
		}
	}
}

extension Dictionary : GBinaryCodable where Key : GTrivialCodable, Value : GTrivialCodable {}


// Range ------------------------------------------------------

extension Range: GDecodable where Bound: GDecodable {
	public init(from decoder: GDecoder) throws {
		let lowerBound	= try decoder.decode() as Bound
		let upperBound	= try decoder.decode() as Bound
		self.init(uncheckedBounds: (lowerBound,upperBound) )
	}
}

extension Range: GEncodable where Bound: GEncodable {
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( lowerBound )
		try encoder.encode( upperBound )
	}
}

extension Range: GTrivialCodable where Bound: GTrivialCodable {}

// ClosedRange ------------------------------------------------------

extension ClosedRange: GDecodable where Bound: GDecodable {
	public init(from decoder: GDecoder) throws {
		let lowerBound	= try decoder.decode() as Bound
		let upperBound	= try decoder.decode() as Bound
		self.init(uncheckedBounds: (lowerBound,upperBound) )
	}
}
extension ClosedRange: GEncodable where Bound: GEncodable {
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( lowerBound )
		try encoder.encode( upperBound )
	}
}

extension ClosedRange: GTrivialCodable where Bound: GTrivialCodable {}


// PartialRangeFrom ------------------------------------------------------

extension PartialRangeFrom: GDecodable where Bound: GDecodable {
	public init(from decoder: GDecoder) throws {
		self.init( try decoder.decode() as Bound )
	}
}
extension PartialRangeFrom: GEncodable where Bound: GEncodable {
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( lowerBound )
	}
}

extension PartialRangeFrom: GTrivialCodable where Bound: GTrivialCodable {}

// PartialRangeUpTo ------------------------------------------------------

extension PartialRangeUpTo: GDecodable where Bound: GDecodable {
	public init(from decoder: GDecoder) throws {
		self.init( try decoder.decode() as Bound )
	}
}
extension PartialRangeUpTo: GEncodable where Bound: GEncodable {
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( upperBound )
	}
}

extension PartialRangeUpTo: GTrivialCodable where Bound: GTrivialCodable {}


// PartialRangeFrom ------------------------------------------------------

extension PartialRangeThrough: GDecodable where Bound: GDecodable {
	public init(from decoder: GDecoder) throws {
		self.init( try decoder.decode() as Bound )
	}
}
extension PartialRangeThrough: GEncodable where Bound: GEncodable {
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( upperBound )
	}
}

extension PartialRangeThrough: GTrivialCodable where Bound: GTrivialCodable {}


// CollectionDifference ------------------------------------------------------

fileprivate extension CollectionDifference.Change {
	private enum ChangeType : UInt8, GCodable { case insert, remove }
	private enum Key : String { case changeType, offset, element, associatedWith }
}

extension CollectionDifference.Change : GDecodable where ChangeElement : GDecodable {
	public init(from decoder: GDecoder) throws {
		let changeType		= try decoder.decode(for: Key.changeType) as ChangeType
		let offset			= try decoder.decode(for: Key.offset) as Int
		let element			= try decoder.decode(for: Key.element) as ChangeElement
		let associatedWith	= try decoder.decodeIfPresent(for: Key.associatedWith ) as Int?
		
		switch changeType {
		case .insert:	self = .insert(offset: offset, element: element, associatedWith: associatedWith)
		case .remove:	self = .remove(offset: offset, element: element, associatedWith: associatedWith)
		}
	}
}

extension CollectionDifference.Change : GEncodable where ChangeElement : GEncodable {
	public func encode(to encoder: GEncoder) throws {
		switch self {
		case .insert(let offset, let element, let associatedWith ):
			try encoder.encode( ChangeType.insert, for: Key.changeType )
			try encoder.encode( offset, for: Key.offset )
			try encoder.encode( element, for: Key.element )
			try encoder.encodeIfPresent( associatedWith, for: Key.associatedWith )
		case .remove(let offset, let element, let associatedWith ):
			try encoder.encode( ChangeType.remove, for: Key.changeType )
			try encoder.encode( offset, for: Key.offset )
			try encoder.encode( element, for: Key.element )
			try encoder.encodeIfPresent( associatedWith, for: Key.associatedWith )
		}

	}
}

extension CollectionDifference.Change : GBinaryCodable where ChangeElement : GBinaryCodable {}


extension CollectionDifference : GDecodable where ChangeElement:GDecodable {
	public init(from decoder: GDecoder) throws {
		var changes	= [CollectionDifference<ChangeElement>.Change]()
		while decoder.unkeyedCount > 0 {
			changes.append( try decoder.decode() )
		}
		guard let value = Self(changes) else {
			throw GCodableError.initTypeError(
				Self.self, GCodableError.Context(
					debugDescription: "Invalid \(changes)"
				)
			)
		}
		
		self = value
	}
}

extension CollectionDifference : GEncodable where ChangeElement:GEncodable {
	public func encode(to encoder: GEncoder) throws {
		for element in self {
			try encoder.encode( element )
		}
	}
}

extension CollectionDifference : GBinaryCodable where ChangeElement:GBinaryCodable {}


