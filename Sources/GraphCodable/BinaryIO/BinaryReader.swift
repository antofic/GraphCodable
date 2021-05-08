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

// faster than BinaryReaderBase<Data> even if bytes originally comes from Data
typealias BinaryReader = BinaryReaderBase<Array<UInt8>>
//	typealias BinaryReader = BinaryReaderBase<Data>

enum BinaryReaderError : Error {
	case outOfBounds
	case cantConstructRawRepresentable
}

struct BinaryReaderBase<T>
where T:MutableDataProtocol, T:ContiguousBytes, T.SubSequence:ContiguousBytes {
	private let base:	T
	private var bytes:	T.SubSequence
	
	init( bytes: T ) {
		self.base	= bytes
		self.bytes	= bytes[ ... ]
	}
	
	init<Q>( data: Q ) where Q:Sequence, Q.Element==UInt8 {
		if let bytes = data as? T {
			self.init( bytes: bytes )
		} else {
			self.init( bytes: T(data) )
		}
	}
	
	var eof : Bool {
		return bytes.count == 0
	}
		
	private func checkRemainingSize( size:Int ) throws {
		if bytes.count < size {
			throw BinaryReaderError.outOfBounds
		}
	}

	// usafe section ---------------------------------------------------------
	
	mutating func readValue<T:FixedSizeIOType>( _ v : inout T ) throws {
		let inSize	= MemoryLayout<T>.size
		try checkRemainingSize( size:inSize )
		defer { bytes.removeFirst( inSize ) }
		
		bytes.withUnsafeBytes { source in
			withUnsafeMutableBytes(of: &v) { target in
				_ = memcpy( target.baseAddress, source.baseAddress, inSize )
			}
		}
	}

	mutating func readArray<T:FixedSizeIOType>( count:Int ) throws -> [T] {
		let inSize	= count * MemoryLayout<T>.stride
		try checkRemainingSize( size:inSize )
		defer { bytes.removeFirst( inSize ) }

		return bytes.withUnsafeBytes { source in
			Array<T>(unsafeUninitializedCapacity: count) { (target, outCount) in
				_ = memcpy( target.baseAddress, source.baseAddress, inSize )
				outCount	= count
			}
		}
	}
	
	mutating func readArray<T:FixedSizeIOType>() throws -> [T] {
		var count = Int64(0)
		try readValue( &count )
		return try readArray( count:Int(count) )
	}

	mutating func readContiguousArray<T:FixedSizeIOType>( count:Int ) throws -> ContiguousArray<T> {
		let inSize	= count * MemoryLayout<T>.stride
		try checkRemainingSize( size:inSize )
		defer { bytes.removeFirst( inSize ) }

		return bytes.withUnsafeBytes { source in
			ContiguousArray<T>(unsafeUninitializedCapacity: count) { (target, outCount) in
				_ = memcpy( target.baseAddress, source.baseAddress, inSize )
				outCount	= count
			}
		}
	}
	
	mutating func readContiguousArray<T:FixedSizeIOType>() throws -> ContiguousArray<T> {
		var count = Int64(0)
		try readValue( &count )
		return try readContiguousArray( count:Int(count) )
	}

	mutating func readData() throws -> Data {
		var count = Int64(0)
		try readValue( &count )

		let inSize	= Int(count) * MemoryLayout<UInt8>.stride
		try checkRemainingSize( size: inSize )
		defer { bytes.removeFirst( inSize ) }

		return bytes.withUnsafeBytes { source in
			return Data( source.prefix( inSize ) )
		}
	}
	
	// read a null terminated utf8 string
	mutating func readString() throws -> String {
		let availableCount	= bytes.count
		
		// ci deve essere almeno un carattere: null
		guard availableCount > 0 else {
			throw BinaryReaderError.outOfBounds
		}
		
		var inSize = 0
		let string = try bytes.withUnsafeBytes { source -> String in
			guard let baseAddress = source.baseAddress else {
				throw BinaryReaderError.outOfBounds
			}
			let ptr	= UnsafePointer<UInt8>( OpaquePointer( baseAddress ) )
			// non posso superare bytesCount
			for index in 0..<availableCount {
				if ptr[index] == 0 {	// ho trovato NULL
					inSize = index + 1
					return String(cString: ptr)
				}
			}
			// ho superato bytesCount!
			throw BinaryReaderError.outOfBounds
		}
		bytes.removeFirst( inSize )
		return string
	}	
}

