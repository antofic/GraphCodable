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

import Dispatch


extension DispatchTime : BinaryIOType {
	public init(from reader: inout BinaryReader) throws {
		self.init( uptimeNanoseconds: try UInt64( from: &reader) )
	}
	
	public func write(to writer: inout BinaryWriter) throws {
		try uptimeNanoseconds.write(to: &writer)
	}
}

extension DispatchTimeInterval : BinaryIOType {
	private enum IntervalType : UInt8, BinaryIOType {
		case seconds,milliseconds,microseconds,nanoseconds,never
	}
	
	public func write(to writer: inout BinaryWriter) throws {
		switch self {
		case .seconds( let value ):
			try IntervalType.seconds.write(to: &writer)
			try value.write(to: &writer)
		case .milliseconds( let value ):
			try IntervalType.milliseconds.write(to: &writer)
			try value.write(to: &writer)
		case .microseconds( let value ):
			try IntervalType.microseconds.write(to: &writer)
			try value.write(to: &writer)
		case .nanoseconds( let value ):
			try IntervalType.nanoseconds.write(to: &writer)
			try value.write(to: &writer)
		case .never:
			try IntervalType.never.write(to: &writer)
		default:
			throw BinaryIOError.versionError(
				Self.self, BinaryIOError.Context(
					debugDescription: "\(Self.self) in a new unknown case -\(self)-."
				)
			)
		}
	}
	
	public init(from reader: inout BinaryReader) throws {
		let intervalType	= try IntervalType.init(from: &reader)
		switch intervalType {
		case .seconds:
			let value = try Int( from: &reader )
			self = .seconds(value)
		case .milliseconds:
			let value = try Int( from: &reader )
			self = .milliseconds(value)
		case .microseconds:
			let value = try Int( from: &reader )
			self = .microseconds(value)
		case .nanoseconds:
			let value = try Int( from: &reader )
			self = .nanoseconds(value)
		case .never:
			self = .never
		}
	}
}

@available(macOS 10.15, iOS 8.0, watchOS 2.0, tvOS 9.0, *)
extension DispatchQueue.SchedulerTimeType : BinaryIOType {
	public func write(to writer: inout BinaryWriter) throws {
		try dispatchTime.write(to: &writer)
	}
	
	public init(from reader: inout BinaryReader) throws {
		self.init( try DispatchTime(from: &reader) )
	}
}


@available(macOS 10.15, iOS 8.0, watchOS 2.0, tvOS 9.0, *)
extension DispatchQueue.SchedulerTimeType.Stride : BinaryIOType {
	public func write(to writer: inout BinaryWriter) throws {
		try timeInterval.write(to: &writer)
	}
	
	public init(from reader: inout BinaryReader) throws {
		self.init( try DispatchTimeInterval( from:&reader) )
	}
}
