//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation
import CwlDemangle

struct EncodedClass {
	let info : ClassBubbu
	
	var	manglingFunction:		ManglingFunction { info.manglingFunction }
	var	mangledClassName:		String { info.mangledClassName }
	var	encodedClassVersion:	UInt32 { info.encodedClassVersion }
	
	func className( qualified: Bool ) -> String {
		do {
			let isType		= manglingFunction == .mangledTypeName ? true : false
			let swiftSymbol = try parseMangledSwiftSymbol( mangledClassName, isType:isType )
			return swiftSymbol.print( using: qualified ? .default : .simplified )
		} catch {
			return mangledClassName
		}
	}
}

extension EncodedClass: BCodable {
	func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( info.manglingFunction )
		try encoder.encode( info.mangledClassName )
		try encoder.encode( info.encodedClassVersion )
	}
	
	init(from decoder: inout some BDecoder) throws {
		let	manglingFunction	= try decoder.decode( ManglingFunction.self )
		let	mangledClassName	= try decoder.decode( String.self )
		let	encodedClassVersion	= try decoder.decode( UInt32.self )
		
		self.info = ClassBubbu( manglingFunction, mangledClassName, encodedClassVersion )
	}
}

extension EncodedClass: CustomStringConvertible { 	// CustomStringConvertible protocol
	var description: String {
		"\"\( className( qualified: true ) )\" V\(encodedClassVersion) "
	}
}

extension EncodedClass {
	static func classType( from mangledClassName:String, manglingFunction:ManglingFunction ) -> AnyClass? {
		switch manglingFunction {
			case .mangledTypeName:		return _typeByName( mangledClassName ) as? AnyClass
			case .nsClassFromString:	return NSClassFromString( mangledClassName )
		}
	}
	
	static func mangledClassName( of classType:AnyClass, manglingFunction:ManglingFunction ) -> String? {
		switch manglingFunction {
			case .mangledTypeName:		return _mangledTypeName( classType )
			case .nsClassFromString:	return NSStringFromClass( classType )
		}
	}

	static func typeName( _ type:Any.Type, qualified:Bool ) -> String {
		_typeName( type, qualified:qualified )
	}
}

extension EncodedClass { 	// init
	init<T>( type:T.Type, manglingFunction:ManglingFunction  ) throws where T:AnyObject, T:GEncodable {
		guard
			let mangledClassName = Self.mangledClassName( of: type, manglingFunction:manglingFunction ),
			Self.classType( from:mangledClassName, manglingFunction:manglingFunction ) != nil else {
			throw Errors.GraphCodable.cantConstructClass(
				Self.self, Errors.Context(
					debugDescription:"The class |\(T.self)| can't be constructed."
				)
			)
		}
		self.info	= ClassBubbu(
			manglingFunction, mangledClassName, type.classVersion 
		)
	}
}

extension EncodedClass {
	var isConstructible : Bool {
		decodedType != nil
	}
	
	private var encodedClass: (any (AnyObject & GDecodable).Type)? {
		Self.classType( from: mangledClassName, manglingFunction: manglingFunction ) as? any (AnyObject & GDecodable).Type
	}

	var decodedType: (any GDecodable.Type)? {
		encodedClass?.decodeType ?? nil
	}
	
	var replacedClass: (any (AnyObject & GDecodable).Type)? {
		if let type = encodedClass, type != type.decodeType {
			return type
		}
		return nil
	}
}


extension EncodedClass {	// static primitive functions
	static func isConstructible( type:AnyClass, manglingFunction:ManglingFunction ) -> Bool {
		guard let mangledClassName = mangledClassName(of: type, manglingFunction:manglingFunction ) else {
			return false
		}
		return classType( from:mangledClassName, manglingFunction:manglingFunction ) != nil
	}
	
	static func throwIfNotConstructible( type:AnyClass, manglingFunction:ManglingFunction ) throws {
		guard isConstructible( type:type, manglingFunction:manglingFunction ) else {
			throw Errors.GraphCodable.cantConstructClass(
				Self.self, Errors.Context(
					debugDescription:"The class |\( _typeName( type, qualified:true ) )| can't be constructed."
				)
			)
		}
	}
}

