//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import XCTest
@testable import GraphCodable

//	testStruct classes
fileprivate struct Body : Equatable, GCodable {
	var height	: Double
	var weight	: Double
	
	init(height: Double, weight: Double) {
		self.height	= height
		self.weight	= weight
	}
	
	private enum Key : String {
		case height, weight
	}

	func encode(to encoder: some GEncoder) throws {
		try encoder.encode( height, for: Key.height )
		try encoder.encode( weight, for: Key.weight )
	}
	
	init(from decoder: some GDecoder) throws {
		height	= try decoder.decode( for: Key.height  )
		weight	= try decoder.decode( for: Key.weight  )
	}
}

fileprivate struct Person : Equatable, GCodable {
	var name	: String
	var body	: Body
	
	init( name: String, body: Body ) {
		self.name	= name
		self.body	= body
	}
	
	private enum Key : String {
		case name, body
	}

	func encode(to encoder: some GEncoder) throws {
		try encoder.encode( name, for: Key.name )
		try encoder.encode( body, for: Key.body )
	}
	
	init(from decoder: some GDecoder) throws {
		name	= try decoder.decode( for: Key.name )
		body	= try decoder.decode( for: Key.body )
	}
}

//	testEnum types

fileprivate enum DisneyString : String, GCodable {
	case pippo, pluto, paperino
}

fileprivate enum DisneyInt : Int, GCodable {
	case pippo, pluto, paperino
}

//	testIndirectLinkedListEnum (a generic enum with payload)

//	A linkedlist using enum:
fileprivate enum List<Element> {
	case end
	indirect case node(Element, List<Element>)
	
	func cons(_ x: Element) -> List<Element> {
		return .node(x, self)
	}
}

extension List: ExpressibleByArrayLiteral {
	init( arrayLiteral elements: Element... ) {
		self = elements.reversed().reduce( List.end ) {
			$0.cons( $1 )
		}
	}
}

extension List: Sequence {
	func makeIterator() -> AnyIterator<Element> {
		var current: List<Element> = self
		return AnyIterator {
			switch current {
			case .end: return nil
			case let .node(x, next):
				current = next
				return x
			}
		}
	}
}

extension List: Equatable where Element:Equatable {}

//	We make our list GCodable: unkeyed encoding
//	works great in this case.
extension List: GCodable where Element:GCodable {
	func encode(to encoder: some GEncoder) throws {
		switch self {
		case .end:
			break;
		case .node( let value, let list ):
			try encoder.encode( value )
			try encoder.encode( list )
		}
	}
	
	init(from decoder: some GDecoder) throws {
		if decoder.unkeyedCount == 0 {
			self		= .end
		} else {
			let value	= try decoder.decode() as Element
			let list	= try decoder.decode() as List<Element>
			self		= .node( value, list )
		}
	}
}

//	testOptionSet
//	we make 'DumpOptions' (defined in 'GraphEncoder.swift') gcodable!
extension GraphDumpOptions : GCodable {}

// --------------------------------------------------------------------------------


final class StructEnumOptionTests: XCTestCase {

	func testStruct() throws {
		let inRoot	= Person(name: "Pippo", body: Body(height: 1.80, weight: 80.0))
		
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
		
		XCTAssertEqual( inRoot, outRoot, #function )
	}
	
	func testKeyedArchiving() throws {
		struct Test : Equatable, GCodable {
			var name	= "Pluto"
			var height	= 1.82
			var nephews	= ["Qui","Quo","Qua"]
			var uncles	= ["Paperone"]

			init() {}
			
			private enum Key : String {
				case name, height, nephews, uncles
			}
			
			func encode(to encoder: some GEncoder) throws {
				try encoder.encode( name, 	for: Key.name	 )
				try encoder.encode( height, for: Key.height	 )
				try encoder.encode( nephews,for: Key.nephews )
				try encoder.encode( uncles, for: Key.uncles	 )
			}
			
			init(from decoder: some GDecoder) throws {
				//	they can be decoded in any order
				uncles	= try decoder.decode( for: Key.uncles  )
				name	= try decoder.decode( for: Key.name    )
				nephews	= try decoder.decode( for: Key.nephews )
				height	= try decoder.decode( for: Key.height  )
			}
		}
		let inRoot	= Test()
		
		let data = try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
		
		XCTAssertEqual( inRoot, outRoot, #function )
	}

	func testUnkeyedArchiving() throws {
		struct Test : Equatable, GCodable {
			var name	= "Pluto"
			var height	= 1.82
			var nephews	= ["Qui","Quo","Qua"]
			var uncles	= ["Paperone"]
			
			init() {}
			
			func encode(to encoder: some GEncoder) throws {
				try encoder.encode( name )
				try encoder.encode( height )
				try encoder.encode( nephews )
				try encoder.encode( uncles )
			}
			
			init(from decoder: some GDecoder) throws {
				//	they must be decoded in the same
				//	order in which they were encoded
				name	= try decoder.decode()
				height	= try decoder.decode()
				nephews	= try decoder.decode()
				uncles	= try decoder.decode()
			}
		}
		let inRoot	= Test()
		
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
		
		XCTAssertEqual( inRoot, outRoot, #function )
	}

	func testMixedArchiving() throws {
		struct Test : Equatable, GCodable {
			var name	= "Pluto"
			var height	= 1.82
			var nephews	= ["Qui","Quo","Qua"]
			var uncles	= ["Paperone"]
			
			init() {}
			
			private enum Key : String {
				case name, height
			}

			func encode(to encoder: some GEncoder) throws {
				try encoder.encode( name, for: Key.name )
				try encoder.encode( nephews )
				try encoder.encode( height, for: Key.height )
				try encoder.encode( uncles )
			}
			
			init(from decoder: some GDecoder) throws {
				//	unkeyed variables must be decoded in the same
				//	order in which they were encoded, regardless
				//	of the keyed variables
				nephews	= try decoder.decode()
				height	= try decoder.decode( for: Key.height )
				name	= try decoder.decode( for: Key.name )
				uncles	= try decoder.decode()
			}
		}
		let inRoot	= Test()
		
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
		
		XCTAssertEqual( inRoot, outRoot, #function )
	}
	
	func testStringEnum() throws {
		let inRoot	= DisneyString.paperino
		
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
		
		XCTAssertEqual( inRoot, outRoot, #function )
	}

	func testIntEnum() throws {
		let inRoot	= DisneyInt.paperino
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
		
		XCTAssertEqual( inRoot, outRoot, #function )
	}
	
	func testIndirectLinkedListEnum() throws {
		let inRoot	= List(arrayLiteral: "a","b","c")
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
		
		XCTAssertEqual( inRoot, outRoot, #function )
	}
	
	func testOptionSet() throws {
		let inRoot	= GraphDumpOptions.fullInfo
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )

		XCTAssertEqual( inRoot, outRoot, #function )
	}
}

