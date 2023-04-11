//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/


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

	let archiveIdentifier	: String?			// encoded/decoded by BinaryIO
	let binaryIOFlags		: BinaryIOFlags		// encoded/decoded by BinaryIO
	let binaryIOVersion		: UInt16			// encoded/decoded by BinaryIO
	let userVersion			: UInt32			// encoded/decoded by BinaryIO
	let gcodableVersion		: UInt32			// encoded/decoded by FileHeader
	let gcoadableFlags		: Flags				// encoded/decoded by FileHeader
	
	func description( fileSize:Int? ) -> String {
		func alignR( _ value:Any,length: Int = 12 ) -> String  {
			"\(value)".align( .right, length: length )
		}
		func bitString<V>( _ value:V ) -> String {
			let bits = MemoryLayout.size(ofValue: value)*8
			return "{\( alignR( bits, length:2 ) ) bit value}"
		}
		func identifier() -> String {
			if let archiveIdentifier {
				return "\"\(archiveIdentifier)\""
			} else {
				return "nil"
			}
		}
		
		var string = ""
		string.append(		  "- archiveIdentifier   = \( identifier() )")
		string.append(		"\n- binaryIOFlags       = \( alignR(binaryIOFlags.rawValue) ) \( bitString(binaryIOFlags) )")
		string.append(		"\n- binaryIOVersion     = \( alignR(binaryIOVersion) ) \( bitString(binaryIOVersion) )")
		string.append(		"\n- userVersion         = \( alignR(userVersion) ) \( bitString(userVersion) )")
		string.append(		"\n- gcodableVersion     = \( alignR(gcodableVersion) ) \( bitString(gcodableVersion) )")
		string.append(		"\n- gcodableFlags       = \( alignR(gcoadableFlags.rawValue) ) \( bitString(gcoadableFlags) )")
		if let fileSize {
			string.append(	"\n- fileSize            = \( alignR(fileSize) ) bytes")
			
		}
		return string
	}
	
	var description: String {
		description(fileSize: nil)
	}

	init(
		binaryIOEncoder:BinaryIOEncoder, gcodableVersion: UInt32 = Versions.CURRENT_FILE_VERSION,
		gcoadableFlags: Flags = [], unused0: UInt64 = 0
	) {
		self.archiveIdentifier	= binaryIOEncoder.archiveIdentifier
		self.userVersion		= binaryIOEncoder.userVersion
		self.binaryIOFlags		= binaryIOEncoder.binaryIOFlags
		self.binaryIOVersion	= binaryIOEncoder.binaryIOVersion
		self.gcodableVersion	= gcodableVersion
		self.gcoadableFlags		= gcoadableFlags
	}
	
	init(from decoder: inout some BDecoder) throws {
		let gcodableVersion		= try decoder.decode() as UInt32
		if gcodableVersion < Versions.NEWFILEBLOCK_VERSION {
			throw GraphCodableError.malformedArchive(
				Self.self, GraphCodableError.Context(
					debugDescription: "GCodable file version < \(Versions.NEWFILEBLOCK_VERSION) are non more supported."
				)
			)
		}
		self.archiveIdentifier	= decoder.encodedArchiveIdentifier
		self.userVersion		= decoder.encodedUserVersion
		self.binaryIOFlags		= decoder.withUnderlyingType { $0.encodedBinaryIOFlags }
		self.binaryIOVersion	= decoder.withUnderlyingType { $0.encodedBinaryIOVersion }
		self.gcodableVersion	= gcodableVersion
		self.gcoadableFlags		= try decoder.decode()
	}
	
	func encode( to encoder: inout some BEncoder ) throws {
		try encoder.encode( gcodableVersion )
		try encoder.encode( gcoadableFlags )
	}
}
