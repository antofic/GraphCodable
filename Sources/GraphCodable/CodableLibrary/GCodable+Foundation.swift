//
//  File.swift
//  
//
//  Created by Antonino Ficarra on 08/05/21.
//

import Foundation

//	CharacterSet SUPPORT ------------------------------------------------------

extension CharacterSet : GCodable {
	public init(from decoder: GDecoder) throws {
		self.init( bitmapRepresentation: try decoder.decode() )
	}

	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( bitmapRepresentation )
	}
}

//	AffineTransform SUPPORT ------------------------------------------------------

extension AffineTransform : GCodable {
	public init(from decoder: GDecoder) throws {
		let m11	= try decoder.decode() as CGFloat
		let m12	= try decoder.decode() as CGFloat
		let m21	= try decoder.decode() as CGFloat
		let m22	= try decoder.decode() as CGFloat
		let tX	= try decoder.decode() as CGFloat
		let tY	= try decoder.decode() as CGFloat
		self.init(m11: m11, m12: m12, m21: m21, m22: m22, tX: tX, tY: tY)
	}
	
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( m11 )
		try encoder.encode( m12 )
		try encoder.encode( m21 )
		try encoder.encode( m22 )
		try encoder.encode( tX )
		try encoder.encode( tY )
	}
}

//	Locale SUPPORT ------------------------------------------------------

extension Locale : GCodable {
	public init(from decoder: GDecoder) throws {
		self.init( identifier: try decoder.decode() )
	}
	
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( identifier )
	}
}

//	TimeZone SUPPORT ------------------------------------------------------

extension TimeZone : GCodable {
	public init(from decoder: GDecoder) throws {
		let identifier = try decoder.decode() as String
		guard let timeZone = TimeZone( identifier: identifier ) else {
			throw GCodableError.initTypeError(
				Self.self, GCodableError.Context(
					debugDescription: "Invalid timezone identifier -\(identifier)-"
				)
			)
		}
		self = timeZone
	}
	
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( identifier )
	}
}

// -- UUID support  -------------------------------------------------------

extension UUID : GCodable  {
	public init(from decoder: GDecoder) throws {
		let uuidString	= try decoder.decode() as String
		
		guard let uuid = UUID(uuidString: uuidString) else {
			throw GCodableError.initTypeError(
				Self.self, GCodableError.Context(
					debugDescription: "Attempted to decode UUID from invalid UUID string -\(uuidString)-."
				)
			)
		}
		self = uuid
	}
	
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( uuidString )
	}
	
}

//	Date SUPPORT ------------------------------------------------------

extension Date : GCodable {
	public init(from decoder: GDecoder) throws {
		self.init( timeIntervalSince1970: try decoder.decode() )
	}
	
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( timeIntervalSince1970 )
	}
	
}

//	IndexSet SUPPORT ------------------------------------------------------

extension IndexSet : GCodable {
	public init(from decoder: GDecoder) throws {
		self.init()
		while decoder.unkeyedCount > 0 {
			self.insert(integersIn: try decoder.decode() )
		}
	}
	
	public func encode(to encoder: GEncoder) throws {
		for range in rangeView {
			try encoder.encode( range )
		}
	}
}

// -- IndexPath support  -------------------------------------------------------

extension IndexPath : GCodable {
	public init(from decoder: GDecoder) throws {
		self.init()
		while decoder.unkeyedCount > 0 {
			self.append( try decoder.decode() as Element )
		}
	}
	
	public func encode(to encoder: GEncoder) throws {
		for element in self {
			try encoder.encode( element )
		}
	}
}

//	CGSize SUPPORT ------------------------------------------------------

extension CGSize : GCodable {
	private enum Key:String {
		case width, height
	}
	
	public init(from decoder: GDecoder) throws {
		let width	= try decoder.decode(for: Key.width) as CGFloat
		let height	= try decoder.decode(for: Key.height) as CGFloat
		self.init(width: width, height: height)
	}
	
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( width,for: Key.width )
		try encoder.encode( height,for: Key.height )
	}
}

//	CGPoint SUPPORT ------------------------------------------------------

extension CGPoint : GCodable {
	private enum Key:String {
		case x, y
	}

	public init(from decoder: GDecoder) throws {
		let x	= try decoder.decode(for: Key.x) as CGFloat
		let y	= try decoder.decode(for: Key.y) as CGFloat
		self.init(x: x, y: y)
	}
	
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( x,for: Key.x )
		try encoder.encode( y,for: Key.y )
	}
}

//	CGVector SUPPORT ------------------------------------------------------

extension CGVector : GCodable {
	private enum Key:String {
		case dx, dy
	}

	public init(from decoder: GDecoder) throws {
		let dx	= try decoder.decode(for: Key.dx) as CGFloat
		let dy	= try decoder.decode(for: Key.dy) as CGFloat
		self.init(dx: dx, dy: dy)
	}
	
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( dx,for: Key.dx )
		try encoder.encode( dy,for: Key.dy )
	}
}

//	CGRect SUPPORT ------------------------------------------------------

extension CGRect : GCodable {
	private enum Key:String {
		case origin, size
	}

	public init(from decoder: GDecoder) throws {
		let origin	= try decoder.decode(for: Key.origin) as CGPoint
		let size	= try decoder.decode(for: Key.size) as CGSize
		self.init(origin: origin, size: size)
	}

	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( origin,for: Key.origin )
		try encoder.encode( size,for: Key.size )
	}
}

//	NSRange SUPPORT ------------------------------------------------------

extension NSRange : GCodable {
	private enum Key:String {
		case location, length
	}

	public init(from decoder: GDecoder) throws {
		let location	= try decoder.decode(for: Key.location) as Int
		let length		= try decoder.decode(for: Key.length) as Int
		self.init(location: location, length: length)
	}

	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( location,for: Key.location )
		try encoder.encode( length,for: Key.length )
	}
}

// -- Decimal support  -------------------------------------------------------

extension Decimal : GCodable {
	private enum Key:String {
		case _exponent, _length, _isNegative, _isCompact
	}

	public init(from decoder: GDecoder) throws {
		let exponent	= try decoder.decode(for: Key._exponent) as Int32
		let length		= try decoder.decode(for: Key._length) as UInt32
		let isNegative	= (try decoder.decode(for: Key._isNegative) as Bool) == false ? UInt32(0) : UInt32(1)
		let isCompact	= (try decoder.decode(for: Key._isCompact) as Bool) == false ? UInt32(0) : UInt32(1)
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
	
	
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( _exponent,for: Key._exponent )
		try encoder.encode( _length,for: Key._length )
		try encoder.encode( _isNegative == 0,for: Key._isNegative )
		try encoder.encode( _isCompact == 0,for: Key._isCompact )
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


//	Calendar SUPPORT ------------------------------------------------------

extension NSCalendar.Identifier : GCodable {}

extension Calendar : GCodable {
	private enum Key: String {
		case nsIdentifier, locale, timeZone, firstWeekday, minimumDaysInFirstWeek
	}
	
	public func encode(to encoder: GEncoder) throws {
		let nsIdentifier = (self as NSCalendar).calendarIdentifier
		
		try encoder.encode( nsIdentifier, for: Key.nsIdentifier )
		try encoder.encode( locale, for: Key.locale )
		try encoder.encode( timeZone, for: Key.timeZone )
		try encoder.encode( firstWeekday, for: Key.firstWeekday )
		try encoder.encode( minimumDaysInFirstWeek, for: Key.minimumDaysInFirstWeek )
	}
	
	public init(from decoder: GDecoder) throws {
		let nsIdentifier	= try decoder.decode(for: Key.nsIdentifier) as NSCalendar.Identifier
		guard var calendar = NSCalendar(calendarIdentifier: nsIdentifier) as Calendar? else {
			throw GCodableError.initTypeError(
				Self.self, GCodableError.Context(
					debugDescription: "Invalid calendar identifier -\(nsIdentifier)-"
				)
			)
		}
		calendar.locale					= try decoder.decodeIfPresent(for: Key.locale)
		calendar.timeZone				= try decoder.decode(for: Key.timeZone)
		calendar.firstWeekday			= try decoder.decode(for: Key.firstWeekday)
		calendar.minimumDaysInFirstWeek	= try decoder.decode(for: Key.minimumDaysInFirstWeek)
		
		self = calendar
	}
}

//	DateComponents SUPPORT ------------------------------------------------------

extension DateComponents : GCodable {
	private enum Key : String {
		case calendar
		case timeZone
		case era
		case year
		case month
		case day
		case hour
		case minute
		case second
		case nanosecond
		case weekday
		case weekdayOrdinal
		case quarter
		case weekOfMonth
		case weekOfYear
		case yearForWeekOfYear
	}

	
	
	public init(from decoder: GDecoder) throws {
		let calendar   			= try decoder.decodeIfPresent( for: Key.calendar ) as Calendar?
		let timeZone   			= try decoder.decodeIfPresent( for: Key.timeZone ) as TimeZone?
		let era        			= try decoder.decodeIfPresent( for: Key.era ) as Int?
		let year       			= try decoder.decodeIfPresent( for: Key.year ) as Int?
		let month      			= try decoder.decodeIfPresent( for: Key.month ) as Int?
		let day        			= try decoder.decodeIfPresent( for: Key.day ) as Int?
		let hour       			= try decoder.decodeIfPresent( for: Key.hour ) as Int?
		let minute     			= try decoder.decodeIfPresent( for: Key.minute ) as Int?
		let second     			= try decoder.decodeIfPresent( for: Key.second ) as Int?
		let nanosecond 			= try decoder.decodeIfPresent( for: Key.nanosecond ) as Int?
		let weekday          	= try decoder.decodeIfPresent( for: Key.weekday ) as Int?
		let weekdayOrdinal   	= try decoder.decodeIfPresent( for: Key.weekdayOrdinal ) as Int?
		let quarter          	= try decoder.decodeIfPresent( for: Key.quarter ) as Int?
		let weekOfMonth      	= try decoder.decodeIfPresent( for: Key.weekOfMonth ) as Int?
		let weekOfYear       	= try decoder.decodeIfPresent( for: Key.weekOfYear ) as Int?
		let yearForWeekOfYear	= try decoder.decodeIfPresent( for: Key.yearForWeekOfYear ) as Int?
		
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
	
	public func encode(to encoder: GEncoder) throws {
		try encoder.encodeIfPresent( calendar, 			for: Key.calendar)
		try encoder.encodeIfPresent( timeZone, 			for: Key.timeZone)
		try encoder.encodeIfPresent( era, 				for: Key.era)
		try encoder.encodeIfPresent( year, 				for: Key.year)
		try encoder.encodeIfPresent( month, 				for: Key.month)
		try encoder.encodeIfPresent( day,				for: Key.day)
		try encoder.encodeIfPresent( hour,				for: Key.hour)
		try encoder.encodeIfPresent( minute,				for: Key.minute)
		try encoder.encodeIfPresent( second,				for: Key.second)
		try encoder.encodeIfPresent( nanosecond,			for: Key.nanosecond)
		try encoder.encodeIfPresent( weekday,			for: Key.weekday)
		try encoder.encodeIfPresent( weekdayOrdinal,		for: Key.weekdayOrdinal)
		try encoder.encodeIfPresent( quarter,			for: Key.quarter)
		try encoder.encodeIfPresent( weekOfMonth,		for: Key.weekOfMonth)
		try encoder.encodeIfPresent( weekOfYear,			for: Key.weekOfYear)
		try encoder.encodeIfPresent( yearForWeekOfYear,	for: Key.yearForWeekOfYear)
	}
}

//	DateInterval SUPPORT ------------------------------------------------------

extension DateInterval : GCodable {
	private enum Key : String {
		case start
		case duration
	}
	
	public init(from decoder: GDecoder) throws {
		let start 		= try decoder.decode( for: Key.start) as Date
		let duration 	= try decoder.decode( for: Key.duration) as TimeInterval
		self.init(start: start, duration: duration)
	}
	
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( start, 		for: Key.start)
		try encoder.encode( duration, 	for: Key.duration)
	}
}

//	PersonNameComponents SUPPORT ------------------------------------------------------

extension PersonNameComponents : GCodable {
	private enum Key : String {
		case namePrefix
		case givenName
		case middleName
		case familyName
		case nameSuffix
		case nickname
	}
	
	public init(from decoder: GDecoder) throws {
		self.init()
		
		namePrefix = try decoder.decodeIfPresent( for: Key.namePrefix )
		givenName  = try decoder.decodeIfPresent( for: Key.givenName )
		middleName = try decoder.decodeIfPresent( for: Key.middleName )
		familyName = try decoder.decodeIfPresent( for: Key.familyName )
		nameSuffix = try decoder.decodeIfPresent( for: Key.nameSuffix )
		nickname   = try decoder.decodeIfPresent( for: Key.nickname )
	}
	
	public func encode(to encoder: GEncoder) throws {
		try encoder.encodeIfPresent( namePrefix, for: Key.namePrefix)
		try encoder.encodeIfPresent( givenName, 	for: Key.givenName)
		try encoder.encodeIfPresent( middleName, for: Key.middleName)
		try encoder.encodeIfPresent( familyName, for: Key.familyName)
		try encoder.encodeIfPresent( nameSuffix, for: Key.nameSuffix)
		try encoder.encodeIfPresent( nickname, 	for: Key.nickname)
	}
}

//	URL SUPPORT ------------------------------------------------------

extension URL : GCodable {
	private enum Key : String { case baseURL, relativeString }

	public init(from decoder: GDecoder) throws {
		let relative	= try decoder.decode( for: Key.relativeString ) as String
		let base		= try decoder.decodeIfPresent( for: Key.baseURL ) as URL?
		
		guard let url = URL(string: relative, relativeTo: base) else {
			throw GCodableError.initTypeError(
				Self.self, GCodableError.Context(
					debugDescription: "Invalid relative -\(relative)- and base -\(base as Any)-"
				)
			)
		}
		self = url
	}
	
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( relativeString, for: Key.relativeString )
		try encoder.encodeIfPresent( baseURL, for: Key.baseURL )
	}
}

//	URLComponents SUPPORT ------------------------------------------------------

extension URLComponents : GCodable {
	private enum Key : String {
		case scheme
		case user
		case password
		case host
		case port
		case path
		case query
		case fragment
	}

	
	public func encode(to encoder: GEncoder) throws {
		try encoder.encodeIfPresent	( scheme,	for: Key.scheme )
		try encoder.encodeIfPresent	( user,	 	for: Key.user )
		try encoder.encodeIfPresent	( password,	for: Key.password )
		try encoder.encodeIfPresent	( host,	 	for: Key.host )
		try encoder.encodeIfPresent	( port,		for: Key.port )
		try encoder.encode			( path,	 	for: Key.path )
		try encoder.encodeIfPresent	( query,	for: Key.query )
		try encoder.encodeIfPresent	( fragment,	for: Key.fragment )
	}

	public init(from decoder: GDecoder) throws {
		self.init()
		
		scheme		= try decoder.decodeIfPresent( for: Key.scheme )
		user		= try decoder.decodeIfPresent( for: Key.user )
		password	= try decoder.decodeIfPresent( for: Key.password )
		host		= try decoder.decodeIfPresent( for: Key.host )
		port		= try decoder.decodeIfPresent( for: Key.port )
		path		= try decoder.decode( for: Key.path )
		query		= try decoder.decodeIfPresent( for: Key.query )
		fragment	= try decoder.decodeIfPresent( for: Key.fragment )
	}
}

//	----------------------------------------------------------------------------
//	----------------------------------------------------------------------------
//	----------------------------------------------------------------------------
//	----------------------------------------------------------------------------
//	----------------------------------------------------------------------------
//	Measurement SUPPORT ------------------------------------------------------


extension Measurement : GCodable {
	private enum Key : String {
		case value
		case symbol
	}
	
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode ( value,	 for: Key.value )
		try encoder.encode ( unit.symbol, for: Key.symbol )
	}

	public init(from decoder: GDecoder) throws {
		let value = try decoder.decode( for:Key.value ) as Double
		let symbol = try decoder.decode( for:Key.symbol ) as String
		self.init( value: value, unit: UnitType(symbol: symbol) )
	}
}
