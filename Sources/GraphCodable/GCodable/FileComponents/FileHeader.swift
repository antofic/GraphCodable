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


///	FileHeader: the 24 bytes fixed size header of every gcodable file
struct FileHeader : CustomStringConvertible, BinaryIOType {
	struct Flags : OptionSet {
		let rawValue: UInt16
		static let	packBinSize		= Self( rawValue: 1 << 0 )
		
	}
	
	static var INITIAL_FILE_VERSION	: UInt32 { 0 }	// no more supported
	static var VALUEID_FILE_VERSION	: UInt32 { 1 }	// no more supported
	static var RMUNUS2_FILE_VERSION	: UInt32 { 2 }	// no more supported
	static var SECTION_FILE_VERSION	: UInt32 { 3 }	// no more supported
	static var NEWFILEBLOCK_VERSION	: UInt32 { 4 }
	static var CURRENT_FILE_VERSION	: UInt32 { NEWFILEBLOCK_VERSION }

	var supportsValueIDs		: Bool { version >= Self.VALUEID_FILE_VERSION }
	var supportsFileSections	: Bool { version >= Self.SECTION_FILE_VERSION }

	// *******************************
	
	private enum HeaderID : UInt64 {
		case gcodable	= 0x67636F6461626C65	// ascii = 'gcodable'
	}

	let version : UInt32
	let flags	: Flags
	let unused0 : UInt16
	let unused1 : UInt64
	
	var description: String {
  """
  - FILETYPE  = '\(HeaderID.gcodable)' {\(MemoryLayout<HeaderID.RawValue>.size) bytes}
  - VERSION   = \(version.format("10")) {\(MemoryLayout.size(ofValue: version)) bytes}
  - FLAGS     = \(flags.rawValue.format("10",.X)) {\(MemoryLayout.size(ofValue: flags)) bytes}
  - UNUSED0   = \(unused0.format("10",.X)) {\(MemoryLayout.size(ofValue: unused0)) bytes}
  - UNUSED1   = \(unused1.format("10",.X)) {\(MemoryLayout.size(ofValue: unused1)) bytes}
  """
	}
	
	init( version: UInt32 = CURRENT_FILE_VERSION, flags: Flags = [], unused0: UInt16 = 0, unused1: UInt64 = 0 ) {
		self.version	= version
		self.flags		= flags
		self.unused0	= unused0
		self.unused1	= unused1
	}

	private enum ObsoleteCode : UInt8, BinaryIOType {
		case header		= 0x5E	// '^'
	}

	init(from rbuffer: inout BinaryReadBuffer) throws {
		do {
			_ = ObsoleteCode.peek( from: &rbuffer ) { $0 == .header }
			
			let headerID	= try HeaderID	( from: &rbuffer )
			guard headerID == .gcodable else {
				throw GCodableError.decodingError(
					Self.self, GCodableError.Context(
						debugDescription: "Not a gcodable file."
					)
				)
			}
			
			self.version	= try UInt32	( from: &rbuffer )
			self.flags		= try Flags		( from: &rbuffer )
			self.unused0	= try UInt16	( from: &rbuffer )
			self.unused1	= try UInt64	( from: &rbuffer )
			if version < Self.RMUNUS2_FILE_VERSION {
				_	= try UInt8( from: &rbuffer )	// removed unused2 from SECTION_FILE_VERSION
			}
			if version < Self.NEWFILEBLOCK_VERSION {
				throw GCodableError.decodingError(
					Self.self, GCodableError.Context(
						debugDescription: "GCodable file version < \(Self.NEWFILEBLOCK_VERSION) are non more supported."
					)
				)
			}
		} catch( let error ) {
			throw GCodableError.invalidHeader(
				Self.self, GCodableError.Context(
					debugDescription: "Invalid gcodable header.",
					underlyingError: error
				)
			)
		}
	}

	func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try HeaderID.gcodable.write(to: &wbuffer)
		try version.write(to: &wbuffer)
		try flags.write(to: &wbuffer)
		try unused0.write(to: &wbuffer)
		try unused1.write(to: &wbuffer)
	}
}
