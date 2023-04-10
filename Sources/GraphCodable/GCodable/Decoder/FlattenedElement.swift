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

import Foundation

typealias ElementMap = [IdnID : FlattenedElement]

/// Decoding Pass 2
///
///	Reorder ReadBlock's in a `rootElement` and a `ElementMap = [idnID : FlattenedElement]`
///	dictionary to allow decoding of every acyclic graphs without requiring deferDecode
final class FlattenedElement {
	private weak var	parentElement 	: FlattenedElement?
	private(set) var	readBlock		: ReadBlock
	private		var		keyedValues		= [String:FlattenedElement]()
	private		var 	unkeyedValues 	= [FlattenedElement]()
	
	private init( readBlock:ReadBlock ) {
		self.readBlock	= readBlock
	}
	
	static func rootElement<S>(
		readBlocks:S, keyStringMap:KeyStringMap, reverse:Bool
	) throws -> ( rootElement: FlattenedElement, elementMap: ElementMap )
	where S:Sequence, S.Element == ReadBlock {
		var elementMap	= ElementMap()
		var lineIterator = readBlocks.makeIterator()
		
		guard let readBlock = lineIterator.next() else {
			throw GraphCodableError.malformedArchive(
				Self.self, GraphCodableError.Context(
					debugDescription: "Root not found."
				)
			)
		}
		
		guard readBlock.fileBlock.level != .exit else {
			throw GraphCodableError.malformedArchive(
				Self.self, GraphCodableError.Context(
					debugDescription: "The archive begins with an end block."
				)
			)
		}
		
		let root = Self.init(readBlock: readBlock)
		try Self.flatten( elementMap: &elementMap, element: root, lineIterator: &lineIterator, keyStringMap:keyStringMap, reverse: reverse )
		
		return (root,elementMap)
	}
	
	var unkeyedCount : Int {
		unkeyedValues.count
	}
	
	func contains( key:String ) -> Bool {
		keyedValues.index(forKey: key) != nil
	}
	
	func pop( key:String ) -> FlattenedElement? {
		keyedValues.removeValue(forKey: key)
	}
	
	func pop() -> FlattenedElement? {
		unkeyedCount > 0 ? unkeyedValues.removeLast() : nil
	}
}

// MARK: BodyElement private flatten section
extension FlattenedElement {
	private static func flatten<T>(
		elementMap map: inout ElementMap, element:FlattenedElement, lineIterator: inout T, keyStringMap:KeyStringMap, reverse:Bool
	) throws where T:IteratorProtocol, T.Element == ReadBlock {
		
		switch element.readBlock.fileBlock {
			case .Val( let keyID, let idnID, _ ):
				if let idnID {
					//	l'oggetto non può già trovarsi nella map
					guard map.index(forKey: idnID) == nil else {
						throw GraphCodableError.internalInconsistency(
							Self.self, GraphCodableError.Context(
								debugDescription: "Object \(element.readBlock) already exists."
							)
						)
					}
					// creo un nuovo elemento con il readBlock
					let root = FlattenedElement( readBlock: element.readBlock )
					// in quello vecchio metto un puntatore al vecchio elemento
					element.readBlock	= ReadBlock( with: .Ptr( keyID: keyID, idnID: idnID, conditional: false ), copying: element.readBlock )
					// metto il nuovo elelemnto nella mappa
					map[ idnID ]	= root
					
					try subFlatten(
						elementMap: &map, parentElement:root, lineIterator:&lineIterator,
						keyStringMap:keyStringMap, reverse:reverse
					)
				} else {
					try subFlatten(
						elementMap: &map, parentElement:element, lineIterator:&lineIterator,
						keyStringMap:keyStringMap, reverse:reverse
					)
				}
			case .Bin( let keyID, let idnID, _, _ ):
				if let idnID {
					//	l'oggetto non può già trovarsi nella map
					guard map.index(forKey: idnID) == nil else {
						throw GraphCodableError.internalInconsistency(
							Self.self, GraphCodableError.Context(
								debugDescription: "Object \(element.readBlock) already exists."
							)
						)
					}
					// creo un nuovo elemento con il readBlock
					let root = FlattenedElement( readBlock: element.readBlock )
					// in quello vecchio metto un puntatore al vecchio elemento
					element.readBlock	= ReadBlock( with: .Ptr( keyID: keyID, idnID: idnID, conditional: false ), copying: element.readBlock )
					// metto il nuovo elelemnto nella mappa
					map[ idnID ]	= root
				}
				// ATT! NO subFlatten for BinValue's
			default:
				//	nothing to do
				break
		}
	}
	
	
	private static func subFlatten<T>(
		elementMap map: inout ElementMap, parentElement:FlattenedElement, lineIterator: inout T, keyStringMap:KeyStringMap, reverse:Bool
	) throws where T:IteratorProtocol, T.Element == ReadBlock {
		while let readBlock = lineIterator.next() {
			let element = FlattenedElement( readBlock: readBlock )
			
			if case .End = readBlock.fileBlock {
				break
			} else {
				element.parentElement = parentElement
				
				if let keyID = readBlock.fileBlock.keyID {
					guard let key = keyStringMap[keyID] else {
						throw GraphCodableError.malformedArchive(
							Self.self, GraphCodableError.Context(
								debugDescription: "Key for keyID\(keyID) not found."
							)
						)
					}
					guard parentElement.keyedValues.index(forKey: key) == nil else {
						throw GraphCodableError.malformedArchive(
							Self.self, GraphCodableError.Context(
								debugDescription: "Key \(key) already used."
							)
						)
					}
					parentElement.keyedValues[ key ] = element
				} else {
					parentElement.unkeyedValues.append( element )
				}
				
				try flatten( elementMap: &map, element: element, lineIterator: &lineIterator, keyStringMap: keyStringMap, reverse: reverse )
			}
		}
		if reverse {
			parentElement.unkeyedValues.reverse()
		}
	}
}

// MARK: BodyElement dump section
extension FlattenedElement {
	func dump( elementMap: ElementMap, classDataMap: ClassDataMap?, keyStringMap: KeyStringMap?, options: GraphDumpOptions ) -> String {
		let level	= 0
		var dump 	= ""
		
		dump.append( EncodeDump.titleString("FLATTENED BODY" ) )
		dump.append( EncodeDump.titleString( "ROOT:", filler: "-") )
		dump.append( subdump(elementMap: elementMap, classDataMap: classDataMap, keyStringMap: keyStringMap, options:options, level: level ))
		
		if elementMap.isEmpty == false {
			dump.append( EncodeDump.titleString( "WHERE:", filler: "-") )
			for (id,element) in elementMap {
				dump.append( "# PTR\(id) is:\n")
				dump.append( element.subdump( elementMap:elementMap, classDataMap: classDataMap, keyStringMap: keyStringMap, options:options, level: level ))
			}
		}
		
		return dump
	}
	
	private func subdump( elementMap: ElementMap, classDataMap: ClassDataMap?, keyStringMap: KeyStringMap?, options: GraphDumpOptions, level:Int ) -> String {
		var dump = ""
		
		let string = readBlock.fileBlock.description(
			options: options, binaryValue: nil,
			classDataMap: classDataMap, keyStringMap: keyStringMap
		)
		let tabs = String(repeating: "\t", count: level)
		dump.append( "\(tabs)\(string)\n" )
		var end	= false
		for element in keyedValues.values {
			end	= true
			dump.append( element.subdump( elementMap:elementMap, classDataMap: classDataMap, keyStringMap: keyStringMap, options:options, level: level+1 ))
		}
		for element in unkeyedValues {
			end	= true
			dump.append( element.subdump( elementMap:elementMap, classDataMap: classDataMap, keyStringMap: keyStringMap, options:options, level: level+1 ))
		}
		if end {
			dump.append( "\(tabs).\n" )
		}
		
		return dump
	}
}
