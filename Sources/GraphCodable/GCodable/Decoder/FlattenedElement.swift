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

///	Reorder FileBlock's in a `rootElement` and a `[objID : FlattenedElement]` dictionary
///	to allow dearchiving of acyclic graphs without requiring deferDecode
final class FlattenedElement {
	private weak var	parentElement 	: FlattenedElement?
	private(set) var	fileBlock		: FileBlock
	private		var		keyedValues		= [String:FlattenedElement]()
	private		var 	unkeyedValues 	= [FlattenedElement]()
	
	private init( fileBlock:FileBlock ) {
		self.fileBlock	= fileBlock
	}
	
	static func rootElement<S>(
		fileBlocks:S, keyStringMap:KeyStringMap, reverse:Bool
	) throws -> ( rootElement: FlattenedElement, elementMap: [UIntID : FlattenedElement] )
	where S:Sequence, S.Element == FileBlock {
		var elementMap	= [UIntID : FlattenedElement]()
		var lineIterator = fileBlocks.makeIterator()
		
		guard let fileBlock = lineIterator.next() else {
			throw GCodableError.decodingError(
				Self.self, GCodableError.Context(
					debugDescription: "Root not found."
				)
			)
		}
		
		guard fileBlock.level != .exit else {
			throw GCodableError.decodingError(
				Self.self, GCodableError.Context(
					debugDescription: "The archive begins with an end block."
				)
			)
		}
		
		let root = Self.init(fileBlock: fileBlock)
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
		elementMap map: inout [UIntID : FlattenedElement], element:FlattenedElement, lineIterator: inout T, keyStringMap:KeyStringMap, reverse:Bool
	) throws where T:IteratorProtocol, T.Element == FileBlock {
		
		switch element.fileBlock {
		case .Val( let keyID, let typeID, let objID, let bytes ):
			if let objID {
				//	l'oggetto non può trovarsi nella map
				guard map.index(forKey: objID) == nil else {
					throw GCodableError.internalInconsistency(
						Self.self, GCodableError.Context(
							debugDescription: "Object -\(element.fileBlock)- already exists."
						)
					)
				}
				//	trasformo l'oggetto in uno strong pointer
				//	così la procedura di lettura incontrerà quello al posto dell'oggetto
				element.fileBlock	= .Ptr( keyID: keyID, objID: objID, conditional: false )
				
				//	e per l'oggetto dovrà andare a vedere nella map, in modo che si possano
				//	beccare gli oggetti memorizzati dopo!
				let root		= FlattenedElement( fileBlock: .Val(keyID: keyID, typeID: typeID, objID: objID, bytes: bytes) )
				map[ objID ]	= root
				if bytes == nil {	// ATT! NO subFlatten for BinValue's
					try subFlatten(
						elementMap: &map, parentElement:root, lineIterator:&lineIterator,
						keyStringMap:keyStringMap, reverse:reverse
					)
				}
			} else if bytes == nil {	// ATT! NO subFlatten for BinValue's
				try subFlatten(
					elementMap: &map, parentElement:element, lineIterator:&lineIterator,
					keyStringMap:keyStringMap, reverse:reverse
				)
			}
		default:
			//	nothing to do
			break
		}
	}
	
	
	private static func subFlatten<T>(
		elementMap map: inout [UIntID : FlattenedElement], parentElement:FlattenedElement, lineIterator: inout T, keyStringMap:KeyStringMap, reverse:Bool
	) throws where T:IteratorProtocol, T.Element == FileBlock {
		while let fileBlock = lineIterator.next() {
			let element = FlattenedElement( fileBlock: fileBlock )
			
			if case .End = fileBlock {
				break
			} else {
				element.parentElement = parentElement
				
				if let keyID = fileBlock.keyID {
					guard let key = keyStringMap[keyID] else {
						throw GCodableError.keyNotFound(
							Self.self, GCodableError.Context(
								debugDescription: "Key for keyID-\(keyID)- not found."
							)
						)
					}
					guard parentElement.keyedValues.index(forKey: key) == nil else {
						throw GCodableError.duplicateKey(
							Self.self, GCodableError.Context(
								debugDescription: "Key -\(key)- already used."
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
	func dump( elementMap: [UIntID : FlattenedElement], classDataMap: ClassDataMap?, keyStringMap: KeyStringMap?, options: GraphDumpOptions ) -> String {
		let level	= 0
		var dump 	= ""
		
		dump.append( StringEncoder.titleString("FLATTENED BODY" ) )
		dump.append( StringEncoder.titleString( "ROOT:", filler: "-") )
		dump.append( subdump(elementMap: elementMap, classDataMap: classDataMap, keyStringMap: keyStringMap, options:options, level: level ))
		
		if elementMap.isEmpty == false {
			dump.append( StringEncoder.titleString( "WHERE:", filler: "-") )
			for (id,element) in elementMap {
				dump.append( "# PTR\(id.format("04")) is:\n")
				dump.append( element.subdump( elementMap:elementMap, classDataMap: classDataMap, keyStringMap: keyStringMap, options:options, level: level ))
			}
		}
		
		return dump
	}
	
	private func subdump( elementMap: [UIntID : FlattenedElement], classDataMap: ClassDataMap?, keyStringMap: KeyStringMap?, options: GraphDumpOptions, level:Int ) -> String {
		var dump = ""
		
		let string = fileBlock.description(
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
