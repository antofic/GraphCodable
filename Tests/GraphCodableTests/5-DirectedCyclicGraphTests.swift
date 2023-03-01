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

//	testDirectedCyclicGraph types

final class DirectedCyclicGraphTests: XCTestCase {
	struct Model : GCodable {
		//	Swift cant have an array of weak references, so we create a generic box
		//	to hold one:
		
		final class WeakBox<T> : GCodable where T:AnyObject, T:GCodable {
			private (set) weak var boxed : T?
			
			init( _ boxed:T ) {
				self.boxed	= boxed
			}
			
			func encode(to encoder: GEncoder) throws {
				//	weak variables must be encoded conditionally!!!
				try encoder.encodeConditional( boxed )
			}
			
			required init(from decoder: GDecoder) throws {
				//	and then we use the deferred decoding
				//	to avoid strong cycles
				try decoder.deferDecode { self.boxed = $0 }
			}
		}

		//	Now we create a node class that hold an array of boxed weak references:

		class Node : GCodable {
			private var boxes = [WeakBox<Node>]()
			let name : String

			func connect( to nodes: Node... ) {
				boxes.append( contentsOf: nodes.map { WeakBox( $0 ) } )
			}
			
			var connections : [Node] {
				return boxes.compactMap { $0.boxed }
			}
			
			init( _ name:String ) {
				self.name	= name
			}
			
			private enum Key : String {
				case name, boxes
			}
			
			required init(from decoder: GDecoder) throws {
				name	= try decoder.decode( for: Key.name  )
				boxes	= try decoder.decode( for: Key.boxes )
			}
			
			func encode(to encoder: GEncoder) throws {
				try encoder.encode(name,  for: Key.name  )
				try encoder.encode(boxes, for: Key.boxes )
			}
		}

	//	However, it is necessary to keep the nodes alive through
	//	strong references. The Model struct serves precisely for this:
	//	we hold all nodes in a dictionary

		private (set) var nodes = [String:Node]()
		
		init() {}
		
		private enum Key : String {
			case nodes
		}

		init(from decoder: GDecoder) throws {
			nodes	= try decoder.decode( for: Key.nodes )
		}
		
		func encode(to encoder: GEncoder) throws {
			try encoder.encode(nodes, for: Key.nodes )
		}
		
		mutating func newNode( _ name: String ) -> Node {
			if let node = nodes[name] {
				return node
			} else {
				let node = Node( name )
				nodes[name]	= node
				return node
			}
		}
		
		subscript( _ name: String ) -> Node? {
			return nodes[name]
		}
	}

	
	func testDGC() throws {
		var model	= Model()
		
		let a 		= model.newNode("a")
		let b 		= model.newNode("b")
		let c 		= model.newNode("c")
		let d 		= model.newNode("d")
		let e 		= model.newNode("e")
		
		//	We take a directed acyclic graph (DAG) from wikipedia
		//	https://en.wikipedia.org/wiki/Directed_acyclic_graph#/media/File:Tred-G.svg
		a.connect( to: b, c, d, e )
		b.connect( to: d )
		c.connect( to: d, e )
		d.connect( to: e )
		//	and now make it cyclic:
		e.connect( to: a,b,c,d,e )
		
		let inRoot	= model
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )

		let outA	= outRoot.nodes[a.name]!
				
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

		//	Cycle Test
		XCTAssertEqual( outA.connections[3].connections[0].name, "a" , #function)

		let a_from_ea	= outA.connections[3].connections[0]
		XCTAssertTrue( outA === a_from_ea, #function )
	}
}

