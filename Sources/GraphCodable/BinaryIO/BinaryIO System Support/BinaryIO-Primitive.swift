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

extension Bool:		BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.withUnderlyingType { try $0.encodeBool(self) } } }
extension UInt:		BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.withUnderlyingType { try $0.encodeUInt(self) } } }
extension UInt8:	BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.withUnderlyingType { try $0.encodeUInt8(self) } } }
extension UInt16:	BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.withUnderlyingType { try $0.encodeUInt16(self) } } }
extension UInt32:	BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.withUnderlyingType { try $0.encodeUInt32(self) } } }
extension UInt64:	BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.withUnderlyingType { try $0.encodeUInt64(self) } } }
extension Int:		BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.withUnderlyingType { try $0.encodeInt(self) } } }
extension Int8:		BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.withUnderlyingType { try $0.encodeInt8(self) } } }
extension Int16:	BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.withUnderlyingType { try $0.encodeInt16(self) } } }
extension Int32:	BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.withUnderlyingType { try $0.encodeInt32(self) } } }
extension Int64:	BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.withUnderlyingType { try $0.encodeInt64(self) } } }
extension Float:	BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.withUnderlyingType { try $0.encodeFloat(self) } } }
extension Double:	BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.withUnderlyingType { try $0.encodeDouble(self) } } }
extension String:	BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.withUnderlyingType { try $0.encodeString(self) } } }
extension Data:		BEncodable { public func encode(to encoder: inout some BEncoder) throws { try encoder.withUnderlyingType { try $0.encodeData(self) } } }

extension Bool:		BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.withUnderlyingType { try $0.decodeBool() } } }
extension UInt:		BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.withUnderlyingType { try $0.decodeUInt() } } }
extension UInt8:	BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.withUnderlyingType { try $0.decodeUInt8() } } }
extension UInt16:	BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.withUnderlyingType { try $0.decodeUInt16() } } }
extension UInt32:	BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.withUnderlyingType { try $0.decodeUInt32() } } }
extension UInt64:	BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.withUnderlyingType { try $0.decodeUInt64() } } }
extension Int:		BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.withUnderlyingType { try $0.decodeInt() } } }
extension Int8:		BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.withUnderlyingType { try $0.decodeInt8() } } }
extension Int16:	BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.withUnderlyingType { try $0.decodeInt16() } } }
extension Int32:	BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.withUnderlyingType { try $0.decodeInt32() } } }
extension Int64:	BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.withUnderlyingType { try $0.decodeInt64() } } }
extension Float:	BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.withUnderlyingType { try $0.decodeFloat() } } }
extension Double:	BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.withUnderlyingType { try $0.decodeDouble() } } }
extension String:	BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.withUnderlyingType { try $0.decodeString() } } }
extension Data:		BDecodable { public init(from decoder: inout some BDecoder) throws { self = try decoder.withUnderlyingType { try $0.decodeData() } } }


















