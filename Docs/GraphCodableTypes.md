#  GraphCodableTypes

## Swift Standard Library

### GCodable as NativeIOTypes
-	Int, Int8, Int16, Int32, Int64
	*note:* Int is always encoded as Int64
-	UInt, UInt8, UInt16, UInt32, UInt64
	*note:* UInt is always encoded as Int64
-	Float, Double
-	Bool
-	String, Character
-	Data
-	Optional (*)
-	Array, ContiguousArray, Set, Dictionary (*)
-	Range, ClosedRange, PartialRangeFrom, PartialRangeUpTo, PartialRangeThrough (*)
-	RawRepresentable types (enum, OptionSet) (*)
	
(*) If the contained types are NativeIOTypes

### GCodable
-	Optional (*)
-	Array, ContiguousArray, Set, Dictionary (*)
-	Range, ClosedRange, PartialRangeFrom, PartialRangeUpTo, PartialRangeThrough (*)
-	RawRepresentable types (enum, OptionSet) (*)

(*) If the contained types are GCodable

### Unsupported
Where is the list of all "Apple Codable" types from the standard library?

## Foundation
Almost all "Apple Codable" foundation types are GCodable, too.

### GCodable as NativeIOTypes
-	CGFloat
	*note:* CGFloat is always encoded as Double
-	CharacterSet
-	AffineTransform
-	Locale
-	TimeZone
-	UUID
-	Date
-	IndexSet
-	CGSize
-	CGPoint
-	CGVector
-	CGRect
-	NSRange
-	Decimal

### CGCodable
-	Calendar
-	DateComponents
-	DateInterval
-	PersonNameComponents
-	URL
-	URLComponents

### Unsupported
-	IndexPath
	*reason:* inaccessible underlying storage.



