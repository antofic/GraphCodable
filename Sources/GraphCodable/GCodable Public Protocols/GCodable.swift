//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

/// The default string that identiefies a GraphCodable archive
///
/// You can choose a different archive identifier with:
/// - the GraphEncoder `init` method
///
/// During decoding this string must match the `archiveIdentifier` in:
/// - the GraphDecoder `init` method
///
/// Note: A GraphDecoder `nil` string match with
/// any encoded `archiveIdentifier` string
public let defaultGraphCodableArchiveIdentifier = "graphCodable"

/// A type that can be encoded from in-memory representations
/// into a native data format
public protocol GEncodable {
	/// Encodes this value into the given encoder.
	///
	/// This function throws an error if any values are invalid for the given
	/// encoder's format.
	///
	/// - Parameter encoder: The encoder to write data to.
	func encode(to encoder: some GEncoder) throws
	
	/// The version of the encoded reference type.
	///
	/// Returns `0` by default
	///
	/// Only reference types **that don't disable** inheritance
	/// support versions
	static var classVersion : UInt32 { get }
	
	///	A flag to control inheritance of reference types
	///
	/// Return `false` if you want disable inheritance.
	/// If inheritanche is disabled, the reference type name
	/// is not endcoed. Inheritance is enabled by default for
	/// reference types
	///
	/// This flag has non effect for value types: they cannot have
	/// inheritance and their type name is never archived
	var inheritanceEnabled : Bool { get }
	
	/// Optional support: reserved for package use.
	var _fullOptionalUnwrappedValue : (any GEncodable)? { get }
}

extension GEncodable {
	/// Default classVersion = 0
	public static var classVersion : UInt32 { 0 }
	/// Inheritance disabled for value types
	/// Enabling inheritance of value types has no effect.
	public var inheritanceEnabled : Bool { false }
	
	/// Optional support: reserved for package use.
	///
	/// Wraps or unwraps self until a **single level optional value**
	/// is obtained.
	public var _fullOptionalUnwrappedValue : (any GEncodable)? { self }
}

extension GEncodable where Self:AnyObject {
	/// Returns true if the type can be constructed from its type name.
	public static var supportsCodableInheritance: Bool {
		ClassData.isConstructible( type:self )
	}
	/// Inheritance enabled by default for reference types
	public var inheritanceEnabled : Bool { true }
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
	init(from decoder: some GDecoder) throws
	
	/// A decodeType for the encoded reference type.
	///
	/// Generic classes may return `Self` if the current specialization is
	/// not to be replaced.
	///	**See the UserGuide**.
	///
	/// - returns: The class that replaces `Self` (`Self.self` by default).
	static var decodeType : any GDecodable.Type { get }
	
	/// Optional support: reserved for package use.
	///
	/// Unwraps `Self` until the inner **non optional** `GDecodable` type
	/// is obtained.
	static var _fullOptionalUnwrappedType	: any GDecodable.Type { get }
}

extension GDecodable {
	/// Default decodeType = `Self.self`
	public static var decodeType : any GDecodable.Type { Self.self }

	/// Optional support: reserved for package use.
	public static var _fullOptionalUnwrappedType : any GDecodable.Type { Self.self }
}

/// A type that can be encoded from in-memory representations
/// into a native data format and vice versa
public typealias GCodable	= GEncodable & GDecodable





