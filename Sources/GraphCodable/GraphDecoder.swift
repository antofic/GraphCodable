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

// -------------------------------------------------
// ----- GraphDecoder
// -------------------------------------------------

public final class GraphDecoder {
	public init() {}

	///	get/set the userInfo dictionary
	public var userInfo : [String:Any] {
		get { decoder.userInfo }
		set { decoder.userInfo = newValue }
	}

	///	Decode the root value from a Data buffer
	///
	///	The root value must conform to the GCodable protocol
	public func decode<T>( _ type: T.Type, from data: Data ) throws -> T  where T:GCodable {
		try decoder.decodeRoot( type, from: data)
	}

	///	Returns all the classes encoded in data
	public func decodableClasses( from data: Data ) throws -> [(AnyObject & GCodable).Type] {
		let types	= try decoder.allClassData( from: data ).compactMap { $0.codableType }
		let keys	= types.map { ObjectIdentifier($0) }
		let map		= Dictionary( zip(keys,types) ) { v1,v2 in v1 }
		return Array( map.values )
	}

	///	Returns all the obsolete classes encoded in data
	public func obsoleteClasses( from data: Data ) throws -> [GCodableObsolete.Type] {
		let types	= try decoder.allClassData( from: data ).compactMap { $0.obsoleteType }
		let keys	= types.map { ObjectIdentifier($0) }
		let map		= Dictionary( zip(keys,types) ) { v1,v2 in v1 }
		return Array( map.values )
	}
	
	private let decoder = Decoder()
	
	// -------------------------------------------------
	// ----- Decoder
	// -------------------------------------------------
	
	private final class Decoder : GDecoder {
		var	userInfo			= [String:Any]()

		func allClassData( from data: Data ) throws -> [ClassData] {
			var reader				= BinaryReader(data: data)
			let decodedNames		= try DecodedNames(from: &reader)
			
			return Array( decodedNames.classDataMap.values )
		}
		
		func decodeRoot<T>( _ type: T.Type, from data: Data ) throws -> T  where T:GCodable {
			defer { _costructor = nil }
			
			var reader	= BinaryReader(data: data)
			
			constructor	= TypeConstructor(decodedData: try DecodedData( from: &reader ))
			
			return try constructor.decodeRoot(type, from: self)
		}
		
		var encodedVersion : UInt32 {
			get throws { try constructor.encodedVersion }
		}

		var replacedType : GCodableObsolete.Type?   {
			get throws { try constructor.replacedType }
		}
		
		// ------ keyed support
		
		func contains<Key>(_ key: Key) -> Bool
		where Key : RawRepresentable, Key.RawValue == String
		{
			constructor.contains(key: key.rawValue)
		}
		
		func decode<Key, Value>(for key: Key) throws -> Value
		where Key : RawRepresentable, Value : GCodable, Key.RawValue == String
		{
			let	bodyElement = try constructor.popBodyElement( key:key.rawValue )
			
			return try constructor.decodeNode( bodyElement:bodyElement, from: self )
		}
		
		func deferDecode<Key, Value>( for key: Key, _ setter: @escaping (Value) -> ()) throws
		where Key : RawRepresentable, Value : GCodable, Key.RawValue == String
		{
			let	bodyElement = try constructor.popBodyElement( key:key.rawValue )

			try constructor.deferDecodeNode( bodyElement:bodyElement, from: self, setter )
		}

		// ------ unkeyed support
		
		var unkeyedCount : Int {
			constructor.currentBodyElement.unkeyedCount
		}
		
		func decode<Value>() throws -> Value where Value : GCodable {
			let	bodyElement = try constructor.popBodyElement()

			return try constructor.decodeNode( bodyElement:bodyElement, from: self )
		}
		
		func deferDecode<Value>(_ setter: @escaping (Value) -> ()) throws where Value : GCodable {
			let	bodyElement = try constructor.popBodyElement()

			try constructor.deferDecodeNode( bodyElement:bodyElement, from: self, setter )
		}

		// ------ Private
		
		private var constructor : TypeConstructor {
			get {
				guard let lpd = _costructor else {
					preconditionFailure( #function )
				}
				return lpd
			}
			set {
				_costructor	= newValue
			}
		}
		
		private var _costructor : TypeConstructor?
	}
}


// -------------------------------------------------
// ----- DecodedData
// -------------------------------------------------

fileprivate struct DecodedData {
	let fileVersion				: UInt32
	let encodedMainModule		: String
	let	classInfoMap			: [IntID:ClassInfo]
	let bodyRootElement 		: BodyElement
	private var	bodyElementMap	: [IntID : BodyElement]
	
	init( from reader:inout BinaryReader ) throws {
		var blockDecoder = BlockDecoder( from: &reader )
		
		(fileVersion,encodedMainModule)		= try blockDecoder.fileVersionAndMainModule()
		classInfoMap						= try blockDecoder.classInfoMap()
		(bodyRootElement,bodyElementMap)	= try blockDecoder.bodyRootElement()
	}
	
	mutating func pop( objID:IntID ) -> BodyElement? {
		bodyElementMap.removeValue( forKey: objID )
	}
}

// -------------------------------------------------
// ----- DecodedNames
// -------------------------------------------------

fileprivate struct DecodedNames {
	let fileVersion				: UInt32
	let encodedMainModule		: String
	let	classDataMap			: [IntID:ClassData]
	
	init( from reader:inout BinaryReader ) throws {
		var blockDecoder = BlockDecoder( from: &reader )
		
		(fileVersion,encodedMainModule)	= try blockDecoder.fileVersionAndMainModule()
		classDataMap					= try blockDecoder.classDataMap()
	}
}

// -------------------------------------------------
// ----- BlockDecoder
// -------------------------------------------------

fileprivate struct BlockDecoder {
	private var reader				: BinaryReader
	private var currentBlock		: DataBlock?
	private var phase				: DataBlock.BlockType
	
	private var _encodedMainModule	= ""

	private var _fileVersion		= UInt32(0)
	private var _classDataMap		= [IntID : ClassData]()
	private var _bodyDataBlocks		= [DataBlock]()
	private var _keyIDToKey			= [IntID:String]()
	
	init( from reader:inout BinaryReader ) {
		self.reader				= reader
		self.phase				= .header
	}

	mutating func fileVersionAndMainModule() throws -> (UInt32,String) {
		try parseHeader()
		return (_fileVersion,_encodedMainModule)
	}

	mutating func classDataMap() throws -> [IntID : ClassData] {
		try parseHeader()
		try parseTypeMap()
		return _classDataMap
	}

	mutating func classInfoMap() throws -> [IntID : ClassInfo] {
		try classDataMap().mapValues {  try ClassInfo(classData: $0)  }
	}
	
	mutating func bodyRootElement() throws -> ( bodyRootElement:BodyElement, bodyElementMap:[IntID : BodyElement] ) {
		try parseHeader()
		try parseTypeMap()
		try parseBody()
		try parseKeyMap()
		
		return try BodyElement.bodyRootElement( bodyDataBlocks:_bodyDataBlocks, keyIDToKey:_keyIDToKey, reverse:true )
	}

	// private section
	
	private mutating func peek() throws -> DataBlock? {
		if currentBlock == nil {
			currentBlock	= reader.eof ? nil : try DataBlock( from: &reader )
		}
		return currentBlock
	}

	private mutating func step() {
		currentBlock = nil
	}

	private mutating func parseHeader() throws {
		guard phase == .header else { return }
		
		while let dataBlock	= try peek() {
			switch dataBlock {
			case .header( let version, let module, _ /*unused1*/, _ /*unused2*/ ):
				_encodedMainModule	= module
				_fileVersion		= version
			default:
				self.phase	= .typeMap
				return
			}
			step()
		}
	}
	
	private mutating func parseTypeMap() throws {
		guard phase == .typeMap else { return }

		while let dataBlock	= try peek() {
			switch dataBlock {
			case .outTypeMap( let typeID, let classData ):
				// ••• PHASE 1 •••
				guard _classDataMap.index(forKey: typeID) == nil else {
					throw GCodableError.duplicateTypeID(
						Self.self, GCodableError.Context(
							debugDescription: "TypeID -\(typeID)- already used."
						)
					)
				}
				_classDataMap[typeID]	= classData
			default:
				self.phase	= .body
				return
			}
			step()
		}
	}
	
	private mutating func parseBody() throws {
		guard phase == .body else { return }

		while let dataBlock	= try peek() {
			guard dataBlock.blockType == .body else {
				self.phase	= .keyMap
				return
			}
			_bodyDataBlocks.append( dataBlock )
			step()
		}
	}

	private mutating func parseKeyMap() throws {
		guard phase == .keyMap else { return }

		while let dataBlock	= try peek() {
			switch dataBlock {
			case .keyMap( let keyID, let key ):
				guard _keyIDToKey.index(forKey: keyID) == nil else {
					throw GCodableError.duplicateKey(
						Self.self, GCodableError.Context(
							debugDescription: "Key -\(key)- already used."
						)
					)
				}
				_keyIDToKey[keyID]	= key
			default:
				return
			}
			step()
		}
	}

}

// ------------------------------------------------------
// ------ final class BodyElement
// ------------------------------------------------------

fileprivate final class BodyElement {
	private weak var	parentElement 	: BodyElement?
	private(set) var	dataBlock		: DataBlock
	private		var		keyedValues		= [String:BodyElement]()
	private		var 	unkeyedValues 	= [BodyElement]()
	
	static func bodyRootElement<S>(
		bodyDataBlocks:S, keyIDToKey:[IntID:String], reverse:Bool
	) throws -> ( bodyRootElement: BodyElement, bodyElementMap: [IntID : BodyElement] )
	where S:Sequence, S.Element == DataBlock {
		var map			= [IntID : BodyElement]()
		
		guard let root	= try BodyElement(
			bodyDataBlocks: bodyDataBlocks, bodyElementMap:&map, keyIDToKey:keyIDToKey, reverse: true
		) else {
			throw GCodableError.decodingError(
				Self.self, GCodableError.Context(
					debugDescription: "Root not found."
				)
			)
		}
		
		return (root,map)
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

	private init?<S>( bodyDataBlocks:S, bodyElementMap map: inout [IntID : BodyElement], keyIDToKey:[IntID:String], reverse:Bool ) throws
	where S:Sequence, S.Element == DataBlock {
		var lineIterator = bodyDataBlocks.makeIterator()
		
		if let dataBlock = lineIterator.next() {
			guard dataBlock.level != .exit else {
				throw GCodableError.decodingError(
					Self.self, GCodableError.Context(
						debugDescription: "The archive begins with an end block."
					)
				)
			}
			self.dataBlock	= dataBlock
			
			try Self.flatten( bodyElementMap: &map, bodyElement: self, lineIterator: &lineIterator, keyIDsToKey:keyIDToKey, reverse: reverse )
		} else {
			return nil
		}
	}

	private init( dataBlock:DataBlock ) {
		self.dataBlock	= dataBlock
	}

	private static func flatten<T>(
		bodyElementMap map: inout [IntID : BodyElement], bodyElement:BodyElement, lineIterator: inout T, keyIDsToKey:[IntID:String], reverse:Bool
	) throws where T:IteratorProtocol, T.Element == DataBlock {
		switch bodyElement.dataBlock {
		case .objectType( let keyID, let typeID, let objID ):
			//	l'oggetto non può trovarsi nella map
			guard map.index(forKey: objID) == nil else {
				throw GCodableError.internalInconsistency(
					Self.self, GCodableError.Context(
						debugDescription: "Object -\(bodyElement.dataBlock)- already exists."
					)
				)
			}
			
			//	trasformo l'oggetto in uno strong pointer
			//	così la procedura di lettura incontrerà quello al posto dell'oggetto
			bodyElement.dataBlock	= .objectSPtr( keyID: keyID, objID: objID )
			
			//	e per l'oggetto dovrà andare a vedere nella map, in modo che si possano
			//	beccare gli oggetti memorizzati dopo!
			let root		= BodyElement( dataBlock: .objectType(keyID: keyID, typeID: typeID, objID: objID) )
			map[ objID ]	= root
			
			try subFlatten(
				bodyElementMap: &map, parentElement:root, lineIterator:&lineIterator,
				keyIDsToKey:keyIDsToKey, reverse:reverse
			)
		case .valueType( _ ):
			try subFlatten(
				bodyElementMap: &map, parentElement:bodyElement, lineIterator:&lineIterator,
				keyIDsToKey:keyIDsToKey, reverse:reverse
			)
		default:
			break
		}
	}
	
	private static func subFlatten<T>(
		bodyElementMap map: inout [IntID : BodyElement], parentElement:BodyElement, lineIterator: inout T, keyIDsToKey:[IntID:String], reverse:Bool
	) throws where T:IteratorProtocol, T.Element == DataBlock {
		while let dataBlock = lineIterator.next() {
			guard dataBlock.blockType == .body else {
				throw GCodableError.internalInconsistency(
					Self.self, GCodableError.Context(
						debugDescription: "Unespected graph -\(dataBlock)-."
					)
				)
			}
			let bodyElement = BodyElement( dataBlock: dataBlock )
			
			if case .end = dataBlock {
				break
			} else {
				bodyElement.parentElement = parentElement
				
				if let keyID = dataBlock.keyID {
					guard let key = keyIDsToKey[keyID] else {
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
				
				try flatten( bodyElementMap: &map, bodyElement: bodyElement, lineIterator: &lineIterator, keyIDsToKey: keyIDsToKey, reverse: reverse )
			}
		}
		if reverse {
			parentElement.unkeyedValues.reverse()
		}
	}
}

// -------------------------------------------------
// ----- TypeConstructor
// -------------------------------------------------

fileprivate final class TypeConstructor {
	private enum SetterType {
		case object	( objID:IntID, setter:(AnyObject) throws -> () )
		case value	( setter:() throws -> () )
	}

	private var			decodedData			: DecodedData
	private (set) var 	currentBodyElement 	: BodyElement
	private (set) var 	currentInfo 		: ClassInfo?
	private var			objectRepository 	= [ IntID :AnyObject ]()
	private var			setterRepository 	= [ SetterType ]()

	init( decodedData:DecodedData ) {
		self.decodedData	= decodedData
		self.currentBodyElement	= decodedData.bodyRootElement
	}
	
	func decodeRoot<T>( _ type: T.Type, from decoder:GDecoder ) throws -> T where T:GCodable {
		let rootBlock		= currentBodyElement
		let value : T		= try decodeNode( bodyElement:rootBlock, from: decoder )
		try decodeDelayed()

		return value
	}
	
	private func decodeDelayed() throws {
		while setterRepository.isEmpty == false {
			switch setterRepository.removeLast() {
			case .object(objID: let objID, setter: let setter):
				guard let object = objectRepository[objID] else {
					throw GCodableError.internalInconsistency(
						Self.self, GCodableError.Context(
							debugDescription: "Object objID = \(objID) must exists."
						)
					)
				}
				try setter( object )
			case .value(setter: let setter):
				try setter()
			}
		}
	}

	func contains(key: String) -> Bool {
		currentBodyElement.contains(key: key)
	}
	
	func popBodyElement( key:String? = nil ) throws -> BodyElement {
		if let key = key {
			// keyed case
			guard let bodyElement = currentBodyElement.pop(key: key) else {
				throw GCodableError.childNotFound(
					Self.self, GCodableError.Context(
						debugDescription: "Keyed child for key-\(key)- not found in \(currentBodyElement.dataBlock)."
					)
				)
			}
			return bodyElement
		} else {
			guard let bodyElement = currentBodyElement.pop(key: nil) else {
				throw GCodableError.childNotFound(
					Self.self, GCodableError.Context(
						debugDescription: "Unkeyed child not found in \(currentBodyElement.dataBlock)."
					)
				)
			}
			return bodyElement
		}
	}
	
	private func classInfo( typeID:IntID ) throws -> ClassInfo {
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

	var replacedType : GCodableObsolete.Type? {
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
	
	func deferDecodeNode<T>( bodyElement:BodyElement, from decoder:GDecoder, _ setter: @escaping (T) -> () ) throws where T:GCodable {
		let saved	= (currentBodyElement, currentInfo)
		(currentBodyElement, currentInfo)	= (bodyElement, nil)
		defer { (currentBodyElement, currentInfo) = saved }

		switch bodyElement.dataBlock {
		case .objectSPtr( _, let objID ):
			//	con questo fallthrough scompare l'obbligo di impiegare
			//	encodeConditional per le variabili weak e tutto funziona,
			//	ma la cosa non ha logicamente senso perché se non sono
			//	tenute in vita da qualche strong path, diventerebbero
			//	comunque nulle non appena viene completato il decode.
			NSLog("You should always use encodeConditional() to encode a weak variable (\(bodyElement.dataBlock)).")
			fallthrough
		case .objectWPtr( _, let objID ):
			let anySetter : (AnyObject) throws -> () = {
				anyObject in
				guard let object = anyObject as? T else {
					throw GCodableError.typeMismatch(
						Self.self, GCodableError.Context(
							debugDescription: "Block \(bodyElement.dataBlock) doesn't contains -\(T.self)-."
						)
					)
				}
				setter( object )
			}
			
			setterRepository.append( .object(objID: objID, setter: anySetter) )			
		default:
			let anySetter : () throws -> () = {
				let value : T = try self.decodeNode( bodyElement:bodyElement, from:decoder )
				setter( value )
			}
			setterRepository.append( .value(setter: anySetter) )
		}
	}

	func decodeNode<T>( bodyElement:BodyElement, from decoder:GDecoder ) throws -> T where T:GCodable {
		func decodeAnyNode( bodyElement:BodyElement, from decoder:GDecoder ) throws -> Any {
			func decodeAnyObject( objID:IntID, from decoder:GDecoder ) throws -> AnyObject? {
				//	tutti gli oggetti (reference types) inizialmente si trovano in decodedData.objBlockMap
				//	quando arriva la prima richiesta di un particolare oggetto (da objID)
				//	lo costruiamo (se esiste) e lo mettiamo nell'objectRepository in modo
				//	che le richieste successive peschino di lì.
				//	se l'oggetto non esiste (possibile, se memorizzato condizionalmente)
				//	ritorniamo nil.
				
				if let object = objectRepository[ objID ] {
					return object
				} else if let bodyElement = decodedData.pop( objID: objID ) {
					//	gli unici blocchi possibili sono di tipo .Object
					switch bodyElement.dataBlock {
					case .objectType( _, let typeID, let objID ):
						let saved	= (currentBodyElement, currentInfo)
						(currentBodyElement, currentInfo)	= (bodyElement, try classInfo( typeID:typeID ))
						defer { (currentBodyElement, currentInfo) = saved }

						let object		= try currentInfo!.codableType.init(from: decoder)
						objectRepository[ objID ]	= object
						return object
					default:
						throw GCodableError.internalInconsistency(
							Self.self, GCodableError.Context(
								debugDescription: "Inappropriate bodyElement \(bodyElement.dataBlock) here."
							)
						)
					}
				} else {
					return nil
				}
			}
			
			switch bodyElement.dataBlock {
			case .nilValue( _ ):
				return Optional<Any>.none as Any
			case .objectWPtr( _, let objID ):
				// nessun controllo: può essere nil
				return try decodeAnyObject( objID:objID, from:decoder ) as Any
			case .objectSPtr( _, let objID ):
				guard let object = try decodeAnyObject( objID:objID, from:decoder ) else {
					throw GCodableError.decodingError(
						Self.self, GCodableError.Context(
							debugDescription:
								"Object pointed from -\(bodyElement.dataBlock)- not found." +
								"Use deferDecode to break the cycles."
						)
					)
				}
				return object
			default:	// .Struct & .Object are inappropriate here!
				throw GCodableError.internalInconsistency(
					Self.self, GCodableError.Context(
						debugDescription: "Inappropriate bodyElement \(bodyElement.dataBlock) here."
					)
				)
			}
		}
		
		let saved	= (currentBodyElement, currentInfo)
		(currentBodyElement, currentInfo)	= (bodyElement, nil)
		defer { (currentBodyElement, currentInfo) = saved }
		
		switch bodyElement.dataBlock {
		case .valueType( _ ):
			// if T is optional
			if let optType = T.self as? OptionalProtocol.Type {
				// get the inner non optional type
				let wrapped	= optType.fullUnwrappedType
				
				// check if conforms to GCodable.Type,
				// costruct the value and check if is T
				guard
					let decodableType = wrapped as? GCodable.Type,
					let value = try decodableType.init(from: decoder) as? T
				else {
					throw GCodableError.typeMismatch(
						Self.self, GCodableError.Context(
							debugDescription: "Block \(bodyElement) wrapped type -\(wrapped)- not GCodable."
						)
					)
				}
				
				return value
			} else { //	if not, construct it:
				return try T.init(from: decoder)
			}
		case .outBinType( _ , let bytes ):
			let wrapped : Any.Type

			if let optType = T.self as? OptionalProtocol.Type {
				// get the inner non optional type
				wrapped	= optType.fullUnwrappedType
			} else {
				wrapped	= T.self
			}

			guard
				let binaryIOType = wrapped as? BinaryIOType.Type,
				let value = try binaryIOType.init(binaryData: bytes) as? T
			else {
				throw GCodableError.typeMismatch(
					Self.self, GCodableError.Context(
						debugDescription: "Block \(bodyElement) wrapped type -\(wrapped)- not BinaryIOType."
					)
				)
			}
			return value
		default:
			guard let value = try decodeAnyNode( bodyElement:bodyElement, from:decoder ) as? T else {
				throw GCodableError.typeMismatch(
					Self.self, GCodableError.Context(
						debugDescription: "Block \(bodyElement) doesn't contains a -\(T.self)- type."
					)
				)
			}
			
			return value
		}
	}
}

