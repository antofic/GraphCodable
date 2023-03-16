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

extension Data 				: GBinaryEncodable {}
extension CharacterSet		: GBinaryEncodable {}
extension Locale 			: GBinaryEncodable {}
extension TimeZone 			: GBinaryEncodable {}
extension IndexSet 			: GBinaryEncodable {}
extension IndexPath 		: GBinaryEncodable {}

extension Data 				: GBinaryDecodable {}
extension CharacterSet		: GBinaryDecodable {}
extension Locale 			: GBinaryDecodable {}
extension TimeZone 			: GBinaryDecodable {}
extension IndexSet 			: GBinaryDecodable {}
extension IndexPath 		: GBinaryDecodable {}

extension CGFloat			: GBinaryEncodable {}
extension AffineTransform	: GBinaryEncodable {}
extension UUID 				: GBinaryEncodable {}
extension Date				: GBinaryEncodable {}
extension CGSize 			: GBinaryEncodable {}
extension CGPoint 			: GBinaryEncodable {}
extension CGVector 			: GBinaryEncodable {}
extension CGRect 			: GBinaryEncodable {}
extension NSRange 			: GBinaryEncodable {}
extension Decimal 			: GBinaryEncodable {}

extension CGFloat			: GBinaryDecodable {}
extension AffineTransform	: GBinaryDecodable {}
extension UUID 				: GBinaryDecodable {}
extension Date				: GBinaryDecodable {}
extension CGSize 			: GBinaryDecodable {}
extension CGPoint 			: GBinaryDecodable {}
extension CGVector 			: GBinaryDecodable {}
extension CGRect 			: GBinaryDecodable {}
extension NSRange 			: GBinaryDecodable {}
extension Decimal 			: GBinaryDecodable {}

extension CGFloat			: GPackable {}
extension AffineTransform	: GPackable {}
extension UUID 				: GPackable {}
extension Date				: GPackable {}
extension CGSize 			: GPackable {}
extension CGPoint 			: GPackable {}
extension CGVector 			: GPackable {}
extension CGRect 			: GPackable {}
extension NSRange 			: GPackable {}
extension Decimal 			: GPackable {}

extension OperationQueue.SchedulerTimeType 			: GBinaryEncodable {}
extension OperationQueue.SchedulerTimeType.Stride	: GBinaryEncodable {}
extension RunLoop.SchedulerTimeType					: GBinaryEncodable {}
extension RunLoop.SchedulerTimeType.Stride			: GBinaryEncodable {}

extension OperationQueue.SchedulerTimeType 			: GBinaryDecodable {}
extension OperationQueue.SchedulerTimeType.Stride	: GBinaryDecodable {}
extension RunLoop.SchedulerTimeType					: GBinaryDecodable {}
extension RunLoop.SchedulerTimeType.Stride			: GBinaryDecodable {}

extension OperationQueue.SchedulerTimeType 			: GPackable {}
extension OperationQueue.SchedulerTimeType.Stride	: GPackable {}
extension RunLoop.SchedulerTimeType					: GPackable {}
extension RunLoop.SchedulerTimeType.Stride			: GPackable {}


//	Calendar SUPPORT ------------------------------------------------------

extension NSCalendar.Identifier : GEncodable {}
extension NSCalendar.Identifier : GDecodable {}

extension Calendar : GEncodable {
	private enum Key: String {
		case nsIdentifier, locale, timeZone, firstWeekday, minimumDaysInFirstWeek
	}
	
	public func encode(to encoder: GEncoder) throws {
		let nsIdentifier = (self as NSCalendar).calendarIdentifier
		
		try encoder.encode( nsIdentifier, 			for: Key.nsIdentifier )
		try encoder.encode( locale, 				for: Key.locale )
		try encoder.encode( timeZone, 				for: Key.timeZone )
		try encoder.encode( firstWeekday, 			for: Key.firstWeekday )
		try encoder.encode( minimumDaysInFirstWeek, for: Key.minimumDaysInFirstWeek )
	}
}

extension Calendar : GDecodable {
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
extension DateComponents {
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
}

extension DateComponents : GDecodable {
	public init(from decoder: GDecoder) throws {
		self.init(
			calendar:			try decoder.decodeIfPresent( for: Key.calendar 			),
			timeZone:			try decoder.decodeIfPresent( for: Key.timeZone 			),
			era:				try decoder.decodeIfPresent( for: Key.era 				),
			year:				try decoder.decodeIfPresent( for: Key.year			 	),
			month:				try decoder.decodeIfPresent( for: Key.month			 	),
			day:				try decoder.decodeIfPresent( for: Key.day			 	),
			hour:				try decoder.decodeIfPresent( for: Key.hour			 	),
			minute:				try decoder.decodeIfPresent( for: Key.minute			),
			second:				try decoder.decodeIfPresent( for: Key.second			),
			nanosecond:			try decoder.decodeIfPresent( for: Key.nanosecond		),
			weekday:			try decoder.decodeIfPresent( for: Key.weekday		 	),
			weekdayOrdinal:		try decoder.decodeIfPresent( for: Key.weekdayOrdinal	),
			quarter:			try decoder.decodeIfPresent( for: Key.quarter		 	),
			weekOfMonth:		try decoder.decodeIfPresent( for: Key.weekOfMonth	 	),
			weekOfYear: 		try decoder.decodeIfPresent( for: Key.weekOfYear 	 	),
			yearForWeekOfYear:	try decoder.decodeIfPresent( for: Key.yearForWeekOfYear )
		)
	}
}
extension DateComponents : GEncodable {
	public func encode(to encoder: GEncoder) throws {
		try encoder.encodeIfPresent( calendar, 			for: Key.calendar 			)
		try encoder.encodeIfPresent( timeZone, 			for: Key.timeZone 			)
		try encoder.encodeIfPresent( era, 				for: Key.era 				)
		try encoder.encodeIfPresent( year, 				for: Key.year			 	)
		try encoder.encodeIfPresent( month, 			for: Key.month			 	)
		try encoder.encodeIfPresent( day,				for: Key.day			 	)
		try encoder.encodeIfPresent( hour,				for: Key.hour			 	)
		try encoder.encodeIfPresent( minute,			for: Key.minute				)
		try encoder.encodeIfPresent( second,			for: Key.second				)
		try encoder.encodeIfPresent( nanosecond,		for: Key.nanosecond			)
		try encoder.encodeIfPresent( weekday,			for: Key.weekday		 	)
		try encoder.encodeIfPresent( weekdayOrdinal,	for: Key.weekdayOrdinal		)
		try encoder.encodeIfPresent( quarter,			for: Key.quarter		 	)
		try encoder.encodeIfPresent( weekOfMonth,		for: Key.weekOfMonth	 	)
		try encoder.encodeIfPresent( weekOfYear,		for: Key.weekOfYear 	 	)
		try encoder.encodeIfPresent( yearForWeekOfYear,	for: Key.yearForWeekOfYear	)
	}
}

//	DateInterval SUPPORT ------------------------------------------------------

extension DateInterval {
	private enum Key : String {
		case start
		case duration
	}
}
extension DateInterval : GDecodable {
	public init(from decoder: GDecoder) throws {
		let start 		= try decoder.decode( for: Key.start) as Date
		let duration 	= try decoder.decode( for: Key.duration) as TimeInterval
		self.init(start: start, duration: duration)
	}
}
extension DateInterval : GEncodable {
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( start, 		for: Key.start)
		try encoder.encode( duration, 	for: Key.duration)
	}
}

//	PersonNameComponents SUPPORT ------------------------------------------------------

extension PersonNameComponents {
	private enum Key : String {
		case namePrefix
		case givenName
		case middleName
		case familyName
		case nameSuffix
		case nickname
	}
}

extension PersonNameComponents : GDecodable {
	public init(from decoder: GDecoder) throws {
		self.init()
		
		namePrefix = try decoder.decodeIfPresent( for: Key.namePrefix )
		givenName  = try decoder.decodeIfPresent( for: Key.givenName )
		middleName = try decoder.decodeIfPresent( for: Key.middleName )
		familyName = try decoder.decodeIfPresent( for: Key.familyName )
		nameSuffix = try decoder.decodeIfPresent( for: Key.nameSuffix )
		nickname   = try decoder.decodeIfPresent( for: Key.nickname )
	}
}
extension PersonNameComponents : GEncodable {
	public func encode(to encoder: GEncoder) throws {
		try encoder.encodeIfPresent( namePrefix, for: Key.namePrefix)
		try encoder.encodeIfPresent( givenName, for: Key.givenName)
		try encoder.encodeIfPresent( middleName, for: Key.middleName)
		try encoder.encodeIfPresent( familyName, for: Key.familyName)
		try encoder.encodeIfPresent( nameSuffix, for: Key.nameSuffix)
		try encoder.encodeIfPresent( nickname, 	for: Key.nickname)
	}
}

//	URL SUPPORT ------------------------------------------------------

extension URL {
	private enum Key : String { case baseURL, relativeString }
}

extension URL : GDecodable {
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
}
extension URL : GEncodable {
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( relativeString, for: Key.relativeString )
		try encoder.encodeIfPresent( baseURL, for: Key.baseURL )
	}
}

//	URLComponents SUPPORT ------------------------------------------------------
extension URLComponents {
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
}


extension URLComponents : GEncodable {
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
}
extension URLComponents : GDecodable {
	public init(from decoder: GDecoder) throws {
		self.init()
		
		scheme		= try decoder.decodeIfPresent(	for: Key.scheme )
		user		= try decoder.decodeIfPresent(	for: Key.user )
		password	= try decoder.decodeIfPresent(	for: Key.password )
		host		= try decoder.decodeIfPresent(	for: Key.host )
		port		= try decoder.decodeIfPresent(	for: Key.port )
		path		= try decoder.decode( 			for: Key.path )
		query		= try decoder.decodeIfPresent(	for: Key.query )
		fragment	= try decoder.decodeIfPresent(	for: Key.fragment )
	}
}

//	Measurement SUPPORT ------------------------------------------------------

extension Measurement {
	private enum Key : String {
		case value
		case symbol
	}
}

extension Measurement : GEncodable {
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode ( value,	 for: Key.value )
		try encoder.encode ( unit.symbol, for: Key.symbol )
	}
}
extension Measurement : GDecodable {
	public init(from decoder: GDecoder) throws {
		let value = try decoder.decode( for:Key.value ) as Double
		let symbol = try decoder.decode( for:Key.symbol ) as String
		self.init( value: value, unit: UnitType(symbol: symbol) )
	}
}

