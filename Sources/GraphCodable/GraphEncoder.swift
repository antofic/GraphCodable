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
// ----- GraphEncoder - dump extension
// -------------------------------------------------

extension GraphEncoder {
	public struct DumpOptions: OptionSet {
		public let rawValue: UInt
		
		public init(rawValue: UInt) {
			self.rawValue	= rawValue
		}
		
		///	four data sections:
		public static let	showHeader						= Self( rawValue: 1 << 0 )
		public static let	showReferenceMap				= Self( rawValue: 1 << 1 )
		public static let	showBody						= Self( rawValue: 1 << 2 )
		public static let	showKeyMap						= Self( rawValue: 1 << 3 )
		
		///	indent the data
		public static let	indentLevel						= Self( rawValue: 1 << 4 )
		///	in the Body section, resolve typeIDs in typeNames, keyIDs in keyNames
		public static let	resolveIDs						= Self( rawValue: 1 << 5 )
		///	in the Body section, show type versions (they are in the ReferenceMap section)
		public static let	showReferenceVersion					= Self( rawValue: 1 << 6 )
		///	includes '=== SECTION TITLE =========================================='
		public static let	showSectionTitles				= Self( rawValue: 1 << 7 )
		///	disable truncation of too long nativeValues (over 48 characters - String or Data typically)
		public static let	noTruncation					= Self( rawValue: 1 << 8 )
		///	show typeName/NSStringFromClass name in ReferenceMap section
		public static let	showMangledClassNames			= Self( rawValue: 1 << 9 )
		
		public static let	displayNSStringFromClassNames: Self = [
			.showReferenceMap, .showMangledClassNames, .showSectionTitles
		]
		public static let	readable: Self = [
			.showBody, .indentLevel, .resolveIDs, .showSectionTitles
		]
		public static let	readableNoTruncation: Self = [
			.showHeader, .showBody, .indentLevel, .resolveIDs, .showSectionTitles, .noTruncation
		]
		public static let	binaryLike: Self = [
			.showHeader, .showReferenceMap, .showBody, .showKeyMap, .indentLevel, .showSectionTitles
		]
		public static let	binaryLikeNoTruncation: Self = [
			.showHeader, .showReferenceMap, .showBody, .showKeyMap, .indentLevel, .showSectionTitles, .noTruncation
		]
		public static let	fullInfo: Self = [
			.showHeader, .showReferenceMap, .showBody, .showKeyMap, .indentLevel, .resolveIDs, .showReferenceVersion, .showSectionTitles, .noTruncation
		]
	}
	
	///	Creates a human-readable string of the data that would be generated by encoding the value
	///
	///	The root value must conform to the GCodable protocol
	public func dump<T>( _ value: T, options: GraphEncoder.DumpOptions = .readable ) throws -> String where T:GCodable {
		try encoder.dumpRoot( value, options:options )
	}
}

// -------------------------------------------------
// ----- BinaryEncoderDelegate
// -------------------------------------------------

fileprivate protocol BinaryEncoderDelegate : AnyObject {
	var	classDataMap:	ClassDataMap { get }
	var	keyStringMap:	KeyStringMap { get }
	var dumpOptions:	GraphEncoder.DumpOptions { get }
}

// -------------------------------------------------
// ----- GraphEncoder
// -------------------------------------------------

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
			
	// -------------------------------------------------
	// ----- Encoder
	// -------------------------------------------------
	
	private final class Encoder : GEncoder, BinaryEncoderDelegate {
		var userInfo							= [String:Any]()
		typealias			IdentifierMap		= AnyIdentifierMap
		
		private let 		encodeOptions		: Options
		private var 		currentKeys			= Set<String>()
		private var			identifierMap		= IdentifierMap()
		private var			referenceMap		= ReferenceMap()
		private var			keyMap				= KeyMap()
		private (set) var	dumpOptions			= GraphEncoder.DumpOptions.readable
		private (set) var	dataEncoder			= BinaryEncoder<Encoder>(isDump: false)
		
		var classDataMap: ClassDataMap 	{ referenceMap.classDataMap }
		var keyStringMap: KeyStringMap 	{ keyMap.keyStringMap }
		
		private func reset( dump: Bool = false, dumpOptions:GraphEncoder.DumpOptions = .readable ) {
			self.currentKeys			= Set<String>()
			self.identifierMap			= IdentifierMap()
			self.referenceMap			= ReferenceMap()
			self.keyMap					= KeyMap()
			self.dumpOptions			= dumpOptions
			self.dataEncoder			= BinaryEncoder<Encoder>(isDump: dump)
			self.dataEncoder.delegate	= self
			
		}
		
		// --------------------------------------------------------
		init( _ options: Options ) {
			self.encodeOptions			= options
			self.dataEncoder.delegate	= self
		}
		
		func encodeRoot<T,Q>( _ value: T ) throws -> Q where T:GCodable, Q:MutableDataProtocol {
			defer { reset() }
			reset()
			
			try encode( value )

			return try dataEncoder.data()
		}
		
		func dumpRoot<T>( _ value: T, options: GraphEncoder.DumpOptions ) throws -> String where T:GCodable {
			defer { reset() }
			reset( dump: true, dumpOptions:options )
			
			try encode( value )
			
			return try dataEncoder.dump()
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
				try dataEncoder.appendNilValue(keyID: keyID)
				return
			}
			// now value if not nil!
			
			if let object = value as? GCodable & AnyObject {	// reference type
				let identifier = gIdentifier( object ) ?? ObjectIdentifier( object )
				if let objID = identifierMap.strongID( identifier ) {
					// l'oggetto è stato già memorizzato, basta un pointer
					if conditional {
						try dataEncoder.appendConditionalPtr(keyID: keyID, objID: objID)
					} else {
						try dataEncoder.appendStrongPtr(keyID: keyID, objID: objID)
					}
				} else if conditional {
					// Conditional Encoding: avrei la descrizione ma non la voglio usare
					// perché servirà solo se dopo arriverà da uno strongRef
					
					// Verifico comunque se l'oggetto è reificabile
					try ClassData.throwIfNotConstructible( type: type(of:object) )
					
					let objID	= identifierMap.createWeakID( identifier )
					try dataEncoder.appendConditionalPtr(keyID: keyID, objID: objID)
				} else {
					//	memorizzo il reference type
					let typeID	= try referenceMap.createTypeIDIfNeeded(type:  type(of:object))
					let objID	= identifierMap.createStrongID( identifier )
					
					try dataEncoder.appendReferenceType(keyID: keyID, typeID: typeID, objID: objID)
					try encodeValue( object )
					try dataEncoder.appendEnd()
				}
			} else if let value = value as? GCodable {
				if let binaryValue = value as? NativeType {
					//	i tipi nativi sono semplici: l'identità non serve
					//	(e per le stringhe?)
					try dataEncoder.appendBinaryValue(keyID: keyID, value: binaryValue )
				} else if let identifier = gIdentifier( value ) {
					// il valore ha un identità
					if let objID = identifierMap.strongID( identifier ) {
						// l'oggetto è stato già memorizzato, basta un pointer
						if conditional {
							try dataEncoder.appendConditionalPtr(keyID: keyID, objID: objID)
						} else {
							try dataEncoder.appendStrongPtr(keyID: keyID, objID: objID)
						}
					} else if conditional {
						// Conditional Encoding: avrei la descrizione ma non la voglio usare
						// perché servirà solo se dopo arriverà da uno strongRef
						let objID	= identifierMap.createWeakID( identifier )
						try dataEncoder.appendConditionalPtr(keyID: keyID, objID: objID)
					} else {
						//	memorizzo il value type
						let objID	= identifierMap.createStrongID( identifier )
						
						if encodeOptions == .allBinaryTypes, let binaryValue = value as? BinaryIOType {
							try dataEncoder.appendIBinaryValue(keyID: keyID, objID: objID, value: binaryValue )
						} else {
							try dataEncoder.appendIValueType(keyID: keyID, objID: objID)
							try encodeValue( value )
							try dataEncoder.appendEnd()
						}
					}
				} else if encodeOptions == .allBinaryTypes, let binaryValue = value as? BinaryIOType {
					try dataEncoder.appendBinaryValue(keyID: keyID, value: binaryValue )
				} else {
					//	valore senza identità
					try dataEncoder.appendValueType( keyID: keyID )
					try encodeValue( value )
					try dataEncoder.appendEnd()
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
		
		private func createKeyID( key: String? ) throws -> UIntID {
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
	// ----- SinglePassBinaryEncoder
	// -------------------------------------------------
	fileprivate final class BinaryEncoder<Provider:BinaryEncoderDelegate> {
		let					fileHeader	= FileHeader()
		let					isDump		: Bool
		weak var			delegate	: Provider?
		private var			writer		= BinaryWriter()
		private var			output		= String()

		init( isDump: Bool ) {
			self.isDump		= isDump
		}
		
		func appendBinaryValue( keyID:UIntID, value:BinaryOType ) throws {
			let bytes	= try value.binaryData() as Bytes
			try append( .binaryData(keyID: keyID, bytes: bytes), value:value  )
		}
		func appendIBinaryValue( keyID:UIntID, objID:UIntID, value:BinaryOType ) throws {
			let bytes	= try value.binaryData() as Bytes
			try append( .iBinaryData(keyID: keyID, objID: objID, bytes: bytes), value:value )
		}
		func appendNilValue( keyID:UIntID ) throws {
			try append( .nilValue(keyID: keyID) )
		}
		func appendValueType( keyID:UIntID ) throws {
			try append( .valueType(keyID: keyID) )
		}
		func appendIValueType( keyID:UIntID, objID:UIntID ) throws {
			try append( .iValueType(keyID: keyID, objID: objID) )
		}
		func appendReferenceType( keyID:UIntID, typeID:UIntID, objID:UIntID )throws {
			try append( .referenceType(keyID: keyID, typeID: typeID, objID: objID) )
		}
		func appendStrongPtr( keyID:UIntID, objID:UIntID ) throws {
			try append( .strongPtr(keyID: keyID, objID: objID) )
		}
		func appendConditionalPtr( keyID:UIntID, objID:UIntID ) throws {
			try append( .conditionalPtr(keyID: keyID, objID: objID) )
		}
		func appendEnd() throws {
			try append( .end )
		}
		
		//	low level
		private func append( _ fileBlock: FileBlock, value:BinaryOType? = nil ) throws {
			if isDump	{ try appendDumpString( fileBlock, binaryValue:value ) }
			else		{ try appendBinaryData( fileBlock ) }
		}

		//	------------------------------------------------------------
		//	--	DUMP section
		//	------------------------------------------------------------
		private var dumpStart	= false
		private var tabs		: String?
		
		private func dumpInit() throws {
			if dumpStart == false {
				dumpStart	= true
				
				let options	= delegate?.dumpOptions ?? .readable
				
				if options.contains( .showHeader ) {
					if options.contains( .showSectionTitles ) {
						output.append( "== HEADER ========================================================\n" )
					}
					output.append( fileHeader.description )
					output.append( "\n" )
				}
				
				if options.contains( .showBody ) {
					if options.contains( .showSectionTitles ) {
						output.append( "== BODY ==========================================================\n" )
					}
					tabs = options.contains( .indentLevel ) ? "" : nil
				}
			}
		}
		
		private func appendDumpString( _ fileBlock: FileBlock, binaryValue:BinaryOType? ) throws {
			try dumpInit()
			let options	= delegate?.dumpOptions ?? .readable

			if options.contains( .showBody ) {
				if case .exit = fileBlock.level { tabs?.removeLast() }
				if let tbs = tabs { output.append( tbs ) }
				
				output.append( fileBlock.readableOutput(
						options:		options,
						binaryValue:	binaryValue,
						classDataMap:	delegate?.classDataMap,
						keyStringMap:	delegate?.keyStringMap
				) )
				output.append( "\n" )
				
				if case .enter = fileBlock.level { tabs?.append("\t") }
			}
		}

		func dump() throws -> String {
			func typeString( _ options:GraphEncoder.DumpOptions, _ classData:ClassData ) -> String {
				var string	= "\(classData.readableTypeName) V\(classData.encodeVersion)"
				if options.contains( .showMangledClassNames ) {
					string.append( "\n\t\t\tMangledName = \( classData.mangledTypeName ?? "nil" )"  )
					string.append( "\n\t\t\tNSTypeName  = \( classData.objcTypeName )"  )
				}
				return string
			}
			
			guard isDump == true else {
				throw GCodableError.internalInconsistency(
					Self.self, GCodableError.Context(
						debugDescription: "Invalis if isDump = \(isDump)."
					)
				)
			}
			
			try dumpInit()
			let options	= delegate?.dumpOptions ?? .readable

			if options.contains( .showReferenceMap ) {
				if options.contains( .showSectionTitles ) {
					output.append( "== REFERENCEMAP ==================================================\n" )
				}
				output = delegate?.classDataMap.reduce( into: output ) {
					result, tuple in
					result.append( "TYPE\( tuple.key ):\t\( typeString( options, tuple.value ) )\n")
				} ?? "UNAVAILABLE DELEGATE \(#function)\n"
			}
			
			if options.contains( .showKeyMap ) {
				if options.contains( .showSectionTitles ) {
					output.append( "== KEYMAP ========================================================\n" )
				}
				output = delegate?.keyStringMap.reduce( into: output ) {
					result, tuple in
					result.append( "KEY\( tuple.key ):\t\"\( tuple.value )\"\n" )
				} ?? "UNAVAILABLE DELEGATE \(#function)\n"
			}
			if options.contains( .showSectionTitles ) {
				output.append( "==================================================================\n" )
			}
			
			return output
		}
		//	------------------------------------------------------------
		//	--	DATA section
		//	------------------------------------------------------------
		private var sectionMap			= SectionMap()
		private var	sectionMapPosition	= 0

		private func writeInit() throws {
			if sectionMap.isEmpty {
				// entriamo la prima volta e quindi scriviamo header e section map.

				// write header:
				try fileHeader.write(to: &writer)
				sectionMapPosition	= writer.position

				// write section map:
				for section in FileSection.allCases {
					sectionMap[ section ] = Range(uncheckedBounds: (0,0))
				}
				try sectionMap.write(to: &writer)
				let bounds	= (writer.position,writer.position)
				sectionMap[ FileSection.body ] = Range( uncheckedBounds:bounds )
			}
		}
		
		private func appendBinaryData( _ fileBlock: FileBlock ) throws {
			try writeInit()
			try fileBlock.write(to: &writer)
		}

		func data<Q>() throws -> Q where Q:MutableDataProtocol {
			guard isDump == false else {
				throw GCodableError.internalInconsistency(
					Self.self, GCodableError.Context(
						debugDescription: "Invalis if isDump = \(isDump)."
					)
				)
			}
			
			try writeInit()
			
			var bounds	= (sectionMap[.body]!.startIndex,writer.position)
			sectionMap[.body]	= Range( uncheckedBounds:bounds )
			
			// referenceMap:
			try delegate!.classDataMap.write(to: &writer)
			bounds	= ( bounds.1,writer.position )
			sectionMap[ FileSection.classDataMap ] = Range( uncheckedBounds:bounds )

			// keyStringMap:
			try delegate!.keyStringMap.write(to: &writer)
			bounds	= ( bounds.1,writer.position )
			sectionMap[ FileSection.keyStringMap ] = Range( uncheckedBounds:bounds )

			do {
				//	sovrascrivo la sectionMapPosition
				//	ora che ho tutti i valori
				defer { writer.setEof() }
				writer.position	= sectionMapPosition
				try sectionMap.write(to: &writer)
			}
			
			return writer.data()
		}
		
	}
	
	// -------------------------------------------------
	// ----- ReferenceMap
	// -------------------------------------------------
	
	fileprivate struct ReferenceMap {
		private	var			currentId : UIntID	= 1000	// ATT! 0-999 future use
		private (set) var	classDataMap	= ClassDataMap()
		private var			identifierMap	= [ObjectIdentifier: UIntID]()
		
		mutating func createTypeIDIfNeeded( type:(AnyObject & GCodable).Type ) throws -> UIntID {
			let objIdentifier	= ObjectIdentifier( type )
			
			if let typeID = identifierMap[ objIdentifier ] {
				return typeID
			} else {
				defer { currentId += 1 }
				
				let typeID = currentId
				classDataMap[ typeID ]	= try ClassData( type: type )
				identifierMap[ objIdentifier ] = typeID
				return typeID
			}
		}
	}
	
	// -------------------------------------------------
	// ----- KeyMap
	// -------------------------------------------------
	
	fileprivate struct KeyMap  {
		private	var			currentId : UIntID	= 1000	// ATT! 0 reserved for unkeyed coding / 1-999 future use
		private (set) var	keyStringMap		= KeyStringMap()
		private var			inverseMap			= [String: UIntID]()
		
		mutating func createKeyIDIfNeeded( key:String ) -> UIntID {
			if let keyID = inverseMap[ key ] {
				return keyID
			} else {
				let keyID = currentId
				defer { currentId += 1 }
				inverseMap[ key ]	= keyID
				keyStringMap[ keyID ] = key
				return keyID
			}
		}
	}
	
	// -------------------------------------------------
	// ----- AnyIdentifierMap
	// -------------------------------------------------
	/* THE STANDARD WAY IS SLOWER:
	fileprivate struct AnyIdentifierMap {
		private	var actualId : UIntID	= 1000	// <1000 reserved for future use
		private var	strongObjDict		= [AnyHashable:UIntID]()
		private var	weakObjDict			= [AnyHashable:UIntID]()

		func strongID<T:Hashable>( _ identifier: T ) -> UIntID? {
			strongObjDict[ identifier ]
		}

		mutating func createWeakID<T:Hashable>( _ identifier: T ) -> UIntID {
			if let objID = weakObjDict[ identifier ] {
				return objID
			} else {
				let objID = actualId
				defer { actualId += 1 }
				weakObjDict[ identifier ] = objID
				return objID
			}
		}

		mutating func createStrongID<T:Hashable>( _ identifier: T ) -> UIntID {
			if let objID = strongObjDict[ identifier ] {
				return objID
			} else if let objID = weakObjDict[identifier] {
				// se è nel weak dict, lo prendo da lì
				weakObjDict.removeValue(forKey: identifier)
				// e lo metto nello strong dict
				strongObjDict[identifier] = objID
				return objID
			} else {
				// altrimenti creo uno nuovo
				let objID = actualId
				defer { actualId += 1 }
				strongObjDict[identifier] = objID
				return objID
			}
		}
	}
	*/
	
	fileprivate struct AnyIdentifierMap {
		private struct Key : Hashable {
			private let identifier : any Hashable
			
			init( _ identifier: any Hashable ) {
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
		
		private	var actualId : UIntID	= 1000	// <1000 reserved for future use
		private var	strongObjDict		= [Key:UIntID]()
		private var	weakObjDict			= [Key:UIntID]()
		
		func strongID<T:Hashable>( _ identifier: T ) -> UIntID? {
			strongObjDict[ Key(identifier) ]
		}
		
		mutating func createWeakID<T:Hashable>( _ identifier: T ) -> UIntID {
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
		
		mutating func createStrongID<T:Hashable>( _ identifier: T ) -> UIntID {
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


/*
public func ==<T,Q>( lhs: T, rhs: Q ) -> Bool where T:Equatable, Q:Equatable {
	guard let rhs = rhs as? T else { return false }
	return lhs == rhs
}
*/


