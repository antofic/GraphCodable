//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra


import UniformTypeIdentifiers

extension UTTagClass : BDecodable {}
extension UTTagClass : BEncodable {}

extension UTType : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( identifier )
	}
}
extension UTType : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		let identifier = try decoder.decode() as String
		
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


