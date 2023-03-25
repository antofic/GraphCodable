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
	init?<Q>( decompressFrom iterator: inout Q )
	where Q:IteratorProtocol, Q.Element==UInt8 {
		guard var byte = iterator.next() else { return nil }
		if MemoryLayout<Self>.size > 1 {
			var	val		= Self( byte & 0x7F )
			
			for index in 1...MemoryLayout<Self>.size {
				guard byte & 0x80 != 0 else {
					self = val
					return
				}
				guard let _byte = iterator.next() else { return nil }
				byte	= 	_byte
				val		|=	Self( byte & 0x7F ) << (index*7)
			}
			self = val
		} else {
			self.init( byte )
		}
	}
	
	func compress<Q>( to data: inout Q )
	where Q:MutableDataProtocol
	{
		if MemoryLayout<Self>.size > 1 {
			var	val		= self
			var byte	= UInt8( val & 0x7F )
			
			while val & (~0x7F) != 0 {
				byte 	|= 0x80
				data.append( byte )
				val 	>>= 7
				byte	= UInt8( val & 0x7F )
			}
			data.append( byte )
		} else {
			data.append( UInt8( self ) )
		}
	}
}
	
extension UnsignedInteger {
	init( decompressFrom rbuffer: inout BinaryReadBuffer ) throws {
		var	byte	= try UInt8( from: &rbuffer )
		if MemoryLayout<Self>.size > 1 {
			var	val		= Self( byte & 0x7F )
			
			for index in 1...MemoryLayout<Self>.size {
				guard byte & 0x80 != 0 else {
					self = val
					return
				}
				byte	= 	try UInt8( from: &rbuffer )
				val		|=	Self( byte & 0x7F ) << (index*7)
			}
			self = val
		} else {
			self.init( byte )
		}
	}

	func write(compressTo wbuffer: inout BinaryWriteBuffer) throws {
		if MemoryLayout<Self>.size > 1 {
			var	val		= self
			var byte	= UInt8( val & 0x7F )
			
			while val & (~0x7F) != 0 {
				byte 	|= 0x80
				try 	byte.write( to: &wbuffer )
				val 	>>= 7
				byte	= UInt8( val & 0x7F )
			}
			try byte.write( to: &wbuffer )
		} else {
			try UInt8( self ).write( to: &wbuffer )
		}
	}

	var compressedSize : Int {
		var size	= 1
		if MemoryLayout<Self>.size > 1 {
			var	val		= self
			var byte	= UInt8( val & 0x7F )
			
			while val & (~0x7F) != 0 {
				byte 	|= 0x80
				size	+= 1
				val 	>>= 7
				byte	= UInt8( val & 0x7F )
			}
		}
		return size
	}
}
