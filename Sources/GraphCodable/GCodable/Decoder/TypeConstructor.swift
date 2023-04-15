//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

final class TypeConstructor {
	private var			ioDecoder			: BinaryIODecoder
	private var			decodeBinary		: DecodeBinary
	private (set) var 	currentElement 		: FlattenedElement
	private (set) var 	currentClass 		: DecodedClass?
	private var			objectRepository 	= [ IdnID: any GDecodable ]()
	private var			setterRepository 	= [ (_:TypeConstructor) throws -> () ]()
	private lazy var	keyStringMap		: KeyStringMap = {
		// we use keyStringMap only in case of errors
		Dictionary( uniqueKeysWithValues: decodeBinary.keyIDMap.map {
				(key,value) in (value,key)
			})
	}()
	
	var fileHeader : FileHeader { decodeBinary.fileHeader }
	
	init( ioDecoder:BinaryIODecoder, classNameMap:ClassNameMap? ) throws {
		self.ioDecoder		= ioDecoder
		self.decodeBinary	= try DecodeBinary(from: ioDecoder, classNameMap:classNameMap )
		self.currentElement	= decodeBinary.rootElement
	}

	func decodeRoot<T,D>( _ type: T.Type, from decoder:D ) throws -> T
	where T:GDecodable, D:GDecoder {
		let rootBlock	= currentElement
		let value : T	= try decode( element:rootBlock, from: decoder )
		
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
		return currentElement.contains( keyID: keyID )
	}
	
	func popBodyElement( key:String ) throws -> FlattenedElement {
		// keyed case
		guard
			let keyID = keyID( for: key ),
			let element = currentElement.pop(keyID: keyID) else {
			throw Errors.GraphCodable.valueNotFound(
				Self.self, Errors.Context(
					debugDescription: "\( fileblockDescr( currentElement ) ): keyed value for key |\(key)| not found."
				)
			)
		}
		return element
	}
	
	func popBodyElement() throws -> FlattenedElement {
		// keyed case
		guard let element = currentElement.pop() else {
			throw Errors.GraphCodable.valueNotFound(
				Self.self, Errors.Context(
					debugDescription: "\( fileblockDescr( currentElement ) ): unkeyed value not found."
				)
			)
		}
		return element
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
	
	func deferDecode<T,D>( element:FlattenedElement, from decoder:D, _ setter: @escaping (T) -> () ) throws
	where T:GDecodable, D:GDecoder {
		let setterFunc : ( _:TypeConstructor ) throws -> () = {
			let value : T = try $0.decode( element:element, from:decoder )
			setter( value )
		}
		setterRepository.append( setterFunc )
	}
	
	func decode<T,D>( element:FlattenedElement, from decoder:D ) throws -> T
	where T:GDecodable, D:GDecoder {
		switch element.readBlock.fileBlock {
			case .Val( _, let idnID, let refID ):
				if idnID == nil {
					return try decode(type: T.self, refID: refID, isBinary: false, element: element, from: decoder)
				}
			case .Bin( _, let idnID, let refID, _ ):
				if idnID == nil {
					return try decode(type: T.self, refID: refID, isBinary: true, element: element, from: decoder)
				}
				
			default:
				break
		}
		guard let value = try decodeAny( element:element, from:decoder, type:T.self ) as? T else {
			throw Errors.GraphCodable.malformedArchive(
				Self.self, Errors.Context(
					debugDescription: "\( fileblockDescr( element ) ) doesn't contains a |\(T.self)| type."
				)
			)
		}
		return value
	}
}

// MARK: TypeConstructor private level 1
extension TypeConstructor {
	private func decodeAny<T,D>( element:FlattenedElement, from decoder:D, type:T.Type ) throws -> Any
	where T:GDecodable, D:GDecoder {
		func decodeIdentifiable<D:GDecoder>( type:T.Type, idnID:IdnID, from decoder:D ) throws -> (any GDecodable)? {
			//	quando arriva la prima richiesta di un particolare oggetto (da idnID)
			//	lo costruiamo (se esiste) e lo mettiamo nell'objectRepository in modo
			//	che le richieste successive peschino di lì.
			//	se l'oggetto non esiste (possibile, se memorizzato condizionalmente)
			//	ritorniamo nil.
			
			if let object = objectRepository[ idnID ] {
				return object
			} else if let element = decodeBinary.pop( idnID: idnID ) {
				switch element.readBlock.fileBlock {
					case .Val( _, let idnID, let refID ):
						if let idnID {
							let object	= try decode(type: T.self, refID: refID, isBinary: false, element: element, from: decoder)
							objectRepository[ idnID ]	= object
							return object
						}
					case .Bin( _, let idnID, let refID, _ ):
						if let idnID {
							let object	= try decode(type: T.self, refID: refID, isBinary: true, element: element, from: decoder)
							objectRepository[ idnID ]	= object
							return object
						}
					default:
						break
				}
				throw Errors.GraphCodable.internalInconsistency(
					Self.self, Errors.Context(
						debugDescription: "\( fileblockDescr( element ) ) not appropriate while decoding type |\(T.self)|."
					)
				)
			} else {
				return nil
			}
		}
		
		switch element.readBlock.fileBlock {
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
									"\( fileblockDescr( element ) ) not found while decoding type |\(T.self)|. Try deferDecode to break the cycle."
							)
						)
					}
					return object
				}
			default:	// .Struct & .Object are inappropriate here!
				throw Errors.GraphCodable.internalInconsistency(
					Self.self, Errors.Context(
						debugDescription: "\( fileblockDescr( element ) ) not appropriate while decoding type |\(T.self)|."
					)
				)
		}
	}
}

// MARK: TypeConstructor private level 2
extension TypeConstructor {
	private func decode<T,D>( type:T.Type, refID:RefID?, isBinary:Bool , element:FlattenedElement, from decoder:D ) throws -> T
	where T:GDecodable, D:GDecoder {
		if let refID {
			return try decodeRefOrBinRef( type:T.self, refID:refID , isBinary:isBinary, element:element, from: decoder )
		} else if isBinary {
			return try decodeBinValue( type:T.self, element:element, from: decoder )
		} else {
			return try decodeValue( type:T.self, element:element, from: decoder )
		}
	}
}

// MARK: TypeConstructor private level 3
extension TypeConstructor {
	private func decodeValue<T,D>( type:T.Type, element:FlattenedElement, from decoder:D ) throws -> T
	where T:GDecodable, D:GDecoder {
		let saved	= currentElement
		defer { currentElement = saved }
		currentElement	= element
		
		guard let value =  try T._fullOptionalUnwrappedType.init(from: decoder) as? T else {
			throw Errors.GraphCodable.malformedArchive(
				Self.self, Errors.Context(
					debugDescription:
						"\( fileblockDescr( element ) ): wrapped type |\(T._fullOptionalUnwrappedType)| retrieved while decoding type |\(T.self)| is not GDecodable."
				)
			)
		}
		
		return value
	}

	private func decodeBinValue<T,D>( type:T.Type, element:FlattenedElement, from decoder:D ) throws -> T
	where T:GDecodable, D:GDecoder {
		let saved	= currentElement
		defer { currentElement = saved }
		currentElement	= element
		
		guard let binaryIType = type._fullOptionalUnwrappedType as? any GBinaryDecodable.Type else {
			throw Errors.GraphCodable.malformedArchive(
				Self.self, Errors.Context(
					debugDescription:
						"\( fileblockDescr( element ) ): wrapped type |\(T._fullOptionalUnwrappedType)| retrieved while decoding type |\(T.self)| is not GBinaryDecodable."
				)
			)
		}

		guard let value = try ioDecoder.withinRegion(
			range: 		element.readBlock.binaryIORegionRange,
			decodeFunc:	{ try $0.decode( binaryIType.self ) }
		) as? T else {
			throw Errors.GraphCodable.malformedArchive(
				Self.self, Errors.Context(
					debugDescription: "\( fileblockDescr( element ) ): decoded type is not a |\(T.self)| type."
				)
			)
		}
		 
		return value
	}

	private func decodeRefOrBinRef<T,D>( type:T.Type, refID:RefID, isBinary: Bool, element:FlattenedElement, from decoder:D ) throws -> T
	where T:GDecodable, D:GDecoder {
		guard let decodedClass = decodeBinary.decodedClassMap[ refID ] else {
			throw Errors.GraphCodable.internalInconsistency(
				Self.self, Errors.Context(
					debugDescription: "\( fileblockDescr( element ) ): class info not found for refID |\(refID)|."
				)
			)
		}
		
		let saved	= currentClass
		defer { currentClass = saved }
		currentClass	= decodedClass
		
		let type 	= decodedClass.decodedType.self
		let object	= isBinary ?
			try decodeBinValue( type:type, element:element, from: decoder ):
			try decodeValue( type:type, element:element, from: decoder )
		
		guard let object = object as? T else {
			throw Errors.GraphCodable.internalInconsistency(
				Self.self, Errors.Context(
					debugDescription: "\( fileblockDescr( element ) ): |\(type)| is not a subtype of |\(T.self)|."
				)
			)
		}

		return object
	}
	
	/// ful fileblock information used only for errors
	private func fileblockDescr( _ element: FlattenedElement ) -> String {
		let string = element.readBlock.fileBlock.description(
			options: .readable, decodedClassMap: decodeBinary.decodedClassMap, keyStringMap: keyStringMap
		)
		if let parent = element.parentElement {
			let  parentString = parent.readBlock.fileBlock.description(
				options: .readable, decodedClassMap: decodeBinary.decodedClassMap, keyStringMap: keyStringMap
			)
			return "Field |\(string)| of value |\(parentString)|"
		} else {
			return "Value |\(string)|"
		}
	}
}

