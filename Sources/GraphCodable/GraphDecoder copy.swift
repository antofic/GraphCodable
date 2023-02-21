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

	///	Decode the root value from the data byte buffer
	///
	///	The root value must conform to the GCodable protocol
	public func decode<T,Q>( _ type: T.Type, from data: Q ) throws -> T
		where T:GCodable, Q:Sequence, Q.Element==UInt8 {
		try decoder.decodeRoot( type, from: data)
	}

	///	Returns all the classes encoded in the data byte buffer
	public func decodableClasses<Q>( from data: Q ) throws -> [(AnyObject & GCodable).Type]
		where Q:Sequence, Q.Element==UInt8 {
		let types	= try decoder.allClassData( from: data ).compactMap { $0.codableType }
		let keys	= types.map { ObjectIdentifier($0) }
		let map		= Dictionary( zip(keys,types) ) { v1,v2 in v1 }
		return Array( map.values )
	}

	///	Returns all the obsolete classes encoded in the data byte buffer
	public func obsoleteClasses<Q>( from data: Q ) throws -> [GCodableObsolete.Type]
		where Q:Sequence, Q.Element==UInt8 {
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

		func allClassData<Q>( from data: Q ) throws -> [ClassData]
		where Q:Sequence, Q.Element==UInt8 {
			var reader				= BinaryReader(data: data)
			let decodedNames		= try DecodedNames(from: &reader)
			
			return Array( decodedNames.classDataMap.values )
		}
		
		func decodeRoot<T,Q>( _ type: T.Type, from data: Q ) throws -> T
			where T:GCodable, Q:Sequence, Q.Element==UInt8 {
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
			
			return try constructor.decode( element:bodyElement, from: self )
		}
		
		func deferDecode<Key, Value>( for key: Key, _ setter: @escaping (Value) -> ()) throws
		where Key : RawRepresentable, Value : GCodable, Key.RawValue == String
		{
			let	bodyElement = try constructor.popBodyElement( key:key.rawValue )

			try constructor.deferDecode( element:bodyElement, from: self, setter )
		}

		// ------ unkeyed support
		
		var unkeyedCount : Int {
			constructor.currentBodyElement.unkeyedCount
		}
		
		func decode<Value>() throws -> Value where Value : GCodable {
			let	bodyElement = try constructor.popBodyElement()

			return try constructor.decode( element:bodyElement, from: self )
		}
		
		func deferDecode<Value>(_ setter: @escaping (Value) -> ()) throws where Value : GCodable {
			let	bodyElement = try constructor.popBodyElement()

			try constructor.deferDecode( element:bodyElement, from: self, setter )
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
	let fileHeader				: FileHeader
	let	classInfoMap			: [IntID:ClassInfo]
	let bodyRootElement 		: BodyElement
	private var	bodyElementMap	: [IntID : BodyElement]
	
	init( from reader:inout BinaryReader ) throws {
		var blockDecoder = try BlockDecoder( from: &reader )
		
		fileHeader							= blockDecoder.fileHeader
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
	let fileHeader				: FileHeader
	let	classDataMap			: [IntID:ClassData]
	
	init( from reader:inout BinaryReader ) throws {
		var blockDecoder = try BlockDecoder( from: &reader )
		
		fileHeader		= blockDecoder.fileHeader
		classDataMap	= try blockDecoder.classDataMap()
	}
}

// -------------------------------------------------
// ----- BlockDecoder
// -------------------------------------------------

fileprivate struct BlockDecoder {
	let 		fileHeader			: FileHeader

	private var reader				: BinaryReader
	private var currentBlock		: FileBlock?
	private var phase				: FileBlock.Section?

	private var _classDataMap		= [IntID : ClassData]()
	private var _bodyDataBlocks		= [FileBlock]()
	private var _keyIDToKey			= [IntID:String]()

	private	var sectionMap			= [FileBlock.Section : Range<Int>]()

	private	var parsedTypeMap		= false
	private	var parsedBody			= false
	private	var parsedKeyMap		= false

	
	init( from reader:inout BinaryReader ) throws {
		let header		= try FileHeader( from: &reader )
		if header.supportsFileSections {
			// read section map
			sectionMap	= try type(of:sectionMap).init(from: &reader)
		} else {
			self.phase		= .typeMap
		}
		
		self.reader		= reader
		self.fileHeader	= header
	}

	mutating func classDataMap() throws -> [IntID : ClassData] {
		try parseTypeMap()
		return _classDataMap
	}

	mutating func classInfoMap() throws -> [IntID : ClassInfo] {
		try classDataMap().mapValues {  try ClassInfo(classData: $0)  }
	}
	
	mutating func bodyRootElement() throws -> ( bodyRootElement:BodyElement, bodyElementMap:[IntID : BodyElement] ) {
		try parseTypeMap()
		try parseBody()
		try parseKeyMap()
		
		return try BodyElement.bodyRootElement( bodyDataBlocks:_bodyDataBlocks, keyIDToKey:_keyIDToKey, reverse:true )
	}

	// private section
	
	private mutating func peek() throws -> FileBlock? {
		if currentBlock == nil {
			currentBlock	= reader.isEof ? nil : try FileBlock(from: &reader, header: fileHeader)
		}
		return currentBlock
	}

	private mutating func step() {
		currentBlock = nil
	}

	private mutating func parseTypeMap() throws {
		if parsedTypeMap { return }
		defer { parsedTypeMap = true }
		
		if fileHeader.supportsFileSections {
			guard let range = sectionMap[ FileBlock.Section.typeMap ] else {
				throw GCodableError.decodingError(
					Self.self, GCodableError.Context(
						debugDescription: "fileRange not found while typeMap parsing."
					)
				)
			}
			let saveRange	= reader.readRange
			defer { reader.readRange = saveRange }
			reader.readRange = range
			
			while let dataBlock	= try peek() {
				switch dataBlock {
				case .typeMap( let typeID, let classData ):
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
					throw GCodableError.decodingError(
						Self.self, GCodableError.Context(
							debugDescription: "\(dataBlock.self) encountered while typeMap parsing."
						)
					)
				}
				step()
			}
		} else if let phase = phase {
			guard phase == .typeMap else { return }
			
			while let dataBlock	= try peek() {
				switch dataBlock {
				case .typeMap( let typeID, let classData ):
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
		} else {
			throw GCodableError.decodingError(
				Self.self, GCodableError.Context(
					debugDescription: "decodingError while typeMap parsing."
				)
			)
		}
	}
	
	private mutating func parseBody() throws {
		if parsedBody { return }
		defer { parsedBody = true }

		if fileHeader.supportsFileSections {
			guard let range = sectionMap[ FileBlock.Section.body ] else {
				throw GCodableError.decodingError(
					Self.self, GCodableError.Context(
						debugDescription: "fileRange not found while body parsing."
					)
				)
			}
			let saveRange	= reader.readRange
			defer { reader.readRange = saveRange }
			reader.readRange = range
			
			while let dataBlock	= try peek() {
				guard dataBlock.section == .body else {
					throw GCodableError.decodingError(
						Self.self, GCodableError.Context(
							debugDescription: "\(dataBlock.self) encountered while body parsing."
						)
					)
				}
				_bodyDataBlocks.append( dataBlock )
				step()
			}
		} else if let phase = phase {
			guard phase == .body else { return }
			
			while let dataBlock	= try peek() {
				guard dataBlock.section == .body else {
					self.phase	= .keyMap
					return
				}
				_bodyDataBlocks.append( dataBlock )
				step()
			}
		} else {
			throw GCodableError.decodingError(
				Self.self, GCodableError.Context(
					debugDescription: "decodingError while body parsing."
				)
			)
		}
	}

	private mutating func parseKeyMap() throws {
		if parsedKeyMap { return }
		defer { parsedKeyMap = true }
		
		if fileHeader.supportsFileSections {
			guard let range = sectionMap[ FileBlock.Section.keyMap ] else {
				throw GCodableError.decodingError(
					Self.self, GCodableError.Context(
						debugDescription: "fileRange not found while body parsing."
					)
				)
			}
			let saveRange	= reader.readRange
			defer { reader.readRange = saveRange }
			reader.readRange = range
			
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
					throw GCodableError.decodingError(
						Self.self, GCodableError.Context(
							debugDescription: "\(dataBlock.self) encountered while keyMap parsing."
						)
					)
				}
				step()
			}
		} else if let phase = phase {
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
			
		} else {
			throw GCodableError.decodingError(
				Self.self, GCodableError.Context(
					debugDescription: "decodingError while keyMap parsing."
				)
			)
		}
	}
}

// -------------------------------------------------
// ----- NewBlockDecoder
// -------------------------------------------------

fileprivate struct NewBlockDecoder {
	let 		fileHeader			: FileHeader

	private var reader				: BinaryReader
	private var currentBlock		: FileBlock?

	private var _classDataMap		= [IntID : ClassData]()
	private var _bodyDataBlocks		= [FileBlock]()
	private var _keyIDToKey			= [IntID:String]()

	private	var sectionMap			= [FileBlock.Section : Range<Int>]()

	private	var parsedTypeMap		= false
	private	var parsedBody			= false
	private	var parsedKeyMap		= false

	
	init( from reader:inout BinaryReader ) throws {
		let header		= try FileHeader( from: &reader )
		if header.supportsFileSections {
			// read section map
			sectionMap	= try type(of:sectionMap).init(from: &reader)
		} else {
			;	// OLD BLOCK DECODER
		}
		
		self.reader		= reader
		self.fileHeader	= header
	}

	mutating func classDataMap() throws -> [IntID : ClassData] {
		try parseTypeMap()
		return _classDataMap
	}

	mutating func classInfoMap() throws -> [IntID : ClassInfo] {
		try classDataMap().mapValues {  try ClassInfo(classData: $0)  }
	}
	
	mutating func bodyRootElement() throws -> ( bodyRootElement:BodyElement, bodyElementMap:[IntID : BodyElement] ) {
		try parseTypeMap()
		try parseBody()
		try parseKeyMap()
		
		return try BodyElement.bodyRootElement( bodyDataBlocks:_bodyDataBlocks, keyIDToKey:_keyIDToKey, reverse:true )
	}

	// private section
	
	private mutating func peek() throws -> FileBlock? {
		if currentBlock == nil {
			currentBlock	= reader.isEof ? nil : try FileBlock(from: &reader, header: fileHeader)
		}
		return currentBlock
	}

	private mutating func step() {
		currentBlock = nil
	}

	private mutating func parseTypeMap() throws {
		if parsedTypeMap { return }
		defer { parsedTypeMap = true }
		
		if fileHeader.supportsFileSections {
			guard let range = sectionMap[ FileBlock.Section.typeMap ] else {
				throw GCodableError.decodingError(
					Self.self, GCodableError.Context(
						debugDescription: "fileRange not found while typeMap parsing."
					)
				)
			}
			let saveRange	= reader.readRange
			defer { reader.readRange = saveRange }
			reader.readRange = range
			
			while let dataBlock	= try peek() {
				switch dataBlock {
				case .typeMap( let typeID, let classData ):
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
					throw GCodableError.decodingError(
						Self.self, GCodableError.Context(
							debugDescription: "\(dataBlock.self) encountered while typeMap parsing."
						)
					)
				}
				step()
			}
		} else if let phase = phase {
			guard phase == .typeMap else { return }
			
			while let dataBlock	= try peek() {
				switch dataBlock {
				case .typeMap( let typeID, let classData ):
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
		} else {
			throw GCodableError.decodingError(
				Self.self, GCodableError.Context(
					debugDescription: "decodingError while typeMap parsing."
				)
			)
		}
	}
	
	private mutating func parseBody() throws {
		if parsedBody { return }
		defer { parsedBody = true }

		if fileHeader.supportsFileSections {
			guard let range = sectionMap[ FileBlock.Section.body ] else {
				throw GCodableError.decodingError(
					Self.self, GCodableError.Context(
						debugDescription: "fileRange not found while body parsing."
					)
				)
			}
			let saveRange	= reader.readRange
			defer { reader.readRange = saveRange }
			reader.readRange = range
			
			while let dataBlock	= try peek() {
				guard dataBlock.section == .body else {
					throw GCodableError.decodingError(
						Self.self, GCodableError.Context(
							debugDescription: "\(dataBlock.self) encountered while body parsing."
						)
					)
				}
				_bodyDataBlocks.append( dataBlock )
				step()
			}
		} else if let phase = phase {
			guard phase == .body else { return }
			
			while let dataBlock	= try peek() {
				guard dataBlock.section == .body else {
					self.phase	= .keyMap
					return
				}
				_bodyDataBlocks.append( dataBlock )
				step()
			}
		} else {
			throw GCodableError.decodingError(
				Self.self, GCodableError.Context(
					debugDescription: "decodingError while body parsing."
				)
			)
		}
	}

	private mutating func parseKeyMap() throws {
		if parsedKeyMap { return }
		defer { parsedKeyMap = true }
		
		if fileHeader.supportsFileSections {
			guard let range = sectionMap[ FileBlock.Section.keyMap ] else {
				throw GCodableError.decodingError(
					Self.self, GCodableError.Context(
						debugDescription: "fileRange not found while body parsing."
					)
				)
			}
			let saveRange	= reader.readRange
			defer { reader.readRange = saveRange }
			reader.readRange = range
			
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
					throw GCodableError.decodingError(
						Self.self, GCodableError.Context(
							debugDescription: "\(dataBlock.self) encountered while keyMap parsing."
						)
					)
				}
				step()
			}
		} else if let phase = phase {
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
			
		} else {
			throw GCodableError.decodingError(
				Self.self, GCodableError.Context(
					debugDescription: "decodingError while keyMap parsing."
				)
			)
		}
	}
}




// ------------------------------------------------------
// ------ final class BodyElement
// ------------------------------------------------------

fileprivate final class BodyElement {
	private weak var	parentElement 	: BodyElement?
	private(set) var	dataBlock		: FileBlock
	private		var		keyedValues		= [String:BodyElement]()
	private		var 	unkeyedValues 	= [BodyElement]()
	
	static func bodyRootElement<S>(
		bodyDataBlocks:S, keyIDToKey:[IntID:String], reverse:Bool
	) throws -> ( bodyRootElement: BodyElement, bodyElementMap: [IntID : BodyElement] )
	where S:Sequence, S.Element == FileBlock {
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
	where S:Sequence, S.Element == FileBlock {
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
			
			try Self.flatten( bodyElementMap: &map, bodyElement: self, lineIterator: &lineIterator, keyIDToKey:keyIDToKey, reverse: reverse )
		} else {
			return nil
		}
	}

	private init( dataBlock:FileBlock ) {
		self.dataBlock	= dataBlock
	}

	private static func flatten<T>(
		bodyElementMap map: inout [IntID : BodyElement], bodyElement:BodyElement, lineIterator: inout T, keyIDToKey:[IntID:String], reverse:Bool
	) throws where T:IteratorProtocol, T.Element == FileBlock {
		switch bodyElement.dataBlock {
		case .referenceType( let keyID, let typeID, let objID ):
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
			bodyElement.dataBlock	= .strongPtr( keyID: keyID, objID: objID )
			
			//	e per l'oggetto dovrà andare a vedere nella map, in modo che si possano
			//	beccare gli oggetti memorizzati dopo!
			let root		= BodyElement( dataBlock: .referenceType(keyID: keyID, typeID: typeID, objID: objID) )
			map[ objID ]	= root
			
			try subFlatten(
				bodyElementMap: &map, parentElement:root, lineIterator:&lineIterator,
				keyIDsToKey:keyIDToKey, reverse:reverse
			)
		case .iValueType( let keyID, let objID ):
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
			bodyElement.dataBlock	= .strongPtr( keyID: keyID, objID: objID )
			
			//	e per l'oggetto dovrà andare a vedere nella map, in modo che si possano
			//	beccare gli oggetti memorizzati dopo!
			let root		= BodyElement( dataBlock: .iValueType(keyID: keyID, objID: objID) )
			map[ objID ]	= root
			
			try subFlatten(
				bodyElementMap: &map, parentElement:root, lineIterator:&lineIterator,
				keyIDsToKey:keyIDToKey, reverse:reverse
			)
		case .iBinaryOUT( let keyID, let objID, let bytes ):
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
			bodyElement.dataBlock	= .strongPtr( keyID: keyID, objID: objID )
			
			//	e per l'oggetto dovrà andare a vedere nella map, in modo che si possano
			//	beccare gli oggetti memorizzati dopo!
			let root		= BodyElement( dataBlock: .iBinaryOUT(keyID: keyID, objID: objID, bytes:bytes ) )
			map[ objID ]	= root
			
			try subFlatten(
				bodyElementMap: &map, parentElement:root, lineIterator:&lineIterator,
				keyIDsToKey:keyIDToKey, reverse:reverse
			)
		case .valueType( _ ):
			try subFlatten(
				bodyElementMap: &map, parentElement:bodyElement, lineIterator:&lineIterator,
				keyIDsToKey:keyIDToKey, reverse:reverse
			)
		default:
			//	nothing to do
			break
		}
	}
	
	private static func subFlatten<T>(
		bodyElementMap map: inout [IntID : BodyElement], parentElement:BodyElement, lineIterator: inout T, keyIDsToKey:[IntID:String], reverse:Bool
	) throws where T:IteratorProtocol, T.Element == FileBlock {
		while let dataBlock = lineIterator.next() {
			guard dataBlock.section == .body else {
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
				
				try flatten( bodyElementMap: &map, bodyElement: bodyElement, lineIterator: &lineIterator, keyIDToKey: keyIDsToKey, reverse: reverse )
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
	private (set) var 	currentBodyElement 	: BodyElement
	private (set) var 	currentInfo 		: ClassInfo?
	private var			objectRepository 	= [ IntID :Any ]()
	private var			setterRepository 	= [ () throws -> () ]()
	
	init( decodedData:DecodedData ) {
		self.decodedData	= decodedData
		self.currentBodyElement	= decodedData.bodyRootElement
	}
	
	func decodeRoot<T>( _ type: T.Type, from decoder:GDecoder ) throws -> T where T:GCodable {
		let rootBlock		= currentBodyElement
		let value : T		= try decode( element:rootBlock, from: decoder )
		
		// decode dalayed
		while setterRepository.isEmpty == false {
			let setter = setterRepository.removeLast()
			try setter()
		}

		return value
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
	
	func deferDecode<T>( element:BodyElement, from decoder:GDecoder, _ setter: @escaping (T) -> () ) throws where T:GCodable {
		let setter : () throws -> () = {
			let value : T = try self.decode( element:element, from:decoder )
			setter( value )
		}
		setterRepository.append( setter )
	}
	
	func decode<T>( element:BodyElement, from decoder:GDecoder ) throws -> T where T:GCodable {
		let saved	= (currentBodyElement, currentInfo)
		defer { (currentBodyElement, currentInfo) = saved }
		
		(currentBodyElement, currentInfo)	= (element, nil)
		
		switch element.dataBlock {
		case .valueType( _ ):
			return try decodeValue( type:T.self, element:element, from: decoder )
		case .binaryOUT( _ , let bytes ):
			return try decodeBinaryIO( type:T.self, bytes: bytes, element:element, from: decoder )
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
	
	private func decodeValue<T>( type:T.Type, element:BodyElement, from decoder:GDecoder ) throws -> T where T:GCodable {
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
						debugDescription: "Block \(element) wrapped type -\(wrapped)- not GCodable."
					)
				)
			}
			return value
		} else { //	if not, construct it:
			return try T.init(from: decoder)
		}
	}
	
	private func decodeBinaryIO<T>( type:T.Type, bytes: [UInt8],element:BodyElement, from decoder:GDecoder ) throws -> T where T:GCodable {
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
					debugDescription: "Block \(element) wrapped type -\(wrapped)- not BinaryIOType."
				)
			)
		}
		return value
	}
	
	private func decodeAny<T>( element:BodyElement, from decoder:GDecoder, type:T.Type ) throws -> Any where T:GCodable {
		func decodeIdentifiables( type:T.Type, objID:IntID, element:BodyElement, from decoder:GDecoder ) throws -> Any? {
			//	tutti gli oggetti (reference types) inizialmente si trovano in decodedData.objBlockMap
			//	quando arriva la prima richiesta di un particolare oggetto (da objID)
			//	lo costruiamo (se esiste) e lo mettiamo nell'objectRepository in modo
			//	che le richieste successive peschino di lì.
			//	se l'oggetto non esiste (possibile, se memorizzato condizionalmente)
			//	ritorniamo nil.
			
			if let object = objectRepository[ objID ] {
				return object
			} else if let bodyElement = decodedData.pop( objID: objID ) {
				let saved	= (currentBodyElement, currentInfo)
				defer { (currentBodyElement, currentInfo) = saved }
				
				switch bodyElement.dataBlock {
				case .referenceType( _, let typeID, let objID ):
					(currentBodyElement, currentInfo)	= (bodyElement, try classInfo( typeID:typeID ))
					
					let object		= try currentInfo!.codableType.init(from: decoder)
					objectRepository[ objID ]	= object
					return object
				case .iValueType( _, let objID ):
					(currentBodyElement, currentInfo)	= (bodyElement, nil)
					
					let object		= try decodeValue( type:T.self, element:bodyElement, from: decoder )
					objectRepository[ objID ]	= object
					return object
				case .iBinaryOUT( _, let objID, let bytes):
					(currentBodyElement, currentInfo)	= (bodyElement, nil)

					let object		= try decodeBinaryIO( type:T.self, bytes: bytes,element:bodyElement, from:decoder )
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
		
		switch element.dataBlock {
		case .nilValue( _ ):
			return Optional<Any>.none as Any
		case .conditionalPtr( _, let objID ):
			// nessun controllo: può essere nil
			return try decodeIdentifiables( type:T.self, objID:objID, element:element, from:decoder ) as Any
		case .strongPtr( _, let objID ):
			// controllo: NON può essere nil
			guard let object = try decodeIdentifiables( type:T.self, objID:objID, element:element, from:decoder ) else {
				throw GCodableError.decodingError(
					Self.self, GCodableError.Context(
						debugDescription:
							"Object pointed from -\(element.dataBlock)- not found." +
						"Use deferDecode to break the cycles."
					)
				)
			}
			return object
		default:	// .Struct & .Object are inappropriate here!
			throw GCodableError.internalInconsistency(
				Self.self, GCodableError.Context(
					debugDescription: "Inappropriate bodyElement \(element.dataBlock) here."
				)
			)
		}
	}
}


