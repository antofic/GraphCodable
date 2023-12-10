//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

protocol DecompressibleInteger: FixedWidthInteger {
	static func decompress( popByte: () throws -> UInt8 ) rethrows -> Self
}

extension DecompressibleInteger where
Self: UnsignedInteger
{
	static func decompress( popByte: () throws -> UInt8 ) rethrows -> Self {
		var	byte	= try popByte()
		var	val		= Self( byte & 0x7F )
		
		for index in 1...MemoryLayout<Self>.size {
			guard byte & 0x80 != 0 else {
				return val
			}
			byte	= 	try popByte()
			val		|=	Self( byte & 0x7F ) &<< ( index * 7 )
		}
		return val
	}
}

extension DecompressibleInteger where
Self: SignedInteger & ZigZagInteger,
Self.Counterpart: DecompressibleInteger & UnsignedInteger,
Self.Counterpart.Counterpart == Self
{
	static func decompress( popByte: () throws -> UInt8 ) rethrows -> Self {
		try Counterpart.decompress(popByte: popByte).zigZagDecoded
	}
}

extension UInt16: DecompressibleInteger {}
extension UInt32: DecompressibleInteger {}
extension UInt64: DecompressibleInteger {}
extension Int16: DecompressibleInteger {}
extension Int32: DecompressibleInteger {}
extension Int64: DecompressibleInteger {}

extension UInt8: DecompressibleInteger {
	static func decompress( popByte: () throws -> UInt8 ) rethrows -> Self {
		try popByte()
	}
}

extension Int8: DecompressibleInteger {
	static func decompress( popByte: () throws -> UInt8 ) rethrows -> Self {
		Self( bitPattern: try .decompress(popByte: popByte) )
	}
}
