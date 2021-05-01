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

import Foundation

/// A type that can encode itself to an external representation.
public protocol GEncodable {
	/// Encodes this value into the given encoder.
	///
	/// This function throws an error if any values are invalid for the given
	/// encoder's format.
	///
	/// - Parameter encoder: The encoder to write data to.
	func encode(to encoder: GEncoder) throws

	/// The version of the encoded value.
	static var	encodeVersion:	UInt32 { get }
}

public extension GEncodable {
	static var encodeVersion: UInt32 {
		return 0	// default version
	}
}

/// A type that can decode itself from an external representation.
public protocol GDecodable {
	/// Creates a new instance by decoding from the given decoder.
	///
	/// This initializer throws an error if reading from the decoder fails, or
	/// if the data read is corrupted or otherwise invalid.
	///
	/// - Parameter decoder: The decoder to read data from.
	init(from decoder: GDecoder) throws

	static func register()
	static func unregister()
	static func replace( type oldType:Any.Type ) throws
}

public extension GDecodable {
	static func register() {
		GTypesRepository.shared.register( type: self )
	}
	static func unregister() {
		GTypesRepository.shared.unregister(type: self)
	}
	static func replace( type:Any.Type ) throws {
		try GTypesRepository.shared.replace( type, with: self )
	}
}

///	GCodable allows you to store and decode
///	value types and arbitrarily complex reference graphs as long
///	as the connections do not realize memory strong cycles.
/// Strong cycles are incompatible with ARC (they leak memory) and
/// therefore this is not a limitation.
/// Indeed, GCodable allows you to easily find out if your graph
/// contains strong cycles precisely because **decoding** it causes
/// an error.
/// Encoded and decoded variables are fully type checked. For this
/// reason, GCodable does **not** allow you to encode heterogeneous
/// collections, even if they contain encodable items.
///
/// * **Make a type conform to the GCodable protocol**
///
///	To make a type archivable / unarchivable, it must be conformed
///	to GCodable.
///
///     struct AStruct : GCodable {
///			init(from decoder: GDecoder) throws {
///				//	...
///
///     	}
///			func encode(to encoder: GEncoder) throws {
///				//	...
///			}
///		}
///
///		class AClass : GCodable {
///			required init(from decoder: GDecoder) throws {
///				//	...
///			}
///
///			func encode(to encoder: GEncoder) throws {
///				//	...
///			}
///		}
/// * **Keys**
///
/// The storage keys for keyed encoding must be defined in an enum
/// with rawValue == String.
///	Idiomatically make the enum private and put it within the type
///	definition that we want conform to GCodable.
///
///     private enum Key : String {
///			case valueA, ...
///		}
/// * **Encoding rules**
///
/// See also the table at the end of the file.
///
/// -- To encode a value (optional or not) or a reference (optional
/// or not), use:
///
///     func encode(to encoder: GEncoder) throws {
///			...
///    		try encoder.encode( valueA, for: Key.valueA )
///    		try encoder.encode( valueB )
///			...
///		}
///	**Warning!** Don't encode **weak** references with these methods.
///
/// -- To encode a **optional** reference to the given object only
/// if it is encoded unconditionally elsewhere in the payload
/// (previously, or in the future), use:
///
///     func encode(to encoder: GEncoder) throws {
///			...
///    		try encoder.encodeConditional( refA, for: Key.valueA )
///    		try encoder.encodeConditional( refB )
///			...
///		}
///
///	**Warning! Weak** references **must** always be encoded with
///	theese methods.
///
/// * **Decoding rules**
///
/// See also the table at the end of the file.
///
/// -- To decode a value (optional or not) or a reference (optional
/// or not), conditionally encoded or not, use:
///
///    	init(from decoder: GDecoder) throws {
///     	...
///	    	valueA	= try decoder.decode( for: Key.valueA )
///	    	valueB	= try decoder.decode()
///			...
///			...
///		}
///
/// -- To decode a reference that is declared **weak** to avoid
/// strong memory cycles in ARC, use:
///
///    	required init(from decoder: GDecoder) throws {
///     	...
///			super.init( ... )
///     	...
///	    	try decoder.deferDecode( for: Key.valueA ) { self.weakA = $0 }
///	    	try decoder.deferDecode()  { self.weakB = $0 }
///			...
///		}
///
/// **Warning!** The weak reference **must** have been conditionally encoded.
/// Deferred decoding **requires** the caller to be the init method
/// of a class and can be called only after initializing the superclass.
///
/// **Note: Just as encoding a variable appends it to the encoder,**
/// **decoding it removes it from the decoder.**
///
/// All methods are in the keyed and unkeyed version and can be used
/// at the same time. With unkeyed methods, decoding must follow the
/// same order as encoding.
///
/// You can find out if a **keyed** variable is still in the decoder
/// with:
///
///	    try decoder.contains( Key.valueA )
///
/// Note: Keys are shared with superclasses.
///
/// You can find out how many unkeyed variables there are still in the
/// decoder with:
///
///	    try decoder.unkeyedCount()
///

public typealias GCodable	= GEncodable & GDecodable

/// A type that can encode values into a native format for external
/// representation.
public protocol GEncoder {
	/// Any contextual information set by the user for encoding.
	var	userInfo : [String:Any] { get }
	
	/// Encodes the given value for the given key.
	///
	/// It can be used with values or **strong** reference, optional or not.
	/// It should not be used with **weak** references.
	///
	/// - parameter value: The value to encode.
	/// - parameter key: The key to associate the value with.
	func encode<Key,Value>(_ value: Value, for key:Key ) throws where
		Value : GEncodable, Key:RawRepresentable, Key.RawValue == String
	
	/// Encodes a reference to the given object only if it is encoded
	/// unconditionally elsewhere in the payload (previously, or in the future).
	///
	/// It can be used with optional **strong** reference and is required
	///	with (mandatory optional) **weak** references.
	///
	/// - parameter object: The object to encode.
	/// - parameter key: The key to associate the object with.
	func encodeConditional<Key,Value>(_ value: Value? , for key:Key ) throws where
		Value : GEncodable, Value:AnyObject, Key:RawRepresentable, Key.RawValue == String
	
	/// Encodes the given value.
	///
	/// It can be used with values or reference, optional or not. It
	/// should not be used with **weak** references.
	///
	/// - parameter value: The value to encode.
	func encode<Value>(_ value: Value ) throws where
		Value : GEncodable
	
	/// Encodes a reference to the given object only if it is encoded
	/// unconditionally elsewhere in the payload (previously, or in the future).
	///
	/// It can be used with optional **strong** reference and is required
	///	with (mandatory optional) **weak** references.
	///
	/// - parameter object: The object to encode.
	func encodeConditional<Value>(_ value: Value? ) throws where
		Value : GEncodable, Value : AnyObject
}

/// A type that can decode values from a native format into in-memory
/// representations.
public protocol GDecoder {
	/// Any contextual information set by the user for encoding.
	var userInfo : [String:Any] { get }
	
	/// Returns the version of the encoded type
	///
	/// Corresponds to the value of encodedVersion () when encoding the
	/// data and can be used to decide on different decoding strategies.
	func encodedVersion<Value>( _ type: Value.Type ) throws -> UInt32  where Value:GDecodable
	
	/// Returns a Boolean value indicating whether the decoder contains a value
	/// associated with the given key.
	///
	/// The value associated with `key` may be a null value as appropriate for
	/// the data format.
	/// The decoding of an element removes it from the decoder.
	///
	/// - parameter key: The key to search for.
	/// - returns: Whether the `Decoder` has an entry for the given key.
	func contains<Key>( _ key:Key ) throws -> Bool where
		Key:RawRepresentable, Key.RawValue == String

	/// Decodes a value of the given type for the given key.
	///
	/// It must be used with values or **strong** reference, optional or not.
	/// It should be used with **weak** references **not** used in order
	/// to avoid strong memory cycles with ARC.
	///
	/// - parameter type: The type of value to decode.
	/// - parameter key: The key that the decoded value is associated with.
	/// - returns: A value of the requested type, if present for the given key
	///   and convertible to the requested type.
	func decode<Key, Value>(for key: Key) throws -> Value where
		Key : RawRepresentable, Value : GEncodable, Key.RawValue == String

	/// Decodes a reference of the given type for the given key when it become available.
	///
	/// This method **must** be used exclusively with **weak** references used in order
	/// to avoid strong memory cycles with ARC. The **weak** reference **must** be
	/// encoded conditionally.
	///
	/// - parameter type: The type of reference to decode.
	/// - parameter key: The key that the decoded reference is associated with.
	/// - parameter setter: A closure to which the required reference is provided.
	func deferDecode<Key, Value>( for key: Key, _ setter: @escaping (Value?) -> ()) throws where
		Key : RawRepresentable, Value : AnyObject, Value : GEncodable, Key.RawValue == String

	/// The number of elements still available for unkeyed decoding.
	///
	/// The decoding of an element removes it from the decoder.
	func unkeyedCount() throws -> Int
	
	/// Decodes a value of the given type.
	///
	/// It must be used with values or **strong** reference, optional or not.
	/// It should be used with **weak** references **not** used in order
	/// to avoid strong memory cycles with ARC.
	///
	/// - parameter type: The type of value to decode.
	/// - returns: A value of the requested type, if present.
	func decode<Value>() throws -> Value where
		Value : GDecodable
	
	/// Decodes a reference of the given type when it become available.
	///
	/// This method **must** be used exclusively with **weak** references used in order
	/// to avoid strong memory cycles with ARC. The **weak** reference **must** be
	/// encoded conditionally.
	///
	/// - parameter type: The type of reference to decode.
	/// - parameter key: The key that the decoded reference is associated with.
	/// - parameter setter: A closure to which the required reference is provided.
	func deferDecode<Value>( _ setter: @escaping (Value?)->() ) throws where
		Value : GDecodable, Value : AnyObject
}

/// ┌───────────────────────────────────────────────────────────────────────────────┐
/// │                           ENCODE/DECODE RULES                                 │
/// ├───────────────────┬───────────────────┬───────────────────────────────────────┤
/// │                   │    VALUE   TYPE   │            REFERENCE TYPE             │
/// │      METHOD       ├─────────┬─────────┼─────────┬─────────┬─────────┬─────────┤
/// │                   │         │    ?    │ strong  │ strong? │ weak? O │ weak? Ø │
/// ╞═══════════════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╡
/// │ encode            │  █████  │  █████  │  █████  │  █████  │⁵        │⁵        │
/// ├───────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
/// │ encodeConditional │¹        │¹        │¹        │  █████  │  █████  │  █████  │
/// ╞═══════════════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╡
/// │ decode            │  █████  │  █████  │  █████  │  █████  │  █████  │⁴        │
/// ├───────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
/// │ deferDecode       │¹        │¹        │¹        │²³       │²³       │² █████  │
/// ╞═══════════════════╧═════════╧═════════╧═════════╧═════════╧═════════╧═════════╡
/// │	 ?    = optional                                                            │
/// │ strong  = strong reference                                                    │
/// │ strong? = optional strong reference                                           │
/// │ weak?   = weak reference (always optional)                                    │
/// │    Ø    = weak reference used to prevent strong memory cycles in ARC          │
/// │    O    = any other use of a weak reference                                   │
/// ├───────────────────────────────────────────────────────────────────────────────┤
/// │  █████  = mandatory or highly recommended                                     │
/// │ ¹       = not allowed by Swift                                                │
/// │ ²       = allowed by Swift only in the init method of a reference type        │
/// │           Swift forces to call it after super class initialization            │
/// │ ³       = you don't need deferDecode: use decode instead                      │
/// │ ⁴       = exception on decode: use deferDecode instead                        │
/// │ ⁵       = allowed but not recommendend: you run the risk of unnecessarily     │
/// │           encoding and decoding objects that will be immediately released     │
/// │           after decoding. Use encodeConditional instead.                      │
/// └───────────────────────────────────────────────────────────────────────────────┘
