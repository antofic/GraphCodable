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

enum BinaryIOError : Error {
	struct Context {
		let debugDescription:	String
		let underlyingError:	Error?
		let function:			String
		let file:				String

		init(
			debugDescription: String,
			underlyingError: Error? = nil,
			function: String = #function,
			file: String = #fileID
		) {
			self.debugDescription	= debugDescription
			self.underlyingError	= underlyingError
			self.function			= function
			self.file				= file
		}
	}

	case notPODType( Any.Type, BinaryIOError.Context )
	case outOfBounds( Any.Type, BinaryIOError.Context )
	case prependingFails( Any.Type, BinaryIOError.Context )
	case initTypeError( Any.Type, BinaryIOError.Context )
	case versionError( Any.Type, BinaryIOError.Context )
}


