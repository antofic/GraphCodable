//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation
import CwlDemangle

public enum ManglingFunction: UInt8, BCodable {
	case nsClassFromString, mangledTypeName
}

public protocol GEncodedClassInfo {
	var manglingFunction:		ManglingFunction { get }
	var mangledClassName: 		String { get }
	var encodedClassVersion:	UInt32 { get }
}

extension GEncodedClassInfo {
	public func className( qualified: Bool ) -> String {
		do {
			let isType		= manglingFunction == .mangledTypeName ? true : false
			let swiftSymbol = try parseMangledSwiftSymbol( mangledClassName, isType:isType )
			return swiftSymbol.print( using: qualified ? .default : .simplified )
		} catch {
			return mangledClassName
		}
	}
	
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
