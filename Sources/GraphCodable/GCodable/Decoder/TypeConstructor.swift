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


final class TypeConstructor {
	private var			ioDecoder			: BinaryIODecoder
	private var			decodeBinary		: DecodeBinary
	private (set) var 	currentElement 		: FlattenedElement
	private (set) var 	currentInfo 		: ClassInfo?
	private var			objectRepository 	= [ ObjID: any GDecodable ]()
	private var			setterRepository 	= [ (_:TypeConstructor) throws -> () ]()
	
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
	
	func contains(key: String) -> Bool {
		currentElement.contains(key: key)
	}
	
	func popBodyElement( key:String ) throws -> FlattenedElement {
		// keyed case
		guard let element = currentElement.pop(key: key) else {
			throw GraphCodableError.valueNotFound(
				Self.self, GraphCodableError.Context(
					debugDescription: "Keyed value for key \(key) not found in \(currentElement.readBlock)."
				)
			)
		}
		return element
	}
	
	func popBodyElement() throws -> FlattenedElement {
		// keyed case
		guard let element = currentElement.pop() else {
			throw GraphCodableError.valueNotFound(
				Self.self, GraphCodableError.Context(
					debugDescription: "Unkeyed value not found in \(currentElement.readBlock)."
				)
			)
		}
		return element
	}
	
	
	var encodedClassVersion : UInt32 {
		get throws {
			guard let classInfo = currentInfo else {
				throw GraphCodableError.referenceTypeRequired(
					Self.self, GraphCodableError.Context(
						debugDescription: "\(#function) not available for value types."
					)
				)
			}
			return classInfo.classData.encodedClassVersion
		}
	}
	
	var replacedClass : (any (AnyObject & GDecodable).Type)? {
		get throws {
			guard let classInfo = currentInfo else {
				throw GraphCodableError.referenceTypeRequired(
					Self.self, GraphCodableError.Context(
						debugDescription: "\(#function) not available for value types."
					)
				)
			}
			return classInfo.classData.replacedClass
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
			case .Val( _, let objID, let typeID ):
				if objID == nil {
					return try decode(type: T.self, typeID: typeID, isBinary: false, element: element, from: decoder)
				}
			case .Bin( _, let objID, let typeID, _ ):
				if objID == nil {
					return try decode(type: T.self, typeID: typeID, isBinary: true, element: element, from: decoder)
				}
				
			default:
				break
		}
		guard let value = try decodeAny( element:element, from:decoder, type:T.self ) as? T else {
			throw GraphCodableError.malformedArchive(
				Self.self, GraphCodableError.Context(
					debugDescription: "Block \(element) doesn't contains a \(T.self) type."
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
		func decodeIdentifiable<D:GDecoder>( type:T.Type, objID:ObjID, from decoder:D ) throws -> (any GDecodable)? {
			//	quando arriva la prima richiesta di un particolare oggetto (da objID)
			//	lo costruiamo (se esiste) e lo mettiamo nell'objectRepository in modo
			//	che le richieste successive peschino di lì.
			//	se l'oggetto non esiste (possibile, se memorizzato condizionalmente)
			//	ritorniamo nil.
			
			if let object = objectRepository[ objID ] {
				return object
			} else if let element = decodeBinary.pop( objID: objID ) {
				switch element.readBlock.fileBlock {
					case .Val( _, let objID, let typeID ):
						if let objID {
							let object	= try decode(type: T.self, typeID: typeID, isBinary: false, element: element, from: decoder)
							objectRepository[ objID ]	= object
							return object
						}
					case .Bin( _, let objID, let typeID, _ ):
						if let objID {
							let object	= try decode(type: T.self, typeID: typeID, isBinary: true, element: element, from: decoder)
							objectRepository[ objID ]	= object
							return object
						}
					default:
						break
				}
				throw GraphCodableError.internalInconsistency(
					Self.self, GraphCodableError.Context(
						debugDescription: "Inappropriate fileblock \(element.readBlock.fileBlock) here."
					)
				)
			} else {
				return nil
			}
		}
		
		switch element.readBlock.fileBlock {
			case .Nil( _ ):
				return Optional<Any>.none as Any
			case .Ptr( _, let objID, let conditional ):
				if conditional {
					return try decodeIdentifiable( type:T.self, objID:objID, from:decoder ) as Any
				} else {
					guard let object = try decodeIdentifiable( type:T.self, objID:objID, from:decoder ) else {
						throw GraphCodableError.possibleCyclicGraphDetected(
							Self.self, GraphCodableError.Context(
								debugDescription:
									"Value pointed from \(element.readBlock.fileBlock) not found. Try deferDecode to break the cycle."
							)
						)
					}
					return object
				}
			default:	// .Struct & .Object are inappropriate here!
				throw GraphCodableError.internalInconsistency(
					Self.self, GraphCodableError.Context(
						debugDescription: "Inappropriate fileblock \(element.readBlock.fileBlock) here."
					)
				)
		}
	}
}

// MARK: TypeConstructor private level 2
extension TypeConstructor {
	private func decode<T,D>( type:T.Type, typeID:TypeID?, isBinary:Bool , element:FlattenedElement, from decoder:D ) throws -> T
	where T:GDecodable, D:GDecoder {
		if let typeID {
			return try decodeRefOrBinRef( type:T.self, typeID:typeID , isBinary:isBinary, element:element, from: decoder )
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
		
		guard let value =  try T._wrappedType.init(from: decoder) as? T else {
			throw GraphCodableError.malformedArchive(
				Self.self, GraphCodableError.Context(
					debugDescription: "Block \(element) wrapped type \(T._wrappedType) not GDecodable."
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
		
		let wrapped = T._wrappedType

		guard let binaryIType = wrapped as? any BDecodable.Type else {
			throw GraphCodableError.malformedArchive(
				Self.self, GraphCodableError.Context(
					debugDescription: "\(element) wrapped type \(wrapped) is not a BDecodable."
				)
			)
		}

		guard let value = try ioDecoder.withinRegion(
			range: 		element.readBlock.binaryIORegionRange,
			decodeFunc:	{ try $0.decode( binaryIType.self ) }
		) as? T else {
			throw GraphCodableError.malformedArchive(
				Self.self, GraphCodableError.Context(
					debugDescription: "\(element) decoded type is not a \(T.self) type."
				)
			)
		}
		 
		return value
	}

	
/*
	private func decodeValue<T,D>( type:T.Type, element:FlattenedElement, from decoder:D ) throws -> T
	where T:GDecodable, D:GDecoder {
		let saved	= currentElement
		defer { currentElement = saved }
		currentElement	= element
		
		if let optType = T.self as? any OptionalProtocol.Type {
			// get the inner non optional type
			let wrapped	= optType.fullUnwrappedType
			
			// check if conforms to GDecodable.Type,
			// costruct the value and check if is T
			guard
				let decodedType = wrapped as? any GDecodable.Type,
				let value = try decodedType.init(from: decoder) as? T
			else {
				throw GraphCodableError.malformedArchive(
					Self.self, GraphCodableError.Context(
						debugDescription: "Block \(element) wrapped type \(wrapped) not GDecodable."
					)
				)
			}
			return value
		} else { //	if not, construct it:
			return try T.init(from: decoder)
		}
	}

	private func decodeBinValue<T,D>( type:T.Type, element:FlattenedElement, from decoder:D ) throws -> T
	where T:GDecodable, D:GDecoder {
		let saved	= currentElement
		defer { currentElement = saved }
		currentElement	= element
		
		let wrapped : Any.Type
		
		if let optType = T.self as? any OptionalProtocol.Type {
			// get the inner non optional type
			wrapped	= optType.fullUnwrappedType
		} else {
			wrapped	= T.self
		}

		guard let binaryIType = wrapped as? any BDecodable.Type else {
			throw GraphCodableError.malformedArchive(
				Self.self, GraphCodableError.Context(
					debugDescription: "\(element) wrapped type \(wrapped) is not a BDecodable."
				)
			)
		}

		guard let value = try ioDecoder.withinRegion(
			range: 		element.readBlock.binaryIORegionRange,
			decodeFunc:	{ try $0.decode( binaryIType.self ) }
		) as? T else {
			throw GraphCodableError.malformedArchive(
				Self.self, GraphCodableError.Context(
					debugDescription: "\(element) decoded type is not a \(T.self) type."
				)
			)
		}
		 
		return value
	}
*/
/*
	private func decodeValue<T,D>( type:T.Type, element:FlattenedElement, from decoder:D ) throws -> T
	where T:GDecodable, D:GDecoder {
		let saved	= currentElement
		defer { currentElement = saved }
		currentElement	= element
		
		return try T.init(from: decoder)
	}

	private func decodeBinValue<T,D>( type:T.Type, element:FlattenedElement, from decoder:D ) throws -> T
	where T:GDecodable, D:GDecoder {
		let saved	= currentElement
		defer { currentElement = saved }
		currentElement	= element
		
		/*
		let wrapped : Any.Type
		
		if let optType = T.self as? any OptionalProtocol.Type {
			// get the inner non optional type
			wrapped	= optType.fullUnwrappedType
		} else {
			wrapped	= T.self
		}
		 */
		 
		guard let binaryIType = T.self as? any BDecodable.Type else {
			throw GraphCodableError.malformedArchive(
				Self.self, GraphCodableError.Context(
					debugDescription: "\(element) wrapped type \(T.self) is not a BDecodable."
				)
			)
		}
	
		guard let value = try ioDecoder.withinRegion(
			range: 		element.readBlock.binaryIORegionRange,
			decodeFunc:	{ try $0.decode( binaryIType.self ) }
		) as? T else {
			throw GraphCodableError.malformedArchive(
				Self.self, GraphCodableError.Context(
					debugDescription: "\(element) decoded type is not a \(T.self) type."
				)
			)
		}
		 
		return value
	}
*/
	
	
	private func decodeRefOrBinRef<T,D>( type:T.Type, typeID:TypeID, isBinary: Bool, element:FlattenedElement, from decoder:D ) throws -> T
	where T:GDecodable, D:GDecoder {
		guard let classInfo = decodeBinary.classInfoMap[ typeID ] else {
			throw GraphCodableError.internalInconsistency(
				Self.self, GraphCodableError.Context(
					debugDescription: "Type name not found for typeID \(typeID)."
				)
			)
		}
		
		let saved	= currentInfo
		defer { currentInfo = saved }
		currentInfo	= classInfo
		
		let type	= classInfo.decodedType.self
		let object	: any GDecodable
		if isBinary {
			object = try decodeBinValue( type:type, element:element, from: decoder )
		} else {
			object = try decodeValue( type:type, element:element, from: decoder )
		}

		guard let object = object as? T else {
			throw GraphCodableError.internalInconsistency(
				Self.self, GraphCodableError.Context(
					debugDescription: "\(type) must be a subtype of \(T.self)."
				)
			)
		}

		return object
	}
}

