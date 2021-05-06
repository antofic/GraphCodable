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
import CwlDemangle


struct ClassData : NativeIOType, CustomStringConvertible {
	let	nsClassName:	String	// the TypeName Generated fro NSStringFromClass
	let	encodeVersion:	UInt32

	// only ClassInfo can initialize it
	fileprivate init( mangledName:String, encodeVersion:UInt32 ) {
		self.nsClassName	= mangledName
		self.encodeVersion	= encodeVersion
	}
	
	func write(to writer: inout BinaryWriter) throws {
		try nsClassName.write(to: &writer)
		try encodeVersion.write(to: &writer)
	}

	init(from reader: inout BinaryReader) throws {
		self.nsClassName	= try String( from: &reader )
		self.encodeVersion	= try UInt32( from: &reader )
	}
		
	var aClass	: (AnyObject & GCodable).Type? {
		return NSClassFromString( nsClassName ) as? (AnyObject & GCodable).Type
	}
	
	var decodable : Bool {
		return aClass != nil
	}
	
	var swiftSymbol: SwiftSymbol? {
		do {
			let symbol = try parseMangledSwiftSymbol( nsClassName )
			return symbol
		} catch {
			return nil
		}
	}
	
	var demangledName: String? {
		return swiftSymbol?.print(using: [.simplified, .displayModuleNames])
	}

	var readableClassName : String {
		return demangledName ?? nsClassName
	}

	var description: String {
		return "\"\(readableClassName)\" V\(encodeVersion) "
	}
}

struct ClassInfo : CustomStringConvertible {
	let	aClass:		(AnyObject & GCodable).Type
	let	classData:	ClassData

	init( aClass:(AnyObject & GCodable).Type ) throws {
		let mangledName	= NSStringFromClass( aClass )

		guard NSClassFromString( mangledName ) == aClass else {
			throw GCodableError.nilClassFromStringFromClass(aClass: aClass)
		}
		self.aClass	= aClass
		self.classData	= ClassData(mangledName: mangledName, encodeVersion: aClass.encodeVersion )
	}
	
	init( classData:ClassData ) throws {
		guard let aClass = classData.aClass else {
			throw GCodableError.nilClassFromString( nsClassName: classData.nsClassName )
		}
		
		self.aClass		= aClass
		self.classData	= classData
	}

	var description: String {
		return classData.description
	}
}

