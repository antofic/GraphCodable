//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

// Never ------------------------------------------------------

extension Never : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		// nothing to do
	}
}

extension Never : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		throw Errors.BinaryIO.libDecodingError(
			Self.self, Errors.Context(
				debugDescription: "Never type can't be istantiated."
			)
		)
	}
}

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
			throw Errors.BinaryIO.libDecodingError(
				Self.self, Errors.Context(
					debugDescription: "Invalid rawValue |\(rawValue)|"
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
			throw Errors.BinaryIO.libDecodingError(
				Self.self, Errors.Context(
					debugDescription: "Invalid |\(changes)|"
				)
			)
		}
		
		self = value
	}
}
