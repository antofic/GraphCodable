//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import System

extension Errno : GEncodable {}
extension Errno : GDecodable {}

extension FileDescriptor : GEncodable {}
extension FileDescriptor : GDecodable {}

extension FileDescriptor.AccessMode : GEncodable {}
extension FileDescriptor.AccessMode : GDecodable {}

extension FileDescriptor.OpenOptions : GEncodable {}
extension FileDescriptor.OpenOptions : GDecodable {}

extension FileDescriptor.SeekOrigin : GEncodable {}
extension FileDescriptor.SeekOrigin : GDecodable {}

extension FilePermissions : GEncodable {}
extension FilePermissions : GDecodable {}

extension FilePath {
	private enum Key : String { case path }
}

extension FilePath : GEncodable {
	public func encode(to encoder: some GEncoder) throws {
		try encoder.encode(description, for: Key.path)
	}
}
extension FilePath : GDecodable {
	public init(from decoder: some GDecoder) throws {
		self.init( try decoder.decode(for: Key.path) as String )
	}
}

