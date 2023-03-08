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

import Foundation

typealias ClassInfoMap	= [TypeID:ClassInfo]

struct BinaryDecoder {
	let fileHeader			: FileHeader
	let	classInfoMap		: ClassInfoMap
	let rootElement 		: FlattenedElement
	private var	elementMap	: ElementMap
	
	init( from readBuffer:BinaryReadBuffer ) throws {
		var binaryDecoder	= try ReadBlockDecoder( from: readBuffer )
		let fileHeader		= binaryDecoder.fileHeader
		let rFileBlocks		= try binaryDecoder.readBlocks()
		let classInfoMap	= try binaryDecoder.classInfoMap()
		let keyStringMap	= try binaryDecoder.keyStringMap()
		
		self.fileHeader		= fileHeader
		self.classInfoMap	= classInfoMap
		(self.rootElement,self.elementMap)	= try FlattenedElement.rootElement(
			rFileBlocks:	rFileBlocks,
			keyStringMap:	keyStringMap,
			reverse:	true
		)
	}
	
	mutating func pop( objID:ObjID ) -> FlattenedElement? {
		elementMap.removeValue( forKey: objID )
	}
	
}


