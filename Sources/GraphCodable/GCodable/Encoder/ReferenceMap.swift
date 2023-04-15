//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

struct ReferenceMap {
	private	var			currentId 		= RefID()
	private (set) var	encodedClassMap	= EncodedClassMap()
	private var			identifierMap	= [ObjectIdentifier: RefID]()

	mutating func createRefIDIfNeeded<T>( for object:T, manglingFunction:ManglingFunction ) throws -> RefID
	where T:AnyObject, T:GEncodable
	{
		let objIdentifier	= ObjectIdentifier( T.self )
		
		if let refID = identifierMap[ objIdentifier ] {
			return refID
		} else {
			defer { currentId = currentId.next }
			encodedClassMap[ currentId ]	= try EncodedClass( type:T.self, manglingFunction:manglingFunction )
			identifierMap[ objIdentifier ] = currentId
			return currentId
		}
	}
}
