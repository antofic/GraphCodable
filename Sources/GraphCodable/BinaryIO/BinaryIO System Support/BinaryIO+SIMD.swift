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

extension SIMDStorage where Scalar:BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		for i in 0..<Self.scalarCount {
			try self[i].write(to: &wbuffer)
		}
	}
}
extension SIMDStorage where Scalar:BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		self.init()
		for i in 0..<Self.scalarCount {
			self[i]	= try Scalar(from: &rbuffer)
		}
	}
}

extension SIMD2:BinaryIType where Scalar:BinaryIType {}
extension SIMD3:BinaryIType where Scalar:BinaryIType {}
extension SIMD4:BinaryIType where Scalar:BinaryIType {}
extension SIMD8:BinaryIType where Scalar:BinaryIType {}
extension SIMD16:BinaryIType where Scalar:BinaryIType {}
extension SIMD32:BinaryIType where Scalar:BinaryIType {}
extension SIMD64:BinaryIType where Scalar:BinaryIType {}

extension SIMD2:BinaryOType where Scalar:BinaryOType {}
extension SIMD3:BinaryOType where Scalar:BinaryOType {}
extension SIMD4:BinaryOType where Scalar:BinaryOType {}
extension SIMD8:BinaryOType where Scalar:BinaryOType {}
extension SIMD16:BinaryOType where Scalar:BinaryOType {}
extension SIMD32:BinaryOType where Scalar:BinaryOType {}
extension SIMD64:BinaryOType where Scalar:BinaryOType {}

extension SIMDMask:BinaryIType {}
extension SIMDMask:BinaryOType {}

// Matrix support

protocol SimdMatrixBinaryIO : BinaryIOType {
	associatedtype Vector : BinaryIOType
	init()
	subscript(column: Int) -> Vector { get set }
	var _binaryNumCols : Int  { get }
}

extension SimdMatrixBinaryIO {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		for c in 0..<_binaryNumCols {
			try self[c].write(to: &wbuffer)
		}
	}

	public init(from rbuffer: inout BinaryReadBuffer) throws {
		self.init()
		for c in 0..<_binaryNumCols {
			self[c]	= try Vector(from: &rbuffer)
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


