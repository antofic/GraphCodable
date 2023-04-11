//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

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
