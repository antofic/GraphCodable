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
// ----- BinaryEncoderDelegate
// -------------------------------------------------

protocol BinaryEncoderDelegate : AnyObject {
	var	classDataMap:	ClassDataMap { get }
	var	keyStringMap:	KeyStringMap { get }
	var dumpOptions:	GraphEncoder.DumpOptions { get }
}

// -------------------------------------------------
// ----- GEncoderImpl
// -------------------------------------------------

final class GEncoderImpl : GEncoder, BinaryEncoderDelegate {
	var userInfo							= [String:Any]()
	private typealias	IdentifierMap		= AnyIdentifierMap
	
	private let 		encodeOptions		: GraphEncoder.Options
	private var 		currentKeys			= Set<String>()
	private var			identifierMap		= IdentifierMap()
	private var			referenceMap		= ReferenceMap()
	private var			keyMap				= KeyMap()
	private (set) var	dumpOptions			= GraphEncoder.DumpOptions.readable
	private var			dataEncoder			= BinaryEncoder<GEncoderImpl>(isDump: false)
	
	var classDataMap: ClassDataMap 	{ referenceMap.classDataMap }
	var keyStringMap: KeyStringMap 	{ keyMap.keyStringMap }
	
	private func reset( dump: Bool = false, dumpOptions:GraphEncoder.DumpOptions = .readable ) {
		self.currentKeys			= Set<String>()
		self.identifierMap			= IdentifierMap()
		self.referenceMap			= ReferenceMap()
		self.keyMap					= KeyMap()
		self.dumpOptions			= dumpOptions
		self.dataEncoder			= BinaryEncoder<GEncoderImpl>(isDump: dump)
		self.dataEncoder.delegate	= self
		
	}
	
	// --------------------------------------------------------
	init( _ options: GraphEncoder.Options ) {
		self.encodeOptions			= options
		self.dataEncoder.delegate	= self
	}
	
	func encodeRoot<T,Q>( _ value: T ) throws -> Q where T:GEncodable, Q:MutableDataProtocol {
		defer { reset() }
		reset()
		
		try encode( value )

		return try dataEncoder.data()
	}
	
	func dumpRoot<T>( _ value: T, options: GraphEncoder.DumpOptions ) throws -> String where T:GEncodable {
		defer { reset() }
		reset( dump: true, dumpOptions:options )
		
		try encode( value )
		
		return try dataEncoder.dump()
	}
	
	// --------------------------------------------------------
	
	func encode<Value>(_ value: Value) throws where Value:GEncodable {
		try encodeAnyValue( value, forKey: nil, conditional:false )
	}

	func encodeConditional<Value>(_ value: Value?) throws where Value:GEncodable {
		try encodeAnyValue( value as Any, forKey: nil, conditional:true )
	}

	func encode<Key, Value>(_ value: Value, for key: Key) throws
	where Key : RawRepresentable, Value : GEncodable, Key.RawValue == String
	{
		try encodeAnyValue( value, forKey: key.rawValue, conditional:false )
	}

	func encodeConditional<Key, Value>(_ value: Value?, for key: Key) throws
	where Key : RawRepresentable, Value : GEncodable, Key.RawValue == String
	{
		try encodeAnyValue( value as Any, forKey: key.rawValue, conditional:true )
	}
	
	// --------------------------------------------------------
	private func identifier( of value:GEncodable ) -> (any Hashable)? {
		if encodeOptions.contains( .disableGIdentifiableProtocol ) {
			if	encodeOptions.contains( .disableObjectIdentifierIdentity ) == false,
				let object = value as? (GEncodable & AnyObject) {
					return ObjectIdentifier( object )
			}
		} else {
			if let identifiable	= value as? any GIdentifiable {
				return identifiable.gID
			} else if
				encodeOptions.contains( .disableObjectIdentifierIdentity ) == false,
				let object = value as? (GEncodable & AnyObject) {
					  return ObjectIdentifier( object )
			  }
		}
		return nil
	}

	private func binaryValue( of value:GEncodable ) -> (BinaryOType)? {
		if let value = value as? GBinaryEncodable { return value }
		else if encodeOptions.contains( .enableLibraryBinaryIOTypes ), let value = value as? BinaryOType { return value }
		else { return nil }
	}

	private func encodeAnyValue(_ anyValue: Any, forKey key: String?, conditional:Bool ) throws {
		// trasformo in un Optional<Any> di un solo livello:
		let value	= Optional(fullUnwrapping: anyValue)
		let keyID	= try createKeyID( key: key )
		
		guard let value = value else {
			try dataEncoder.appendNilValue(keyID: keyID)
			return
		}
		// now value if not nil!
		if let binaryValue = value as? NativeEncodable {
			//	i tipi nativi sono semplici: l'identità non serve
			//	(e per le stringhe?)
			//	in teoria possono essere reference, ma si comportano come value
			try dataEncoder.appendBinValue(keyID: keyID, value: binaryValue )
		} else if let value = value as? GEncodable {
			if let identifier = identifier( of:value ) {
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
					
					if let type	= type(of:value) as? AnyClass {
						// se è un feference verifico che sia reificabile
						try ClassData.throwIfNotConstructible( type: type )
					}
						
					let objID	= identifierMap.createWeakID( identifier )
					try dataEncoder.appendConditionalPtr(keyID: keyID, objID: objID)
				} else if let object = value as? GEncodable & AnyObject {
					//	memorizzo il reference type
					let typeID	= try referenceMap.createTypeIDIfNeeded(type:  type(of:object))
					let objID	= identifierMap.createStrongID( identifier )
					
					if let binaryValue = binaryValue( of:value ) {
						try dataEncoder.appendIBinRef(keyID: keyID, typeID: typeID, objID: objID, value: binaryValue )
					} else {
						try dataEncoder.appendReferenceType(keyID: keyID, typeID: typeID, objID: objID)
						try encodeValue( object )
						try dataEncoder.appendEnd()
					}
				} else {
					//	memorizzo il value type
					let objID	= identifierMap.createStrongID( identifier )
					
					if let binaryValue = binaryValue( of:value ) {
						try dataEncoder.appendIBinValue(keyID: keyID, objID: objID, value: binaryValue )
					} else {
						try dataEncoder.appendIValueType(keyID: keyID, objID: objID)
						try encodeValue( value )
						try dataEncoder.appendEnd()
					}
				}
			}  else if let binaryValue = binaryValue( of:value ) {
				try dataEncoder.appendBinValue(keyID: keyID, value: binaryValue )
			} else {
				//	valore senza identità
				try dataEncoder.appendValueType( keyID: keyID )
				try encodeValue( value )
				try dataEncoder.appendEnd()
			}
		} else {
			throw GCodableError.internalInconsistency(
				Self.self, GCodableError.Context(
					debugDescription: "Not GEncodable value \(value)."
				)
			)
		}
		
	}

	private func encodeValue( _ value:GEncodable ) throws {
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
	
	func appendBinValue( keyID:UIntID, value:BinaryOType ) throws {
		let bytes	= try value.binaryData() as Bytes
		try append( .binValueRef(keyID: keyID, bytes: bytes), value:value  )
	}
	func appendIBinValue( keyID:UIntID, objID:UIntID, value:BinaryOType ) throws {
		let bytes	= try value.binaryData() as Bytes
		try append( .idBinValue(keyID: keyID, objID: objID, bytes: bytes), value:value )
	}
	func appendIBinRef( keyID:UIntID,  typeID:UIntID, objID:UIntID, value:BinaryOType ) throws {
		let bytes	= try value.binaryData() as Bytes
		try append( .idBinRef(keyID: keyID, typeID:typeID, objID: objID, bytes: bytes), value:value )
	}
	
	func appendNilValue( keyID:UIntID ) throws {
		try append( .Nil(keyID: keyID) )
	}
	func appendValueType( keyID:UIntID ) throws {
		try append( .valueRef(keyID: keyID) )
	}
	func appendIValueType( keyID:UIntID, objID:UIntID ) throws {
		try append( .idValue(keyID: keyID, objID: objID) )
	}
	func appendReferenceType( keyID:UIntID, typeID:UIntID, objID:UIntID )throws {
		try append( .idRef(keyID: keyID, typeID: typeID, objID: objID) )
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

		if options.contains( .showClassDataMap ) {
			if options.contains( .showSectionTitles ) {
				output.append( "== REFERENCEMAP ==================================================\n" )
			}
			output = delegate?.classDataMap.reduce( into: output ) {
				result, tuple in
				result.append( "TYPE\( tuple.key ):\t\( typeString( options, tuple.value ) )\n")
			} ?? "UNAVAILABLE DELEGATE \(#function)\n"
		}
		
		if options.contains( .showKeyStringMap ) {
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
	
	mutating func createTypeIDIfNeeded( type:(AnyObject & GEncodable).Type ) throws -> UIntID {
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


