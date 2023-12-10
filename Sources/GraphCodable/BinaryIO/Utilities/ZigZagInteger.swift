//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

protocol ZigZagInteger : FixedWidthInteger {
	associatedtype Counterpart : ZigZagInteger
	init( bitPattern: Self.Counterpart )
}

extension ZigZagInteger where
Self: UnsignedInteger,
Self == Self.Counterpart.Counterpart
{
	/// Transform unsigned integers to signed so that unpacking is possible.
	var zigZagDecoded : Counterpart {
		Counterpart( bitPattern: (self &>> 1) ^ (0 &- (self & 1)) )
	}
}

extension ZigZagInteger where
Self: SignedInteger,
Self == Self.Counterpart.Counterpart
{
	/// Transform signed integers to unsigned with zigzag algorithm so that packing is possible.
	var zigZagEncoded : Counterpart {
		(Counterpart(bitPattern: self) &+ Counterpart(bitPattern: self)) ^ Counterpart(bitPattern:( self &>> (self.bitWidth - 1) ))
	}
}

extension UInt16:	ZigZagInteger {}
extension UInt32:	ZigZagInteger {}
extension UInt64:	ZigZagInteger {}
extension UInt:		ZigZagInteger {}

extension Int16: 	ZigZagInteger {}
extension Int32: 	ZigZagInteger {}
extension Int64: 	ZigZagInteger {}
extension Int: 		ZigZagInteger {}
