//
//  File.swift
//
//
//  Created by Antonino Ficarra on 29/04/21.
//

import Foundation


protocol OptionalProtocol {
	static var wrappedType: Any.Type { get }
	// nested optional types unwrapping
	static var fullUnwrappedType: Any.Type { get }

	var	isNil			: Bool		{ get }
	var wrappedValue	: Any 		{ get }
}

extension Optional : OptionalProtocol {
	static var wrappedType: Any.Type {
		return Wrapped.self
	}

	static var fullUnwrappedType: Any.Type {
		var	currentType = wrappedType
		while let actual = currentType as? OptionalProtocol.Type {
			currentType = actual.wrappedType
		}
		return currentType
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

extension Optional : GCodable where Wrapped : GCodable {
	public func encode(to encoder: GEncoder) throws {
		throw GCodableError.optionalEncodeError
	}
	
	public init(from decoder: GDecoder) throws {
		throw GCodableError.optionalDecodeError
	}
}

