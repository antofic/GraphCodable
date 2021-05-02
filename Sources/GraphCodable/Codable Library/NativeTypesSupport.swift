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

enum NativeCode : UInt8 {
	case int = 0,int8,int16,int32,int64
	case uint = 8,uint8,uint16,uint32,uint64
	case float = 16,double
	case bool = 24, string, data
	
	func readNativeType( from reader: inout BinaryReader ) throws -> GNativeCodable {
		switch self {
		case .int: 		return try Int.read(from: &reader)
		case .int8: 	return try Int8.read(from: &reader)
		case .int16: 	return try Int16.read(from: &reader)
		case .int32: 	return try Int32.read(from: &reader)
		case .int64: 	return try Int64.read(from: &reader)
		case .uint: 	return try UInt.read(from: &reader)
		case .uint8: 	return try UInt8.read(from: &reader)
		case .uint16: 	return try UInt16.read(from: &reader)
		case .uint32: 	return try UInt32.read(from: &reader)
		case .uint64: 	return try UInt64.read(from: &reader)
		case .float: 	return try Float.read(from: &reader)
		case .double: 	return try Double.read(from: &reader)
		case .bool: 	return try Bool.read(from: &reader)
		case .string: 	return try String.read(from: &reader)
		case .data: 	return try Data.read(from: &reader)
		}
	}
}

protocol GNativeCodable : GCodable {
	static var nativeCode	: NativeCode { get }
	
	func write( to: inout BinaryWriter ) throws
	static func read( from: inout BinaryReader ) throws -> Self
}

extension GNativeCodable {
	public func encode(to encoder: GEncoder) throws	{ throw GCodableError.nativeEncodeError }
	public init(from decoder: GDecoder) throws		{ throw GCodableError.nativeDecodeError }
}

// --------------------------------------------------------------------------------------------------------

extension Bool 		: GNativeCodable {
	static let nativeCode = NativeCode.bool
	
	func write( to writer: inout BinaryWriter ) throws					{ writer.write( self ) }
	static func read( from reader: inout BinaryReader ) throws -> Self	{ return try reader.read() }
}

// --------------------------------------------------------------------------------------------------------

extension BinaryInteger  {
	func write( to writer: inout BinaryWriter ) throws					{ writer.write( self ) }
	static func read( from reader: inout BinaryReader ) throws -> Self	{ return try reader.read() }
}

extension Int 		: GNativeCodable { static let nativeCode = NativeCode.int }
extension Int8 		: GNativeCodable { static let nativeCode = NativeCode.int8 }
extension Int16 	: GNativeCodable { static let nativeCode = NativeCode.int16 }
extension Int32 	: GNativeCodable { static let nativeCode = NativeCode.int32 }
extension Int64 	: GNativeCodable { static let nativeCode = NativeCode.int64 }
extension UInt 		: GNativeCodable { static let nativeCode = NativeCode.uint }
extension UInt8 	: GNativeCodable { static let nativeCode = NativeCode.uint8  }
extension UInt16 	: GNativeCodable { static let nativeCode = NativeCode.uint16 }
extension UInt32 	: GNativeCodable { static let nativeCode = NativeCode.uint32 }
extension UInt64 	: GNativeCodable { static let nativeCode = NativeCode.uint64 }

// --------------------------------------------------------------------------------------------------------

extension BinaryFloatingPoint {
	func write( to writer: inout BinaryWriter ) throws					{ writer.write( self ) }
	static func read( from reader: inout BinaryReader ) throws -> Self	{ return try reader.read() }
}

extension Float 	: GNativeCodable { static let nativeCode = NativeCode.float }
extension Double 	: GNativeCodable { static let nativeCode = NativeCode.double }

// --------------------------------------------------------------------------------------------------------

extension String 	: GNativeCodable {
	static let nativeCode = NativeCode.string

	func write( to writer: inout BinaryWriter ) throws					{ writer.write( self ) }
	static func read( from reader: inout BinaryReader ) throws -> Self	{ return try reader.read() }
}

// --------------------------------------------------------------------------------------------------------

extension Data 		: GNativeCodable {
	static let nativeCode = NativeCode.data

	func write( to writer: inout BinaryWriter ) throws					{ writer.write( self ) }
	static func read( from reader: inout BinaryReader ) throws -> Self	{ return try reader.read() }
}

// --------------------------------------------------------------------------------------------------------
