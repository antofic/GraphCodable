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

public struct DumpOptions: OptionSet {
	public let rawValue: UInt
	
	public init(rawValue: UInt) {
		self.rawValue	= rawValue
	}
	
	//	four data sections:
	public static let	showHeader			= Self( rawValue: 1 << 0 )
	public static let	showTypeMap			= Self( rawValue: 1 << 1 )
	public static let	showGraph			= Self( rawValue: 1 << 2 )
	public static let	showKeyMap			= Self( rawValue: 1 << 3 )
	
	//	indent the data
	public static let	indentLevel			= Self( rawValue: 1 << 4 )
	//	in the Graph section, resolve typeIDs in typeNames, keyIDs in keyNames
	public static let	resolveIDs			= Self( rawValue: 1 << 5 )
	//	in the Graph section, show type versions (they are in the TypeMap section)
	public static let	showTypeVersion		= Self( rawValue: 1 << 6 )
	//	includes '=== SECTION TITLE =========================================='
	public static let	showSectionTitles	= Self( rawValue: 1 << 7 )
	//	disable truncation of too long nativeValues (over 48 characters - String or Data typically)
	public static let	noTruncation		= Self( rawValue: 1 << 8 )

	public static let	readable: Self = [
		.showHeader, .showGraph, .indentLevel, .resolveIDs, .showSectionTitles
	]
	public static let	fullInfo: Self = [
		.showHeader, .showTypeMap, .showGraph, .showKeyMap, .indentLevel, .resolveIDs, .showTypeVersion, .showSectionTitles, .noTruncation
	]
	public static let	binaryLike: Self = [
		.showHeader, .showTypeMap, .showGraph, .showKeyMap, .indentLevel, .showSectionTitles
	]
}


public struct EncodeOptions: OptionSet {
	public let rawValue: UInt
	
	public init(rawValue: UInt) {
		self.rawValue	= rawValue
	}
	
	//	four data sections:
	public static let	binaryCollapse = Self( rawValue: 1 << 0 )

	public static let	fastest: Self	= [ .binaryCollapse ]
	public static let	readable: Self	= [  ]
}


public final class GraphEncoder {
	private let encoder	= Encoder()

	public init() {}
	
	public var userInfo : [String:Any] {
		get { return encoder.userInfo }
		set { encoder.userInfo = newValue }
	}

	public func dump<T>( _ value: T, dumpOptions: DumpOptions = .readable, encodeOptions: EncodeOptions = .readable ) throws -> String where T:GCodable {
		return try encoder.dumpRoot( value, dumpOptions:dumpOptions, encodeOptions:encodeOptions )
	}
	
	public func encode<T>( _ value: T, encodeOptions: EncodeOptions = .fastest ) throws -> Data where T:GCodable {
		return try encoder.encodeRoot( value , encodeOptions:encodeOptions )
	}

	// -------------------------------------------------
	// ----- Encoder
	// -------------------------------------------------

	private final class Encoder : GEncoder {
		var userInfo		= [String:Any]()
		
		private func _encodeRoot<T>( _ value: T,encodeOptions: EncodeOptions ) throws -> EncodedData where T:GCodable {
			defer { reset() }
			reset( /* encodeOptions:encodeOptions */ )
			
			try encode( value )
			
			return encodedData
		}
		
		func dumpRoot<T>( _ value: T, dumpOptions: DumpOptions, encodeOptions:EncodeOptions ) throws -> String where T:GCodable {
			let encodedData = try _encodeRoot( value, encodeOptions: encodeOptions )
			
			return encodedData.readableOutput(options: dumpOptions)
		}
		
		func encodeRoot<T>( _ value: T, encodeOptions: EncodeOptions = .fastest ) throws -> Data where T:GCodable {
			let output	= try _encodeRoot( value, encodeOptions:encodeOptions )
			var writer	= BinaryWriter()
			try output.write(to: &writer)
			return writer.data()
		}
		
		// --------------------------------------------------------
	
		func encode<Value>(_ value: Value) throws where Value:GCodable {
			try encodeUnwrapping( value, forKey: nil, weak:false )
		}

		func encodeConditional<Value>(_ value: Value?) throws where Value:GCodable, Value:AnyObject {
			try encodeUnwrapping( value, forKey: nil, weak:true )
		}
		
		func encode<Key, Value>(_ value: Value, for key: Key) throws
		where Key : RawRepresentable, Value : GCodable, Key.RawValue == String
		{
			try encodeUnwrapping( value, forKey: key.rawValue, weak:false )
		}
		
		func encodeConditional<Key, Value>(_ value: Value?, for key: Key) throws
		where Key : RawRepresentable, Value : AnyObject, Value : GCodable, Key.RawValue == String
		{
			try encodeUnwrapping( value, forKey: key.rawValue, weak:true )
		}

		// --------------------------------------------------------
		private var			encodeOptions	= EncodeOptions.fastest
		private var 		currentKeys		= Set<String>()
		private var			referenceID		= ObjectMap()
		private (set) var	encodedData		= EncodedData()
		private var			tempNativeValue	: Any?

		private func reset( encodeOptions: EncodeOptions = EncodeOptions.fastest ) {
			self.encodeOptions	= encodeOptions
			self.currentKeys	= Set<String>()
			self.referenceID	= ObjectMap()
			self.encodedData	= EncodedData()
		}
	
		private func encodeUnwrapping<T>(_ value: T, forKey key: String?, weak:Bool ) throws {
			try encodeAny( Optional(fullUnwrapping: value as Any), forKey: key, weak:weak )
		}

		private func encodeAny(_ value: Any?, forKey key: String?, weak:Bool ) throws {
			func encodeValue( _ value:GCodable, to encoder:GEncoder ) throws {
				let savedKeys	= currentKeys
				defer { currentKeys = savedKeys }
				currentKeys.removeAll()
				
				try value.encode(to: encoder)
			}
			
			func updateKey( key: String? ) throws -> IntID {
				if let key = key {
					defer { currentKeys.insert( key ) }
					if currentKeys.contains( key ) {
						throw GCodableError.duplicateKey(key: key)
					}
					return encodedData.createKeyIDIfNeeded(key: key)
				} else {
					return 0	// unkeyed
				}
			}
			let keyID	= try updateKey( key: key )
			
			guard let value = value else {
				encodedData.append( .nilValue(keyID: keyID) )
				return
			}
			// now value if not nil!

			if let nativeValue = value as? GNativeCodable {
				encodedData.append( .nativeType(keyID: keyID, value: nativeValue) )
			} else if encodeOptions.contains( .binaryCollapse ), let binaryValue = value as? BinaryIOType {
				let bytes = try binaryValue.bytes()
				encodedData.append( .binaryType(keyID: keyID, bytes: bytes ) )
			} else if type(of:value) is AnyClass {
				guard let object = value as? GCodable & AnyObject else {
					throw GCodableError.notEncodableType( typeName: "\(type(of:value))" )
				}
				
				let objectType	= type(of:object)
				let typeName	= GTypesRepository.shared.typeName( type: objectType )
				let typeVersion	= objectType.encodeVersion
				let newType		= !encodedData.contains(typeName: typeName)
				let typeID		= encodedData.createTypeIDIfNeeded( typeName:typeName, version: typeVersion )
				
				if newType {
					// we update ever the register
					objectType.register()
				}
				// siamo sicuri che è un oggetto
				if let objID = referenceID.strongID( object ) {
					// l'oggetto è stato già memorizzato, basta un pointer
					if weak {
						encodedData.append( .objectWPtr(keyID: keyID, objID: objID) )
					} else {
						encodedData.append( .objectSPtr(keyID: keyID, objID: objID) )
					}
				} else if weak {
					// WeakRef: avrei la descrizione ma non la voglio usare
					// perché servirà solo se arriverà da uno strongRef
					let objID	= referenceID.createWeakID( object )
					encodedData.append( .objectWPtr(keyID: keyID, objID: objID) )
				} else {
					//	memorizzo l'oggetto
					let objID	= referenceID.createStrongID( object )
					
					encodedData.append( .objectType(keyID: keyID, typeID: typeID, objID: objID) )
					try encodeValue( object, to:self )
					encodedData.append( .end )
				}
			} else {	// full value type (struct)
				guard let value = value as? GCodable else {
					throw GCodableError.notEncodableType( typeName: "\(type(of:value))" )
				}
				encodedData.append( .valueType( keyID: keyID ) )
				try encodeValue( value, to:self )
				encodedData.append( .end )
			}
		}

		// -------------------------------------------------
		// ----- ReferenceID
		// -------------------------------------------------
		
		fileprivate struct ObjectMap {
			private	var actualId : IntID	= 1000	// <1000 reserved for future use
			private var	strongObjDict		= [ObjectIdentifier:IntID]()
			private var	weakObjDict			= [ObjectIdentifier:IntID]()
			
			func strongID( _ value: AnyObject ) -> IntID? {
				return strongObjDict[ ObjectIdentifier( value as AnyObject ) ]
			}
			
			mutating func createWeakID( _ value: AnyObject ) -> IntID {
				let objectKey = ObjectIdentifier( value as AnyObject )
				if let objID = weakObjDict[ objectKey ] {
					return objID
				} else {
					let objID = actualId
					defer { actualId += 1 }
					weakObjDict[ objectKey ] = objID
					return objID
				}
			}
			
			mutating func createStrongID( _ value: AnyObject ) -> IntID {
				let objectKey = ObjectIdentifier( value as AnyObject )
				
				if let objID = weakObjDict[ objectKey] {
					// se è nel weak dict, lo prendo da lì
					weakObjDict.removeValue(forKey: objectKey)
					// e lo metto nello strong dict
					strongObjDict[ objectKey] = objID
					return objID
				} else {
					// altrimenti creo uno nuovo
					let objID = actualId
					defer { actualId += 1 }
					strongObjDict[ objectKey] = objID
					return objID
				}
			}
		}

		
		// -------------------------------------------------
		// ----- EncodedData
		// -------------------------------------------------
		
		fileprivate struct EncodedData : CustomStringConvertible, CustomDebugStringConvertible {
			
			private var	typeNameID		= TypeNameVersionMap()
			private var	keyNameID		= KeyMap()
			private (set) var blocks	= [DataBlock]()
			private let header			= DataBlock.header( // Header Block
				version: 0,
				module: GTypesRepository.shared.mainModuleName,
				unused1: 0,
				unused2: 0
			)
			
			func contains( typeID:IntID ) -> Bool {
				return typeNameID.contains( typeID:typeID )
			}
			
			func contains( typeName:String ) -> Bool {
				return typeNameID.contains( typeName:typeName )
			}

			mutating func createTypeIDIfNeeded( typeName:String, version:UInt32 ) -> IntID {
				return typeNameID.createIDIfNeeded( typeNameVersion:TypeNameVersion(typeName: typeName, version: version) )
			}

			mutating func createKeyIDIfNeeded( key:String ) -> IntID {
				return keyNameID.createIDIfNeeded( key:key )
			}
			
			mutating func append( _ dataBlock:DataBlock ) {
				blocks.append( dataBlock )
			}
			
			var description: String {
				return readableOutput( options:.binaryLike )
			}

			var debugDescription: String {
				return readableOutput( options:.binaryLike )
			}

			func readableOutput( options:DumpOptions ) -> String {
				let info = DumpInfo(
					options:		options,
					typeIDtoName:	options.contains( .resolveIDs ) ? typeNameID.typeIDtoName : nil,
					keyIDtoKey:		options.contains( .resolveIDs ) ? keyNameID.keyIDtoKey : nil
				)

				var output = ""
				if options.contains( .showHeader ) {
					if options.contains( .showSectionTitles ) {
						output.append( "== HEADER ========================================================\n" )
					}
					output.append( header.readableOutput(info: info) )
					output.append( "\n" )
				}
				if options.contains( .showTypeMap ) {
					if options.contains( .showSectionTitles ) {
						output.append( "== TYPEMAP =======================================================\n" )
					}
					output = typeNameID.typeIDtoName.reduce( into: output ) {
						result, tuple in
						result.append(
							DataBlock.typeMap(
								typeID:			tuple.key,
								typeVersion:	tuple.value.version,
								typeName:		tuple.value.typeName
							).readableOutput(info: info)
						)
						result.append( "\n" )
					}
				}
				if options.contains( .showGraph ) {
					if options.contains( .showSectionTitles ) {
						output.append( "== GRAPH =========================================================\n" )
					}

					var	tabs : String?	= options.contains( .indentLevel ) ? "" : nil
					
					output = blocks.reduce( into: output ) {
						result, block in

						if case .exit = block.level { tabs?.removeLast() }

						if let tbs = tabs { result.append( tbs ) }
						
						result.append( block.readableOutput(  info:info ) )
						result.append( "\n" )
						
						if case .enter = block.level { tabs?.append("\t") }

					}
				}
				if options.contains( .showKeyMap ) {
					if options.contains( .showSectionTitles ) {
						output.append( "== KEYMAP ========================================================\n" )
					}
					output = keyNameID.keyIDtoKey.reduce( into: output ) {
						result, tuple in
						result.append(
							DataBlock.keyMap(
								keyID:		tuple.key,
								keyName:	tuple.value
							).readableOutput(info: info)
						)
						result.append( "\n" )
					}
				}
				if options.contains( .showSectionTitles ) {
					output.append( "==================================================================\n" )
				}
				return output
			}
			
			
			func write( to writer: inout BinaryWriter ) throws {
				try header.write(to: &writer)
				
				for (typeID,tnv) in typeNameID.typeIDtoName {
					try DataBlock.typeMap( typeID: typeID, typeVersion: tnv.version, typeName: tnv.typeName ).write(to: &writer)
				}
				
				for block in blocks {
					try block.write(to: &writer)
				}
				
				for (keyID,key) in keyNameID.keyIDtoKey {
					try DataBlock.keyMap(keyID: keyID, keyName: key).write(to: &writer)
				}
			}
			
			// -------------------------------------------------
			// ----- TypeNameMap
			// -------------------------------------------------
			
			private struct TypeNameVersionMap  {
				private	var			actualId : IntID	= 100	// <100 reserved for future use
				private (set) var	typeIDtoName		= [IntID:TypeNameVersion]()
				private var			typeNameToID		= [String:IntID]()

				func contains( typeID:IntID ) -> Bool {
					return typeIDtoName.index(forKey: typeID) != nil
				}

				func contains( typeName:String ) -> Bool {
					return typeNameToID.index(forKey: typeName) != nil
				}

				mutating func createIDIfNeeded( typeNameVersion:TypeNameVersion ) -> IntID {
					if let typeID = typeNameToID[ typeNameVersion.typeName ] {
						return typeID
					} else {
						let typeID = actualId
						defer { actualId += 1 }
						typeNameToID[ typeNameVersion.typeName ] = typeID
						typeIDtoName[ typeID ] = typeNameVersion
						return typeID
					}
				}
			}

			// -------------------------------------------------
			// ----- KeyMap
			// -------------------------------------------------
			
			private struct KeyMap  {
				private	var			actualId : IntID	= 100	// ATT! 0 reserved for unkeyed coding / 1-999 future use
				private (set) var	keyIDtoKey			= [IntID:String]()
				private var			keyToKeyID			= [String:IntID]()
				
				func contains( keyID:IntID ) -> Bool {
					return keyIDtoKey.index(forKey: keyID) != nil
				}

				func contains( key:String ) -> Bool {
					return keyToKeyID.index(forKey: key) != nil
				}

				mutating func createIDIfNeeded( key:String ) -> IntID {
					if let keyID = keyToKeyID[ key ] {
						return keyID
					} else {
						let keyID = actualId
						defer { actualId += 1 }
						keyToKeyID[ key ] = keyID
						keyIDtoKey[ keyID ] = key
						return keyID
					}
				}
			}
		}
	}
}





