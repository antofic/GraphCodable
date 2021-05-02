//
//  File.swift
//  
//
//  Created by Antonino Ficarra on 29/04/21.
//

import Foundation


protocol OptionalProtocol {
	var	isNil			: Bool		{ get }
	var wrappedValue	: Any 		{ get }
	var	wrappedType		: Any.Type	{ get }
}

extension Optional : OptionalProtocol {
	var wrappedType: Any.Type {
		return Wrapped.self
	}
	
	var isNil: Bool {
		switch self {
		case .some:
			return false
		case .none:
			return true
		}
	}
	
	var wrappedValue: Any {
		switch self {
		case .some( let unwrapped ):
			return unwrapped
		case .none:
			preconditionFailure( "nil unwrap" )
		}
	}
}

extension Optional where Wrapped == Any {
	// nested optionals unwrapping
	init( fullUnwrapping value:Any ) {
		var	currentValue = value
		while let optionalValue = currentValue as? OptionalProtocol {
			if optionalValue.isNil {
				self = .none
				return
			} else {
				currentValue = optionalValue.wrappedValue
			}
		}
		self = .some( currentValue )
	}
}

//	OPTIONAL CONFORMANCE
//	un optional viene archiviato come il suo wrapped value oppure come .Nil
//	quindi qui dentro non arriva mai
extension Optional : GCodable where Wrapped : GCodable {
	public func encode(to encoder: GEncoder) throws	{ throw GCodableError.optionalEncodeError }
	public init(from decoder: GDecoder) throws		{ throw GCodableError.optionalDecodeError }
}
