//
//  File.swift
//  
//
//  Created by Antonino Ficarra on 04/03/23.
//

import Foundation

///	Read and Write packed UnsignedIntegers to reduce file size:
///	we use it to compact typeID's, objID's, keyID's
///	**Note:** Packed data is variable in size.
extension UnsignedInteger {
	init( unpackFrom rbuffer: inout BinaryReadBuffer ) throws {
		if MemoryLayout<Self>.size > 1 {
			var	word	= try UInt8( from: &rbuffer )
			var	val		= Self( word & 0x7F )
			
			for index in 1...MemoryLayout<Self>.size {
				guard word & 0x80 != 0 else {
					self = val
					return
				}
				word	= 	try UInt8( from: &rbuffer )
				val		|=	Self( word & 0x7F ) << (index*7)
			}
			self = val
		} else {
			self.init( try UInt8( from: &rbuffer ) )
		}
	}

	func write(packTo wbuffer: inout BinaryWriteBuffer) throws {
		if MemoryLayout<Self>.size > 1 {
			var	val		= self
			var word	= UInt8( val & 0x7F )
			
			while val & (~0x7F) != 0 {
				word 	|= 0x80
				try 	word.write( to: &wbuffer )
				val 	>>= 7
				word	= UInt8( val & 0x7F )
			}
			try word.write( to: &wbuffer )
		} else {
			try UInt8( self ).write( to: &wbuffer )
		}
	}
}
