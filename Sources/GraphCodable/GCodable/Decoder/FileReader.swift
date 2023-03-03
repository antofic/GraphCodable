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

struct FileReader {
	let 		fileHeader		: FileHeader
	private	var sectionMap		: SectionMap
	private var rbuffer			: BinaryReadBuffer

	private var _classDataMap	: ClassDataMap?
	private var _bodyFileBlocks	: BodyBlocks?
	private var _keyStringMap	: KeyStringMap?

	init<Q>( from data:Q ) throws where Q:Sequence, Q.Element==UInt8 {
		var rbuffer 	= BinaryReadBuffer(data: data)

		self.fileHeader		= try FileHeader( from: &rbuffer )
		self.sectionMap		= try type(of:sectionMap).init(from: &rbuffer)
		self.rbuffer		= rbuffer
	}

	mutating func classDataMap() throws -> ClassDataMap {
		if let classMap = _classDataMap { return classMap }
		
		let saveRegion	= try setReaderRegionTo(section: .classDataMap)
		defer { rbuffer.currentRegion = saveRegion }

		_classDataMap	= try ClassDataMap(from: &rbuffer)
		return _classDataMap!
	}
	
	mutating func classInfoMap() throws -> [UIntID : ClassInfo] {
		try classDataMap().mapValues {  try ClassInfo(classData: $0)  }
	}

	mutating func bodyFileBlocks() throws -> BodyBlocks {
		if let bodyBlocks = _bodyFileBlocks { return bodyBlocks }

		let saveRegion	= try setReaderRegionTo(section: .body)
		defer { rbuffer.currentRegion = saveRegion }

		var bodyBlocks	= [FileBlock]()
		while rbuffer.isEof == false {
			bodyBlocks.append( try FileBlock(from: &rbuffer, fileHeader: fileHeader) )
		}
		
		_bodyFileBlocks	= bodyBlocks
		return bodyBlocks
	}

	mutating func keyStringMap() throws -> KeyStringMap {
		if let keyStringMap = _keyStringMap { return keyStringMap }

		let saveRegion	= try setReaderRegionTo(section: .keyStringMap)
		defer { rbuffer.currentRegion = saveRegion }
		
		_keyStringMap	= try KeyStringMap(from: &rbuffer)
		return _keyStringMap!
	}
	
	private mutating func setReaderRegionTo( section:FileSection ) throws -> Range<Int> {
		guard let range = sectionMap[ section ] else {
			throw GCodableError.decodingError(
				Self.self, GCodableError.Context(
					debugDescription: "fileRange not found while body parsing."
				)
			)
		}
		defer { rbuffer.currentRegion = range }
		return rbuffer.currentRegion
	}
}

