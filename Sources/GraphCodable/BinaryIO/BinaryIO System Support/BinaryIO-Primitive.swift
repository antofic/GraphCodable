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

// Bool ------------------------------------------------------

extension Bool: BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try withUnsafeMutablePointer(to: &encoder) {
			try $0.withMemoryRebound(to: BinaryIOEncoder.self, capacity: 1) {
				try $0.pointee.encodeBool( self )
			}
		}
	}
}


extension Bool: BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self = try withUnsafeMutablePointer(to: &decoder) {
			try $0.withMemoryRebound(to: BinaryIODecoder.self, capacity: 1) {
				try $0.pointee.decodeBool()
			}
		}
	}
}

// Signed Integers ------------------------------------------------------

extension Int: BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try withUnsafeMutablePointer(to: &encoder) {
			try $0.withMemoryRebound(to: BinaryIOEncoder.self, capacity: 1) {
				try $0.pointee.encodeInt( self )
			}
		}
	}
}

extension Int: BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self = try withUnsafeMutablePointer(to: &decoder) {
			try $0.withMemoryRebound(to: BinaryIODecoder.self, capacity: 1) {
				try $0.pointee.decodeInt()
			}
		}
	}
}

extension Int8: BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try withUnsafeMutablePointer(to: &encoder) {
			try $0.withMemoryRebound(to: BinaryIOEncoder.self, capacity: 1) {
				try $0.pointee.encodeInt8( self )
			}
		}
	}
}

extension Int8: BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self = try withUnsafeMutablePointer(to: &decoder) {
			try $0.withMemoryRebound(to: BinaryIODecoder.self, capacity: 1) {
				try $0.pointee.decodeInt8()
			}
		}
	}
}
extension Int16: BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try withUnsafeMutablePointer(to: &encoder) {
			try $0.withMemoryRebound(to: BinaryIOEncoder.self, capacity: 1) {
				try $0.pointee.encodeInt16( self )
			}
		}
	}
}

extension Int16: BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self = try withUnsafeMutablePointer(to: &decoder) {
			try $0.withMemoryRebound(to: BinaryIODecoder.self, capacity: 1) {
				try $0.pointee.decodeInt16()
			}
		}
	}
}
extension Int32: BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try withUnsafeMutablePointer(to: &encoder) {
			try $0.withMemoryRebound(to: BinaryIOEncoder.self, capacity: 1) {
				try $0.pointee.encodeInt32( self )
			}
		}
	}
}

extension Int32: BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self = try withUnsafeMutablePointer(to: &decoder) {
			try $0.withMemoryRebound(to: BinaryIODecoder.self, capacity: 1) {
				try $0.pointee.decodeInt32()
			}
		}
	}
}
extension Int64: BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try withUnsafeMutablePointer(to: &encoder) {
			try $0.withMemoryRebound(to: BinaryIOEncoder.self, capacity: 1) {
				try $0.pointee.encodeInt64( self )
			}
		}
	}
}

extension Int64: BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self = try withUnsafeMutablePointer(to: &decoder) {
			try $0.withMemoryRebound(to: BinaryIODecoder.self, capacity: 1) {
				try $0.pointee.decodeInt64()
			}
		}
	}
}

// Unsigned Integers ------------------------------------------------------

extension UInt: BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try withUnsafeMutablePointer(to: &encoder) {
			try $0.withMemoryRebound(to: BinaryIOEncoder.self, capacity: 1) {
				try $0.pointee.encodeUInt( self )
			}
		}
	}
}

extension UInt: BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self = try withUnsafeMutablePointer(to: &decoder) {
			try $0.withMemoryRebound(to: BinaryIODecoder.self, capacity: 1) {
				try $0.pointee.decodeUInt()
			}
		}
	}
}

extension UInt8: BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try withUnsafeMutablePointer(to: &encoder) {
			try $0.withMemoryRebound(to: BinaryIOEncoder.self, capacity: 1) {
				try $0.pointee.encodeUInt8( self )
			}
		}
	}
}

extension UInt8: BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self = try withUnsafeMutablePointer(to: &decoder) {
			try $0.withMemoryRebound(to: BinaryIODecoder.self, capacity: 1) {
				try $0.pointee.decodeUInt8()
			}
		}
	}
}
extension UInt16: BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try withUnsafeMutablePointer(to: &encoder) {
			try $0.withMemoryRebound(to: BinaryIOEncoder.self, capacity: 1) {
				try $0.pointee.encodeUInt16( self )
			}
		}
	}
}

extension UInt16: BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self = try withUnsafeMutablePointer(to: &decoder) {
			try $0.withMemoryRebound(to: BinaryIODecoder.self, capacity: 1) {
				try $0.pointee.decodeUInt16()
			}
		}
	}
}
extension UInt32: BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try withUnsafeMutablePointer(to: &encoder) {
			try $0.withMemoryRebound(to: BinaryIOEncoder.self, capacity: 1) {
				try $0.pointee.encodeUInt32( self )
			}
		}
	}
}

extension UInt32: BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self = try withUnsafeMutablePointer(to: &decoder) {
			try $0.withMemoryRebound(to: BinaryIODecoder.self, capacity: 1) {
				try $0.pointee.decodeUInt32()
			}
		}
	}
}
extension UInt64: BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try withUnsafeMutablePointer(to: &encoder) {
			try $0.withMemoryRebound(to: BinaryIOEncoder.self, capacity: 1) {
				try $0.pointee.encodeUInt64( self )
			}
		}
	}
}

extension UInt64: BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self = try withUnsafeMutablePointer(to: &decoder) {
			try $0.withMemoryRebound(to: BinaryIODecoder.self, capacity: 1) {
				try $0.pointee.decodeUInt64()
			}
		}
	}
}

// Float ------------------------------------------------------

extension Float: BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try withUnsafeMutablePointer(to: &encoder) {
			try $0.withMemoryRebound(to: BinaryIOEncoder.self, capacity: 1) {
				try $0.pointee.encodeFloat( self )
			}
		}
	}
}


extension Float: BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self = try withUnsafeMutablePointer(to: &decoder) {
			try $0.withMemoryRebound(to: BinaryIODecoder.self, capacity: 1) {
				try $0.pointee.decodeFloat()
			}
		}
	}
}

// Double ------------------------------------------------------

extension Double: BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try withUnsafeMutablePointer(to: &encoder) {
			try $0.withMemoryRebound(to: BinaryIOEncoder.self, capacity: 1) {
				try $0.pointee.encodeDouble( self )
			}
		}
	}
}

extension Double: BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self = try withUnsafeMutablePointer(to: &decoder) {
			try $0.withMemoryRebound(to: BinaryIODecoder.self, capacity: 1) {
				try $0.pointee.decodeDouble()
			}
		}
	}
}

// String ------------------------------------------------------

extension String: BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try withUnsafeMutablePointer(to: &encoder) {
			try $0.withMemoryRebound(to: BinaryIOEncoder.self, capacity: 1) {
				try $0.pointee.encodeString( self )
			}
		}
	}
}

extension String: BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self = try withUnsafeMutablePointer(to: &decoder) {
			try $0.withMemoryRebound(to: BinaryIODecoder.self, capacity: 1) {
				try $0.pointee.decodeString()
			}
		}
	}
}


// -- Data support -------------------------------------------------------

extension Data: BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try withUnsafeMutablePointer(to: &encoder) {
			try $0.withMemoryRebound(to: BinaryIOEncoder.self, capacity: 1) {
				try $0.pointee.encodeData( self )
			}
		}
	}
}

extension Data: BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self = try withUnsafeMutablePointer(to: &decoder) {
			try $0.withMemoryRebound(to: BinaryIODecoder.self, capacity: 1) {
				try $0.pointee.decodeData()
			}
		}
	}
}
