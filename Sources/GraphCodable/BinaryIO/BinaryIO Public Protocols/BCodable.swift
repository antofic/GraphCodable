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
	///	Write the value in a byte buffer
	///
	///	The root value must conform to the BEncodable protocol
	/// - returns: The byte buffer.
	func binaryIOData<Q>(
		userVersion:UInt32,
		archiveIdentifier: String? = defaultBinaryIOArchiveIdentifier,
		userData:Any? = nil,
		enableCompression:Bool = true
	) throws -> Q
	where Q:MutableDataProtocol {
		var encoder = BinaryIOEncoder( userVersion:userVersion, archiveIdentifier: archiveIdentifier, userData: userData, enableCompression:enableCompression )
		try encoder.encode( self )
		return encoder.data()
	}
}

public extension BDecodable {
	///	Decode the root value from the byte buffer
	///
	///	The root value must conform to the `BDecodable` protocol
	init<Q>( binaryIOData: Q, archiveIdentifier: String? = defaultBinaryIOArchiveIdentifier, userData:Any? = nil ) throws where Q:DataProtocol {
		var decoder = try BinaryIODecoder( data:binaryIOData, archiveIdentifier:archiveIdentifier, userData:userData )
		self = try decoder.decode()
	}
}
