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

struct AnyIdentifierMap {
	private struct Key : Hashable {
		private let identifier : any Hashable
		
		init( _ identifier: any Hashable ) {
			self.identifier		= identifier
		}
		
		private static func equal<T,Q>( lhs: T, rhs: Q ) -> Bool where T:Equatable, Q:Equatable {
			guard let rhs = rhs as? T else { return false }
			return lhs == rhs
		}
		
		static func == (lhs: Self, rhs: Self) -> Bool {
			return equal(lhs: lhs.identifier, rhs: rhs.identifier)
		}
		
		func hash(into hasher: inout Hasher) {
			hasher.combine( ObjectIdentifier( type( of:identifier) ) )
			hasher.combine( identifier )
		}
	}
	
	private	var actualId : UIntID	= 1000	// <1000 reserved for future use
	private var	strongObjDict		= [Key:UIntID]()
	private var	weakObjDict			= [Key:UIntID]()
	
	func strongID<T:Hashable>( _ identifier: T ) -> UIntID? {
		strongObjDict[ Key(identifier) ]
	}
	
	mutating func createWeakID<T:Hashable>( _ identifier: T ) -> UIntID {
		let box	= Key(identifier)
		if let objID = weakObjDict[ box ] {
			return objID
		} else {
			let objID = actualId
			defer { actualId += 1 }
			weakObjDict[ box ] = objID
			return objID
		}
	}
	
	mutating func createStrongID<T:Hashable>( _ identifier: T ) -> UIntID {
		let key	= Key(identifier)
		if let objID = strongObjDict[ key ] {
			return objID
		} else if let objID = weakObjDict[key] {
			// se è nel weak dict, lo prendo da lì
			weakObjDict.removeValue(forKey: key)
			// e lo metto nello strong dict
			strongObjDict[key] = objID
			return objID
		} else {
			// altrimenti creo uno nuovo
			let objID = actualId
			defer { actualId += 1 }
			strongObjDict[key] = objID
			return objID
		}
	}
}

/* THE STANDARD WAY IS SLOWER: *//*
fileprivate struct AnyIdentifierMap {
	private	var actualId : UIntID	= 1000	// <1000 reserved for future use
	private var	strongObjDict		= [AnyHashable:UIntID]()
	private var	weakObjDict			= [AnyHashable:UIntID]()
	
	func strongID<T:Hashable>( _ identifier: T ) -> UIntID? {
		strongObjDict[ identifier ]
	}
	
	mutating func createWeakID<T:Hashable>( _ identifier: T ) -> UIntID {
		if let objID = weakObjDict[ identifier ] {
			return objID
		} else {
			let objID = actualId
			defer { actualId += 1 }
			weakObjDict[ identifier ] = objID
			return objID
		}
	}
	
	mutating func createStrongID<T:Hashable>( _ identifier: T ) -> UIntID {
		if let objID = strongObjDict[ identifier ] {
			return objID
		} else if let objID = weakObjDict[identifier] {
			// se è nel weak dict, lo prendo da lì
			weakObjDict.removeValue(forKey: identifier)
			// e lo metto nello strong dict
			strongObjDict[identifier] = objID
			return objID
		} else {
			// altrimenti creo uno nuovo
			let objID = actualId
			defer { actualId += 1 }
			strongObjDict[identifier] = objID
			return objID
		}
	}
}
*/
