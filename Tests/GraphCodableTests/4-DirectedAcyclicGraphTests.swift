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

//	testDirectedAcyclicGraph types


// --------------------------------------------------------------------------------

final class DirectedAcyclicGraphTests: XCTestCase {
	class Node : Codable, GCodable {
		private (set) var connections = [Node]()
		let name : String

		func connect( to nodes: Node... ) {
			connections.append( contentsOf: nodes)
		}
		
		init( _ name:String ) {
			self.name	= name
		}

		private enum Key : String {
			case name, connections
		}

		required init(from decoder: GDecoder) throws {
			name		= try decoder.decode( for: Key.name )
			connections	= try decoder.decode( for: Key.connections )
		}
		
		func encode(to encoder: GEncoder) throws {
			try encoder.encode(name, 		for: Key.name )
			try encoder.encode(connections, for: Key.connections )
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

		a.connect( to: b, c, d, e )
		b.connect( to: d )
		c.connect( to: d, e )
		d.connect( to: e )	// Read the note (1)
		
		let inRoot	= a
		let data	= try GraphEncoder().encode( inRoot )
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
		
		let outA	= outRoot
		
		//	Reconstruction test
		XCTAssertEqual( outA.connections[0].name, "b" , #function)
		XCTAssertEqual( outA.connections[1].name, "c" , #function)
		XCTAssertEqual( outA.connections[2].name, "d" , #function)
		XCTAssertEqual( outA.connections[3].name, "e" , #function)
		
		XCTAssertEqual( outA.connections[0].connections[0].name, "d" , #function)
		XCTAssertEqual( outA.connections[1].connections[0].name, "d" , #function)
		
		//	No duplicates test
		let d_from_a	= outA.connections[2]
		let d_from_ab	= outA.connections[0].connections[0]
		let d_from_ac	= outA.connections[1].connections[0]
		
		XCTAssertTrue( d_from_a === d_from_ab, #function )
		XCTAssertTrue( d_from_a === d_from_ac, #function )

		///	Note (1):
		///	If we add:
		///		e.connect( to:b )
		/// the graph becomes cyclic.
		/// A directed cyclic graph of strong references leaks memory with ARC.
		///	(and also GCodable cannot decode it)
		/// Basically such graphs cannot exist in Swift without using weak
		/// variables.
		///	The next test will show an example
	}
	
}
