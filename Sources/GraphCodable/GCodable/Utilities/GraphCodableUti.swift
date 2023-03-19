//
//  File.swift
//  
//
//  Created by Antonino Ficarra on 13/03/23.
//

import Foundation


public enum GraphCodableUti {
	@discardableResult
	public static func checkDecoder<T:GDecodable,Q:MutableDataProtocol>(
		type:T.Type, data:Q, options: GraphEncoder.Options = .defaultOption, dumpOptions:GraphDumpOptions? = nil
	) throws -> T
	{
		let graphDecoder = GraphDecoder()
		
		if let dumpOptions {
			print("-- Decoded Root Dump --------------")
			print( try graphDecoder.dump( from: data,options: dumpOptions ) )
		}

		return try graphDecoder.decode( T.self, from: data)
	}
	
	@discardableResult
	public static func checkEncoder<T:GEncodable,Q:MutableDataProtocol>(
		root inRoot:T, options: GraphEncoder.Options = .defaultOption, dumpOptions:GraphDumpOptions? = nil
	) throws -> Q
	{
		let graphEncoder = GraphEncoder( options )
		
		if let dumpOptions {
			// source encode dump
			print("-- Encoded Root Dump --------------")
			print( try graphEncoder.dump( inRoot,options: dumpOptions ) )
		}
		
		return try graphEncoder.encode( inRoot )
	}
	
	@discardableResult
	public static func check<T:GCodable>(
		root inRoot:T, options: GraphEncoder.Options = .defaultOption,
		encodeDumpOptions:GraphDumpOptions? = nil, decodeDumpOptions:GraphDumpOptions? = nil
	) throws -> T
	{
		// Encoding the root value:
		let data	= try checkEncoder( root: inRoot, options:options, dumpOptions:encodeDumpOptions ) as Bytes
		return try checkDecoder(type:T.self, data: data, options:options, dumpOptions:decodeDumpOptions )
	}
}
