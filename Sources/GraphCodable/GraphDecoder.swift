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

///	An object that decodes instances of a **GDecodable** type
///	from a data buffer that uses **GraphCodable** format.
public final class GraphDecoder {
	public init() {}

	///	get/set the userInfo dictionary
	public var userInfo : [String:Any] {
		get { decoder.userInfo }
		set { decoder.userInfo = newValue }
	}

	///	Decode the root value from the data byte buffer
	///
	///	The root value must conform to the GDecodable protocol
	public func decode<T,Q>( _ type: T.Type, from data: Q ) throws -> T
	where T:GDecodable, Q:Sequence, Q.Element==UInt8 {
		try decoder.decodeRoot( type, from: data)
	}

	public func dump<Q>( from data: Q, options: GraphDumpOptions = .readable ) throws -> String
	where Q:Sequence, Q.Element==UInt8 {
		try decoder.dumpRoot( from: data, options:options )
	}
	
	///	Returns all the classes encoded in the data byte buffer
	public func decodableClasses<Q>( from data: Q ) throws -> [(AnyObject & GDecodable).Type]
	where Q:Sequence, Q.Element==UInt8 {
		let types	= try decoder.allClassData( from: data ).compactMap { $0.decodableType }
		let keys	= types.map { ObjectIdentifier($0) }
		let map		= Dictionary( zip(keys,types) ) { v1,v2 in v1 }
		return Array( map.values )
	}

	///	Returns all the obsolete classes encoded in the data byte buffer
	public func obsoleteClasses<Q>( from data: Q ) throws -> [GObsolete.Type]
	where Q:Sequence, Q.Element==UInt8 {
		let types	= try decoder.allClassData( from: data ).compactMap { $0.obsoleteType }
		let keys	= types.map { ObjectIdentifier($0) }
		let map		= Dictionary( zip(keys,types) ) { v1,v2 in v1 }
		return Array( map.values )
	}
	
	private let decoder = GDecoderImpl()
}

