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

// -- CGFloat -----------------------------------------------------------
//	Su alcune piattaforme CGFloat == Float (32 bit).
//	Salviamo sempre come Double 64bit

extension CGFloat : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self.init( try Double( from: &decoder ) )
	}
}
extension CGFloat : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( Double( self ) )
	}
}

//	CharacterSet SUPPORT ------------------------------------------------------

extension CharacterSet : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self.init(bitmapRepresentation: try decoder.decode() )
	}
}
extension CharacterSet : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( bitmapRepresentation )
	}
}

//	AffineTransform SUPPORT ------------------------------------------------------
// m11: CGFloat, m12: CGFloat, m21: CGFloat, m22: CGFloat, tX: CGFloat, tY: CGFloat

extension AffineTransform : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		let m11	= try decoder.decode() as CGFloat
		let m12	= try decoder.decode() as CGFloat
		let m21	= try decoder.decode() as CGFloat
		let m22	= try decoder.decode() as CGFloat
		let tX	= try decoder.decode() as CGFloat
		let tY	= try decoder.decode() as CGFloat
		self.init(m11: m11, m12: m12, m21: m21, m22: m22, tX: tX, tY: tY)
	}
}

extension AffineTransform : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( m11 )
		try encoder.encode( m12 )
		try encoder.encode( m21 )
		try encoder.encode( m22 )
		try encoder.encode( tX )
		try encoder.encode( tY )
	}
}

//	Locale SUPPORT ------------------------------------------------------

extension Locale : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( identifier )
	}
}
extension Locale : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self.init( identifier: try decoder.decode() )
	}
}

//	TimeZone SUPPORT ------------------------------------------------------

extension TimeZone : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( identifier )
	}
}
extension TimeZone : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		let identifier = try decoder.decode() as String
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

extension UUID : BEncodable  {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( uuidString )
	}
}
extension UUID : BDecodable  {
	public init(from decoder: inout some BDecoder) throws {
		let uuidString	= try decoder.decode() as String
		
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

extension Date : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( timeIntervalSince1970 )
	}
}
extension Date : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self.init( timeIntervalSince1970: try decoder.decode() )
	}
}

//	IndexSet SUPPORT ------------------------------------------------------

extension IndexSet : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self.init()
		let count	= try decoder.decode() as Int
		for _ in 0..<count {
			self.insert(integersIn: try decoder.decode() )
		}
	}
}

extension IndexSet : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( rangeView.count )
		for range in rangeView {
			try encoder.encode( range )
		}
	}
}

// -- IndexPath support  -------------------------------------------------------

extension IndexPath : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self.init()
		let count	= try decoder.decode() as Int
		for _ in 0..<count {
			self.append( try decoder.decode() as Element )
		}
	}
}
extension IndexPath : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( count )
		for element in self {
			try encoder.encode( element )
		}
	}
}

//	CGSize SUPPORT ------------------------------------------------------

extension CGSize : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( width )
		try encoder.encode( height )
	}
}
extension CGSize : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		let width	= try decoder.decode() as CGFloat
		let height	= try decoder.decode() as CGFloat
		self.init(width: width, height: height)
	}
}

//	CGPoint SUPPORT ------------------------------------------------------

extension CGPoint : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( x )
		try encoder.encode( y )
	}
}
extension CGPoint : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		let x	= try decoder.decode() as CGFloat
		let y	= try decoder.decode() as CGFloat
		self.init(x: x, y: y)
	}
}

//	CGVector SUPPORT ------------------------------------------------------

extension CGVector : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( dx )
		try encoder.encode( dy )
	}
}
extension CGVector : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		let dx	= try decoder.decode() as CGFloat
		let dy	= try decoder.decode() as CGFloat
		self.init(dx: dx, dy: dy)
	}
}

//	CGRect SUPPORT ------------------------------------------------------

extension CGRect : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( origin )
		try encoder.encode( size )
	}
}
extension CGRect : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		let origin	= try decoder.decode() as CGPoint
		let size	= try decoder.decode() as CGSize
		self.init(origin: origin, size: size)
	}
}

//	NSRange SUPPORT ------------------------------------------------------

extension NSRange : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( location )
		try encoder.encode( length )
	}
}
extension NSRange : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		let location	= try decoder.decode() as Int
		let length		= try decoder.decode() as Int
		self.init(location: location, length: length)
	}
}

// -- Decimal support  -------------------------------------------------------

extension Decimal : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( _exponent )
		try encoder.encode( _length )
		try encoder.encode( _isNegative == 0 ? false : true )
		try encoder.encode( _isCompact == 0 ? false : true )
		try encoder.encode( _mantissa.0 )
		try encoder.encode( _mantissa.1 )
		try encoder.encode( _mantissa.2 )
		try encoder.encode( _mantissa.3 )
		try encoder.encode( _mantissa.4 )
		try encoder.encode( _mantissa.5 )
		try encoder.encode( _mantissa.6 )
		try encoder.encode( _mantissa.7 )
	}
}


extension Decimal : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		let exponent	= try decoder.decode() as Int32
		let length		= try decoder.decode() as UInt32
		let isNegative	= (try decoder.decode() as Bool) == false ? UInt32(0) : UInt32(1)
		let isCompact	= (try decoder.decode() as Bool) == false ? UInt32(0) : UInt32(1)
		let mantissa0	= try decoder.decode() as UInt16
		let mantissa1	= try decoder.decode() as UInt16
		let mantissa2	= try decoder.decode() as UInt16
		let mantissa3	= try decoder.decode() as UInt16
		let mantissa4	= try decoder.decode() as UInt16
		let mantissa5	= try decoder.decode() as UInt16
		let mantissa6	= try decoder.decode() as UInt16
		let mantissa7	= try decoder.decode() as UInt16
		
		self.init(
			_exponent: exponent, _length: length, _isNegative: isNegative, _isCompact: isCompact, _reserved: 0,
			_mantissa: (mantissa0, mantissa1, mantissa2, mantissa3, mantissa4, mantissa5, mantissa6, mantissa7)
		)
		
	}
}

//	Calendar SUPPORT ------------------------------------------------------

extension NSCalendar.Identifier : BDecodable {}
extension NSCalendar.Identifier : BEncodable {}

extension Calendar : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		let nsIdentifier = (self as NSCalendar).calendarIdentifier
		try encoder.encode( nsIdentifier )
		try encoder.encode( locale )
		try encoder.encode( timeZone )
		try encoder.encode( firstWeekday )
		try encoder.encode( minimumDaysInFirstWeek )
	}
}

extension Calendar : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		let nsIdentifier = try decoder.decode() as NSCalendar.Identifier
		guard var calendar = NSCalendar(calendarIdentifier: nsIdentifier) as Calendar? else {
			throw BinaryIOError.libDecodingError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Invalid calendar identifier -\(nsIdentifier)-"
				)
			)
		}
		calendar.locale					= try decoder.decode()
		calendar.timeZone				= try decoder.decode()
		calendar.firstWeekday			= try decoder.decode()
		calendar.minimumDaysInFirstWeek	= try decoder.decode()
		
		self = calendar
	}
}


//	DateComponents SUPPORT ------------------------------------------------------

extension DateComponents : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( calendar   		 )
		try encoder.encode( timeZone   		 )
		try encoder.encode( era        		 )
		try encoder.encode( year       		 )
		try encoder.encode( month      		 )
		try encoder.encode( day        		 )
		try encoder.encode( hour       		 )
		try encoder.encode( minute     		 )
		try encoder.encode( second     		 )
		try encoder.encode( nanosecond 		 )
		try encoder.encode( weekday           )
		try encoder.encode( weekdayOrdinal    )
		try encoder.encode( quarter           )
		try encoder.encode( weekOfMonth       )
		try encoder.encode( weekOfYear        )
		try encoder.encode( yearForWeekOfYear )
	}
}

extension DateComponents : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		let calendar   			= try decoder.decode() as Calendar?
		let timeZone   			= try decoder.decode() as TimeZone?
		let era        			= try decoder.decode() as Int?
		let year       			= try decoder.decode() as Int?
		let month      			= try decoder.decode() as Int?
		let day        			= try decoder.decode() as Int?
		let hour       			= try decoder.decode() as Int?
		let minute     			= try decoder.decode() as Int?
		let second     			= try decoder.decode() as Int?
		let nanosecond 			= try decoder.decode() as Int?
		let weekday          	= try decoder.decode() as Int?
		let weekdayOrdinal   	= try decoder.decode() as Int?
		let quarter          	= try decoder.decode() as Int?
		let weekOfMonth      	= try decoder.decode() as Int?
		let weekOfYear       	= try decoder.decode() as Int?
		let yearForWeekOfYear	= try decoder.decode() as Int?
		
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

extension DateInterval : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( start )
		try encoder.encode( duration )
	}
}
extension DateInterval : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		let start 		= try decoder.decode() as Date
		let duration 	= try decoder.decode() as TimeInterval
		self.init(start: start, duration: duration)
	}
}


//	PersonNameComponents SUPPORT ------------------------------------------------------

extension PersonNameComponents : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( namePrefix )
		try encoder.encode( givenName )
		try encoder.encode( middleName )
		try encoder.encode( familyName )
		try encoder.encode( nameSuffix )
		try encoder.encode( nickname )
	}
}
extension PersonNameComponents : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self.init()
		
		namePrefix	= try decoder.decode()
		givenName	= try decoder.decode()
		middleName	= try decoder.decode()
		familyName	= try decoder.decode()
		nameSuffix	= try decoder.decode()
		nickname	= try decoder.decode()
	}
}

//	URL SUPPORT ------------------------------------------------------

extension URL : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( relativeString )
		try encoder.encode( baseURL )
	}
}
extension URL : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		let relative	= try decoder.decode() as String
		let base		= try decoder.decode() as URL?
		
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

extension URLComponents : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( scheme	 )
		try encoder.encode( user	 )
		try encoder.encode( password )
		try encoder.encode( host	 )
		try encoder.encode( port	 )
		try encoder.encode( path	 )
		try encoder.encode( query	 )
		try encoder.encode( fragment )
	}
}
extension URLComponents : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self.init()
		
		scheme		= try decoder.decode()
		user		= try decoder.decode()
		password	= try decoder.decode()
		host		= try decoder.decode()
		port		= try decoder.decode()
		path		= try decoder.decode()
		query		= try decoder.decode()
		fragment	= try decoder.decode()
	}
}

//	Measurement SUPPORT ------------------------------------------------------

extension Measurement : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( value )
		try encoder.encode( unit.symbol )
	}
}
extension Measurement : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		let value	= try decoder.decode() as Double
		let symbol	= try decoder.decode() as String
		self.init( value: value, unit: UnitType(symbol: symbol) )
	}
}


extension OperationQueue.SchedulerTimeType : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( date )
	}
}
extension OperationQueue.SchedulerTimeType : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self.init( try decoder.decode() )
	}
}

extension OperationQueue.SchedulerTimeType.Stride : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( timeInterval )
	}
}
extension OperationQueue.SchedulerTimeType.Stride : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self.init( try decoder.decode() )
	}
}

extension RunLoop.SchedulerTimeType : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( date )
	}
}
extension RunLoop.SchedulerTimeType : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self.init( try decoder.decode() )
	}
}

extension RunLoop.SchedulerTimeType.Stride : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( timeInterval )
	}
}
extension RunLoop.SchedulerTimeType.Stride : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self.init( try decoder.decode() )
	}
}


