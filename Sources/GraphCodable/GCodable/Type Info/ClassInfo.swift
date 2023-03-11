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

struct ClassInfo : CustomStringConvertible {
	let	decodableType:	(AnyObject & GDecodable).Type
	let	classData:		ClassData
	
	init( classData:ClassData, classNameMap:ClassNameMap? ) throws {
		self.classData		= classData

		if let decodableType = classData.decodableType {
			self.decodableType	= decodableType
			return
		} else if let classNameMap {
			if let decodableType = classNameMap[ .qualifiedName(classData.qualifiedName) ] {
				self.decodableType	= decodableType
				return
			} else if let decodableType	= classNameMap[ .mangledName(classData.mangledName) ] {
				self.decodableType	= decodableType
				return
			}
		}
		
		throw GCodableError.cantConstructClass(
			Self.self, GCodableError.Context(
				debugDescription:"The class -\(classData.qualifiedName)- can't be constructed."
			)
		)
	}

	var description: String {
		return classData.description
	}
}
