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
	private var			readBuffer			: BinaryReadBuffer
	private var			binaryDecoder		: BinaryDecoder
	private (set) var 	currentElement 		: FlattenedElement
	private (set) var 	currentInfo 		: ClassInfo?
	private var			objectRepository 	= [ ObjID: Any ]()
	private var			setterRepository 	= [ () throws -> () ]()
	
	var fileHeader : FileHeader { binaryDecoder.fileHeader }
	
	init( readBuffer:BinaryReadBuffer, classNameMap:ClassNameMap? ) throws {
		self.readBuffer		= readBuffer
		self.binaryDecoder	= try BinaryDecoder(from: readBuffer, classNameMap:classNameMap )
		self.currentElement	= binaryDecoder.rootElement
	}

	func decodeRoot<T>( _ type: T.Type, from decoder:GDecoder ) throws -> T where T:GDecodable {
		let rootBlock	= currentElement
		let value : T	= try decode( element:rootBlock, from: decoder )
		
		// call deferDecode
		while setterRepository.isEmpty == false {
			let setter = setterRepository.removeLast()
			try setter()
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
	
	var replacedClass : (AnyObject & GDecodable).Type? {
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
	
	func deferDecode<T>( element:FlattenedElement, from decoder:GDecoder, _ setter: @escaping (T) -> () ) throws where T:GDecodable {
		let setter : () throws -> () = {
			let value : T = try self.decode( element:element, from:decoder )
			setter( value )
		}
		setterRepository.append( setter )
	}
	
	func decode<T>( element:FlattenedElement, from decoder:GDecoder ) throws -> T where T:GDecodable {
		switch element.readBlock.fileBlock {
		case .Val( _, let objID, let typeID, let binSize):
			if objID == nil {
				return try decode(type: T.self, typeID: typeID, binSize: binSize, element: element, from: decoder)
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
	private func decodeAny<T>( element:FlattenedElement, from decoder:GDecoder, type:T.Type ) throws -> Any where T:GDecodable {
		func decodeIdentifiable( type:T.Type, objID:ObjID, from decoder:GDecoder ) throws -> Any? {
			//	tutti gli oggetti (reference types) inizialmente si trovano in binaryDecoder
			//	quando arriva la prima richiesta di un particolare oggetto (da objID)
			//	lo costruiamo (se esiste) e lo mettiamo nell'objectRepository in modo
			//	che le richieste successive peschino di lì.
			//	se l'oggetto non esiste (possibile, se memorizzato condizionalmente)
			//	ritorniamo nil.
			
			if let object = objectRepository[ objID ] {
				return object
			} else if let element = binaryDecoder.pop( objID: objID ) {
				switch element.readBlock.fileBlock {
				case .Val( _, let objID, let typeID, let binSize):
					if let objID {
						let object	= try decode(type: T.self, typeID: typeID, binSize: binSize, element: element, from: decoder)
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
	private func decode<T>( type:T.Type, typeID:TypeID?, binSize: BinSize?, element:FlattenedElement, from decoder:GDecoder ) throws -> T where T:GDecodable {
		if let typeID {
			return try decodeRefOrBinRef( type:T.self, typeID:typeID , binSize:binSize, element:element, from: decoder )
		} else if let binSize {
			return try decodeBinValue( type:T.self, binSize:binSize, element:element, from: decoder )
		} else {
			return try decodeValue( type:T.self, element:element, from: decoder )
		}
	}
}

// MARK: TypeConstructor private level 3
extension TypeConstructor {
	private func decodeValue<T>( type:T.Type, element:FlattenedElement, from decoder:GDecoder ) throws -> T where T:GDecodable {
		let saved	= currentElement
		defer { currentElement = saved }
		currentElement	= element
		
		if let optType = T.self as? OptionalProtocol.Type {
			// get the inner non optional type
			let wrapped	= optType.fullUnwrappedType
			
			// check if conforms to GDecodable.Type,
			// costruct the value and check if is T
			guard
				let decodedType = wrapped as? GDecodable.Type,
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

	private func decodeBinValue<T>( type:T.Type, binSize:BinSize, element:FlattenedElement, from decoder:GDecoder ) throws -> T where T:GDecodable {
		let saved	= currentElement
		defer { currentElement = saved }
		currentElement	= element
		
		let wrapped : Any.Type
		
		if let optType = T.self as? OptionalProtocol.Type {
			// get the inner non optional type
			wrapped	= optType.fullUnwrappedType
		} else {
			wrapped	= T.self
		}

		guard let binaryIType = wrapped as? BinaryIType.Type else {
			throw GraphCodableError.malformedArchive(
				Self.self, GraphCodableError.Context(
					debugDescription: "\(element) wrapped type \(wrapped) is not a BinaryIType."
				)
			)
		}

		readBuffer.region	= element.readBlock.valueRegion

		guard let value = try binaryIType.init(from: &readBuffer) as? T else {
			throw GraphCodableError.malformedArchive(
				Self.self, GraphCodableError.Context(
					debugDescription: "\(element) decoded type is not a \(T.self) type."
				)
			)
		}

		let readSize	= readBuffer.regionStart - element.readBlock.valueRegion.startIndex
		guard binSize.size == readSize else {
			throw GraphCodableError.malformedArchive(
				Self.self, GraphCodableError.Context(
					debugDescription: "\(binSize.size) bytes required, \(readSize) bytes read."
				)
			)
		}

		return value
	}
	
	private func decodeRefOrBinRef<T>(
		type:T.Type, typeID:TypeID, binSize: BinSize?, element:FlattenedElement, from decoder:GDecoder
	) throws -> T where T:GDecodable {
		guard let classInfo = binaryDecoder.classInfoMap[ typeID ] else {
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
		let object	: GDecodable
		if let binSize {
			object = try decodeBinValue( type:type, binSize: binSize, element:element, from: decoder )
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
