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

//	ObjID's, KeyID's, TypeID's can consume a non-negligible amount
//	of disk space. On the other hand they are generally small
//	unsigned integers and for this we use a simple algorithm
//	to compress them.
//	Note: this will make written BinSize data variable in size


protocol UIntID: Hashable, BCodable, CustomStringConvertible {
	associatedtype uID : UnsignedInteger
	
	init( _ id:uID )
	var id : uID { get }
}

extension UIntID {
	init() {
		self.init( 1 )
	}

	func encode(to encoder: inout some BEncoder) throws {
		try id.compress(to: &encoder)
	}
	
	init(from decoder: inout some BDecoder) throws {
		self.init( try uID.decompress(from: &decoder) )
	}
	
	var next : Self {
		return Self( id + 1 )
	}
	
	var description: String {
		return "\(id)".align(.right, length: 4, filler: "0")
	}
}

//	We use three distinct structures so as not to run
//	the risk of confusing them.
struct ObjID : UIntID {
	
	let id: UInt32
	init(_ id: UInt32) { self.id = id }
}

struct KeyID : UIntID {
	let id: UInt32
	init(_ id: UInt32) { self.id = id }
}

struct TypeID : UIntID {
	let id: UInt32
	init(_ id: UInt32) { self.id = id }
}


//	We also make BinSize (the size of the GBinaryCodable)
//	compressible as desired. The benefits are minor.
struct BinSize: Equatable, BCodable {
	private let _usize: UInt
	
	private init( _ usize: UInt ) {
		_usize = usize
	}
	
	init() { _usize = UInt(bitPattern: -1) }
	
	init(_ size: Int)	{ self._usize = UInt(size) }
	var size: Int		{ Int(_usize) }
	
	func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( _usize )
	}
	
	init(from decoder: inout some BDecoder) throws {
		try _usize	= decoder.decode()
	}

	static func decompress( from decoder: inout some BDecoder ) throws -> Self {
		return self.init( try UInt.decompress(from: &decoder) )
	}
	
	func compress(to encoder: inout some BEncoder ) throws {
		try _usize.compress(to: &encoder)
	}

	/*
	init(from decoder: inout some BDecoder, decompress:Bool ) throws {
		if decompress	{ _usize = try UInt.decompress( from: &decoder ) }
		else			{ _usize = try UInt( from: &decoder ) }
	}
	
	//	compress will make writed BinSize data variable in size
	func write(to encoder: inout some BEncoder, compress:Bool ) throws {
		if compress 	{ try _usize.compress( to: &encoder) }
		else			{ try encoder.encode( _usize ) }
	}
	*/
}

