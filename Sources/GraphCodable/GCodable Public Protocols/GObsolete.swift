//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/

/// A protocol for marking obsolete classes.
///
///  Use the `GDecodable` property `decodeType` to return the
///  replacement type
///
/// **See the UserGuide**.
public protocol GObsolete : GCodable {
}

/// dummy functions to satisfy the GCodable protocol
public extension GObsolete {
	init(from decoder: some GDecoder) throws {
		throw GraphCodableError.misuseOfGObsoleteProtocol(
			Self.self, GraphCodableError.Context(
				debugDescription: "The code must not go here: Self.decodeType must be different from Self."
			)
		)
	}

	func encode(to encoder: some GEncoder) throws {
		throw GraphCodableError.misuseOfGObsoleteProtocol(
			Self.self, GraphCodableError.Context(
				debugDescription: "You must not encode an obsolete type."
			)
		)
	}
}






