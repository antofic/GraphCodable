//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

final class GDecoderImpl {
	private var archiveIdentifier	: String?
	var	userInfo					= [String:Any]()
	var classNameMap				= ClassNameMap()
	private var constructor 		: TypeConstructor!
	
	init( archiveIdentifier: String? ) {
		self.archiveIdentifier	= archiveIdentifier
	}
	
	private func ioDecoder( from data: some DataProtocol ) throws -> BinaryIODecoder {
		try BinaryIODecoder(data: data, archiveIdentifier:archiveIdentifier, userData:self )
	}
	
	func allEncodedClass( from data: some DataProtocol ) throws -> [EncodedClass] {
		let ioDecoder 		= try ioDecoder(from: data)
		var blockDecoder	= try DecodeReadBlocks( from: ioDecoder )
		let encodedClassMap	= try blockDecoder.encodedClassMap()
		
		return Array( encodedClassMap.values )
	}
	
	func decodeRoot<T>( _ type: T.Type, from data: some DataProtocol ) throws -> T
	where T:GDecodable {
		defer { constructor = nil }
		
		let ioDecoder 	= try ioDecoder(from: data)
		constructor		= try TypeConstructor( ioDecoder: ioDecoder, classNameMap:classNameMap )
		
		return try constructor.decodeRoot(type, from: self)
	}
	
	func dumpRoot( from data: some DataProtocol, options: GraphDumpOptions ) throws -> String {
		let ioDecoder 	= try ioDecoder(from: data)
		let decodedDump	= try DecodeDump(from: ioDecoder, classNameMap:classNameMap, options: options)
		
		return decodedDump.dump()
	}
	
	func isCyclic( from data: some DataProtocol ) throws -> Bool {
		let ioDecoder 		= try ioDecoder(from: data)
		var blockDecoder	= try DecodeReadBlocks( from: ioDecoder )
		let readBlocks		= try blockDecoder.readBlocks()
		let (root,nodeMap)	= try ReadNode.flatGraph(blocks: readBlocks)

		return root.isCyclic(nodeMap: nodeMap)
	}
	
	func encodedArchiveIdentifier( from data: some DataProtocol ) throws -> String? {
		let ioDecoder 	= try ioDecoder(from: data)
		return ioDecoder.encodedArchiveIdentifier
	}
	
}

// MARK: adopt GDecoder/GDecoderView protocol
extension GDecoderImpl : GDecoder, GDecoderView {
	var	encodedUserVersion	: UInt32 {
		constructor.fileHeader.userVersion
	}
	
	var encodedClassVersion : UInt32 {
		get throws { try constructor.encodedClassVersion }
	}

	var replacedClass : (any (AnyObject & GDecodable).Type)?   {
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
		let	node = try constructor.popNode( key:key.rawValue )
		
		return try constructor.decode( node:node, from: self )
	}
	
	func deferDecode<Key, Value>( _ type:Value.Type, for key: Key, _ setter: @escaping (Value) -> ()) throws
	where Key : RawRepresentable, Value : GDecodable, Key.RawValue == String
	{
		let	node = try constructor.popNode( key:key.rawValue )

		try constructor.deferDecode( node:node, from: self, setter )
	}

	// ------ unkeyed support
	
	var unkeyedCount : Int {
		constructor.currentNode.unkeyedCount
	}
	
	func decode<Value>( _ type:Value.Type ) throws -> Value where Value : GDecodable {
		let	node = try constructor.popNode()

		return try constructor.decode( node:node, from: self )
	}
	
	func deferDecode<Value>( _ type:Value.Type, _ setter: @escaping (Value) -> () ) throws where Value : GDecodable {
		let	node = try constructor.popNode()

		try constructor.deferDecode( node:node, from: self, setter )
	}
}

