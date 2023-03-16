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


extension Errno : BinaryIType {}
extension Errno : BinaryOType {}

extension FileDescriptor : BinaryIType {}
extension FileDescriptor : BinaryOType {}

extension FileDescriptor.AccessMode : BinaryIType {}
extension FileDescriptor.AccessMode : BinaryOType {}

extension FileDescriptor.OpenOptions : BinaryIType {}
extension FileDescriptor.OpenOptions : BinaryOType {}

extension FileDescriptor.SeekOrigin : BinaryIType {}
extension FileDescriptor.SeekOrigin : BinaryOType {}

extension FilePath : BinaryOType {
	public func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try description.write(to: &wbuffer)
	}
}
extension FilePath : BinaryIType {
	public init(from rbuffer: inout BinaryReadBuffer) throws {
		self.init( try String( from: &rbuffer ) )
	}
}

extension FilePermissions : BinaryIType {}
extension FilePermissions : BinaryOType {}

