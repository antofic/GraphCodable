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
import simd

// SIMD Vector support

extension SIMDStorage where Scalar:GEncodable {
	public func encode(to encoder: GEncoder) throws {
		for i in 0..<Self.scalarCount {
			try encoder.encode( self[i] )
		}
	}
}

extension SIMDStorage where Scalar:GDecodable {
	public init(from decoder: GDecoder) throws {
		self.init()
		for i in 0..<Self.scalarCount {
			self[i]	= try decoder.decode()
		}
	}
}

extension SIMD2:GCodable where Scalar:GCodable {}
extension SIMD3:GCodable where Scalar:GCodable {}
extension SIMD4:GCodable where Scalar:GCodable {}
extension SIMD8:GCodable where Scalar:GCodable {}
extension SIMD16:GCodable where Scalar:GCodable {}
extension SIMD32:GCodable where Scalar:GCodable {}
extension SIMD64:GCodable where Scalar:GCodable {}
extension SIMDMask:GCodable {}

// Matrix support

protocol SimdMatrixCodable : GCodable {
	associatedtype Vector : GCodable
	init()
	subscript(column: Int) -> Vector { get set }
	var _codableNumCols : Int  { get }
}

extension SimdMatrixCodable {
	public func encode(to encoder: GraphCodable.GEncoder) throws {
		for c in 0..<_codableNumCols {
			try encoder.encode( self[c] )
		}
	}
	public init(from decoder: GraphCodable.GDecoder) throws {
		self.init()
		for c in 0..<_codableNumCols {
			self[c]	= try decoder.decode()
		}
	}
}

extension simd_float2x2: SimdMatrixCodable { var _codableNumCols: Int { 2 } }
extension simd_float2x3: SimdMatrixCodable { var _codableNumCols: Int { 2 } }
extension simd_float2x4: SimdMatrixCodable { var _codableNumCols: Int { 2 } }
extension simd_float3x2: SimdMatrixCodable { var _codableNumCols: Int { 3 } }
extension simd_float3x3: SimdMatrixCodable { var _codableNumCols: Int { 3 } }
extension simd_float3x4: SimdMatrixCodable { var _codableNumCols: Int { 3 } }
extension simd_float4x2: SimdMatrixCodable { var _codableNumCols: Int { 4 } }
extension simd_float4x3: SimdMatrixCodable { var _codableNumCols: Int { 4 } }
extension simd_float4x4: SimdMatrixCodable { var _codableNumCols: Int { 4 } }

extension simd_double2x2: SimdMatrixCodable { var _codableNumCols: Int { 2 } }
extension simd_double2x3: SimdMatrixCodable { var _codableNumCols: Int { 2 } }
extension simd_double2x4: SimdMatrixCodable { var _codableNumCols: Int { 2 } }
extension simd_double3x2: SimdMatrixCodable { var _codableNumCols: Int { 3 } }
extension simd_double3x3: SimdMatrixCodable { var _codableNumCols: Int { 3 } }
extension simd_double3x4: SimdMatrixCodable { var _codableNumCols: Int { 3 } }
extension simd_double4x2: SimdMatrixCodable { var _codableNumCols: Int { 4 } }
extension simd_double4x3: SimdMatrixCodable { var _codableNumCols: Int { 4 } }
extension simd_double4x4: SimdMatrixCodable { var _codableNumCols: Int { 4 } }

