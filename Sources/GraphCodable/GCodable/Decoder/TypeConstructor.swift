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
	private var			objectRepository 	= [ IdnID: any GDecodable ]()
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
			case .Ptr( _, let idnID, let conditional ):
				if conditional {
					return try decodeIdentifiable( type:T.self, idnID:idnID, from:decoder ) as Any
				} else {
					guard let object = try decodeIdentifiable( type:T.self, idnID:idnID, from:decoder ) else {
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
			throw GraphCodableError.malformedArchive(
				Self.self, GraphCodableError.Context(
					debugDescription: "Block \(element) wrapped type \(T._fullOptionalUnwrappedType) not GDecodable."
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
			throw GraphCodableError.malformedArchive(
				Self.self, GraphCodableError.Context(
					debugDescription: "\(element) wrapped type \(type._fullOptionalUnwrappedType) is not GBinaryDecodable."
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

	private func decodeRefOrBinRef<T,D>( type:T.Type, refID:RefID, isBinary: Bool, element:FlattenedElement, from decoder:D ) throws -> T
	where T:GDecodable, D:GDecoder {
		guard let classInfo = decodeBinary.classInfoMap[ refID ] else {
			throw GraphCodableError.internalInconsistency(
				Self.self, GraphCodableError.Context(
					debugDescription: "Type name not found for refID \(refID)."
				)
			)
		}
		
		let saved	= currentInfo
		defer { currentInfo = saved }
		currentInfo	= classInfo
		
		let type = classInfo.decodedType.self
		let object	= isBinary ?
			try decodeBinValue( type:type, element:element, from: decoder ):
			try decodeValue( type:type, element:element, from: decoder )
		
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

