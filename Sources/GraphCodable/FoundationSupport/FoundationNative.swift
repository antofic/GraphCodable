//
//  File.swift
//  
//
//  Created by Antonino Ficarra on 06/05/21.
//

import Foundation


// -- CGFloat (NativeIOType) --------------------------------------------
//	Su alcune piattaforme CGFloat == Float (32 bit).
//	Salviamo sempre come Double 64bit

extension CGFloat : NativeIOType {
	init(from reader: inout BinaryReader) throws {
		self.init( try Double( from: &reader ) )
	}

	func write(to writer: inout BinaryWriter) throws {
		try Double( self ).write(to: &writer)
	}
}

//	CharacterSet SUPPORT ------------------------------------------------------

extension CharacterSet : NativeIOType {
	init(from reader: inout BinaryReader) throws {
		self.init( bitmapRepresentation: try Data( from: &reader) )
	}
	
	func write(to writer: inout BinaryWriter) throws {
		try self.bitmapRepresentation.write(to: &writer)
	}
}

//	AffineTransform SUPPORT ------------------------------------------------------

extension AffineTransform : NativeIOType {
	// m11: CGFloat, m12: CGFloat, m21: CGFloat, m22: CGFloat, tX: CGFloat, tY: CGFloat
	
	func write(to writer: inout BinaryWriter) throws {
		try m11.write(to: &writer)
		try m12.write(to: &writer)
		try m21.write(to: &writer)
		try m22.write(to: &writer)
		try tX.write(to: &writer)
		try tY.write(to: &writer)
	}
	
	init(from reader: inout BinaryReader) throws {
		let m11	= try CGFloat( from: &reader )
		let m12	= try CGFloat( from: &reader )
		let m21	= try CGFloat( from: &reader )
		let m22	= try CGFloat( from: &reader )
		let tX	= try CGFloat( from: &reader )
		let tY	= try CGFloat( from: &reader )
		self.init(m11: m11, m12: m12, m21: m21, m22: m22, tX: tX, tY: tY)
	}
}

//	Locale SUPPORT ------------------------------------------------------

extension Locale : NativeIOType {
	func write( to writer: inout BinaryWriter ) throws {
		try self.identifier.write(to: &writer)
	}

	init( from reader: inout BinaryReader ) throws {
		self.init( identifier: try String( from: &reader) )
	}
}

//	TimeZone SUPPORT ------------------------------------------------------

extension TimeZone : NativeIOType {
	func write( to writer: inout BinaryWriter ) throws {
		try self.identifier.write(to: &writer)
	}

	init( from reader: inout BinaryReader ) throws {
		let identifier = try String( from: &reader)
		guard let timeZone = TimeZone( identifier: identifier ) else {
			throw GCodableError.initGCodableError(
				Self.self, GCodableError.Context(
					debugDescription: "Invalid timezone identifier -\(identifier)-"
				)
			)
		}
		self = timeZone
	}
}

// -- UUID support  -------------------------------------------------------

extension UUID : NativeIOType  {
	func write(to writer: inout BinaryWriter) throws {
		try uuidString.write(to: &writer)
	}
	
	init( from reader: inout BinaryReader ) throws {
		let uuidString	= try String( from: &reader)
		
		guard let uuid = UUID(uuidString: uuidString) else {
			throw GCodableError.initGCodableError(
				Self.self, GCodableError.Context(
					debugDescription: "Attempted to decode UUID from invalid UUID string -\(uuidString)-."
				)
			)
		}
		self = uuid
	}
}

//	Date SUPPORT ------------------------------------------------------

extension Date : NativeIOType {
	func write( to writer: inout BinaryWriter ) throws {
		try self.timeIntervalSince1970.write(to: &writer)
	}
	init( from reader: inout BinaryReader ) throws {
		self.init( timeIntervalSince1970: try TimeInterval( from: &reader) )
	}
}



//	IndexSet SUPPORT ------------------------------------------------------

extension IndexSet : NativeIOType {
	init(from reader: inout BinaryReader) throws {
		self.init()
		let count	= try Int( from: &reader )
		for _ in 0..<count {
			self.insert(integersIn: try Range(from: &reader) )
		}
	}
	
	func write(to writer: inout BinaryWriter) throws {
		try rangeView.count.write(to: &writer)
		for range in rangeView {
			try range.write(to: &writer)
		}
	}
}

// -- IndexPath support  -------------------------------------------------------
/* inaccessible underlying storage
extension IndexPath : NativeIOType {
}
*/



//	CGSize SUPPORT ------------------------------------------------------

extension CGSize : NativeIOType {
	func write(to writer: inout BinaryWriter) throws {
		try width.write(to: &writer)
		try height.write(to: &writer)
	}

	init(from reader: inout BinaryReader) throws {
		let width	= try CGFloat( from: &reader )
		let height	= try CGFloat( from: &reader )
		self.init(width: width, height: height)
	}
}

//	CGPoint SUPPORT ------------------------------------------------------

extension CGPoint : NativeIOType {
	func write(to writer: inout BinaryWriter) throws {
		try x.write(to: &writer)
		try y.write(to: &writer)
	}

	init(from reader: inout BinaryReader) throws {
		let x	= try CGFloat( from: &reader )
		let y	= try CGFloat( from: &reader )
		self.init(x: x, y: y)
	}
}

//	CGVector SUPPORT ------------------------------------------------------

extension CGVector : NativeIOType {
	func write(to writer: inout BinaryWriter) throws {
		try dx.write(to: &writer)
		try dy.write(to: &writer)
	}
	init(from reader: inout BinaryReader) throws {
		let dx	= try CGFloat( from: &reader )
		let dy	= try CGFloat( from: &reader )
		self.init(dx: dx, dy: dy)
	}
}

//	CGRect SUPPORT ------------------------------------------------------

extension CGRect : NativeIOType {
	func write(to writer: inout BinaryWriter) throws {
		try origin.write(to: &writer)
		try size.write(to: &writer)
	}
	init(from reader: inout BinaryReader) throws {
		let origin	= try CGPoint( from: &reader )
		let size	= try CGSize( from: &reader )
		self.init(origin: origin, size: size)
	}
}

//	NSRange SUPPORT ------------------------------------------------------

extension NSRange : NativeIOType {
	func write(to writer: inout BinaryWriter) throws {
		try location.write(to: &writer)
		try length.write(to: &writer)
	}
	init(from reader: inout BinaryReader) throws {
		let location	= try Int( from: &reader )
		let length		= try Int( from: &reader )
		self.init(location: location, length: length)
	}
}

// -- Decimal support  -------------------------------------------------------

extension Decimal : NativeIOType {
	func write( to writer: inout BinaryWriter ) throws {
		try _exponent.write(to: &writer)
		try _length.write(to: &writer)
		try (_isNegative == 0 ? false : true).write(to: &writer)
		try (_isCompact == 0 ? false : true).write(to: &writer)
		try _mantissa.0.write(to: &writer)
		try _mantissa.1.write(to: &writer)
		try _mantissa.2.write(to: &writer)
		try _mantissa.3.write(to: &writer)
		try _mantissa.4.write(to: &writer)
		try _mantissa.5.write(to: &writer)
		try _mantissa.6.write(to: &writer)
		try _mantissa.7.write(to: &writer)

	}

	init( from reader: inout BinaryReader ) throws {
		let exponent	= try Int32( from:&reader )
		let length		= try UInt32( from:&reader )
		let isNegative	= (try Bool( from:&reader )) == false ? UInt32(0) : UInt32(1)
		let isCompact	= (try Bool( from:&reader )) == false ? UInt32(0) : UInt32(1)
		let mantissa0	= try UInt16( from:&reader )
		let mantissa1	= try UInt16( from:&reader )
		let mantissa2	= try UInt16( from:&reader )
		let mantissa3	= try UInt16( from:&reader )
		let mantissa4	= try UInt16( from:&reader )
		let mantissa5	= try UInt16( from:&reader )
		let mantissa6	= try UInt16( from:&reader )
		let mantissa7	= try UInt16( from:&reader )

		self.init(
			_exponent: exponent, _length: length, _isNegative: isNegative, _isCompact: isCompact, _reserved: 0,
			_mantissa: (mantissa0, mantissa1, mantissa2, mantissa3, mantissa4, mantissa5, mantissa6, mantissa7)
		)
	}
}

