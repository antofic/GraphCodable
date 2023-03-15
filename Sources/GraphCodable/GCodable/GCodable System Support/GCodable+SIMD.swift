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
extension SIMDStorage	where Scalar:GPackCodable {}
extension SIMDMask		where Scalar:GPackCodable {}

extension SIMD2:GCodable	where Scalar:GPackCodable {}
extension SIMD3:GCodable	where Scalar:GPackCodable {}
extension SIMD4:GCodable	where Scalar:GPackCodable {}
extension SIMD8:GCodable	where Scalar:GPackCodable {}
extension SIMD16:GCodable	where Scalar:GPackCodable {}
extension SIMD32:GCodable	where Scalar:GPackCodable {}
extension SIMD64:GCodable	where Scalar:GPackCodable {}

extension SIMD2:GPackCodable		where Scalar:GPackCodable {}
extension SIMD3:GPackCodable		where Scalar:GPackCodable {}
extension SIMD4:GPackCodable		where Scalar:GPackCodable {}
extension SIMD8:GPackCodable		where Scalar:GPackCodable {}
extension SIMD16:GPackCodable	where Scalar:GPackCodable {}
extension SIMD32:GPackCodable	where Scalar:GPackCodable {}
extension SIMD64:GPackCodable	where Scalar:GPackCodable {}

// Matrix support

extension simd_float2x2:	GPackCodable {}
extension simd_float2x3:	GPackCodable {}
extension simd_float2x4:	GPackCodable {}
extension simd_float3x2:	GPackCodable {}
extension simd_float3x3:	GPackCodable {}
extension simd_float3x4:	GPackCodable {}
extension simd_float4x2:	GPackCodable {}
extension simd_float4x3:	GPackCodable {}
extension simd_float4x4:	GPackCodable {}

extension simd_double2x2:	GPackCodable {}
extension simd_double2x3:	GPackCodable {}
extension simd_double2x4:	GPackCodable {}
extension simd_double3x2:	GPackCodable {}
extension simd_double3x3:	GPackCodable {}
extension simd_double3x4:	GPackCodable {}
extension simd_double4x2:	GPackCodable {}
extension simd_double4x3:	GPackCodable {}
extension simd_double4x4:	GPackCodable {}
