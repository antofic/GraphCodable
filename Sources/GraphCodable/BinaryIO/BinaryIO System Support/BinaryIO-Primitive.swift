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

extension Bool:		BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encode(self) } }
extension UInt:		BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encode(self) } }
extension UInt8:	BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encode(self) } }
extension UInt16:	BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encode(self) } }
extension UInt32:	BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encode(self) } }
extension UInt64:	BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encode(self) } }
extension Int:		BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encode(self) } }
extension Int8:		BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encode(self) } }
extension Int16:	BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encode(self) } }
extension Int32:	BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encode(self) } }
extension Int64:	BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encode(self) } }
extension Float:	BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encode(self) } }
extension Double:	BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encode(self) } }
extension String:	BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encode(self) } }
extension Data:		BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.encode(self) } }

extension Bool:		BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decode() } }
extension UInt:		BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decode() } }
extension UInt8:	BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decode() } }
extension UInt16:	BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decode() } }
extension UInt32:	BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decode() } }
extension UInt64:	BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decode() } }
extension Int:		BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decode() } }
extension Int8:		BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decode() } }
extension Int16:	BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decode() } }
extension Int32:	BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decode() } }
extension Int64:	BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decode() } }
extension Float:	BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decode() } }
extension Double:	BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decode() } }
extension String:	BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decode() } }
extension Data:		BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.decode() } }

