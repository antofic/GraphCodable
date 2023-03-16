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
	private enum Versions {
		static var INITIAL_FILE_VERSION	: UInt16 { 0 }	// no more supported
		static var VALUEID_FILE_VERSION	: UInt16 { 1 }	// no more supported
		static var RMUNUS2_FILE_VERSION	: UInt16 { 2 }	// no more supported
		static var SECTION_FILE_VERSION	: UInt16 { 3 }	// no more supported
		static var NEWFILEBLOCK_VERSION	: UInt16 { 4 }
//		static var USER_VERSION_VERSION	: UInt16 { 5 }
		static var CURRENT_FILE_VERSION	: UInt16 { NEWFILEBLOCK_VERSION }
	}

	var supportsValueIDs		: Bool { privateVersion >= Versions.VALUEID_FILE_VERSION }
	var supportsFileSections	: Bool { privateVersion >= Versions.SECTION_FILE_VERSION }

	// *******************************
	
	private enum HeaderID : UInt64 {
		case gcodable	= 0x67636F6461626C65	// ascii = 'gcodable'
	}

	let userVersion		: UInt16
	let privateVersion	: UInt16
	let flags			: Flags
	let unused0 		: UInt16
	let unused1 		: UInt64
	
	var description: String {
  """
  - FileType       = '\(HeaderID.gcodable)' {\(MemoryLayout<HeaderID.RawValue>.size) bytes}
  - UserVersion    = \(userVersion.format("10")) {\(MemoryLayout.size(ofValue: userVersion)) bytes}
  - PrivateVersion = \(privateVersion.format("10")) {\(MemoryLayout.size(ofValue: privateVersion)) bytes}
  - Flags          = \(flags.rawValue.format("10",.X)) {\(MemoryLayout.size(ofValue: flags)) bytes}
  - Unused0        = \(unused0.format("10",.X)) {\(MemoryLayout.size(ofValue: unused0)) bytes}
  - Unused1        = \(unused1.format("10",.X)) {\(MemoryLayout.size(ofValue: unused1)) bytes}
  """
	}
	
	init( userVersion:UInt16, privateVersion: UInt16 = Versions.CURRENT_FILE_VERSION, flags: Flags = [], unused0: UInt16 = 0, unused1: UInt64 = 0 ) {
		self.userVersion		= userVersion
		self.privateVersion		= privateVersion
		self.flags				= flags
		self.unused0			= unused0
		self.unused1			= unused1
	}

	init(from rbuffer: inout BinaryReadBuffer) throws {
		let headerID	= try HeaderID	( from: &rbuffer )
		guard headerID == .gcodable else {
			throw GCodableError.decodingError(
				Self.self, GCodableError.Context(
					debugDescription: "Not a gcodable file."
				)
			)
		}
		
		self.userVersion	= try UInt16	( from: &rbuffer )
		self.privateVersion	= try UInt16	( from: &rbuffer )
		self.flags			= try Flags		( from: &rbuffer )
		self.unused0		= try UInt16	( from: &rbuffer )
		self.unused1		= try UInt64	( from: &rbuffer )
		if privateVersion < Versions.RMUNUS2_FILE_VERSION {
			_	= try UInt8( from: &rbuffer )	// removed unused2 from SECTION_FILE_VERSION
		}
		if privateVersion < Versions.NEWFILEBLOCK_VERSION {
			throw GCodableError.decodingError(
				Self.self, GCodableError.Context(
					debugDescription: "GCodable file version < \(Versions.NEWFILEBLOCK_VERSION) are non more supported."
				)
			)
		}
	}

	func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try HeaderID.gcodable.write(to: &wbuffer)
		try userVersion.write(to: &wbuffer)
		try privateVersion.write(to: &wbuffer)
		try flags.write(to: &wbuffer)
		try unused0.write(to: &wbuffer)
		try unused1.write(to: &wbuffer)
	}
}
