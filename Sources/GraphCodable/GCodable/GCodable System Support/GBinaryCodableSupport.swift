//
//  File.swift
//  
//
//  Created by Antonino Ficarra on 01/03/23.
//

import Foundation

extension Int		: GTrivialCodable {}
extension Int8		: GTrivialCodable {}
extension Int16		: GTrivialCodable {}
extension Int32		: GTrivialCodable {}
extension Int64		: GTrivialCodable {}
extension UInt		: GTrivialCodable {}
extension UInt8		: GTrivialCodable {}
extension UInt16	: GTrivialCodable {}
extension UInt32	: GTrivialCodable {}
extension UInt64	: GTrivialCodable {}

// -- BinaryFloatingPoint support -------------------------------------------------------
extension Float		: GTrivialCodable {}
extension Double	: GTrivialCodable {}
extension CGFloat	: GTrivialCodable {}

// -- Bool support -------------------------------------------------------
extension Bool 		: GTrivialCodable {}

extension String : GBinaryCodable {}
extension Array : GBinaryCodable where Element : GTrivialCodable {}
extension ContiguousArray : GBinaryCodable where Element : GTrivialCodable {}
extension Set : GBinaryCodable where Element : GTrivialCodable {}
extension Dictionary : GBinaryCodable where Key : GTrivialCodable, Value : GTrivialCodable {}

extension RawRepresentable where Self.RawValue : GBinaryCodable {}

extension Range: GTrivialCodable where Bound: GTrivialCodable {}
extension ClosedRange: GTrivialCodable where Bound: GTrivialCodable {}
extension PartialRangeFrom: GTrivialCodable where Bound: GTrivialCodable {}
extension PartialRangeUpTo: GTrivialCodable where Bound: GTrivialCodable {}
extension PartialRangeThrough: GTrivialCodable where Bound: GTrivialCodable {}

extension CollectionDifference.Change : GBinaryCodable where ChangeElement : GBinaryCodable {}
extension CollectionDifference : GBinaryCodable where ChangeElement:GBinaryCodable {}

import Foundation

extension Data : GBinaryCodable {}
extension CharacterSet : GBinaryCodable {}
extension AffineTransform : GTrivialCodable {}

extension Locale : GBinaryCodable {}
extension TimeZone : GBinaryCodable {}
extension UUID : GTrivialCodable  {}


extension Date : GTrivialCodable {}
extension IndexSet : GBinaryCodable {}
extension IndexPath : GBinaryCodable {}
extension CGSize : GTrivialCodable {}
extension CGPoint : GTrivialCodable {}
extension CGVector : GTrivialCodable {}
extension CGRect : GTrivialCodable {}
extension NSRange : GTrivialCodable {}
extension Decimal : GTrivialCodable {}
// extension NSCalendar.Identifier : GBinaryCodable {} // Why?
extension Calendar : GBinaryCodable {}
extension DateComponents : GBinaryCodable {}
extension DateInterval : GTrivialCodable {}
extension PersonNameComponents : GBinaryCodable {}
extension URL : GBinaryCodable {}
extension URLComponents : GBinaryCodable {}
extension Measurement : GBinaryCodable {}
extension OperationQueue.SchedulerTimeType : GTrivialCodable {}
extension OperationQueue.SchedulerTimeType.Stride : GTrivialCodable {}
extension RunLoop.SchedulerTimeType : GTrivialCodable {}
extension RunLoop.SchedulerTimeType.Stride : GTrivialCodable {}

import simd

//	extension SIMDStorage where Scalar:GBinaryCodable {} // Why?
//	extension SIMDMask:GBinaryCodable {} // Why?


//	extension SIMD2:GBinaryCodable where Scalar:GBinaryCodable {}
//	extension SIMD3:GBinaryCodable where Scalar:GBinaryCodable {}
//	extension SIMD4:GBinaryCodable where Scalar:GBinaryCodable {}
//	extension SIMD8:GBinaryCodable where Scalar:GBinaryCodable {}
//	extension SIMD16:GBinaryCodable where Scalar:GBinaryCodable {}
//	extension SIMD32:GBinaryCodable where Scalar:GBinaryCodable {}
//	extension SIMD64:GBinaryCodable where Scalar:GBinaryCodable {}

//	extension SIMD2: GTrivial {}
//	extension SIMD3: GTrivial {}
//	extension SIMD4: GTrivial {}
//	extension SIMD8: GTrivial {}
//	extension SIMD16: GTrivial {}
//	extension SIMD32: GTrivial {}
//	extension SIMD64: GTrivial {}

// extension SIMD2:GTrivialCodable where Scalar:GTrivialCodable {}
// extension SIMD3:GTrivialCodable where Scalar:GTrivialCodable {}
// extension SIMD4:GTrivialCodable where Scalar:GTrivialCodable {}
// extension SIMD8:GTrivialCodable where Scalar:GTrivialCodable {}
// extension SIMD16:GTrivialCodable where Scalar:GTrivialCodable {}
// extension SIMD32:GTrivialCodable where Scalar:GTrivialCodable {}
// extension SIMD64:GTrivialCodable where Scalar:GTrivialCodable {}






import System

//	extension Errno : GTrivialCodable {}
//	extension FileDescriptor : GTrivialCodable {}
//	extension FileDescriptor.AccessMode : GTrivialCodable {}
//	extension FileDescriptor.OpenOptions : GTrivialCodable {}
//	extension FileDescriptor.SeekOrigin : GTrivialCodable {}
//	extension FilePath : GBinaryCodable {}
//	extension FilePermissions : GTrivialCodable {}



import UniformTypeIdentifiers

//	extension UTTagClass : GBinaryCodable {}
//	extension UTType : GBinaryCodable {}


import Dispatch

extension DispatchTime : GTrivialCodable {}
extension DispatchTimeInterval : GTrivialCodable {}
extension DispatchQueue.SchedulerTimeType : GTrivialCodable {}
extension DispatchQueue.SchedulerTimeType.Stride : GTrivialCodable {}

