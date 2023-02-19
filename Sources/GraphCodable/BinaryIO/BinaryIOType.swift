//	MIT License
//
//	Copyright (c) 2021 Antonino Ficarra
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

public protocol BinaryIType {
	init( from reader: inout BinaryReader ) throws
}

public extension BinaryIType {
	init<Q>( binaryData: Q ) throws where Q:Sequence, Q.Element==UInt8 {
		var reader = BinaryReader( data:binaryData )
		try self.init( from: &reader )
	}
	
	static func peek( from reader: inout BinaryReader, _ accept:( Self ) -> Bool ) -> Self? {
		let position	= reader.position
		do {
			let value = try Self(from: &reader)
			if accept( value ) {
				return value
			}
		}
		catch {}

		reader.position	= position
		return nil
	}
}

public protocol BinaryOType {
	func write( to writer: inout BinaryWriter ) throws
}

public extension BinaryOType {
	func binaryData<Q>() throws -> Q where Q:MutableDataProtocol {
		var writer = BinaryWriter()
		try write( to:&writer )
		return writer.data()
	}
}

public typealias BinaryIOType = BinaryIType & BinaryOType

