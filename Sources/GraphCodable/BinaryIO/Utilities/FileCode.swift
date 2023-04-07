//
//  File.swift
//  
//
//  Created by Antonino Ficarra on 05/04/23.
//

import Foundation

public struct FileCode : ExpressibleByStringLiteral, Equatable, Hashable {
	let code : UInt32
	
	public init( stringLiteral fourCharCode: StaticString ) {
		guard let value = FileCode( fourCharCode:fourCharCode ) else {
			fatalError( "\(#function) FileCode requires a StaticString of exactly 4 ascii characters." )
		}
		self = value
	}
	
	init( code:UInt32 ) {
		self.code = code
	}
	
	private init?( fourCharCode: StaticString ) {
		guard
			fourCharCode.utf8CodeUnitCount == 4,
			fourCharCode.isASCII
		else { return nil }
		var code : UInt32 = 0
		fourCharCode.withUTF8Buffer { utf8 in
			code |= UInt32( utf8[0] ) &<< 24
			code |= UInt32( utf8[1] ) &<< 16
			code |= UInt32( utf8[2] ) &<< 8
			code |= UInt32( utf8[3] )
		}
		self.code = code
	}
	
	public var fourCharCode: String {
		let code	= UInt32(bigEndian: code)
		
		return withUnsafePointer(to: code) { ptr in
			ptr.withMemoryRebound(to: UInt8.self, capacity: 4 ) { ptr in
				let buffer = UnsafeBufferPointer(start: ptr, count: 4)
				return String( unsafeUninitializedCapacity: 4 ) {
					_ = $0.initialize(from: buffer)
					return 4
				}
			}
		}
	}
}

extension FileCode: CustomStringConvertible {
	public var description: String {
		fourCharCode
	}
}

extension FileCode: CustomDebugStringConvertible {
	public var debugDescription: String {
		String( format: "%@ (0x%X)", fourCharCode, code )
	}
}
