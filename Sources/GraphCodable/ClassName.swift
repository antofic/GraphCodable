//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

///	A struct that specifies the name of the encoded
/// class to match the type to create
///
/// Used by `GraphDecoder` `setType(...)` function.
public enum ClassName : Hashable {
	///	The `mangledClassName` string
	///
	/// You can specify the encoded class `mangledClassName`
	case mangled( _:String )
	///	The `qualifiedClassName` string
	///
	/// You can specify the encoded class `qualifiedClassName`
	case qualified( _:String )
}

public typealias ClassNameMap = [ClassName : any GDecodable.Type ]


public enum ManglingFunction: UInt8, BCodable {
	case nsClassFromString, mangledTypeName
}

public struct ClassBubbu {
	public let	manglingFunction:		ManglingFunction
	public let	mangledClassName:		String
	public let	encodedClassVersion:	UInt32
}

extension ClassBubbu {
	init(
		_ manglingFunction: ManglingFunction,
		_ mangledClassName: String,
		_ encodedClassVersion: UInt32
	) {
		self.manglingFunction		= manglingFunction
		self.mangledClassName		= mangledClassName
		self.encodedClassVersion	= encodedClassVersion
	}
}
