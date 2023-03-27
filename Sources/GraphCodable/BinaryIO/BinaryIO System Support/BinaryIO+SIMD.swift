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

extension SIMDStorage where Scalar:BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		for i in 0..<Self.scalarCount {
			try encoder.encode( self[i] )
		}
	}
}
extension SIMDStorage where Scalar:BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self.init()
		for i in 0..<Self.scalarCount {
			self[i]	= try decoder.decode()
		}
	}
}


extension SIMD2: BEncodable where Scalar:BEncodable {}
extension SIMD3: BEncodable where Scalar:BEncodable {}
extension SIMD4: BEncodable where Scalar:BEncodable {}
extension SIMD8: BEncodable where Scalar:BEncodable {}
extension SIMD16:BEncodable where Scalar:BEncodable {}
extension SIMD32:BEncodable where Scalar:BEncodable {}
extension SIMD64:BEncodable where Scalar:BEncodable {}

extension SIMD2: BDecodable where Scalar:BDecodable {}
extension SIMD3: BDecodable where Scalar:BDecodable {}
extension SIMD4: BDecodable where Scalar:BDecodable {}
extension SIMD8: BDecodable where Scalar:BDecodable {}
extension SIMD16:BDecodable where Scalar:BDecodable {}
extension SIMD32:BDecodable where Scalar:BDecodable {}
extension SIMD64:BDecodable where Scalar:BDecodable {}

extension SIMDMask:BEncodable {}
extension SIMDMask:BDecodable {}

// Matrix support

protocol SimdMatrixBinaryIO : BCodable {
	associatedtype Vector : BCodable
	init()
	subscript(column: Int) -> Vector { get set }
	var _binaryNumCols : Int  { get }
}

extension SimdMatrixBinaryIO {
	public func encode(to encoder: inout some BEncoder) throws {
		for c in 0..<_binaryNumCols {
			try encoder.encode( self[c] )
		}
	}
	
	public init(from decoder: inout some BDecoder) throws {
		self.init()
		for c in 0..<_binaryNumCols {
			self[c]	= try decoder.decode()
		}
	}
}

extension simd_float2x2: SimdMatrixBinaryIO { var _binaryNumCols: Int { 2 } }
extension simd_float2x3: SimdMatrixBinaryIO { var _binaryNumCols: Int { 2 } }
extension simd_float2x4: SimdMatrixBinaryIO { var _binaryNumCols: Int { 2 } }
extension simd_float3x2: SimdMatrixBinaryIO { var _binaryNumCols: Int { 3 } }
extension simd_float3x3: SimdMatrixBinaryIO { var _binaryNumCols: Int { 3 } }
extension simd_float3x4: SimdMatrixBinaryIO { var _binaryNumCols: Int { 3 } }
extension simd_float4x2: SimdMatrixBinaryIO { var _binaryNumCols: Int { 4 } }
extension simd_float4x3: SimdMatrixBinaryIO { var _binaryNumCols: Int { 4 } }
extension simd_float4x4: SimdMatrixBinaryIO { var _binaryNumCols: Int { 4 } }

extension simd_double2x2: SimdMatrixBinaryIO { var _binaryNumCols: Int { 2 } }
extension simd_double2x3: SimdMatrixBinaryIO { var _binaryNumCols: Int { 2 } }
extension simd_double2x4: SimdMatrixBinaryIO { var _binaryNumCols: Int { 2 } }
extension simd_double3x2: SimdMatrixBinaryIO { var _binaryNumCols: Int { 3 } }
extension simd_double3x3: SimdMatrixBinaryIO { var _binaryNumCols: Int { 3 } }
extension simd_double3x4: SimdMatrixBinaryIO { var _binaryNumCols: Int { 3 } }
extension simd_double4x2: SimdMatrixBinaryIO { var _binaryNumCols: Int { 4 } }
extension simd_double4x3: SimdMatrixBinaryIO { var _binaryNumCols: Int { 4 } }
extension simd_double4x4: SimdMatrixBinaryIO { var _binaryNumCols: Int { 4 } }

