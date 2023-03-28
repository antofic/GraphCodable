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

///	last resort to decode a reference type with identity
public enum ClassName : Hashable {
	case mangledName( _:String )
	case qualifiedName( _:String )
}

public typealias ClassNameMap 		= [ClassName : GDecodable.Type ]

public struct UndecodableClass {
	public let	qualifiedName:			String	// generated by _typeName( type, qualified:true )
	public let	mangledName:			String	// generated by _mangledTypeName( type )
	public let	encodedClassVersion:	UInt32	// encoded GEncodable.classVersion
	
	fileprivate init( _ qualifiedName: String, _ mangledName: String, _ encodedClassVersion: UInt32) {
		self.qualifiedName = qualifiedName
		self.mangledName = mangledName
		self.encodedClassVersion = encodedClassVersion
	}
}

///	An object that decodes instances of a **GDecodable** type
///	from a data buffer that uses **GraphCodable** format.
public struct GraphDecoder {
	public init() {}

	///	get/set the userInfo dictionary
	public var userInfo : [String:Any] {
		get { decoder.userInfo }
		set { decoder.userInfo = newValue }
	}
	
	///	get the dictionary that maps the type to create
	///	when an encoded className is encountered
	public var classNameMap : ClassNameMap {
		decoder.classNameMap
	}
	
	///	set the type to create when an encoded className
	///	is encountered.
	///
	///	**The type can also be a value type.**
	public func setType( _ type:GDecodable.Type, for className:ClassName ) {
		decoder.classNameMap[ className ] = type
	}
	
	///	Decode the root value from the data byte buffer
	///
	///	The root value must conform to the GDecodable protocol
	public func decode<T,Q>( _ type: T.Type, from data: Q ) throws -> T
	where T:GDecodable, Q:DataProtocol {
		try decoder.decodeRoot( type, from: data)
	}

	public func dump<Q>( from data: Q, options: GraphDumpOptions = .readable ) throws -> String
	where Q:DataProtocol {
		try decoder.dumpRoot( from: data, options:options )
	}
	
	///	returns an array of types that will potentially be instantiated
	///	after replacements from encoded classes  in the data byte buffer
	///
	///	as a result of the replacements, types may not be classes
	public func decodableTypes<Q>( from data: Q ) throws -> [GDecodable.Type]
	where Q:DataProtocol {
		return try decoder.allClassData( from: data ).compactMap { $0.decodedType }
	}

	///	Returns all replaced classes encoded in the data byte buffer
	public func replacedClasses<Q>( from data: Q ) throws -> [GDecodable.Type]
	where Q:DataProtocol {
		return try decoder.allClassData( from: data ).compactMap { $0.replacedClass }
	}

	///	Returns a UndecodableClass struct for every undecodable class in the data byte buffer
	public func undecodableClasses<Q>( from data: Q )
	throws -> [UndecodableClass]
	where Q:DataProtocol {
		return try decoder.allClassData( from: data ).compactMap {
			$0.decodedType == nil ?
			UndecodableClass( $0.qualifiedName, $0.mangledName, $0.encodedClassVersion ) : nil
		}
	}
	
	private let decoder = GDecoderImpl()
}


