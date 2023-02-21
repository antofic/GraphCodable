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

fileprivate protocol DataEncoder : AnyObject {
	init()
	func append( _ dataBlock:FileBlock ) throws
}

extension GraphEncoder {
	public struct DumpOptions: OptionSet {
		public let rawValue: UInt
		
		public init(rawValue: UInt) {
			self.rawValue	= rawValue
		}
		
		///	four data sections:
		public static let	showHeader						= Self( rawValue: 1 << 0 )
		public static let	showTypeMap						= Self( rawValue: 1 << 1 )
		public static let	showBody						= Self( rawValue: 1 << 2 )
		public static let	showKeyMap						= Self( rawValue: 1 << 3 )
		
		///	indent the data
		public static let	indentLevel						= Self( rawValue: 1 << 4 )
		///	in the Body section, resolve typeIDs in typeNames, keyIDs in keyNames
		public static let	resolveIDs						= Self( rawValue: 1 << 5 )
		///	in the Body section, show type versions (they are in the TypeMap section)
		public static let	showTypeVersion					= Self( rawValue: 1 << 6 )
		///	includes '=== SECTION TITLE =========================================='
		public static let	showSectionTitles				= Self( rawValue: 1 << 7 )
		///	disable truncation of too long nativeValues (over 48 characters - String or Data typically)
		public static let	noTruncation					= Self( rawValue: 1 << 8 )
		///	show NSStringFromClass name in TypeMap section
		public static let	showMangledClassNames			= Self( rawValue: 1 << 9 )

		public static let	displayNSStringFromClassNames: Self = [
			.showTypeMap, .showMangledClassNames, .showSectionTitles
		]
		public static let	readable: Self = [
			.showBody, .indentLevel, .resolveIDs, .showSectionTitles
		]
		public static let	readableNoTruncation: Self = [
			.showHeader, .showBody, .indentLevel, .resolveIDs, .showSectionTitles, .noTruncation
		]
		public static let	binaryLike: Self = [
			.showHeader, .showTypeMap, .showBody, .showKeyMap, .indentLevel, .showSectionTitles
		]
		public static let	binaryLikeNoTruncation: Self = [
			.showHeader, .showTypeMap, .showBody, .showKeyMap, .indentLevel, .showSectionTitles, .noTruncation
		]
		public static let	fullInfo: Self = [
			.showHeader, .showTypeMap, .showBody, .showKeyMap, .indentLevel, .resolveIDs, .showTypeVersion, .showSectionTitles, .noTruncation
		]
	}
}

public final class GraphEncoder {
	private let encoder	: Encoder
	
	public enum Options {
		case onlyNativeTypes, allBinaryTypes
		
		public static let defaultOption = Self.onlyNativeTypes
	}
	
	/// GraphEncoder init method
	public init( _ options: Options = .defaultOption ) {
		encoder	= Encoder( options )
	}

	///	Get/Set the userInfo dictionary
	public var userInfo : [String:Any] {
		get { encoder.userInfo }
		set { encoder.userInfo = newValue }
	}

	///	Encode the root value in a Data byte buffer
	///
	///	The root value must conform to the GCodable protocol
	public func encode<T>( _ value: T ) throws -> Data where T:GCodable {
		try encodeBytes( value )
	}

	///	Encode the root value in a generic byte buffer
	///
	///	The root value must conform to the GCodable protocol
	public func encodeBytes<T,Q>( _ value: T ) throws -> Q where T:GCodable, Q:MutableDataProtocol {
		try encoder.encodeRoot( value )
	}
	
	///	Creates a human-readable string of the data that would be generated by encoding the value
	///
	///	The root value must conform to the GCodable protocol
	public func dump<T>( _ value: T, options: GraphEncoder.DumpOptions = .readable ) throws -> String where T:GCodable {
		try encoder.dumpRoot( value, options:options )
	}
		
	// -------------------------------------------------
	// ----- Encoder
	// -------------------------------------------------
	
	private final class Encoder : GEncoder {
		var userInfo			= [String:Any]()
		typealias			IdentifierMap		= AnyIdentifierMap
		
		private let 		encodeOptions		: Options
		private var 		currentKeys			= Set<String>()
		private var			identifierMap		= IdentifierMap()
		private var			typeMap				= TypeMap()
		private var			keyMap				= KeyMap()
		private (set) var	dataEncoder			: DataEncoder!
		
		
		private func reset() {
			self.currentKeys	= Set<String>()
			self.identifierMap	= IdentifierMap()
			self.typeMap		= TypeMap()
			self.keyMap			= KeyMap()
			self.dataEncoder	= nil
		}
		
		// --------------------------------------------------------
		init( _ options: Options ) {
			self.encodeOptions	= options
		}
		
		func encodeRoot<T,Q>( _ value: T ) throws -> Q where T:GCodable, Q:MutableDataProtocol {
			defer { reset() }
			reset()
			
			dataEncoder	= ByteEncoder()
			try encode( value )
			
			return try (dataEncoder as! ByteEncoder).data(typeMap: typeMap, keyMap: keyMap)
		}
		
		func dumpRoot<T>( _ value: T, options: GraphEncoder.DumpOptions ) throws -> String where T:GCodable {
			defer { reset() }
			reset()
			
			dataEncoder	= StringEncoder()
			try encode( value )
			
			return try (dataEncoder as! StringEncoder).output(typeMap: typeMap, keyMap: keyMap, options: options)
		}
		
		// --------------------------------------------------------
		
		func encode<Value>(_ value: Value) throws where Value:GCodable {
			try encodeAnyValue( value, forKey: nil, conditional:false )
		}
		
		func encodeConditional<Value>(_ value: Value?) throws where Value:GCodable {
			try encodeAnyValue( value as Any, forKey: nil, conditional:true )
		}
		
		func encode<Key, Value>(_ value: Value, for key: Key) throws
		where Key : RawRepresentable, Value : GCodable, Key.RawValue == String
		{
			try encodeAnyValue( value, forKey: key.rawValue, conditional:false )
		}
		
		func encodeConditional<Key, Value>(_ value: Value?, for key: Key) throws
		where Key : RawRepresentable, Value : GCodable, Key.RawValue == String
		{
			try encodeAnyValue( value as Any, forKey: key.rawValue, conditional:true )
		}
		
		// --------------------------------------------------------
		
		private func encodeAnyValue(_ anyValue: Any, forKey key: String?, conditional:Bool ) throws {
			func gIdentifier( _ value:GCodable ) -> (any Hashable)? { return (value as? any GIdentifiable)?.gID }
			
			// trasformo in un Optional<Any> di un solo livello:
			let value	= Optional(fullUnwrapping: anyValue)
			let keyID	= try createKeyID( key: key )
			
			guard let value = value else {
				try dataEncoder.append( .nilValue(keyID: keyID) )
				return
			}
			// now value if not nil!
			
			if let object = value as? GCodable & AnyObject {	// reference type
				let identifier = gIdentifier( object ) ?? ObjectIdentifier( object )
				if let objID = identifierMap.strongID( identifier ) {
					// l'oggetto è stato già memorizzato, basta un pointer
					if conditional {
						try dataEncoder.append( .conditionalPtr(keyID: keyID, objID: objID) )
					} else {
						try dataEncoder.append( .strongPtr(keyID: keyID, objID: objID) )
					}
				} else if conditional {
					// Conditional Encoding: avrei la descrizione ma non la voglio usare
					// perché servirà solo se dopo arriverà da uno strongRef
					
					// Verifico comunque se l'oggetto è reificabile
					try ClassData.throwIfNotConstructible( type: type(of:object) )
					
					let objID	= identifierMap.createWeakID( identifier )
					try dataEncoder.append( .conditionalPtr(keyID: keyID, objID: objID) )
				} else {
					//	memorizzo il reference type
					let typeID	= try typeMap.createTypeIDIfNeeded(type:  type(of:object))
					let objID	= identifierMap.createStrongID( identifier )
					
					try dataEncoder.append( .referenceType(keyID: keyID, typeID: typeID, objID: objID) )
					try encodeValue( object )
					try dataEncoder.append( .end )
				}
			} else if let value = value as? GCodable {
				if let binaryValue = value as? NativeType {
					//	i tipi nativi sono semplici: l'identità non serve
					//	(e per le stringhe?)
					try dataEncoder.append( .binaryIN(keyID: keyID, value: binaryValue ) )
				} else if let identifier = gIdentifier( value ) {
					// il valore ha un identità
					if let objID = identifierMap.strongID( identifier ) {
						// l'oggetto è stato già memorizzato, basta un pointer
						if conditional {
							try dataEncoder.append( .conditionalPtr(keyID: keyID, objID: objID) )
						} else {
							try dataEncoder.append( .strongPtr(keyID: keyID, objID: objID) )
						}
					} else if conditional {
						// Conditional Encoding: avrei la descrizione ma non la voglio usare
						// perché servirà solo se dopo arriverà da uno strongRef
						let objID	= identifierMap.createWeakID( identifier )
						try dataEncoder.append( .conditionalPtr(keyID: keyID, objID: objID) )
					} else {
						//	memorizzo il value type
						let objID	= identifierMap.createStrongID( identifier )
						
						if encodeOptions == .allBinaryTypes, let binaryValue = value as? BinaryIOType {
							try dataEncoder.append( .iBinaryIN(keyID: keyID, objID: objID, value: binaryValue ) )
						} else {
							try dataEncoder.append( .iValueType(keyID: keyID, objID: objID) )
							try encodeValue( value )
							try dataEncoder.append( .end )
						}
					}
				} else if encodeOptions == .allBinaryTypes, let binaryValue = value as? BinaryIOType {
					try dataEncoder.append( .binaryIN(keyID: keyID, value: binaryValue ) )
				} else {
					//	valore senza identità
					try dataEncoder.append( .valueType( keyID: keyID ) )
					try encodeValue( value )
					try dataEncoder.append( .end )
				}
			} else {
				throw GCodableError.internalInconsistency(
					Self.self, GCodableError.Context(
						debugDescription: "Not GCodable value \(value)."
					)
				)
			}
		}
		
		private func encodeValue( _ value:GCodable ) throws {
			let savedKeys	= currentKeys
			defer { currentKeys = savedKeys }
			currentKeys.removeAll()
			
			try value.encode(to: self)
		}
		
		private func createKeyID( key: String? ) throws -> IntID {
			if let key = key {
				defer { currentKeys.insert( key ) }
				if currentKeys.contains( key ) {
					throw GCodableError.duplicateKey(
						Self.self, GCodableError.Context(
							debugDescription: "Key -\(key)- already used."
						)
					)
				}
				return keyMap.createKeyIDIfNeeded(key: key)
			} else {
				return 0	// unkeyed
			}
		}
	}
	
	// -------------------------------------------------
	// ----- StringEncoder: DataEncoder
	// -------------------------------------------------
	
	fileprivate final class StringEncoder : DataEncoder {
		struct	OutputInfo {
			let	typeMap	: TypeMap
			let	keyMap	: KeyMap
			let	options	: GraphEncoder.DumpOptions
		}
		
		let			fileHeader		= FileHeader(version: FileHeader.CURRENT_FILE_VERSION)
		private	var blocks			= [FileBlock]()
		
		init() {}
		
		func append( _ dataBlock:FileBlock ) throws {
			guard dataBlock.section == .body else {
				throw GCodableError.internalInconsistency(
					Self.self, GCodableError.Context(
						debugDescription: "Inappropriate section -\(dataBlock.section)- here."
					)
				)
			}
			blocks.append( dataBlock )
		}
		
		func output( typeMap:TypeMap, keyMap:KeyMap, options:GraphEncoder.DumpOptions ) throws -> String {
			let dumpInfo = DumpInfo(
				options:		options,
				classDataMap:	options.contains( .resolveIDs ) ? typeMap.typeIDtoClassData : nil,
				keyIDtoKey:		options.contains( .resolveIDs ) ? keyMap.keyIDtoKey : nil
			)
			
			var output = ""
			if options.contains( .showHeader ) {
				if options.contains( .showSectionTitles ) {
					output.append( "== HEADER ========================================================\n" )
				}
				output.append( fileHeader.description )
				output.append( "\n" )
			}
			if options.contains( .showTypeMap ) {
				if options.contains( .showSectionTitles ) {
					output.append( "== TYPEMAP =======================================================\n" )
				}
				output = typeMap.typeIDtoClassData.reduce( into: output ) {
					result, tuple in
					result.append(
						FileBlock.typeMap(
							typeID: tuple.key, classData: tuple.value
						).readableOutput(info: dumpInfo)
					)
					result.append( "\n" )
				}
			}
			if options.contains( .showBody ) {
				if options.contains( .showSectionTitles ) {
					output.append( "== BODY ==========================================================\n" )
				}
				
				var	tabs : String?	= options.contains( .indentLevel ) ? "" : nil
				
				output = blocks.reduce( into: output ) {
					result, block in
					
					if case .exit = block.level { tabs?.removeLast() }
					
					if let tbs = tabs { result.append( tbs ) }
					
					result.append( block.readableOutput(  info:dumpInfo ) )
					result.append( "\n" )
					
					if case .enter = block.level { tabs?.append("\t") }
					
				}
			}
			if options.contains( .showKeyMap ) {
				if options.contains( .showSectionTitles ) {
					output.append( "== KEYMAP ========================================================\n" )
				}
				output = keyMap.keyIDtoKey.reduce( into: output ) {
					result, tuple in
					result.append(
						FileBlock.keyMap(
							keyID:		tuple.key,
							keyName:	tuple.value
						).readableOutput(info: dumpInfo)
					)
					result.append( "\n" )
				}
			}
			if options.contains( .showSectionTitles ) {
				output.append( "==================================================================\n" )
			}
			return output
		}
	}
	
	// -------------------------------------------------
	// ----- ByteEncoder : DataEncoder
	// -------------------------------------------------
	
	fileprivate final class ByteEncoder : DataEncoder {
		let					fileHeader		= FileHeader(version: FileHeader.CURRENT_FILE_VERSION)
		private			var sectionMap		= [FileBlock.Section : Range<Int>]()
		private			var writer			= BinaryWriter()
		
		init() {}
		
		private func update() throws {
			if sectionMap.isEmpty {
				for section in FileBlock.Section.allCases {
					self.sectionMap[ section ] = Range(uncheckedBounds: (0,0))
				}
				try fileHeader.write(to: &writer)
				try sectionMap.write(to: &writer)
				sectionMap[ FileBlock.Section.body ] = Range(uncheckedBounds: (writer.position,writer.position))
			}
		}
		
		func append( _ dataBlock:FileBlock ) throws {
			try update()
			
			guard dataBlock.section == .body else {
				throw GCodableError.internalInconsistency(
					Self.self, GCodableError.Context(
						debugDescription: "Inappropriate section -\(dataBlock.section)- here."
					)
				)
			}
			try dataBlock.write(to: &writer)
		}
		
		func data<Q>( typeMap:TypeMap, keyMap:KeyMap ) throws -> Q where Q:MutableDataProtocol {
			try update()

			var bounds	= (sectionMap[ FileBlock.Section.body ]!.startIndex,writer.position)
			sectionMap[ FileBlock.Section.body ] = Range( uncheckedBounds:bounds )

			// typeMap:
			for (typeID,classData) in typeMap.typeIDtoClassData {
				try FileBlock.typeMap( typeID: typeID, classData: classData ).write(to: &writer)
			}
			bounds	= ( bounds.1,writer.position )
			sectionMap[ FileBlock.Section.typeMap ] = Range( uncheckedBounds:bounds )

			// keyMap:
			for (keyID,key) in keyMap.keyIDtoKey {
				try FileBlock.keyMap(keyID: keyID, keyName: key).write(to: &writer)
			}
			bounds	= ( bounds.1,writer.position )
			sectionMap[ FileBlock.Section.keyMap ] = Range( uncheckedBounds:bounds )

			do {
				defer { writer.setEof() }
				writer.position	= 0
				try fileHeader.write(to: &writer)
				try sectionMap.write(to: &writer)
			}
			
			return writer.data()
		}
	}
	
	// -------------------------------------------------
	// ----- TypeMap
	// -------------------------------------------------
	
	fileprivate struct TypeMap {
		private	var			currentId : IntID	= 1000	// ATT! 0-999 future use
		private (set) var	typeIDtoClassData	= [ IntID: ClassData ]()
		private var			typeToTypeID		= [ ObjectIdentifier: IntID ]()
		
		mutating func createTypeIDIfNeeded( type:(AnyObject & GCodable).Type ) throws -> IntID {
			let objIdentifier	= ObjectIdentifier( type )
			
			if let typeID = typeToTypeID[ objIdentifier ] {
				return typeID
			} else {
				defer { currentId += 1 }
				
				let typeID = currentId
				typeIDtoClassData[ typeID ]	= try ClassData( type: type )
				typeToTypeID[ objIdentifier ] = typeID
				return typeID
			}
		}
	}
	
	// -------------------------------------------------
	// ----- KeyMap
	// -------------------------------------------------
	
	fileprivate struct KeyMap  {
		private	var			currentId : IntID	= 1000	// ATT! 0 reserved for unkeyed coding / 1-999 future use
		private (set) var	keyIDtoKey			= [IntID: String]()
		private var			keyToKeyID			= [String: IntID]()
		
		mutating func createKeyIDIfNeeded( key:String ) -> IntID {
			if let keyID = keyToKeyID[ key ] {
				return keyID
			} else {
				let keyID = currentId
				defer { currentId += 1 }
				keyToKeyID[ key ]	= keyID
				keyIDtoKey[ keyID ] = key
				return keyID
			}
		}
	}
	
	// -------------------------------------------------
	// ----- AnyIdentifierMap
	// -------------------------------------------------
	
	fileprivate struct AnyIdentifierMap {
		private struct Key : Hashable {
			private let identifier : any Hashable
			
			init<T:Hashable>( _ identifier: T ) {
				self.identifier		= identifier
			}
			
			private static func equal<T,Q>( lhs: T, rhs: Q ) -> Bool where T:Equatable, Q:Equatable {
				guard let rhs = rhs as? T else { return false }
				return lhs == rhs
			}
			
			static func == (lhs: Self, rhs: Self) -> Bool {
				return equal(lhs: lhs.identifier, rhs: rhs.identifier)
			}
			
			func hash(into hasher: inout Hasher) {
				hasher.combine( ObjectIdentifier( type( of:identifier) ) )
				hasher.combine( identifier )
			}
		}
		
		private	var actualId : IntID	= 1000	// <1000 reserved for future use
		private var	strongObjDict		= [Key:IntID]()
		private var	weakObjDict			= [Key:IntID]()
		
		func strongID<T:Hashable>( _ identifier: T ) -> IntID? {
			strongObjDict[ Key(identifier) ]
		}
		
		mutating func createWeakID<T:Hashable>( _ identifier: T ) -> IntID {
			let box	= Key(identifier)
			if let objID = weakObjDict[ box ] {
				return objID
			} else {
				let objID = actualId
				defer { actualId += 1 }
				weakObjDict[ box ] = objID
				return objID
			}
		}
		
		mutating func createStrongID<T:Hashable>( _ identifier: T ) -> IntID {
			let key	= Key(identifier)
			if let objID = strongObjDict[ key ] {
				return objID
			} else if let objID = weakObjDict[key] {
				// se è nel weak dict, lo prendo da lì
				weakObjDict.removeValue(forKey: key)
				// e lo metto nello strong dict
				strongObjDict[key] = objID
				return objID
			} else {
				// altrimenti creo uno nuovo
				let objID = actualId
				defer { actualId += 1 }
				strongObjDict[key] = objID
				return objID
			}
		}
	}
}





