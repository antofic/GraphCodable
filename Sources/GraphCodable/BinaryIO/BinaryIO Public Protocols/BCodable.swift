//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

/// The bytes container used by `BinaryIODecoder` and `BinaryIOEncoder`
///
/// The container must conform to `MutableDataProtocol`, i.e `Data`, `[UInt8]`, `ContiguousArray<UInt8>`
public typealias Bytes	= [UInt8]

/// The default string that identiefies a BinaryIO archive
///
/// You can choose a different archive identifier in:
/// - the BinaryIOEncoder `init` method
/// - the BEncodable `binaryIOData(...)` method
///
/// During decoding this string must match the `archiveIdentifier` in:
/// - the BinaryIODecoder `init` method
/// - the BDecodable `init( binaryIOData:... )` method
///
/// Note: A BinaryIODecoder `nil` string match with
/// any encoded `archiveIdentifier` string
public let defaultBinaryIOArchiveIdentifier = "binaryIO"


/// A type that can write itself into a `BEncoder` istance
public protocol BEncodable {
	/// Writes this value into the given istance of `BEncoder`.
	///
	/// This function throws an error if any values are invalid for the given
	/// istance of `BEncoder`.
	///
	/// - Parameter encoder: The `BEncoder` istance
	/// to write data to.
	func encode(to encoder: inout some BEncoder) throws
}

/// A type that can read itself from a `BDecoder` istance
public protocol BDecodable {
	/// Creates a new instance by reading it from the given
	/// istance of `BDecoder`.
	///
	/// This initializer throws an error if reading fails, or
	/// if the data read is corrupted or otherwise invalid.
	/// - Parameter decoder: The `BDecoder` istance
	/// to read data from.
	init(from decoder: inout some BDecoder) throws
}

/// A type that can write itself to a byte buffer
///	and read itself from a byte buffer.
public typealias BCodable = BEncodable & BDecodable


public extension BEncodable {
	///	Encode the root value of your archive in a byte buffer
	///
	///	The root value must conform to the BEncodable protocol
	///
	/// - Parameter userVersion: An user defined version for its data. It is recommended
	/// to start at 0 and increment this value by 1 each time a type change requires a
	/// different encoding so that you can continue to decode previously encoded types.
	///
	/// - Parameter archiveIdentifier: An optional string that will be encoded to identify
	/// the archive. If specified, decoding occurs only if the decoder is instantiated by
	/// specifying the same string.
	/// By default, both encoder and decoder use the string:
	/// `defaultBinaryIOArchiveIdentifier = "binaryIO"`
	/// If `nil` is specified, no `archiveIdentifier` string will be encoded. A `nil`
	/// archiveIdentifier should be used only to create temporary data internal to
	/// the application that will not be saved on disk.
	///	The GraphCodable package uses
	///	`defaultGraphCodableArchiveIdentifier = "graphCodable"`
	/// as default archive identifier string.
	///
	///	- Parameter userData: User defined data for encoding strategies.
	///	GraphCodable uses this parameter to store the `encoderView` property accessible
	///	from `GBinaryEncodable` types.
	///
	///	- Parameter enableCompression: compress integer values to reduce file size. Compression
	///	is enabled by default.
	/// - returns: The byte buffer.
	func binaryIOData<Q>(
		userVersion:UInt32,
		archiveIdentifier: String? = defaultBinaryIOArchiveIdentifier,
		userData:Any? = nil,
		enableCompression:Bool = true
	) throws -> Q
	where Q:MutableBinaryDataProtocol {
		var encoder = BinaryIOEncoder<Q>( userVersion:userVersion, archiveIdentifier: archiveIdentifier, userData: userData, enableCompression:enableCompression )
		try encoder.encode( self )
		return encoder.data
	}
}

public extension BDecodable {
	///	Decode the root value from the byte buffer
	///
	///	The root value must conform to the `BDecodable` protocol
	///
	/// - Parameter binaryIOData: The data to read from.
	/// - Parameter archiveIdentifier: An optional string to match the encoded identifier
	/// of the archive. A `nil` string match with any encoded `archiveIdentifier`
	/// string.
	///	- Parameter userData: User defined data for decoding strategies.
	///	GraphCodable uses this parameter to store the `decoderView` property accessible
	///	from `GBinaryDecodable` types.
	init<Q>( binaryIOData: Q, archiveIdentifier: String? = defaultBinaryIOArchiveIdentifier, userData:Any? = nil ) throws
	where Q:BinaryDataProtocol, Q.Indices == Range<Int>, Q.SubSequence: BinaryDataProtocol, Q.SubSequence.Indices == Range<Int> {
		var decoder = try BinaryIODecoder<Q>( data:binaryIOData, archiveIdentifier:archiveIdentifier, userData:userData )
		self = try decoder.decode()
	}
}
