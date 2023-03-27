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

extension DispatchTime : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self.init( uptimeNanoseconds: try decoder.decode() )
	}
}
extension DispatchTime : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( uptimeNanoseconds )
	}
}


extension DispatchTimeInterval {
	private enum IntervalType : UInt8, BCodable {
		case seconds,milliseconds,microseconds,nanoseconds,never
	}
}

extension DispatchTimeInterval : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		let intervalType	= try decoder.decode() as IntervalType
		switch intervalType {
			case .seconds:
				self = .seconds( try decoder.decode() )
			case .milliseconds:
				self = .milliseconds( try decoder.decode() )
			case .microseconds:
				self = .microseconds( try decoder.decode() )
			case .nanoseconds:
				self = .nanoseconds( try decoder.decode() )
			case .never:
				self = .never
		}
	}
}

extension DispatchTimeInterval : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
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
			default:
				throw BinaryIOError.libEncodingError(
					Self.self, BinaryIOError.Context(
						debugDescription: "\(Self.self) in a new unknown case -\(self)-."
					)
				)
		}
	}
}

extension DispatchQueue.SchedulerTimeType : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self.init( try decoder.decode() )
	}
}
extension DispatchQueue.SchedulerTimeType : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( dispatchTime )
	}
	
}

extension DispatchQueue.SchedulerTimeType.Stride : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self.init( try decoder.decode() )
	}
}

extension DispatchQueue.SchedulerTimeType.Stride : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( timeInterval )
	}
}


