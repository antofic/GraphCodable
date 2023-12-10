//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

protocol ZigzagInteger : FixedWidthInteger {
	associatedtype Counterpart : ZigzagInteger
	init( bitPattern: Self.Counterpart )
}

extension ZigzagInteger where
Self: UnsignedInteger,
Self == Self.Counterpart.Counterpart
{
	/// returns the signed integer starting from the unsigned integer
	/// value (self) suitable for compression
	var zigzag: Counterpart {
		Counterpart( bitPattern: (self &>> 1) ^ (0 &- (self & 1)) )
	}
}

extension ZigzagInteger where
Self: SignedInteger,
Self == Self.Counterpart.Counterpart
{
	/// returns an unsigned integer suitable for integer compression
	var zigzag: Counterpart {
		(Counterpart(bitPattern: self) &+ Counterpart(bitPattern: self)) ^ Counterpart(bitPattern:( self &>> (self.bitWidth - 1) ))
	}
}

extension UInt16:	ZigzagInteger {}
extension UInt32:	ZigzagInteger {}
extension UInt64:	ZigzagInteger {}
extension UInt:		ZigzagInteger {}

extension Int16: 	ZigzagInteger {}
extension Int32: 	ZigzagInteger {}
extension Int64: 	ZigzagInteger {}
extension Int: 		ZigzagInteger {}
