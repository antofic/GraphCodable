//
//  File.swift
//  
//
//  Created by Antonino Ficarra on 13/03/23.
//

import Foundation


public enum GraphCodableUti {
	public static func decodedClasses<Q:MutableDataProtocol>( data:Q, qualifiedClassNames:Bool,decoder:GraphDecoder? = nil ) throws -> String {
		var string				= ""
		let graphDecoder 		= decoder ?? GraphDecoder()
		let decodableClasses	= try graphDecoder.decodableClasses(from: data)
		if decodableClasses.isEmpty == false {
			let array	= decodableClasses.map { _typeName( $0, qualified:qualifiedClassNames ) }.sorted()
			string.append( "Decoded Classes: --------------------------" )
			string = array.reduce(into: string) { $0.append( "\n\t'\( $1 )'" ) }

			let replacedClasses	= try graphDecoder.replacedClasses(from: data)
			if replacedClasses.isEmpty == false {
				let couples	= replacedClasses.map {
					(_typeName( $0, qualified:qualifiedClassNames ),_typeName( $0.replacementType, qualified:qualifiedClassNames )) }.sorted { $0.0 < $1.0 }
				string.append( "\nwhere:" )
				return couples.reduce(into: string) {
					$0.append( "\n\t'\( $1.0 )'\n\t\twas replaced by '\( $1.1 )'" )
				}
			}
		}
		return string
	}
	
	@discardableResult
	public static func checkDecoder<T:GDecodable,Q:MutableDataProtocol>(
		type:T.Type, data:Q, options: GraphEncoder.Options = .defaultOption, dumpOptions:GraphDumpOptions? = nil, qualifiedClassNames:Bool? = nil
	) throws -> T
	{
		let graphDecoder = GraphDecoder()
		
		if let dumpOptions {
			print("-- Decoded Root Dump --------------")
			print( try graphDecoder.dump( from: data,options: dumpOptions ) )
		}
		
		if let qualifiedClassNames {
			print( try decodedClasses(data: data, qualifiedClassNames: qualifiedClassNames) )
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
		encodeDumpOptions:GraphDumpOptions? = nil, decodeDumpOptions:GraphDumpOptions? = nil,
		qualifiedClassNames:Bool? = nil
	) throws -> T
	{
		// Encoding the root value:
		let data	= try checkEncoder( root: inRoot, options:options, dumpOptions:encodeDumpOptions ) as Bytes
		return try checkDecoder(type:T.self, data: data, options:options, dumpOptions:decodeDumpOptions, qualifiedClassNames:qualifiedClassNames )
	}
}
