//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

struct ClassData: GEncodedClassInfo {
	let	mangledClassName:		String
	let	encodedClassVersion:	UInt32
	let	manglingFunction:		ManglingFunction
}

extension ClassData { 	// init
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
		self.manglingFunction		= manglingFunction
		self.mangledClassName 		= mangledClassName
		self.encodedClassVersion	= type.classVersion
	}
}

extension ClassData {
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

extension ClassData: BCodable {
	func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode(manglingFunction)
		try encoder.encode(mangledClassName)
		try encoder.encode(encodedClassVersion)
	}
	
	init(from decoder: inout some BDecoder) throws {
		self.manglingFunction		= try decoder.decode()
		self.mangledClassName		= try decoder.decode()
		self.encodedClassVersion	= try decoder.decode()
	}
}

extension ClassData: CustomStringConvertible { 	// CustomStringConvertible protocol
	var description: String {
		"\"\( className(qualified: true) )\" V\(encodedClassVersion) "
	}
}

extension ClassData {	// static primitive functions
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

