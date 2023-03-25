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

import Foundation



// -- Data support (BinaryIOType) -------------------------------------------------------

extension Data : BinaryOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try wbuffer.writeData( self )
	}
}
extension Data : BinaryIType {
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		self = try rbuffer.readData()
	}
}

// -- CGFloat (BinaryIOType) --------------------------------------------
//	Su alcune piattaforme CGFloat == Float (32 bit).
//	Salviamo sempre come Double 64bit

extension CGFloat : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		self.init( try Double( from: &rbuffer ) )
	}
}
extension CGFloat : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try Double( self ).write(to: &wbuffer)
	}
}

//	CharacterSet SUPPORT ------------------------------------------------------

extension CharacterSet : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		self.init( bitmapRepresentation: try Data( from: &rbuffer) )
	}
}
extension CharacterSet : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try self.bitmapRepresentation.write(to: &wbuffer)
	}
}

//	AffineTransform SUPPORT ------------------------------------------------------
// m11: CGFloat, m12: CGFloat, m21: CGFloat, m22: CGFloat, tX: CGFloat, tY: CGFloat

extension AffineTransform : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try m11.write(to: &wbuffer)
		try m12.write(to: &wbuffer)
		try m21.write(to: &wbuffer)
		try m22.write(to: &wbuffer)
		try tX.write(to: &wbuffer)
		try tY.write(to: &wbuffer)
	}
}
extension AffineTransform : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		let m11	= try CGFloat( from: &rbuffer )
		let m12	= try CGFloat( from: &rbuffer )
		let m21	= try CGFloat( from: &rbuffer )
		let m22	= try CGFloat( from: &rbuffer )
		let tX	= try CGFloat( from: &rbuffer )
		let tY	= try CGFloat( from: &rbuffer )
		self.init(m11: m11, m12: m12, m21: m21, m22: m22, tX: tX, tY: tY)
	}
}

//	Locale SUPPORT ------------------------------------------------------

extension Locale : BinaryOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try self.identifier.write(to: &wbuffer)
	}
}
extension Locale : BinaryIType {
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		self.init( identifier: try String( from: &rbuffer) )
	}
}

//	TimeZone SUPPORT ------------------------------------------------------

extension TimeZone : BinaryOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try self.identifier.write(to: &wbuffer)
	}
}
extension TimeZone : BinaryIType {
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		let identifier = try String( from: &rbuffer)
		guard let timeZone = TimeZone( identifier: identifier ) else {
			throw BinaryIOError.libDecodingError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Invalid timezone identifier -\(identifier)-"
				)
			)
		}
		self = timeZone
	}
}

// -- UUID support  -------------------------------------------------------

extension UUID : BinaryOType  {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try uuidString.write(to: &wbuffer)
	}
}
extension UUID : BinaryIType  {
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		let uuidString	= try String( from: &rbuffer)
		
		guard let uuid = UUID(uuidString: uuidString) else {
			throw BinaryIOError.libDecodingError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Attempted to decode UUID from invalid UUID string -\(uuidString)-."
				)
			)
		}
		self = uuid
	}
}

//	Date SUPPORT ------------------------------------------------------

extension Date : BinaryOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try self.timeIntervalSince1970.write(to: &wbuffer)
	}
}
extension Date : BinaryIType {
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		self.init( timeIntervalSince1970: try TimeInterval( from: &rbuffer) )
	}
}

//	IndexSet SUPPORT ------------------------------------------------------

extension IndexSet : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		self.init()
		let count	= try Int( from: &rbuffer )
		for _ in 0..<count {
			self.insert(integersIn: try Range(from: &rbuffer) )
		}
	}
}

extension IndexSet : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try rangeView.count.write(to: &wbuffer)
		for range in rangeView {
			try range.write(to: &wbuffer)
		}
	}
}

// -- IndexPath support  -------------------------------------------------------

extension IndexPath : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		self.init()
		let count	= try Int( from: &rbuffer )
		for _ in 0..<count {
			self.append( try Int( from: &rbuffer ) )
		}
	}
}
extension IndexPath : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try count.write(to: &wbuffer)
		for element in self {
			try element.write(to: &wbuffer)
		}
		
	}
}

//	CGSize SUPPORT ------------------------------------------------------

extension CGSize : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try width.write(to: &wbuffer)
		try height.write(to: &wbuffer)
	}
}
extension CGSize : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		let width	= try CGFloat( from: &rbuffer )
		let height	= try CGFloat( from: &rbuffer )
		self.init(width: width, height: height)
	}
}

//	CGPoint SUPPORT ------------------------------------------------------

extension CGPoint : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try x.write(to: &wbuffer)
		try y.write(to: &wbuffer)
	}
}
extension CGPoint : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		let x	= try CGFloat( from: &rbuffer )
		let y	= try CGFloat( from: &rbuffer )
		self.init(x: x, y: y)
	}
}

//	CGVector SUPPORT ------------------------------------------------------

extension CGVector : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try dx.write(to: &wbuffer)
		try dy.write(to: &wbuffer)
	}
}
extension CGVector : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		let dx	= try CGFloat( from: &rbuffer )
		let dy	= try CGFloat( from: &rbuffer )
		self.init(dx: dx, dy: dy)
	}
}

//	CGRect SUPPORT ------------------------------------------------------

extension CGRect : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try origin.write(to: &wbuffer)
		try size.write(to: &wbuffer)
	}
}
extension CGRect : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		let origin	= try CGPoint( from: &rbuffer )
		let size	= try CGSize( from: &rbuffer )
		self.init(origin: origin, size: size)
	}
}

//	NSRange SUPPORT ------------------------------------------------------

extension NSRange : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try location.write(to: &wbuffer)
		try length.write(to: &wbuffer)
	}
}
extension NSRange : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		let location	= try Int( from: &rbuffer )
		let length		= try Int( from: &rbuffer )
		self.init(location: location, length: length)
	}
}

// -- Decimal support  -------------------------------------------------------

extension Decimal : BinaryOType {
	public func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		try _exponent.write(to: &wbuffer)
		try _length.write(to: &wbuffer)
		try (_isNegative == 0 ? false : true).write(to: &wbuffer)
		try (_isCompact == 0 ? false : true).write(to: &wbuffer)
		try _mantissa.0.write(to: &wbuffer)
		try _mantissa.1.write(to: &wbuffer)
		try _mantissa.2.write(to: &wbuffer)
		try _mantissa.3.write(to: &wbuffer)
		try _mantissa.4.write(to: &wbuffer)
		try _mantissa.5.write(to: &wbuffer)
		try _mantissa.6.write(to: &wbuffer)
		try _mantissa.7.write(to: &wbuffer)
	}
}
extension Decimal : BinaryIType {
	public init( from rbuffer: inout BinaryReadBuffer ) throws {
		let exponent	= try Int32( from:&rbuffer )
		let length		= try UInt32( from:&rbuffer )
		let isNegative	= (try Bool( from:&rbuffer )) == false ? UInt32(0) : UInt32(1)
		let isCompact	= (try Bool( from:&rbuffer )) == false ? UInt32(0) : UInt32(1)
		let mantissa0	= try UInt16( from:&rbuffer )
		let mantissa1	= try UInt16( from:&rbuffer )
		let mantissa2	= try UInt16( from:&rbuffer )
		let mantissa3	= try UInt16( from:&rbuffer )
		let mantissa4	= try UInt16( from:&rbuffer )
		let mantissa5	= try UInt16( from:&rbuffer )
		let mantissa6	= try UInt16( from:&rbuffer )
		let mantissa7	= try UInt16( from:&rbuffer )

		self.init(
			_exponent: exponent, _length: length, _isNegative: isNegative, _isCompact: isCompact, _reserved: 0,
			_mantissa: (mantissa0, mantissa1, mantissa2, mantissa3, mantissa4, mantissa5, mantissa6, mantissa7)
		)
	}
}

//	Calendar SUPPORT ------------------------------------------------------

extension NSCalendar.Identifier : BinaryIType {}
extension NSCalendar.Identifier : BinaryOType {}

extension Calendar : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		let nsIdentifier = (self as NSCalendar).calendarIdentifier
		try nsIdentifier.write(to: &wbuffer)
		try locale.write(to: &wbuffer)
		try timeZone.write(to: &wbuffer)
		try firstWeekday.write(to: &wbuffer)
		try minimumDaysInFirstWeek.write(to: &wbuffer)
	}
}
extension Calendar : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		let nsIdentifier = try NSCalendar.Identifier(from: &rbuffer)
		guard var calendar = NSCalendar(calendarIdentifier: nsIdentifier) as Calendar? else {
			throw BinaryIOError.libDecodingError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Invalid calendar identifier -\(nsIdentifier)-"
				)
			)
		}
		calendar.locale					= try Locale(from: &rbuffer)
		calendar.timeZone				= try TimeZone(from: &rbuffer)
		calendar.firstWeekday			= try Int(from: &rbuffer)
		calendar.minimumDaysInFirstWeek	= try Int(from: &rbuffer)
		
		self = calendar
	}
}

//	DateComponents SUPPORT ------------------------------------------------------

extension DateComponents : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try calendar   			.write(to: &wbuffer)
		try timeZone   			.write(to: &wbuffer)
		try era        			.write(to: &wbuffer)
		try year       			.write(to: &wbuffer)
		try month      			.write(to: &wbuffer)
		try day        			.write(to: &wbuffer)
		try hour       			.write(to: &wbuffer)
		try minute     			.write(to: &wbuffer)
		try second     			.write(to: &wbuffer)
		try nanosecond 			.write(to: &wbuffer)
		try weekday          	.write(to: &wbuffer)
		try weekdayOrdinal   	.write(to: &wbuffer)
		try quarter          	.write(to: &wbuffer)
		try weekOfMonth      	.write(to: &wbuffer)
		try weekOfYear       	.write(to: &wbuffer)
		try yearForWeekOfYear	.write(to: &wbuffer)
	}
}
extension DateComponents : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		let calendar   			= try Calendar?(from: &rbuffer)
		let timeZone   			= try TimeZone?(from: &rbuffer)
		let era        			= try Int?(from: &rbuffer)
		let year       			= try Int?(from: &rbuffer)
		let month      			= try Int?(from: &rbuffer)
		let day        			= try Int?(from: &rbuffer)
		let hour       			= try Int?(from: &rbuffer)
		let minute     			= try Int?(from: &rbuffer)
		let second     			= try Int?(from: &rbuffer)
		let nanosecond 			= try Int?(from: &rbuffer)
		let weekday          	= try Int?(from: &rbuffer)
		let weekdayOrdinal   	= try Int?(from: &rbuffer)
		let quarter          	= try Int?(from: &rbuffer)
		let weekOfMonth      	= try Int?(from: &rbuffer)
		let weekOfYear       	= try Int?(from: &rbuffer)
		let yearForWeekOfYear	= try Int?(from: &rbuffer)
		
		self.init(
			calendar: calendar,
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

extension DateInterval : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try start.write(to: &wbuffer)
		try duration.write(to: &wbuffer)
	}
}
extension DateInterval : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		let start 		= try Date(from: &rbuffer)
		let duration 	= try TimeInterval(from: &rbuffer)
		self.init(start: start, duration: duration)
	}
}

//	PersonNameComponents SUPPORT ------------------------------------------------------

extension PersonNameComponents : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try namePrefix	.write(to: &wbuffer)
		try givenName	.write(to: &wbuffer)
		try middleName	.write(to: &wbuffer)
		try familyName	.write(to: &wbuffer)
		try nameSuffix	.write(to: &wbuffer)
		try nickname	.write(to: &wbuffer)
	}
}
extension PersonNameComponents : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		self.init()
		
		namePrefix	= try String?(from: &rbuffer)
		givenName	= try String?(from: &rbuffer)
		middleName	= try String?(from: &rbuffer)
		familyName	= try String?(from: &rbuffer)
		nameSuffix	= try String?(from: &rbuffer)
		nickname	= try String?(from: &rbuffer)
	}
}

//	URL SUPPORT ------------------------------------------------------

extension URL : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try relativeString	.write(to: &wbuffer)
		try baseURL			.write(to: &wbuffer)
	}
}
extension URL : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		let relative	= try String(from: &rbuffer)
		let base		= try URL?(from: &rbuffer)

		guard let url = URL(string: relative, relativeTo: base) else {
			throw BinaryIOError.libDecodingError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Invalid relative -\(relative)- and base -\(base as Any)-"
				)
			)
		}
		self = url
	}
}

//	URLComponents SUPPORT ------------------------------------------------------

extension URLComponents : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try scheme		.write(to: &wbuffer)
		try user		.write(to: &wbuffer)
		try password	.write(to: &wbuffer)
		try host		.write(to: &wbuffer)
		try port		.write(to: &wbuffer)
		try path		.write(to: &wbuffer)
		try query		.write(to: &wbuffer)
		try fragment	.write(to: &wbuffer)
	}
}
extension URLComponents : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		self.init()
		
		scheme		= try String?(from: &rbuffer)
		user		= try String?(from: &rbuffer)
		password	= try String?(from: &rbuffer)
		host		= try String?(from: &rbuffer)
		port		= try Int?(from: &rbuffer)
		path		= try String(from: &rbuffer)
		query		= try String?(from: &rbuffer)
		fragment	= try String?(from: &rbuffer)
	}
}

//	Measurement SUPPORT ------------------------------------------------------

extension Measurement : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try value		.write(to: &wbuffer)
		try unit.symbol	.write(to: &wbuffer)
	}
}
extension Measurement : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		let value	= try Double(from: &rbuffer)
		let symbol	= try String(from: &rbuffer)
		self.init( value: value, unit: UnitType(symbol: symbol) )
	}
}


extension OperationQueue.SchedulerTimeType : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try date.write(to: &wbuffer)
	}
}
extension OperationQueue.SchedulerTimeType : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		self.init( try Date(from: &rbuffer) )
	}
}

extension OperationQueue.SchedulerTimeType.Stride : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try timeInterval.write(to: &wbuffer)
	}
}
extension OperationQueue.SchedulerTimeType.Stride : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		self.init( try TimeInterval(from: &rbuffer) )
	}
}

extension RunLoop.SchedulerTimeType : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try date.write(to: &wbuffer)
	}
}
extension RunLoop.SchedulerTimeType : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		self.init( try Date(from: &rbuffer) )
	}
}

extension RunLoop.SchedulerTimeType.Stride : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try timeInterval.write(to: &wbuffer)
	}
}
extension RunLoop.SchedulerTimeType.Stride : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		self.init( try TimeInterval(from: &rbuffer) )
	}
}


