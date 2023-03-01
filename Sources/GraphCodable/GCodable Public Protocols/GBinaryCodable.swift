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


public protocol	GBinaryEncodable : BinaryOType, GEncodable {}
public protocol	GBinaryDecodable : BinaryIType, GDecodable {}

///	A protocol to use the `GBinaryCodable` protocol
///
///	To bypass the standard coding mechanism and use the faster
///	BinaryIO one, adopt the `GBinaryCodable` protocol and write
///	the required methods of GBinaryCodable protocol.
///
///	- Note: The GBinaryCodable protocol does not support
///	any of the GraphCodable features. Use it for simple types
///	only when it's really necessary.
public typealias GBinaryCodable = GBinaryEncodable & GBinaryDecodable

extension GBinaryEncodable {
	public func encode(to encoder: GEncoder) throws	{
		throw GCodableError.internalInconsistency(
			Self.self, GCodableError.Context(
				debugDescription: "Program must not reach this \(#function)."
			)
		)
	}
}
extension GBinaryDecodable {
	public init(from decoder: GDecoder) throws {
		throw GCodableError.internalInconsistency(
			Self.self, GCodableError.Context(
				debugDescription: "Program must not reach this \(#function)."
			)
		)
	}
}

public protocol GTrivial {}

public typealias GTrivialEncodable	= GBinaryEncodable & GTrivial
public typealias GTrivialDecodable	= GBinaryDecodable & GTrivial
public typealias GTrivialCodable	= GTrivialEncodable & GTrivialDecodable

extension String : GIdentifiable {
	public var gcodableID: String? {
		self
	}
}

extension Array : GIdentifiable where Element:GCodable {
	public var gcodableID: ObjectIdentifier? {
		withUnsafeBytes { unsafeBitCast( $0.baseAddress, to: ObjectIdentifier?.self) }
	}
}

extension ContiguousArray : GIdentifiable where Element:GCodable {
	public var gcodableID: ObjectIdentifier? {
		withUnsafeBytes { unsafeBitCast( $0.baseAddress, to: ObjectIdentifier?.self) }
	}
}

