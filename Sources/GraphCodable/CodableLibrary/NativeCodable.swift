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

// -- Int & UInt support (NativeCodable) --------------------------------------------
protocol NativeEncodable	: GBinaryEncodable {}
protocol NativeDecodable	: GBinaryDecodable {}
typealias NativeCodable = NativeEncodable & NativeDecodable

extension Int		: NativeCodable {}
extension Int8		: NativeCodable {}
extension Int16		: NativeCodable {}
extension Int32		: NativeCodable {}
extension Int64		: NativeCodable {}
extension UInt		: NativeCodable {}
extension UInt8		: NativeCodable {}
extension UInt16	: NativeCodable {}
extension UInt32	: NativeCodable {}
extension UInt64	: NativeCodable {}

// -- BinaryFloatingPoint support -------------------------------------------------------
extension Float		: NativeCodable {}
extension Double	: NativeCodable {}
extension CGFloat	: NativeCodable {}

// -- Bool support -------------------------------------------------------
extension Bool 		: NativeCodable {}

// -- String support --------------------------------------------
extension String 	: NativeCodable {}
