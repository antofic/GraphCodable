//	MIT License
//
//	Copyright (c) 2021 Antonino Ficarra
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

struct FileHeader : CustomStringConvertible, BinaryIOType {
	static var INITIAL_FILE_VERSION	: UInt32 { 0 }
	static var VALUEID_FILE_VERSION	: UInt32 { 1 }
	static var RMUNUS2_FILE_VERSION	: UInt32 { 2 }
	static var SECTION_FILE_VERSION	: UInt32 { 3 }
	static var CURRENT_FILE_VERSION	: UInt32 { SECTION_FILE_VERSION }

	var supportsValueIDs		: Bool { version >= Self.VALUEID_FILE_VERSION }
	var supportsFileSections	: Bool { version >= Self.SECTION_FILE_VERSION }

	// *******************************
	
	private enum HeaderID : UInt64 {
		case gcodable	= 0x67636F6461626C65	// ascii = 'gcodable'
	}

	let version : UInt32
	let unused0 : UInt32
	let unused1 : UInt64
	
	var description: String {
		"FILETYPE = \(HeaderID.gcodable) V\(version), U0 = \(unused0), U1 = \(unused1)"
	}
	
	init( version: UInt32 = CURRENT_FILE_VERSION, unused0: UInt32 = 0, unused1: UInt64 = 0 ) {
		self.version = version	// Self.CURRENT_FILE_VERSION
		self.unused0 = unused0
		self.unused1 = unused1
	}

	private enum ObsoleteCode : UInt8, BinaryIOType {
		case header		= 0x5E	// '^'
	}

	init(from rbuffer: inout BinaryReadBuffer) throws {
		do {
			_ = ObsoleteCode.peek( from: &rbuffer ) {
				$0 == .header
			}
			
			let headerID	= try HeaderID	( from: &rbuffer )
			guard headerID == .gcodable else {
				throw GCodableError.decodingError(
					Self.self, GCodableError.Context(
						debugDescription: "Not a gcodable file."
					)
				)
			}
			
			self.version	= try UInt32	( from: &rbuffer )
			self.unused0	= try UInt32	( from: &rbuffer )
			self.unused1	= try UInt64	( from: &rbuffer )
			if version < Self.RMUNUS2_FILE_VERSION {
				_	= try UInt8( from: &rbuffer )	// removed unused2 from SECTION_FILE_VERSION
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
		try unused0.write(to: &wbuffer)
		try unused1.write(to: &wbuffer)
	}
}
