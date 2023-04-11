//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

struct BinaryIOFlags: OptionSet {
	let rawValue: UInt16
	
	init(rawValue: UInt16) {
		self.rawValue	= rawValue
	}
	
	static let	compressionEnabled		= Self( rawValue: 1 << 0 )
	static let	hasArchiveIdentifier	= Self( rawValue: 1 << 1 )
}
