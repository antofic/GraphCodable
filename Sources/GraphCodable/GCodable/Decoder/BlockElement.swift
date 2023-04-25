//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

typealias ElementMap = [IdnID : BlockElement]

/// Decoding Pass 2
///
///	Reorder ReadBlock's in a `rootElement` and a `ElementMap = [idnID : BlockElement]`
///	dictionary to allow decoding of every acyclic graphs without requiring deferDecode
final class BlockElement {
	private(set) var		readBlock		: ReadBlock
	private		var			keyedValues		= [KeyID:BlockElement]()
	private		var 		unkeyedValues 	= [BlockElement]()
	
	private init( readBlock:ReadBlock ) {
		self.readBlock	= readBlock
	}
	
	static func rootElement<S>( readBlocks:S ) throws -> ( rootElement: BlockElement, elementMap: ElementMap )
	where S:Sequence, S.Element == ReadBlock {
		var blockIterator = readBlocks.makeIterator()
		
		guard let readBlock = blockIterator.next() else {
			throw Errors.GraphCodable.malformedArchive(
				Self.self, Errors.Context(
					debugDescription: "Root not found."
				)
			)
		}
		
		if case FileBlock.End = readBlock.fileBlock {
			throw Errors.GraphCodable.malformedArchive(
				Self.self, Errors.Context(
					debugDescription: "The archive begins with an end block."
				)
			)
		}
		
		let root = Self.init(readBlock: readBlock)
	
		var elementMap	= ElementMap()
		try Self.buildGraph( root, elementMap: &elementMap, blockIterator: &blockIterator, flatten: true )

		return (root,elementMap)
	}
	
	var unkeyedCount : Int {
		unkeyedValues.count
	}
	
	func contains( keyID:KeyID ) -> Bool {
		keyedValues.index(forKey: keyID) != nil
	}
	
	func pop( keyID:KeyID ) -> BlockElement? {
		keyedValues.removeValue(forKey: keyID)
	}
	
	func pop() -> BlockElement? {
		unkeyedCount > 0 ? unkeyedValues.removeLast() : nil
	}
}

// MARK: BodyElement private flatten section
extension BlockElement {
	@discardableResult
	private static func replaceWithPtr(
		_ element:BlockElement,elementMap map: inout ElementMap, keyID:KeyID?, idnID:IdnID
	) throws -> BlockElement {
		//	l'oggetto non può già trovarsi nella map
		guard map.index(forKey: idnID) == nil else {
			throw Errors.GraphCodable.internalInconsistency(
				Self.self, Errors.Context(
					debugDescription: "Object |\(element.readBlock.fileBlock)| already exists."
				)
			)
		}
		// creo un nuovo elemento con il readBlock
		let root = BlockElement( readBlock: element.readBlock )
		// metto il nuovo elemento nella mappa
		map[ idnID ]	= root
		// al posto del vecchio elemento metto un puntatore al vecchio elemento
		element.readBlock	= ReadBlock( strongPointerKeyID: keyID, idnID: idnID, position: element.readBlock.position )
		
		return root
	}
	
	private static func buildGraph<T>(
		_ element:BlockElement, elementMap map: inout ElementMap, blockIterator: inout T, flatten: Bool
	) throws where T:IteratorProtocol, T.Element == ReadBlock {
		switch element.readBlock.fileBlock {
			case .Val( let keyID, let idnID, _ ):
				if flatten, let idnID {
					let root = try replaceWithPtr( element, elementMap: &map, keyID:keyID, idnID:idnID )
					try buildSubGraph( root, elementMap: &map, blockIterator:&blockIterator, flatten: flatten )
				} else {
					try buildSubGraph( element, elementMap: &map, blockIterator:&blockIterator, flatten: flatten )
				}
			case .Bin( let keyID, let idnID, _, _ ):
				if flatten, let idnID {
					try replaceWithPtr( element, elementMap: &map, keyID:keyID, idnID:idnID )
				}	// ATT! NO subFlatten for BinValue's
			default: //	nothing to do
				break
		}
	}
	
	private static func buildSubGraph<T>(
		_ element:BlockElement, elementMap map: inout ElementMap, blockIterator: inout T, flatten: Bool
	) throws where T:IteratorProtocol, T.Element == ReadBlock {
		
		while let readBlock = blockIterator.next() {
			let field = BlockElement( readBlock: readBlock )
			
			if case .End = readBlock.fileBlock {
				break
			} else {
				//	field.parentElement = element
				
				if let keyID = readBlock.fileBlock.keyID {
					guard element.keyedValues.index(forKey: keyID) == nil else {
						throw Errors.GraphCodable.malformedArchive(
							Self.self, Errors.Context(
								debugDescription: "KeyID |\(keyID)| already in use."
							)
						)
					}
					element.keyedValues[ keyID ] = field
				} else {
					element.unkeyedValues.append( field )
				}
				
				try buildGraph( field, elementMap: &map, blockIterator: &blockIterator, flatten: flatten )
			}
		}
		element.unkeyedValues.reverse()
	}
}



/*
extension BlockElement : Hashable {
	static func == (lhs: BlockElement, rhs: BlockElement) -> Bool {
		lhs === rhs
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine( ObjectIdentifier( self ) )
	}
}

extension BlockElement {
	private struct ColorMap {
		enum Color { case white, gray, black }
		
		private var colorMap = [BlockElement:Color]()
		
		subscript( elem:BlockElement ) -> Color {
			get { colorMap[elem] ?? .white }
			set { colorMap[elem] = newValue }
		}
	}
	
	func isCyclic( elementMap:ElementMap ) -> Bool {
		var colorMap = ColorMap()
		if let element = self.trueValue(elementMap: elementMap) {
			return element.isCyclic(elementMap: elementMap, colorMap: &colorMap)
		} else {
			return false
		}
	}
	
	private func withField( apply: ( _ element:BlockElement )->Bool ) -> Bool {
		for field in unkeyedValues {
			if apply( field ) {
				return true
			}
		}
		for field in keyedValues.values {
			if apply( field ) {
				return true
			}
		}
		return false
	}
	
	private func isCyclic( elementMap:ElementMap, colorMap:inout ColorMap ) -> Bool {
		colorMap[ self ] = .gray
		
		if withField( apply: { field in
			if let trueField = field.trueValue( elementMap:elementMap ) {
				switch colorMap[ trueField ] {
					case .white:
						if trueField.isCyclic(elementMap: elementMap, colorMap: &colorMap) {
							return true
						}
					case .gray:
						return true
					case .black:
						break
				}
			}
			return false
		}) {
			return true
		}
		
		colorMap[ self ] = .black
		return false
	}
		 
	private func trueValue( elementMap:ElementMap ) -> BlockElement? {
		switch readBlock.fileBlock {
			case .Ptr( _, let idnID , _ ):
				return elementMap[ idnID ]
			case .Val( _,_,_ ):
				return self
			case .Bin( _,_,_,_ ):
				return self
			default:
				return nil
		}
	}
}
*/


// MARK: BodyElement dump section
extension BlockElement {
	func dump(
		elementMap: ElementMap, encodedClassMap: EncodedClassMap?, keyStringMap: KeyStringMap?,
		options: GraphDumpOptions
	) -> String {
		var tabs	= Tabs(tabString: options.contains( .dontIndentBody ) ? Tabs.noTabs : Tabs.defaultTabs )
		var dump 	= ""
		dump.append( EncodeDump.titleString( "FLATTENED BODY" ) )
		dump.append( EncodeDump.titleString( "ROOT:", filler: "-") )
		dump.append( subdump(elementMap: elementMap, encodedClassMap: encodedClassMap, keyStringMap: keyStringMap, options:options, tabs: &tabs ))
		
		if elementMap.isEmpty == false {
			dump.append( EncodeDump.titleString( "WHERE:", filler: "-") )
			for (id,element) in elementMap.sorted( by: { $0.key < $1.key } ) {
				dump.append( "# PTR\(id) is:\n")
				dump.append( element.subdump( elementMap:elementMap, encodedClassMap: encodedClassMap, keyStringMap: keyStringMap, options:options, tabs: &tabs ))
			}
		}
		
		return dump
	}

	private func subdump(
		elementMap: ElementMap, encodedClassMap: EncodedClassMap?, keyStringMap: KeyStringMap?,
		options: GraphDumpOptions, tabs: inout Tabs
	) -> String {
		var dump 	= ""
		let string	= readBlock.fileBlock.description( options: options, encodedClassMap: encodedClassMap, keyStringMap: keyStringMap )
		
		dump.append( "\(tabs)\(string)\n" )
		tabs.enter()
		var end	= false
		for element in keyedValues.values {
			end	= true
			dump.append(
				element.subdump(
					elementMap:elementMap, encodedClassMap: encodedClassMap, keyStringMap: keyStringMap, options:options, tabs: &tabs
				)
			)
		}
		for element in unkeyedValues {
			end	= true
			dump.append(
				element.subdump(
					elementMap:elementMap, encodedClassMap: encodedClassMap, keyStringMap: keyStringMap, options:options, tabs: &tabs
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
