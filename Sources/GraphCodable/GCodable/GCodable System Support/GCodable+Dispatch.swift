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

import Dispatch

/*
extension DispatchTime : GCodable {
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( uptimeNanoseconds )
	}
	
	public init(from decoder: GDecoder) throws {
		self.init( uptimeNanoseconds: try decoder.decode() )
	}
}
*/
extension DispatchTime : GTrivialCodable {}

/*
extension DispatchTimeInterval : GCodable {
	private enum IntervalType : UInt8, GCodable {
		case seconds,milliseconds,microseconds,nanoseconds,never
	}

	public func encode(to encoder: GEncoder) throws {
		switch self {
		case .seconds( let value ):
			try encoder.encode( IntervalType.seconds )
			try encoder.encode( value )
		case .milliseconds( let value ):
			try encoder.encode( IntervalType.milliseconds )
			try encoder.encode( value )
		case .microseconds( let value ):
			try encoder.encode( IntervalType.microseconds )
			try encoder.encode( value )
		case .nanoseconds( let value ):
			try encoder.encode( IntervalType.nanoseconds )
			try encoder.encode( value )
		case .never:
			try encoder.encode( IntervalType.never )
		@unknown default:
			throw GCodableError.versionError(
				Self.self, GCodableError.Context(
					debugDescription: "\(Self.self) in a new unknown case -\(self)-."
				)
			)
		}
	}
	
	public init(from decoder: GDecoder) throws {
		let intervalType	= try decoder.decode() as IntervalType
		switch intervalType {
		case .seconds:
			let value = try decoder.decode() as Int
			self = .seconds(value)
		case .milliseconds:
			let value = try decoder.decode() as Int
			self = .milliseconds(value)
		case .microseconds:
			let value = try decoder.decode() as Int
			self = .microseconds(value)
		case .nanoseconds:
			let value = try decoder.decode() as Int
			self = .nanoseconds(value)
		case .never:
			self = .never
		}
	}
}
*/

extension DispatchTimeInterval : GTrivialCodable {}

/*
extension DispatchQueue.SchedulerTimeType : GCodable {
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( dispatchTime )
	}
	
	public init(from decoder: GDecoder) throws {
		self.init( try decoder.decode() )
	}
}
*/

extension DispatchQueue.SchedulerTimeType : GTrivialCodable {}

/*
extension DispatchQueue.SchedulerTimeType.Stride : GCodable {
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( timeInterval )
	}

	public init(from decoder: GDecoder) throws {
		self.init( try decoder.decode() )
	}
}
*/

extension DispatchQueue.SchedulerTimeType.Stride : GTrivialCodable {}
