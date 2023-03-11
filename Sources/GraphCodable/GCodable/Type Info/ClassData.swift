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

import Foundation

/*
public enum ClassName : Hashable {
	case qualifiedName( _:String )
	case mangledName( _:String )
	case nsClassName( _:String )
}
*/

struct ClassData : BinaryIOType, CustomStringConvertible {
	let	qualifiedName:	String	// the TypeName Generated _typeName( type, qualified:true )
	let	mangledName:	String	// the TypeName Generated _mangledTypeName( type )
	let	encodedVersion:	UInt32
	
	func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try qualifiedName.write(to: &wbuffer)
		try mangledName.write(to: &wbuffer)
		try encodedVersion.write(to: &wbuffer)
	}
	
	init(from rbuffer: inout BinaryReadBuffer) throws {
		self.qualifiedName	= try String( from: &rbuffer )
		self.mangledName	= try String( from: &rbuffer )
		self.encodedVersion	= try UInt32( from: &rbuffer )
	}
	
	static private func constructType( mangledName:String ) -> AnyClass? {
		//	_typeByName( mangledTypeName ) is faster than NSClassFromString( objcTypeName )
		return _typeByName( mangledName ) as? AnyClass ?? nil
	}
	
	init( type:(AnyObject & GEncodable).Type ) throws {
		self.qualifiedName	= _typeName( type, qualified:true )
		guard
			let mangledName = _mangledTypeName( type ),
			Self.constructType( mangledName:mangledName ) != nil else {
			throw GCodableError.cantConstructClass(
				Self.self, GCodableError.Context(
					debugDescription:"The class -\(qualifiedName)- can't be constructed."
				)
			)
		}

		self.mangledName 	= mangledName
		self.encodedVersion	= (type as? GVersion.Type)?.encodeVersion ?? 0
	}
	
	static func isConstructible( type:AnyObject.Type ) -> Bool {
		if let mangledName = _mangledTypeName( type ),
		   Self.constructType( mangledName:mangledName ) != nil {
			return true
		}
		return false
	}
	
	static func throwIfNotConstructible( type:AnyObject.Type ) throws {
		guard isConstructible( type:type ) else {
			throw GCodableError.cantConstructClass(
				Self.self, GCodableError.Context(
					debugDescription:"The class -\( _typeName( type, qualified:true ) )- can't be constructed."
				)
			)
		}
	}
	
	private var encodedType : Any.Type? {
		Self.constructType( mangledName: mangledName )
	}
	
	var decodableType: (AnyObject & GDecodable).Type? {
		let type = encodedType
		
		if let type = type as? GObsolete.Type {
			if let newName = _mangledTypeName( type.replacementType ) {
				let replacementName = Self.replacementeName(oldMangled: mangledName, newMangled: newName)

				if let replacement = _typeByName( replacementName ) as? (AnyObject & GDecodable).Type {
					return replacement
				}
			}
		} else if let type = type as? (AnyObject & GDecodable).Type {
			return type
		}
		return nil
	}
	
	var obsoleteType : GObsolete.Type? {
		encodedType as? GObsolete.Type
	}
	
	var isConstructible : Bool {
		decodableType != nil
	}
	
	var description: String {
		"\"\(qualifiedName)\" V\(encodedVersion) "
	}
	
	private static func replacementeName( oldMangled:String,newMangled:String ) -> String {
		func separator( _ mangled:String ) -> String.SubSequence.Index {
			var	remain		= mangled[...]
			var lenString	= remain.prefix { $0.isASCII && $0.isNumber }
			
			while lenString.isEmpty == false, let len = Int(lenString) {
				remain 		= remain[ lenString.endIndex... ]
				remain.removeFirst( len )
				lenString	= remain.prefix { $0.isASCII && $0.isNumber }
			}
			return remain.startIndex
		}

		let oldSeparator	= separator( oldMangled )
		let newSeparator	= separator( newMangled )

		return String( newMangled[..<newSeparator] + oldMangled[oldSeparator...] )
	}
}



