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

struct FileBlockDecoder {
	let 		fileHeader		: FileHeader
	private	var sectionMap		: SectionMap
	private var rbuffer			: BinaryReadBuffer

	private var _classDataMap	: ClassDataMap?
	private var _fileBlocks		: FileBlocks?
	private var _keyStringMap	: KeyStringMap?

	init( from readBuffer:BinaryReadBuffer ) throws {
		self.rbuffer		= readBuffer
		self.fileHeader		= try FileHeader( from: &rbuffer )
		self.sectionMap		= try type(of:sectionMap).init(from: &rbuffer)
	}
	
	mutating func classDataMap() throws -> ClassDataMap {
		if let classDataMap = self._classDataMap { return classDataMap }
		
		let saveRegion	= try setReaderRegionTo(section: .classDataMap)
		defer { rbuffer.currentRegion = saveRegion }

		let classDataMap	= try ClassDataMap(from: &rbuffer)
		self._classDataMap	= classDataMap
		return classDataMap
	}
	
	mutating func classInfoMap() throws -> ClassInfoMap {
		try classDataMap().mapValues {  try ClassInfo(classData: $0)  }
	}

	mutating func fileBlocks() throws -> FileBlocks {
		if let fileBlocks = self._fileBlocks { return fileBlocks }

		let saveRegion	= try setReaderRegionTo(section: .body)
		defer { rbuffer.currentRegion = saveRegion }

		var fileBlocks	= [FileBlock]()
		while rbuffer.isEof == false {
			fileBlocks.append( try FileBlock(from: &rbuffer, fileHeader: fileHeader) )
		}
		
		self._fileBlocks	= fileBlocks
		return fileBlocks
	}

	mutating func keyStringMap() throws -> KeyStringMap {
		if let keyStringMap = self._keyStringMap { return keyStringMap }

		let saveRegion		= try setReaderRegionTo(section: .keyStringMap)
		defer { rbuffer.currentRegion = saveRegion }
		
		let keyStringMap 	= try KeyStringMap(from: &rbuffer)
		self._keyStringMap	= keyStringMap
		return keyStringMap
	}
	
	private mutating func setReaderRegionTo( section:FileSection ) throws -> Range<Int> {
		guard let range = sectionMap[ section ] else {
			throw GCodableError.decodingError(
				Self.self, GCodableError.Context(
					debugDescription: "File section \(section) not found."
				)
			)
		}
		defer { rbuffer.currentRegion = range }
		return rbuffer.currentRegion
	}
}

