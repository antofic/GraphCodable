//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

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
	
	func encode(to encoder: some GEncoder) throws {
		// we use userinfo to change some names during encode
		let newName = encoder.userInfo[name] as? String ?? name
		try encoder.encode( newName, for: Key.name )
	}
	
	init(from decoder: some GDecoder) throws {
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
		let data	= try encoder.encode( inRoot ) as Bytes

		let decoder = GraphDecoder()
		let outRoot	= try decoder.decode( type(of:inRoot), from: data )
		
		XCTAssertEqual( outRoot.description, "[Paperino, Pluto]", #function )
	}
	
	func testDecodeUserInfo() throws {
		let pippo	= Name(name: "Pippo")
		let pluto	= Name(name: "Pluto")
		
		let inRoot	= [pippo, pluto]
		
		let encoder = GraphEncoder()
		let data	= try encoder.encode( inRoot ) as Bytes
		
		let decoder = GraphDecoder()
		// change Pluto to Topolino during decode
		decoder.userInfo	= ["Pluto":"Topolino"]
		let outRoot	= try decoder.decode( type(of:inRoot), from: data )
		
		XCTAssertEqual( outRoot.description, "[Pippo, Topolino]", #function )
	}
	
}

