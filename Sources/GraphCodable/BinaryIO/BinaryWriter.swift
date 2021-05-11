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
public typealias BinaryWriter = BinaryWriterBase<Array<UInt8>>
//	typealias BinaryWriter = BinaryWriterBase<Data>

public struct BinaryWriterBase<T>
where T:MutableDataProtocol, T:ContiguousBytes
{
	private (set) var bytes = T()

	func data<Q>() -> Q where Q:MutableDataProtocol {
		if let data = bytes as? Q {
			return data
		} else {
			return Q( bytes )
		}
	}

	mutating func writeBool( _ v:Bool )			{ writeValue( v ) }

	mutating func writeInt8( _ v:Int8 )			{ writeValue( v.littleEndian ) }
	mutating func writeInt16( _ v:Int16 )		{ writeValue( v.littleEndian ) }
	mutating func writeInt32( _ v:Int32 )		{ writeValue( v.littleEndian ) }
	mutating func writeInt64( _ v:Int64 )		{ writeValue( v.littleEndian ) }
	
	mutating func writeUInt8(  _ v:UInt8 )		{ writeValue( v.littleEndian ) }
	mutating func writeUInt16( _ v:UInt16 )		{ writeValue( v.littleEndian ) }
	mutating func writeUInt32( _ v:UInt32 )		{ writeValue( v.littleEndian ) }
	mutating func writeUInt64( _ v:UInt64 )		{ writeValue( v.littleEndian ) }

	mutating func writeFloat( _ v:Float )		{ writeUInt32( v.bitPattern ) }
	mutating func writeDouble( _ v:Double )		{ writeUInt64( v.bitPattern ) }

	mutating func writeInt( _ v:Int ) throws {
		guard let value64 = Int64( exactly: v ) else {
			throw BinaryIOError.initTypeError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Int \(v) can't be converted to Int64."
				)
			)
		}
		writeInt64( value64 )
	}

	mutating func writeUInt( _ v:UInt ) throws {
		guard let value64 = UInt64( exactly: v ) else {
			throw BinaryIOError.initTypeError(
				Self.self, BinaryIOError.Context(
					debugDescription: "UInt \(v) can't be converted to UInt64."
				)
			)
		}
		writeUInt64( value64 )
	}
	
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
	
	mutating func writeData<T>( _ v:T ) where T:MutableDataProtocol, T:ContiguousBytes {
		writeInt64( Int64(v.count) )
		v.withUnsafeBytes { source in
			bytes.append(contentsOf: source)
		}
	}

	// write a null terminated utf8 string
	mutating func writeString( _ v:String ) {
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
}
