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

