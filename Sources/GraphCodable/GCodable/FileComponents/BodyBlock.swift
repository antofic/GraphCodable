//
//  File.swift
//  
//
//  Created by Antonino Ficarra on 03/03/23.
//

import Foundation

enum FileBlock {
	private struct Code: OptionSet {
		let rawValue: UInt8
		
		private static let	b0 = Self( rawValue: 1 << 0 )
		private static let	b1 = Self( rawValue: 1 << 1 )
		private static let	b2 = Self( rawValue: 1 << 2 )
		private static let	b3 = Self( rawValue: 1 << 3 )
		private static let	b4 = Self( rawValue: 1 << 4 )
		private static let	b5 = Self( rawValue: 1 << 5 )
		private static let	b6 = Self( rawValue: 1 << 6 )
		private static let	b7 = Self( rawValue: 1 << 7 )
		
		private static let	catMask:		Self = [ b0,b1,b2 ]
		private static let	catEnd:			Self = []
		private static let	catNil:			Self = [ b0 ]
		private static let	catVal:			Self = [ b1 ]
		private static let	catPtr:			Self = [ b0, b1 ]
		
		private static let	hasKeyID:		Self = [ b3 ]	// catNil, catVal, catPtr
		private static let	hasObjID:		Self = [ b5 ]	// catVal, catPtr
		private static let	hasTypeID:		Self = [ b4 ]	// catVal
		private static let	hasBytes:		Self = [ b6 ]	// catVal
		
		private static let	conditional:	Self = [ b4 ]	// conditional
		
		enum Category {
			case End, Nil, Val, Ptr
		}
		
		var category : Category {
			get throws {
				let cat = self.intersection( Self.catMask )
				switch cat {
				case Self.catEnd:	return .End
				case Self.catNil:	return .Nil
				case Self.catVal:	return .Val
				case Self.catPtr:	return .Ptr
				default:
					throw GCodableError.decodingError(
						Self.self, GCodableError.Context(
							debugDescription: "Unknown code category \(cat)"
						)
					)
				}
			}
		}
		
		var hasKeyID		: Bool { self.contains( Self.hasKeyID ) }
		var hasObjID		: Bool { self.contains( Self.hasObjID ) }
		var hasTypeID		: Bool { self.contains( Self.hasTypeID ) }
		var hasBytes		: Bool { self.contains( Self.hasBytes ) }
		var isConditional	: Bool { self.contains( Self.conditional ) }
	
		static func End() -> Self {
			return catEnd
		}

		static func Nil( keyID:UIntID? ) -> Self {
			var code	= catNil
			if keyID	!= nil { code.formUnion( hasKeyID ) }
			return code
		}
		
		static func Ptr( keyID:UIntID?, objID:UIntID, conditional:Bool ) -> Self {
			var code	= catPtr.union( hasObjID )
			if keyID	!= nil { code.formUnion( hasKeyID ) }
			if conditional { code.formUnion( Self.conditional ) }
			return code
		}
		
		static func  Val( keyID:UIntID?, typeID:UIntID?, objID:UIntID?, bytes:Bytes? ) -> Self {
			var code	= catVal
			if keyID	!= nil { code.formUnion( hasKeyID ) }
			if typeID	!= nil { code.formUnion( hasTypeID ) }
			if objID	!= nil { code.formUnion( hasObjID ) }
			if bytes	!= nil { code.formUnion( hasBytes ) }
			return code
		}
	}
	
	case End
	case Nil( keyID:UIntID? )
	case Ptr( keyID:UIntID?, objID:UIntID, conditional:Bool )
	case Val( keyID:UIntID?, typeID:UIntID?, objID:UIntID?, bytes:Bytes? )
}

extension FileBlock {
	var objID : UIntID? {
		switch self {
		case .Ptr( _, let objID, _ ):		return	objID
		case .Val( _, _, let objID, _ ):	return	objID
		default:							return	nil
		}
	}

	var typeID : UIntID? {
		switch self {
		case .Val( _, let typeID,_ , _):	return	typeID
		default:							return	nil
		}
	}

	var bytes : Bytes? {
		switch self {
		case .Val( _, _ , _ , let bytes ):	return	bytes
		default:							return	nil
		}
	}

	var keyID : UIntID? {
		switch self {
		case .Nil( let keyID ):				return	keyID
		case .Ptr( let keyID, _, _ ):		return	keyID
		case .Val( let keyID, _, _, _ ):	return	keyID
		default:							return	nil
		}
	}
	var conditional : Bool {
		switch self {
		case .Ptr( _, _, let conditional ):	return	conditional
		default:							return	false
		}
	}
}

extension FileBlock {
	enum Level { case exit, same, enter }
	var level : Level {
		switch self {
		case .Val( _, _ , _ , let bytes ):	return	bytes == nil ? .enter : .same
		case .End:	return .exit
		default:	return .same
		}
	}
}

extension FileBlock : BinaryOType {
	func write( to wbuffer: inout BinaryWriteBuffer ) throws {
		switch self {
		case .End:
			try Code.End().write(to: &wbuffer)
		case .Nil( let keyID ):
			try Code.Nil(keyID: keyID).write(to: &wbuffer)
			if let keyID	{ try keyID.write(to: &wbuffer) }
		case .Ptr( let keyID, let objID, let conditional ):
			try Code.Ptr(keyID: keyID, objID: objID, conditional:conditional ).write(to: &wbuffer)
			if let keyID	{ try keyID.write(to: &wbuffer) }
			try objID.write(to: &wbuffer)
		case .Val( let keyID, let typeID, let objID, let bytes ):
			try Code.Val(keyID: keyID, typeID: typeID, objID: objID, bytes: bytes).write(to: &wbuffer)
			if let keyID	{ try keyID.write(to: &wbuffer) }
			if let typeID	{ try typeID.write(to: &wbuffer) }
			if let objID	{ try objID.write(to: &wbuffer) }
			if let bytes	{ try bytes.write(to: &wbuffer) }
		}
	}
}

extension FileBlock {
	init(from rbuffer: inout BinaryReadBuffer, fileHeader:FileHeader ) throws {
		let code	= try Code(from: &rbuffer)

		switch try code.category {
		case .End:
			self	= .End
		case .Nil:
			let keyID	= code.hasKeyID ? try UIntID.init(from: &rbuffer) : nil
			self = .Nil(keyID: keyID)
		case .Ptr:
			let keyID	= code.hasKeyID ? try UIntID.init(from: &rbuffer) : nil
			let objID	= try UIntID.init(from: &rbuffer)
			self = .Ptr( keyID: keyID, objID: objID, conditional: code.isConditional )
		case .Val:
			let keyID	= code.hasKeyID ? try UIntID.init(from: &rbuffer) : nil
			let typeID	= code.hasTypeID ? try UIntID.init(from: &rbuffer) : nil
			let objID	= code.hasObjID ? try UIntID.init(from: &rbuffer) : nil
			let bytes	= code.hasBytes ? try Bytes.init(from: &rbuffer) : nil
			self = .Val( keyID: keyID, typeID: typeID, objID: objID, bytes: bytes )
		}
	}
}

extension FileBlock {
	func readableOutput(
		options:			GraphDumpOptions,
		binaryValue: 		BinaryOType?,
		classDataMap cdm:	ClassDataMap?,
		keyStringMap ksm: 	KeyStringMap?
	) -> String {
		func typeName( _ typeID:UInt32, _ options:GraphDumpOptions, _ classDataMap:[UIntID:ClassData]? ) -> String {
			if let classData	= classDataMap?[typeID] {
				if options.contains( .showReferenceVersion ) {
					return "\(classData.readableTypeName) V\(classData.encodeVersion)"
				} else {
					return classData.readableTypeName
				}
			} else {
				return "TYPE\(typeID)"
			}
		}

		func small( _ value: Any, _ options:GraphDumpOptions, maxLength:Int = 64 ) -> String {
			let phase1 = String(describing: value)
			if options.contains( .noTruncation ) {
				return phase1
			} else {
				let phase2	= phase1.count > maxLength ?
					phase1.prefix(maxLength).appending("…") : phase1
				
				return value is String ? "\"\(phase2)\"" : phase2
			}
		}
		
		func keyName( _ keyID:UIntID?, _ keyStringMap: [UIntID:String]? ) -> String {
			if let keyID {
				if let key = keyStringMap?[keyID] {
					return "+ \"\(key)\": "
				} else {
					return "+ KEY\(keyID): "
				}
			} else {
				return "- "
			}
		}

		
		let classDataMap = options.contains( .resolveTypeIDs ) ? cdm : nil
		let keyStringMap = options.contains( .resolveKeyIDs ) ? ksm : nil
		
		switch self {
		case .End:
			return 	"."
		case .Nil( let keyID ):
			return keyName( keyID, keyStringMap ).appending("nil")
		case .Ptr( let keyID, let objID, let conditional ):
			return keyName( keyID, keyStringMap ).appending(
				conditional ? "PTR\(objID)?" : "PTR\(objID)"
			)
		case .Val( let keyID, let typeID, let objID, let bytes ):
			//	VAL			= value		= []
			//	BIV			= binValue	= [bytes]
			//	REF			= ref		= [typeID]
			//	BIR			= binRef	= [typeID,bytes]
			//	VAL_objID	= iValue	= [objID]
			//	BIV_objID	= iBinValue	= [objID,bytes]
			//	REF_objID	= iRef		= [objID,typeID]
			//	BIR_objID	= iBinRef	= [objID,typeID,bytes]

			var string = keyName( keyID, keyStringMap )
			
			switch (typeID != nil,bytes != nil) {
			case (false, false)	: string = "VAL"
			case (false, true)	: string = "BIV"
			case (true,  false)	: string = "REF"
			case (true,  true)	: string = "BIR"
			}
			if let objID {
				string.append( "\(objID)" )
			}
			if let typeID {
				string.append( " \( typeName( typeID,options,classDataMap ) )")
			}
			if let bytes {
				if let binaryValue {
					string.append( " \( small( binaryValue, options ) )")
				} else {
					string.append( " {\(bytes.count) bytes}")
				}
			}
			return 	string
		}
	}
}







