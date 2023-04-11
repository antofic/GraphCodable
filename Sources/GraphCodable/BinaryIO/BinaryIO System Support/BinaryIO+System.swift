//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra



import System


extension Errno : BEncodable {}
extension Errno : BDecodable {}

extension FileDescriptor : BEncodable {}
extension FileDescriptor : BDecodable {}

extension FileDescriptor.AccessMode : BEncodable {}
extension FileDescriptor.AccessMode : BDecodable {}

extension FileDescriptor.OpenOptions : BEncodable {}
extension FileDescriptor.OpenOptions : BDecodable {}

extension FileDescriptor.SeekOrigin : BEncodable {}
extension FileDescriptor.SeekOrigin : BDecodable {}

extension FilePermissions : BEncodable {}
extension FilePermissions : BDecodable {}


extension FilePath : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self.init( try decoder.decode() )
	}
}
extension FilePath : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( description )
	}
}

