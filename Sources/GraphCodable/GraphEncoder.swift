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

import Foundation

///	An object that encodes instances of a **GEncodable** type
///	into a data buffer that uses **GraphCodable** format.
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

	///	Encode the root value in a generic byte buffer
	///
	///	The root value must conform to the GEncodable protocol
	public func encode<T,Q>( _ value: T ) throws -> Q where T:GEncodable, Q:MutableDataProtocol {
		try encoder.encodeRoot( value )
	}
	
	///	Creates a human-readable string of the data that would be generated by encoding the value
	///
	///	The root value must conform to the GEncodable protocol
	public func dump<T>( _ value: T, options: GraphDumpOptions = .readable ) throws -> String where T:GEncodable {
		try encoder.dumpRoot( value, options:options )
	}
}

// -------------------------------------------------
// ----- GraphEncoder.Options
// -------------------------------------------------

extension GraphEncoder {
	public struct Options: OptionSet {
		public let rawValue: UInt
		
		public init(rawValue: UInt) {
			self.rawValue	= rawValue
		}
		
		
		///	Enable printing of warnings
		///
		/// If this flag is enabled, the encoder doesn't generate an exception
		/// but print a warning if:
		/// - a value with no identity is conditionally encoded.
		/// The value is encoded unconditionally.
		/// - a reference type uses the versioning system. To use the versioning
		/// system, the reference type must have identity.
		///
		/// - Note: This option is auto-enabled if DEBUG is active.
		public static let	printWarnings										= Self( rawValue: 1 << 0 )
		///	Ignore the `GIdentifiable` protocol
		///
		/// By default, reference types have the automatic identity defined by
		/// `ObjectIdentifier(self)` and value types don't have an identity.
		/// If the type adopts the `GIdentifiable` protocol, its identity is defined by the
		/// `gcodableID` property: if `gcodableID` returns nil, the type has no identity
		/// even if it is a reference type.
		/// By activating this option, the encoder will ignore the `GIdentifiable` protocol
		/// and values that adopt this protocol act as they have not adopted it.
		///
		/// - Note: This option is disabled by default
		public static let	ignoreGIdentifiableProtocol							= Self( rawValue: 1 << 1 )

		///	Ignore the `GInheritance` protocol
		///
		/// By activating this option, the encoder will ignore the `GInheritance` protocol
		/// and values that adopt this protocol act as they have not adopted it.
		///
		/// - Note: This option is disabled by default
		public static let	ignoreGInheritanceProtocol							= Self( rawValue: 1 << 2 )
		
		///	Disable the automatic reference type identity
		///
		/// By default, in GraphCodable reference types have the automatic identity
		/// defined by `ObjectIdentifier(self)` and value types don't have an identity.
		/// By activating this option, **even reference type don't receive an identity**.
		/// When this active option is active, reference types must adopt the
		/// `ObjectIdentifier(self)` protocol to define their identity.
		///
		/// - Note: This option is disabled by default
		public static let	disableAutoObjectIdentifierIdentityForReferences	= Self( rawValue: 1 << 3 )

		///	Disable identity
		///
		/// All types will be encoded with no identity regardless of how they are defined.
		///
		/// - Note: This option is disabled by default
		public static let	disableIdentity										= Self( rawValue: 1 << 4 )
		
		///	Disable inheritance
		///
		/// All reference types will be encoded with no class name info's.
		///
		/// - Note: This option is disabled by default
		public static let	disableInheritance									= Self( rawValue: 1 << 5 )

		///	Resort to hashable identity
		///
		/// If .disableIdentity == false, uses immediately the value as identity.
		///
		/// - Note: This option is disabled by default
		/// - Note: The option can be expensive in certain situations
		public static let	tryHashableIdentityAtFirst							= Self( rawValue: 1 << 6 )
		///	Resort to hashable identity if any other fails
		///
		/// If .disableIdentity == false, any other tentative to aquire an identity
		/// has failed, the value is Hashable, uses the value as identity.
		///
		/// - Note: This option is disabled by default
		/// - Note: The option can be expensive in certain situations
		public static let	tryHashableIdentityAtLast							= Self( rawValue: 1 << 7 )
		
		public static let	mimicSwiftCodable:				Self 	= [ disableIdentity, disableInheritance ]
		public static let	defaultOption:					Self 	= []
	}
}

