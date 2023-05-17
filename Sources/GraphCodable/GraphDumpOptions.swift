//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

public struct GraphDumpOptions: OptionSet {
	public let rawValue: UInt
	
	public init(rawValue: UInt) {
		self.rawValue	= rawValue
	}
	
	// SECTIONS:
	///	show file header
	public static let	showHeader								= Self( rawValue: 1 << 0 )
	///	show help
	public static let	showHelp								= Self( rawValue: 1 << 1 )
	///	show body
	public static let	showBody								= Self( rawValue: 1 << 2 )
	///	show the flat body structure (DECODER DUMP ONLY)
	public static let	showFlatBody							= Self( rawValue: 1 << 3 )
	///	show reference map
	public static let	showReferenceMap						= Self( rawValue: 1 << 4 )
	///	show keyString map
	public static let	showKeyStringMap						= Self( rawValue: 1 << 5 )
	///	internal use only
	internal static let	hideKeyString							= Self( rawValue: 1 << 6 )

	// BODY/FLATBODY/REFERENCEMAP OPTIONS:
	///	show full qualified type names in Body/FlatBody/RefererenceMap section
	public static let	qualifiedTypeNames						= Self( rawValue: 1 << 15 )

	// BODY/FLATBODY OPTIONS:
	///	disable indentation in body/flatbody
	public static let	dontIndentBody							= Self( rawValue: 1 << 16 )
	///	in Body / Flattended Body section, show the qualified class name instead of the RefID
	public static let	showClassNamesInBody					= Self( rawValue: 1 << 17 )
	///	in Body / Flattended Body section, show the key string instead of the KeyID
	public static let	showKeyStringsInBody					= Self( rawValue: 1 << 18 )
	///	in the Body section, show type versions (they are in the ReferenceMap section)
	public static let	showClassVersionsInBody					= Self( rawValue: 1 << 19 )
	
	// BODY (only) OPTIONS FOR BINARYVALUES :
	///	show `GBinaryEncodable` value description (ENCODER DUMP ONLY)
	public static let	showBinaryValueDescriptionInBody		= Self( rawValue: 1 << 24 )
	///	show `GEncodable` but not value `GBinaryEncodable` description (ENCODER DUMP ONLY)
	///
	///	- Note: Since the description of the fields is printed, it is not usually
	///	necessary to activate this option.
	public static let	showNotBinaryValueDescriptionInBody		= Self( rawValue: 1 << 25 )
	///	value descriptions can be very large strings (example: a large int array)
	///	so the dump function by default truncate this description to 48 characters
	///	displaying ellipses (…).
	///	When showValueDescription in enablen, this option disable description
	///	truncation. (ENCODER DUMP ONLY)
	public static let	dontTruncateValueDescriptionInBody		= Self( rawValue: 1 << 26 )

	// REFERENCEMAP OPTIONS:
	///	show mangledClassName strings in RefererenceMap section
	public static let	showMangledClassNames					= Self( rawValue: 1 << 32 )


	// REFERENCEMAP OPTIONS (DECODER DUMP ONLY):
	public static let	onlyUndecodableClassesInReferenceMap	= Self( rawValue: 1 << 35 )
	
	// OTHER OPTIONS:
	///	disable '== SECTION TITLE =========================================='
	public static let	hideSectionTitles						= Self( rawValue: 1 << 40 )
	

	public static let	readable: Self = [
		.showBody, .showClassNamesInBody, .showKeyStringsInBody, .showBinaryValueDescriptionInBody
	]
	public static let	binaryLike: Self = [
		.showHeader, .showBody, .showReferenceMap, .showKeyStringMap
	]
	public static let	fullInfo: Self = [
		.readable, .showHeader, .showFlatBody, .showReferenceMap, .showKeyStringMap,
		.showClassVersionsInBody, .showFlatBody, .showBinaryValueDescriptionInBody,
		.qualifiedTypeNames,.showMangledClassNames
	]
	public static let	referenceMapOnly: Self = [
		.showReferenceMap,.showMangledClassNames
	]
}

