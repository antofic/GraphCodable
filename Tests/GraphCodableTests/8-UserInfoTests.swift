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


struct Name : GCodable, CustomStringConvertible {
	let name : String
	
	init( name:String ) {
		self.name	= name
	}
	
	var description: String {
		return name
	}
	
	enum Key : String {
		case name
	}
	
	/*
	As an example, we use the 'userInfo' dictionary to have the
	possibility to change the 'name' value during the encoding
	and the decoding phase
	*/
	
	func encode(to encoder: GEncoder) throws {
		// we use userinfo to change some names during encode
		let newName = encoder.userInfo[name] as? String ?? name
		try encoder.encode( newName, for: Key.name )
	}
	
	init(from decoder: GDecoder) throws {
		let name : String = try decoder.decode( for: Key.name )
		// we use userinfo to change some names during decode
		self.name = decoder.userInfo[name] as? String ?? name
	}
}


final class UserInfoTests: XCTestCase {

	func testEncodeUserInfo() throws {
		let pippo	= Name(name: "Pippo")
		let pluto	= Name(name: "Pluto")
		
		let inRoot	= [pippo, pluto]
		
		let encoder = GraphEncoder()
		// change Pippo to Paperino during encode
		encoder.userInfo	= ["Pippo":"Paperino"]
		let data	= try encoder.encode( inRoot )

		let decoder = GraphDecoder()
		let outRoot	= try decoder.decode( type(of:inRoot), from: data )
		
		XCTAssertEqual( outRoot.description, "[Paperino, Pluto]", #function )
	}
	
	func testDecodeUserInfo() throws {
		let pippo	= Name(name: "Pippo")
		let pluto	= Name(name: "Pluto")
		
		let inRoot	= [pippo, pluto]
		
		let encoder = GraphEncoder()
		let data	= try encoder.encode( inRoot )
		
		let decoder = GraphDecoder()
		// change Pluto to Topolino during decode
		decoder.userInfo	= ["Pluto":"Topolino"]
		let outRoot	= try decoder.decode( type(of:inRoot), from: data )
		
		XCTAssertEqual( outRoot.description, "[Pippo, Topolino]", #function )
	}
	
}

