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
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		self.init( uptimeNanoseconds: try UInt64( from: &rbuffer) )
	}
	
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try uptimeNanoseconds.write(to: &wbuffer)
	}
}

extension DispatchTimeInterval : BinaryIOType {
	private enum IntervalType : UInt8, BinaryIOType {
		case seconds,milliseconds,microseconds,nanoseconds,never
	}
	
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		switch self {
		case .seconds( let value ):
			try IntervalType.seconds.write(to: &wbuffer)
			try value.write(to: &wbuffer)
		case .milliseconds( let value ):
			try IntervalType.milliseconds.write(to: &wbuffer)
			try value.write(to: &wbuffer)
		case .microseconds( let value ):
			try IntervalType.microseconds.write(to: &wbuffer)
			try value.write(to: &wbuffer)
		case .nanoseconds( let value ):
			try IntervalType.nanoseconds.write(to: &wbuffer)
			try value.write(to: &wbuffer)
		case .never:
			try IntervalType.never.write(to: &wbuffer)
		default:
			throw BinaryIOError.versionError(
				Self.self, BinaryIOError.Context(
					debugDescription: "\(Self.self) in a new unknown case -\(self)-."
				)
			)
		}
	}
	
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		let intervalType	= try IntervalType.init(from: &rbuffer)
		switch intervalType {
		case .seconds:
			let value = try Int( from: &rbuffer )
			self = .seconds(value)
		case .milliseconds:
			let value = try Int( from: &rbuffer )
			self = .milliseconds(value)
		case .microseconds:
			let value = try Int( from: &rbuffer )
			self = .microseconds(value)
		case .nanoseconds:
			let value = try Int( from: &rbuffer )
			self = .nanoseconds(value)
		case .never:
			self = .never
		}
	}
}

extension DispatchQueue.SchedulerTimeType : BinaryIOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try dispatchTime.write(to: &wbuffer)
	}
	
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		self.init( try DispatchTime(from: &rbuffer) )
	}
}

extension DispatchQueue.SchedulerTimeType.Stride : BinaryIOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try timeInterval.write(to: &wbuffer)
	}
	
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		self.init( try DispatchTimeInterval( from:&rbuffer) )
	}
}

