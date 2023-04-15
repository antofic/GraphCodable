//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

struct BinaryIOFlags: OptionSet {
	typealias RawValue = UInt16
	
	let rawValue: RawValue

	var isValid: Bool {
		Self.validFlags.contains( self )
	}

	init( rawValue:RawValue ) {
		self.rawValue = rawValue
	}

	// compression is enabled
	static let	compressionEnabled		= Self( rawValue: 1 << 0 )
	// archiveIdentifier is not nil
	static let	hasArchiveIdentifier	= Self( rawValue: 1 << 1 )
	
	private static let validFlags		= Self(
		rawValue:compressionEnabled.rawValue + hasArchiveIdentifier.rawValue
	)
}
