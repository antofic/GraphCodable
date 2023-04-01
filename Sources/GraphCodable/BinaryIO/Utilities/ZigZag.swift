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

import Foundation

enum ZigZag {
	/// Transform signed integers to unsigned so that packing is possible.
	static func encode(  _ v:Int16 ) -> UInt16 {
		(UInt16(bitPattern: v) &+ UInt16(bitPattern: v)) ^ UInt16(bitPattern:( v &>> (v.bitWidth - 1) ))
	}
	/// Transform signed integers to unsigned so that packing is possible.
	static func encode(  _ v:Int32 ) -> UInt32 {
		(UInt32(bitPattern: v) &+ UInt32(bitPattern: v)) ^ UInt32(bitPattern:( v &>> (v.bitWidth - 1) ))
	}
	/// Transform signed integers to unsigned so that packing is possible.
	static func encode(  _ v:Int64 ) -> UInt64 {
		(UInt64(bitPattern: v) &+ UInt64(bitPattern: v)) ^ UInt64(bitPattern:( v &>> (v.bitWidth - 1) ))
	}

	/// Transform unsigned integers to signed so that unpacking is possible.
	static func decode(  _ v:UInt16 ) -> Int16 {
		Int16( bitPattern: (v &>> 1) ^ (0 &- (v & 1)) )
	}
	/// Transform unsigned integers to signed so that unpacking is possible.
	static func decode(  _ v:UInt32 ) -> Int32 {
		Int32( bitPattern: (v &>> 1) ^ (0 &- (v & 1)) )
	}
	/// Transform unsigned integers to signed so that unpacking is possible.
	static func decode(  _ v:UInt64 ) -> Int64 {
		Int64( bitPattern: (v &>> 1) ^ (0 &- (v & 1)) )
	}
}
