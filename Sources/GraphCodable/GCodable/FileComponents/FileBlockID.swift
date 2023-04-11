//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation


protocol FileBlockID: Hashable, BCodable, CustomStringConvertible {
	associatedtype uID : FixedWidthInteger & UnsignedInteger & BCodable
	
	init( _ id:uID )
	var id : uID { get }
}

extension FileBlockID {
	init() {
		self.init( 1 )
	}

	func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( id )
	}
	
	init(from decoder: inout some BDecoder) throws {
		self.init( try decoder.decode() )
	}
	
	var next : Self {
		return Self( id + 1 )
	}
	
	var description: String {
		return "\(id)".align(.right, length: 4, filler: "0")
	}
}

//	I put these integers in three different structures
//	so that there is no way to swap them as they often
//	appear together in FileBlocks.

///	An unique id for value/reference identity
struct IdnID : FileBlockID {
	let id: UInt32
	init(_ id: UInt32) { self.id = id }
}

///	An unique id for a field key
struct KeyID : FileBlockID {
	let id: UInt32
	init(_ id: UInt32) { self.id = id }
}

///	An unique id for reference inheritance
struct RefID : FileBlockID {
	let id: UInt32
	init(_ id: UInt32) { self.id = id }
}
