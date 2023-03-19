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

struct ClassData {
	let	qualifiedName:			String	// generated by _typeName( type, qualified:true )
	let	mangledName:			String	// generated by _mangledTypeName( type )
	let	encodedClassVersion:	UInt32	// encoded GEncodable.classVersion
}

extension ClassData { 	// init
	init( type:(AnyObject & GEncodable).Type ) throws {
		self.qualifiedName	= Self.typeName(of: type)
		guard
			let mangledName = Self.mangledName(of: type),
			Self.classType( from:mangledName ) != nil else {
			throw GCodableError.cantConstructClass(
				Self.self, GCodableError.Context(
					debugDescription:"The class -\(qualifiedName)- can't be constructed."
				)
			)
		}
		
		self.mangledName 			= mangledName
		self.encodedClassVersion	= type.classVersion
	}
}

extension ClassData {	// internal properties
	var isConstructible : Bool {
		decodedType != nil
	}
	
	private var encodedClass: (AnyObject & GDecodable).Type? {
		Self.classType( from: mangledName ) as? (AnyObject & GDecodable).Type
	}

	var decodedType: GDecodable.Type? {
		encodedClass?.decodeType ?? nil
	}
	
	var replacedClass: (AnyObject & GDecodable).Type? {
		if let type = encodedClass, type != type.decodeType {
			return type
		}
		return nil
	}
}

extension ClassData: BinaryIOType {	// BinaryIOType protocol
	func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try qualifiedName.write(to: &wbuffer)
		try mangledName.write(to: &wbuffer)
		try encodedClassVersion.write(to: &wbuffer)
	}
	
	init(from rbuffer: inout BinaryReadBuffer) throws {
		self.qualifiedName		= try String( from: &rbuffer )
		self.mangledName		= try String( from: &rbuffer )
		self.encodedClassVersion	= try UInt32( from: &rbuffer )
	}
}

extension ClassData: CustomStringConvertible { 	// CustomStringConvertible protocol
	var description: String {
		"\"\(qualifiedName)\" V\(encodedClassVersion) "
	}
}

extension ClassData {	// static primitive functions
	static func isConstructible( type:AnyClass ) -> Bool {
		if let mangledName = Self.mangledName(of: type),
		   Self.classType( from:mangledName ) != nil {
			return true
		}
		return false
	}
	
	static func throwIfNotConstructible( type:AnyClass ) throws {
		guard isConstructible( type:type ) else {
			throw GCodableError.cantConstructClass(
				Self.self, GCodableError.Context(
					debugDescription:"The class -\( _typeName( type, qualified:true ) )- can't be constructed."
				)
			)
		}
	}
}

extension ClassData {	// private static primitive functions
	static private func classType( from mangledName:String ) -> AnyClass? {
		//	_typeByName( _mangledTypeName( type ) ) is faster
		//	than NSClassFromString( NSStringFromClass( class ) )
		_typeByName( mangledName ) as? AnyClass ?? nil
	}
	
	static private func mangledName( of classType:AnyClass ) -> String? {
		_mangledTypeName( classType )
	}
	
	static private func typeName( of classType:AnyClass ) -> String {
		_typeName( classType, qualified:true )
	}
}

