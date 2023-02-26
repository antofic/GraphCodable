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
/*
private func identifier( of value:GEncodable ) -> (any Hashable)? {
	if encodeOptions.contains( .disableGIdentifiableProtocol ) {
		if	encodeOptions.contains( .disableObjectIdentifierIdentity ) == false,
			let object = value as? (GEncodable & AnyObject) {
				return ObjectIdentifier( object )
		}
	} else {
		if let identifiable	= value as? any GIdentifiable {
			return identifiable.gID
		} else if
			encodeOptions.contains( .disableObjectIdentifierIdentity ) == false,
			let object = value as? (GEncodable & AnyObject) {
				  return ObjectIdentifier( object )
		  }
	}
	return nil
}
*/


// -------------------------------------------------
// ----- GraphEncoder - flags!
// -------------------------------------------------

extension GraphEncoder {
	public struct Options: OptionSet {
		public let rawValue: UInt
		
		public init(rawValue: UInt) {
			self.rawValue	= rawValue
		}
		
		///	Enable fast binary encoding/decoding for some library types
		///
		/// The BinaryIO library implements the BinaryIOType protocol for many system types.
		/// When this option is on, GraphCodable will store these types using the
		/// BinaryIOType protocol instead of the GCodable protocol.
		///	This makes storage faster but doesn't allow you to take full advantage of
		///	type identity.
		///
		/// - Note: This option is disabled by default
		public static let	enableLibraryBinaryIOTypes			= Self( rawValue: 1 << 0 )
		
		///	Disable the `GIdentifiable` protocol
		///
		/// By default, reference types have the automatic identity defined by
		/// `ObjectIdentifier(self)` and value types don't have an identity.
		/// If the type adopts the `GIdentifiable` protocol, its identity is defined by the
		/// `gID` property: if `gID` returns nil, the type has no identity even if it is
		/// a reference type.
		/// By activating this option, the encoder will ignore the `GIdentifiable` protocol.
		///
		/// - Note: This option is disabled by default
		public static let	disableGIdentifiableProtocol		= Self( rawValue: 1 << 1 )
		
		///	Disable the automatic reference type identity
		///
		/// By default, in GraphCodable reference types have the automatic identity
		/// defined by `ObjectIdentifier(self)` and value types don't have an identity.
		/// By activating this option, **even reference type don't receive an identity**.
		/// When this active option is active, reference types must adopt the
		/// `ObjectIdentifier(self)` protocol to define their identity.
		///
		/// - Note: This option is disabled by default
		public static let	disableObjectIdentifierIdentity		= Self( rawValue: 1 << 2 )

		public static let	onlyNativeTypes: Self 	= []
		public static let	defaultOption: Self 	= onlyNativeTypes
	}
}

extension GraphEncoder {
	public struct DumpOptions: OptionSet {
		public let rawValue: UInt
		
		public init(rawValue: UInt) {
			self.rawValue	= rawValue
		}
		
		///	show file header
		public static let	showHeader						= Self( rawValue: 1 << 0 )
		///	show file body
		public static let	showBody						= Self( rawValue: 1 << 1 )
		///	show file header
		public static let	showClassDataMap				= Self( rawValue: 1 << 2 )
		///	show file header
		public static let	showKeyStringMap				= Self( rawValue: 1 << 3 )
		///	indent the data
		public static let	indentLevel						= Self( rawValue: 1 << 4 )
		///	in the Body section, resolve typeIDs in typeNames, keyIDs in keyNames
		public static let	resolveIDs						= Self( rawValue: 1 << 5 )
		///	in the Body section, show type versions (they are in the ReferenceMap section)
		public static let	showReferenceVersion					= Self( rawValue: 1 << 6 )
		///	includes '=== SECTION TITLE =========================================='
		public static let	showSectionTitles				= Self( rawValue: 1 << 7 )
		///	disable truncation of too long nativeValues (over 48 characters - String or Data typically)
		public static let	noTruncation					= Self( rawValue: 1 << 8 )
		///	show typeName/NSStringFromClass name in ReferenceMap section
		public static let	showMangledClassNames			= Self( rawValue: 1 << 9 )
		
		public static let	displayNSStringFromClassNames: Self = [
			.showClassDataMap, .showMangledClassNames, .showSectionTitles
		]
		public static let	readable: Self = [
			.showBody, .indentLevel, .resolveIDs, .showSectionTitles
		]
		public static let	readableNoTruncation: Self = [
			.showHeader, .showBody, .indentLevel, .resolveIDs, .showSectionTitles, .noTruncation
		]
		public static let	binaryLike: Self = [
			.showHeader, .showClassDataMap, .showBody, .showKeyStringMap, .indentLevel, .showSectionTitles
		]
		public static let	binaryLikeNoTruncation: Self = [
			.showHeader, .showClassDataMap, .showBody, .showKeyStringMap, .indentLevel, .showSectionTitles, .noTruncation
		]
		public static let	fullInfo: Self = [
			.showHeader, .showClassDataMap, .showBody, .showKeyStringMap, .indentLevel, .resolveIDs, .showReferenceVersion, .showSectionTitles, .noTruncation
		]
	}
	
}



// -------------------------------------------------
// ----- GraphEncoder
// -------------------------------------------------

public final class GraphEncoder {
	private let encoder	: GEncoderImpl

	/// GraphEncoder init method
	public init( _ options: Options = .defaultOption ) {
		encoder	= GEncoderImpl( options )
	}

	///	Get/Set the userInfo dictionary
	public var userInfo : [String:Any] {
		get { encoder.userInfo }
		set { encoder.userInfo = newValue }
	}

	///	Encode the root value in a Data byte buffer
	///
	///	The root value must conform to the GEncodable protocol
	public func encode<T>( _ value: T ) throws -> Data where T:GEncodable {
		try encodeBytes( value )
	}

	///	Encode the root value in a generic byte buffer
	///
	///	The root value must conform to the GEncodable protocol
	public func encodeBytes<T,Q>( _ value: T ) throws -> Q where T:GEncodable, Q:MutableDataProtocol {
		try encoder.encodeRoot( value )
	}
	
	///	Creates a human-readable string of the data that would be generated by encoding the value
	///
	///	The root value must conform to the GEncodable protocol
	public func dump<T>( _ value: T, options: GraphEncoder.DumpOptions = .readable ) throws -> String where T:GEncodable {
		try encoder.dumpRoot( value, options:options )
	}
}


