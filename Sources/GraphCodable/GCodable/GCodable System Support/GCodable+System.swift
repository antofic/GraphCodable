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

import System

extension Errno : GCodable {}
extension FileDescriptor : GCodable {}
extension FileDescriptor.AccessMode : GCodable {}
extension FileDescriptor.OpenOptions : GCodable {}
extension FileDescriptor.SeekOrigin : GCodable {}
extension FilePermissions : GCodable {}

extension FilePath : GCodable {
	private enum Key : String { case path }

	public func encode(to encoder: GEncoder) throws {
		try encoder.encode(description, for: Key.path)
	}
	
	public init(from decoder: GDecoder) throws {
		self.init( try decoder.decode(for: Key.path) as String )
	}
}

//	extension FilePath : GBinaryCodable {}

