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

// -------------------------------------------------
// ----- DataEncoderDelegate
// -------------------------------------------------

protocol DataEncoderDelegate : AnyObject {
	var	classDataMap:	ClassDataMap { get }
	var	keyStringMap:	KeyStringMap { get }
	var dumpOptions:	GraphDumpOptions { get }
}

// -------------------------------------------------
// ----- DataEncoder protocol
// -------------------------------------------------

protocol DataEncoder : AnyObject {
	associatedtype	Output
	
	var delegate	: DataEncoderDelegate? { get set }
	
	func append( _ fileBlock: FileBlock, binaryValue:BinaryOType? ) throws
	func output() throws -> Output
	
	func appendNil( keyID:UIntID ) throws
	func appendValue( keyID:UIntID ) throws
	func appendBinValue( keyID:UIntID, binaryValue:BinaryOType ) throws
	func appendRef( keyID:UIntID, typeID:UIntID ) throws
	func appendBinRef( keyID:UIntID, typeID:UIntID, binaryValue:BinaryOType ) throws
	func appendIdValue( keyID:UIntID, objID:UIntID ) throws
	func appendIdBinValue( keyID:UIntID, objID:UIntID, binaryValue:BinaryOType ) throws
	func appendIdRef( keyID:UIntID, typeID:UIntID, objID:UIntID ) throws
	func appendIdBinRef( keyID:UIntID,  typeID:UIntID, objID:UIntID, binaryValue:BinaryOType ) throws
	func appendStrongPtr( keyID:UIntID, objID:UIntID ) throws
	func appendConditionalPtr( keyID:UIntID, objID:UIntID ) throws
	func appendEnd() throws
	
}

extension DataEncoder {
	func appendNil( keyID:UIntID ) throws {
		try append( .Nil(keyID: keyID), binaryValue:nil )
	}
	func appendValue( keyID:UIntID ) throws {
		try append( .value(keyID: keyID), binaryValue:nil )
	}
	func appendBinValue( keyID:UIntID, binaryValue:BinaryOType ) throws {
		let bytes	= try binaryValue.binaryData() as Bytes
		try append( .binValue(keyID: keyID, bytes: bytes), binaryValue:binaryValue  )
	}
	func appendRef( keyID:UIntID, typeID:UIntID ) throws {
		try append( .ref(keyID: keyID, typeID:typeID ), binaryValue:nil )
	}
	func appendBinRef( keyID:UIntID, typeID:UIntID, binaryValue:BinaryOType ) throws {
		let bytes	= try binaryValue.binaryData() as Bytes
		try append( .binRef(keyID: keyID, typeID:typeID, bytes: bytes), binaryValue:binaryValue  )
	}
	func appendIdValue( keyID:UIntID, objID:UIntID ) throws {
		try append( .idValue(keyID: keyID, objID: objID), binaryValue:nil )
	}
	func appendIdBinValue( keyID:UIntID, objID:UIntID, binaryValue:BinaryOType ) throws {
		let bytes	= try binaryValue.binaryData() as Bytes
		try append( .idBinValue(keyID: keyID, objID: objID, bytes: bytes), binaryValue:binaryValue )
	}
	func appendIdRef( keyID:UIntID, typeID:UIntID, objID:UIntID )throws {
		try append( .idRef(keyID: keyID, typeID: typeID, objID: objID), binaryValue:nil )
	}
	func appendIdBinRef( keyID:UIntID,  typeID:UIntID, objID:UIntID, binaryValue:BinaryOType ) throws {
		let bytes	= try binaryValue.binaryData() as Bytes
		try append( .idBinRef(keyID: keyID, typeID:typeID, objID: objID, bytes: bytes), binaryValue:binaryValue )
	}
	func appendStrongPtr( keyID:UIntID, objID:UIntID ) throws {
		try append( .strongPtr(keyID: keyID, objID: objID), binaryValue:nil )
	}
	func appendConditionalPtr( keyID:UIntID, objID:UIntID ) throws {
		try append( .conditionalPtr(keyID: keyID, objID: objID), binaryValue:nil )
	}
	func appendEnd() throws {
		try append( .end, binaryValue:nil )
	}
}

// -------------------------------------------------
// ----- BinEncoder
// -------------------------------------------------

final class BinEncoder<Output:MutableDataProtocol> : DataEncoder {
	weak var			delegate			: DataEncoderDelegate?
	let					fileHeader			= FileHeader()
	private var			wbuffer				= BinaryWriteBuffer()
	private var 		sectionMap			= SectionMap()
	private var			sectionMapPosition	= 0
	
	private func writeInit() throws {
		if sectionMap.isEmpty {
			// entriamo la prima volta e quindi scriviamo header e section map.
			
			// write header:
			try fileHeader.write(to: &wbuffer)
			sectionMapPosition	= wbuffer.position
			
			// write section map:
			for section in FileSection.allCases {
				sectionMap[ section ] = Range(uncheckedBounds: (0,0))
			}
			try sectionMap.write(to: &wbuffer)
			let bounds	= (wbuffer.position,wbuffer.position)
			sectionMap[ FileSection.body ] = Range( uncheckedBounds:bounds )
		}
	}
	
	func append(_ fileBlock: FileBlock, binaryValue: BinaryOType?) throws {
		try writeInit()
		try fileBlock.write(to: &wbuffer)
	}
	
	func output() throws -> Output {
		try writeInit()
		
		var bounds	= (sectionMap[.body]!.startIndex,wbuffer.position)
		sectionMap[.body]	= Range( uncheckedBounds:bounds )
		
		// referenceMap:
		try delegate!.classDataMap.write(to: &wbuffer)
		bounds	= ( bounds.1,wbuffer.position )
		sectionMap[ FileSection.classDataMap ] = Range( uncheckedBounds:bounds )
		
		// keyStringMap:
		try delegate!.keyStringMap.write(to: &wbuffer)
		bounds	= ( bounds.1,wbuffer.position )
		sectionMap[ FileSection.keyStringMap ] = Range( uncheckedBounds:bounds )
		
		do {
			//	sovrascrivo la sectionMapPosition
			//	ora che ho tutti i valori
			defer { wbuffer.setEof() }
			wbuffer.position	= sectionMapPosition
			try sectionMap.write(to: &wbuffer)
		}
		
		return wbuffer.data()
	}
}

// -------------------------------------------------
// ----- StringEncoder
// -------------------------------------------------

final class StringEncoder : DataEncoder {
	typealias			Output		= String
	weak var			delegate	: DataEncoderDelegate?
	let					fileHeader	= FileHeader()
	private var			dump		= String()
	private var 		dumpStart	= false
	private var 		tabs		: String?
	
	static func titleString( _ string: String, filler:Character = "=", lenght: Int = 66 ) -> String {
		var title	= ""
		if string.count > 0 {
			title.append( String(repeating: filler, count: 2) )
			title.append( " " )
			title.append( string )
			let remains	= lenght - title.count
			if remains > 1 {
				title.append( " " )
				title.append( String(repeating: filler, count: remains - 1 ) )
			}
		} else {
			title.append( String(repeating: filler, count: lenght ) )
		}
		title.append( "\n" )
		return title
	}
	
	private func dumpInit() throws {
		if dumpStart == false {
			dumpStart	= true
			
			let options	= delegate?.dumpOptions ?? .readable
			
			if options.contains( .showHeader ) {
				if options.contains( .hideSectionTitles ) == false {
					dump.append( Self.titleString( "HEADER" ) )
				}
				dump.append( fileHeader.description )
				dump.append( "\n" )
			}
			
			if options.contains( .hideBody ) == false {
				if options.contains( .hideSectionTitles ) == false {
					dump.append( Self.titleString( "BODY" ) )
				}
				tabs = options.contains( .dontIndentLevel ) ? nil : ""
			}
		}
	}
	
	func append(_ string: String ) throws {
		try dumpInit()
		dump.append( string )
	}
	
	func append(_ fileBlock: FileBlock, binaryValue: BinaryOType?) throws {
		try dumpInit()
		let options	= delegate?.dumpOptions ?? .readable
		
		if options.contains( .hideBody ) == false {
			if case .exit = fileBlock.level { tabs?.removeLast() }
			if let tbs = tabs { dump.append( tbs ) }
			
			dump.append( fileBlock.readableOutput(
				options:		options,
				binaryValue:	binaryValue,
				classDataMap:	delegate?.classDataMap,
				keyStringMap:	delegate?.keyStringMap
			) )
			dump.append( "\n" )
			
			if case .enter = fileBlock.level { tabs?.append("\t") }
		}
	}
	
	func output() throws -> String {
		func typeString( _ options:GraphDumpOptions, _ classData:ClassData ) -> String {
			var string	= "\(classData.readableTypeName) V\(classData.encodeVersion)"
			if options.contains( .showMangledClassNames ) {
				string.append( "\n\t\t\tMangledName = \( classData.mangledTypeName ?? "nil" )"  )
				string.append( "\n\t\t\tNSTypeName  = \( classData.objcTypeName )"  )
			}
			return string
		}
		
		try dumpInit()
		let options	= delegate?.dumpOptions ?? .readable
		
		if options.contains( .showClassDataMap ) {
			if options.contains( .hideSectionTitles ) == false {
				dump.append( Self.titleString( "REFERENCEMAP" ) )
			}
			dump = delegate?.classDataMap.reduce( into: dump ) {
				result, tuple in
				result.append( "TYPE\( tuple.key ):\t\( typeString( options, tuple.value ) )\n")
			} ?? "UNAVAILABLE DELEGATE \(#function)\n"
		}
		
		if options.contains( .showKeyStringMap ) {
			if options.contains( .hideSectionTitles ) == false {
				dump.append( Self.titleString( "KEYMAP" ) )
			}
			dump = delegate?.keyStringMap.reduce( into: dump ) {
				result, tuple in
				result.append( "KEY\( tuple.key ):\t\"\( tuple.value )\"\n" )
			} ?? "UNAVAILABLE DELEGATE \(#function)\n"
		}
		if options.contains( .hideSectionTitles ) == false {
			dump.append( Self.titleString( "" ) )
		}
		
		return dump
	}
}
