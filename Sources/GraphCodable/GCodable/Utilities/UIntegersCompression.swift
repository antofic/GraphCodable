//
//  File.swift
//  
//
//  Created by Antonino Ficarra on 04/03/23.
//

import Foundation

/*
func zigzagEncode( _ val:Int16 ) -> UInt16 {
	(UInt16(bitPattern: val) &+ UInt16(bitPattern: val)) ^ UInt16(bitPattern:( val &>> 15 ))
}

func zigzagDecode( _ val:UInt16 ) -> Int16 {
	Int16(bitPattern:  (val >> 1) ^ (0 &- (val & 1)) )
}
*/
/*
protocol BCompression {
	func compress(to encoder: inout some BEncoder ) throws
}

protocol BDecompression {
	static func decompress( from decoder: inout some BDecoder ) throws -> Self
}


extension FixedWidthInteger where Self : UnsignedInteger {
	static func decompress( from decoder: inout some BDecoder ) throws -> Self {
		var	byte	= try decoder.decode() as UInt8
		if MemoryLayout<Self>.size > 1 {
			var	val		= Self( byte & 0x7F )
			
			for index in 1...MemoryLayout<Self>.size {
				guard byte & 0x80 != 0 else {
					return val
				}
				byte	= 	try decoder.decode() as UInt8
				val		|=	Self( byte & 0x7F ) &<< (index*7)
			}
			return val
		} else {
			return Self( byte )
		}
	}
}

extension FixedWidthInteger where Self : UnsignedInteger {
	func compress(to encoder: inout some BEncoder ) throws {
		if MemoryLayout<Self>.size > 1 {
			var	val		= self
			var byte	= UInt8( val & 0x7F )
			
			while val & (~0x7F) != 0 {
				byte 	|= 0x80
				try 	encoder.encode( byte )
				val 	&>>= 7
				byte	= UInt8( val & 0x7F )
			}
			try encoder.encode( byte )
		} else {
			try encoder.encode( UInt8( self ) )
		}
	}
}

extension FixedWidthInteger where Self : UnsignedInteger {
	var compressedSize : Int {
		var size	= 1
		if MemoryLayout<Self>.size > 1 {
			var	val		= self
			var byte	= UInt8( val & 0x7F )
			
			while val & (~0x7F) != 0 {
				byte 	|= 0x80
				size	+= 1
				val 	&>>= 7
				byte	= UInt8( val & 0x7F )
			}
		}
		return size
	}
}

extension UInt8: BCompression {}
extension UInt8: BDecompression {}

extension UInt16: BCompression {}
extension UInt16: BDecompression {}

extension UInt32: BCompression {}
extension UInt32: BDecompression {}

extension UInt64: BCompression {}
extension UInt64: BDecompression {}

extension Int8: BCompression {
	func compress(to encoder: inout some BEncoder ) throws {
		try encoder.encode( self )
	}
}

extension Int8: BDecompression {
	static func decompress( from decoder: inout some BDecoder ) throws -> Self {
		try decoder.decode()
	}

}

extension Int16: BCompression {
	func compress(to encoder: inout some BEncoder ) throws {
		let uint = (UInt16(bitPattern: self) &+ UInt16(bitPattern: self)) ^ UInt16(bitPattern:( self &>> 15 ))
		try uint.compress(to: &encoder)
	}
}

extension Int16: BDecompression {
	static func decompress( from decoder: inout some BDecoder ) throws -> Self {
		let uint = try UInt16.decompress( from: &decoder )
		return Self( bitPattern: (uint >> 1) ^ (0 &- (uint & 1))  )
	}
}

extension Int32: BCompression {
	func compress(to encoder: inout some BEncoder ) throws {
		let uint = (UInt32(bitPattern: self) &+ UInt32(bitPattern: self)) ^ UInt32(bitPattern:( self &>> 31 ))
		try uint.compress(to: &encoder)
	}
}

extension Int32: BDecompression {
	static func decompress( from decoder: inout some BDecoder ) throws -> Self {
		let uint = try UInt32.decompress( from: &decoder )
		return Self( bitPattern: (uint >> 1) ^ (0 &- (uint & 1))  )
	}
}

extension Int64: BCompression {
	func compress(to encoder: inout some BEncoder ) throws {
		let uint = (UInt64(bitPattern: self) &+ UInt64(bitPattern: self)) ^ UInt64(bitPattern:( self &>> 63 ))
		try uint.compress(to: &encoder)
	}
}

extension Int64: BDecompression {
	static func decompress( from decoder: inout some BDecoder ) throws -> Self {
		let uint = try UInt64.decompress( from: &decoder )
		return Self( bitPattern: (uint >> 1) ^ (0 &- (uint & 1))  )
	}
}
*/
