//
//  File.swift
//  
//
//  Created by Antonino Ficarra on 08/05/21.
//

import Foundation

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
			throw GCodableError.initGCodableError(
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

@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
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

@available(macOS 10.11, iOS 9.0, watchOS 2.0, tvOS 9.0, *)
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
	private enum Key : String { case base, relative }

	public init(from decoder: GDecoder) throws {
		let relative	= try decoder.decode( for: Key.relative ) as String
		let base		= try decoder.decodeIfPresent( for: Key.base ) as URL?
		
		guard let url = URL(string: relative, relativeTo: base) else {
			throw GCodableError.initGCodableError(
				Self.self, GCodableError.Context(
					debugDescription: "Invalid relative -\(relative)- and base -\(base as Any)-"
				)
			)
		}
		self = url
	}
	
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( relativeString, for: Key.relative )
		try encoder.encodeIfPresent( baseURL, for: Key.base )
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
		try encoder.encodeIfPresent( scheme,		for: Key.scheme )
		try encoder.encodeIfPresent( user,	 	for: Key.user )
		try encoder.encodeIfPresent( password,	for: Key.password )
		try encoder.encodeIfPresent( host,	 	for: Key.host )
		try encoder.encodeIfPresent( port,		for: Key.port )
		try encoder.encode( path,	 	for: Key.path )
		try encoder.encodeIfPresent( query,		for: Key.query )
		try encoder.encodeIfPresent( fragment,	 for: Key.fragment )
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

