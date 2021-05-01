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

//	faster than BinaryWriterBase<Data> even if you must generate a Data result
typealias BinaryWriter = BinaryWriterBase<Array<UInt8>>
//	typealias BinaryWriter = BinaryWriterBase<Data>

struct BinaryWriterBase<T>
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
	
	// ----------------------------------------------------------------------------------------------------------
	// Bool
	// ----------------------------------------------------------------------------------------------------------
	mutating func write( _ v:Bool )					{ writeValue(v) }
	mutating func write( _ v:[Bool], count:Int )	{ writeArray(v) }
	mutating func write( _ v:[Bool] )				{ writeArray(v) }
	
	// ----------------------------------------------------------------------------------------------------------
	// BinaryInteger
	// ----------------------------------------------------------------------------------------------------------
	mutating func write<T>( _ v:T ) where T : BinaryInteger 				{ writeValue(v) }
	mutating func write<T>( _ v:[T], count:Int ) where T : BinaryInteger	{ writeArray(v) }
	mutating func write<T>( _ v:[T] ) where T : BinaryInteger				{ writeArray(v) }
	
	// ----------------------------------------------------------------------------------------------------------
	// Data
	// ----------------------------------------------------------------------------------------------------------

	mutating func write( _ v:Data )				{ writeData(v) }
	
	// ----------------------------------------------------------------------------------------------------------
	// BinaryFloatingPoint
	// ----------------------------------------------------------------------------------------------------------
	mutating func write<T>( _ v:T ) where T : BinaryFloatingPoint 				{ writeValue(v) }
	mutating func write<T>( _ v:[T], count:Int ) where T : BinaryFloatingPoint	{ writeArray(v) }
	mutating func write<T>( _ v:[T] ) where T : BinaryFloatingPoint				{ writeArray(v) }
	
	// ----------------------------------------------------------------------------------------------------------
	// String
	// ----------------------------------------------------------------------------------------------------------
	mutating func write(_ v: String ) 		{ writeString( v ) }
	
	// ----------------------------------------------------------------------------------------------------------
	// RawRepresentable
	// ----------------------------------------------------------------------------------------------------------
	
	mutating func write<T>( _ v:T ) where T : RawRepresentable, T.RawValue : BinaryInteger			{ write(v.rawValue) }
	mutating func write<T>( _ v:T ) where T : RawRepresentable, T.RawValue : BinaryFloatingPoint	{ write(v.rawValue) }
	mutating func write<T>( _ v:T ) where T : RawRepresentable, T.RawValue == String				{ write(v.rawValue) }
	mutating func write<T>( _ v:T ) where T : RawRepresentable, T.RawValue == Bool					{ write(v.rawValue) }

	// ----------------------------------------------------------------------------------------------------------
	// Private / unsafe section
	// ----------------------------------------------------------------------------------------------------------
	
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
	
	private mutating func writeArray<T>( _ v:[T], count:Int ) {
		v.withUnsafeBufferPointer { source in
			bytes.append(
				contentsOf: UnsafeBufferPointer(
					start: UnsafePointer<UInt8>( OpaquePointer( source.baseAddress ) ),
					count: count * MemoryLayout<T>.stride
				)
			)
		}
	}
	
	private mutating func writeData( _ v:Data ) {
		writeValue( v.count )
		v.withUnsafeBytes { source in
			bytes.append(contentsOf: source)
		}
	}
	
	private mutating func writeArray<T>( _ v:[T] ) {
		writeValue( v.count )
		writeArray( v, count:v.count )
	}
	
	// write a null terminated utf8 string
	private mutating func writeString( _ v:String ) {
		// string saved as null-terminated sequence of utf8
		v.withCString() { ptr in
			var endptr = ptr
			while endptr.pointee != 0 { endptr += 1 }	// null terminated
			bytes.append(
				contentsOf:UnsafeBufferPointer(
					start: UnsafePointer<UInt8>( OpaquePointer( ptr ) ),
					count: 1 + endptr - ptr
				)
			)
		}
	}
}
