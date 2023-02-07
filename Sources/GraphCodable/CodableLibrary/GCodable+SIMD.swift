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

