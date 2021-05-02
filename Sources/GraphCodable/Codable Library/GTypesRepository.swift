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

struct TypeNameVersion : CustomStringConvertible {
	init( typeName: String, version:UInt32 ) {
		self.typeName	= typeName
		self.version	= version
	}
	
	let	typeName:	String
	let	version:	UInt32

	var swiftTypeString : String { // this is a costly call!!!
		guard let string = try? TypeDescriptor(
			typeName: typeName,
			mainModuleName:GTypesRepository.shared.mainModuleName
		).swiftTypeString else {
			preconditionFailure("Error retrieving swiftTypeString")
		}
		return string
	}

	var description: String {
		return "\(typeName) V\(version)"
	}
}


public final class GTypesRepository {
	private static var _shared	: GTypesRepository?
	
	public static var shared : GTypesRepository {
		precondition(
			_shared != nil,
			"You must call 'GTypesRepository.initialize()' from your main module before using GraphCodable."
		)
		return _shared!
	}

	public static func initialize( mainModuleName name:String ) {
		// _shared viene settato da GTypesRepository.init
		if _shared == nil { GTypesRepository(mainModuleName: name) }
		_shared?.reset()
	}

	public static func initialize( fromFileID fileID:String = #fileID ) {
		initialize( mainModuleName: String( fileID.prefix() { $0 != "/" } ) )
	}

	// --------------------------------------------------------------------------------
	
	private(set) var mainModuleName	: String

	@discardableResult
	private init( mainModuleName name:String ) {
		mainModuleName	= name
		Self._shared	= self
		
//		registerNativeTypes()
	}
/*
	private func registerNativeTypes() {
		nativeRegister( type:Bool.self )
		nativeRegister( type:Int.self )
		nativeRegister( type:Int8.self )
		nativeRegister( type:Int16.self )
		nativeRegister( type:Int32.self )
		nativeRegister( type:Int64.self )
		nativeRegister( type:UInt.self )
		nativeRegister( type:UInt8.self )
		nativeRegister( type:UInt16.self )
		nativeRegister( type:UInt32.self )
		nativeRegister( type:UInt64.self )
		nativeRegister( type:Float.self )
		nativeRegister( type:Double.self )
		nativeRegister( type:String.self )
		nativeRegister( type:Data.self )
	}
*/
	// --------------------------------------------------------------------------------

	private var typeNames 			= [ObjectIdentifier: String]()
			
	func typeName( type:Any.Type ) -> String {
		let typeIdentifier	= ObjectIdentifier(type)
		if let name = self.typeNames[ typeIdentifier ] {
			return name
		} else if let name = try? TypeDescriptor( type: type, mainModuleName: mainModuleName ).typeName {
			self.typeNames[ typeIdentifier ]	= name
			return name
		} else {
			preconditionFailure(
				"Error parsing typeName '\(type)'."
			)
		}
	}

	// --------------------------------------------------------------------------------

	private var decodableTypes		= [String : GDecodable.Type]()
//	private var nativeTypes			= [String : GNativeCodable.Type]()
/*
	func nativeType( typeName:String ) -> GNativeCodable.Type? {
		return nativeTypes[ typeName ]
	}
*/
	func decodableType( typeName:String ) -> GDecodable.Type? {
		return decodableTypes[ typeName ]
	}
/*
	private func nativeRegister<T>( type:T.Type ) where T:GNativeCodable {
		nativeTypes[ typeName(type: type) ] = type
	}
*/
	func register<T>( type:T.Type ) where T:GDecodable, T:AnyObject {
		let typeName = typeName(type: type)
		
		if let oldType = decodableTypes[ typeName ] {
			precondition( oldType == type, "Attempt to overwrite \( String(reflecting:oldType) ) with \( String(reflecting:type) )")
		} else {
			decodableTypes[ typeName ] = type
		}
	}

	func unregister<T:GDecodable>( type:T.Type ) {
		decodableTypes.removeValue( forKey: typeName(type: type) )
	}
	
	func reset() {
		decodableTypes.removeAll()
		typeReplacementsTable.removeAll()
	}

	// --------------------------------------------------------------------------------

	
	private var typeReplacementsTable		= [String : TypeDescriptor]()	// oldTypeName:	newTypeDescriptor

	func replace<T>( _ type:AnyObject.Type, with newType:T.Type ) throws where T:GDecodable, T:AnyObject {
		let oldTypeName	= typeName(type: type)
		decodableTypes.removeValue( forKey: oldTypeName )
		register(type: newType)

		let new	= try TypeDescriptor( type:newType, mainModuleName:mainModuleName )
		typeReplacementsTable[ oldTypeName ] = new
	}

	func replaceEncodedTypenameIfNeeded( typeName:String ) throws -> String {
		if typeReplacementsTable.count == 0 {
			return typeName
		} else {
			let old	= try TypeDescriptor( typeName: typeName, mainModuleName: mainModuleName )
			let new	= old.updateToNewType( with: typeReplacementsTable )
			return new.typeName
		}
	}
}

extension GTypesRepository {	// HELP
	public func help( initializeFuncName name:String = "initializeGraphCodable" ) -> String {
		let tnvs	= decodableTypes.map {
			//	non ho la versione a disposizione, perché è una proprietà
			//	di GEncodable e nel registro sono memorizzati elementi GDecodable
			return TypeNameVersion(typeName: $0.key, version: 0)
		}
		return Self.swiftRegisterFunc( typeNameVersions:tnvs, initializeFuncName:name, showVersions:false )
	}
	
	static func swiftRegisterFunc<S>( typeNameVersions:S, initializeFuncName:String, showVersions sv:Bool ) -> String
	where S:Sequence, S.Element==TypeNameVersion
	{
		let calls =
			typeNameVersions
			.sorted { $0.swiftTypeString < $1.swiftTypeString }
			.reduce(into: "") {
				$0 += "\t\( $1.swiftTypeString ).register()\t" + (sv ? "// V=\( $1.version )\n" : "")
			}
		
		return
			"// \(String(repeating: "-", count: 60))\n" +
			"//\tPlease, define and call this function very early\n" +
			"//\tfrom your main module:\n" +
			"func \(initializeFuncName)() {\n" +
			"\t//\tinizializes the register with the main module name\n" +
			"\t//\tobtained from #fileID:\n" +
			"\t\(self).initialize()\t\n\n" +
			"\t//\tregister all GCodable types:\n" +
			calls +
			"}\n" +
			"// \(String(repeating: "-", count: 60))\n"
	}
}

extension GTypesRepository : CustomStringConvertible {
	public var description: String {

		return
			"\(type(of: self))( " +
			"\(TypeDescriptor.mainModulePlaceHolder) = \"\( mainModuleName )\", " +
//			"nativeTypes = \( nativeTypes.keys.map { $0 }.sorted() ), " +
			"registeredTypes = \( decodableTypes.keys.map { $0 }.sorted() ), " +
			"typeReplacementsTable = \( typeReplacementsTable ) )"


		
//		return "\(type(of: self)) registered types:\(decodableTypes.keys.description)"
	}
}

// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

fileprivate extension StringProtocol {
	func innerRange( open:Character, close:Character ) throws -> Range<String.Index>? {
		if let first = self.firstIndex(of: open) {
			let laststring	= self[ first... ]
			if let last = laststring.lastIndex(of: close) {
				return first ..< last
			} else {
				throw GCodableError.typeDescriptorError(1)
			}
		}
		return nil
	}
}

// --------------------------------------------------------------------------------

fileprivate struct TypeDescriptor : Equatable, Hashable {
	static let mainModulePlaceHolder : Character	= "*"
	//	example Swift.Dictionary<Swift.String, Swift.Array<Swift.Int>>
	let	module		: String			// "Swift"
	let parts		: [String]			// ["Dictionary"]
	let	subTypes	: [TypeDescriptor]	// [Swift.String, Swift.Array<Swift.Int>]
	
	private init( module:String, parts:[String], subTypes:[TypeDescriptor] ) {
		self.module		= module
		self.parts		= parts
		self.subTypes	= subTypes
	}
	
	//	This is a complex operation and it is not clear how stable it is.
	//	Language support would be needed in order to have stable type names.
	//	Now we first remove "(_______).(____________)." from the reflectedString
	//	and then remove the "mainModuleName." so that reflected types like this:
	//		MainModuleName.(unknown context at $1000499fc).(unknown context at $100049ab4).MyType.MyNestedType
	//	become:
	//		Type.NestedType
	//	and reflected types like this:
	//		Swift.Array<MainModuleName.(unknown context at $10004d9ac).(unknown context at $10004ddb4).MyType>
	//	become:
	//		Swift.Array<MyType>
	
	fileprivate init( typeName:String, mainModuleName:String ) throws {
		func iparse( iterator: inout String.Iterator ) throws -> [TypeDescriptor] {
			enum Phase { case module,type,ignore }
			var phase	= Phase.module
			
			var descriptors	= [TypeDescriptor]()
			
			var parts		= [String]()
			var subTypes	= [TypeDescriptor]()
			
			var module		= ""
			var part		= ""
			
			func newPart() {
				if part.isEmpty == false {
					parts.append( part )
				}
				part = ""
			}
			
			func newDescriptor() throws {
				newPart()
				
				if module.isEmpty || parts.isEmpty || parts[0].isEmpty {
					throw GCodableError.typeDescriptorError(2)
				}
				
				let moduleName	= (module == mainModuleName) ?
					String( Self.mainModulePlaceHolder ) : module
				
				descriptors.append(
					TypeDescriptor( module: moduleName, parts: parts, subTypes: subTypes )
				)
				parts.removeAll()
				subTypes.removeAll()
				module		= ""
				part		= ""
				phase		= .module
			}
			
			while let ch = iterator.next() {
				switch ch {
				case ".":
					switch phase {
					case .module:	phase = .type
					case .type:		newPart()
					case .ignore:	newPart()
					}
				case "<":
					switch phase {
					case .module:	throw GCodableError.typeDescriptorError(3)
					case .type:		subTypes = try iparse( iterator:&iterator )
					case .ignore:	throw GCodableError.typeDescriptorError(4)
					}
					break
				case ">":
					switch phase {
					case .module:	throw GCodableError.typeDescriptorError(5)
					case .type:		break
					case .ignore:	throw GCodableError.typeDescriptorError(6)
					}
				case "(":
					switch phase {
					case .module:	throw GCodableError.typeDescriptorError(7)
					case .type:		phase = .ignore
					case .ignore:	break
					}
				case ")":
					switch phase {
					case .module:	throw GCodableError.typeDescriptorError(8)
					case .type:		break
					case .ignore:	phase = .type
					}
				case ",":
					switch phase {
					case .module:	throw GCodableError.typeDescriptorError(9)
					case .type:		try newDescriptor()
					case .ignore:	throw GCodableError.typeDescriptorError(10)
					}
				case " ":
					break
				default:
					switch phase {
					case .module:	module.append( ch )
					case .type:		part.append( ch )
					case .ignore:	break
					}
				}
			}
			try newDescriptor()
			
			return descriptors
		}
		
		var iterator	= typeName.makeIterator()
		let descriptors	= try iparse( iterator:&iterator )
		
		guard descriptors.count == 1 else { throw GCodableError.typeDescriptorError(11) }
		
		self = descriptors[0]
	}
	
	fileprivate init( type:Any.Type, mainModuleName main:String ) throws {
		try self.init( typeName: String(reflecting: type), mainModuleName: main )
	}

	/*
	fileprivate func update( table:[TypeDescriptor:TypeDescriptor] ) -> TypeDescriptor {
		if let updated = table[self] {
			return updated
		} else {
			return TypeDescriptor(
				module:		self.module,
				parts:		self.parts,
				subTypes:	self.subTypes.map { $0.update(table: table) }
			)
		}
	}
	*/
	
	// recursively updates types
	fileprivate func updateToNewType( with typeReplacementsTable:[String:TypeDescriptor] ) -> TypeDescriptor {
		if let updated = typeReplacementsTable[ self.typeName ] {
			return updated
		} else {
			return TypeDescriptor(
				module:		self.module,
				parts:		self.parts,
				subTypes:	self.subTypes.map { $0.updateToNewType( with:typeReplacementsTable ) }
			)
		}
	}
	/*
	fileprivate func contains( type:TypeDescriptor ) -> Bool {
		for subType in subTypes {
			if type == subType || subType.contains(type: type) {
				return true
			}
		}
		return false
	}
	*/
	
	
	private func typeName( stripMainModule:Bool ) -> String {
		var string	= ""
		
		do {
			var point	= false
			if stripMainModule == false || module.first! != Self.mainModulePlaceHolder {
				string.append( module )
				point	= true
			}
			
			for typeName in parts {
				if point {
					string.append( "." )
				} else {
					point	= true
				}
				string.append( contentsOf: typeName )
			}
		}

		do {
			var bracket = false
			for subType in subTypes {
				if bracket {
					string.append( "," )
				} else {
					string.append( "<" )
					bracket	= true
				}
				string.append( subType.typeName( stripMainModule:stripMainModule ) )
			}
			if bracket {
				string.append( ">" )
			}
		}
		
		return string
	}
	
	fileprivate var typeName : String {
		return typeName( stripMainModule:false )
	}
	
	fileprivate var swiftTypeString : String {
		return typeName( stripMainModule:true )
	}
}

extension TypeDescriptor : CustomStringConvertible {
	var description: String {
		return "\"\(typeName)\""
	}
}
