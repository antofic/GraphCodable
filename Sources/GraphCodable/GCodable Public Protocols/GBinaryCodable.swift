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


public protocol	GBinaryEncodable : BinaryOType, GEncodable {}
public protocol	GBinaryDecodable : BinaryIType, GDecodable {}

///	A protocol to use the `GBinaryCodable` protocol
///
///	To bypass the standard coding mechanism and use the faster
///	BinaryIO one, adopt the `GBinaryCodable` protocol and write
///	the required methods of GBinaryCodable protocol.
///
///	- Note: The GBinaryCodable protocol does not support
///	any of the GraphCodable features. Use it for simple types
///	only when it's really necessary.
public typealias GBinaryCodable = GBinaryEncodable & GBinaryDecodable

extension GBinaryEncodable {
	public func encode(to encoder: GEncoder) throws	{
		throw GCodableError.internalInconsistency(
			Self.self, GCodableError.Context(
				debugDescription: "Program must not reach this \(#function)."
			)
		)
	}
}
extension GBinaryDecodable {
	public init(from decoder: GDecoder) throws {
		throw GCodableError.internalInconsistency(
			Self.self, GCodableError.Context(
				debugDescription: "Program must not reach this \(#function)."
			)
		)
	}
}

extension String : GIdentifiable {
	public var gcodableID: String? { self }
}

extension Array : GIdentifiable where Element:GCodable {
	public var gcodableID: ObjectIdentifier? {
		withUnsafeBytes { unsafeBitCast( $0.baseAddress, to: ObjectIdentifier?.self) }
	}
}

extension ContiguousArray : GIdentifiable where Element:GCodable {
	public var gcodableID: ObjectIdentifier? {
		withUnsafeBytes { unsafeBitCast( $0.baseAddress, to: ObjectIdentifier?.self) }
	}
}


//	extension Int : GBinaryCodable {}
//	extension Int8 : GBinaryCodable {}
//	extension Int16 : GBinaryCodable {}
//	extension Int32 : GBinaryCodable {}
//	extension Int64 : GBinaryCodable {}
//	extension UInt : GBinaryCodable {}
//	extension UInt8 : GBinaryCodable {}
//	extension UInt16 : GBinaryCodable {}
//	extension UInt32 : GBinaryCodable {}
//	extension UInt64 : GBinaryCodable {}
//	extension Float : GBinaryCodable {}
//	extension Double : GBinaryCodable {}
//	extension Bool : GBinaryCodable {}

extension String : GBinaryCodable {}

extension Array : GBinaryCodable where Element : NativeCodable {}
extension ContiguousArray : GBinaryCodable where Element : NativeCodable {}
extension Set : GBinaryCodable where Element : NativeCodable {}
extension Dictionary : GBinaryCodable where Key : NativeCodable, Value : NativeCodable {}


/*
extension RawRepresentable where Self.RawValue : GBinaryCodable {}
extension Range: GBinaryCodable where Bound: GBinaryCodable {}
extension ClosedRange: GBinaryCodable where Bound: GBinaryCodable {}
extension PartialRangeFrom: GBinaryCodable where Bound: GBinaryCodable {}
extension PartialRangeUpTo: GBinaryCodable where Bound: GBinaryCodable {}
extension PartialRangeThrough: GBinaryCodable where Bound: GBinaryCodable {}
extension CollectionDifference.Change : GBinaryCodable where ChangeElement : GBinaryCodable {}
extension CollectionDifference : GBinaryCodable where ChangeElement:GBinaryCodable {}

import Foundation

extension Data : GBinaryCodable {}
extension CGFloat : GBinaryCodable {}
extension CharacterSet : GBinaryCodable {}
extension AffineTransform : GBinaryCodable {}
extension Locale : GBinaryCodable {}
extension TimeZone : GBinaryCodable {}
extension UUID : GBinaryCodable  {}
extension Date : GBinaryCodable {}
extension IndexSet : GBinaryCodable {}
extension IndexPath : GBinaryCodable {}
extension CGSize : GBinaryCodable {}
extension CGPoint : GBinaryCodable {}
extension CGVector : GBinaryCodable {}
extension CGRect : GBinaryCodable {}
extension NSRange : GBinaryCodable {}
extension Decimal : GBinaryCodable {}
//	extension NSCalendar.Identifier : GBinaryCodable {} // Why?
extension Calendar : GBinaryCodable {}
extension DateComponents : GBinaryCodable {}
extension DateInterval : GBinaryCodable {}
extension PersonNameComponents : GBinaryCodable {}
extension URL : GBinaryCodable {}
extension URLComponents : GBinaryCodable {}
extension Measurement : GBinaryCodable {}
extension OperationQueue.SchedulerTimeType : GBinaryCodable {}
extension OperationQueue.SchedulerTimeType.Stride : GBinaryCodable {}
extension RunLoop.SchedulerTimeType : GBinaryCodable {}
extension RunLoop.SchedulerTimeType.Stride : GBinaryCodable {}

import simd

//	extension SIMDStorage where Scalar:GBinaryCodable {} // Why?
extension SIMD2:GBinaryCodable where Scalar:GBinaryCodable {}
extension SIMD3:GBinaryCodable where Scalar:GBinaryCodable {}
extension SIMD4:GBinaryCodable where Scalar:GBinaryCodable {}
extension SIMD8:GBinaryCodable where Scalar:GBinaryCodable {}
extension SIMD16:GBinaryCodable where Scalar:GBinaryCodable {}
extension SIMD32:GBinaryCodable where Scalar:GBinaryCodable {}
extension SIMD64:GBinaryCodable where Scalar:GBinaryCodable {}
//	extension SIMDMask:GBinaryCodable {} // Why?

import System

//	extension Errno : GBinaryCodable {}
//	extension FileDescriptor : GBinaryCodable {}
//	extension FileDescriptor.AccessMode : GBinaryCodable {}
//	extension FileDescriptor.OpenOptions : GBinaryCodable {}
//	extension FileDescriptor.SeekOrigin : GBinaryCodable {}
extension FilePath : GBinaryCodable {}
//	extension FilePermissions : GBinaryCodable {}

import UniformTypeIdentifiers

//	extension UTTagClass : GBinaryCodable {}
extension UTType : GBinaryCodable {}

import Dispatch

extension DispatchTime : GBinaryCodable {}
extension DispatchTimeInterval : GBinaryCodable {}
extension DispatchQueue.SchedulerTimeType : GBinaryCodable {}
extension DispatchQueue.SchedulerTimeType.Stride : GBinaryCodable {}
*/
