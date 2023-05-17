//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

typealias ManglingFunction = ClassInfo.ManglingFunction

extension ClassInfo : BCodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( manglingFunction )
		try encoder.encode( mangledClassName )
		try encoder.encode( classVersion )
	}
	
	public init(from decoder: inout some BDecoder) throws {
		manglingFunction	= try decoder.decode( ManglingFunction.self )
		mangledClassName	= try decoder.decode( String.self )
		classVersion		= try decoder.decode( UInt32.self )
	}
}



struct EncodedClass {
	let info : ClassInfo
	
	var	manglingFunction:		ManglingFunction { info.manglingFunction }
	var	mangledClassName:		String { info.mangledClassName }
	var	encodedClassVersion:	UInt32 { info.classVersion }
	
	func className( qualified: Bool ) -> String {
		info.className(qualified: qualified)
	}
}

extension EncodedClass: BCodable {
	func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( info )
	}
	
	init(from decoder: inout some BDecoder) throws {
		info	= try decoder.decode( ClassInfo.self )
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
		self.info	= ClassInfo(
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
}

