//	MIT License
//
//	Copyright (c) 2021-2023 Antonino Ficarra
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

final class DirectedCyclicGraphTestsB: XCTestCase {
	class Model : GCodable, Equatable, CustomStringConvertible {
		class Node : GCodable, Equatable, CustomStringConvertible {
			static func == (lhs: Node, rhs: Node) -> Bool {
				return lhs.name == rhs.name && lhs.connections.map { $0.name } == rhs.connections.map { $0.name }
			}
			
			private var connections = [Node]()
			let name : String

			func connect( to nodes: Node... ) {
				connections.append(contentsOf: nodes)
			}
			
			init( _ name:String ) {
				self.name	= name
			}
			
			private enum Key : String {
				case name, connections
			}
			
			required init(from decoder: some GDecoder) throws {
				name		= try decoder.decode( for: Key.name )
				//	decode fails if the graph is cyclic:
				//		connections	= try decoder.decode( for: Key.connections )
				//	you have to use deferDecode:
				try decoder.deferDecode( for: Key.connections ) { self.connections = $0 }
			}
			
			func encode(to encoder: some GEncoder) throws {
				try encoder.encode( name,  for: Key.name  )
				try encoder.encode( connections, for: Key.connections )
			}
			
			func removeConnections() {
				connections.removeAll()
			}

			var description: String {
				return "\( Self.self ) \"\(name)\" -> \( connections.map { $0.name } )"
			}
		}

		private (set) var nodes = [String:Node]()
		
		init() {}

		static func == (lhs: Model, rhs: Model) -> Bool {
			return lhs.nodes == rhs.nodes
		}

		private enum Key : String {
			case nodes
		}

		required init(from decoder: some GDecoder) throws {
			nodes	= try decoder.decode( for: Key.nodes )
			//	deferDecode can be used here, but is not required
			//	try decoder.deferDecode( for: Key.nodes ) { self.nodes = $0 }
		}
		
		func encode(to encoder: some GEncoder) throws {
			try encoder.encode(nodes, for: Key.nodes )
		}
		
		func newNode( _ name: String ) -> Node {
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
				
		deinit {
			// avoid strong memory cycles
			nodes.forEach { $0.value.removeConnections() }
		}
		
		var description: String {
			return nodes.values.reduce(into: "\(Self.self):" ) { $0.append( "\n\t• \($1.description )" ) }
		}
	}
	
	func testDGC() throws {
		let inModel	= Model()
		
		let a 		= inModel.newNode("a")
		let b 		= inModel.newNode("b")
		let c 		= inModel.newNode("c")
		let d 		= inModel.newNode("d")
		let e 		= inModel.newNode("e")
		
		//	A cyclic graph
		a.connect( to: b,c,d,e )
		b.connect( to: d,a,c,b,b,b )
		c.connect( to: d,e,a,c,b,b,b,c,e )
		d.connect( to: e,d,e,a,c,b )
		e.connect( to: a,b,c,d,e,e )
		
		let data		= try GraphEncoder().encode( inModel ) as Bytes
		let outModel	= try GraphDecoder().decode( type(of:inModel), from:data )
		
		XCTAssertTrue( inModel == outModel, #function )
		print( "decoded \(outModel)" )
	}
}
