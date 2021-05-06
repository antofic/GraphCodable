//
//  File.swift
//  
//
//  Created by Antonino Ficarra on 06/05/21.
//

import Foundation

//	Date SUPPORT ------------------------------------------------------

extension Date : FixedSizeIOType {
	func write( to writer: inout BinaryWriter ) throws {
		writer.writeValue( self.timeIntervalSince1970 )
	}
	init( from reader: inout BinaryReader ) throws {
		var value = TimeInterval(0)
		try reader.readValue( &value )
		self.init(timeIntervalSince1970: value )
	}
}


//	URL SUPPORT ------------------------------------------------------

extension URL : GCodable {
	private enum Key : String { case base, relative }

	public init(from decoder: GDecoder) throws {
		let relative	= try decoder.decode( for: Key.relative ) as String
		let base		= try decoder.decodeIfPresent( for: Key.base ) as URL?

		guard let url = URL(string: relative, relativeTo: base) else {
			throw GCodableError.urlDecodeError
		}
		self = url
	}
	
	public func encode(to encoder: GEncoder) throws {
		try encoder.encode( self.relativeString, for: Key.relative )
		if let base = self.baseURL {
			try encoder.encode(base, for: Key.base)
		}
	}
}

//	IndexSet SUPPORT ------------------------------------------------------

extension IndexSet : NativeIOType {
	init(from reader: inout BinaryReader) throws {
		var indexSet = IndexSet()
		let count	= try Int( from: &reader )
		for _ in 0..<count {
			indexSet.insert(integersIn: try Range(from: &reader) )
		}
		self = indexSet
	}
	
	func write(to writer: inout BinaryWriter) throws {
		try rangeView.count.write(to: &writer)
		for range in rangeView {
			try range.write(to: &writer)
		}
	}
}
