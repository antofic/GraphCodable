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

import Foundation

// -------------------------------------------------
// ----- GraphDumpOptions
// -------------------------------------------------

public struct GraphDumpOptions: OptionSet {
	public let rawValue: UInt
	
	public init(rawValue: UInt) {
		self.rawValue	= rawValue
	}
	
	///	show file header
	public static let	showHeader						= Self( rawValue: 1 << 0 )
	///	show file body
	public static let	hideBody						= Self( rawValue: 1 << 1 )
	///	show file header
	public static let	showClassDataMap				= Self( rawValue: 1 << 2 )
	///	show file header
	public static let	showKeyStringMap				= Self( rawValue: 1 << 3 )
	///	indent the data
	public static let	dontIndentLevel					= Self( rawValue: 1 << 4 )
	///	in Body / Flattended Body section, resolve typeIDs in typeNames
	public static let	resolveTypeIDs					= Self( rawValue: 1 << 5 )
	///	in Body / Flattended Body section, resolve keyIDs in keyNames
	public static let	resolveKeyIDs					= Self( rawValue: 1 << 6 )
	///	in the Body section, show type versions (they are in the ReferenceMap section)
	public static let	showReferenceVersion			= Self( rawValue: 1 << 7 )
	///	includes '=== SECTION TITLE =========================================='
	public static let	hideSectionTitles				= Self( rawValue: 1 << 8 )
	///	disable truncation of too long nativeValues (over 48 characters - String or Data typically)
	public static let	noTruncation					= Self( rawValue: 1 << 9 )
	///	show mangledTypeNames/NSStringFromClass name in ReferenceMap section
	public static let	showMangledClassNames			= Self( rawValue: 1 << 10 )
	///	show the flattened body structure (Decoder dump only)
	public static let	showDecodedFlattenedBody		= Self( rawValue: 1 << 11 )

	public static let	showOnlyMangledClassNames: Self = [
		.hideBody, .showClassDataMap, .showMangledClassNames,
	]
	public static let	readable: Self = [
		.resolveTypeIDs, .resolveKeyIDs
	]
	public static let	readableNoTruncation: Self = [
		.showHeader, .readable, .noTruncation
	]
	public static let	binaryLike: Self = [
		.showHeader, .showClassDataMap, .showKeyStringMap
	]
	public static let	binaryLikeNoTruncation: Self = [
		.showHeader, .showClassDataMap, .showKeyStringMap, .noTruncation
	]
	public static let	fullInfo: Self = [
		.showHeader, .showClassDataMap, .showKeyStringMap, .readable, .showReferenceVersion, .showDecodedFlattenedBody
	]
	public static let	fullInfoNoTruncation: Self = [
		.showHeader, .showClassDataMap, .showKeyStringMap, .readable, .noTruncation, .showReferenceVersion, .showDecodedFlattenedBody
	]
}

