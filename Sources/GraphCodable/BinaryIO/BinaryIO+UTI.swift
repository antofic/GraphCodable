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

import UniformTypeIdentifiers

extension UTTagClass : BinaryIOType {}

extension UTType : BinaryIOType {
	private enum Version : UInt8 { case v0 }

	public func write(to writer: inout BinaryWriter) throws {
		try Version.v0.rawValue.write(to: &writer)
		try identifier.write(to: &writer)
	}
	
	public init(from reader: inout BinaryReader) throws {
		let versionRaw	= try Version.RawValue(from: &reader)

		switch versionRaw {
		case Version.v0.rawValue:
			let identifier = try String( from: &reader )
			
			guard let uttype = Self.init( identifier ) else {
				throw BinaryIOError.initTypeError(
					Self.self, BinaryIOError.Context(
						debugDescription: "Invalid UTType identifier -\(identifier)-"
					)
				)
			}
			self = uttype
		default:
			throw BinaryIOError.versionError(
				Self.self, BinaryIOError.Context(
					debugDescription: "\(Self.self) data in a new unknown version -\(versionRaw)-."
				)
			)
		}
	}
}

