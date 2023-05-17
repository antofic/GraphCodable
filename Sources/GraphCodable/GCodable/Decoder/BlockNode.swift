//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

typealias ReadNode		= BlockNode<ReadBlock>
typealias ReadNodeMap 	= [IdnID : ReadNode]

/// Decoding Pass 2
///
final class BlockNode<Block:FileBlockProtocol> {
	private(set)	var block			: Block
	private			var	keyedValues		= [KeyID:BlockNode]()
	private			var unkeyedValues 	= [BlockNode]()
	
	private init( block:Block ) {
		self.block	= block
	}
	
	///	Reorder ReadBlock's in a `root = BlockNode` and a `[IdnID : BlockNode<Block>]`
	///	dictionary to allow decoding of every acyclic graphs without requiring deferDecode
	static func flatGraph<S>( blocks:S ) throws
	-> ( rootNode: BlockNode, nodeMap: [IdnID : BlockNode<Block>] )
	where S:Sequence, S.Element == Block {
		var iterator	= blocks.makeIterator()
		
		guard let block = iterator.next() else {
			throw Errors.GraphCodable.malformedArchive(
				Self.self, Errors.Context(
					debugDescription: "Root not found."
				)
			)
		}
		
		if case FileBlock.End = block.fileBlock {
			throw Errors.GraphCodable.malformedArchive(
				Self.self, Errors.Context(
					debugDescription: "The archive begins with an end block."
				)
			)
		}
		
		let root 		= Self.init(block: block)
		var nodeMap		= [IdnID : BlockNode<Block>]()

		try Self.buildFlatGraph( root, nodeMap: &nodeMap, blockIterator: &iterator )
		
		return (root,nodeMap)
	}
	
	var unkeyedCount : Int {
		unkeyedValues.count
	}
	
	func contains( keyID:KeyID ) -> Bool {
		keyedValues.index(forKey: keyID) != nil
	}
	
	func pop( keyID:KeyID ) -> BlockNode? {
		keyedValues.removeValue(forKey: keyID)
	}
	
	func pop() -> BlockNode? {
		unkeyedCount > 0 ? unkeyedValues.removeLast() : nil
	}
}

extension BlockNode : CustomStringConvertible {
	var description: String {
		description(
			options: .readable, encodedClassMap: nil, keyStringMap: nil
		)
	}
	
	func description(
		options:			GraphDumpOptions,
		encodedClassMap:	EncodedClassMap?,
		keyStringMap: 		KeyStringMap?
	) -> String {
		block.fileBlock.description(
			options: 			options,
			encodedClassMap:	encodedClassMap,
			keyStringMap:		keyStringMap
		)
	}
	
}

// MARK: BlockNode private flatten section
extension BlockNode {
	@discardableResult
	private static func replaceValueWithPtr(
		_ node:BlockNode, nodeMap map: [IdnID : BlockNode<Block>],
		keyID:KeyID?, idnID:IdnID
	) throws -> BlockNode {
		//	l'oggetto non può già trovarsi nella map
		guard map.index(forKey: idnID) == nil else {
			throw Errors.GraphCodable.internalInconsistency(
				Self.self, Errors.Context(
					debugDescription: "Object |\(node.block.fileBlock)| already exists."
				)
			)
		}
		// creo un nuovo nodo con il readBlock
		let root 	= BlockNode( block: node.block )
		// al posto del vecchio nodo metto un puntatore al vecchio nodo
		node.block	= Block(pointerTo: node.block, conditional: false)!
		
		return root
	}
	
	private static func buildFlatGraph<T>(
		_ node:BlockNode, nodeMap map: inout [IdnID : BlockNode<Block>], blockIterator: inout T
	) throws where T:IteratorProtocol, T.Element == Block {
		switch node.block.fileBlock {
			case .Val( let keyID, let idnID, _ ):
				if let idnID {
					let root = try replaceValueWithPtr( node, nodeMap: map, keyID:keyID, idnID:idnID )
					try buildSubGraph( root, nodeMap: &map, blockIterator:&blockIterator )
					map[ idnID ]	= root
				} else {
					try buildSubGraph( node, nodeMap: &map, blockIterator:&blockIterator )
				}
			case .Bin( let keyID, let idnID, _, _ ):
				if let idnID {
					let root = try replaceValueWithPtr( node, nodeMap: map, keyID:keyID, idnID:idnID )
					map[ idnID ]	= root
				}	// ATT! NO subFlatten for BinValue's
			default: //	nothing to do
				break
		}
	}
	
	private static func buildSubGraph<T>(
		_ node:BlockNode, nodeMap map: inout [IdnID : BlockNode<Block>], blockIterator: inout T
	) throws where T:IteratorProtocol, T.Element == Block {
		
		while let block = blockIterator.next() {
			let field = BlockNode( block: block )

			if case .End = block.fileBlock {
				break
			} else {
				//	field.parentNode = node
				try buildFlatGraph( field, nodeMap: &map, blockIterator: &blockIterator )

				if let keyID = block.fileBlock.keyID {
					guard node.keyedValues.index(forKey: keyID) == nil else {
						throw Errors.GraphCodable.malformedArchive(
							Self.self, Errors.Context(
								debugDescription: "KeyID |\(keyID)| already in use."
							)
						)
					}
					node.keyedValues[ keyID ] = field
				} else {
					node.unkeyedValues.append( field )
				}
				
			}
		}
		node.unkeyedValues.reverse()
	}
}

// MARK: BlockNode cycle discovering

extension BlockNode : Identifiable {
	private struct ColorMap {
		enum Color { case white, gray, black }
		
		private var colorMap = [BlockNode.ID:Color]()
		
		subscript( node:BlockNode ) -> Color {
			get { colorMap[node.id] ?? .white }
			set { colorMap[node.id] = newValue }
		}
	}
	
	func isCyclic( nodeMap:[IdnID : BlockNode<Block>] ) -> Bool {
		var colorMap = ColorMap()
		if let node = self.pointedValue(nodeMap: nodeMap) {
			return node.isCyclic(nodeMap: nodeMap, colorMap: &colorMap)
		} else {
			return false
		}
	}
	
	private func withEachField( isCyclic: ( _ :BlockNode )->Bool ) -> Bool {
		for field in keyedValues.values {
			if isCyclic( field ) {
				return true
			}
		}
		for field in unkeyedValues {
			if isCyclic( field ) {
				return true
			}
		}
		return false
	}
	
	private func isCyclic( nodeMap:[IdnID : BlockNode<Block>], colorMap:inout ColorMap ) -> Bool {
		colorMap[ self ] = .gray
		
		let isCyclic = withEachField { field in
			if let pointedField = field.pointedValue( nodeMap:nodeMap ) {
				switch colorMap[ pointedField ] {
					case .white:
						if pointedField.isCyclic(nodeMap: nodeMap, colorMap: &colorMap) {
							return true
						}
					case .gray:
						return true
					case .black:
						break
				}
			}
			return false
		}
		
		if isCyclic {
			return true
		} else {
			colorMap[ self ] = .black
			return false
		}		
	}
		 
	private func pointedValue( nodeMap:[IdnID : BlockNode<Block>] ) -> BlockNode? {
		switch block.fileBlock {
			case .Ptr( _, let idnID , _ ):
				return nodeMap[ idnID ]
			case .Val( _,_,_ ):
				return self
			case .Bin( _,_,_,_ ):
				return self
			default:
				return nil
		}
	}
}

// MARK: BlockNode dump section
extension BlockNode {
	func dump(
		nodeMap: [IdnID : BlockNode<Block>], encodedClassMap: EncodedClassMap?, keyStringMap: KeyStringMap?,
		options: GraphDumpOptions
	) -> String {
		var tabs	= Tabs(tabString: options.contains( .dontIndentBody ) ? Tabs.noTabs : Tabs.defaultTabs )
		var dump 	= ""
		dump.append( EncodeDump.titleString( "FLAT BODY" ) )
		dump.append( EncodeDump.titleString( "ROOT:", filler: "-") )
		dump.append( subdump(nodeMap: nodeMap, encodedClassMap: encodedClassMap, keyStringMap: keyStringMap, options:options, tabs: &tabs, first: false ))
		
		if nodeMap.isEmpty == false {
			dump.append( EncodeDump.titleString( "WHERE:", filler: "-") )
			for (id,node) in nodeMap.sorted( by: { $0.key < $1.key } ) {
				dump.append( "- PTR\(id) is")
				dump.append( node.subdump( nodeMap: nodeMap, encodedClassMap: encodedClassMap, keyStringMap: keyStringMap, options:options, tabs: &tabs, first: true ))
			}
		}
		
		return dump
	}

	private func subdump(
		nodeMap: [IdnID : BlockNode<Block>], encodedClassMap: EncodedClassMap?, keyStringMap: KeyStringMap?,
		options: GraphDumpOptions, tabs: inout Tabs, first: Bool
	) -> String {
		var dump 	= ""
		if first {
			let string	= block.fileBlock.description( options: [options, .hideKeyString], encodedClassMap: encodedClassMap, keyStringMap: keyStringMap )
			dump.append( " \(string)\n" )
		} else {
			let string	= block.fileBlock.description( options: options, encodedClassMap: encodedClassMap, keyStringMap: keyStringMap )
			dump.append( "\(tabs)\(string)\n" )
		}
		
		tabs.enter()
		var end	= false
		for node in keyedValues.values {
			end	= true
			dump.append(
				node.subdump(
					nodeMap:nodeMap, encodedClassMap: encodedClassMap, keyStringMap: keyStringMap,
					options:options, tabs: &tabs, first: false
				)
			)
		}
		for node in unkeyedValues {
			end	= true
			dump.append(
				node.subdump(
					nodeMap:nodeMap, encodedClassMap: encodedClassMap, keyStringMap: keyStringMap,
					options:options, tabs: &tabs, first: false
				)
			)
		}
		tabs.exit()
		if end {
			dump.append( "\(tabs).\n" )
		}

		return dump
	}
}
