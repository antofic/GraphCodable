//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

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


