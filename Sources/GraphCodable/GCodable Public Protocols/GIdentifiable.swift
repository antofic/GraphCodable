//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/

/// A class of types whose instances hold the value of an entity with stable
/// identity **over encoding/decoding**.
public protocol GIdentifiable<GID> {
	/// A type representing the stable identity **over encoding/decoding**
	/// of the entity associated with an instance.
	associatedtype GID : Hashable

	/// The stable identity **over encoding/decoding** of the entity associated
	/// with this instance.
	var gcodableID: GID? { get }
}
