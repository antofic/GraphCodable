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

import simd

// SIMD Vector support

extension SIMDStorage	where Scalar:GBinaryEncodable {}
extension SIMDMask		where Scalar:GBinaryEncodable {}
extension SIMDStorage	where Scalar:GBinaryDecodable {}
extension SIMDMask		where Scalar:GBinaryDecodable {}
extension SIMDStorage	where Scalar:GPackable {}
extension SIMDMask		where Scalar:GPackable {}

extension SIMD2:GEncodable			where Scalar:GBinaryEncodable {}
extension SIMD2:GBinaryEncodable	where Scalar:GBinaryEncodable {}
extension SIMD2:GDecodable			where Scalar:GBinaryDecodable {}
extension SIMD2:GBinaryDecodable	where Scalar:GBinaryDecodable {}
extension SIMD2:GPackable			where Scalar:GPackable {}

extension SIMD3:GEncodable			where Scalar:GBinaryEncodable {}
extension SIMD3:GBinaryEncodable	where Scalar:GBinaryEncodable {}
extension SIMD3:GDecodable			where Scalar:GBinaryDecodable {}
extension SIMD3:GBinaryDecodable	where Scalar:GBinaryDecodable {}
extension SIMD3:GPackable			where Scalar:GPackable {}

extension SIMD4:GEncodable			where Scalar:GBinaryEncodable {}
extension SIMD4:GBinaryEncodable	where Scalar:GBinaryEncodable {}
extension SIMD4:GDecodable			where Scalar:GBinaryDecodable {}
extension SIMD4:GBinaryDecodable	where Scalar:GBinaryDecodable {}
extension SIMD4:GPackable			where Scalar:GPackable {}

extension SIMD8:GEncodable			where Scalar:GBinaryEncodable {}
extension SIMD8:GBinaryEncodable	where Scalar:GBinaryEncodable {}
extension SIMD8:GDecodable			where Scalar:GBinaryDecodable {}
extension SIMD8:GBinaryDecodable	where Scalar:GBinaryDecodable {}
extension SIMD8:GPackable			where Scalar:GPackable {}

extension SIMD16:GEncodable			where Scalar:GBinaryEncodable {}
extension SIMD16:GBinaryEncodable	where Scalar:GBinaryEncodable {}
extension SIMD16:GDecodable			where Scalar:GBinaryDecodable {}
extension SIMD16:GBinaryDecodable	where Scalar:GBinaryDecodable {}
extension SIMD16:GPackable			where Scalar:GPackable {}

extension SIMD32:GEncodable			where Scalar:GBinaryEncodable {}
extension SIMD32:GBinaryEncodable	where Scalar:GBinaryEncodable {}
extension SIMD32:GDecodable			where Scalar:GBinaryDecodable {}
extension SIMD32:GBinaryDecodable	where Scalar:GBinaryDecodable {}
extension SIMD32:GPackable			where Scalar:GPackable {}

extension SIMD64:GEncodable			where Scalar:GBinaryEncodable {}
extension SIMD64:GBinaryEncodable	where Scalar:GBinaryEncodable {}
extension SIMD64:GDecodable			where Scalar:GBinaryDecodable {}
extension SIMD64:GBinaryDecodable	where Scalar:GBinaryDecodable {}
extension SIMD64:GPackable			where Scalar:GPackable {}

// Matrix support

extension simd_float2x2:	GBinaryEncodable {}
extension simd_float2x2:	GBinaryDecodable {}
extension simd_float2x2:	GPackable {}

extension simd_float2x3:	GBinaryEncodable {}
extension simd_float2x3:	GBinaryDecodable {}
extension simd_float2x3:	GPackable {}

extension simd_float2x4:	GBinaryEncodable {}
extension simd_float2x4:	GBinaryDecodable {}
extension simd_float2x4:	GPackable {}

extension simd_float3x2:	GBinaryEncodable {}
extension simd_float3x2:	GBinaryDecodable {}
extension simd_float3x2:	GPackable {}

extension simd_float3x3:	GBinaryEncodable {}
extension simd_float3x3:	GBinaryDecodable {}
extension simd_float3x3:	GPackable {}

extension simd_float3x4:	GBinaryEncodable {}
extension simd_float3x4:	GBinaryDecodable {}
extension simd_float3x4:	GPackable {}

extension simd_float4x2:	GBinaryEncodable {}
extension simd_float4x2:	GBinaryDecodable {}
extension simd_float4x2:	GPackable {}

extension simd_float4x3:	GBinaryEncodable {}
extension simd_float4x3:	GBinaryDecodable {}
extension simd_float4x3:	GPackable {}

extension simd_float4x4:	GBinaryEncodable {}
extension simd_float4x4:	GBinaryDecodable {}
extension simd_float4x4:	GPackable {}

extension simd_double2x2:	GBinaryEncodable {}
extension simd_double2x2:	GBinaryDecodable {}
extension simd_double2x2:	GPackable {}

extension simd_double2x3:	GBinaryEncodable {}
extension simd_double2x3:	GBinaryDecodable {}
extension simd_double2x3:	GPackable {}

extension simd_double2x4:	GBinaryEncodable {}
extension simd_double2x4:	GBinaryDecodable {}
extension simd_double2x4:	GPackable {}

extension simd_double3x2:	GBinaryEncodable {}
extension simd_double3x2:	GBinaryDecodable {}
extension simd_double3x2:	GPackable {}

extension simd_double3x3:	GBinaryEncodable {}
extension simd_double3x3:	GBinaryDecodable {}
extension simd_double3x3:	GPackable {}

extension simd_double3x4:	GBinaryEncodable {}
extension simd_double3x4:	GBinaryDecodable {}
extension simd_double3x4:	GPackable {}

extension simd_double4x2:	GBinaryEncodable {}
extension simd_double4x2:	GBinaryDecodable {}
extension simd_double4x2:	GPackable {}

extension simd_double4x3:	GBinaryEncodable {}
extension simd_double4x3:	GBinaryDecodable {}
extension simd_double4x3:	GPackable {}

extension simd_double4x4:	GBinaryEncodable {}
extension simd_double4x4:	GBinaryDecodable {}
extension simd_double4x4:	GPackable {}