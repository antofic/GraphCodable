//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

typealias DecodedClassMap	= [RefID:DecodedClass]

struct DecodedClass : CustomStringConvertible {
	let	decodedType:	any GDecodable.Type
	let	encodedClass:		EncodedClass
	
	init( encodedClass:EncodedClass, classNameMap:ClassNameMap? ) throws {
		self.encodedClass		= encodedClass
		
		if let type = encodedClass.decodedType {
			self.decodedType	= type
			return
		} else if let classNameMap {
			if let type	= classNameMap[ .mangled( encodedClass.mangledClassName ) ] {
				self.decodedType	= type
				return
			} else if let type	= classNameMap[ .qualified( encodedClass.className( qualified: true ) ) ] {
				self.decodedType	= type
				return
			}
		}
		
		throw Errors.GraphCodable.cantConstructClass(
			Self.self, Errors.Context(
				debugDescription:"The class |\(encodedClass.className( qualified: true ))| can't be constructed."
			)
		)
	}
	
	var description: String {
		return encodedClass.description
	}
	
	static func decodedClassMap( encodedClassMap:EncodedClassMap, classNameMap:ClassNameMap? ) throws -> DecodedClassMap {
		try encodedClassMap.mapValues {
			try DecodedClass(encodedClass: $0, classNameMap:classNameMap )
		}
	}

	static func decodedClassMapNoThrow( encodedClassMap:EncodedClassMap, classNameMap:ClassNameMap? ) -> DecodedClassMap {
		encodedClassMap.compactMapValues {
			try? DecodedClass(encodedClass: $0, classNameMap:classNameMap )
		}
	}

	static func undecodablesEncodedClassMap( encodedClassMap:EncodedClassMap, classNameMap:ClassNameMap? ) -> EncodedClassMap {
		encodedClassMap.compactMapValues {
			(try? DecodedClass(encodedClass: $0, classNameMap:classNameMap )) == nil ? $0 : nil
		}
	}
}
