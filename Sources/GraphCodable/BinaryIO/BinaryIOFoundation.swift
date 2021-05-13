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

// -- Data support (BinaryIOType) -------------------------------------------------------
//	Uses Version: NO

extension Data : BinaryIOType {
	public func write( to writer: inout BinaryWriter ) throws {
		try writer.write( self )
	}
	public init( from reader: inout BinaryReader ) throws {
		self = try reader.read()
	}
}


// -- CGFloat (BinaryIOType) --------------------------------------------
//	Uses Version: NO
//	Su alcune piattaforme CGFloat == Float (32 bit).
//	Salviamo sempre come Double 64bit

extension CGFloat : BinaryIOType {
	public init(from reader: inout BinaryReader) throws {
		self.init( try reader.read() as Self )
	}

	public func write(to writer: inout BinaryWriter) throws {
		try writer.write( Double( self ) )
	}
}

//	CharacterSet SUPPORT ------------------------------------------------------
//	Uses Version: NO

extension CharacterSet : BinaryIOType {
	public init(from reader: inout BinaryReader) throws {
		self.init( bitmapRepresentation: try reader.read() as Data )
	}
	
	public func write(to writer: inout BinaryWriter) throws {
		try writer.write( self.bitmapRepresentation )
	}
}

//	AffineTransform SUPPORT ------------------------------------------------------
//	Uses Version: NO

extension AffineTransform : BinaryIOType {
	// m11: CGFloat, m12: CGFloat, m21: CGFloat, m22: CGFloat, tX: CGFloat, tY: CGFloat
	
	public func write(to writer: inout BinaryWriter) throws {
		try writer.write( m11 )
		try writer.write( m12 )
		try writer.write( m21 )
		try writer.write( m22 )
		try writer.write( tX )
		try writer.write( tY )
	}
	
	public init(from reader: inout BinaryReader) throws {
		let m11	= try reader.read() as CGFloat
		let m12	= try reader.read() as CGFloat
		let m21	= try reader.read() as CGFloat
		let m22	= try reader.read() as CGFloat
		let tX	= try reader.read() as CGFloat
		let tY	= try reader.read() as CGFloat
		self.init(m11: m11, m12: m12, m21: m21, m22: m22, tX: tX, tY: tY)
	}
}

//	Locale SUPPORT ------------------------------------------------------
//	Uses Version: NO

extension Locale : BinaryIOType {
	public func write( to writer: inout BinaryWriter ) throws {
		try writer.write( self.identifier )
	}

	public init( from reader: inout BinaryReader ) throws {
		self.init( identifier: try reader.read() as String )
	}
}

//	TimeZone SUPPORT ------------------------------------------------------
//	Uses Version: NO

extension TimeZone : BinaryIOType {
	public func write( to writer: inout BinaryWriter ) throws {
		try writer.write( self.identifier )
	}

	public init( from reader: inout BinaryReader ) throws {
		let identifier = try reader.read() as String
		guard let timeZone = TimeZone( identifier: identifier ) else {
			throw BinaryIOError.initTypeError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Invalid timezone identifier -\(identifier)-"
				)
			)
		}
		self = timeZone
	}
}

// -- UUID support  -------------------------------------------------------
//	Uses Version: NO

extension UUID : BinaryIOType  {
	public func write(to writer: inout BinaryWriter) throws {
		try writer.write( self.uuidString )
	}
	
	public init( from reader: inout BinaryReader ) throws {
		let uuidString	= try reader.read() as String
		
		guard let uuid = UUID(uuidString: uuidString) else {
			throw BinaryIOError.initTypeError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Attempted to decode UUID from invalid UUID string -\(uuidString)-."
				)
			)
		}
		self = uuid
	}
}

//	Date SUPPORT ------------------------------------------------------
//	Uses Version: NO

extension Date : BinaryIOType {
	public func write( to writer: inout BinaryWriter ) throws {
		try writer.write( self.timeIntervalSince1970 )
	}
	public init( from reader: inout BinaryReader ) throws {
		self.init( timeIntervalSince1970: try reader.read() as TimeInterval )
	}
}



//	IndexSet SUPPORT ------------------------------------------------------
//	Uses Version: NO

extension IndexSet : BinaryIOType {
	public init(from reader: inout BinaryReader) throws {
		self.init()
		let count	= try reader.read() as Int
		for _ in 0..<count {
			self.insert(integersIn: try reader.read() as Range )
		}
	}
	
	public func write(to writer: inout BinaryWriter) throws {
		try writer.write( rangeView.count )
		for range in rangeView {
			try writer.write( range )
		}
	}
}

// -- IndexPath support  -------------------------------------------------------
//	Uses Version: NO

extension IndexPath : BinaryIOType {
	public init(from reader: inout BinaryReader) throws {
		self.init()
		let count	= try reader.read() as Int
		for _ in 0..<count {
			self.append( try reader.read() as Int )
		}
	}
	
	public func write(to writer: inout BinaryWriter) throws {
		try writer.write( count )
		for element in self {
			try writer.write( element )
		}

	}
}

//	CGSize SUPPORT ------------------------------------------------------
//	Uses Version: NO

extension CGSize : BinaryIOType {
	public func write(to writer: inout BinaryWriter) throws {
		try writer.write( width )
		try writer.write( height )
	}

	public init(from reader: inout BinaryReader) throws {
		let width	= try reader.read() as CGFloat
		let height	= try reader.read() as CGFloat
		self.init(width: width, height: height)
	}
}

//	CGPoint SUPPORT ------------------------------------------------------
//	Uses Version: NO

extension CGPoint : BinaryIOType {
	public func write(to writer: inout BinaryWriter) throws {
		try writer.write( x )
		try writer.write( y )
	}

	public init(from reader: inout BinaryReader) throws {
		let x	= try reader.read() as CGFloat
		let y	= try reader.read() as CGFloat
		self.init(x: x, y: y)
	}
}

//	CGVector SUPPORT ------------------------------------------------------
//	Uses Version: NO

extension CGVector : BinaryIOType {
	public func write(to writer: inout BinaryWriter) throws {
		try writer.write( dx )
		try writer.write( dy )
	}
	public init(from reader: inout BinaryReader) throws {
		let dx	= try reader.read() as CGFloat
		let dy	= try reader.read() as CGFloat
		self.init(dx: dx, dy: dy)
	}
}

//	CGRect SUPPORT ------------------------------------------------------
//	Uses Version: NO

extension CGRect : BinaryIOType {
	public func write(to writer: inout BinaryWriter) throws {
		try writer.write( origin )
		try writer.write( size )
	}
	public init(from reader: inout BinaryReader) throws {
		let origin	= try reader.read() as CGPoint
		let size	= try reader.read() as CGSize
		self.init(origin: origin, size: size)
	}
}

//	NSRange SUPPORT ------------------------------------------------------
//	Uses Version: NO

extension NSRange : BinaryIOType {
	public func write(to writer: inout BinaryWriter) throws {
		try writer.write( location )
		try writer.write( length )
	}
	public init(from reader: inout BinaryReader) throws {
		let location	= try reader.read() as Int
		let length		= try reader.read() as Int
		self.init(location: location, length: length)
	}
}

// -- Decimal support  -------------------------------------------------------
//	Uses Version: YES

extension Decimal : BinaryIOType {
	private enum Version : UInt8 { case v0 }
	
	// CANDIDATO
	
	public func write( to writer: inout BinaryWriter ) throws {
		try writer.write( Version.v0.rawValue )

		try writer.write( _exponent )
		try writer.write( _length )
		try writer.write( _isNegative == 0 )
		try writer.write( _isCompact == 0 )
		try writer.write( _mantissa.0 )
		try writer.write( _mantissa.1 )
		try writer.write( _mantissa.2 )
		try writer.write( _mantissa.3 )
		try writer.write( _mantissa.4 )
		try writer.write( _mantissa.5 )
		try writer.write( _mantissa.6 )
		try writer.write( _mantissa.7 )
	}

	public init( from reader: inout BinaryReader ) throws {
		let versionRaw	= try Version.RawValue(from: &reader)
		
		switch versionRaw {
		case Version.v0.rawValue:
			let exponent	= try reader.read() as Int32
			let length		= try reader.read() as UInt32
			let isNegative	= (try reader.read() as Bool) == false ? UInt32(0) : UInt32(1)
			let isCompact	= (try reader.read() as Bool) == false ? UInt32(0) : UInt32(1)
			let mantissa0	= try reader.read() as UInt16
			let mantissa1	= try reader.read() as UInt16
			let mantissa2	= try reader.read() as UInt16
			let mantissa3	= try reader.read() as UInt16
			let mantissa4	= try reader.read() as UInt16
			let mantissa5	= try reader.read() as UInt16
			let mantissa6	= try reader.read() as UInt16
			let mantissa7	= try reader.read() as UInt16

			self.init(
				_exponent: exponent, _length: length, _isNegative: isNegative, _isCompact: isCompact, _reserved: 0,
				_mantissa: (mantissa0, mantissa1, mantissa2, mantissa3, mantissa4, mantissa5, mantissa6, mantissa7)
			)
		default:
			throw BinaryIOError.versionError(
				Self.self, BinaryIOError.Context(
					debugDescription: "\(Self.self) data in a new unknown version -\(versionRaw)-."
				)
			)
		}

	}
}

//	Calendar SUPPORT ------------------------------------------------------
//	Uses Version: YES

extension NSCalendar.Identifier : BinaryIOType {}

extension Calendar : BinaryIOType {
	private enum Version : UInt8 { case v0 }

	public func write(to writer: inout BinaryWriter) throws {
		try writer.write( Version.v0.rawValue )

		let nsIdentifier = (self as NSCalendar).calendarIdentifier
		
		try writer.write( nsIdentifier )
		try writer.write( locale )
		try writer.write( timeZone )
		try writer.write( firstWeekday )
		try writer.write( minimumDaysInFirstWeek )
	}
	
	public init(from reader: inout BinaryReader) throws {
		let versionRaw	= try reader.read() as Version.RawValue

		switch versionRaw {
		case Version.v0.rawValue:
			let nsIdentifier = try reader.read() as NSCalendar.Identifier
			guard var calendar = NSCalendar(calendarIdentifier: nsIdentifier) as Calendar? else {
				throw BinaryIOError.initTypeError(
					Self.self, BinaryIOError.Context(
						debugDescription: "Invalid calendar identifier -\(nsIdentifier)-"
					)
				)
			}
			calendar.locale					= try reader.read() as Locale
			calendar.timeZone				= try reader.read() as TimeZone
			calendar.firstWeekday			= try reader.read() as Int
			calendar.minimumDaysInFirstWeek	= try reader.read() as Int
			
			self = calendar
		default:
			throw BinaryIOError.versionError(
				Self.self, BinaryIOError.Context(
					debugDescription: "\(Self.self) data in a new unknown version -\(versionRaw)-."
				)
			)
		}
	}
}

//	DateComponents SUPPORT ------------------------------------------------------
//	Uses Version: YES

extension DateComponents : BinaryIOType {
	private enum Version : UInt8 { case v0 }

	public func write(to writer: inout BinaryWriter) throws {
		try writer.write( Version.v0.rawValue )


		try writer.write( calendar   		)
		try writer.write( timeZone   		)
		try writer.write( era        		)
		try writer.write( year       		)
		try writer.write( month      		)
		try writer.write( day        		)
		try writer.write( hour       		)
		try writer.write( minute     		)
		try writer.write( second     		)
		try writer.write( nanosecond 		)
		try writer.write( weekday          	)
		try writer.write( weekdayOrdinal   	)
		try writer.write( quarter          	)
		try writer.write( weekOfMonth      	)
		try writer.write( weekOfYear       	)
		try writer.write( yearForWeekOfYear	)
	}

	public init(from reader: inout BinaryReader) throws {
		let versionRaw	= try reader.read() as Version.RawValue

		switch versionRaw {
		case Version.v0.rawValue:
			let calendar   			= try reader.read() as Calendar?
			let timeZone   			= try reader.read() as TimeZone?
			let era        			= try reader.read() as Int?
			let year       			= try reader.read() as Int?
			let month      			= try reader.read() as Int?
			let day        			= try reader.read() as Int?
			let hour       			= try reader.read() as Int?
			let minute     			= try reader.read() as Int?
			let second     			= try reader.read() as Int?
			let nanosecond 			= try reader.read() as Int?
			let weekday          	= try reader.read() as Int?
			let weekdayOrdinal   	= try reader.read() as Int?
			let quarter          	= try reader.read() as Int?
			let weekOfMonth      	= try reader.read() as Int?
			let weekOfYear       	= try reader.read() as Int?
			let yearForWeekOfYear	= try reader.read() as Int?
		
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
		default:
			throw BinaryIOError.versionError(
				Self.self, BinaryIOError.Context(
					debugDescription: "\(Self.self) data in a new unknown version -\(versionRaw)-."
				)
			)
		}
	}
}


//	DateInterval SUPPORT ------------------------------------------------------
//	Uses Version: YES

@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
extension DateInterval : BinaryIOType {
	private enum Version : UInt8 { case v0 }

	public func write(to writer: inout BinaryWriter) throws {
		try writer.write( Version.v0.rawValue )

		try writer.write( start )
		try writer.write( duration )
	}
	
	public init(from reader: inout BinaryReader) throws {
		let versionRaw	= try reader.read() as Version.RawValue

		switch versionRaw {
		case Version.v0.rawValue:
			let start 		= try reader.read() as Date
			let duration 	= try reader.read() as TimeInterval
			self.init(start: start, duration: duration)
		default:
			throw BinaryIOError.versionError(
				Self.self, BinaryIOError.Context(
					debugDescription: "\(Self.self) data in a new unknown version -\(versionRaw)-."
				)
			)
		}
	}
}

//	PersonNameComponents SUPPORT ------------------------------------------------------
//	Uses Version: YES

@available(macOS 10.11, iOS 9.0, watchOS 2.0, tvOS 9.0, *)
extension PersonNameComponents : BinaryIOType {
	private enum Version : UInt8 { case v0 }

	public func write(to writer: inout BinaryWriter) throws {
		try writer.write( Version.v0.rawValue )

		try writer.write( namePrefix	)
		try writer.write( givenName		)
		try writer.write( middleName	)
		try writer.write( familyName	)
		try writer.write( nameSuffix	)
		try writer.write( nickname		)
	}
	
	public init(from reader: inout BinaryReader) throws {
		let versionRaw	= try reader.read() as Version.RawValue

		switch versionRaw {
		case Version.v0.rawValue:
			self.init()
			
			namePrefix	= try reader.read() as String?
			givenName	= try reader.read() as String?
			middleName	= try reader.read() as String?
			familyName	= try reader.read() as String?
			nameSuffix	= try reader.read() as String?
			nickname	= try reader.read() as String?
		default:
			throw BinaryIOError.versionError(
				Self.self, BinaryIOError.Context(
					debugDescription: "\(Self.self) data in a new unknown version -\(versionRaw)-."
				)
			)
		}
	}
}

//	URL SUPPORT ------------------------------------------------------
//	Uses Version: YES

extension URL : BinaryIOType {
	private enum Version : UInt8 { case v0 }

	public func write(to writer: inout BinaryWriter) throws {
		try writer.write( Version.v0.rawValue )

		try writer.write( relativeString )
		try writer.write( baseURL )
	}
	
	public init(from reader: inout BinaryReader) throws {
		let versionRaw	= try reader.read() as Version.RawValue

		switch versionRaw {
		case Version.v0.rawValue:
			let relative	= try reader.read() as String
			let base		= try reader.read() as URL?

			guard let url = URL(string: relative, relativeTo: base) else {
				throw BinaryIOError.initTypeError(
					Self.self, BinaryIOError.Context(
						debugDescription: "Invalid relative -\(relative)- and base -\(base as Any)-"
					)
				)
			}
			self = url
		default:
			throw BinaryIOError.versionError(
				Self.self, BinaryIOError.Context(
					debugDescription: "\(Self.self) data in a new unknown version -\(versionRaw)-."
				)
			)
		}
	}
}

//	URLComponents SUPPORT ------------------------------------------------------
//	Uses Version: YES

extension URLComponents : BinaryIOType {
	private enum Version : UInt8 { case v0 }

	public func write(to writer: inout BinaryWriter) throws {
		try writer.write( Version.v0.rawValue )

		try writer.write( scheme	)
		try writer.write( user		)
		try writer.write( password	)
		try writer.write( host		)
		try writer.write( port		)
		try writer.write( path		)
		try writer.write( query		)
		try writer.write( fragment	)
	}
	
	public init(from reader: inout BinaryReader) throws {
		let versionRaw	= try reader.read() as Version.RawValue

		switch versionRaw {
		case Version.v0.rawValue:
			self.init()
			
			scheme		= try reader.read() as String?
			user		= try reader.read() as String?
			password	= try reader.read() as String?
			host		= try reader.read() as String?
			port		= try reader.read() as Int?
			path		= try reader.read() as String
			query		= try reader.read() as String?
			fragment	= try reader.read() as String?
		default:
			throw BinaryIOError.versionError(
				Self.self, BinaryIOError.Context(
					debugDescription: "\(Self.self) data in a new unknown version -\(versionRaw)-."
				)
			)
		}
	}
}

