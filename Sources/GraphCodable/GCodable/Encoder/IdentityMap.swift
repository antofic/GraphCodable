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

// optimized for the most common case: ObjectIdentifier
struct Identity {
	fileprivate enum ID {
		case objIdentifier( ObjectIdentifier )
		case anyHashable( any Hashable )
	}
	fileprivate let id : ID
	
	init( _ id:ObjectIdentifier ) {
		self.id = ID.objIdentifier(id)
	}
	
	init( _ id:any Hashable ) {
		// make sure you get all the ObjectIdentifier's
		if let id = id as? ObjectIdentifier {
			self.id = ID.objIdentifier( id )
		} else {
			self.id = ID.anyHashable( id )
		}
	}
}

// optimized for the most common case: ObjectIdentifier
struct IdentityMap {
	private struct HashableBox : Hashable {
		private let value : any Hashable
		
		init( _ value: any Hashable ) {
			self.value	= value
		}
		
		private static func equal<T,Q>( lhs: T, rhs: Q ) -> Bool where T:Equatable, Q:Equatable {
			guard let rhs = rhs as? T else { return false }
			return lhs == rhs
		}
		
		static func == (lhs: Self, rhs: Self) -> Bool {
			return equal(lhs: lhs.value, rhs: rhs.value)
		}
		
		func hash(into hasher: inout Hasher) {
			hasher.combine( ObjectIdentifier( type( of:value ) ) )
			hasher.combine( value )
		}
	}
	
	private struct TwoTables<IDE:Hashable> {
		private var	strongObjDict	= [IDE:ObjID]()
		private var	weakObjDict		= [IDE:ObjID]()
		
		func strongID( _ identifier: IDE ) -> ObjID? {
			strongObjDict[ identifier ]
		}
		
		mutating func createWeakID( _ identifier: IDE, actualId: inout ObjID ) -> ObjID {
			if let objID = weakObjDict[ identifier ] {
				return objID
			} else {
				defer { actualId = actualId.next }
				weakObjDict[ identifier ] = actualId
				return actualId
			}
		}
		
		mutating func createStrongID( _ identifier: IDE, actualId: inout ObjID ) -> ObjID {
			if let objID = strongObjDict[ identifier ] {
				return objID
			} else if let objID = weakObjDict.removeValue(forKey: identifier) {
				// se è nel weak dict, lo prendo da lì
				// e lo metto nello strong dict
				strongObjDict[identifier] = objID
				return objID
			} else {
				defer { actualId = actualId.next }
				strongObjDict[identifier] = actualId
				return actualId
			}
		}
	}

	private	var actualId	= ObjID()
	private var	objTable	= TwoTables<ObjectIdentifier>()
	private var	boxTable	= TwoTables<HashableBox>()
	
	func strongID( _ identity: Identity ) -> ObjID? {
		switch identity.id {
			case .objIdentifier( let id):	return objTable.strongID( id )
			case .anyHashable(let id): 		return boxTable.strongID( HashableBox(id) )
		}
	}
	
	mutating func createWeakID( _ identity: Identity ) -> ObjID {
		switch identity.id {
			case .objIdentifier( let id):	return objTable.createWeakID( id, actualId:&actualId )
			case .anyHashable(let id): 		return boxTable.createWeakID( HashableBox(id), actualId:&actualId )
		}
	}
	
	mutating func createStrongID( _ identity: Identity ) -> ObjID {
		switch identity.id {
			case .objIdentifier( let id):	return objTable.createStrongID( id, actualId:&actualId )
			case .anyHashable(let id): 		return boxTable.createStrongID( HashableBox(id), actualId:&actualId )
		}
	}
}

