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

final class GDecoderImpl : GDecoder {
	var	userInfo			= [String:Any]()
	private var constructor : TypeConstructor!

	func allClassData<Q>( from data: Q ) throws -> [ClassData]
	where Q:Sequence, Q.Element==UInt8 {
		let decodedNames		= try ClassNamesDecoder(from: data)
		
		return Array( decodedNames.classDataMap.values )
	}
	
	func decodeRoot<T,Q>( _ type: T.Type, from data: Q ) throws -> T
		where T:GDecodable, Q:Sequence, Q.Element==UInt8 {
		defer { constructor = nil }
		
		constructor	= TypeConstructor(decodedData: try DataDecoder( from: data ))
		
		return try constructor.decodeRoot(type, from: self)
	}

	func dumpRoot<Q>( from data: Q, options: GraphDumpOptions ) throws -> String
	where Q:Sequence, Q.Element==UInt8 {
		let decodedDump	= try StringDecoder(from: data, options: options)
		
		return try decodedDump.dump()
	}
	
	var encodedVersion : UInt32 {
		get throws { try constructor.encodedVersion }
	}

	var replacedType : GObsolete.Type?   {
		get throws { try constructor.replacedType }
	}
	
	// ------ keyed support
	
	func contains<Key>(_ key: Key) -> Bool
	where Key : RawRepresentable, Key.RawValue == String
	{
		constructor.contains(key: key.rawValue)
	}
	
	func decode<Key, Value>(for key: Key) throws -> Value
	where Key : RawRepresentable, Value : GDecodable, Key.RawValue == String
	{
		let	bodyElement = try constructor.popBodyElement( key:key.rawValue )
		
		return try constructor.decode( element:bodyElement, from: self )
	}
	
	func deferDecode<Key, Value>( for key: Key, _ setter: @escaping (Value) -> ()) throws
	where Key : RawRepresentable, Value : GDecodable, Key.RawValue == String
	{
		let	bodyElement = try constructor.popBodyElement( key:key.rawValue )

		try constructor.deferDecode( element:bodyElement, from: self, setter )
	}

	// ------ unkeyed support
	
	var unkeyedCount : Int {
		constructor.currentElement.unkeyedCount
	}
	
	func decode<Value>() throws -> Value where Value : GDecodable {
		let	bodyElement = try constructor.popBodyElement()

		return try constructor.decode( element:bodyElement, from: self )
	}
	
	func deferDecode<Value>(_ setter: @escaping (Value) -> ()) throws where Value : GDecodable {
		let	bodyElement = try constructor.popBodyElement()

		try constructor.deferDecode( element:bodyElement, from: self, setter )
	}
}
