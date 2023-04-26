//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

final class TypeConstructor {
	private var			ioDecoder			: BinaryIODecoder
	private var			decodeBinary		: DecodeBinary
	private (set) var 	currentNode 		: ReadNode
	private (set) var 	currentClass 		: DecodedClass?
	private var			objectRepository 	= [ IdnID: any GDecodable ]()
	private var			setterRepository 	= [ (_:TypeConstructor) throws -> () ]()
	private lazy var	keyStringMap		: KeyStringMap = {
		// we use keyStringMap only in case of errors
		Dictionary( uniqueKeysWithValues: decodeBinary.keyIDMap.map { ($1,$0) })
	}()
	
	var fileHeader : FileHeader { decodeBinary.fileHeader }
	
	init( ioDecoder:BinaryIODecoder, classNameMap:ClassNameMap? ) throws {
		self.ioDecoder		= ioDecoder
		self.decodeBinary	= try DecodeBinary(from: ioDecoder, classNameMap:classNameMap )
		self.currentNode	= decodeBinary.rootNode
	}

	func decodeRoot<T,D>( _ type: T.Type, from decoder:D ) throws -> T
	where T:GDecodable, D:GDecoder {
		let rootBlock	= currentNode
		let value : T	= try decode( node:rootBlock, from: decoder )
		
		// call deferDecode
		while setterRepository.isEmpty == false {
			let setter = setterRepository.removeLast()
			try setter( self )
		}
		
		return value
	}
	
	private func keyID( for key:String ) -> KeyID? {
		decodeBinary.keyIDMap[ key ]
	}
	
	func contains(key: String) -> Bool {
		guard let keyID = keyID( for: key ) else {
			return false
		}
		return currentNode.contains( keyID: keyID )
	}
	
	func popNode( key:String ) throws -> ReadNode {
		// keyed case
		guard
			let keyID = keyID( for: key ),
			let node = currentNode.pop(keyID: keyID) else {
			throw Errors.GraphCodable.valueNotFound(
				Self.self, Errors.Context(
					debugDescription: "\( fileblockDescr( currentNode ) ): keyed value for key |\(key)| not found or already decoded."
				)
			)
		}
		return node
	}
	
	func popNode() throws -> ReadNode {
		// unkeyed case
		guard let node = currentNode.pop() else {
			throw Errors.GraphCodable.valueNotFound(
				Self.self, Errors.Context(
					debugDescription: "\( fileblockDescr( currentNode ) ): unkeyed value not found."
				)
			)
		}
		return node
	}
	
	var encodedClassVersion : UInt32 {
		get throws {
			guard let decodedClass = currentClass else {
				throw Errors.GraphCodable.referenceTypeRequired(
					Self.self, Errors.Context(
						debugDescription: "\(#function) not available for value types."
					)
				)
			}
			return decodedClass.encodedClass.encodedClassVersion
		}
	}
	
	var replacedClass : (any (AnyObject & GDecodable).Type)? {
		get throws {
			guard let decodedClass = currentClass else {
				throw Errors.GraphCodable.referenceTypeRequired(
					Self.self, Errors.Context(
						debugDescription: "\(#function) not available for value types."
					)
				)
			}
			return decodedClass.encodedClass.replacedClass
		}
	}
	
	func deferDecode<T,D>( node:ReadNode, from decoder:D, _ setter: @escaping (T) -> () ) throws
	where T:GDecodable, D:GDecoder {
		let setterFunc : ( _:TypeConstructor ) throws -> () = {
			let value : T = try $0.decode( node:node, from:decoder )
			setter( value )
		}
		setterRepository.append( setterFunc )
	}
	
	func decode<T,D>( node:ReadNode, from decoder:D ) throws -> T
	where T:GDecodable, D:GDecoder {
		switch node.block.fileBlock {
			case .Val( _, let idnID, let refID ):
				if idnID == nil {
					return try decode(type: T.self, refID: refID, isBinary: false, node: node, from: decoder)
				}
			case .Bin( _, let idnID, let refID, _ ):
				if idnID == nil {
					return try decode(type: T.self, refID: refID, isBinary: true, node: node, from: decoder)
				}
				
			default:
				break
		}
		guard let value = try decodeAny( node:node, from:decoder, type:T.self ) as? T else {
			throw Errors.GraphCodable.malformedArchive(
				Self.self, Errors.Context(
					debugDescription: "\( fileblockDescr( node ) ) doesn't contains a |\(T.self)| type."
				)
			)
		}
		return value
	}
}

// MARK: TypeConstructor private level 1
extension TypeConstructor {
	private func decodeAny<T,D>( node:ReadNode, from decoder:D, type:T.Type ) throws -> Any
	where T:GDecodable, D:GDecoder {
		func decodeIdentifiable<D:GDecoder>( type:T.Type, idnID:IdnID, from decoder:D ) throws -> (any GDecodable)? {
			//	quando arriva la prima richiesta di un particolare oggetto (da idnID)
			//	lo costruiamo (se esiste) e lo mettiamo nell'objectRepository in modo
			//	che le richieste successive peschino di lì.
			//	se l'oggetto non esiste (possibile, se memorizzato condizionalmente)
			//	ritorniamo nil.
			
			if let object = objectRepository[ idnID ] {
				return object
			} else if let node = decodeBinary.pop( idnID: idnID ) {
				switch node.block.fileBlock {
					case .Val( _, let idnID, let refID ):
						if let idnID {
							let object	= try decode(type: T.self, refID: refID, isBinary: false, node: node, from: decoder)
							objectRepository[ idnID ]	= object
							return object
						}
					case .Bin( _, let idnID, let refID, _ ):
						if let idnID {
							let object	= try decode(type: T.self, refID: refID, isBinary: true, node: node, from: decoder)
							objectRepository[ idnID ]	= object
							return object
						}
					default:
						break
				}
				throw Errors.GraphCodable.internalInconsistency(
					Self.self, Errors.Context(
						debugDescription: "\( fileblockDescr( node ) ) not appropriate while decoding type |\(T.self)|."
					)
				)
			} else {
				return nil
			}
		}
		
		switch node.block.fileBlock {
			case .Nil( _ ):
				return Optional<Any>.none as Any
			case .Ptr( _, let idnID, let conditional ):
				if conditional {
					return try decodeIdentifiable( type:T.self, idnID:idnID, from:decoder ) as Any
				} else {
					guard let object = try decodeIdentifiable( type:T.self, idnID:idnID, from:decoder ) else {
						throw Errors.GraphCodable.possibleCyclicGraphDetected(
							Self.self, Errors.Context(
								debugDescription:
									"\( fileblockDescr( node ) ) not found while decoding type |\(T.self)|. Try deferDecode to break the cycle."
							)
						)
					}
					return object
				}
			default:	// .Struct & .Object are inappropriate here!
				throw Errors.GraphCodable.internalInconsistency(
					Self.self, Errors.Context(
						debugDescription: "\( fileblockDescr( node ) ) not appropriate while decoding type |\(T.self)|."
					)
				)
		}
	}
}

// MARK: TypeConstructor private level 2
extension TypeConstructor {
	private func decode<T,D>( type:T.Type, refID:RefID?, isBinary:Bool , node:ReadNode, from decoder:D ) throws -> T
	where T:GDecodable, D:GDecoder {
		if let refID {
			return try decodeRefOrBinRef( type:T.self, refID:refID , isBinary:isBinary, node:node, from: decoder )
		} else if isBinary {
			return try decodeBinValue( type:T.self, node:node, from: decoder )
		} else {
			return try decodeValue( type:T.self, node:node, from: decoder )
		}
	}
}

// MARK: TypeConstructor private level 3
extension TypeConstructor {
	private func decodeValue<T,D>( type:T.Type, node:ReadNode, from decoder:D ) throws -> T
	where T:GDecodable, D:GDecoder {
		let saved	= currentNode
		defer { currentNode = saved }
		currentNode	= node
		
		guard let value =  try T._fullOptionalUnwrappedType.init(from: decoder) as? T else {
			throw Errors.GraphCodable.malformedArchive(
				Self.self, Errors.Context(
					debugDescription:
						"\( fileblockDescr( node ) ): wrapped type |\(T._fullOptionalUnwrappedType)| retrieved while decoding type |\(T.self)| is not GDecodable."
				)
			)
		}
		
		return value
	}

	private func decodeBinValue<T,D>( type:T.Type, node:ReadNode, from decoder:D ) throws -> T
	where T:GDecodable, D:GDecoder {
		let saved	= currentNode
		defer { currentNode = saved }
		currentNode	= node
		
		guard let binaryIType = type._fullOptionalUnwrappedType as? any GBinaryDecodable.Type else {
			throw Errors.GraphCodable.malformedArchive(
				Self.self, Errors.Context(
					debugDescription:
						"\( fileblockDescr( node ) ): wrapped type |\(T._fullOptionalUnwrappedType)| retrieved while decoding type |\(T.self)| is not GBinaryDecodable."
				)
			)
		}

		guard let value = try ioDecoder.withinRegion(
			range: 		node.block.binaryIORegionRange,
			decodeFunc:	{ try $0.decode( binaryIType.self ) }
		) as? T else {
			throw Errors.GraphCodable.malformedArchive(
				Self.self, Errors.Context(
					debugDescription: "\( fileblockDescr( node ) ): decoded type is not a |\(T.self)| type."
				)
			)
		}
		 
		return value
	}

	private func decodeRefOrBinRef<T,D>( type:T.Type, refID:RefID, isBinary: Bool, node:ReadNode, from decoder:D ) throws -> T
	where T:GDecodable, D:GDecoder {
		guard let decodedClass = decodeBinary.decodedClassMap[ refID ] else {
			throw Errors.GraphCodable.internalInconsistency(
				Self.self, Errors.Context(
					debugDescription: "\( fileblockDescr( node ) ): class info not found for refID |\(refID)|."
				)
			)
		}
		
		let saved	= currentClass
		defer { currentClass = saved }
		currentClass	= decodedClass
		
		let type 	= decodedClass.decodedType.self
		let object	= isBinary ?
			try decodeBinValue( type:type, node:node, from: decoder ):
			try decodeValue( type:type, node:node, from: decoder )
		
		guard let object = object as? T else {
			throw Errors.GraphCodable.internalInconsistency(
				Self.self, Errors.Context(
					debugDescription: "\( fileblockDescr( node ) ): |\(type)| is not a subtype of |\(T.self)|."
				)
			)
		}

		return object
	}
	
	/// ful fileblock information used only for errors
	private func fileblockDescr( _ node: ReadNode ) -> String {
		let string = node.block.fileBlock.description(
			options: .readable, decodedClassMap: decodeBinary.decodedClassMap, keyStringMap: keyStringMap
		)
		return "Value |\(string)|"
	}
}

