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

///	GCodable allows you to store and decode value types and
///	arbitrarily complex reference graphs.
/// GCodable offers a special "deferDecode" method to decode
/// cyclic graphs. Acyclic graph do not require any special
/// treatment.
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
///	**Note:** You should not encode **weak** references with these methods.
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
///	**Note:** You should always encode **weak** references with
///	"conditional" these methods.
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
/// -- To decode a value (optional or not) or a reference (optional
/// or not), conditionally encoded or not, that form a cyclic graph
/// use:
///
///    	required init(from decoder: GDecoder) throws {
///     	...
///			super.init( ... )
///     	...
///	    	try decoder.deferDecode( for: Key.valueA ) { self.valueA = $0 }
///	    	try decoder.deferDecode()  { self.valueA = $0 }
///			...
///		}
///
/// **Note:** A value type that contains a reference type (e.g., an
/// array of reference types) can indirectly create a cyclic graph.
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
///	    try decoder.unkeyedCount
///
/// * **GCodable**
///
/// A type that can encode itself to an external representation.
///	and decode itself from an external representation.
public protocol GCodable {
	/// Creates a new instance by decoding from the given decoder.
	///
	/// This initializer throws an error if reading from the decoder fails, or
	/// if the data read is corrupted or otherwise invalid.
	///
	/// - Parameter decoder: The decoder to read data from.
	init(from decoder: GDecoder) throws
	/// Encodes this value into the given encoder.
	///
	/// This function throws an error if any values are invalid for the given
	/// encoder's format.
	///
	/// - Parameter encoder: The encoder to write data to.
	func encode(to encoder: GEncoder) throws
	/// The version of the encoded reference type.
	///
	/// Only reference types support versioning.
	/// Should really be 'class var' but Swift doesn't allow that
	static var currentVersion: UInt32 { get }
}

public extension GCodable {
	static var currentVersion: UInt32 { 0 }
}

public extension GCodable where Self:AnyObject {
	/// Check if a class is really GCodable.
	///
	/// It depends on the ability to be created from its name.
	static var supportsCodable: Bool {
		return ClassData.supportsCodable( self )
	}
}

/// A protocol to mark GCodable obsolete class.
public protocol GCodableObsolete : AnyObject {
	/// The class that replaces this obsoleted class.
	///
	/// Returns the class that replaces the class that adopt this protocol
	static var replacementType : (AnyObject & GCodable).Type { get }
}

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
		Value : GCodable, Key:RawRepresentable, Key.RawValue == String

	/// Encodes the given value/reference for the given key if it is not `nil`.
	///
	/// - parameter value: The value to encode.
	/// - parameter key: The key to associate the value with.
	func encodeIfPresent<Key,Value>(_ value: Value?, for key:Key ) throws where
		Value : GCodable, Key:RawRepresentable, Key.RawValue == String

	/// Encodes a reference to the given object only if it is encoded
	/// unconditionally elsewhere in the payload (previously, or in the future).
	///
	/// - parameter object: The object to encode.
	/// - parameter key: The key to associate the object with.
	func encodeConditional<Key,Value>(_ value: Value? , for key:Key ) throws where
		Value : GCodable, Value:AnyObject, Key:RawRepresentable, Key.RawValue == String
	
	/// Encodes the given value.
	///
	/// - parameter value: The value to encode.
	func encode<Value>(_ value: Value ) throws where
		Value : GCodable
	
	/// Encodes a reference to the given object only if it is encoded
	/// unconditionally elsewhere in the payload (previously, or in the future).
	///
	/// - parameter object: The object to encode.
	func encodeConditional<Value>(_ value: Value? ) throws where
		Value : GCodable, Value : AnyObject
}

extension GEncoder {
	func encodeIfPresent<Key,Value>(_ value: Value?, for key:Key ) throws where
		Value : GCodable, Key:RawRepresentable, Key.RawValue == String
	{
		if let value = value {
			try encode( value, for: key )
		}
	}
}

/// A type that can decode values from a native format into in-memory
/// representations.
public protocol GDecoder {
	/// Any contextual information set by the user for encoding.
	var userInfo : [String:Any] { get }
	
	/// Returns the version of the encoded object during the object decoding
	///
	/// Corresponds to the value of encodedVersion() when encoding the
	/// data and can be used to decide on different decoding strategies.
	///
	/// Only reference types can have a version.
	var encodedVersion : UInt32  { get throws }

	/// Returns the replacedType type during the object decoding if exists
	///
	/// Corresponds to the class marked with GCodableObsolete protocol that
	/// signals the replacingClass.
	/// Can be used to decide on different decoding strategies.
	///
	/// Only reference types can have a version.
	var replacedType : GCodableObsolete.Type?  { get throws }
	
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
	/// - parameter key: The key that the decoded value is associated with.
	/// - returns: A value of the requested type, if present for the given key
	///   and convertible to the requested type.
	func decode<Key, Value>(for key: Key) throws -> Value where
		Key : RawRepresentable, Value : GCodable, Key.RawValue == String

	/// Decodes a value/reference of the given type for the given key, if present.
	///
	/// This method returns `nil` if the container does not have a value
	/// associated with `key`, or if the value is null. The difference between
	/// these states can be distinguished with a `contains(_:)` call.
	///
	/// - parameter key: The key that the decoded value is associated with.
	/// - returns: A decoded value of the requested type, or `nil` if the
	///   `Decoder` does not have an entry associated with the given key, or if
	///   the value is a null value.
	func decodeIfPresent<Key, Value>(for key: Key) throws -> Value? where
		Key : RawRepresentable, Value : GCodable, Key.RawValue == String

	/// Decodes a value/reference of the given type for the given key when it
	/// become available.
	///
	/// If your data forms a cyclic graph, use this method to "break" the cycle
	/// and decode the graph.
	///
	/// - parameter key: The key that the decoded reference is associated with.
	/// - parameter setter: A closure to which the required value is provided.
	func deferDecode<Key, Value>( for key: Key, _ setter: @escaping (Value) -> ()) throws where
		Key : RawRepresentable, Value : GCodable, Key.RawValue == String

	/// The number of elements still available for unkeyed decoding.
	///
	/// The decoding of an element removes it from the decoder.
	var unkeyedCount : Int { get }
	
	/// Decodes a value/reference of the given type.
	///
	/// - returns: A value of the requested type, if present for the given key
	///   and convertible to the requested type.
	func decode<Value>() throws -> Value where
		Value : GCodable
	
	/// Decodes a value/reference of the given type when it become available.
	///
	/// If references in your data forms a cyclic graph, use this method to
	/// "break" the cycle and decode the graph.
	///
	/// - parameter setter: A closure to which the required reference is provided.
	func deferDecode<Value>( _ setter: @escaping (Value?)->() ) throws where
		Value : GCodable, Value : AnyObject
}

extension GDecoder {
	func decodeIfPresent<Key, Value>(for key: Key) throws -> Value? where
		Key : RawRepresentable, Value : GCodable, Key.RawValue == String
	{
		return contains(key) ? try decode(for: key) : nil
	}
}


/*
┌───────────────────────────────────────────────────────────────────────────────┐
│                           ENCODE/DECODE RULES                                 │
├───────────────────┬───────────────────┬───────────────────────────────────────┤
│                   │    VALUE   TYPE   │            REFERENCE TYPE             │
│      METHOD       ├─────────┬─────────┼─────────┬─────────┬─────────┬─────────┤
│                   │         │    ?    │ strong  │ strong? │ weak? O │ weak? Ø │
╞═══════════════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╡
│ encode            │  █████  │  █████  │  █████  │  █████  │⁵        │⁵        │
├───────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│⁶encodeIfPresent   │¹        │  █████  │¹        │  █████  │⁵        │⁵        │
├───────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ encodeConditional │¹        │¹        │¹        │  █████  │  █████  │  █████  │
╞═══════════════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╡
│ decode            │  █████  │  █████  │  █████  │  █████  │  █████  │⁴        │
├───────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│⁶decodeIfPresent   │¹        │  █████  │¹        │  █████  │  █████  │⁴        │
├───────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ deferDecode       │¹        │¹        │¹        │³        │³        │² █████  │
╞═══════════════════╧═════════╧═════════╧═════════╧═════════╧═════════╧═════════╡
│    ?    = optional                                                            │
│ strong  = strong reference                                                    │
│ strong? = optional strong reference                                           │
│  weak?  = weak reference (always optional)                                    │
│    Ø    = weak reference used to prevent strong memory cycles in ARC          │
│    O    = any other use of a weak reference                                   │
├───────────────────────────────────────────────────────────────────────────────┤
│  █████  = mandatory or highly recommended                                     │
│ ¹       = not allowed                                                         │
│ ²       = allowed by Swift only in the init method of a reference type        │
│           Swift forces to call it after super class initialization            │
│ ³       = you don't need deferDecode: use decode(...) instead                 │
│ ⁴       = GraphCodable exception during decode: use deferDecode(...) instead  │
│ ⁵       = allowed but not recommendend: you run the risk of unnecessarily     │
│           encode and decode objects that will be immediately released after   │
│           decoding. Use encodeConditional(...) instead.                       │
│ ⁶       = keyed coding only.                                                  │
│         - encodeIfPresent(...) encode the value only if value != nil          │
│           encode(...) encode nil in the same situation                        │
│         - decodeIfPresent(...) decode the value for the given key if it       │
│           exists ( i.e. contains(key) == true ) and do not generate an        │
│           exception if the key doesn't exists.                                │
└───────────────────────────────────────────────────────────────────────────────┘
*/
