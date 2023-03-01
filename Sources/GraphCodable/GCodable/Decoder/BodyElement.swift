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

import Foundation

final class BodyElement {
	private weak var	parentElement 	: BodyElement?
	private(set) var	fileBlock		: FileBlock
	private		var		keyedValues		= [String:BodyElement]()
	private		var 	unkeyedValues 	= [BodyElement]()
	
	
	static func rootElement<S>(
		bodyBlocks:S, keyStringMap:KeyStringMap, reverse:Bool
	) throws -> ( rootElement: BodyElement, elementMap: [UIntID : BodyElement] )
	where S:Sequence, S.Element == FileBlock {
		var elementMap	= [UIntID : BodyElement]()
		
		guard let root	= try BodyElement(
			bodyBlocks: bodyBlocks, elementMap:&elementMap, keyStringMap:keyStringMap, reverse: true
		) else {
			throw GCodableError.decodingError(
				Self.self, GCodableError.Context(
					debugDescription: "Root not found."
				)
			)
		}
		
		return (root,elementMap)
	}
	
	var keyedCount : Int {
		keyedValues.count
	}
	
	var unkeyedCount : Int {
		unkeyedValues.count
	}
	
	func contains( key:String ) -> Bool {
		keyedValues.index(forKey: key) != nil
	}
	
	func pop( key:String? ) -> BodyElement? {
		if let key = key {
			return keyedValues.removeValue(forKey: key)
		} else if unkeyedValues.count > 0 {
			return unkeyedValues.removeLast()
		} else {
			return nil
		}
	}
	
	func popIfNil() -> Bool? {
		guard unkeyedValues.count > 0 else {
			return nil
		}
		guard unkeyedValues.last.isNil else {
			return false
		}
		unkeyedValues.removeLast()
		return true
	}
	
	//	----------------------------------------------------------------
	
	private func subdump( elementMap: [UIntID : BodyElement], classDataMap: ClassDataMap?, keyStringMap: KeyStringMap?, options: GraphDumpOptions, level:Int ) -> String {
		var dump = ""
		
		let string = fileBlock.readableOutput(
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
	
	func dump( elementMap: [UIntID : BodyElement], classDataMap: ClassDataMap?, keyStringMap: KeyStringMap?, options: GraphDumpOptions ) -> String {
		let level	= 0
		var dump 	= ""
		
		dump.append( StringEncoder.titleString("FLATTENED BODY" ) )
		dump.append( StringEncoder.titleString( "ROOT:", filler: "-") )
		dump.append( subdump(elementMap: elementMap, classDataMap: classDataMap, keyStringMap: keyStringMap, options:options, level: level ))
		
		if elementMap.isEmpty == false {
			dump.append( StringEncoder.titleString( "WHERE:", filler: "-") )
			for (id,element) in elementMap {
				dump.append( "# PTR\(id) is:\n")
				dump.append( element.subdump( elementMap:elementMap, classDataMap: classDataMap, keyStringMap: keyStringMap, options:options, level: level ))
			}
		}
		
		return dump
	}
	
	//	----------------------------------------------------------------
	
	private init?<S>( bodyBlocks:S, elementMap map: inout [UIntID : BodyElement], keyStringMap:KeyStringMap, reverse:Bool ) throws
	where S:Sequence, S.Element == FileBlock {
		var lineIterator = bodyBlocks.makeIterator()
		
		if let dataBlock = lineIterator.next() {
			guard dataBlock.level != .exit else {
				throw GCodableError.decodingError(
					Self.self, GCodableError.Context(
						debugDescription: "The archive begins with an end block."
					)
				)
			}
			self.fileBlock	= dataBlock
			
			try Self.flatten( elementMap: &map, element: self, lineIterator: &lineIterator, keyStringMap:keyStringMap, reverse: reverse )
		} else {
			return nil
		}
	}
	
	private init( fileBlock:FileBlock ) {
		self.fileBlock	= fileBlock
	}
	
	private static func flatten<T>(
		elementMap map: inout [UIntID : BodyElement], element:BodyElement, lineIterator: inout T, keyStringMap:KeyStringMap, reverse:Bool
	) throws where T:IteratorProtocol, T.Element == FileBlock {
		
		switch element.fileBlock {
		case .idRef( let keyID, let typeID, let objID ):
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
			element.fileBlock	= .strongPtr( keyID: keyID, objID: objID )
			
			//	e per l'oggetto dovrà andare a vedere nella map, in modo che si possano
			//	beccare gli oggetti memorizzati dopo!
			let root		= BodyElement( fileBlock: .idRef(keyID: keyID, typeID: typeID, objID: objID) )
			map[ objID ]	= root
			
			try subFlatten(
				elementMap: &map, parentElement:root, lineIterator:&lineIterator,
				keyStringMap:keyStringMap, reverse:reverse
			)
		case .idBinRef( let keyID, let typeID, let objID, bytes: let bytes ):
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
			element.fileBlock	= .strongPtr( keyID: keyID, objID: objID )
			//	e per l'oggetto dovrà andare a vedere nella map, in modo che si possano
			//	beccare gli oggetti memorizzati dopo!
			let root		= BodyElement( fileBlock: .idBinRef(keyID: keyID, typeID: typeID, objID: objID,  bytes: bytes ) )
			map[ objID ]	= root
			// ATT! NO subFlatten for BinValue's
		case .idValue( let keyID, let objID ):
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
			element.fileBlock	= .strongPtr( keyID: keyID, objID: objID )
			
			//	e per l'oggetto dovrà andare a vedere nella map, in modo che si possano
			//	beccare gli oggetti memorizzati dopo!
			let root		= BodyElement( fileBlock: .idValue(keyID: keyID, objID: objID) )
			map[ objID ]	= root
			
			try subFlatten(
				elementMap: &map, parentElement:root, lineIterator:&lineIterator,
				keyStringMap:keyStringMap, reverse:reverse
			)
		case .idBinValue( let keyID, let objID, let bytes ):
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
			element.fileBlock	= .strongPtr( keyID: keyID, objID: objID )
			
			//	e per l'oggetto dovrà andare a vedere nella map, in modo che si possano
			//	beccare gli oggetti memorizzati dopo!
			let root		= BodyElement( fileBlock: .idBinValue(keyID: keyID, objID: objID, bytes:bytes ) )
			map[ objID ]	= root
			// ATT! NO subFlatten for BinValue's
		case .value( _ ):	fallthrough
		case .ref( _, _ ):
			try subFlatten(
				elementMap: &map, parentElement:element, lineIterator:&lineIterator,
				keyStringMap:keyStringMap, reverse:reverse
			)
		default:
			//	nothing to do
			break
		}
	}
	
	private static func subFlatten<T>(
		elementMap map: inout [UIntID : BodyElement], parentElement:BodyElement, lineIterator: inout T, keyStringMap:KeyStringMap, reverse:Bool
	) throws where T:IteratorProtocol, T.Element == FileBlock {
		while let dataBlock = lineIterator.next() {
			let bodyElement = BodyElement( fileBlock: dataBlock )
			
			if case .end = dataBlock {
				break
			} else {
				bodyElement.parentElement = parentElement
				
				if let keyID = dataBlock.keyID {
					guard let key = keyStringMap[keyID] else {
						throw GCodableError.keyNotFound(
							Self.self, GCodableError.Context(
								debugDescription: "Key for keyID-\(keyID)- not found."
							)
						)
					}
					if parentElement.keyedValues.index(forKey: key) == nil {
						parentElement.keyedValues[ key ] = bodyElement
					} else {
						throw GCodableError.duplicateKey(
							Self.self, GCodableError.Context(
								debugDescription: "Key -\(key)- already used."
							)
						)
					}
				} else {
					parentElement.unkeyedValues.append( bodyElement )
				}
				
				try flatten( elementMap: &map, element: bodyElement, lineIterator: &lineIterator, keyStringMap: keyStringMap, reverse: reverse )
			}
		}
		if reverse {
			parentElement.unkeyedValues.reverse()
		}
	}
}
