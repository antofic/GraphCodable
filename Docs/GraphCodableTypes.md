#  GraphCodableTypes
This is the list of types that GraphCodable is capable of automatically archiving/unarchiving.
GraphCodable relies on an internal package (BinaryIO) to archive/dearchive data in binary format.

That said, NativeTypes are the system types that are always encoded/decoded directly by BinaryIO.
Additional types (BinaryTypes) can be stored directly by BinaryIO using the `GraphEncoder( .allBinaryTypes )` option.
This option very often makes archiving/dearchiving much faster but, if used, it bypasses the identity of types Array and ContiguousArray (if their elements are BCodable) if they were defined in your code and thus does not prevent their duplication.
If instead the `GraphEncoder( .onlyNativeTypes )` option is used, only the NativeTypes will be encoded/decoded directly in binary and the other types in the list will be stored with standard GCodable methods.

To define identity and avoid duplications of Arrays and ContiguousArrays, copy/paste in your code
these two extensions.
```swift
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
```
## GCodable as NativeTypes
-	Int, Int8, Int16, Int32, Int64
	*note:* Int is always encoded as Int64
-	UInt, UInt8, UInt16, UInt32, UInt64
	*note:* UInt is always encoded as UInt64
-	Float, Double, CGFloat
	*note:* CGFloat is always encoded as Double
-	Bool
-	String

## GCodable as BinaryTypes
	** Using `GraphEncoder( .allBinaryTypes )` the following types are encoded directly with BinaryIO (fast path). **
	It is assumed that the format of these types can no longer change.
-	Data
-	Array, ContiguousArray, Set, Dictionary (*)
-	Range, ClosedRange, PartialRangeFrom, PartialRangeUpTo, PartialRangeThrough (*)
-	RawRepresentable types (enum, OptionSet) (*)
-	CollectionDifference.Change, CollectionDifference (*)
-	CharacterSet, AffineTransform, Locale, TimeZone, UUID, Date
-	IndexSet, IndexPath, CGSize, CGPoint, CGVector, CGRect, NSRange
-	Decimal, Calendar, DateComponents, DateInterval, PersonNameComponents
-	URL, URLComponents, Measurement
-	OperationQueue.SchedulerTimeType, OperationQueue.SchedulerTimeType.Stride
-	RunLoop.SchedulerTimeType, RunLoop.SchedulerTimeType.Stride
-	DispatchTime, DispatchTimeInterval
-	DispatchQueue.SchedulerTimeType, DispatchQueue.SchedulerTimeType.Stride
-	Errno
-	FileDescriptor, FileDescriptor.AccessMode, FileDescriptor.OpenOptions, FileDescriptor.SeekOrigin
-	FilePath, FilePermissions
-	UTTagClass, UTType
-	SIMD2...64, SIMDMask, SIMDStorage, simd_floatAxB, simd_doubleAxB

(*) If the contained types are NativeTypes or BinaryTypes

## GCodable
	** Using `GraphEncoder( .onlyNativeTypes )` the following types are encoded with general GCodable methods (slow path). **
-	Data
-	Array, ContiguousArray, Set, Dictionary (*)
-	Range, ClosedRange, PartialRangeFrom, PartialRangeUpTo, PartialRangeThrough (*)
-	RawRepresentable types (enum, OptionSet) (*)
-	CollectionDifference.Change, CollectionDifference (*)
-	CharacterSet, AffineTransform, Locale, TimeZone, UUID, Date
-	IndexSet, IndexPath, CGSize, CGPoint, CGVector, CGRect, NSRange
-	Decimal, Calendar, DateComponents, DateInterval, PersonNameComponents
-	URL, URLComponents, Measurement
-	OperationQueue.SchedulerTimeType, OperationQueue.SchedulerTimeType.Stride
-	RunLoop.SchedulerTimeType, RunLoop.SchedulerTimeType.Stride
-	DispatchTime, DispatchTimeInterval
-	DispatchQueue.SchedulerTimeType, DispatchQueue.SchedulerTimeType.Stride
-	Errno
-	FileDescriptor, FileDescriptor.AccessMode, FileDescriptor.OpenOptions, FileDescriptor.SeekOrigin
-	FilePath, FilePermissions
-	UTTagClass, UTType
-	SIMD2...64, SIMDMask, SIMDStorage, simd_floatAxB, simd_doubleAxB

(*) If the contained types are GCodable



