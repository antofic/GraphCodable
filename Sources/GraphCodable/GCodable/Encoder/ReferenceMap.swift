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

struct ReferenceMap {
	private	var			currentId 		= RefID()
	private (set) var	classDataMap	= ClassDataMap()
	private var			identifierMap	= [ObjectIdentifier: RefID]()

	mutating func createRefIDIfNeeded<T>( for object:T ) throws -> RefID
	where T:AnyObject, T:GEncodable
	{
		let objIdentifier	= ObjectIdentifier( T.self )
		
		if let refID = identifierMap[ objIdentifier ] {
			return refID
		} else {
			defer { currentId = currentId.next }
			classDataMap[ currentId ]	= try ClassData( type: T.self )
			identifierMap[ objIdentifier ] = currentId
			return currentId
		}
	}
}
