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
extension Int		: GBinaryEncodable {}
extension Int8		: GBinaryEncodable {}
extension Int16		: GBinaryEncodable {}
extension Int32		: GBinaryEncodable {}
extension Int64		: GBinaryEncodable {}
extension UInt		: GBinaryEncodable {}
extension UInt8		: GBinaryEncodable {}
extension UInt16	: GBinaryEncodable {}
extension UInt32	: GBinaryEncodable {}
extension UInt64	: GBinaryEncodable {}

extension Int		: GBinaryDecodable {}
extension Int8		: GBinaryDecodable {}
extension Int16		: GBinaryDecodable {}
extension Int32		: GBinaryDecodable {}
extension Int64		: GBinaryDecodable {}
extension UInt		: GBinaryDecodable {}
extension UInt8		: GBinaryDecodable {}
extension UInt16	: GBinaryDecodable {}
extension UInt32	: GBinaryDecodable {}
extension UInt64	: GBinaryDecodable {}

extension Int		: GPackable {}
extension Int8		: GPackable {}
extension Int16		: GPackable {}
extension Int32		: GPackable {}
extension Int64		: GPackable {}
extension UInt		: GPackable {}
extension UInt8		: GPackable {}
extension UInt16	: GPackable {}
extension UInt32	: GPackable {}
extension UInt64	: GPackable {}

// -- BinaryFloatingPoint support -------------------------------------------------------
extension Float		: GBinaryEncodable {}
extension Double	: GBinaryEncodable {}

extension Float		: GBinaryDecodable {}
extension Double	: GBinaryDecodable {}

extension Float		: GPackable {}
extension Double	: GPackable {}


// -- Bool support -------------------------------------------------------
extension Bool 		: GBinaryEncodable {}
extension Bool 		: GBinaryDecodable {}
extension Bool 		: GPackable {}

// -- Never support -------------------------------------------------------
extension Never 	: GBinaryEncodable {}
extension Never 	: GBinaryDecodable {}
extension Never 	: GPackable {}

//	Optional SUPPORT ------------------------------------------------------


extension Optional: GEncodable where Wrapped: GEncodable {
	//	The encoder always unwraps optional values
	//	and so this function is never called.
	public func encode(to encoder: some GEncoder) throws {
		throw GraphCodableError.internalInconsistency(
			Self.self, GraphCodableError.Context(
				debugDescription: "Unreachable code."
			)
		)
	}
}

extension Optional: GDecodable where Wrapped: GDecodable {
	//	The encoder always unwraps optional values
	//	and so this function is never called.
	public init(from decoder: some GDecoder) throws {
		throw GraphCodableError.internalInconsistency(
			Self.self, GraphCodableError.Context(
				debugDescription: "Unreachable code."
			)
		)
	}
}

/*
extension Optional: GEncodable where Wrapped: GEncodable {
	public func encode(to encoder: some GEncoder) throws {
		switch self {
			case .none: break
			case .some( let value ): try encoder.encode( value )
		}
	}
}

extension Optional: GDecodable where Wrapped: GDecodable {
	public init(from decoder: some GDecoder) throws {
		switch decoder.unkeyedCount {
			case 0: self = .none
			case 1: self = .some( try decoder.decode() )
			default:
				throw GraphCodableError.internalInconsistency(
					Self.self, GraphCodableError.Context(
						debugDescription: "Invalid Optional."
					)
				)
		}
	}
}
*/


extension Optional: GBinaryEncodable where Wrapped: GBinaryEncodable {}
extension Optional: GBinaryDecodable where Wrapped: GBinaryDecodable {}
extension Optional: GPackable where Wrapped: GPackable {}



//	RawRepresentable SUPPORT ------------------------------------------------------

extension RawRepresentable where Self.RawValue : GEncodable {
	public func encode(to encoder: some GEncoder) throws	{
		try encoder.encode( self.rawValue )
	}
}
extension RawRepresentable where Self.RawValue : GDecodable {
	public init(from decoder: some GDecoder) throws {
		let rawValue = try decoder.decode() as RawValue
		guard let value = Self.init(rawValue:rawValue ) else {
			throw GraphCodableError.libDecodingError(
				Self.self, GraphCodableError.Context(
					debugDescription: "Invalid rawValue = \(rawValue)."
				)
			)
		}
		self = value
	}
}

extension RawRepresentable where Self.RawValue : GBinaryEncodable {}
extension RawRepresentable where Self.RawValue : GBinaryDecodable {}
extension RawRepresentable where Self.RawValue : GPackable {}

//	String SUPPORT ------------------------------------------------------
extension String : GBinaryEncodable {}
extension String : GBinaryDecodable {}

//	Array SUPPORT ------------------------------------------------------

extension Array: GEncodable where Element:GEncodable {
	public func encode(to encoder: some GEncoder) throws {
		for element in self {
			try encoder.encode( element )
		}
	}
}
extension Array: GDecodable where Element:GDecodable {
	public init(from decoder: some GDecoder) throws {
		self.init()
		
		self.reserveCapacity( decoder.unkeyedCount )
		while decoder.unkeyedCount > 0 {
			self.append( try decoder.decode() )
		}
	}
}

extension Array : GBinaryEncodable where Element : GPackEncodable {}
extension Array : GBinaryDecodable where Element : GPackDecodable {}


//	ContiguousArray SUPPORT ------------------------------------------------------

extension ContiguousArray: GEncodable where Element:GEncodable {
	public func encode(to encoder: some GEncoder) throws {
		for element in self {
			try encoder.encode( element )
		}
	}
}
extension ContiguousArray: GDecodable where Element:GDecodable {
	public init(from decoder: some GDecoder) throws {
		self.init()
		
		self.reserveCapacity( decoder.unkeyedCount )
		while decoder.unkeyedCount > 0 {
			self.append( try decoder.decode() )
		}
	}
}

extension ContiguousArray : GBinaryEncodable where Element : GPackEncodable {}
extension ContiguousArray : GBinaryDecodable where Element : GPackDecodable {}

//	Set SUPPORT ------------------------------------------------------
extension Set: GEncodable where Element:GEncodable {
	public func encode(to encoder: some GEncoder) throws {
		for element in self {
			try encoder.encode( element )
		}
	}
}

extension Set: GDecodable where Element:GDecodable {
	public init(from decoder: some GDecoder) throws {
		self.init()
		
		self.reserveCapacity( decoder.unkeyedCount )
		while decoder.unkeyedCount > 0 {
			self.insert( try decoder.decode() )
		}
	}
}

extension Set : GBinaryEncodable where Element : GPackEncodable {}
extension Set : GBinaryDecodable where Element : GPackDecodable {}

//	Dictionary SUPPORT ------------------------------------------------------

extension Dictionary: GEncodable where Key:GEncodable, Value:GEncodable {
	public func encode(to encoder: some GEncoder) throws {
		for (key,value) in self {
			try encoder.encode( key )
			try encoder.encode( value )
		}
	}
}
extension Dictionary: GDecodable where Key:GDecodable, Value:GDecodable {
	public init(from decoder: some GDecoder) throws {
		self.init()
		
		self.reserveCapacity( decoder.unkeyedCount )
		while decoder.unkeyedCount > 0 {
			let key		: Key	= try decoder.decode()
			let value	: Value	= try decoder.decode()
			self[ key ]	= value
		}
	}
}

extension Dictionary : GBinaryEncodable where Key : GPackEncodable, Value : GPackEncodable {}
extension Dictionary : GBinaryDecodable where Key : GPackDecodable, Value : GPackDecodable {}


// Range ------------------------------------------------------

extension Range: GDecodable where Bound: GDecodable {
	public init(from decoder: some GDecoder) throws {
		let lowerBound	= try decoder.decode() as Bound
		let upperBound	= try decoder.decode() as Bound
		self.init(uncheckedBounds: (lowerBound,upperBound) )
	}
}

extension Range: GEncodable where Bound: GEncodable {
	public func encode(to encoder: some GEncoder) throws {
		try encoder.encode( lowerBound )
		try encoder.encode( upperBound )
	}
}
extension Range: GBinaryEncodable where Bound: GBinaryEncodable {}
extension Range: GBinaryDecodable where Bound: GBinaryDecodable {}
extension Range: GPackable where Bound: GPackable {}

// ClosedRange ------------------------------------------------------

extension ClosedRange: GDecodable where Bound: GDecodable {
	public init(from decoder: some GDecoder) throws {
		let lowerBound	= try decoder.decode() as Bound
		let upperBound	= try decoder.decode() as Bound
		self.init(uncheckedBounds: (lowerBound,upperBound) )
	}
}
extension ClosedRange: GEncodable where Bound: GEncodable {
	public func encode(to encoder: some GEncoder) throws {
		try encoder.encode( lowerBound )
		try encoder.encode( upperBound )
	}
}

extension ClosedRange: GBinaryEncodable where Bound: GBinaryEncodable {}
extension ClosedRange: GBinaryDecodable where Bound: GBinaryDecodable {}
extension ClosedRange: GPackable where Bound: GPackable {}


// PartialRangeFrom ------------------------------------------------------

extension PartialRangeFrom: GDecodable where Bound: GDecodable {
	public init(from decoder: some GDecoder) throws {
		self.init( try decoder.decode() as Bound )
	}
}
extension PartialRangeFrom: GEncodable where Bound: GEncodable {
	public func encode(to encoder: some GEncoder) throws {
		try encoder.encode( lowerBound )
	}
}

extension PartialRangeFrom: GBinaryEncodable where Bound: GBinaryEncodable {}
extension PartialRangeFrom: GBinaryDecodable where Bound: GBinaryDecodable {}
extension PartialRangeFrom: GPackable where Bound: GPackable {}

// PartialRangeUpTo ------------------------------------------------------

extension PartialRangeUpTo: GDecodable where Bound: GDecodable {
	public init(from decoder: some GDecoder) throws {
		self.init( try decoder.decode() as Bound )
	}
}
extension PartialRangeUpTo: GEncodable where Bound: GEncodable {
	public func encode(to encoder: some GEncoder) throws {
		try encoder.encode( upperBound )
	}
}

extension PartialRangeUpTo: GBinaryEncodable where Bound: GBinaryEncodable {}
extension PartialRangeUpTo: GBinaryDecodable where Bound: GBinaryDecodable {}
extension PartialRangeUpTo: GPackable where Bound: GPackable {}


// PartialRangeFrom ------------------------------------------------------

extension PartialRangeThrough: GDecodable where Bound: GDecodable {
	public init(from decoder: some GDecoder) throws {
		self.init( try decoder.decode() as Bound )
	}
}
extension PartialRangeThrough: GEncodable where Bound: GEncodable {
	public func encode(to encoder: some GEncoder) throws {
		try encoder.encode( upperBound )
	}
}

extension PartialRangeThrough: GBinaryEncodable where Bound: GBinaryEncodable {}
extension PartialRangeThrough: GBinaryDecodable where Bound: GBinaryDecodable {}
extension PartialRangeThrough: GPackable where Bound: GPackable {}


// CollectionDifference ------------------------------------------------------

fileprivate extension CollectionDifference.Change {
	private enum ChangeType : UInt8, GCodable { case insert, remove }
	private enum Key : String { case changeType, offset, element, associatedWith }
}

extension CollectionDifference.Change : GDecodable where ChangeElement : GDecodable {
	public init(from decoder: some GDecoder) throws {
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
	public func encode(to encoder: some GEncoder) throws {
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

extension CollectionDifference.Change : GBinaryEncodable where ChangeElement : GBinaryEncodable {}
extension CollectionDifference.Change : GBinaryDecodable where ChangeElement : GBinaryDecodable {}
extension CollectionDifference.Change : GPackable where ChangeElement : GPackable {}


extension CollectionDifference : GDecodable where ChangeElement:GDecodable {
	public init(from decoder: some GDecoder) throws {
		var changes	= [CollectionDifference<ChangeElement>.Change]()
		while decoder.unkeyedCount > 0 {
			changes.append( try decoder.decode() )
		}
		guard let value = Self(changes) else {
			throw GraphCodableError.libDecodingError(
				Self.self, GraphCodableError.Context(
					debugDescription: "Invalid \(changes)."
				)
			)
		}
		
		self = value
	}
}

extension CollectionDifference : GEncodable where ChangeElement:GEncodable {
	public func encode(to encoder: some GEncoder) throws {
		for element in self {
			try encoder.encode( element )
		}
	}
}

extension CollectionDifference : GBinaryEncodable where ChangeElement : GBinaryEncodable {}
extension CollectionDifference : GBinaryDecodable where ChangeElement : GBinaryDecodable {}
extension CollectionDifference : GPackable where ChangeElement : GPackable {}


