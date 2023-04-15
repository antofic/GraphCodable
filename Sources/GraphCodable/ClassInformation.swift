//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

public enum ManglingFunction: UInt8, BCodable {
	case nsClassFromString, mangledTypeName
}

public struct ClassInformation {
	public let	manglingFunction:		ManglingFunction
	public let	mangledClassName:		String
	public let	encodedClassVersion:	UInt32
}

extension ClassInformation {
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
