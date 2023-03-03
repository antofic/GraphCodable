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
	private enum Decoder {
		case new( _ : SectionBinaryDecoder )		//	>=	SECTION_FILE_VERSION
		case old( _ : OldBinaryDecoder )			//	<	SECTION_FILE_VERSION
	}
	
	let 			fileHeader	: FileHeader
	private var  	decoder		: Decoder
	
	init<Q>( from data:Q ) throws where Q:Sequence, Q.Element==UInt8 {
		var rbuffer 	= BinaryReadBuffer(data: data)

		fileHeader	= try FileHeader( from: &rbuffer )
		if fileHeader.supportsFileSections {
			decoder	= .new( try SectionBinaryDecoder( from: &rbuffer ) )
		} else {
			decoder	= .old( try OldBinaryDecoder( from: &rbuffer ) )
		}
	}

	mutating func classDataMap() throws -> ClassDataMap {
		switch decoder {
		case .new( var decoder ): return try decoder.classDataMap()
		case .old( var decoder ): return try decoder.classDataMap(fileHeader: fileHeader)
		}
	}
	
	mutating func classInfoMap() throws -> [UIntID : ClassInfo] {
		try classDataMap().mapValues {  try ClassInfo(classData: $0)  }
	}

	mutating func bodyFileBlocks() throws -> BodyBlocks {
		switch decoder {
		case .new( var decoder ): return try decoder.bodyFileBlocks(fileHeader: fileHeader)
		case .old( var decoder ): return try decoder.bodyFileBlocks(fileHeader: fileHeader)
		}
	}

	mutating func keyStringMap() throws -> KeyStringMap {
		switch decoder {
		case .new( var decoder ): return try decoder.keyStringMap()
		case .old( var decoder ): return try decoder.keyStringMap(fileHeader: fileHeader)
		}
	}
	
	// -------------------------------------------------
	// ----- SinglePassSectionBinaryDecoder
	// -------------------------------------------------

	private struct SectionBinaryDecoder {
		private	var sectionMap			: SectionMap
		private var rbuffer				: BinaryReadBuffer

		private var _classDataMap		: ClassDataMap?
		private var _bodyFileBlocks		: BodyBlocks?
		private var _keyStringMap		: KeyStringMap?
		
		init( from rbuffer:inout BinaryReadBuffer ) throws {
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
		
		mutating func bodyFileBlocks( fileHeader:FileHeader ) throws -> BodyBlocks {
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

	// -------------------------------------------------
	// ----- OldBinaryDecoder
	// -------------------------------------------------

	private struct OldBinaryDecoder {
		enum CompatibleFileBlock {
			case current( fileBlock:FileBlock )
			case obsolete( fileBlock:FileBlockObsolete )

			init(from rbuffer: inout BinaryReadBuffer, fileHeader:FileHeader ) throws {
				var obsolete	= false
				let _ = FileBlockObsolete.peek(from: &rbuffer) {
					_ in
					obsolete	= true
					return false
				}
				if obsolete {
					self	= .obsolete(fileBlock: try FileBlockObsolete(from: &rbuffer))
				} else {
					self	= .current(fileBlock: try FileBlock(from: &rbuffer, fileHeader:fileHeader ))
				}
			}
		}
		
		private var rbuffer				: BinaryReadBuffer

		private var _classDataMap		= ClassDataMap()
		private var _bodyFileBlocks		= BodyBlocks()
		private var _keyStringMap		= KeyStringMap()

		private var currentBlock		: CompatibleFileBlock?
		private var phase				: FileSection
		
		init( from rbuffer:inout BinaryReadBuffer ) throws {
			self.rbuffer	= rbuffer
			self.phase		= .classDataMap
		}

		mutating func classDataMap( fileHeader:FileHeader ) throws -> ClassDataMap {
			try parseTypeMap(fileHeader: fileHeader)
			return _classDataMap
		}

		mutating func bodyFileBlocks( fileHeader:FileHeader ) throws -> BodyBlocks {
			try parseTypeMap(fileHeader: fileHeader)
			try parseBody(fileHeader: fileHeader)
			
			return _bodyFileBlocks
		}

		mutating func keyStringMap( fileHeader:FileHeader ) throws -> KeyStringMap {
			try parseTypeMap(fileHeader: fileHeader)
			try parseBody(fileHeader: fileHeader)
			try parseKeyMap(fileHeader: fileHeader)

			return _keyStringMap
		}

		// private section
		
		private mutating func peek( fileHeader:FileHeader ) throws -> CompatibleFileBlock? {
			if currentBlock == nil {
				currentBlock	= rbuffer.isEof ? nil : try CompatibleFileBlock(from: &rbuffer, fileHeader: fileHeader)
			}
			return currentBlock
		}

		private mutating func step() {
			currentBlock = nil
		}

		private mutating func parseTypeMap( fileHeader:FileHeader ) throws {
			guard phase == .classDataMap else { return }

			while let compatibleBlock	= try peek(fileHeader: fileHeader) {
				switch compatibleBlock {
				case .obsolete( let dataBlock ):
					switch dataBlock {
					case .classDataMap( let typeID, let classData ):
						// ••• PHASE 1 •••
						guard _classDataMap.index(forKey: typeID) == nil else {
							throw GCodableError.duplicateTypeID(
								Self.self, GCodableError.Context(
									debugDescription: "TypeID -\(typeID)- already used."
								)
							)
						}
						_classDataMap[typeID]	= classData
					default:
						self.phase	= .body
						return
					}
				default:
					self.phase	= .body
					return
				}
				step()
			}
		}
		
		private mutating func parseBody( fileHeader:FileHeader ) throws {
			guard phase == .body else { return }

			while let compatibleBlock	= try peek(fileHeader: fileHeader) {
				switch compatibleBlock {
				case .current( let dataBlock ):
					_bodyFileBlocks.append( dataBlock )
				default:
					self.phase	= .keyStringMap
					return
				}
				step()
			}
		}

		private mutating func parseKeyMap( fileHeader:FileHeader ) throws {
			guard phase == .keyStringMap else { return }

			while let compatibleBlock	= try peek(fileHeader: fileHeader) {
				switch compatibleBlock {
				case .obsolete( let dataBlock ):
					switch dataBlock {
					case .keyStringMap( let keyID, let key ):
						guard _keyStringMap.index(forKey: keyID) == nil else {
							throw GCodableError.duplicateKey(
								Self.self, GCodableError.Context(
									debugDescription: "Key -\(key)- already used."
								)
							)
						}
						_keyStringMap[keyID]	= key
					default:
						return
					}
				default:
					return
				}
				step()
			}
		}
	}
}

