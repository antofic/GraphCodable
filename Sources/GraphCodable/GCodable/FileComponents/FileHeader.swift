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
		static var NEWFILEBLOCK_VERSION	: UInt32 { 4 }
		static var CURRENT_FILE_VERSION	: UInt32 { NEWFILEBLOCK_VERSION }
	}

	// *******************************
	/*
	private enum OLDHeaderID : UInt64 {
		case gcodable	= 0x67636F6461626C65	// ascii = 'gcodable'
	}
	 */
	private enum HeaderID : UInt32 {
		case gcod	= 0x67636F64	// ascii = 'gcod'
	}

	let userVersion		: UInt32
	let binaryIOVersion	: UInt32
	let gcodableVersion	: UInt32
	let flags			: Flags
	let unused0 		: UInt16
	let unused1 		: UInt64
		
	func description( dataSize:Int? ) -> String {
		var string = ""
		
		string.append(		  "- fileType            =       '\(HeaderID.gcod)' {\(MemoryLayout<HeaderID.RawValue>.size) bytes}")
		string.append(		"\n- userVersion         = \(userVersion.format("12")) {\(MemoryLayout.size(ofValue: userVersion)) bytes}")
		string.append(		"\n- gcodableVersion     = \(gcodableVersion.format("12")) {\(MemoryLayout.size(ofValue: gcodableVersion)) bytes}")
		string.append(		"\n- binaryIOVersion     = \(binaryIOVersion.format("12")) {\(MemoryLayout.size(ofValue: binaryIOVersion)) bytes}")
		string.append(		"\n- flags               = \(flags.rawValue.format("12",.X)) {\(MemoryLayout.size(ofValue: flags)) bytes}")
		if let dataSize {
			string.append(	"\n- data size           = \(dataSize.format("12")) bytes")
		}
		return string
	}
	
	var description: String {
		description(dataSize: nil)
	}
	
	init(
		userVersion:UInt32, binaryIOVersion:UInt32, gcodableVersion: UInt32 = Versions.CURRENT_FILE_VERSION,
		flags: Flags = [], unused0: UInt16 = 0, unused1: UInt64 = 0
	) {
		self.userVersion		= userVersion
		self.binaryIOVersion	= binaryIOVersion
		self.gcodableVersion	= gcodableVersion
		self.flags				= flags
		self.unused0			= unused0
		self.unused1			= unused1
	}

	init(from rbuffer: inout BinaryReadBuffer) throws {
		let headerID	= try HeaderID	( from: &rbuffer )
		guard headerID == .gcod else {
			throw GCodableError.decodingError(
				Self.self, GCodableError.Context(
					debugDescription: "Not a gcodable file."
				)
			)
		}
		let gcodableVersion		= try UInt32	( from: &rbuffer )
		if gcodableVersion < Versions.NEWFILEBLOCK_VERSION {
			throw GCodableError.decodingError(
				Self.self, GCodableError.Context(
					debugDescription: "GCodable file version < \(Versions.NEWFILEBLOCK_VERSION) are non more supported."
				)
			)
		}
		
		self.userVersion		= rbuffer.encodedUserVersion
		self.binaryIOVersion	= rbuffer.binaryIOVersion
		self.gcodableVersion	= gcodableVersion
		self.flags				= try Flags		( from: &rbuffer )
		self.unused0			= try UInt16	( from: &rbuffer )
		self.unused1			= try UInt64	( from: &rbuffer )
	}

	func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try HeaderID.gcod.write(to: &wbuffer)
		try gcodableVersion.write(to: &wbuffer)
		try flags.write(to: &wbuffer)
		try unused0.write(to: &wbuffer)
		try unused1.write(to: &wbuffer)
	}
}
