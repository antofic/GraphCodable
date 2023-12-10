//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

protocol CompressibleInteger: FixedWidthInteger {
	func compress( pushByte: (UInt8) throws -> () ) rethrows
}

extension CompressibleInteger where
Self: UnsignedInteger
{
	func compress( pushByte: (UInt8) throws -> () ) rethrows {
		var	value	= self
		var byte	= UInt8( value & 0x7F )
		
		while value & (~0x7F) != 0 {
			byte 	|= 0x80
			try 	pushByte( byte )
			value 	&>>= 7
			byte	= UInt8( value & 0x7F )
		}
		try pushByte( byte )
	}
}

extension CompressibleInteger where
Self: SignedInteger & ZigzagInteger,
Self.Counterpart: CompressibleInteger,
Self.Counterpart.Counterpart == Self
{
	func compress( pushByte: (UInt8) throws -> () ) rethrows {
		//	transforms the signed integer into an unsigned one
		//	and compresses it.
		try self.zigzag.compress( pushByte: pushByte )
	}
}

extension UInt16: CompressibleInteger {}
extension UInt32: CompressibleInteger {}
extension UInt64: CompressibleInteger {}
extension UInt: CompressibleInteger {}

extension Int16: CompressibleInteger {}
extension Int32: CompressibleInteger {}
extension Int64: CompressibleInteger {}
extension Int: CompressibleInteger {}

extension UInt8: CompressibleInteger {
	func compress( pushByte: (UInt8) throws -> () ) rethrows {
		try pushByte( self )
	}
}

extension Int8: CompressibleInteger {
	func compress( pushByte: (UInt8) throws -> () ) rethrows {
		try UInt8(bitPattern: self).compress(pushByte: pushByte)
	}
}







