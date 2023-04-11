//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import XCTest
@testable import GraphCodable

//	testDirectedAcyclicGraph types


// --------------------------------------------------------------------------------

final class DirectedAcyclicGraphTests: XCTestCase {
	class Node : Codable, GCodable, Equatable {
		let name : String
		var others = [Node]()
		
		init( _ name:String ) {
			self.name	= name
		}

		private enum Key : String {
			case name, others
		}

		required init(from decoder: some GDecoder) throws {
			name	= try decoder.decode( for: Key.name )
			others	= try decoder.decode( for: Key.others )
		}
		
		func encode(to encoder: some GEncoder) throws {
			try encoder.encode(name, 	for: Key.name )
			try encoder.encode(others,	for: Key.others )
		}
	}

	func testDAG() throws {
		//	A directed acyclic graph (DAG) from wikipedia
		//	https://en.wikipedia.org/wiki/Directed_acyclic_graph#/media/File:Tred-G.svg
		//	A DAG of strong references don't leaks memeory with ARC
		//	GCodable will decode it without duplicate objects
				
		let a = Node("a")
		let b = Node("b")
		let c = Node("c")
		let d = Node("d")
		let e = Node("e")
		
		///                 ╭───╮
		///	  ┌────────────▶︎│ c │─────┐
		///	  │             ╰───╯     │
		///   │               │       │
		///   │               ▼       ▼
		/// ╭───╮   ╭───╮   ╭───╮   ╭───╮
		///	│ a │──▶︎│ b │──▶︎│ d │──▶︎│ e │
		///	╰───╯   ╰───╯   ╰───╯   ╰───╯
		///  │ │              ▲       ▲
		///  │ │              │       │
		///  │ └──────────────┘       │
		///	 └────────────────────────┘

		//	The order here is irrelevant:
		a.others = [ b, c, d, e ]
		b.others = [ d ]
		c.others = [ d, e ]
		d.others = [ e ]	// Read the note (1)

		let inRoot	= a
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
		
		let outA	= outRoot
		
		//	Reconstruction test
		XCTAssertEqual( outA.others[0].name, "b" , #function)
		XCTAssertEqual( outA.others[1].name, "c" , #function)
		XCTAssertEqual( outA.others[2].name, "d" , #function)
		XCTAssertEqual( outA.others[3].name, "e" , #function)
		
		XCTAssertEqual( outA.others[0].others[0].name, "d" , #function)
		XCTAssertEqual( outA.others[1].others[0].name, "d" , #function)
		
		//	No duplicates test
		let d_from_a	= outA.others[2]
		let d_from_ab	= outA.others[0].others[0]
		let d_from_ac	= outA.others[1].others[0]
		
		XCTAssertTrue( d_from_a == d_from_ab, #function )
		XCTAssertTrue( d_from_a == d_from_ac, #function )

		///	Note (1):
		///	If we add:
		///		e.connect( to:b )
		/// the graph becomes cyclic.
		/// A directed cyclic graph of strong references leaks memory with ARC.
		///	(and also GCodable cannot decode it)
		/// Basically such graphs cannot exist in Swift without using weak
		/// variables.
		///	See "DirectedCyclicGraphTrest as esamples.
	}
	
	struct NodeStruct : GCodable, GIdentifiable, CustomStringConvertible {
		var id 		= UUID()
		
		var gcodableID: UUID? { id }
		
		//	Note: Equality '===' defined as 'same Identity'.
		//	It is the counterpart of the '===' equality
		//	between reference types based on their
		//	ObjectIdentifier
		static func === (lhs:Self, rhs:Self) -> Bool {
			return lhs.id == rhs.id
		}
		
		let name	: String
		var others	= [NodeStruct]() {
			willSet { id = UUID() }
		}
		
		init( _ name:String ) {
			self.name	= name
		}
		
		private enum Key : String {
			case name, others
		}
		
		func encode(to encoder: some GEncoder) throws {
			try encoder.encode( name, for: Key.name )
			try encoder.encode( others, for: Key.others )
		}
		
		init(from decoder: some GDecoder) throws {
			self.name	= try decoder.decode( for: Key.name )
			self.others	= try decoder.decode( for: Key.others )
		}
		
		var description: String {
			return "\(name) \( others.map { $0.name } )"
		}
	}

	func testDAGstruct() throws {
		//	This test uses values with identities
		var a = NodeStruct("a")
		var b = NodeStruct("b")
		var c = NodeStruct("c")
		var d = NodeStruct("d")
		let e = NodeStruct("e")

		///                 ╭───╮
		///	  ┌────────────▶︎│ c │─────┐
		///	  │             ╰───╯     │
		///   │               │       │
		///   │               ▼       ▼
		/// ╭───╮   ╭───╮   ╭───╮   ╭───╮
		///	│ a │──▶︎│ b │──▶︎│ d │──▶︎│ e │
		///	╰───╯   ╰───╯   ╰───╯   ╰───╯
		///  │ │              ▲       ▲
		///  │ │              │       │
		///  │ └──────────────┘       │
		///	 └────────────────────────┘

		// Note: The order with value types is important!
		d.others = [e, a]
		c.others = [d, e]
		b.others = [d]
		a.others = [b, c, d, e]

		let inRoot	= a
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
		
		let outA	= outRoot
		
		//	Reconstruction test
		XCTAssertEqual( outA.others[0].name, "b" , #function)
		XCTAssertEqual( outA.others[1].name, "c" , #function)
		XCTAssertEqual( outA.others[2].name, "d" , #function)
		XCTAssertEqual( outA.others[3].name, "e" , #function)
		
		XCTAssertEqual( outA.others[0].others[0].name, "d" , #function)
		XCTAssertEqual( outA.others[1].others[0].name, "d" , #function)

		//	Note: Equality defined as Identity.
		//	It is the counterpart of the identity between
		//	reference types based on ObjectIdentifier
		//	No duplicates test. Codable fails this test.
		let d_from_a	= outA.others[2]
		let d_from_ab	= outA.others[0].others[0]
		let d_from_ac	= outA.others[1].others[0]
		
		XCTAssertTrue( d_from_a === d_from_ab, #function )
		XCTAssertTrue( d_from_a === d_from_ac, #function )
	}
}

