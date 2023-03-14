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

public protocol GEncodable {
	/// Encodes this value into the given encoder.
	///
	/// This function throws an error if any values are invalid for the given
	/// encoder's format.
	///
	/// - Parameter encoder: The encoder to write data to.
	func encode(to encoder: GEncoder) throws
}

extension GEncodable where Self:AnyObject {
	/// It depends on the ability to be constructed from its type name.
	public static var supportsCodableInheritance: Bool {
		ClassData.isConstructible( type:self )
	}
}

public protocol GDecodable {
	/// Creates a new instance by decoding from the given decoder.
	///
	/// This initializer throws an error if reading from the decoder fails, or
	/// if the data read is corrupted or otherwise invalid.
	///
	/// - Parameter decoder: The decoder to read data from.
	init(from decoder: GDecoder) throws
	
	static var replacementType : GDecodable.Type { get }
}

public extension GDecodable {
	static var replacementType : GDecodable.Type { Self.self }
}

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
public typealias GCodable	= GEncodable & GDecodable





