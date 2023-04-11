//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import XCTest
import simd
@testable import GraphCodable


final class NativeTests: XCTestCase {
	
	func testString() throws {
		let inRoot	= "Pippo"
		
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
		
		XCTAssertEqual( inRoot, outRoot, #function )
	}

	func testBool() throws {
		let inRoot	= true
		
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
		
		XCTAssertEqual( inRoot, outRoot, #function )
	}

	func testOptional() throws {
		let inRoot	: Double??? = 3
		
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
		
		XCTAssertEqual( inRoot, outRoot, #function )
	}

	func testIntArray() throws {
		let inRoot	= [1,2,3]
		
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
		
		XCTAssertEqual( inRoot, outRoot, #function )
	}

	func testStringArray() throws {
		let inRoot	= [["Io","Stringa molto molto molto lunga","Ma davvero"]:4, ["forse"]:17]
		
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
		
		XCTAssertEqual( inRoot, outRoot, #function )
	}

	
	func testComplexArray() throws {
		let inRoot	= [[1,2,3,nil,5],nil,[nil]]
		
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
		
		XCTAssertEqual( inRoot, outRoot, #function )
	}

	func testComplexArrayDictSet() throws {
		let inRoot	= Set( arrayLiteral: [ [1 : "Pi❤️po"], [2 : "Pluto"] , [3 : nil] ], [ [4 : "B❌u"], [5 : nil] ] )
		
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
		
		XCTAssertEqual( inRoot, outRoot, #function )
	}

	func testSet() throws {
		let inRoot : Set<Int?> = [1,2,nil,3,4,5]

		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
		
		XCTAssertEqual( inRoot, outRoot, #function )
	}

	func testSet2() throws {
		let inRoot : Set<String?> = ["1","2",nil,"3","4","😀"]
		
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
		
		XCTAssertEqual( inRoot, outRoot, #function )
	}
	
	func testData() throws {
		let a		= "Pippo".data(using: .utf8)
		let b		= "Paperino".data(using: .utf8)

		let inRoot	= [a, b, a, nil]
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )

		XCTAssertEqual( inRoot, outRoot, #function )
	}

	func testSIMDVector() throws {
		let a = SIMD8(repeating: 2.0)
		let b = SIMD8(repeating: 4.0)
		let inRoot	= [a, b, nil]
	
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )

		XCTAssertEqual( inRoot, outRoot, #function )
	}
	
	func testSIMDMatrix() throws {
		var a = simd_float4x2()
		a[3,0] = 1.0
		a[2,1] = 3.0

		let inRoot	= a // [[a, a, nil],[a, a]]
	
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )

		XCTAssertEqual( inRoot, outRoot, #function )
	}
	
}

