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
/*
extension GCodable where Self : RawRepresentable, Self.RawValue : GCodable {
	public func encode(to encoder: GEncoder) throws	{
		try encoder.encode( self.rawValue )
	}
	public init(from decoder: GDecoder) throws {
		let rawValue = try decoder.decode() as RawValue
		guard let value = Self.init(rawValue:rawValue ) else {
			throw GCodableError.initGCodableError(
				Self.self, GCodableError.Context(
					debugDescription: "Invalid rawValue = \(rawValue) for \(Self.self)"
				)
			)
		}
		self = value
	}
}
*/

extension RawRepresentable where Self.RawValue : GCodable {
	public func encode(to encoder: GEncoder) throws	{
		try encoder.encode( self.rawValue )
	}
	public init(from decoder: GDecoder) throws {
		let rawValue = try decoder.decode() as RawValue
		guard let value = Self.init(rawValue:rawValue ) else {
			throw GCodableError.initGCodableError(
				Self.self, GCodableError.Context(
					debugDescription: "Invalid rawValue = \(rawValue) for \(Self.self)"
				)
			)
		}
		self = value
	}
}

extension RawRepresentable where Self.RawValue : NativeIOType {
	func write( to writer: inout BinaryWriter ) throws {
		try self.rawValue.write(to: &writer)
	}
	init( from reader: inout BinaryReader ) throws {
		guard let value = Self(rawValue: try Self.RawValue(from: &reader) ) else {
			throw BinaryReaderError.cantConstructRawRepresentable
		}
		self = value
	}
}
