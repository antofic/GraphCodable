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

protocol FixedSizeIOType : NativeIOType {
	init()
}

extension FixedSizeIOType {
	func write( to writer: inout BinaryWriter ) throws {
		writer.writeValue( self )
	}
	init( from reader: inout BinaryReader ) throws {
		var value = Self()
		try reader.readValue( &value )
		self = value
	}
}


// -- BinaryInteger support (FixedSizeIOType) -------------------------------------------------------
extension Int8		: FixedSizeIOType {}
extension Int16		: FixedSizeIOType {}
extension Int32		: FixedSizeIOType {}
extension Int64		: FixedSizeIOType {}
extension UInt8		: FixedSizeIOType {}
extension UInt16	: FixedSizeIOType {}
extension UInt32	: FixedSizeIOType {}
extension UInt64	: FixedSizeIOType {}

// -- BinaryFloatingPoint support (FixedSizeIOType) -------------------------------------------------------
extension Float		: FixedSizeIOType {}
extension Double	: FixedSizeIOType {}

// -- Bool support (FixedSizeIOType) -------------------------------------------------------
extension Bool : FixedSizeIOType {}


// -- Array support (FixedSizeIOType) -------------------------------------------------------

//	Attenzione, questa ottimizzazione solo per Array: Set e Dictionary la sfruttano
//	se l'array è fatto di FixedSizeIOType posso stamparlo in blocco
//	e pure l'array diventa un FixedSizeIOType

extension Array where Element : FixedSizeIOType {
	func write( to writer: inout BinaryWriter ) throws {
		writer.writeArray( self )
	}
	init( from reader: inout BinaryReader ) throws {
		self = try reader.readArray()
	}
}

// -- ContiguousArray support (FixedSizeIOType) -------------------------------------------------------

//	Attenzione, questa ottimizzazione solo per Array: Set e Dictionary la sfruttano
//	se l'array è fatto di FixedSizeIOType posso stamparlo in blocco
//	e pure l'array diventa un FixedSizeIOType

extension ContiguousArray where Element : FixedSizeIOType {
	func write( to writer: inout BinaryWriter ) throws {
		writer.writeContiguousArray( self )
	}
	init( from reader: inout BinaryReader ) throws {
		self = try reader.readContiguousArray()
	}
}


