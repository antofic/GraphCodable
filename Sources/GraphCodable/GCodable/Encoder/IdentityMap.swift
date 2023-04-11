//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

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

	init<T:Hashable>( _ id:T ) {
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
	 
	private struct WeakToStrongTable<IDE:Hashable> {
		private var	strongObjDict	= [IDE:IdnID]()
		private var	weakObjDict		= [IDE:IdnID]()

		func strongID( _ identifier: IDE ) -> IdnID? {
			strongObjDict[ identifier ]
		}

		mutating func createWeakID( _ identifier: IDE, actualId: inout IdnID ) -> IdnID {
			if let idnID = strongObjDict[ identifier ] {
				return idnID
			} else if let idnID = weakObjDict[ identifier ] {
				return idnID
			} else {
				defer { actualId = actualId.next }
				weakObjDict[ identifier ] = actualId
				return actualId
			}
		}
		
		mutating func createStrongID( _ identifier: IDE, actualId: inout IdnID ) -> IdnID {
			if let idnID = strongObjDict[ identifier ] {
				return idnID
			} else if let idnID = weakObjDict.removeValue(forKey: identifier) {
				// se è nel weak dict, lo prendo da lì
				// e lo metto nello strong dict
				strongObjDict[identifier] = idnID
				return idnID
			} else {
				defer { actualId = actualId.next }
				strongObjDict[identifier] = actualId
				return actualId
			}
		}
	}

	private	var actualId	= IdnID()
	private var	objTable	= WeakToStrongTable<ObjectIdentifier>()
	private var	boxTable	= WeakToStrongTable<HashableBox>()
	
	func strongID( for identity: Identity ) -> IdnID? {
		switch identity.id {
			case .objIdentifier( let id):	return objTable.strongID( id )
			case .anyHashable(let id): 		return boxTable.strongID( HashableBox(id) )
		}
	}
	
	mutating func createWeakID( for identity: Identity ) -> IdnID {
		switch identity.id {
			case .objIdentifier( let id):	return objTable.createWeakID( id, actualId:&actualId )
			case .anyHashable(let id): 		return boxTable.createWeakID( HashableBox(id), actualId:&actualId )
		}
	}
	
	mutating func createStrongID( for identity: Identity ) -> IdnID {
		switch identity.id {
			case .objIdentifier( let id):	return objTable.createStrongID( id, actualId:&actualId )
			case .anyHashable(let id): 		return boxTable.createStrongID( HashableBox(id), actualId:&actualId )
		}
	}
}

