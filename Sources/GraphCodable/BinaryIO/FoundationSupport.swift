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


// -- CGFloat (BinaryIOType) --------------------------------------------
//	Su alcune piattaforme CGFloat == Float (32 bit).
//	Salviamo sempre come Double 64bit

extension CGFloat : BinaryIOType {
	public init(from reader: inout BinaryReader) throws {
		self.init( try Double( from: &reader ) )
	}

	public func write(to writer: inout BinaryWriter) throws {
		try Double( self ).write(to: &writer)
	}
}

//	CharacterSet SUPPORT ------------------------------------------------------

extension CharacterSet : BinaryIOType {
	public init(from reader: inout BinaryReader) throws {
		self.init( bitmapRepresentation: try Data( from: &reader) )
	}
	
	public func write(to writer: inout BinaryWriter) throws {
		try self.bitmapRepresentation.write(to: &writer)
	}
}

//	AffineTransform SUPPORT ------------------------------------------------------

extension AffineTransform : BinaryIOType {
	// m11: CGFloat, m12: CGFloat, m21: CGFloat, m22: CGFloat, tX: CGFloat, tY: CGFloat
	
	public func write(to writer: inout BinaryWriter) throws {
		try m11.write(to: &writer)
		try m12.write(to: &writer)
		try m21.write(to: &writer)
		try m22.write(to: &writer)
		try tX.write(to: &writer)
		try tY.write(to: &writer)
	}
	
	public init(from reader: inout BinaryReader) throws {
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

extension Locale : BinaryIOType {
	public func write( to writer: inout BinaryWriter ) throws {
		try self.identifier.write(to: &writer)
	}

	public init( from reader: inout BinaryReader ) throws {
		self.init( identifier: try String( from: &reader) )
	}
}

//	TimeZone SUPPORT ------------------------------------------------------

extension TimeZone : BinaryIOType {
	public func write( to writer: inout BinaryWriter ) throws {
		try self.identifier.write(to: &writer)
	}

	public init( from reader: inout BinaryReader ) throws {
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

extension UUID : BinaryIOType  {
	public func write(to writer: inout BinaryWriter) throws {
		try uuidString.write(to: &writer)
	}
	
	public init( from reader: inout BinaryReader ) throws {
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

extension Date : BinaryIOType {
	public func write( to writer: inout BinaryWriter ) throws {
		try self.timeIntervalSince1970.write(to: &writer)
	}
	public init( from reader: inout BinaryReader ) throws {
		self.init( timeIntervalSince1970: try TimeInterval( from: &reader) )
	}
}



//	IndexSet SUPPORT ------------------------------------------------------

extension IndexSet : BinaryIOType {
	public init(from reader: inout BinaryReader) throws {
		self.init()
		let count	= try Int( from: &reader )
		for _ in 0..<count {
			self.insert(integersIn: try Range(from: &reader) )
		}
	}
	
	public func write(to writer: inout BinaryWriter) throws {
		try rangeView.count.write(to: &writer)
		for range in rangeView {
			try range.write(to: &writer)
		}
	}
}

// -- IndexPath support  -------------------------------------------------------
/* inaccessible underlying storage
extension IndexPath : BinaryIOType {
}
*/



//	CGSize SUPPORT ------------------------------------------------------

extension CGSize : BinaryIOType {
	public func write(to writer: inout BinaryWriter) throws {
		try width.write(to: &writer)
		try height.write(to: &writer)
	}

	public init(from reader: inout BinaryReader) throws {
		let width	= try CGFloat( from: &reader )
		let height	= try CGFloat( from: &reader )
		self.init(width: width, height: height)
	}
}

//	CGPoint SUPPORT ------------------------------------------------------

extension CGPoint : BinaryIOType {
	public func write(to writer: inout BinaryWriter) throws {
		try x.write(to: &writer)
		try y.write(to: &writer)
	}

	public init(from reader: inout BinaryReader) throws {
		let x	= try CGFloat( from: &reader )
		let y	= try CGFloat( from: &reader )
		self.init(x: x, y: y)
	}
}

//	CGVector SUPPORT ------------------------------------------------------

extension CGVector : BinaryIOType {
	public func write(to writer: inout BinaryWriter) throws {
		try dx.write(to: &writer)
		try dy.write(to: &writer)
	}
	public init(from reader: inout BinaryReader) throws {
		let dx	= try CGFloat( from: &reader )
		let dy	= try CGFloat( from: &reader )
		self.init(dx: dx, dy: dy)
	}
}

//	CGRect SUPPORT ------------------------------------------------------

extension CGRect : BinaryIOType {
	public func write(to writer: inout BinaryWriter) throws {
		try origin.write(to: &writer)
		try size.write(to: &writer)
	}
	public init(from reader: inout BinaryReader) throws {
		let origin	= try CGPoint( from: &reader )
		let size	= try CGSize( from: &reader )
		self.init(origin: origin, size: size)
	}
}

//	NSRange SUPPORT ------------------------------------------------------

extension NSRange : BinaryIOType {
	public func write(to writer: inout BinaryWriter) throws {
		try location.write(to: &writer)
		try length.write(to: &writer)
	}
	public init(from reader: inout BinaryReader) throws {
		let location	= try Int( from: &reader )
		let length		= try Int( from: &reader )
		self.init(location: location, length: length)
	}
}

// -- Decimal support  -------------------------------------------------------

extension Decimal : BinaryIOType {
	public func write( to writer: inout BinaryWriter ) throws {
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

	public init( from reader: inout BinaryReader ) throws {
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

//	Calendar SUPPORT ------------------------------------------------------

extension NSCalendar.Identifier : BinaryIOType {}

extension Calendar : BinaryIOType {
	public func write(to writer: inout BinaryWriter) throws {
		let nsIdentifier = (self as NSCalendar).calendarIdentifier
		
		try nsIdentifier.write(to: &writer)
		try locale.write(to: &writer)
		try timeZone.write(to: &writer)
		try firstWeekday.write(to: &writer)
		try minimumDaysInFirstWeek.write(to: &writer)
	}
	
	public init(from reader: inout BinaryReader) throws {
		let nsIdentifier = try NSCalendar.Identifier(from: &reader)
		guard var calendar = NSCalendar(calendarIdentifier: nsIdentifier) as Calendar? else {
			throw GCodableError.initGCodableError(
				Self.self, GCodableError.Context(
					debugDescription: "Invalid calendar identifier -\(nsIdentifier)-"
				)
			)
		}
		calendar.locale					= try Locale(from: &reader)
		calendar.timeZone				= try TimeZone(from: &reader)
		calendar.firstWeekday			= try Int(from: &reader)
		calendar.minimumDaysInFirstWeek	= try Int(from: &reader)
		
		self = calendar
	}
}

//	DateComponents SUPPORT ------------------------------------------------------

extension DateComponents : BinaryIOType {
	public func write(to writer: inout BinaryWriter) throws {
		try calendar   			.write(to: &writer)
		try timeZone   			.write(to: &writer)
		try era        			.write(to: &writer)
		try year       			.write(to: &writer)
		try month      			.write(to: &writer)
		try day        			.write(to: &writer)
		try hour       			.write(to: &writer)
		try minute     			.write(to: &writer)
		try second     			.write(to: &writer)
		try nanosecond 			.write(to: &writer)
		try weekday          	.write(to: &writer)
		try weekdayOrdinal   	.write(to: &writer)
		try quarter          	.write(to: &writer)
		try weekOfMonth      	.write(to: &writer)
		try weekOfYear       	.write(to: &writer)
		try yearForWeekOfYear	.write(to: &writer)
	}

	public init(from reader: inout BinaryReader) throws {
		let calendar   			= try Calendar?(from: &reader)
		let timeZone   			= try TimeZone?(from: &reader)
		let era        			= try Int?(from: &reader)
		let year       			= try Int?(from: &reader)
		let month      			= try Int?(from: &reader)
		let day        			= try Int?(from: &reader)
		let hour       			= try Int?(from: &reader)
		let minute     			= try Int?(from: &reader)
		let second     			= try Int?(from: &reader)
		let nanosecond 			= try Int?(from: &reader)
		let weekday          	= try Int?(from: &reader)
		let weekdayOrdinal   	= try Int?(from: &reader)
		let quarter          	= try Int?(from: &reader)
		let weekOfMonth      	= try Int?(from: &reader)
		let weekOfYear       	= try Int?(from: &reader)
		let yearForWeekOfYear	= try Int?(from: &reader)
	
		self.init(calendar: calendar,
				  timeZone: timeZone,
				  era: era,
				  year: year,
				  month: month,
				  day: day,
				  hour: hour,
				  minute: minute,
				  second: second,
				  nanosecond: nanosecond,
				  weekday: weekday,
				  weekdayOrdinal: weekdayOrdinal,
				  quarter: quarter,
				  weekOfMonth: weekOfMonth,
				  weekOfYear: weekOfYear,
				  yearForWeekOfYear: yearForWeekOfYear
		)

	}
}

//	DateInterval SUPPORT ------------------------------------------------------

@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
extension DateInterval : BinaryIOType {
	public func write(to writer: inout BinaryWriter) throws {
		try start.write(to: &writer)
		try duration.write(to: &writer)
	}
	
	public init(from reader: inout BinaryReader) throws {
		let start 		= try Date(from: &reader)
		let duration 	= try TimeInterval(from: &reader)
		self.init(start: start, duration: duration)
	}
}

//	PersonNameComponents SUPPORT ------------------------------------------------------

@available(macOS 10.11, iOS 9.0, watchOS 2.0, tvOS 9.0, *)
extension PersonNameComponents : BinaryIOType {
	public func write(to writer: inout BinaryWriter) throws {
		try namePrefix	.write(to: &writer)
		try givenName	.write(to: &writer)
		try middleName	.write(to: &writer)
		try familyName	.write(to: &writer)
		try nameSuffix	.write(to: &writer)
		try nickname	.write(to: &writer)
	}
	
	public init(from reader: inout BinaryReader) throws {
		self.init()
		
		namePrefix	= try String?(from: &reader)
		givenName	= try String?(from: &reader)
		middleName	= try String?(from: &reader)
		familyName	= try String?(from: &reader)
		nameSuffix	= try String?(from: &reader)
		nickname	= try String?(from: &reader)
	}
}

//	URL SUPPORT ------------------------------------------------------

extension URL : BinaryIOType {
	public func write(to writer: inout BinaryWriter) throws {
		try relativeString	.write(to: &writer)
		try baseURL			.write(to: &writer)
	}
	
	public init(from reader: inout BinaryReader) throws {
		let relative	= try String(from: &reader)
		let base		= try URL?(from: &reader)

		guard let url = URL(string: relative, relativeTo: base) else {
			throw GCodableError.initGCodableError(
				Self.self, GCodableError.Context(
					debugDescription: "Invalid relative -\(relative)- and base -\(base as Any)-"
				)
			)
		}
		self = url
	}
}

//	URLComponents SUPPORT ------------------------------------------------------

extension URLComponents : BinaryIOType {
	public func write(to writer: inout BinaryWriter) throws {
		try scheme		.write(to: &writer)
		try user		.write(to: &writer)
		try password	.write(to: &writer)
		try host		.write(to: &writer)
		try port		.write(to: &writer)
		try path		.write(to: &writer)
		try query		.write(to: &writer)
		try fragment	.write(to: &writer)
	}
	
	public init(from reader: inout BinaryReader) throws {
		self.init()
		
		scheme		= try String?(from: &reader)
		user		= try String?(from: &reader)
		password	= try String?(from: &reader)
		host		= try String?(from: &reader)
		port		= try Int?(from: &reader)
		path		= try String(from: &reader)
		query		= try String?(from: &reader)
		fragment	= try String?(from: &reader)
	}
}

