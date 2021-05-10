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


protocol NativeType : BinaryIOType, GCodable {}

extension NativeType {
	public func encode(to encoder: GEncoder) throws	{
		throw GCodableError.internalInconsistency(
			Self.self, GCodableError.Context(
				debugDescription: "Program must not reach this point."
			)
		)
	}
	
	public init(from decoder: GDecoder) throws {
		throw GCodableError.internalInconsistency(
			Self.self, GCodableError.Context(
				debugDescription: "Program must not reach this point."
			)
		)
	}
}

// -- Int & UInt support (NativeType) --------------------------------------------

extension Int		: NativeType {}
extension Int8		: NativeType {}
extension Int16		: NativeType {}
extension Int32		: NativeType {}
extension Int64		: NativeType {}
extension UInt		: NativeType {}
extension UInt8		: NativeType {}
extension UInt16	: NativeType {}
extension UInt32	: NativeType {}
extension UInt64	: NativeType {}

// -- BinaryFloatingPoint support -------------------------------------------------------
extension Float		: NativeType {}
extension Double	: NativeType {}
extension CGFloat	: NativeType {}

// -- Bool support -------------------------------------------------------
extension Bool 		: NativeType {}

// -- String & Character support --------------------------------------------
extension String 	: NativeType {}
extension Character : NativeType {}

// -- Data support ----------------------------------------------------------
extension Data 		: NativeType {}