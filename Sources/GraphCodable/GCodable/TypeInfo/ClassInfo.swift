//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

typealias ClassInfoMap	= [RefID:ClassInfo]

struct ClassInfo : CustomStringConvertible {
	let	decodedType:	any GDecodable.Type
	let	classData:		ClassData
	
	init( classData:ClassData, classNameMap:ClassNameMap? ) throws {
		self.classData		= classData
		
		if let type = classData.decodedType {
			self.decodedType	= type
			return
		} else if let classNameMap {
			if let type	= classNameMap[ .mangled( classData.mangledClassName ) ] {
				self.decodedType	= type
				return
			} else if let type	= classNameMap[ .qualified( classData.className( qualified: true ) ) ] {
				self.decodedType	= type
				return
			}
		}
		
		throw Errors.GraphCodable.cantConstructClass(
			Self.self, Errors.Context(
				debugDescription:"The class |\(classData.className( qualified: true ))| can't be constructed."
			)
		)
	}
	
	var description: String {
		return classData.description
	}
	
	static func classInfoMap( classDataMap:ClassDataMap, classNameMap:ClassNameMap? ) throws -> ClassInfoMap {
		try classDataMap.mapValues {
			try ClassInfo(classData: $0, classNameMap:classNameMap )
		}
	}

	static func classInfoMapNoThrow( classDataMap:ClassDataMap, classNameMap:ClassNameMap? ) -> ClassInfoMap {
		classDataMap.compactMapValues {
			try? ClassInfo(classData: $0, classNameMap:classNameMap )
		}
	}

	static func undecodablesClassDataMap( classDataMap:ClassDataMap, classNameMap:ClassNameMap? ) -> ClassDataMap {
		classDataMap.compactMapValues {
			(try? ClassInfo(classData: $0, classNameMap:classNameMap )) == nil ? $0 : nil
		}
	}
}
