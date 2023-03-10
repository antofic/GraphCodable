//	MIT License
//
//	Copyright (c) 2021-2023 Antonino Ficarra
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

final class StringEncoder : FileBlockEncoder {
	typealias			Output		= String
	weak var			delegate			: FileBlockEncoderDelegate?
	private var			fileHeader			: FileHeader
	private var			options				: GraphDumpOptions
	private var			binaryIOVersion		: UInt16
	private var			dataSize			: Int?
	private var			dump		= String()
	private var 		dumpStart	= false
	private var 		tabs		: String?

	init( fileHeader: FileHeader, dumpOptions:GraphDumpOptions, binaryIOVersion:UInt16, dataSize:Int? ) {
		self.fileHeader			= fileHeader
		self.options			= dumpOptions
		self.binaryIOVersion	= binaryIOVersion
		self.dataSize			= dataSize
	}

	static func titleString( _ string: String, filler:Character = "=", lenght: Int = 69 ) -> String {
		var title	= ""
		if string.count > 0 {
			title.append( String(repeating: filler, count: 1) )
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
			
			if options.contains( .showHeader ) {
				if options.contains( .hideSectionTitles ) == false {
					dump.append( Self.titleString( "HEADER" ) )
				}
				dump.append( fileHeader.description )
				dump.append( "\n" )
				dump.append( Self.titleString( "BinaryIO",filler:"-" ) )
				dump.append( "- Version   = \(binaryIOVersion.format("10")) {\(MemoryLayout.size(ofValue: binaryIOVersion)) bytes}\n" )
				if let dataSize = dataSize {
					dump.append( "- Data size = \(dataSize.format("10")) bytes\n" )
				}
			}
			
			if options.contains( .showHelp ) {
				if options.contains( .hideSectionTitles ) == false {
					dump.append( Self.titleString( "HELP" ) )
				}
				dump.append( infoString )
				dump.append( "\n" )
			}
			
			if options.contains( .showBody ) {
				if options.contains( .hideSectionTitles ) == false {
					dump.append( Self.titleString( "BODY" ) )
				}
				tabs = options.contains( .dontIndentBody ) ? nil : ""
			}
		}
	}
	
	func append(_ string: String ) throws {
		try dumpInit()
		dump.append( string )
	}
	
	func append(_ fileBlock: FileBlock, binaryValue: BinaryOType?) throws {
		try dumpInit()
		
		if options.contains( .showBody ) {
			if case .exit = fileBlock.level { tabs?.removeLast() }
			if let tbs = tabs { dump.append( tbs ) }
			
			let binValue = options.contains( .showValueDescriptionInBody ) ? binaryValue : nil 
			
			dump.append( fileBlock.description(
				options:		options,
				binaryValue:	binValue,
				classDataMap:	delegate?.classDataMap,
				keyStringMap:	delegate?.keyStringMap
			) )
			dump.append( "\n" )
			
			if case .enter = fileBlock.level { tabs?.append("\t") }
		}
	}
	
	func appendEnd() throws {
		try append( .End, binaryValue:nil )
	}
	func appendNil( keyID:KeyID? ) throws {
		try append( .Nil(keyID: keyID), binaryValue:nil )
	}
	func appendPtr( keyID:KeyID?, objID:ObjID, conditional:Bool ) throws {
		try append( .Ptr(keyID: keyID,objID:objID, conditional:conditional ), binaryValue:nil )
	}
	func appendVal( keyID:KeyID?, typeID:TypeID?, objID:ObjID?, binaryValue:BinaryOType? ) throws {
		let size = binaryValue != nil ? BinSize() : nil
		
		try append( .Val(keyID: keyID, objID:objID, typeID:typeID, binSize: size), binaryValue:binaryValue  )
	}
	
	func output() throws -> String {
		func typeString( _ options:GraphDumpOptions, _ classData:ClassData ) -> String {
			var string	= ""
			if options.contains( .showMangledNamesInReferenceMap ) {
				string.append( "QualifiedName  = \( classData.qualifiedName )"  )
				string.append( "\n\t\t\tMangledName    = \( classData.mangledName ?? "nil" )"  )
				string.append( "\n\t\t\tNSClassName    = \( classData.nsClassName )"  )
				string.append( "\n\t\t\tEncodedVersion = \( classData.encodedVersion )"  )
			} else {
				string.append("\(classData.qualifiedName) V\(classData.encodedVersion)")
			}
			return string
		}
		
		try dumpInit()
		
		if options.contains( .showReferenceMap ) {
			if options.contains( .hideSectionTitles ) == false {
				dump.append( Self.titleString( "REFERENCEMAP" ) )
			}
			dump = delegate?.classDataMap.reduce( into: dump ) {
				result, tuple in
				result.append( "TYPE\( tuple.key.id.format("04") ):\t\( typeString( options, tuple.value ) )\n")
			} ?? "UNAVAILABLE DELEGATE \(#function)\n"
		}
		
		if options.contains( .showKeyStringMap ) {
			if options.contains( .hideSectionTitles ) == false {
				dump.append( Self.titleString( "KEYMAP" ) )
			}
			dump = delegate?.keyStringMap.reduce( into: dump ) {
				result, tuple in
				result.append( "KEY\( tuple.key.id.format("04") ):\t\"\( tuple.value )\"\n" )
			} ?? "UNAVAILABLE DELEGATE \(#function)\n"
		}
		if options.contains( .hideSectionTitles ) == false {
			dump.append( Self.titleString( "" ) )
		}
		
		return dump
	}
	
	private var infoString : String  {
"""
Codes:
\tVAL<objID?>   = GCodable value tipe
\tREF<objID?>   = GCodable reference type
\tBIV<objID?>   = BinaryIO value type
\tBIR<objID?>   = BinaryIO reference type
\tNIL<objID?>   = nil (Optional.none) VAL,REF,BIV,BIR
\tPTS<objID>    = Strong pointer to VAL,REF,BIV,BIR
\tPTC<objID>    = Conditional pointer to VAL,REF,BIV,BIR

\t• VAL, REF are followed by their internal fields ending with '.'
\t• The '+ key/KEY<keyID>' symbol precedes keyed fields.
\t• The '-' symbol precedes unkeyed fields.
\t• objID is an unique integer code associated with REF, VAL, BIV,
\t  BIR, NIL only if they have identities. The PTC and PTS objID
\t  code is the same as the REF, VAL, BIV, BIR, NIL the pointer
\t  points to.

Other codes:
\tTYPE<typeID>  = uniquely identifies the class of a reference
\t                (REF, BIR). Depending on the options selected,
\t                the qualified name of the class may be displayed
\t                alternatively.
\tKEY<keyID>    = uniquely identifies the key used in keyed coding.
\t			    Only used by the VAL and REF fields.
"""
	}

}
