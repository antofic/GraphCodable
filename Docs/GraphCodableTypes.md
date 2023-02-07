#  GraphCodableTypes

## Swift Standard Library

### GCodable as NativeTypes
-	Int, Int8, Int16, Int32, Int64
	*note:* Int is always encoded as Int64
-	UInt, UInt8, UInt16, UInt32, UInt64
	*note:* UInt is always encoded as UInt64
-	Float, Double, CGFloat
-	Bool
-	String
-	Data
-	Optional (*)
-	Array, ContiguousArray, Set, Dictionary (*)
-	Range, ClosedRange, PartialRangeFrom, PartialRangeUpTo, PartialRangeThrough (*)
-	RawRepresentable types (enum, OptionSet) (*)

(*) If the contained types are NativeTypes/BinaryTypes

### GCodable as BinaryTypes
	** Only when encoding with: GraphEncoder( .allBinaryTypes /* default */ ) **
-	Optional (*)
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

(*) If the contained types are NativeTypes/BinaryTypes

### GCodable
	** When encoding with: GraphEncoder( .onlyNativeTypes ) **	
-	Optional (*)
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
(*) If the contained types are GCodable


