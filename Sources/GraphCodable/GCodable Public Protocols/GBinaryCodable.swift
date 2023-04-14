//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra


/// The `GEncoderView` protocol allows `GBinaryEncodable` values to access part
/// of the methods of the `GEncoder` protocol.
///
///	Example:
///	```
///	func encode(to encoder: inout some BEncoder) throws {
///	  let encoderView = Self.encoderView( encoder )
///	  let userInfo = encoderView.userInfo
///	  /* ... */
/// }
///	```
public protocol GEncoderView {
	/// A view to the `GEncoder` `userInfo` property
	var	userInfo : [String:Any] { get }
}

///	A `GEncodable` type that directly accesses faster `BEncoder`'s
///	methods for encoding while bypassing those of `GEncoder`.
///
///	To bypass the standard encoding mechanism and use the faster
///	`BEncodable` one, adopt the `GBinaryEncodable` protocol and write
///	the required methods of `BEncodable` protocol to encode the fields
///	of the type.
///
///	You can use `GBinaryEncodable` when you still want to give type
///	identity and/or inheritance in case of reference types,
///	but all its fields are trivial.
///
///	In the case of generic types, `GBinaryEncodable` can be applied
///	when the generic fields are trivial, leaving the normal mechanism
///	to operate when they are not.
///
///	For example, `Array` is defined as `GBinaryEncodable` when its
///	elements are `GEncodable` and `GBinaryEncodable` when its elements
///	are `GPackEncodable`:
/// ```
///	extension Array: GEncodable where Element:GEncodable ...
///
///	extension Array: GBinaryEncodable where Element: GPackEncodable...
/// ```
/// In this way, an array of integers, for example, is encoded quickly
/// with the methods of BinaryIO package, while an array of non-trivial
/// elements, for example reference types, is encoded with the methods
/// of `GEncodable` so that these elements continue to retain identity
/// and inheritance.
///
/// - Note: All field of a `GBinaryEncodable` type **must** be
/// at least `BEncodable`
public protocol	GBinaryEncodable : BEncodable, GEncodable {}

extension GBinaryEncodable {
	///	Allows `GBinaryEncodable` values to access a view of `GEncoder`.
	///
	///	Example:
	///	```
	///	func encode(to encoder: inout some BEncoder) throws {
	///	  let encoderView = Self.encoderView( encoder )
	///	  /* ... */
	/// }
	public static func encoderView( _ encoder: some BEncoder ) -> some GEncoderView {
		// can't fail
		return encoder.userData as! GEncoderImpl
	}
	
	public func encode(to encoder: some GEncoder) throws {
		throw GraphCodableError.internalInconsistency(
			Self.self, GraphCodableError.Context(
				debugDescription: "Unreachable code."
			)
		)
	}
}

/// The `GDecoderView` protocol allows `GBinaryDecodable` values to access part
/// of the methods of the `GDecoder` protocol.
///
///	Example:
///	```
///	init(from decoder: inout BinaryIODecoder) throws
///	  let decoderView = Self.decoderView( decoder )
///	  let userInfo = decoderView.userInfo
///	  let encodedClassVersion = try decoderView.encodedClassVersion
///	  let replacedClass = try decoderView.replacedClass
///	  /* ... */
/// }
///	```
public protocol GDecoderView {
	/// A view to the `GDecoder` `userInfo` property
	var	userInfo			: [String:Any] { get }
	/// A view to the `GDecoder` `encodedClassVersion` property
	///
	/// Only `GBinaryDecodable` reference types can have a version.
	var encodedClassVersion	: UInt32  { get throws }
	/// A view to the `GDecoder` `replacedClass` property
	///
	/// Only `GBinaryDecodable` reference types can be replaced.
	var replacedClass		: (any (AnyObject & GDecodable).Type)?  { get throws }
}

///	A `GDecodable` type that directly accesses faster `BDecoder`'s
///	methods for decoding while bypassing those of `GDecoder`.
///
///	To bypass the standard decoding mechanism and use the faster
///	`BDecodable` one, adopt the `GBinaryDecodable` protocol and write
///	the required methods of `BDecodable` protocol to decode the fields
///	of the type.
///
///	You can use `GBinaryDecodable` when you still want to give type
///	identity and/or inheritance in case of reference types,
///	but all its fields are trivial.
///
///	In the case of generic types, `GBinaryDecodable` can be applied
///	when the generic fields are trivial, leaving the normal mechanism
///	to operate when they are not.
///
///	For example, `Array` is defined as `GBinaryDecodable` when its
///	elements are `GDecodable` and `GBinaryDecodable` when its elements
///	are `GPackDecodable`:
/// ```
///	extension Array: GDecodable where Element:GDecodable ...
///
///	extension Array: GBinaryDecodable where Element: GPackDecodable...
/// ```
/// In this way, an array of integers, for example, is decoded quickly
/// with the methods of BinaryIO package, while an array of non-trivial
/// elements, for example reference types, is decoded with the methods
/// of `GEncodable` so that these elements continue to retain identity
/// and inheritance.
///
/// - Note: All field of a `GBinaryDecodable` type **must** be
/// at least `BDecodable`
public protocol	GBinaryDecodable : BDecodable, GDecodable {}

extension GBinaryDecodable {
	///	Allows `GBinaryDecodable` values to access a view of `GDecoder`.
	///
	///	Example:
	///	```
	///	init(from decoder: inout some BDecoder) throws
	///	  let decoderView = Self.decoderView( decoder )
	///	  /* ... */
	/// }
	///	```
	public static func decoderView( _ decoder: some BDecoder ) -> some GDecoderView {
		// can't fail
		return decoder.userData as! GDecoderImpl
	}
	
	public init(from decoder: some GDecoder) throws {
		throw GraphCodableError.internalInconsistency(
			Self.self, GraphCodableError.Context(
				debugDescription: "Unreachable code."
			)
		)
	}
}

/// A type that is both `GBinaryEncodable` and `GBinaryDecodable`.
public typealias GBinaryCodable = GBinaryEncodable & GBinaryDecodable



