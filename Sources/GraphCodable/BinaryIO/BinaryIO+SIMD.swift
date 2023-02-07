//
//  File.swift
//  
//
//  Created by Antonino Ficarra on 07/02/23.
//

import Foundation
import simd

extension SIMDStorage where Scalar:BinaryIOType {
	public func write(to writer: inout BinaryWriter) throws {
		for i in 0..<Self.scalarCount {
			try self[i].write(to: &writer)
		}
	}

	public init(from reader: inout BinaryReader) throws {
		self.init()
		for i in 0..<Self.scalarCount {
			self[i]	= try Scalar(from: &reader)
		}
	}
}

extension SIMD2:BinaryIOType where Scalar:BinaryIOType {}
extension SIMD3:BinaryIOType where Scalar:BinaryIOType {}
extension SIMD4:BinaryIOType where Scalar:BinaryIOType {}
extension SIMD8:BinaryIOType where Scalar:BinaryIOType {}
extension SIMD16:BinaryIOType where Scalar:BinaryIOType {}
extension SIMD32:BinaryIOType where Scalar:BinaryIOType {}
extension SIMD64:BinaryIOType where Scalar:BinaryIOType {}
extension SIMDMask:BinaryIOType {}

// Matrix support

protocol SimdMatrixBinaryIO : BinaryIOType {
	associatedtype Scalar : BinaryIOType
	init()
	subscript(column: Int, row: Int) -> Scalar { get set }
	var binaryIODim : (cols: Int, rows: Int)  { get }
}

extension SimdMatrixBinaryIO {
	public func write(to writer: inout BinaryWriter) throws {
		let (cols,rows) = binaryIODim
		for r in 0..<rows {
			for c in 0..<cols {
				try self[c,r].write(to: &writer)
			}
		}

	}

	public init(from reader: inout BinaryReader) throws {
		self.init()
		let (cols,rows) = binaryIODim
		for r in 0..<rows {
			for c in 0..<cols {
				self[c,r]	= try Scalar(from: &reader)
			}
		}
	}
}

extension simd_float2x2: SimdMatrixBinaryIO { var binaryIODim: (cols: Int, rows: Int) { (2,2) } }
extension simd_float2x3: SimdMatrixBinaryIO { var binaryIODim: (cols: Int, rows: Int) { (2,3) } }
extension simd_float2x4: SimdMatrixBinaryIO { var binaryIODim: (cols: Int, rows: Int) { (2,4) } }
extension simd_float3x2: SimdMatrixBinaryIO { var binaryIODim: (cols: Int, rows: Int) { (3,2) } }
extension simd_float3x3: SimdMatrixBinaryIO { var binaryIODim: (cols: Int, rows: Int) { (3,3) } }
extension simd_float3x4: SimdMatrixBinaryIO { var binaryIODim: (cols: Int, rows: Int) { (3,4) } }
extension simd_float4x2: SimdMatrixBinaryIO { var binaryIODim: (cols: Int, rows: Int) { (4,2) } }
extension simd_float4x3: SimdMatrixBinaryIO { var binaryIODim: (cols: Int, rows: Int) { (4,3) } }
extension simd_float4x4: SimdMatrixBinaryIO { var binaryIODim: (cols: Int, rows: Int) { (4,4) } }

extension simd_double2x2: SimdMatrixBinaryIO { var binaryIODim: (cols: Int, rows: Int) { (2,2) } }
extension simd_double2x3: SimdMatrixBinaryIO { var binaryIODim: (cols: Int, rows: Int) { (2,3) } }
extension simd_double2x4: SimdMatrixBinaryIO { var binaryIODim: (cols: Int, rows: Int) { (2,4) } }
extension simd_double3x2: SimdMatrixBinaryIO { var binaryIODim: (cols: Int, rows: Int) { (3,2) } }
extension simd_double3x3: SimdMatrixBinaryIO { var binaryIODim: (cols: Int, rows: Int) { (3,3) } }
extension simd_double3x4: SimdMatrixBinaryIO { var binaryIODim: (cols: Int, rows: Int) { (3,4) } }
extension simd_double4x2: SimdMatrixBinaryIO { var binaryIODim: (cols: Int, rows: Int) { (4,2) } }
extension simd_double4x3: SimdMatrixBinaryIO { var binaryIODim: (cols: Int, rows: Int) { (4,3) } }
extension simd_double4x4: SimdMatrixBinaryIO { var binaryIODim: (cols: Int, rows: Int) { (4,4) } }
