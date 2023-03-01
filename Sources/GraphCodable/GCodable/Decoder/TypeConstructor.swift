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

final class TypeConstructor {
	private var			decodedData			: DataDecoder
	private (set) var 	currentElement 		: BodyElement
	private (set) var 	currentInfo 		: ClassInfo?
	private var			objectRepository 	= [ UIntID :Any ]()
	private var			setterRepository 	= [ () throws -> () ]()
	
	init( decodedData:DataDecoder ) {
		self.decodedData	= decodedData
		self.currentElement	= decodedData.rootElement
	}
	
	func decodeRoot<T>( _ type: T.Type, from decoder:GDecoder ) throws -> T where T:GDecodable {
		let rootBlock	= currentElement
		let value : T	= try decode( element:rootBlock, from: decoder )
		
		// decode dalayed
		while setterRepository.isEmpty == false {
			let setter = setterRepository.removeLast()
			try setter()
		}
		
		return value
	}
	
	func contains(key: String) -> Bool {
		currentElement.contains(key: key)
	}
	
	func popBodyElement( key:String? = nil ) throws -> BodyElement {
		if let key = key {
			// keyed case
			guard let element = currentElement.pop(key: key) else {
				throw GCodableError.childNotFound(
					Self.self, GCodableError.Context(
						debugDescription: "Keyed child for key-\(key)- not found in \(currentElement.fileBlock)."
					)
				)
			}
			return element
		} else {
			guard let element = currentElement.pop(key: nil) else {
				throw GCodableError.childNotFound(
					Self.self, GCodableError.Context(
						debugDescription: "Unkeyed child not found in \(currentElement.fileBlock)."
					)
				)
			}
			return element
		}
	}
	
	private func classInfo( typeID:UIntID ) throws -> ClassInfo {
		guard let classInfo = decodedData.classInfoMap[ typeID ] else {
			throw GCodableError.internalInconsistency(
				Self.self, GCodableError.Context(
					debugDescription: "ClassInfo not found for typeID -\(typeID)-."
				)
			)
		}
		return classInfo
	}
	
	var encodedVersion : UInt32 {
		get throws {
			guard let classInfo = currentInfo else {
				throw GCodableError.typeMismatch(
					Self.self, GCodableError.Context(
						debugDescription: "\(#function) not available for value types."
					)
				)
			}
			return classInfo.classData.encodeVersion
		}
	}
	
	var replacedType : GObsolete.Type? {
		get throws {
			guard let classInfo = currentInfo else {
				throw GCodableError.typeMismatch(
					Self.self, GCodableError.Context(
						debugDescription: "\(#function) not available for value types."
					)
				)
			}
			return classInfo.classData.obsoleteType
		}
	}
	
	func deferDecode<T>( element:BodyElement, from decoder:GDecoder, _ setter: @escaping (T) -> () ) throws where T:GDecodable {
		let setter : () throws -> () = {
			let value : T = try self.decode( element:element, from:decoder )
			setter( value )
		}
		setterRepository.append( setter )
	}
	
	
	private func decodeValue<T>( type:T.Type, element:BodyElement, from decoder:GDecoder ) throws -> T where T:GDecodable {
		let saved	= currentElement
		defer { currentElement = saved }
		currentElement	= element
		
		if let optType = T.self as? OptionalProtocol.Type {
			// get the inner non optional type
			let wrapped	= optType.fullUnwrappedType
			
			// check if conforms to GDecodable.Type,
			// costruct the value and check if is T
			guard
				let decodableType = wrapped as? GDecodable.Type,
				let value = try decodableType.init(from: decoder) as? T
			else {
				throw GCodableError.typeMismatch(
					Self.self, GCodableError.Context(
						debugDescription: "Block \(element) wrapped type -\(wrapped)- not GDecodable."
					)
				)
			}
			return value
		} else { //	if not, construct it:
			return try T.init(from: decoder)
		}
	}
	
	private func decodeBinValue<T>( type:T.Type, bytes: Bytes,element:BodyElement, from decoder:GDecoder ) throws -> T where T:GDecodable {
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
		
		guard
			let binaryIType = wrapped as? BinaryIType.Type,
			let value = try binaryIType.init(binaryData: bytes) as? T
		else {
			throw GCodableError.typeMismatch(
				Self.self, GCodableError.Context(
					debugDescription: "Block \(element) wrapped type -\(wrapped)- not BinaryIType."
				)
			)
		}
		return value
	}
	
	private func decodeRef<T>( type:T.Type, typeID:UIntID, element:BodyElement, from decoder:GDecoder ) throws -> T where T:GDecodable {
		let saved	= currentInfo
		defer { currentInfo = saved }
		currentInfo	= try classInfo( typeID:typeID )
		
		let type	= currentInfo!.decodableType.self
		guard let object = try decodeValue( type:type, element:element, from: decoder ) as? T else {
			throw GCodableError.internalInconsistency(
				Self.self, GCodableError.Context(
					debugDescription: "\(type) must be a subtype of \(T.self)."
				)
			)
		}
		return object
	}
	
	private func decodeBinRef<T>( type:T.Type, typeID:UIntID, bytes: Bytes, element:BodyElement, from decoder:GDecoder ) throws -> T where T:GDecodable {
		let saved	= currentInfo
		defer { currentInfo = saved }
		currentInfo	= try classInfo( typeID:typeID )
		
		let type	= currentInfo!.decodableType.self
		guard let object = try decodeBinValue( type:type, bytes: bytes, element:element, from: decoder ) as? T else {
			throw GCodableError.internalInconsistency(
				Self.self, GCodableError.Context(
					debugDescription: "\(type) must be a subtype of \(T.self)."
				)
			)
		}
		return object
	}
	
	func decode<T>( element:BodyElement, from decoder:GDecoder ) throws -> T where T:GDecodable {
		//		print(T.self)
		switch element.fileBlock {
		case .value( _ ):
			return try decodeValue( type:T.self, element:element, from: decoder )
		case .binValue( _ , let bytes ):
			return try decodeBinValue( type:T.self, bytes: bytes, element:element, from: decoder )
		case .ref( _ , let typeID ):
			return try decodeRef( type:T.self, typeID:typeID , element:element, from: decoder )
		case .binRef( _ , let typeID, let bytes ):
			return try decodeBinRef( type:T.self, typeID:typeID , bytes: bytes, element:element, from: decoder )
		default:
			guard let value = try decodeAny( element:element, from:decoder, type:T.self ) as? T else {
				throw GCodableError.typeMismatch(
					Self.self, GCodableError.Context(
						debugDescription: "Block \(element) doesn't contains a -\(T.self)- type."
					)
				)
			}
			
			return value
		}
	}
	
	private func decodeAny<T>( element:BodyElement, from decoder:GDecoder, type:T.Type ) throws -> Any where T:GDecodable {
		func decodeIdentifiable( type:T.Type, objID:UIntID, from decoder:GDecoder ) throws -> Any? {
			//	tutti gli oggetti (reference types) inizialmente si trovano in decodedData.objBlockMap
			//	quando arriva la prima richiesta di un particolare oggetto (da objID)
			//	lo costruiamo (se esiste) e lo mettiamo nell'objectRepository in modo
			//	che le richieste successive peschino di lì.
			//	se l'oggetto non esiste (possibile, se memorizzato condizionalmente)
			//	ritorniamo nil.
			
			if let object = objectRepository[ objID ] {
				return object
			} else if let element = decodedData.pop( objID: objID ) {
				switch element.fileBlock {
				case .idRef( _, let typeID, let objID ):
					let object	= try decodeRef(type: type, typeID: typeID, element: element, from: decoder)
					objectRepository[ objID ]	= object
					return object
				case .idBinRef( _, let typeID, let objID, let bytes ):
					let object	= try decodeBinRef( type:type, typeID: typeID, bytes: bytes, element:element, from:decoder )
					objectRepository[ objID ]	= object
					return object
				case .idValue( _, let objID ):
					let object		= try decodeValue( type:T.self, element:element, from: decoder )
					objectRepository[ objID ]	= object
					return object
				case .idBinValue( _, let objID, let bytes):
					let object		= try decodeBinValue( type:T.self, bytes: bytes, element:element, from:decoder )
					objectRepository[ objID ]	= object
					return object
				default:
					throw GCodableError.internalInconsistency(
						Self.self, GCodableError.Context(
							debugDescription: "Inappropriate bodyElement \(element.fileBlock) here."
						)
					)
				}
			} else {
				return nil
			}
		}
		
		switch element.fileBlock {
		case .Nil( _ ):
			return Optional<Any>.none as Any
		case .conditionalPtr( _, let objID ):
			// nessun controllo: può essere nil
			return try decodeIdentifiable( type:T.self, objID:objID, from:decoder ) as Any
		case .strongPtr( _, let objID ):
			// controllo: NON può essere nil
			guard let object = try decodeIdentifiable( type:T.self, objID:objID, from:decoder ) else {
				throw GCodableError.decodingError(
					Self.self, GCodableError.Context(
						debugDescription:
							"Object pointed from -\(element.fileBlock)- not found." +
						"Use deferDecode to break the cycles."
					)
				)
			}
			return object
		default:	// .Struct & .Object are inappropriate here!
			throw GCodableError.internalInconsistency(
				Self.self, GCodableError.Context(
					debugDescription: "Inappropriate bodyElement \(element.fileBlock) here."
				)
			)
		}
	}
}
