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

	public var userInfo : [String:Any] {
		get { return decoder.userInfo }
		set { decoder.userInfo = newValue }
	}

	public func decode<T>( _ type: T.Type, from data: Data ) throws -> T  where T:GDecodable {
		return try decoder.decodeRoot( type, from: data)
	}

	public func encodedTypeNames( from data: Data ) throws -> [String] {
		return try decoder.storedTypesAndVersions( from:data ).map { $0.typeName }
	}

	public func help( from data: Data, initializeFuncName:String = "initializeGraphCodable" ) throws -> String {
		return GTypesRepository.swiftRegisterFunc(
			typeNameVersions:	try decoder.storedTypesAndVersions(from: data),
			initializeFuncName:	initializeFuncName,
			showVersions: 		true
		)
	}
	
	private let decoder = Decoder()
	
	// -------------------------------------------------
	// ----- Decoder
	// -------------------------------------------------
	
	private final class Decoder : GOptionalDecoder {		
		var	userInfo			= [String:Any]()
		
		func storedTypesAndVersions( from: Data ) throws -> [TypeNameVersion] {
			var reader				= BinaryReader(data: from)
			let decodedTypes		= try DecodedTypes(from: &reader)
			let shared				= GTypesRepository.shared
			let typeNameVersions	= decodedTypes.typeIDtoName.values.filter() {
				shared.nativeType(typeName: $0.typeName) == nil
			}
			
			return Array( typeNameVersions )
		}
		
		func decodeRoot<T>( _ type: T.Type, from data: Data ) throws -> T  where T:GDecodable {
			defer { _costructor = nil }
			
			var reader		= BinaryReader(data: data)
			
			constructor	= TypeConstructor(decodedData: try DecodedData( from: &reader ))
			
			return try constructor.decodeRoot(type, from: self)
		}
		
		// ------ keyed support
		
		func encodedVersion<T>( _ type: T.Type ) throws -> UInt32  where T:GDecodable {
			return try constructor.encodedVersion( type )
		}
		
		// ------ keyed support
		
		func contains<Key>(_ key: Key) throws -> Bool
		where Key : RawRepresentable, Key.RawValue == String
		{
			return try constructor.contains(key: key.rawValue)
		}
		
		func decode<Key, Value>(for key: Key) throws -> Value
		where Key : RawRepresentable, Value : GEncodable, Key.RawValue == String
		{
			let	block = try constructor.popNode( key:key.rawValue )
			
			guard let	value = try constructor.decodeNode( block:block, from: self ) as? Value else {
				throw GCodableError.typeMismatch(dataBlock: block.dataBlock)
			}
			
			return value
		}
		
		func deferDecode<Key, Value>( for key: Key, _ setter: @escaping (Value?) -> ()) throws
		where Key : RawRepresentable, Value : AnyObject, Value : GEncodable, Key.RawValue == String
		{
			try constructor.decodeNode( graphBlock:try constructor.popNode( key:key.rawValue ), setter )
		}

		// ------ unkeyed support
		
		func unkeyedCount() throws -> Int {
			return constructor.currentBlock.unkeyedCount
		}
		
		func decode<Value>() throws -> Value where Value : GDecodable {
			let	block = try constructor.popNode()
			guard let value = try constructor.decodeNode( block:block, from: self ) as? Value else {
				throw GCodableError.typeMismatch(dataBlock: block.dataBlock)
			}
			
			return value
		}
		
		func deferDecode<Value>(_ setter: @escaping (Value?) -> ()) throws where Value : GDecodable, Value : AnyObject {
			try constructor.decodeNode( graphBlock:try constructor.popNode(), setter )
		}
		
		func decodeNil() throws -> Bool {
			guard let isNil = constructor.currentBlock.popIfNil() else {
				throw GCodableError.unkeyedChildNotFound( parentDataBlock: constructor.currentBlock.dataBlock )
			}
			return isNil
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
	let	typeIDtoName			: [IntID:TypeNameVersion]
	let rootBlock 				: GraphBlock
	private var	objBlockMap		: [IntID : GraphBlock]
	
	init( from reader:inout BinaryReader ) throws {
		var blockDecoder = BlockDecoder( from: &reader )
		
		(fileVersion,encodedMainModule)	= try blockDecoder.fileVersionAndMainModule()
		typeIDtoName					= try blockDecoder.typeIDtoName()
		(rootBlock,objBlockMap)			= try blockDecoder.rootBlock()
	}
	
	mutating func pop( objID:IntID ) -> GraphBlock? {
		return objBlockMap.removeValue( forKey: objID )
	}
}

// -------------------------------------------------
// ----- DecodedTypes
// -------------------------------------------------

fileprivate struct DecodedTypes {
	let fileVersion				: UInt32
	let encodedMainModule		: String
	let	typeIDtoName			: [IntID:TypeNameVersion]
	
	init( from reader:inout BinaryReader ) throws {
		var blockDecoder = BlockDecoder( from: &reader )
		
		(fileVersion,encodedMainModule)	= try blockDecoder.fileVersionAndMainModule()
		typeIDtoName					= try blockDecoder.typeIDtoName()
	}
}


// -------------------------------------------------
// ----- BlockDecoder
// -------------------------------------------------

fileprivate struct BlockDecoder {
	private var reader				: BinaryReader
	private var currentBlock		: DataBlock?
	private var phase				: DataBlock.BlockType
	
	private var _fileVersion		= UInt32(0)
	private var _encodedMainModule	= ""
	private var _typeIDtoName		= [IntID : TypeNameVersion]()
	private var _graphDataBlocks	= [DataBlock]()
	private var _keyIDToKey			= [IntID:String]()
	
	init( from reader:inout BinaryReader ) {
		self.reader				= reader
		self.phase				= .header
	}

	private mutating func peek() throws -> DataBlock? {
		if currentBlock == nil {
			currentBlock	= reader.eof ? nil : try DataBlock.read(from: &reader, typeIDtoName: _typeIDtoName )
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
			case .Header( let version, let module, _ /*unused1*/, _ /*unused2*/ ):
				_encodedMainModule	= module
				_fileVersion		= version
			default:
				self.phase	= .typeMap
				return
			}
			step()
		}
	}
	
	private mutating func parseTypeIDs() throws {
		guard phase == .typeMap else { return }

		while let dataBlock	= try peek() {
			switch dataBlock {
			case .TypeMap( let typeID, let typeVersion, let typeName ):
				// ••• PHASE 1 •••
				guard _typeIDtoName.index(forKey: typeID) == nil else {
					throw GCodableError.duplicateTypeID( typeID:typeID )
				}
				// Qui interroghiamo il register!
				_typeIDtoName[typeID]	= TypeNameVersion(
					typeName:	try GTypesRepository.shared.replaceEncodedTypenameIfNeeded(typeName: typeName),
					version:	typeVersion
				)
			default:
				self.phase	= .graph
				return
			}
			step()
		}
	}
	
	private mutating func parseGraph() throws {
		guard phase == .graph else { return }

		var firstBlock = true
		while let dataBlock	= try peek() {
			guard dataBlock.blockType == .graph else {
				self.phase	= .keyMap
				return
			}
			if firstBlock {
				firstBlock = false

				// controllo che tutti i typeNames siano nel registro
				let shared				= GTypesRepository.shared
				let unregisteredTypes	= _typeIDtoName.values.filter() {
					shared.nativeType(typeName: $0.typeName) == nil &&
					shared.decodableType(typeName: $0.typeName) == nil
				}
				
				if unregisteredTypes.isEmpty == false {
					throw GCodableError.unregisteredTypes( typeNames:unregisteredTypes.map { $0.typeName } )
				}
			}
			_graphDataBlocks.append( dataBlock )
			step()
		}
	}

	private mutating func parseKeys() throws {
		guard phase == .keyMap else { return }

		while let dataBlock	= try peek() {
			switch dataBlock {
			case .KeyMap( let keyID, let key ):
				// ••• PHASE 3 •••
				guard _keyIDToKey.index(forKey: keyID) == nil else {
					throw GCodableError.duplicateKey( key:key )
				}
				_keyIDToKey[keyID]	= key
			default:
				return
			}
			step()
		}
	}

	mutating func fileVersionAndMainModule() throws -> (UInt32,String) {
		try parseHeader()
		return (_fileVersion,_encodedMainModule)
	}

	mutating func typeIDtoName() throws -> [IntID : TypeNameVersion] {
		try parseHeader()
		try parseTypeIDs()
		return _typeIDtoName
	}

	mutating func rootBlock() throws -> ( root:GraphBlock, objBlockMap:[IntID : GraphBlock] ) {
		try parseHeader()
		try parseTypeIDs()
		try parseGraph()
		try parseKeys()
		
		var map = [IntID : GraphBlock]()
		guard let root = try GraphBlock(
				blocks: _graphDataBlocks, objBlockMap:&map, keyIDsToKey:_keyIDToKey, reverse: true
		) else {
			throw GCodableError.rootNotFound
		}
		return (root, map)
	}
}

// ------------------------------------------------------
// ------ final class GraphBlock
// ------------------------------------------------------

fileprivate final class GraphBlock {
	init?<S>( blocks:S, objBlockMap map: inout [IntID : GraphBlock], keyIDsToKey:[IntID:String], reverse:Bool ) throws
	where S:Sequence, S.Element == DataBlock {
		var lineIterator = blocks.makeIterator()
		
		if let dataBlock = lineIterator.next() {
			guard dataBlock.level != .exit else { throw GCodableError.invalidRootLevel }
			self.dataBlock	= dataBlock
			
			try Self.flatten( objBlockMap: &map, block: self, lineIterator: &lineIterator, keyIDsToKey:keyIDsToKey, reverse: reverse )
		} else {
			return nil
		}
	}
	
	//	----------------------------------------------------------------
	
	private(set) weak var	parent 			: GraphBlock?
	private(set) var		dataBlock		: DataBlock
	private		var			keyedValues		= [String:GraphBlock]()
	private		var 		unkeyedValues 	= [GraphBlock]()
	
	var keyedCount : Int {
		return keyedValues.count
	}
	
	var unkeyedCount : Int {
		return unkeyedValues.count
	}
	
	func contains( key:String ) -> Bool {
		return keyedValues.index(forKey: key) != nil
	}
	
	func pop( key:String? ) -> GraphBlock? {
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
	
	private init( dataBlock:DataBlock ) {
		self.dataBlock	= dataBlock
	}
		
	private static func flatten<T>(
		objBlockMap map: inout [IntID : GraphBlock], block:GraphBlock, lineIterator: inout T, keyIDsToKey:[IntID:String], reverse:Bool
	) throws where T:IteratorProtocol, T.Element == DataBlock {
		switch block.dataBlock {
		case .Object( let keyID, let typeID, let objID ):
			//	l'oggetto non può trovarsi nella map
			guard map.index(forKey: objID) == nil else {
				throw GCodableError.objectAlreadyExists( dataBlock: block.dataBlock )
			}
			
			//	trasformo l'oggetto in uno strong pointer
			//	così la procedura di lettura incontrerà quello al posto dell'oggetto
			block.dataBlock	= .ObjSPtr( keyID: keyID, objID: objID )
			
			//	e per l'oggetto dovrà andare a vedere nella map, in modo che si possano
			//	beccare gli oggetti memorizzati dopo!
			let root		= GraphBlock( dataBlock: .Object(keyID: keyID, typeID: typeID, objID: objID) )
			map[ objID ]	= root
			
			try subFlatten(
				objBlockMap: &map, parent:root, lineIterator:&lineIterator,
				keyIDsToKey:keyIDsToKey, reverse:reverse
			)
		case .Struct( _,_ ):
			try subFlatten(
				objBlockMap: &map, parent:block, lineIterator:&lineIterator,
				keyIDsToKey:keyIDsToKey, reverse:reverse
			)
		default:
			break
		}
	}
	
	private static func subFlatten<T>(
		objBlockMap map: inout [IntID : GraphBlock], parent:GraphBlock, lineIterator: inout T, keyIDsToKey:[IntID:String], reverse:Bool
	) throws where T:IteratorProtocol, T.Element == DataBlock {
		while let dataBlock = lineIterator.next() {
			guard dataBlock.blockType == .graph else {
				throw GCodableError.unespectedDataBlockInThisPhase
			}
			let block = GraphBlock( dataBlock: dataBlock )
			
			if case .End = dataBlock {
				break
			} else {
				block.parent = parent
				
				if let keyID = dataBlock.keyID {
					guard let key = keyIDsToKey[keyID] else {
						throw GCodableError.keyNotFound( keyID:keyID )
					}
					if parent.keyedValues.index(forKey: key) == nil {
						parent.keyedValues[ key ] = block
					} else {
						throw GCodableError.duplicateKey( key:key )
					}
				} else {
					parent.unkeyedValues.append( block )
				}
				
				try flatten( objBlockMap: &map, block: block, lineIterator: &lineIterator, keyIDsToKey: keyIDsToKey, reverse: reverse )
			}
		}
		if reverse {
			parent.unkeyedValues.reverse()
		}
	}

}

// -------------------------------------------------
// ----- DecodeConstructor
// -------------------------------------------------

fileprivate final class TypeConstructor {
	init( decodedData:DecodedData ) {
		self.decodedData	= decodedData
		self.currentBlock	= decodedData.rootBlock
	}
	
	func decodeRoot<T>( _ type: T.Type, from decoder:GDecoder ) throws -> T {
		let rootBlock		= currentBlock
		guard let value		= try decodeNode( block:rootBlock, from: decoder ) as? T else {
			throw GCodableError.cantDecodeRoot( dataBlock:rootBlock.dataBlock )
		}
		try decodeDelayed()
		return value
	}
	
	private var			decodedData			: DecodedData
	private (set) var 	currentBlock 		: GraphBlock
	private var			objectRepository 	= [IntID:AnyObject]()
	private var			deferredRepository 	= [IntID:[(AnyObject) throws -> ()]]()
	private lazy var	typeNameToID	 	: [String:IntID] = {
		var tnToID = [String:IntID]()
		for (id,typeNameVersion) in decodedData.typeIDtoName {
			tnToID[ typeNameVersion.typeName ] = id
		}
		return tnToID
	}()
	
	func decodeDelayed() throws {
		for (objID,setters) in deferredRepository {
			// solo se sono stati salvati!
			if let anyValue = objectRepository[objID] {
				for setter in setters {
					try setter( anyValue )
				}
			}
		}
	}
	
	func contains(key: String) throws -> Bool {
		return currentBlock.contains(key: key)
	}
	
	func popNode( key:String? = nil ) throws -> GraphBlock {
		if let key = key {
			// keyed case
			guard let	block = currentBlock.pop(key: key) else {
				throw GCodableError.keyedChildNotFound( parentDataBlock: currentBlock.dataBlock )
			}
			return block
		} else {
			guard let	block = currentBlock.pop(key: nil) else {
				throw GCodableError.unkeyedChildNotFound( parentDataBlock: currentBlock.dataBlock )
			}
			return block
		}
	}
	
	private func typeNameVersion( typeID:IntID ) throws -> TypeNameVersion {
		guard let typeName = decodedData.typeIDtoName[ typeID ] else {
			throw GCodableError.typeNameNotFound( typeID:typeID )
		}
		return typeName
	}
	
	func encodedVersion<T>( _ type: T.Type ) throws -> UInt32  where T:GDecodable {
		let typeName	= GTypesRepository.shared.typeName(type: type)
		guard let typeID = typeNameToID[typeName] else {
			throw GCodableError.decodedDataDontContainsTypeName( typeName:typeName )
		}
		return try typeNameVersion(typeID: typeID).version
	}
	
	
	func decodeObject( objID:IntID, from decoder:GDecoder ) throws -> AnyObject? {
		//	tutti gli oggetti (reference types) inizialmente si trovano in decodedData.objBlockMap
		//	quando arriva la prima richiesta di un particolare oggetto (da objID)
		//	lo costruiamo (se esiste) e lo mettiamo nell'objectRepository in modo
		//	che le richieste successive peschino di lì.
		//	se l'oggetto non esiste (possibile, se memorizzato condizionalmente)
		//	ritorniamo nil.
		
		if let object = objectRepository[ objID ] {
			return object
		} else if let block = decodedData.pop( objID: objID ) {
			//	gli unici blocchi possibili sono di tipo .Object
			switch block.dataBlock {
			case .Object( _, let typeID, let objID ):
				let saveCurrent = currentBlock
				currentBlock	= block
				defer { currentBlock = saveCurrent }
				
				let	typeName	= try typeNameVersion( typeID:typeID ).typeName
				guard let type	= GTypesRepository.shared.decodableType( typeName:typeName ) else {
					throw GCodableError.typeNotFoundInRegister( typeName: typeName )
				}
				let value		= try type.init(from: decoder)
				
				objectRepository[ objID ]	= value as AnyObject
				return value as AnyObject
			default:
				throw GCodableError.inappropriateDataBlock( dataBlock:block.dataBlock )
			}
		} else {
			return nil
		}
	}
	
	func decodeNode( block:GraphBlock, from decoder:GDecoder ) throws -> Any {
		let saveCurrent = currentBlock
		currentBlock	= block
		defer { currentBlock = saveCurrent }
		
		switch block.dataBlock {
		case .Nil( _ ):
			let x : Any? = nil
			return x as Any
		case .Native( _, _, let value ):
			return value
		case .Struct( _, let typeID ):
			let	typeName	= try typeNameVersion( typeID:typeID ).typeName
			guard let type	= GTypesRepository.shared.decodableType( typeName:typeName ) else {
				throw GCodableError.typeNotFoundInRegister( typeName: typeName )
			}
			let value		= try type.init(from: decoder)

			return value
		case .ObjWPtr( _, let objID ):
			// nessun controllo: può essere nil!
			return try decodeObject( objID:objID, from:decoder ) as Any
		case .ObjSPtr( _, let objID ):
			guard let anyObject = try decodeObject( objID:objID, from:decoder ) else {
				throw GCodableError.pointerNotFound( dataBlock:block.dataBlock )
			}
			return anyObject
		default:	// .Object is inappropriate, too!
			throw GCodableError.inappropriateDataBlock( dataBlock:block.dataBlock )
		}
	}
	
	func decodeNode<T>( graphBlock:GraphBlock, _ setter: @escaping (T?) -> () ) throws {
		let saveCurrent = currentBlock
		currentBlock	= graphBlock
		defer { currentBlock = saveCurrent }
		
		switch graphBlock.dataBlock {
		case .Nil( _ ):
			setter( nil )
		case .ObjWPtr( _, let objID ):
			let anySetter : (AnyObject) throws -> () = {
				anyValue in
				guard let value = anyValue as? T else {
					throw GCodableError.deferredTypeMismatch( dataBlock:graphBlock.dataBlock )
				}
				setter( value )
			}
			
			if var array = deferredRepository[ objID ] {
				array.append( anySetter )
				deferredRepository[ objID ]	= array
			} else {
				deferredRepository[ objID ] = [ anySetter ]
			}
		default:
			throw GCodableError.inappropriateDataBlock( dataBlock:graphBlock.dataBlock )
		}
	}

}
