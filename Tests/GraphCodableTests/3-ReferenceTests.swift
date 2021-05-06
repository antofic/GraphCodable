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

import XCTest
@testable import GraphCodable

//	testInheritance types
fileprivate class SuperClass : GCodable {
	init() {}
	required init(from decoder: GDecoder) throws {}
	func encode(to encoder: GEncoder) throws {}
}

//	testInheritance classes
fileprivate class SubClass : SuperClass {
}

//	testConditionalEncoding types
class ConditionalList : GCodable {
	private (set) var next : ConditionalList?
	
	init( _ a: ConditionalList? = nil ) {
		self.next = a
	}

	private enum Key : String {
		case next
	}

	func encode(to encoder: GEncoder) throws {
		try encoder.encodeConditional( next, for: Key.next )
	}
	
	required init(from decoder: GDecoder) throws {
		next	= try decoder.decode( for: Key.next )
	}
}

//	testDontDuplicateReferences types
class Dummy : GCodable {
	init() {}
	required init(from decoder: GDecoder) throws {}
	func encode(to encoder: GEncoder) throws {}
}

// --------------------------------------------------------------------------------

final class ReferenceTests: XCTestCase {
	
	func testInheritance() throws {
		let inRoot	: SuperClass = SubClass()
		let data	= try GraphEncoder().encode( inRoot )
		let outRoot	= try GraphDecoder().decode( SuperClass.self, from:data )
		
		XCTAssert( outRoot is SubClass , #function )
	}
	
	func testConditionalEncoding1() throws {
		let a = ConditionalList()
		let b = ConditionalList( a )
		let c = ConditionalList( b )
		
		let inRoot	= [ "a": a, "b": b, "c" : c ]
		let data	= try GraphEncoder().encode( inRoot )
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
		
		XCTAssertNil( outRoot["a"]!.next, #function )
		XCTAssertNotNil( outRoot["b"]!.next, #function )
		XCTAssertNotNil( outRoot["c"]!.next, #function )
	}

	func testConditionalEncoding2() throws {
		let a = ConditionalList()
		let b = ConditionalList( a )
		let c = ConditionalList( b )
		
		let inRoot	= [ "b": b, "c": c ]
		let data	= try GraphEncoder().encode( inRoot )
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
		
		XCTAssertNil( outRoot["b"]!.next, #function )
		XCTAssertNotNil( outRoot["c"]!.next, #function )
	}

	func testConditionalEncoding3() throws {
		let a = ConditionalList()
		let b = ConditionalList( a )
		let c = ConditionalList( b )
		
		let inRoot	= [ "a": a, "c" : c ]
		let data	= try GraphEncoder().encode( inRoot )
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
		
		XCTAssertNil( outRoot["a"]!.next, #function )
		XCTAssertNil( outRoot["c"]!.next, #function )
	}
	
	func testReferenceDuplication() throws {
		let a = Dummy()
		
		let inRoot	= ["a": [a,a,a], "b" : [a,nil,a]]
		let data	= try GraphEncoder().encode( inRoot )
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )

		let out_a_0	= outRoot["a"]![0]!
		
		XCTAssertTrue( out_a_0 === outRoot["a"]![1]!, #function)
		XCTAssertTrue( out_a_0 === outRoot["a"]![2]!, #function)
		XCTAssertTrue( out_a_0 === outRoot["b"]![0]!, #function)
		XCTAssertTrue( out_a_0 === outRoot["b"]![2]!, #function)
	}
}
