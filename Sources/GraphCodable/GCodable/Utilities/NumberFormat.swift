//
//  BinaryFloatingPointFormat.swift
//  SIMDTest
//
//  Created by Antonino Ficarra on 15/03/22.
//

import Foundation
import simd

//****************************************************
// integer format

enum IntegerFormatCode {
	case d,u,x,X,o
	var code : String {
		switch self {
		case .d: return "d"
		case .u: return "u"
		case .x: return "x"
		case .X: return "X"
		case .o: return "o"
		}
	}
}

extension BinaryInteger {
	func format( _ f:String, _ code:IntegerFormatCode ) -> String {
		return String(format: "%\(f)l\(code.code)", Int64(self) )
	}
}

extension SignedInteger {
	func format( _ f:String ) -> String { format( f, .d ) }
	func format( _ code:IntegerFormatCode = .d ) -> String { format( "", code ) }
}

extension UnsignedInteger {
	func format( _ f:String ) -> String { format( f, .u ) }
	func format( _ code:IntegerFormatCode = .u ) -> String { format( "", code ) }
}

extension ObjectIdentifier {
	func format( _ f:String = "" ) -> String { UInt(bitPattern: self).format( f, .X ) }
}

//****************************************************
// floating point format

enum FloatingPointFormatCode {
	case f,e,E,g,G
	
	var code : String {
		switch self {
		case .f: return "f"
		case .e: return "e"
		case .E: return "E"
		case .g: return "g"
		case .G: return "G"
		}
	}
}

extension BinaryFloatingPoint {
	func format( _ f:String, _ code:FloatingPointFormatCode = .f ) -> String {
		return String(format: "%\(f)l\(code.code)", Double(self) )
	}
}

//****************************************************
// simd vector format

extension SIMD where Self.Scalar : BinaryFloatingPoint {
	func format( _ f:String, _ code:FloatingPointFormatCode = .f ) -> String {
		var string = ""
		for i in indices {
			if i > indices.lowerBound {
				string.append( " " )
			}
			string.append( self[i].format(f,code) )
		}
		return string
	}
}

extension SIMD where Self.Scalar : BinaryInteger {
	func format( _ f:String, _ code:IntegerFormatCode ) -> String {
		var string = ""
		for i in indices {
			if i > indices.lowerBound {
				string.append( " " )
			}
			string.append( self[i].format(f,code) )
		}
		return string
	}
}

extension SIMD where Self.Scalar : SignedInteger {
	func format( _ f:String ) -> String { format( f, .d ) }
}

extension SIMD where Self.Scalar : UnsignedInteger {
	func format( _ f:String ) -> String { format( f, .u ) }
}
 
//****************************************************
// simd matrix format

protocol SIMDMatrixDimension {
	static var cols : Int { get }
	static var rows : Int { get }
}

protocol SIMDMatrixFloatingPointFormat : SIMDMatrixDimension {
	associatedtype	Scalar : BinaryFloatingPoint

	subscript(column: Int, row: Int) -> Scalar { get }
	func format( _ f:String, _ code:FloatingPointFormatCode ) -> String
}

extension SIMDMatrixFloatingPointFormat {
	func format( _ f:String, _ code:FloatingPointFormatCode = .f ) -> String {
		var string = ""
		for r in 0..<Self.rows {
			for c in 0..<Self.cols {
				if c > 0 {
					string.append( " " )
				}
				string.append( self[c,r].format(f,code) )
			}
			string.append( "\n" )
		}
		return string
	}
}

//****************************************************
// float simd matrix support

extension simd_float2x2 : SIMDMatrixFloatingPointFormat {
	static var cols: Int { 2 }
	static var rows: Int { 2 }
}

extension simd_float2x3 : SIMDMatrixFloatingPointFormat {
	static var cols: Int { 2 }
	static var rows: Int { 3 }
}

extension simd_float2x4 : SIMDMatrixFloatingPointFormat {
	static var cols: Int { 2 }
	static var rows: Int { 4 }
}

extension simd_float3x2 : SIMDMatrixFloatingPointFormat {
	static var cols: Int { 3 }
	static var rows: Int { 2 }
}

extension simd_float3x3 : SIMDMatrixFloatingPointFormat {
	static var cols: Int { 3 }
	static var rows: Int { 3 }
}

extension simd_float3x4 : SIMDMatrixFloatingPointFormat {
	static var cols: Int { 3 }
	static var rows: Int { 4 }
}

extension simd_float4x2 : SIMDMatrixFloatingPointFormat {
	static var cols: Int { 4 }
	static var rows: Int { 2 }
}

extension simd_float4x3 : SIMDMatrixFloatingPointFormat {
	static var cols: Int { 4 }
	static var rows: Int { 3 }
}

extension simd_float4x4 : SIMDMatrixFloatingPointFormat {
	static var cols: Int { 4 }
	static var rows: Int { 4 }
}

//****************************************************
// double simd matrix support

extension simd_double2x2 : SIMDMatrixFloatingPointFormat {
	static var cols: Int { 2 }
	static var rows: Int { 2 }
}

extension simd_double2x3 : SIMDMatrixFloatingPointFormat {
	static var cols: Int { 2 }
	static var rows: Int { 3 }
}

extension simd_double2x4 : SIMDMatrixFloatingPointFormat {
	static var cols: Int { 2 }
	static var rows: Int { 4 }
}

extension simd_double3x2 : SIMDMatrixFloatingPointFormat {
	static var cols: Int { 3 }
	static var rows: Int { 2 }
}

extension simd_double3x3 : SIMDMatrixFloatingPointFormat {
	static var cols: Int { 3 }
	static var rows: Int { 3 }
}

extension simd_double3x4 : SIMDMatrixFloatingPointFormat {
	static var cols: Int { 3 }
	static var rows: Int { 4 }
}

extension simd_double4x2 : SIMDMatrixFloatingPointFormat {
	static var cols: Int { 4 }
	static var rows: Int { 2 }
}

extension simd_double4x3 : SIMDMatrixFloatingPointFormat {
	static var cols: Int { 4 }
	static var rows: Int { 3 }
}

extension simd_double4x4 : SIMDMatrixFloatingPointFormat {
	static var cols: Int { 4 }
	static var rows: Int { 4 }
}
