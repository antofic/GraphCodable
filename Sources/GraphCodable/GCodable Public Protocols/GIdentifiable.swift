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

/// A class of types whose instances hold the value of an entity with stable
/// identity **over encoding/decoding**.

public protocol GIdentifiable<GID> {
	/// A type representing the stable identity **over encoding/decoding**
	/// of the entity associated with an instance.
	associatedtype GID : Hashable

	/// The stable identity **over encoding/decoding** of the entity associated
	/// with this instance.
	var gcodableID: Self.GID? { get }
}

extension GIdentifiable where Self:Identifiable {
	/// By default gcodableID == id.
	public var gcodableID: Self.ID? { id }
}


///	 If you want avoid duplications of Arrays and ContiguousArrays, please, define in your code
///	 theese two extensions.
///	 Note: works only with .onlyNativeTypes (default) option in GraphEncoder()
///
///	extension Array : GIdentifiable where Element:GCodable {
///		public var gcodableID: ObjectIdentifier? {
///			withUnsafeBytes { unsafeBitCast( $0.baseAddress, to: ObjectIdentifier?.self) }
///		}
///	}
///
///	extension ContiguousArray : GIdentifiable where Element:GCodable {
///		public var gcodableID: ObjectIdentifier? {
///			withUnsafeBytes { unsafeBitCast( $0.baseAddress, to: ObjectIdentifier?.self) }
///		}
///	}


