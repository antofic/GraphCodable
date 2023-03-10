//	MIT License
//
//	Copyright (c) 2021-2023 Antonino Ficarra
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

/*
BinaryWriteBuffer data format uses always:
	• little-endian
	• store Int, UInt as Int64, UInt64
*/

/// Buffer to write instances of BinaryOType types to.
public struct BinaryWriteBuffer {
	public let			version		: UInt16
	private (set) var 	bytes 		: Bytes
	private var 		_position	: Int
	private var			insert		: Bool

	init( version: UInt16 ) {
		self.version		= version
		self.bytes			= Bytes()
		self._position		= 0
		self.insert			= false
		// really can't throw
		try! self.writeValue( version )
	}
	
	func data<Q>() -> Q where Q:MutableDataProtocol {
		if let data = bytes as? Q {
			return data
		} else {
			return Q( bytes )
		}
	}

	var startOfFile	: Int { MemoryLayout.size(ofValue: version) }
	var endOfFile	: Int { bytes.endIndex }
	
	mutating func setPositionToStart()	{ _position = startOfFile }
	mutating func setPositionToEnd()	{ _position = endOfFile }

	var position: Int {
		get { _position }
		set {
			precondition( (startOfFile...endOfFile).contains( newValue ),"\(Self.self): outOfBounds position." )
			_position	= newValue
		}
	}

	mutating func prependingWrite(
		dummyWrite			dummyFunc: ( _: inout BinaryWriteBuffer ) throws -> (),
		thenWrite 			writeFunc: ( _: inout BinaryWriteBuffer ) throws -> (),
		thenOverwriteDummy 	overwriteFunc: ( inout BinaryWriteBuffer, _: Int ) throws -> ()
	) throws {
		let dummyPos		= position
		try dummyFunc( &self )
		let bodyPos			= position
		try writeFunc( &self )
		let finalPos		= position
		
		position			= dummyPos
		try overwriteFunc( &self, finalPos - bodyPos )
		let newbodyPos		= position
		position			= finalPos

		if newbodyPos != bodyPos {
			throw BinaryIOError.prependingFails(
				Self.self, BinaryIOError.Context(
					debugDescription: "\(Self.self): outOfBounds position."
				)
			)
		}
	}
	
	mutating func insertingWrite(
		firstWrite	writeFunc: ( _: inout BinaryWriteBuffer ) throws -> (),
		thenInsert	insertFunc: ( _: inout BinaryWriteBuffer, _: Int ) throws -> ()
	) throws {
		let initialPos		= position
		try writeFunc( &self )
		let finalPos		= position
		position			= initialPos
		do {
			insert = true
			defer { insert = false }
			try insertFunc( &self, finalPos - initialPos )
		}
		let valuePos		= position
		position	= finalPos + (valuePos - initialPos)
	}
	
	private mutating func write<C>( contentsOf source:C ) throws
	where C:RandomAccessCollection, C.Element == UInt8 {
		if position == bytes.endIndex {
			bytes.append( contentsOf: source )
		} else if position >= bytes.startIndex {
			let endIndex	= bytes.index( position, offsetBy: insert ? 0 : source.count )
			let range		= position ..< Swift.min( bytes.endIndex, endIndex )
			bytes.replaceSubrange( range, with: source )
		} else {
			throw BinaryIOError.outOfBounds(
				Self.self, BinaryIOError.Context(
					debugDescription: "\(Self.self): outOfBounds position."
				)
			)
		}
		_position += source.count
	}
	
	private mutating func writeValue<T>( _ value:T ) throws {
		guard _isPOD(T.self) else {
			throw BinaryIOError.notPODType(
				Self.self, BinaryIOError.Context(
					debugDescription: "\(T.self) must be a POD type."
				)
			)
		}
		
		try withUnsafePointer(to: value) { source in
			let size = MemoryLayout<T>.size
			try source.withMemoryRebound(to: UInt8.self, capacity: size ) {
				try write( contentsOf: UnsafeBufferPointer( start: $0, count: size ) )
			}
		}
	}

	mutating func writeData<T>( _ value:T, insert:Bool = false ) throws where T:MutableDataProtocol, T:ContiguousBytes {
		try writeInt64( Int64(value.count) )
		try value.withUnsafeBytes { source in
			try write(contentsOf: source)
		}
	}

	// write a null terminated utf8 string
	mutating func writeString( _ value:String, insert:Bool = false ) throws {
		// string saved as null-terminated sequence of utf8
		//	let uint8array	= unsafeBitCast( value.utf8CString, to: ContiguousArray<UInt8>.self )
		//	try write( contentsOf: uint8array )
		
		try value.withCString() { ptr in
			var endptr	= ptr
			while endptr.pointee != 0 { endptr += 1 }	// null terminated
			let size = endptr - ptr + 1
			try ptr.withMemoryRebound(to: UInt8.self, capacity: size ) {
				try write( contentsOf: UnsafeBufferPointer( start: $0, count: size ) )
			}
		}
		 
	}
}

extension BinaryWriteBuffer {
	mutating func writeBool( _ value:Bool ) throws			{ try writeValue( value ) }

	mutating func writeInt8( _ value:Int8 ) throws			{ try writeValue( value ) }
	mutating func writeInt16( _ value:Int16 ) throws		{ try writeValue( value.littleEndian ) }
	mutating func writeInt32( _ value:Int32 ) throws		{ try writeValue( value.littleEndian ) }
	mutating func writeInt64( _ value:Int64 ) throws		{ try writeValue( value.littleEndian ) }

	mutating func writeUInt8(  _ value:UInt8 ) throws		{ try writeValue( value ) }
	mutating func writeUInt16( _ value:UInt16 ) throws		{ try writeValue( value.littleEndian ) }
	mutating func writeUInt32( _ value:UInt32 ) throws		{ try writeValue( value.littleEndian ) }
	mutating func writeUInt64( _ value:UInt64 ) throws		{ try writeValue( value.littleEndian ) }

	mutating func writeFloat( _ value:Float ) throws		{ try writeUInt32( value.bitPattern ) }
	mutating func writeDouble( _ value:Double ) throws		{ try writeUInt64( value.bitPattern ) }

	mutating func writeInt( _ value:Int ) throws {
		guard let value64 = Int64( exactly: value ) else {
			throw BinaryIOError.initTypeError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Int \(value) can't be converted to Int64."
				)
			)
		}
		try writeInt64( value64 )
	}

	mutating func writeUInt( _ value:UInt ) throws {
		guard let value64 = UInt64( exactly: value ) else {
			throw BinaryIOError.initTypeError(
				Self.self, BinaryIOError.Context(
					debugDescription: "UInt \(value) can't be converted to UInt64."
				)
			)
		}
		try writeUInt64( value64 )
	}
}

