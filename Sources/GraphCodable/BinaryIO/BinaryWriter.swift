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

	mutating func writeBool( _ value:Bool )			{ writeValue( value ) }

	mutating func writeInt8( _ value:Int8 )			{ writeValue( value ) }
	mutating func writeInt16( _ value:Int16 )		{ writeValue( value.littleEndian ) }
	mutating func writeInt32( _ value:Int32 )		{ writeValue( value.littleEndian ) }
	mutating func writeInt64( _ value:Int64 )		{ writeValue( value.littleEndian ) }
	
	mutating func writeUInt8(  _ value:UInt8 )		{ writeValue( value ) }
	mutating func writeUInt16( _ value:UInt16 )		{ writeValue( value.littleEndian ) }
	mutating func writeUInt32( _ value:UInt32 )		{ writeValue( value.littleEndian ) }
	mutating func writeUInt64( _ value:UInt64 )		{ writeValue( value.littleEndian ) }

	mutating func writeFloat( _ value:Float )		{ writeUInt32( value.bitPattern ) }
	mutating func writeDouble( _ value:Double )		{ writeUInt64( value.bitPattern ) }

	mutating func writeInt( _ value:Int ) throws {
		guard let value64 = Int64( exactly: value ) else {
			throw BinaryIOError.initTypeError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Int \(value) can't be converted to Int64."
				)
			)
		}
		writeInt64( value64 )
	}

	mutating func writeUInt( _ value:UInt ) throws {
		guard let value64 = UInt64( exactly: value ) else {
			throw BinaryIOError.initTypeError(
				Self.self, BinaryIOError.Context(
					debugDescription: "UInt \(value) can't be converted to UInt64."
				)
			)
		}
		writeUInt64( value64 )
	}
	
	private mutating func writeValue<T>( _ value:T ) {
		withUnsafePointer(to: value) { source in
			bytes.append(
				contentsOf: UnsafeBufferPointer(
					start: UnsafePointer<UInt8>( OpaquePointer( source ) ),
					count: MemoryLayout<T>.size
				)
			)
		}
	}
	
	mutating func writeData<T>( _ value:T ) where T:MutableDataProtocol, T:ContiguousBytes {
		writeInt64( Int64(value.count) )
		value.withUnsafeBytes { source in
			bytes.append(contentsOf: source)
		}
	}

	// write a null terminated utf8 string
	mutating func writeString( _ value:String ) {
		// string saved as null-terminated sequence of utf8
		value.withCString() { ptr0 in
			let ptr		= UnsafePointer<UInt8>( OpaquePointer( ptr0 ) )
			var endptr	= ptr
			while endptr.pointee != 0 { endptr += 1 }	// null terminated
			bytes.append( contentsOf:UnsafeBufferPointer( start: ptr, count: endptr - ptr + 1 ) )
		}
	}
}
