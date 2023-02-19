#  GraphCodableTypes

## Swift Standard Library

### GCodable as NativeTypes
-	Int, Int8, Int16, Int32, Int64
	*note:* Int is always encoded as Int64
-	UInt, UInt8, UInt16, UInt32, UInt64
	*note:* UInt is always encoded as UInt64
-	Float, Double, CGFloat
	*note:* CGFloat is always encoded as Double
-	Bool
-	String

### GCodable as BinaryTypes
	** Using `GraphEncoder( .allBinaryTypes /* default */ )` the following types are encoded directly with BinaryIO (fast path). **
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

### GCodable
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



