//
//  File.swift
//  
//
//  Created by Antonino Ficarra on 07/02/23.
//

import Foundation
import simd

// SIMD Vector support

extension SIMDStorage where Scalar:GCodable {
	public func encode(to encoder: GraphCodable.GEncoder) throws {
		for i in 0..<Self.scalarCount {
			try encoder.encode( self[i] )
		}
	}
	
	public init(from decoder: GraphCodable.GDecoder) throws {
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
	associatedtype Scalar : GCodable
	init()
	subscript(column: Int, row: Int) -> Scalar { get set }
	var codableDim : (cols: Int, rows: Int)  { get }
}

extension SimdMatrixCodable {
	public func encode(to encoder: GraphCodable.GEncoder) throws {
		let (cols,rows) = codableDim
		for r in 0..<rows {
			for c in 0..<cols {
				try encoder.encode( self[c,r] )
			}
		}
	}
	public init(from decoder: GraphCodable.GDecoder) throws {
		self.init()
		let (cols,rows) = codableDim
		for r in 0..<rows {
			for c in 0..<cols {
				self[c,r]	= try decoder.decode()
			}
		}
	}
}

extension simd_float2x2: SimdMatrixCodable { var codableDim: (cols: Int, rows: Int) { (2,2) } }
extension simd_float2x3: SimdMatrixCodable { var codableDim: (cols: Int, rows: Int) { (2,3) } }
extension simd_float2x4: SimdMatrixCodable { var codableDim: (cols: Int, rows: Int) { (2,4) } }
extension simd_float3x2: SimdMatrixCodable { var codableDim: (cols: Int, rows: Int) { (3,2) } }
extension simd_float3x3: SimdMatrixCodable { var codableDim: (cols: Int, rows: Int) { (3,3) } }
extension simd_float3x4: SimdMatrixCodable { var codableDim: (cols: Int, rows: Int) { (3,4) } }
extension simd_float4x2: SimdMatrixCodable { var codableDim: (cols: Int, rows: Int) { (4,2) } }
extension simd_float4x3: SimdMatrixCodable { var codableDim: (cols: Int, rows: Int) { (4,3) } }
extension simd_float4x4: SimdMatrixCodable { var codableDim: (cols: Int, rows: Int) { (4,4) } }

extension simd_double2x2: SimdMatrixCodable { var codableDim: (cols: Int, rows: Int) { (2,2) } }
extension simd_double2x3: SimdMatrixCodable { var codableDim: (cols: Int, rows: Int) { (2,3) } }
extension simd_double2x4: SimdMatrixCodable { var codableDim: (cols: Int, rows: Int) { (2,4) } }
extension simd_double3x2: SimdMatrixCodable { var codableDim: (cols: Int, rows: Int) { (3,2) } }
extension simd_double3x3: SimdMatrixCodable { var codableDim: (cols: Int, rows: Int) { (3,3) } }
extension simd_double3x4: SimdMatrixCodable { var codableDim: (cols: Int, rows: Int) { (3,4) } }
extension simd_double4x2: SimdMatrixCodable { var codableDim: (cols: Int, rows: Int) { (4,2) } }
extension simd_double4x3: SimdMatrixCodable { var codableDim: (cols: Int, rows: Int) { (4,3) } }
extension simd_double4x4: SimdMatrixCodable { var codableDim: (cols: Int, rows: Int) { (4,4) } }
