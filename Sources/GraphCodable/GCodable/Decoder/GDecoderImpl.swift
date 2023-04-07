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

final class GDecoderImpl {
	let archiveIdentifier	: String?
	var	userInfo			= [String:Any]()
	var classNameMap		= ClassNameMap()
	private var constructor : TypeConstructor!
	
	init( archiveIdentifier: String? ) {
		self.archiveIdentifier	= archiveIdentifier
	}	
	
	private func ioDecoder<Q>( from data: Q ) throws -> BinaryIODecoder
	where Q:DataProtocol {
		try BinaryIODecoder(data: data, archiveIdentifier:archiveIdentifier, userData:self )
	}
	
	func allClassData<Q>( from data: Q ) throws -> [ClassData]
	where Q:DataProtocol {
		let ioDecoder 		= try ioDecoder(from: data)
		let decodedNames	= try DecodeClassNames(from: ioDecoder)

		return Array( decodedNames.classDataMap.values )
	}
	
	func decodeRoot<T,Q>( _ type: T.Type, from data: Q ) throws -> T
	where T:GDecodable, Q:DataProtocol {
		defer { constructor = nil }
		
		let ioDecoder 	= try ioDecoder(from: data)
		constructor		= try TypeConstructor( ioDecoder: ioDecoder, classNameMap:classNameMap )
		
		return try constructor.decodeRoot(type, from: self)
	}
	
	func dumpRoot<Q>( from data: Q, options: GraphDumpOptions ) throws -> String
	where Q:DataProtocol {
		let ioDecoder 	= try ioDecoder(from: data)
		let decodedDump	= try DecodeDump(from: ioDecoder, classNameMap:classNameMap, options: options)
		
		return decodedDump.dump()
	}
}

// MARK: GDecoderImpl conformance to GDecoder protocol
extension GDecoderImpl : GDecoder, GDecoderView {
	var	encodedUserVersion	: UInt32 {
		constructor.fileHeader.userVersion
	}
	
	var encodedClassVersion : UInt32 {
		get throws { try constructor.encodedClassVersion }
	}

	var replacedClass : (AnyObject & GDecodable).Type?   {
		get throws { try constructor.replacedClass }
	}
	
	// ------ keyed support
	
	func contains<Key>(_ key: Key) -> Bool
	where Key : RawRepresentable, Key.RawValue == String
	{
		constructor.contains(key: key.rawValue)
	}
	
	func decode<Key, Value>( _ type:Value.Type, for key: Key ) throws -> Value
	where Key : RawRepresentable, Value : GDecodable, Key.RawValue == String
	{
		let	element = try constructor.popBodyElement( key:key.rawValue )
		
		return try constructor.decode( element:element, from: self )
	}
	
	func deferDecode<Key, Value>( _ type:Value.Type, for key: Key, _ setter: @escaping (Value) -> ()) throws
	where Key : RawRepresentable, Value : GDecodable, Key.RawValue == String
	{
		let	element = try constructor.popBodyElement( key:key.rawValue )

		try constructor.deferDecode( element:element, from: self, setter )
	}

	// ------ unkeyed support
	
	var unkeyedCount : Int {
		constructor.currentElement.unkeyedCount
	}
	
	func decode<Value>( _ type:Value.Type ) throws -> Value where Value : GDecodable {
		let	element = try constructor.popBodyElement()

		return try constructor.decode( element:element, from: self )
	}
	
	func deferDecode<Value>( _ type:Value.Type, _ setter: @escaping (Value) -> () ) throws where Value : GDecodable {
		let	element = try constructor.popBodyElement()

		try constructor.deferDecode( element:element, from: self, setter )
	}
}

