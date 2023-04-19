//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

struct KeyMap  {
	private	var			currentId		= KeyID()
	private (set) var	keyStringMap	= KeyStringMap()
	private var			inverseMap		= [String: KeyID]()
	
	mutating func createKeyIDIfNeeded( for key:String ) -> KeyID {
		if let keyID = inverseMap[ key ] {
			return keyID
		} else {
			defer { currentId = currentId.next }
			inverseMap[ key ]	= currentId
			keyStringMap[ currentId ] = key
			return currentId
		}
	}
}
