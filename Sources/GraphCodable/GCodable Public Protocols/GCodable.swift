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

/// A type that can be encoded from in-memory representations
/// into a native data format
public protocol GEncodable {
	/// Encodes this value into the given encoder.
	///
	/// This function throws an error if any values are invalid for the given
	/// encoder's format.
	///
	/// - Parameter encoder: The encoder to write data to.
	func encode(to encoder: GEncoder) throws
	/// The version of the encoded reference type.
	///
	/// Returns `0` by default
	///
	/// Only reference types support versioning.
	static var typeVersion : UInt32 { get }
}

extension GEncodable {
	/// Default typeVersion = 0
	public static var typeVersion : UInt32 { 0 }
}

extension GEncodable where Self:AnyObject {
	/// Returns true if the type can be constructed from its type name.
	public static var supportsCodableInheritance: Bool {
		ClassData.isConstructible( type:self )
	}
}

/// A type that can be decoded from a native data format
/// into in-memory representations
public protocol GDecodable {
	/// Creates a new instance by decoding from the given decoder.
	///
	/// This initializer throws an error if reading from the decoder fails, or
	/// if the data read is corrupted or otherwise invalid.
	///
	/// - Parameter decoder: The decoder to read data from.
	init(from decoder: GDecoder) throws
	
	/// A replacementType for the encoded reference type.
	///
	/// Generic classes may return `Self` if the current specialization is
	/// not to be replaced.
	///	**See the UserGuide**.
	///
	/// - returns: The class that replaces `Self` (`Self.self` by default).
	static var replacementType : GDecodable.Type { get }
}

extension GDecodable {
	/// Default replacementType = `Self.self`
	public static var replacementType : GDecodable.Type { Self.self }
}

/// A type that can be encoded from in-memory representations
/// into a native data format and vice versa
public typealias GCodable	= GEncodable & GDecodable





