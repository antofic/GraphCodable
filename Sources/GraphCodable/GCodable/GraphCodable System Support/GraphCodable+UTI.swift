//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/

import UniformTypeIdentifiers

extension UTTagClass : GEncodable {}
extension UTTagClass : GDecodable {}

extension UTType {
	private enum Key : String { case identifier }
}

extension UTType : GEncodable {
	public func encode(to encoder: some GEncoder) throws {
		try encoder.encode(identifier, for: Key.identifier)
	}
}
extension UTType : GDecodable {
	public init(from decoder: some GDecoder) throws {
		let identifier = try decoder.decode(for: Key.identifier) as String
		
		guard let uttype = Self.init( identifier ) else {
			throw BinaryIOError.libDecodingError(
				Self.self, BinaryIOError.Context(
					debugDescription: "Invalid UTType identifier -\(identifier)-"
				)
			)
		}
		self = uttype
	}
}
