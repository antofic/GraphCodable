//
//  File.swift
//
//
//  Created by Antonino Ficarra on 04/02/23.
//

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
			
			required init(from decoder: GDecoder) throws {
				name		= try decoder.decode( for: Key.name )
				//	decode fails if the graph is cyclic:
				//		connections	= try decoder.decode( for: Key.connections )
				//	you have to use deferDecode:
				try decoder.deferDecode( for: Key.connections ) { self.connections = $0 }
			}
			
			func encode(to encoder: GEncoder) throws {
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

		required init(from decoder: GDecoder) throws {
			nodes	= try decoder.decode( for: Key.nodes )
			//	deferDecode can be used here, but is not required
			//	try decoder.deferDecode( for: Key.nodes ) { self.nodes = $0 }
		}
		
		func encode(to encoder: GEncoder) throws {
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
