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
struct FileHeader : CustomStringConvertible, BCodable {
	
	struct Flags : OptionSet, BCodable {
		let rawValue: UInt16
		static let	useBinaryIOInsert		= Self( rawValue: 1 << 0 )
	}
	private enum Versions {
		static var NEWFILEBLOCK_VERSION	: UInt32 { 4 }
		static var CURRENT_FILE_VERSION	: UInt32 { NEWFILEBLOCK_VERSION }
	}

	private enum HeaderID : UInt32, BCodable {
		case gcod	= 0x67636F64	// ascii = 'gcod'
	}

	let userVersion		: UInt32
	let binaryIOFlags	: BinaryIOFlags
	let binaryIOVersion	: UInt16
	let gcodableVersion	: UInt32
	let gcoadableFlags	: Flags
	let unused0 		: UInt16
	let unused1 		: UInt64
	
	func description( dataSize:Int? ) -> String {
		func alignR( _ value:Any,length: Int = 12 ) -> String  {
			"\(value)".align( .right, length: length )
		}
		func bitString<V>( _ value:V ) -> String {
			let bits = MemoryLayout.size(ofValue: value)*8
			return "{\( alignR( bits, length:2 ) ) bit value}"
		}
		
		var string = ""
		string.append(		  "- binaryIOFlags       = \( alignR(binaryIOFlags.rawValue) ) \( bitString(binaryIOFlags) )")
		string.append(		"\n- binaryIOVersion     = \( alignR(binaryIOVersion) ) \( bitString(binaryIOVersion) )")
		string.append(		"\n- userVersion         = \( alignR(userVersion) ) \( bitString(userVersion) )")
		string.append(		"\n- fileType            = \( alignR(HeaderID.gcod) ) \( bitString(HeaderID.gcod.rawValue) )")
		string.append(		"\n- gcodableVersion     = \( alignR(gcodableVersion) ) \( bitString(gcodableVersion) )")
		string.append(		"\n- gcodableFlags       = \( alignR(gcoadableFlags.rawValue) ) \( bitString(gcoadableFlags) )")
		if let dataSize {
			string.append(	"\n- fileSize            = \( alignR(dataSize) ) bytes")
			
		}
		return string
	}
	
	/*
	func description( dataSize:Int? ) -> String {
		func alignR( _ value:Any ) -> String  {
			"\(value)".align( .right, length: 12 )
		}
		
		var string = ""
		string.append(		  "- binaryIOFlags       = \( alignR(binaryIOFlags.rawValue) ) {\(MemoryLayout.size(ofValue: binaryIOFlags)) bytes}")
		string.append(		"\n- binaryIOVersion     = \( alignR(binaryIOVersion) ) {\(MemoryLayout.size(ofValue: binaryIOVersion)) bytes}")
		string.append(		"\n- userVersion         = \( alignR(userVersion) ) {\(MemoryLayout.size(ofValue: userVersion)) bytes}")
		string.append(		"\n- fileType            = \( alignR(HeaderID.gcod) ) {\(MemoryLayout<HeaderID.RawValue>.size) bytes}")
		string.append(		"\n- gcodableVersion     = \( alignR(gcodableVersion) ) {\(MemoryLayout.size(ofValue: gcodableVersion)) bytes}")
		string.append(		"\n- gcodableFlags       = \( alignR(gcoadableFlags.rawValue) ) {\(MemoryLayout.size(ofValue: gcoadableFlags)) bytes}")
		if let dataSize {
			string.append(	"\n- fileSize            = \( alignR(dataSize) ) bytes")
			
		}
		return string
	}
	*/
	
	var description: String {
		description(dataSize: nil)
	}

	init(
		binaryIOEncoder:BinaryIOEncoder, gcodableVersion: UInt32 = Versions.CURRENT_FILE_VERSION,
		gcoadableFlags: Flags = [], unused0: UInt16 = 0, unused1: UInt64 = 0
	) {
		self.userVersion		= binaryIOEncoder.userVersion
		self.binaryIOFlags		= binaryIOEncoder.binaryIOFlags
		self.binaryIOVersion	= binaryIOEncoder.binaryIOVersion
		self.gcodableVersion	= gcodableVersion
		self.gcoadableFlags		= gcoadableFlags
		self.unused0			= unused0
		self.unused1			= unused1
	}
	
	init(from decoder: inout some BDecoder) throws {
		let headerID	= try decoder.decode() as HeaderID
		guard headerID == .gcod else {
			throw GraphCodableError.malformedArchive(
				Self.self, GraphCodableError.Context(
					debugDescription: "Not a gcodable file."
				)
			)
		}
		let gcodableVersion		= try decoder.decode() as UInt32
		if gcodableVersion < Versions.NEWFILEBLOCK_VERSION {
			throw GraphCodableError.malformedArchive(
				Self.self, GraphCodableError.Context(
					debugDescription: "GCodable file version < \(Versions.NEWFILEBLOCK_VERSION) are non more supported."
				)
			)
		}
		self.userVersion		= decoder.encodedUserVersion
		self.binaryIOFlags		= decoder.withUnderlyingType { $0.encodedBinaryIOFlags }
		self.binaryIOVersion	= decoder.withUnderlyingType { $0.encodedBinaryIOVersion }
		self.gcodableVersion	= gcodableVersion
		self.gcoadableFlags		= try decoder.decode()
		self.unused0			= try decoder.decode()
		self.unused1			= try decoder.decode()
	}
	
	func encode( to encoder: inout some BEncoder ) throws {
		try encoder.encode( HeaderID.gcod )
		try encoder.encode( gcodableVersion )
		try encoder.encode( gcoadableFlags )
		try encoder.encode( unused0 )
		try encoder.encode( unused1 )
	}
}
