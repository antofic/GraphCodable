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

extension ClassData : Codable {}

struct ClassData : BinaryIOType, CustomStringConvertible {
	let	readableTypeName:	String	// the TypeName Generated _typeName( type, qualified:true )
	let	mangledTypeName:	String?	// the TypeName Generated _mangledTypeName( type )
	let	objcTypeName:		String	// the TypeName Generated by NSStringFromClass
	let	encodeVersion:		UInt32
	
	func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try readableTypeName.write(to: &wbuffer)
		try mangledTypeName.write(to: &wbuffer)
		try objcTypeName.write(to: &wbuffer)
		try encodeVersion.write(to: &wbuffer)
	}
	
	init(from rbuffer: inout BinaryReadBuffer) throws {
		self.readableTypeName	= try String( from: &rbuffer )
		self.mangledTypeName	= try Optional<String>( from: &rbuffer )
		self.objcTypeName		= try String( from: &rbuffer )
		self.encodeVersion		= try UInt32( from: &rbuffer )
	}
	
	static private func constructType( mangledTypeName:String?, objcTypeName:String ) -> AnyClass? {
		if let mangledTypeName, let type = _typeByName( mangledTypeName ) as? AnyClass {
			return type
		} else {
			return NSClassFromString( objcTypeName )
		}
	}
	
	init( type:(AnyObject & GEncodable).Type ) throws {
		self.readableTypeName	= _typeName( type, qualified:true )
		self.mangledTypeName 	= _mangledTypeName( type )
		self.objcTypeName		= NSStringFromClass( type )
		if let versionedType = type as? GVersion.Type {
			self.encodeVersion		= versionedType.encodeVersion
		} else {
			self.encodeVersion		= 0
		}
		
		guard Self.constructType(mangledTypeName: mangledTypeName, objcTypeName: objcTypeName ) != nil else {
			throw GCodableError.cantConstructClass(
				Self.self, GCodableError.Context(
					debugDescription:"The class -\(readableTypeName)- can't be constructed."
				)
			)
		}
	}
	
	static func isConstructible( type:AnyObject.Type ) -> Bool {
		Self.constructType(mangledTypeName: _mangledTypeName( type ), objcTypeName: NSStringFromClass( type ) ) != nil
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
		Self.constructType(mangledTypeName: mangledTypeName, objcTypeName: objcTypeName )
	}
	
	var decodableType: (AnyObject & GDecodable).Type? {
		let type = encodedType
		return type as? (AnyObject & GDecodable).Type ?? (type as? GObsolete.Type)?.replacementType
	}
	
	var obsoleteType : GObsolete.Type? {
		encodedType as? GObsolete.Type
	}
	
	var isConstructible : Bool {
		decodableType != nil
	}
	
	var description: String {
		"\"\(readableTypeName)\" V\(encodeVersion) "
	}
}
