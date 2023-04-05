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

/// A type that can decode values from a native format into in-memory
/// representations.
public protocol GDecoder {
	/// Any contextual information set by the user for encoding.
	var userInfo : [String:Any] { get }

	///	Encoded version for user defined types for
	///	decoding strategies.
	///
	///	Use for your decoding strategies.
	var	encodedUserVersion	: UInt32 { get }

	/// Returns the version of the encoded object during the object decoding
	///
	/// Corresponds to the value of `encodedClassVersion` when encoding the
	/// data and can be used to decide on different decoding strategies.
	///
	/// Only reference types can have a version.
	var encodedClassVersion : UInt32  { get throws }

	/// The replacedClass type during the object decoding if exists
	///
	/// Can be used to decide on different decoding strategies.
	/// **See the UserGuide**.
	///
	/// Only reference types can be replaced.
	/// - returns: the replaced type if exists, nil otherwise
	var replacedClass : (AnyObject & GDecodable).Type?  { get throws }
	
	/// Returns a Boolean value indicating whether the decoder contains a value
	/// associated with the given key.
	///
	/// The value associated with `key` may be a null value as appropriate for
	/// the data format.
	/// The decoding of an element removes it from the decoder.
	///
	/// - parameter key: The key to search for.
	/// - returns: Whether the `Decoder` has an entry for the given key.
	func contains<Key>( _ key:Key ) -> Bool where
		Key:RawRepresentable, Key.RawValue == String

	/// Decodes a value/reference of the given type for the given key.
	///
	///	Example:
	///
	///		init(from decoder: some GDecoder) throws {
	///     	...
	///	    	valueA	= try decoder.decode( type(of:valueA), for: Key.valueA )
	///			...
	///		}
	///
	/// **Note: Just as encoding a variable appends it to the encoder,**
	/// **decoding it removes it from the decoder.**
	/// - parameter type: The decoded value type.
	/// - parameter key: The key that the decoded value is associated with.
	/// - returns: A value of the requested type, if present for the given key
	///   and convertible to the requested type.
	func decode<Key, Value>(_ type:Value.Type, for key: Key) throws -> Value where
		Key : RawRepresentable, Value : GDecodable, Key.RawValue == String

	/// Decodes a value/reference of the given type for the given key when it
	/// become available.
	///
	/// If your data forms a cyclic graph, use this method to "break" the cycle
	/// and decode the graph.
	/// Example:
	///
	///    	init(from decoder: some GDecoder) throws {
	///     	...
	///	    	try decoder.deferDecode( type(of:valueA), for: Key.valueA ) { self.valueA = $0 }
	///			...
	///		}
	/// **Note: Just as encoding a variable appends it to the encoder,**
	/// **decoding it removes it from the decoder.**
	/// - parameter type: The decoded value type.
	/// - parameter key: The key that the decoded reference is associated with.
	/// - parameter setter: A closure to which the required value is provided.
	func deferDecode<Key, Value>( _ type:Value.Type, for key: Key, _ setter: @escaping (Value) -> ()) throws where
	Key : RawRepresentable, Value : GDecodable, Key.RawValue == String

	/// The number of elements still available for unkeyed decoding.
	///
	/// Decoding an element **removes it from the decoder**.
	var unkeyedCount : Int { get }
	
	/// Decodes a value/reference of the given type.
	///
	///	Example:
	///
	///		init(from decoder: some GDecoder) throws {
	///     	...
	///	    	valueA	= try decoder.decode( type(of:valueA) )
	///			...
	///		}
	/// **Note: Just as encoding a variable appends it to the encoder,**
	/// **decoding it removes it from the decoder.**
	/// - parameter type: The decoded value type.
	/// - returns: A value of the requested type, if present
	///   and convertible to the requested type.
	func decode<Value>( _ type:Value.Type ) throws -> Value where
		Value : GDecodable
	
	/// Decodes a value/reference of the given type when it become available.
	///
	/// If references in your data forms a cyclic graph, use this method to
	/// "break" the cycle and decode the graph.
	/// Example:
	///
	///    	init(from decoder: some GDecoder) throws {
	///     	...
	///	    	try decoder.deferDecode( type(of:valueA) ) { self.valueA = $0 }
	///			...
	///		}
	/// **Note: Just as encoding a variable appends it to the encoder,**
	/// **decoding it removes it from the decoder.**
	/// - parameter type: The decoded value type.
	/// - parameter setter: A closure to which the required reference is provided.
	func deferDecode<Value>( _ type:Value.Type, _ setter: @escaping (Value)->() ) throws where
		Value : GDecodable
}

public extension GDecoder {
	/// Decodes a value/reference of the given type for the given key.
	///
	/// The type is taken from the variable whenever possible, otherwise
	/// it must be specified with `as Type.self`.
	///
	///	Example:
	///
	///		init(from decoder: some GDecoder) throws {
	///     	...
	///	    	valueA	= try decoder.decode( for: Key.valueA )
	///			...
	///		}
	///
	/// **Note: Just as encoding a variable appends it to the encoder,**
	/// **decoding it removes it from the decoder.**
	/// - parameter key: The key that the decoded value is associated with.
	/// - returns: A value of the requested type, if present for the given key
	///   and convertible to the requested type.
	func decode<Key, Value>(for key: Key) throws -> Value where
	Key : RawRepresentable, Value : GDecodable, Key.RawValue == String {
		try decode( Value.self, for: key )
	}
	
	/// Decodes a value/reference of the given type for the given key when it
	/// become available.
	///
	/// The type is taken from the variable whenever possible, otherwise
	/// it must be specified with `as Type.self`.
	///
	/// If your data forms a cyclic graph, use this method to "break" the cycle
	/// and decode the graph.
	/// Example:
	///
	///    	init(from decoder: some GDecoder) throws {
	///     	...
	///	    	try decoder.deferDecode( for: Key.valueA ) { self.valueA = $0 }
	///			...
	///		}
	/// **Note: Just as encoding a variable appends it to the encoder,**
	/// **decoding it removes it from the decoder.**
	/// - parameter key: The key that the decoded reference is associated with.
	/// - parameter setter: A closure to which the required value is provided.
	func deferDecode<Key, Value>( for key: Key, _ setter: @escaping (Value) -> ()) throws where
	Key : RawRepresentable, Value : GDecodable, Key.RawValue == String {
		try deferDecode( Value.self, for:key, setter )
	}
	
	/// Decodes a value/reference of the given type for the given key, if present.
	///
	/// This method returns `nil` if the container does not have a value
	/// associated with `key`, or if the value is `nil`. The difference between
	/// these states can be distinguished with a `contains(_:)` call.
	///
	/// **Note: Just as encoding a variable appends it to the encoder,**
	/// **decoding it removes it from the decoder.**
	/// - parameter type: The decoded value type.
	/// - parameter key: The key that the decoded value is associated with.
	/// - returns: A decoded value of the requested type, or `nil` if the
	///   `Decoder` does not have an entry associated with the given key, or if
	///   the value is a null value.
	func decodeIfPresent<Key, Value>(_ type:Value.Type, for key: Key) throws -> Value? where
		Key : RawRepresentable, Value : GDecodable, Key.RawValue == String {
		contains(key) ? try decode( type, for: key) : nil
	}
	
	/// Decodes a value/reference of the given type for the given key, if present.
	///
	/// This method returns `nil` if the container does not have a value
	/// associated with `key`, or if the value is `nil`. The difference between
	/// these states can be distinguished with a `contains(_:)` call.
	///
	/// **Note: Just as encoding a variable appends it to the encoder,**
	/// **decoding it removes it from the decoder.**
	/// - parameter key: The key that the decoded value is associated with.
	/// - returns: A decoded value of the requested type, or `nil` if the
	///   `Decoder` does not have an entry associated with the given key, or if
	///   the value is a null value.
	func decodeIfPresent<Key, Value>(for key: Key) throws -> Value? where
		Key : RawRepresentable, Value : GDecodable, Key.RawValue == String {
		try decodeIfPresent( Value.self, for: key )
	}

	/// Decodes a value/reference of the given type.
	///
	/// The type is taken from the variable whenever possible, otherwise
	/// it must be specified with `as Type.self`.
	///
	///	Example:
	///
	///		init(from decoder: some GDecoder) throws {
	///     	...
	///	    	valueA	= try decoder.decode()
	///			...
	///		}
	/// **Note: Just as encoding a variable appends it to the encoder,**
	/// **decoding it removes it from the decoder.**
	/// - returns: A value of the requested type, if present
	///   and convertible to the requested type.
	func decode<Value>() throws -> Value where
	Value : GDecodable {
		try decode( Value.self )
	}

	/// Decodes a value/reference of the given type when it become available.
	///
	/// The type is taken from the variable whenever possible, otherwise
	/// it must be specified with `as Type.self`.
	///
	/// If references in your data forms a cyclic graph, use this method to
	/// "break" the cycle and decode the graph.
	/// Example:
	///
	///    	init(from decoder: some GDecoder) throws {
	///     	...
	///	    	try decoder.deferDecode() { self.valueA = $0 }
	///			...
	///		}
	/// **Note: Just as encoding a variable appends it to the encoder,**
	/// **decoding it removes it from the decoder.**
	/// - parameter setter: A closure to which the required reference is provided.
	func deferDecode<Value>( _ setter: @escaping (Value)->() ) throws where
	Value : GDecodable {
		try deferDecode( Value.self, setter )
	}
}

