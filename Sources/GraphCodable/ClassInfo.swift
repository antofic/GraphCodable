//
//  File.swift
//  
//
//  Created by Antonino Ficarra on 16/04/23.
//

import Foundation

///	A struct that specifies the name of the encoded
/// class to match the type to create
///
/// Used by `GraphDecoder` `setType(...)` function.
public enum ClassName : Hashable {
	///	The `mangledClassName` string
	///
	/// You can specify the encoded class `mangledClassName`
	case mangled( _:String )
	///	The `qualifiedClassName` string
	///
	/// You can specify the encoded class `qualifiedClassName`
	case qualified( _:String )
}

public typealias ClassNameMap = [ClassName : any GDecodable.Type ]


/// The struct contains the data saved by the encoder for each class type
/// needed to *reify* the class type during decoding.
///
/// During encoding the class name is transformed into a string
/// (the `mangledClassName`) which allows, during decoding, to get back
/// the class.
///
/// Swift allows you to use two pairs of functions to achieve this result:
/// - `_mangledTypeName()/_typeByName()`
/// - `NSStringFromClass()` and `NSClassFromString()`
/// The `useNSClassFromStringMangling` flag (to be set when instantiating
/// a GraphEncoder) allows you to choose the second option. This settings
/// is then stored in the enum `ManglingFunction` for every class type.
public struct ClassInfo {
	/// The mangling functions used to generate the
	/// encoded class name an to istantiate the class
	/// type during decode.
	public enum ManglingFunction: UInt8, BCodable {
		///	uses `NSStringFromClass()/NSClassFromString()`
		case nsClassFromString
		///	uses `_mangledTypeName()/_typeByName()`
		case mangledTypeName
	}
	
	/// The mangling function used for encode this class
	public let	manglingFunction:		ManglingFunction
	/// The mangled string of the encoded class Name
	public let	mangledClassName:		String
	public let	encodedClassVersion:	UInt32
	
	internal init(
		_ manglingFunction: ManglingFunction,
		_ mangledClassName: String,
		_ encodedClassVersion: UInt32
	) {
		self.manglingFunction		= manglingFunction
		self.mangledClassName		= mangledClassName
		self.encodedClassVersion	= encodedClassVersion
	}
}


#if USE_CWL_DEMANGLE

//  CwlDemangle
//
//  Created by Matt Gallagher on 2016/04/30.
//  Copyright © 2016 Matt Gallagher. All rights reserved.
//
//  Licensed under Apache License v2.0 with Runtime Library Exception
//	 https://github.com/mattgallagher/CwlDemangle
//

import CwlDemangle

extension ClassInfo {
	///	Get a readable string of the encoded class name
	///
	/// If the `CwlDemangle` package is included, this function will provide
	/// the class name in a readable format from the encoded class information.
	/// Without the `CwlDemangle` package it gives the *mangled* name instead,
	/// which can be difficult to interpret.
	///
	/// Class names in:
	///
	/// - strings generated by GraphEncoder/Decoder dump functions;
	/// - error messages;
	///
	/// are affected but GraphCodable **does not lose any ability to
	/// encode or decode archives** without the `CwlDemangle` package.
	///
	/// - parameter qualified: If true, the returned string contains
	/// the ModuleName
	/// - returns: The class name.
	public func className( qualified: Bool ) -> String {
		let isType	= manglingFunction == .nsClassFromString ? false : true
		do {
			// parseMangledSwiftSymbol fails with objC stype class names
			let swiftSymbol = try parseMangledSwiftSymbol( mangledClassName, isType:isType )
			return swiftSymbol.print( using: qualified ? .default : .simplified )
		} catch {
			if	// objC stype class names are in the form "ModuleName.ClassName"...
				qualified == false,	// no module name
				isType == false,	// nsClassFromString mangling function
				let index = mangledClassName.firstIndex(of: ".")
			{	// so removing the module name is simple...
				return String( mangledClassName.suffix(from: index) )
			}
			return mangledClassName
		}
	}
}

#else

extension ClassInfo {
	public func className( qualified: Bool ) -> String {
		mangledClassName
	}
}

#endif
