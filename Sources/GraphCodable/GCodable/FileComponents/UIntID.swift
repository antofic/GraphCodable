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

//	IdnID's, KeyID's, RefID's can consume a non-negligible amount
//	of disk space. On the other hand they are generally small
//	unsigned integers and for this we use a simple algorithm
//	to compress them.
//	Note: this will make written BinSize data variable in size


protocol UIntID: Hashable, BCodable, CustomStringConvertible {
	associatedtype uID : FixedWidthInteger & UnsignedInteger & BCodable
	
	init( _ id:uID )
	var id : uID { get }
}

extension UIntID {
	init() {
		self.init( 1 )
	}

	func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( id )
	}
	
	init(from decoder: inout some BDecoder) throws {
		self.init( try decoder.decode() )
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
struct IdnID : UIntID {
	
	let id: UInt32
	init(_ id: UInt32) { self.id = id }
}

struct KeyID : UIntID {
	let id: UInt32
	init(_ id: UInt32) { self.id = id }
}

struct RefID : UIntID {
	let id: UInt32
	init(_ id: UInt32) { self.id = id }
}

struct BinSize: Equatable, BCodable {
	let size	: Int
	
	init(_ size: Int)	{ self.size = size }
	init() { size = -1 }

	func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( size )
	}
	
	init(from decoder: inout some BDecoder) throws {
		size = try decoder.decode()
	}
}
