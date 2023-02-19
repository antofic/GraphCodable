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

//	RawRepresentable SUPPORT ------------------------------------------------------

extension RawRepresentable where Self.RawValue : GCodable {
	public func encode(to encoder: GEncoder) throws	{
		try encoder.encode( self.rawValue )
	}
	public init(from decoder: GDecoder) throws {
		let rawValue = try decoder.decode() as RawValue
		guard let value = Self.init(rawValue:rawValue ) else {
			throw GCodableError.initTypeError(
				Self.self, GCodableError.Context(
					debugDescription: "Invalid rawValue = \(rawValue) for \(Self.self)"
				)
			)
		}
		self = value
	}
}

//	String SUPPORT ------------------------------------------------------
extension String: GCodable {
	public func encode(to encoder: GEncoder) throws	{
		try withCString() { ptr0 in
			var ptr = ptr0
			while ptr.pointee != 0 {	// null terminated
				try encoder.encode( ptr.pointee )
				ptr += 1
			}
		}
	}
	public init(from decoder: GDecoder) throws {
		let count = decoder.unkeyedCount

		let string = try withUnsafeTemporaryAllocation(of: CChar.self, capacity: count+1) {
			let ptr = $0.baseAddress!
			for i in 0..<count {
				ptr[i]	= try decoder.decode()
			}
			ptr[count]	= 0
			return String( cString: $0.baseAddress! )
		}
		
		self = string
	}
}


//	Array SUPPORT ------------------------------------------------------
extension Array: GCodable where Element:GCodable {
	public func encode(to encoder: GEncoder) throws {
		for element in self {
			try encoder.encode( element )
		}
	}
	public init(from decoder: GDecoder) throws {
		self.init()
		
		self.reserveCapacity( decoder.unkeyedCount )
		while decoder.unkeyedCount > 0 {
			self.append( try decoder.decode() )
		}
	}
}


//	ContiguousArray SUPPORT ------------------------------------------------------

extension ContiguousArray: GCodable where Element:GCodable {
	public func encode(to encoder: GEncoder) throws {
		for element in self {
			try encoder.encode( element )
		}
	}
	public init(from decoder: GDecoder) throws {
		self.init()
		
		self.reserveCapacity( decoder.unkeyedCount )
		while decoder.unkeyedCount > 0 {
			self.append( try decoder.decode() )
		}
	}
}


//	Set SUPPORT ------------------------------------------------------
extension Set: GCodable where Element:GCodable {
	public func encode(to encoder: GEncoder) throws {
		for element in self {
			try encoder.encode( element )
		}
	}
	public init(from decoder: GDecoder) throws {
		self.init()
		
		self.reserveCapacity( decoder.unkeyedCount )
		while decoder.unkeyedCount > 0 {
			self.insert( try decoder.decode() )
		}
	}
}

//	Dictionary SUPPORT ------------------------------------------------------

extension Dictionary: GCodable where Key:GCodable, Value:GCodable {
	public func encode(to encoder: GEncoder) throws {
		for (key,value) in self {
			try encoder.encode( key )
			try encoder.encode( value )
		}
	}
	
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


// PartialRangeFrom ------------------------------------------------------

extension PartialRangeFrom: GCodable where Bound: GCodable {
	public init(from decoder: GDecoder) throws {
		self.init( try decoder.decode() as Bound )
	}
	
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( lowerBound )
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


// PartialRangeFrom ------------------------------------------------------

extension PartialRangeThrough: GCodable where Bound: GCodable {
	public init(from decoder: GDecoder) throws {
		self.init( try decoder.decode() as Bound )
	}
	
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( upperBound )
	}
}

// CollectionDifference ------------------------------------------------------

extension CollectionDifference.Change : GCodable where ChangeElement : GCodable {
	private enum ChangeType : UInt8, GCodable { case insert, remove }
	private enum Key : String { case changeType, offset, element, associatedWith }
	
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

extension CollectionDifference : GCodable where ChangeElement:GCodable {
	public init(from decoder: GDecoder) throws {
		var changes	= [CollectionDifference<ChangeElement>.Change]()
		while decoder.unkeyedCount > 0 {
			changes.append( try decoder.decode() )
		}
		guard let value = Self(changes) else {
			throw GCodableError.initTypeError(
				Self.self, GCodableError.Context(
					debugDescription: "Can't initialize \(Self.self) with \(changes)"
				)
			)
		}
		
		self = value
	}
	
	public func encode(to encoder: GEncoder) throws {
		for element in self {
			try encoder.encode( element )
		}
	}
}


