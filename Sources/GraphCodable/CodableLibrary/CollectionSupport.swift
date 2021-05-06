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

//	Array SUPPORT ------------------------------------------------------
extension Array: GCodable where Element:GCodable {
	public func encode(to encoder: GEncoder) throws {
		for element in self {
			try encoder.encode( element )
		}
	}
	public init(from decoder: GDecoder) throws {
		self.init()
		
		self.reserveCapacity( try decoder.unkeyedCount() )
		while try decoder.unkeyedCount() > 0 {
			self.append( try decoder.decode() )
		}
	}
}

extension Array : NativeIOType where Element : NativeIOType {
	func write( to writer: inout BinaryWriter ) throws {
		try count.write(to: &writer)
		for element in self {
			try element.write(to: &writer)
		}
	}
	init( from reader: inout BinaryReader ) throws {
		var array = [Element]()
		let count = try Int( from: &reader )
		array.reserveCapacity( count )
		for _ in 0..<count {
			array.append( try Element.init(from: &reader) )
		}
		self = array
	}
}

//	Attenzione, questa ottimizzazione solo per Array: Set e Dictionary la sfruttano
//	se l'array è fatto di FixedSizeIOType posso stamparlo in blocco
//	e pure l'array diventa un FixedSizeIOType
extension Array : FixedSizeIOType where Element : FixedSizeIOType {
	func write( to writer: inout BinaryWriter ) throws {
		writer.writeArray( self )
	}
	init( from reader: inout BinaryReader ) throws {
		self = try reader.readArray()
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
		
		self.reserveCapacity( try decoder.unkeyedCount() )
		while try decoder.unkeyedCount() > 0 {
			self.append( try decoder.decode() )
		}
	}
}

extension ContiguousArray : NativeIOType where Element : NativeIOType {
	func write( to writer: inout BinaryWriter ) throws {
		try count.write(to: &writer)
		for element in self {
			try element.write(to: &writer)
		}
	}
	init( from reader: inout BinaryReader ) throws {
		var array = ContiguousArray<Element>()
		let count = try Int( from: &reader )
		array.reserveCapacity( count )
		for _ in 0..<count {
			array.append( try Element.init(from: &reader) )
		}
		self = array
	}
}


extension ContiguousArray : FixedSizeIOType where Element : FixedSizeIOType {
	func write( to writer: inout BinaryWriter ) throws {
		writer.writeContiguousArray( self )
	}
	init( from reader: inout BinaryReader ) throws {
		self = try reader.readContiguousArray()
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
		
		self.reserveCapacity( try decoder.unkeyedCount() )
		while try decoder.unkeyedCount() > 0 {
			self.insert( try decoder.decode() )
		}
	}
}

extension Set : NativeIOType where Element : NativeIOType {
	func write( to writer: inout BinaryWriter ) throws {
		try Array( self ).write(to: &writer)
	}
	init( from reader: inout BinaryReader ) throws {
		self = Set( try Array(from: &reader) )
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
		
		self.reserveCapacity( try decoder.unkeyedCount() )
		while try decoder.unkeyedCount() > 0 {
			let key		: Key	= try decoder.decode()
			let value	: Value	= try decoder.decode()
			self[ key ]	= value
		}
	}
}

extension Dictionary : NativeIOType where Key : NativeIOType, Value : NativeIOType {
	func write( to writer: inout BinaryWriter ) throws {
		try Array( self.keys ).write(to: &writer )
		try Array( self.values ).write(to: &writer )
	}

	init( from reader: inout BinaryReader ) throws {
		let keys	= try [Key](from: &reader)
		let values	= try [Value](from: &reader)

		self.init(uniqueKeysWithValues: zip(keys, values))
	}
}
