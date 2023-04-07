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


public protocol	GBinaryEncodable : BEncodable, GEncodable {}
public protocol	GBinaryDecodable : BDecodable, GDecodable {}

///	To bypass the standard coding mechanism and use the faster
///	`BCodable` one, adopt the `GBinaryCodable` protocol and write
///	the required methods of `BCodable` protocol to encode and decode
///	the fields of the type.
///
///	You can use GBinaryEncodable when you still want to give type
///	identity and/or inheritance in case of reference types,
///	but all its fields are trivial.
///
///	In the case of generic types, GBinaryEncodable can be applied
///	when the generic fields are trivial, leaving the normal mechanism
///	to operate when they are not.
///
///	For example, `Array` is defined as `GCodable` when its elements
///	are `GCodable` and `GBinaryEncodable` when its elements are
///	`GPackCodable`:
/// ```
///	extension Array: GCodable where Element:GCodable ...
///
///	extension Array: GBinaryCodable where Element: GPackCodable...
/// ```
/// In this way, an array of integers, for example, is stored quickly
/// with the methods of `BinaryIO`, while an array of non-trivial elements,
/// for example reference types, is stored with the methods of `GCodable`
/// so that these elements continue to retain identity and inheritance.
public typealias GBinaryCodable = GBinaryEncodable & GBinaryDecodable

extension GBinaryEncodable {
	public func encode(to encoder: some GEncoder) throws	{
		throw GraphCodableError.internalInconsistency(
			Self.self, GraphCodableError.Context(
				debugDescription: "Unreachable code."
			)
		)
	}
}
extension GBinaryDecodable {
	public init(from decoder: some GDecoder) throws {
		throw GraphCodableError.internalInconsistency(
			Self.self, GraphCodableError.Context(
				debugDescription: "Unreachable code."
			)
		)
	}
}

public protocol GEncoderView {
	var	userInfo : [String:Any] { get }
}

extension BEncoder {
	public var encoderView : GEncoderView {
		get throws {
			guard let encoderView = userData as? GEncoderView else {
				throw GraphCodableError.internalInconsistency(
					Self.self, GraphCodableError.Context(
						debugDescription: "encoderView can be accessed only from the GraphCodable BinaryIOEncoder"
					)
				)
			}
			return encoderView
		}
	}
}

public protocol GDecoderView {
	var	userInfo			: [String:Any] { get }
	var encodedClassVersion	: UInt32  { get throws }
	var replacedClass		: (AnyObject & GDecodable).Type?  { get throws }
}

extension BDecoder {
	public var decoderView : GDecoderView {
		get throws {
			guard let decoderView = userData as? GDecoderView else {
				throw GraphCodableError.internalInconsistency(
					Self.self, GraphCodableError.Context(
						debugDescription: "decoderView can be accessed only from the GraphCodable BinaryIODecoder"
					)
				)
			}
			return decoderView
		}
	}
}
