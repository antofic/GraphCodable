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

protocol GNativeCodable : GCodable {
	func write( to: inout BinaryWriter ) throws
	static func read( from: inout BinaryReader ) throws -> Self
}

extension GNativeCodable {
	public func encode(to encoder: GEncoder) throws	{ throw GCodableError.nativeEncodeError }
	public init(from decoder: GDecoder) throws		{ throw GCodableError.nativeDecodeError }
}

// --------------------------------------------------------------------------------------------------------

extension Bool 		: GNativeCodable {
	func write( to writer: inout BinaryWriter ) throws					{ writer.write( self ) }
	static func read( from reader: inout BinaryReader ) throws -> Self	{ return try reader.read() }
}

// --------------------------------------------------------------------------------------------------------

extension BinaryInteger  {
	func write( to writer: inout BinaryWriter ) throws					{ writer.write( self ) }
	static func read( from reader: inout BinaryReader ) throws -> Self	{ return try reader.read() }
}

extension Int 		: GNativeCodable {}
extension Int8 		: GNativeCodable {}
extension Int16 	: GNativeCodable {}
extension Int32 	: GNativeCodable {}
extension Int64 	: GNativeCodable {}
extension UInt 		: GNativeCodable {}
extension UInt8 	: GNativeCodable {}
extension UInt16 	: GNativeCodable {}
extension UInt32 	: GNativeCodable {}
extension UInt64 	: GNativeCodable {}

// --------------------------------------------------------------------------------------------------------

extension BinaryFloatingPoint {
	func write( to writer: inout BinaryWriter ) throws					{ writer.write( self ) }
	static func read( from reader: inout BinaryReader ) throws -> Self	{ return try reader.read() }
}

extension Float 	: GNativeCodable {}
extension Double 	: GNativeCodable {}

// --------------------------------------------------------------------------------------------------------

extension String 	: GNativeCodable {
	func write( to writer: inout BinaryWriter ) throws					{ writer.write( self ) }
	static func read( from reader: inout BinaryReader ) throws -> Self	{ return try reader.read() }
}

// --------------------------------------------------------------------------------------------------------

extension Data 		: GNativeCodable {
	func write( to writer: inout BinaryWriter ) throws					{ writer.write( self ) }
	static func read( from reader: inout BinaryReader ) throws -> Self	{ return try reader.read() }
}

// --------------------------------------------------------------------------------------------------------
