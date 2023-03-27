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


import UniformTypeIdentifiers

extension UTTagClass : BDecodable {}
extension UTTagClass : BEncodable {}

extension UTType : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( identifier )
	}
}
extension UTType : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		let identifier = try decoder.decode() as String
		
		guard let uttype = Self.init( identifier ) else {
			throw BinaryIOError.libDecodingError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Invalid UTType identifier -\(identifier)-"
				)
			)
		}
		self = uttype
	}
}


