//
//  File.swift
//
//
//  Created by Antonino Ficarra on 29/04/21.
//

import Foundation

extension Optional : GCodable where Wrapped : GCodable {
	// queste due perché i decoder unwrappano gli optional
	public func encode(to encoder: GEncoder) throws {
		throw GCodableError.internalInconsistency(
			Self.self, GCodableError.Context(
				debugDescription: "Program must not reach \(#function)."
			)
		)
	}
	
	public init(from decoder: GDecoder) throws {
		throw GCodableError.internalInconsistency(
			Self.self, GCodableError.Context(
				debugDescription: "Program must not reach \(#function)."
			)
		)
	}
}

protocol OptionalProtocol {
	static var wrappedType: Any.Type { get }
	// nested optional types unwrapping
	static var fullUnwrappedType: Any.Type { get }

	var	isNil			: Bool		{ get }
	var wrappedValue	: Any 		{ get }
}

extension Optional : OptionalProtocol {
	static var wrappedType: Any.Type {
		Wrapped.self
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

