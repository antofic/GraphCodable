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

struct ClassData : NativeType, CustomStringConvertible {
	let	readableTypeName:	String	// the TypeName Generated _typeName( type, qualified:true )
	let	mangledTypeName:	String?	// the TypeName Generated _mangledTypeName( type )
	let	objcTypeName:		String	// the TypeName Generated by NSStringFromClass
	let	encodeVersion:		UInt32

	func write(to writer: inout BinaryWriter) throws {
		try readableTypeName.write(to: &writer)
		try mangledTypeName.write(to: &writer)
		try objcTypeName.write(to: &writer)
		try encodeVersion.write(to: &writer)
	}

	init(from reader: inout BinaryReader) throws {
		self.readableTypeName	= try String( from: &reader )
		self.mangledTypeName	= try Optional<String>( from: &reader )
		self.objcTypeName		= try String( from: &reader )
		self.encodeVersion		= try UInt32( from: &reader )
	}
	
	init( codableType:(AnyObject & GCodable).Type ) throws {
		self.readableTypeName		= _typeName( codableType, qualified:true )

		if #available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
			self.mangledTypeName = _mangledTypeName( codableType )
			guard
				let typeName = mangledTypeName,
				_typeByName( typeName ) == codableType else {
				throw GCodableError.cantConstructClass(
					Self.self, GCodableError.Context(
						debugDescription:"The class -\(readableTypeName)- can't be constructed."
					)
				)
			}
			self.objcTypeName		= NSStringFromClass( codableType )
		} else {
			self.mangledTypeName	= nil
			self.objcTypeName		= NSStringFromClass( codableType )

			guard NSClassFromString( objcTypeName ) == codableType else {
				throw GCodableError.cantConstructClass(
					Self.self, GCodableError.Context(
						debugDescription:"The class -\(readableTypeName)- can't be constructed."
					)
				)
			}
		}
		self.encodeVersion		= codableType.currentVersion
	}
	
	static func supportsCodable( _ type:(AnyObject & GCodable).Type ) -> Bool {
		// we try to be more restrictive
		
		if #available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
			if let typeName = _mangledTypeName( type ) {
				return _typeByName( typeName ) != nil
			} else {
				return false
			}
		} else {
			return NSClassFromString( NSStringFromClass( type ) ) != nil
		}
	}
	
	private var encodedType : Any.Type? {
		func typeByMangledName() -> Any.Type? {
			if let typeName = mangledTypeName {
				return _typeByName( typeName )
			} else {
				return nil
			}
		}
		// provo in tutti i modi:
		return typeByMangledName() ?? NSClassFromString( objcTypeName ) ?? NSClassFromString( readableTypeName )
	}
	
	var codableType	: (AnyObject & GCodable).Type? {
		let type = encodedType
		
		return type as? (AnyObject & GCodable).Type ?? (type as? GCodableObsolete.Type)?.replacementType
	}
	
	var obsoleteType : GCodableObsolete.Type? {
		return encodedType as? GCodableObsolete.Type
	}

	var isDecodable : Bool {
		return codableType != nil
	}

	var description: String {
		return "\"\(readableTypeName)\" V\(encodeVersion) "
	}
}

struct ClassInfo : CustomStringConvertible {
	let	codableType:	(AnyObject & GCodable).Type
	let	classData:		ClassData

	init( codableType:(AnyObject & GCodable).Type ) throws {
		self.classData		= try ClassData(codableType: codableType)
		self.codableType	= codableType
	}
	
	init( classData:ClassData ) throws {
		guard let aClass = classData.codableType else {
			throw GCodableError.cantConstructClass(
				Self.self, GCodableError.Context(
					debugDescription:"The class -\(classData.readableTypeName)- can't be constructed."
				)
			)
		}
		
		self.codableType	= aClass
		self.classData		= classData
	}

	var description: String {
		return classData.description
	}
}

