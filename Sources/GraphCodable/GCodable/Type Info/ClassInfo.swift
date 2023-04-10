//	MIT License
//
//	Copyright (c) 2021-2023 Antonino Ficarra
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
			if let type	= classNameMap[ .mangledName(classData.mangledName) ] {
				self.decodedType	= type
				return
			} else if let type = classNameMap[ .qualifiedName(classData.qualifiedName) ] {
				self.decodedType	= type
				return
			}
		}
		
		throw GraphCodableError.cantConstructClass(
			Self.self, GraphCodableError.Context(
				debugDescription:"The class \(classData.qualifiedName) can't be constructed."
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
