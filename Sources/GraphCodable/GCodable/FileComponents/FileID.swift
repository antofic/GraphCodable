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

protocol FileID: Hashable, BinaryIOType {
	init( _ id:UIntID )
	var id : UIntID { get }
}

extension FileID {
	init() {
		self.init( 1 )
	}

	init( from rbuffer:inout BinaryReadBuffer ) throws {
		self.init( try UIntID(unpackFrom: &rbuffer) )
	}

	func write( to wbuffer:inout BinaryWriteBuffer ) throws {
		try id.write(packTo: &wbuffer)
	}

	var next : Self {
		return Self( id + 1 )
	}
}

struct ObjID : FileID {
	let id: UIntID
	init(_ id: UIntID) { self.id = id }
}

struct KeyID : FileID {
	let id: UIntID
	init(_ id: UIntID) { self.id = id }
}

struct TypeID : FileID {
	let id: UIntID
	init(_ id: UIntID) { self.id = id }
}

struct BinSize: Equatable {
	private let _usize: UInt
	
	init() { _usize = UInt(bitPattern: -1) }
	
	init(_ size: Int)	{ self._usize = UInt(size) }
	var size: Int		{ Int(_usize) }
	
	init(from rbuffer: inout BinaryReadBuffer, unpack:Bool ) throws {
		if unpack	{ _usize = try UInt( unpackFrom: &rbuffer ) }
		else		{ _usize = try UInt( from: &rbuffer ) }
	}
	
	///	pack will make writed data variable in size
	func write(to wbuffer: inout BinaryWriteBuffer, pack:Bool ) throws {
		if pack 	{ try _usize.write( packTo: &wbuffer) }
		else		{ try _usize.write( to: &wbuffer) }
	}
}

