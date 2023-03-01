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

import Foundation

// -------------------------------------------------
// ----- KeyMap
// -------------------------------------------------

struct KeyMap  {
	private	var			currentId : UIntID	= 1000	// ATT! 0 reserved for unkeyed coding / 1-999 future use
	private (set) var	keyStringMap		= KeyStringMap()
	private var			inverseMap			= [String: UIntID]()
	
	mutating func createKeyIDIfNeeded( key:String ) -> UIntID {
		if let keyID = inverseMap[ key ] {
			return keyID
		} else {
			let keyID = currentId
			defer { currentId += 1 }
			inverseMap[ key ]	= keyID
			keyStringMap[ keyID ] = key
			return keyID
		}
	}
}