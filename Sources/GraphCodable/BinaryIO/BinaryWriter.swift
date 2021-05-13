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

/*
BinaryWriter data format uses always:
	• little-endian
	• store Int, UInt as Int64, UInt64
*/

//	faster than BinaryWriterBase<Data> even if you must generate a Data result
//	public typealias BinaryWriter = BinaryWriterBase<Array<UInt8>>
//	typealias BinaryWriter = BinaryWriterBase<Data>

public struct BinaryWriter{
	private (set) var bytes = Array<UInt8>()

	func data<Q>() -> Q where Q:MutableDataProtocol {
		if let data = bytes as? Q {
			return data
		} else {
			return Q( bytes )
		}
	}
/*
	public mutating func write<T>( _ v:T ) throws where T:BinaryIOType {
		try v.write( to: &self )
	}

*/
	
	public mutating func write( _ v:BinaryIOType ) throws {
		try v.write( to: &self )
	}

	mutating func write( _ v:Bool ) throws		{ writeValue( v ) }
	mutating func write( _ v:Int8 ) throws		{ writeValue( v.littleEndian ) }
	mutating func write( _ v:Int16 ) throws		{ writeValue( v.littleEndian ) }
	mutating func write( _ v:Int32 ) throws		{ writeValue( v.littleEndian ) }
	mutating func write( _ v:Int64 ) throws		{ writeValue( v.littleEndian ) }
	mutating func write(  _ v:UInt8 ) throws	{ writeValue( v.littleEndian ) }
	mutating func write( _ v:UInt16 ) throws	{ writeValue( v.littleEndian ) }
	mutating func write( _ v:UInt32 ) throws	{ writeValue( v.littleEndian ) }
	mutating func write( _ v:UInt64 ) throws	{ writeValue( v.littleEndian ) }
	mutating func write( _ v:Float ) throws		{ try write( v.bitPattern ) }
	mutating func write( _ v:Double ) throws	{ try write( v.bitPattern ) }

	mutating func write( _ v:Int ) throws {
		guard let value64 = Int64( exactly: v ) else {
			throw BinaryIOError.initTypeError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Int \(v) can't be converted to Int64."
				)
			)
		}
		try write( value64 )
	}

	mutating func write( _ v:UInt ) throws {
		guard let value64 = UInt64( exactly: v ) else {
			throw BinaryIOError.initTypeError(
				Self.self, BinaryIOError.Context(
					debugDescription: "UInt \(v) can't be converted to UInt64."
				)
			)
		}
		try write( value64 )
	}
	
	mutating func write<T>( _ v:T ) throws where T:MutableDataProtocol, T:ContiguousBytes {
		try write( Int64(v.count) )
		v.withUnsafeBytes { source in
			bytes.append(contentsOf: source)
		}
	}

	// write a null terminated utf8 string
	mutating func write( _ v:String )  throws {
		// string saved as null-terminated sequence of utf8
		v.withCString() { ptr in
			var endptr = ptr
			while endptr.pointee != 0 { endptr += 1 }	// null terminated
			bytes.append(
				contentsOf:UnsafeBufferPointer(
					start: UnsafePointer<UInt8>( OpaquePointer( ptr ) ),
					count: endptr - ptr + 1
				)
			)
		}
	}

	// ------------- private
	private mutating func writeValue<T>( _ v:T ) {
		withUnsafePointer(to: v) { source in
			bytes.append(
				contentsOf: UnsafeBufferPointer(
					start: UnsafePointer<UInt8>( OpaquePointer( source ) ),
					count: MemoryLayout<T>.size
				)
			)
		}
	}
}
