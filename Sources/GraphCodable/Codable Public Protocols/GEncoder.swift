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

/// A type that can encode values into a native format for external
/// representation.
public protocol GEncoder {
	/// Any contextual information set by the user for encoding.
	var	userInfo : [String:Any] { get }
	
	/// Encodes the given value/reference for the given key.
	///
	/// - parameter value: The value to encode.
	/// - parameter key: The key to associate the value with.
	func encode<Key,Value>(_ value: Value, for key:Key ) throws where
		Value : GEncodable, Key:RawRepresentable, Key.RawValue == String

	/// Encodes the given value/reference for the given key if it is not `nil`.
	///
	/// - parameter value: The value to encode.
	/// - parameter key: The key to associate the value with.
	func encodeIfPresent<Key,Value>(_ value: Value?, for key:Key ) throws where
		Value : GEncodable, Key:RawRepresentable, Key.RawValue == String

	/// Encodes a reference to the given object only if it is encoded
	/// unconditionally elsewhere in the payload (previously, or in the future).
	///
	/// - parameter object: The object to encode.
	/// - parameter key: The key to associate the object with.
	func encodeConditional<Key,Value>(_ value: Value? , for key:Key ) throws where
		Value : GEncodable, Key:RawRepresentable, Key.RawValue == String
	
	/// Encodes the given value.
	///
	/// - parameter value: The value to encode.
	func encode<Value>(_ value: Value ) throws where
		Value : GEncodable
	
	/// Encodes a reference to the given object only if it is encoded
	/// unconditionally elsewhere in the payload (previously, or in the future).
	///
	/// - parameter object: The object to encode.
	func encodeConditional<Value>(_ value: Value? ) throws where
		Value : GEncodable
}

extension GEncoder {
	public func encodeIfPresent<Key,Value>(_ value: Value?, for key:Key ) throws where
		Value : GEncodable, Key:RawRepresentable, Key.RawValue == String
	{
		if let value = value {
			try encode( value, for: key )
		}
	}
}
