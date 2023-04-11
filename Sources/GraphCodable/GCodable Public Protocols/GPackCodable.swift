//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

/// A dummy protocol to mark trivial types
public protocol GPackable {}

public typealias GPackEncodable	= GBinaryEncodable & GPackable
public typealias GPackDecodable	= GBinaryDecodable & GPackable


///	Use this protocol to encode and decode trivial types.
///
///	`GPackCodable` types bypass the standard coding mechanism and use the faster
///	`BCodable` one. It also bypasses inheritance and identity.
//////
///	- Note: The library generate a runtime error if you mark a non trivial type
///	with the `GPackCodable` protocol and try to encode it.
public typealias GPackCodable	= GPackEncodable & GPackDecodable

