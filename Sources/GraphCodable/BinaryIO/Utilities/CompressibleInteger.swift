//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

protocol CompressibleInteger: FixedWidthInteger {
	func squeeze( pushByte: (UInt8) throws -> () ) rethrows
}

extension CompressibleInteger where
Self: UnsignedInteger
{
	func squeeze( pushByte: (UInt8) throws -> () ) rethrows {
		var	val		= self
		var byte	= UInt8( val & 0x7F )
		
		while val & (~0x7F) != 0 {
			byte 	|= 0x80
			try 	pushByte( byte )
			val 	&>>= 7
			byte	= UInt8( val & 0x7F )
		}
		try pushByte( byte )
	}
}

extension CompressibleInteger where
Self: SignedInteger & ZigZagInteger,
Self.Counterpart: CompressibleInteger,
Self.Counterpart.Counterpart == Self
{
	func squeeze( pushByte: (UInt8) throws -> () ) rethrows {
		try self.zigZagEncoded.squeeze( pushByte: pushByte )
	}
}

extension UInt16: CompressibleInteger {}
extension UInt32: CompressibleInteger {}
extension UInt64: CompressibleInteger {}
extension Int16: CompressibleInteger {}
extension Int32: CompressibleInteger {}
extension Int64: CompressibleInteger {}

extension UInt8: CompressibleInteger {
	func squeeze( pushByte: (UInt8) throws -> () ) rethrows {
		try pushByte( self )
	}
}

extension Int8: CompressibleInteger {
	func squeeze( pushByte: (UInt8) throws -> () ) rethrows {
		try UInt8(bitPattern: self).squeeze(pushByte: pushByte)
	}
}








