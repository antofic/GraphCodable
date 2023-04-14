//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

typealias ElementMap = [IdnID : FlattenedElement]

/// Decoding Pass 2
///
///	Reorder ReadBlock's in a `rootElement` and a `ElementMap = [idnID : FlattenedElement]`
///	dictionary to allow decoding of every acyclic graphs without requiring deferDecode
final class FlattenedElement {
	private(set) weak var	parentElement 	: FlattenedElement?
	private(set) var		readBlock		: ReadBlock
	private		var			keyedValues		= [KeyID:FlattenedElement]()
	private		var 		unkeyedValues 	= [FlattenedElement]()
	
	private init( readBlock:ReadBlock ) {
		self.readBlock	= readBlock
	}
	
	static func rootElement<S>(
		readBlocks:S, reverse:Bool
	) throws -> ( rootElement: FlattenedElement, elementMap: ElementMap )
	where S:Sequence, S.Element == ReadBlock {
		var elementMap	= ElementMap()
		var lineIterator = readBlocks.makeIterator()
		
		guard let readBlock = lineIterator.next() else {
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
		try Self.flatten( elementMap: &elementMap, element: root, lineIterator: &lineIterator, reverse: reverse )
		
		return (root,elementMap)
	}
	
	var unkeyedCount : Int {
		unkeyedValues.count
	}
	
	func contains( keyID:KeyID ) -> Bool {
		keyedValues.index(forKey: keyID) != nil
	}
	
	func pop( keyID:KeyID ) -> FlattenedElement? {
		keyedValues.removeValue(forKey: keyID)
	}
	
	func pop() -> FlattenedElement? {
		unkeyedCount > 0 ? unkeyedValues.removeLast() : nil
	}
}

// MARK: BodyElement private flatten section
extension FlattenedElement {
	private static func flatten<T>(
		elementMap map: inout ElementMap, element:FlattenedElement, lineIterator: inout T, reverse:Bool
	) throws where T:IteratorProtocol, T.Element == ReadBlock {
		func pointerRoot( element:FlattenedElement, elementMap map: ElementMap, keyID:KeyID?, idnID:IdnID ) throws -> FlattenedElement {
			//	l'oggetto non può già trovarsi nella map
			guard map.index(forKey: idnID) == nil else {
				throw Errors.GraphCodable.internalInconsistency(
					Self.self, Errors.Context(
						debugDescription: "Object |\(element.readBlock.fileBlock)| already exists."
					)
				)
			}
			// creo un nuovo elemento con il readBlock
			let root = FlattenedElement( readBlock: element.readBlock )
			// in quello vecchio metto un puntatore al vecchio elemento
			element.readBlock	= ReadBlock( strongPointerKeyID: keyID, idnID: idnID, position: element.readBlock.position )
			
			return root
		}
		
		switch element.readBlock.fileBlock {
			case .Val( let keyID, let idnID, _ ):
				if let idnID {
					let root = try pointerRoot( element:element, elementMap: map, keyID:keyID, idnID:idnID )
					// metto il nuovo elemento nella mappa
					map[ idnID ]	= root
					try subFlatten(
						elementMap: &map, parentElement:root, lineIterator:&lineIterator, reverse:reverse
					)
				} else {
					try subFlatten(
						elementMap: &map, parentElement:element, lineIterator:&lineIterator, reverse:reverse
					)
				}
			case .Bin( let keyID, let idnID, _, _ ):
				if let idnID {
					let root = try pointerRoot( element:element, elementMap: map, keyID:keyID, idnID:idnID )
					// metto il nuovo elemento nella mappa
					map[ idnID ]	= root
				}
				// ATT! NO subFlatten for BinValue's
			default:
				//	nothing to do
				break
		}
	}
	
	
	private static func subFlatten<T>(
		elementMap map: inout ElementMap, parentElement:FlattenedElement, lineIterator: inout T, reverse:Bool
	) throws where T:IteratorProtocol, T.Element == ReadBlock {
		while let readBlock = lineIterator.next() {
			let element = FlattenedElement( readBlock: readBlock )
			
			if case .End = readBlock.fileBlock {
				break
			} else {
				element.parentElement = parentElement
				
				if let keyID = readBlock.fileBlock.keyID {
					guard parentElement.keyedValues.index(forKey: keyID) == nil else {
						throw Errors.GraphCodable.malformedArchive(
							Self.self, Errors.Context(
								debugDescription: "KeyID |\(keyID)| already in use."
							)
						)
					}
					parentElement.keyedValues[ keyID ] = element
				} else {
					parentElement.unkeyedValues.append( element )
				}
				
				try flatten( elementMap: &map, element: element, lineIterator: &lineIterator, reverse: reverse )
			}
		}
		if reverse {
			parentElement.unkeyedValues.reverse()
		}
	}
}

// MARK: BodyElement dump section
extension FlattenedElement {
	func dump(
		elementMap: ElementMap, classDataMap: ClassDataMap?, keyStringMap: KeyStringMap?,
		options: GraphDumpOptions
	) -> String {
		var tabs	= Tabs(tabString: options.contains( .dontIndentBody ) ? Tabs.noTabs : Tabs.defaultTabs )
		var dump 	= ""
		dump.append( EncodeDump.titleString( "FLATTENED BODY" ) )
		dump.append( EncodeDump.titleString( "ROOT:", filler: "-") )
		dump.append( subdump(elementMap: elementMap, classDataMap: classDataMap, keyStringMap: keyStringMap, options:options, tabs: &tabs ))
		
		if elementMap.isEmpty == false {
			dump.append( EncodeDump.titleString( "WHERE:", filler: "-") )
			for (id,element) in elementMap.sorted( by: { $0.key < $1.key } ) {
				dump.append( "# PTR\(id) is:\n")
				dump.append( element.subdump( elementMap:elementMap, classDataMap: classDataMap, keyStringMap: keyStringMap, options:options, tabs: &tabs ))
			}
		}
		
		return dump
	}

	private func subdump(
		elementMap: ElementMap, classDataMap: ClassDataMap?, keyStringMap: KeyStringMap?,
		options: GraphDumpOptions, tabs: inout Tabs
	) -> String {
		var dump 	= ""
		let string	= readBlock.fileBlock.description( options: options, classDataMap: classDataMap, keyStringMap: keyStringMap )
		
		dump.append( "\(tabs)\(string)\n" )
		tabs.enter()
		var end	= false
		for element in keyedValues.values {
			end	= true
			dump.append(
				element.subdump(
					elementMap:elementMap, classDataMap: classDataMap, keyStringMap: keyStringMap, options:options, tabs: &tabs
				)
			)
		}
		for element in unkeyedValues {
			end	= true
			dump.append(
				element.subdump(
					elementMap:elementMap, classDataMap: classDataMap, keyStringMap: keyStringMap, options:options, tabs: &tabs
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
