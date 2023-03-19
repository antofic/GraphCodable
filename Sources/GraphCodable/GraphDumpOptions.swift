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
	///	show the flattened body structure (DECODER DUMP ONLY)
	public static let	showFlattenedBody						= Self( rawValue: 1 << 3 )
	///	show reference map
	public static let	showReferenceMap						= Self( rawValue: 1 << 4 )
	///	show keyString map
	public static let	showKeyStringMap						= Self( rawValue: 1 << 5 )
	///	show construction map (DECODER DUMP ONLY)
	public static let	showConstructionMap						= Self( rawValue: 1 << 6 )
	
	// BODY/FLATTENEDBODY OPTIONS:
	///	disable indentation in body
	public static let	dontIndentBody							= Self( rawValue: 1 << 16 )
	///	in Body / Flattended Body section, show the qualified class name instead of the TypeID
	public static let	showClassNamesInBody					= Self( rawValue: 1 << 17 )
	///	in Body / Flattended Body section, show the key string instead of the KeyID
	public static let	showKeyStringsInBody					= Self( rawValue: 1 << 18 )
	///	in the Body section, show type versions (they are in the ReferenceMap section)
	public static let	showClassVersionsInBody					= Self( rawValue: 1 << 19 )
	
	// BODY (only) OPTIONS FOR BINARYVALUES :
	///	show value description (ENCODER DUMP ONLY)
	public static let	showValueDescriptionInBody				= Self( rawValue: 1 << 24 )
	///	value descriptions can be very large strings (example: a large int array)
	///	so the dump function by default truncate this description to 48 characters
	///	displaying ellipses (…).
	///	When showValueDescription in enablen, this option disable description
	///	truncation. (ENCODER DUMP ONLY)
	public static let	dontTruncateValueDescriptionInBody		= Self( rawValue: 1 << 25 )

	// REFERENCEMAP/CONSTRUCTIONMAP OPTIONS:
	///	show mangledName/nsClassName in ReferenceMap/Instantiations
	public static let	showMangledNames						= Self( rawValue: 1 << 32 )

	// CONSTRUCTIONMAP OPTIONS:
	///	if disabled, unqualified type names will be shown when possible
	public static let	qualifiedNamesInConstructionMap			= Self( rawValue: 1 << 33 )
	public static let	hideTypeIDsInConstructionMap			= Self( rawValue: 1 << 34 )
	public static let	onlyUndecodableClassesInConstructionMap	= Self( rawValue: 1 << 35 )
	
	// OTHER OPTIONS:
	///	disable '== SECTION TITLE =========================================='
	public static let	hideSectionTitles						= Self( rawValue: 1 << 40 )
	

	public static let	readable: Self = [
		.showBody, .showClassNamesInBody, .showKeyStringsInBody, .showValueDescriptionInBody
	]
	public static let	binaryLike: Self = [
		.showHeader, .showBody, .showReferenceMap, .showKeyStringMap
	]
	public static let	fullInfo: Self = [
		.readable, .showHeader, .showFlattenedBody, .showReferenceMap, .showKeyStringMap,
		.showClassVersionsInBody, .showFlattenedBody, .showValueDescriptionInBody
	]
	public static let	referenceMapOnly: Self = [
		.showReferenceMap,.showMangledNames
	]
}

