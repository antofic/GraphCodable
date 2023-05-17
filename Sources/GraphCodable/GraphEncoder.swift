//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

///	An object that encodes instances of a **GEncodable** type
///	into a data buffer that uses **GraphCodable** format.
public final class GraphEncoder {
	private let encoder	: GEncoderImpl

	/// GraphEncoder init method
	///
	/// - Parameter options: encoder user defined flags
	/// - Parameter userVersion: global user defined version of the archive
	/// - Parameter archiveIdentifier: a string identifier for the archive
	/// - Note: By default, the identifier `defaultGraphCodableArchiveIdentifier` is used.
	/// - Note: If you pass nil no identifiers will be encoded.
	public init(
		_ options: Options = .defaultOptions,
		userVersion: UInt32 = 0,
		archiveIdentifier: String? = defaultGraphCodableArchiveIdentifier
	) {
		encoder	= GEncoderImpl(
			options, userVersion:userVersion, archiveIdentifier: archiveIdentifier
		)
	}

	///	Get the archiveIdentifier
	public var archiveIdentifier: String? {
		encoder.archiveIdentifier
	}

	///	Get/Set the userInfo dictionary
	public var userInfo : [String:Any] {
		get { encoder.userInfo }
		set { encoder.userInfo = newValue }
	}

	///	Encode the root value in a native binary format buffer
	///
	///	Example:
	///	```
	///	let data = try GraphEncoder().encode( root ) as Data
	///	```
	/// or:
	///	```
	///	let data = try GraphEncoder().encode( root ) as Bytes
	///	```
	///
	/// - Parameter value: the archive root value to encode.
	/// - Returns: the encoded data in a native binary format.
	///	- Note: The root value must conform to the `GEncodable` protocol.
	///	- Note: You must specify buffer type (typically `Data` or `Bytes = [UInt8]`).
	public func encode<Q>( _ value: some GEncodable ) throws -> Q where Q:MutableDataProtocol {
		return try encoder.encodeRoot( value )
	}
	
	///	Creates a human-readable string of the data that would be generated by encoding the value
	///
	/// Example:
	/// ```
	///	let string = try GraphEncoder().dump( root )
	/// ```
	///
	/// - Parameter value: the archive root value to encode.
	/// - Parameter options: a series of options to choose the information to be generated.
	/// - Returns: a human-readable string representation of the archive that would be generated.
	/// by the `encode(...)` function.
	///	- Note: The root value must conform to the `GEncodable` protocol.
	///	- Note: The generated string cannot be used for decoding.
	public func dump( _ value: some GEncodable, options: GraphDumpOptions = .readable ) throws -> String {
		try encoder.dumpRoot( value, options:options )
	}
	
	///	Check if the value to encode generates a cyclic graph.
	///
	/// If the value to be encoded generates a cyclic graph it is necessary to use
	/// `deferDecode` for the decoding.
	///
	/// - Parameter value: the archive root value to encode.
	/// - Returns: `true` if the value to encode generates a cyclic graph, `false` otherwise.
	/// by the `encode(...)` function.
	///	- Note: The root value must conform to the `GEncodable` protocol.
	public func isCyclic( _ value: some GEncodable ) throws -> Bool {
		try encoder.isCyclic( value )
	}
}

// -------------------------------------------------
// ----- GraphEncoder.Options
// -------------------------------------------------

extension GraphEncoder {
	/// Options for GraphEncoder init method
	public struct Options: OptionSet {
		public let rawValue: UInt
		
		public init(rawValue: UInt) {
			self.rawValue	= rawValue
		}
		
		///	Set the mangling mode
		///
		///	During encoding the class name is transformed into a string
		/// (the `mangledClassName`) which allows, during decoding, to get back
		/// the class.
		/// Swift allows you to use two pairs of functions to achieve this result:
		/// - `_mangledTypeName()` and `_typeByName()`
		/// - `NSStringFromClass()` and `NSClassFromString()`
		///
		/// The first pais is used by default.
		/// The `nsClassFromStringMangling` flag (to be set when instantiating
		/// a GraphEncoder) allows you to choose the second pair. This settings
		/// is then stored in the enum `ManglingFunction` for every class type.
		public static let	nsClassFromStringMangling							= Self( rawValue: 1 << 0 )
		///	Disable compression
		///
		/// By default integers are compressed to produce smaller files.
		/// This option disables compression.
		///
		/// - Note: Compression is enabled by default
		public static let	disableCompression									= Self( rawValue: 1 << 1 )
				
		///	Disable identity
		///
		/// All types will be encoded with no identity regardless of how they are defined.
		///
		/// - Note: This option is disabled by default
		public static let	disableIdentity										= Self( rawValue: 1 << 2 )
		
		///	Disable inheritance
		///
		/// All reference types will be encoded with no class name info's.
		///
		/// - Note: This option is disabled by default
		public static let	disableInheritance									= Self( rawValue: 1 << 3 )

		///	Resort to hashable identity
		///
		/// If .disableIdentity == false, uses immediately the value as identity
		/// if the value is Hashable.
		///
		/// - Note: This option is disabled by default
		/// - Note: The option can be expensive in certain situations
		public static let	tryHashableIdentityAtFirst							= Self( rawValue: 1 << 4 )
		
		///	Resort to hashable identity if any other fails
		///
		/// If .disableIdentity == false and any other tentative to aquire an identity
		/// has failed and the value is Hashable, uses the value as identity.
		///
		/// - Note: This option is disabled by default
		/// - Note: The option can be expensive in certain situations
		public static let	tryHashableIdentityAtLast							= Self( rawValue: 1 << 5 )

		public static let	mimicSwiftCodable:				Self 	= [ disableIdentity, disableInheritance ]
		public static let	defaultOptions:					Self 	= []
	}
}

