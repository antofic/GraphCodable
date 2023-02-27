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

final class GDecoderImpl : GDecoder {
	var	userInfo			= [String:Any]()
	private var constructor : TypeConstructor!

	func allClassData<Q>( from data: Q ) throws -> [ClassData]
	where Q:Sequence, Q.Element==UInt8 {
		let decodedNames		= try DecodedNames(from: data)
		
		return Array( decodedNames.classDataMap.values )
	}
	
	func decodeRoot<T,Q>( _ type: T.Type, from data: Q ) throws -> T
		where T:GDecodable, Q:Sequence, Q.Element==UInt8 {
		defer { constructor = nil }
		
		constructor	= TypeConstructor(decodedData: try DecodedData( from: data ))
		
		return try constructor.decodeRoot(type, from: self)
	}
	
	var encodedVersion : UInt32 {
		get throws { try constructor.encodedVersion }
	}

	var replacedType : GObsolete.Type?   {
		get throws { try constructor.replacedType }
	}
	
	// ------ keyed support
	
	func contains<Key>(_ key: Key) -> Bool
	where Key : RawRepresentable, Key.RawValue == String
	{
		constructor.contains(key: key.rawValue)
	}
	
	func decode<Key, Value>(for key: Key) throws -> Value
	where Key : RawRepresentable, Value : GDecodable, Key.RawValue == String
	{
		let	bodyElement = try constructor.popBodyElement( key:key.rawValue )
		
		return try constructor.decode( element:bodyElement, from: self )
	}
	
	func deferDecode<Key, Value>( for key: Key, _ setter: @escaping (Value) -> ()) throws
	where Key : RawRepresentable, Value : GDecodable, Key.RawValue == String
	{
		let	bodyElement = try constructor.popBodyElement( key:key.rawValue )

		try constructor.deferDecode( element:bodyElement, from: self, setter )
	}

	// ------ unkeyed support
	
	var unkeyedCount : Int {
		constructor.currentElement.unkeyedCount
	}
	
	func decode<Value>() throws -> Value where Value : GDecodable {
		let	bodyElement = try constructor.popBodyElement()

		return try constructor.decode( element:bodyElement, from: self )
	}
	
	func deferDecode<Value>(_ setter: @escaping (Value) -> ()) throws where Value : GDecodable {
		let	bodyElement = try constructor.popBodyElement()

		try constructor.deferDecode( element:bodyElement, from: self, setter )
	}
}

// -------------------------------------------------
// ----- DecodedData
// -------------------------------------------------

fileprivate struct DecodedData {
	let fileHeader			: FileHeader
	let	classInfoMap		: [UIntID:ClassInfo]
	let rootElement 		: BodyElement
	private var	elementMap	: [UIntID : BodyElement]
	
	init<Q>( from bytes:Q ) throws where Q:Sequence, Q.Element==UInt8 {
		var binaryDecoder	= try BinaryDecoder( from: bytes )
		let fileHeader		= binaryDecoder.fileHeader
		let bodyBlocks		= try binaryDecoder.bodyFileBlocks()
		let classInfoMap	= try binaryDecoder.classInfoMap()
		let keyStringMap	= try binaryDecoder.keyStringMap()
		
		self.fileHeader		= fileHeader
		self.classInfoMap	= classInfoMap
		(self.rootElement,self.elementMap)	= try BodyElement.rootElement(
			bodyBlocks:		bodyBlocks,
			keyStringMap:	keyStringMap,
			reverse:	true
		)
	}

	mutating func pop( objID:UIntID ) -> BodyElement? {
		elementMap.removeValue( forKey: objID )
	}
}

// -------------------------------------------------
// ----- DecodedNames
// -------------------------------------------------

fileprivate struct DecodedNames {
	let fileHeader				: FileHeader
	let	classDataMap			: ClassDataMap
	
	init<Q>( from data:Q ) throws where Q:Sequence, Q.Element==UInt8 {
		var binaryDecoder	= try BinaryDecoder( from: data )
		fileHeader			= binaryDecoder.fileHeader
		classDataMap		= try binaryDecoder.classDataMap()
	}
}

// -------------------------------------------------
// ----- BinaryDecoder
// -------------------------------------------------

fileprivate struct BinaryDecoder {
	private enum Decoder {
		case new( _ : SectionBinaryDecoder )		//	>=	SECTION_FILE_VERSION
		case old( _ : OldBinaryDecoder )			//	<	SECTION_FILE_VERSION
	}
	
	let 			fileHeader	: FileHeader
	private var  	decoder		: Decoder
	
	init<Q>( from data:Q ) throws where Q:Sequence, Q.Element==UInt8 {
		var reader 	= BinaryReadBuffer(data: data)

		fileHeader	= try FileHeader( from: &reader )
		if fileHeader.supportsFileSections {
			decoder	= .new( try SectionBinaryDecoder( from: &reader ) )
		} else {
			decoder	= .old( try OldBinaryDecoder( from: &reader ) )
		}
	}

	mutating func classDataMap() throws -> ClassDataMap {
		switch decoder {
		case .new( var decoder ): return try decoder.classDataMap()
		case .old( var decoder ): return try decoder.classDataMap()
		}
	}
	
	mutating func classInfoMap() throws -> [UIntID : ClassInfo] {
		try classDataMap().mapValues {  try ClassInfo(classData: $0)  }
	}

	mutating func bodyFileBlocks() throws -> BodyBlocks {
		switch decoder {
		case .new( var decoder ): return try decoder.bodyFileBlocks()
		case .old( var decoder ): return try decoder.bodyFileBlocks()
		}
	}

	mutating func keyStringMap() throws -> KeyStringMap {
		switch decoder {
		case .new( var decoder ): return try decoder.keyStringMap()
		case .old( var decoder ): return try decoder.keyStringMap()
		}
	}
	
	// -------------------------------------------------
	// ----- SinglePassSectionBinaryDecoder
	// -------------------------------------------------

	private struct SectionBinaryDecoder {
		private	var sectionMap			: SectionMap
		private var reader				: BinaryReadBuffer

		private var _classDataMap		: ClassDataMap?
		private var _bodyFileBlocks		: BodyBlocks?
		private var _keyStringMap		: KeyStringMap?
		
		init( from reader:inout BinaryReadBuffer ) throws {
			self.sectionMap		= try type(of:sectionMap).init(from: &reader)
			self.reader			= reader
		}

		mutating func classDataMap() throws -> ClassDataMap {
			if let classMap = _classDataMap { return classMap }
			
			let saveRegion	= try setReaderRegionTo(section: .classDataMap)
			defer { reader.currentRegion = saveRegion }

			_classDataMap	= try ClassDataMap(from: &reader)
			return _classDataMap!
		}
		
		mutating func bodyFileBlocks() throws -> BodyBlocks {
			if let bodyBlocks = _bodyFileBlocks { return bodyBlocks }

			let saveRegion	= try setReaderRegionTo(section: .body)
			defer { reader.currentRegion = saveRegion }

			var bodyBlocks	= [FileBlock]()
			while reader.isEof == false {
				bodyBlocks.append( try FileBlock(from: &reader) )
			}
			
			_bodyFileBlocks	= bodyBlocks
			return bodyBlocks
		}

		mutating func keyStringMap() throws -> KeyStringMap {
			if let keyStringMap = _keyStringMap { return keyStringMap }

			let saveRegion	= try setReaderRegionTo(section: .keyStringMap)
			defer { reader.currentRegion = saveRegion }
			
			_keyStringMap	= try KeyStringMap(from: &reader)
			return _keyStringMap!
		}
		
		private mutating func setReaderRegionTo( section:FileSection ) throws -> Range<Int> {
			guard let range = sectionMap[ section ] else {
				throw GCodableError.decodingError(
					Self.self, GCodableError.Context(
						debugDescription: "fileRange not found while body parsing."
					)
				)
			}
			defer { reader.currentRegion = range }
			return reader.currentRegion
		}
	}

	// -------------------------------------------------
	// ----- OldBinaryDecoder
	// -------------------------------------------------

	private struct OldBinaryDecoder {
		enum CompatibleFileBlock : BinaryIType {
			case current( fileBlock:FileBlock )
			case obsolete( fileBlock:FileBlockObsolete )

			init(from reader: inout BinaryReadBuffer) throws {
				var obsolete	= false
				let _ = FileBlockObsolete.peek(from: &reader) {
					_ in
					obsolete	= true
					return false
				}
				if obsolete {
					self	= .obsolete(fileBlock: try FileBlockObsolete(from: &reader))
				} else {
					self	= .current(fileBlock: try FileBlock(from: &reader))
				}
			}
		}
		
		private var reader				: BinaryReadBuffer

		private var _classDataMap		= ClassDataMap()
		private var _bodyFileBlocks		= BodyBlocks()
		private var _keyStringMap		= KeyStringMap()

		private var currentBlock		: CompatibleFileBlock?
		private var phase				: FileSection
		
		init( from reader:inout BinaryReadBuffer ) throws {
			self.reader		= reader
			self.phase		= .classDataMap
		}

		mutating func classDataMap() throws -> ClassDataMap {
			try parseTypeMap()
			return _classDataMap
		}

		mutating func bodyFileBlocks() throws -> BodyBlocks {
			try parseTypeMap()
			try parseBody()
			
			return _bodyFileBlocks
		}

		mutating func keyStringMap() throws -> KeyStringMap {
			try parseTypeMap()
			try parseBody()
			try parseKeyMap()

			return _keyStringMap
		}

		// private section
		
		private mutating func peek() throws -> CompatibleFileBlock? {
			if currentBlock == nil {
				currentBlock	= reader.isEof ? nil : try CompatibleFileBlock(from: &reader)
			}
			return currentBlock
		}

		private mutating func step() {
			currentBlock = nil
		}

		private mutating func parseTypeMap() throws {
			guard phase == .classDataMap else { return }

			while let compatibleBlock	= try peek() {
				switch compatibleBlock {
				case .obsolete( let dataBlock ):
					switch dataBlock {
					case .classDataMap( let typeID, let classData ):
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
				default:
					self.phase	= .body
					return
				}
				step()
			}
		}
		
		private mutating func parseBody() throws {
			guard phase == .body else { return }

			while let compatibleBlock	= try peek() {
				switch compatibleBlock {
				case .current( let dataBlock ):
					_bodyFileBlocks.append( dataBlock )
				default:
					self.phase	= .keyStringMap
					return
				}
				step()
			}
		}

		private mutating func parseKeyMap() throws {
			guard phase == .keyStringMap else { return }

			while let compatibleBlock	= try peek() {
				switch compatibleBlock {
				case .obsolete( let dataBlock ):
					switch dataBlock {
					case .keyStringMap( let keyID, let key ):
						guard _keyStringMap.index(forKey: keyID) == nil else {
							throw GCodableError.duplicateKey(
								Self.self, GCodableError.Context(
									debugDescription: "Key -\(key)- already used."
								)
							)
						}
						_keyStringMap[keyID]	= key
					default:
						return
					}
				default:
					return
				}
				step()
			}
		}

	}
	
}

// ------------------------------------------------------
// ------ final class BodyElement
// ------------------------------------------------------

fileprivate final class BodyElement {
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
			
			try subFlatten(
				elementMap: &map, parentElement:root, lineIterator:&lineIterator,
				keyStringMap:keyStringMap, reverse:reverse
			)
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
			
			try subFlatten(
				elementMap: &map, parentElement:root, lineIterator:&lineIterator,
				keyStringMap:keyStringMap, reverse:reverse
			)
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

// -------------------------------------------------
// ----- TypeConstructor
// -------------------------------------------------

fileprivate final class TypeConstructor {
	private var			decodedData			: DecodedData
	private (set) var 	currentElement 		: BodyElement
	private (set) var 	currentInfo 		: ClassInfo?
	private var			objectRepository 	= [ UIntID :Any ]()
	private var			setterRepository 	= [ () throws -> () ]()
	
	init( decodedData:DecodedData ) {
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
