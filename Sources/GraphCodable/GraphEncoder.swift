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


public final class GraphEncoder {
	private let encoder	: Encoder

	public enum Options {
		case onlyNativeTypes, allBinaryTypes
	}
	
	/// GraphEncoder init method
	public init( _ options: Options = .allBinaryTypes ) {
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
	public func dump<T>( _ value: T, options: DumpOptions = .readable ) throws -> String where T:GCodable {
		try encoder.dumpRoot( value, options:options )
	}
	
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

	// -------------------------------------------------
	// ----- Encoder
	// -------------------------------------------------

	private final class Encoder : GEncoder {
		var userInfo			= [String:Any]()
		
		init( _ options: Options ) {
			self.encodeOptions	= options
		}
		
		private func _encodeRoot<T>( _ value: T ) throws -> EncodedData where T:GCodable {
			defer { reset() }
			reset()
			
			try encode( value )
			
			return encodedData
		}
		
		func dumpRoot<T>( _ value: T, options: DumpOptions ) throws -> String where T:GCodable {
			let encodedData = try _encodeRoot( value )
			
			return encodedData.readableOutput(options: options)
		}
		
		func encodeRoot<T,Q>( _ value: T ) throws -> Q where T:GCodable, Q:MutableDataProtocol {
			let output	= try _encodeRoot( value )
			var writer	: BinaryWriter = BinaryWriter()
			try output.write(to: &writer)
			return writer.data()
		}
		
		// --------------------------------------------------------
	
		func encode<Value>(_ value: Value) throws where Value:GCodable {
			try encodeAnyValue( value, forKey: nil, conditional:false )
		}

		func encodeConditional<Value>(_ value: Value?) throws where Value:GCodable, Value:AnyObject {
			try encodeAnyValue( value as Any, forKey: nil, conditional:true )
		}
		
		func encode<Key, Value>(_ value: Value, for key: Key) throws
		where Key : RawRepresentable, Value : GCodable, Key.RawValue == String
		{
			try encodeAnyValue( value, forKey: key.rawValue, conditional:false )
		}
		
		func encodeConditional<Key, Value>(_ value: Value?, for key: Key) throws
		where Key : RawRepresentable, Value : AnyObject, Value : GCodable, Key.RawValue == String
		{
			try encodeAnyValue( value as Any, forKey: key.rawValue, conditional:true )
		}

		// --------------------------------------------------------
		private let 		encodeOptions		: Options
		private var 		currentKeys			= Set<String>()
		private var			referenceID			= ObjectMap()
		private (set) var	encodedData			= EncodedData()
		private var			tempNativeValue		: Any?

		private var fullBinaryEncode : Bool {
			switch encodeOptions {
			case	.allBinaryTypes: return true
			default: return false
			}
		}
		
		private func reset() {
			self.currentKeys	= Set<String>()
			self.referenceID	= ObjectMap()
			self.encodedData	= EncodedData()
		}
	
		private func encodeAnyValue(_ anyValue: Any, forKey key: String?, conditional:Bool ) throws {
			// trasformo in un Optional<Any> di un solo livello:
			let value	= Optional(fullUnwrapping: anyValue)
			let keyID	= try createKeyID( key: key )
			
			guard let value = value else {
				encodedData.append( .nilValue(keyID: keyID) )
				return
			}
			// now value if not nil!

			//	let valueIdentifier	= (value as? GUniqueValue)?.uniqueID
			
			if let binaryValue = value as? NativeType {
				encodedData.append( .inBinType(keyID: keyID, value: binaryValue ) )
			} else if fullBinaryEncode, let binaryValue = value as? BinaryIOType {
				encodedData.append( .inBinType(keyID: keyID, value: binaryValue ) )
			} else if let object = value as? GCodable & AnyObject {	// reference type
				let identifier = ObjectIdentifier( object )
				if let objID = referenceID.strongID( identifier ) {
					// l'oggetto è stato già memorizzato, basta un pointer
					if conditional {
						encodedData.append( .objectWPtr(keyID: keyID, objID: objID) )
					} else {
						encodedData.append( .objectSPtr(keyID: keyID, objID: objID) )
					}
				} else if conditional {
					// Conditional Encoding: avrei la descrizione ma non la voglio usare
					// perché servirà solo se dopo arriverà da uno strongRef
					
					// Verifico comunque se l'oggetto è reificabile
					try ClassData.throwIfNotConstructible( type: type(of:object) )
					
					let objID	= referenceID.createWeakID( identifier )
					encodedData.append( .objectWPtr(keyID: keyID, objID: objID) )
				} else {
					//	memorizzo l'oggetto
					let typeID	= try encodedData.createTypeIDIfNeeded(type: type(of:object))
					let objID	= referenceID.createStrongID( identifier )
					
					encodedData.append( .objectType(keyID: keyID, typeID: typeID, objID: objID) )
					try encodeValue( object, to:self )
					encodedData.append( .end )
				}
			} else if let value = value as? GCodable {
				// value type
				encodedData.append( .valueType( keyID: keyID ) )
				try encodeValue( value, to:self )
				encodedData.append( .end )
			} else {
				throw GCodableError.internalInconsistency(
					Self.self, GCodableError.Context(
						debugDescription: "Not GCodable value \(value)."
					)
				)
			}
		}

		private func encodeValue( _ value:GCodable, to encoder:GEncoder ) throws {
			let savedKeys	= currentKeys
			defer { currentKeys = savedKeys }
			currentKeys.removeAll()
			
			try value.encode(to: encoder)
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
				return encodedData.createKeyIDIfNeeded(key: key)
			} else {
				return 0	// unkeyed
			}
		}

		// -------------------------------------------------
		// ----- ReferenceID
		// -------------------------------------------------
		/*
		fileprivate struct ObjectMap {
			private	var actualId : IntID	= 1000	// <1000 reserved for future use
			private var	strongObjDict		= [ObjectIdentifier:IntID]()
			private var	weakObjDict			= [ObjectIdentifier:IntID]()
			
			func strongID( _ value: AnyObject ) -> IntID? {
				strongObjDict[ ObjectIdentifier( value as AnyObject ) ]
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
		*/
		fileprivate struct ObjectMap {
			private	var actualId : IntID	= 1000	// <1000 reserved for future use
			private var	strongObjDict		= [ObjectIdentifier:IntID]()
			private var	weakObjDict			= [ObjectIdentifier:IntID]()
			
			func strongID( _ identifier: ObjectIdentifier ) -> IntID? {
				strongObjDict[ identifier ]
			}
			
			mutating func createWeakID( _ identifier: ObjectIdentifier ) -> IntID {
				if let objID = weakObjDict[ identifier ] {
					return objID
				} else {
					let objID = actualId
					defer { actualId += 1 }
					weakObjDict[ identifier ] = objID
					return objID
				}
			}
			
			mutating func createStrongID( _ identifier: ObjectIdentifier ) -> IntID {
				if let objID = weakObjDict[identifier] {
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

		// -------------------------------------------------
		// ----- EncodedData
		// -------------------------------------------------
		
		fileprivate struct EncodedData : CustomStringConvertible, CustomDebugStringConvertible {
			private var	typeMap			= TypeMap()
			private var	keyMap			= KeyMap()
			private (set) var blocks	= [DataBlock]()
			private let header			= DataBlock.header( // Header Block
				version: 0,
				unused0: "",
				unused1: 0,
				unused2: 0
			)

			mutating func createTypeIDIfNeeded( type:(AnyObject & GCodable).Type ) throws -> IntID {
				try typeMap.createTypeIDIfNeeded( type: type )
			}

			mutating func createKeyIDIfNeeded( key:String ) -> IntID {
				keyMap.createKeyIDIfNeeded( key:key )
			}
			
			mutating func append( _ dataBlock:DataBlock ) {
				blocks.append( dataBlock )
			}
			
			func write( to writer: inout BinaryWriter ) throws {
				try header.write(to: &writer)
				
				for (typeID,classInfo) in typeMap.typeIDtoClassInfo {
					try DataBlock.inTypeMap( typeID: typeID, classInfo: classInfo ).write(to: &writer)
				}
				
				for block in blocks {
					try block.write(to: &writer)
				}
				
				for (keyID,key) in keyMap.keyIDtoKey {
					try DataBlock.keyMap(keyID: keyID, keyName: key).write(to: &writer)
				}
			}
			
			var description: String {
				readableOutput( options:.binaryLike )
			}

			var debugDescription: String {
				readableOutput( options:.binaryLike )
			}
			
			func readableOutput( options:DumpOptions ) -> String {
				let info = DumpInfo(
					options:		options,
					classInfoMap:	options.contains( .resolveIDs ) ? typeMap.typeIDtoClassInfo : nil,
					keyIDtoKey:		options.contains( .resolveIDs ) ? keyMap.keyIDtoKey : nil
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
					output = typeMap.typeIDtoClassInfo.reduce( into: output ) {
						result, tuple in
						result.append(
							DataBlock.inTypeMap(
								typeID: tuple.key, classInfo: tuple.value
							).readableOutput(info: info)
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
						
						result.append( block.readableOutput(  info:info ) )
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
			
			// -------------------------------------------------
			// ----- TypeMap
			// -------------------------------------------------
			
			private struct TypeMap {
				private	var			currentId : IntID	= 1000	// ATT! 0-999 future use
				private (set) var	typeIDtoClassInfo	= [ IntID: ClassInfo ]()
				private var			typeToTypeID		= [ ObjectIdentifier: IntID ]()

				mutating func createTypeIDIfNeeded( type:(AnyObject & GCodable).Type ) throws -> IntID {
					let objIdentifier	= ObjectIdentifier( type )
					
					if let typeID = typeToTypeID[ objIdentifier ] {
						return typeID
					} else {
						defer { currentId += 1 }

						let typeID = currentId
						typeIDtoClassInfo[ typeID ]	= try ClassInfo( type: type )
						typeToTypeID[ objIdentifier ] = typeID
						return typeID
					}
				}
			}
	
			// -------------------------------------------------
			// ----- KeyMap
			// -------------------------------------------------
			
			private struct KeyMap  {
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
		}
	}
}



