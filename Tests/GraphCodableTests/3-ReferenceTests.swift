//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import XCTest
@testable import GraphCodable


// --------------------------------------------------------------------------------

final class ReferenceTests: XCTestCase {
	//	testInheritance types
	class SuperClass : GCodable {
		init() {}
		required init(from decoder: some GDecoder) throws {}
		func encode(to encoder: some GEncoder) throws {}
	}

	//	testInheritance classes
	class SubClass : SuperClass {
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

		func encode(to encoder: some GEncoder) throws {
			try encoder.encodeConditional( next, for: Key.next )
		}
		
		required init(from decoder: some GDecoder) throws {
			next	= try decoder.decode( for: Key.next )
		}
	}

	//	testDontDuplicateReferences types
	class Dummy : GCodable {
		init() {}
		required init(from decoder: some GDecoder) throws {}
		func encode(to encoder: some GEncoder) throws {}
	}

	
	
	
	func testInheritance() throws {
		let inRoot	: SuperClass = SubClass()
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( SuperClass.self, from:data )
		
		XCTAssert( outRoot is SubClass , #function )
	}
	
	func testConditionalEncoding1() throws {
		let a = ConditionalList()
		let b = ConditionalList( a )
		let c = ConditionalList( b )
		
		let inRoot	= [ "a": a, "b": b, "c" : c ]
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
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
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
		
		XCTAssertNil( outRoot["b"]!.next, #function )
		XCTAssertNotNil( outRoot["c"]!.next, #function )
	}

	func testConditionalEncoding3() throws {
		let a = ConditionalList()
		let b = ConditionalList( a )
		let c = ConditionalList( b )
		
		let inRoot	= [ "a": a, "c" : c ]
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
		
		XCTAssertNil( outRoot["a"]!.next, #function )
		XCTAssertNil( outRoot["c"]!.next, #function )
	}
	
	func testReferenceDuplication() throws {
		let a = Dummy()
		
		let inRoot	= ["a": [a,a,a], "b" : [a,nil,a]]
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )

		let out_a_0	= outRoot["a"]![0]!
		
		XCTAssertTrue( out_a_0 === outRoot["a"]![1]!, #function)
		XCTAssertTrue( out_a_0 === outRoot["a"]![2]!, #function)
		XCTAssertTrue( out_a_0 === outRoot["b"]![0]!, #function)
		XCTAssertTrue( out_a_0 === outRoot["b"]![2]!, #function)
	}
}

