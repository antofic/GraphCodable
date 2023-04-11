//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/

import Dispatch

extension DispatchTime : GBinaryEncodable {}
extension DispatchTimeInterval : GBinaryEncodable {}
extension DispatchQueue.SchedulerTimeType : GBinaryEncodable {}
extension DispatchQueue.SchedulerTimeType.Stride : GBinaryEncodable {}

extension DispatchTime : GBinaryDecodable {}
extension DispatchTimeInterval : GBinaryDecodable {}
extension DispatchQueue.SchedulerTimeType : GBinaryDecodable {}
extension DispatchQueue.SchedulerTimeType.Stride : GBinaryDecodable {}

extension DispatchTime : GPackable {}
extension DispatchTimeInterval : GPackable {}
extension DispatchQueue.SchedulerTimeType : GPackable {}
extension DispatchQueue.SchedulerTimeType.Stride : GPackable {}
