//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

final class EncodeDump : EncodeFileBlocks {
	weak var			delegate	: (any EncodeFileBlocksDelegate)?
	private var			fileHeader	: FileHeader
	private var			dumpOptions	: GraphDumpOptions
	private var			fileSize	: Int?
	private var			dumpString	= String()
	private var 		beforeBody	= false
	private var 		tabs		: Tabs

	init( fileHeader: FileHeader, dumpOptions:GraphDumpOptions, fileSize:Int? ) {
		self.fileHeader		= fileHeader
		self.dumpOptions	= dumpOptions
		self.fileSize		= fileSize
		self.tabs			= Tabs(
			tabString: dumpOptions.contains( .dontIndentBody ) ? Tabs.noTabs : Tabs.defaultTabs
		)
	}

	static func titleString( _ string: String, filler:Character = "=", lenght: Int = 88 ) -> String {
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
	
	func append(_ string: String ) {
		beforeBodyAppend()
		dumpString.append( string )
	}
	
	func append(_ fileBlock: FileBlock, value: (any GEncodable)?) {
		beforeBodyAppend()
		
		if dumpOptions.contains( .showBody ) {
			if case FileBlock.End = fileBlock { tabs.exit() }
			
			dumpString.append( tabs.description )
			let fileBlockString = fileBlock.description(
				options:		dumpOptions,
				classDataMap:	delegate?.classDataMap,
				keyStringMap:	delegate?.keyStringMap
			) {
				if let value {
					if let string = value as? String {
						return "\"\(string)\""
					} else {
						return String( describing: value )
					}
				} else {
					return nil
				}
			}
			
			dumpString.append( fileBlockString )
			dumpString.append( "\n" )
	
			if case FileBlock.Val = fileBlock { tabs.enter() }
		}
	}
	
	// FileBlockEncoder protocol
	func appendEnd() throws {
		append( .End, value:nil )
	}
	func appendNil( keyID:KeyID? ) throws {
		append( .Nil(keyID: keyID), value:nil )
	}
	func appendPtr( keyID:KeyID?, idnID:IdnID, conditional:Bool ) throws {
		append( .Ptr(keyID: keyID,idnID:idnID, conditional:conditional ), value:nil )
	}
	
	func appendVal(keyID: KeyID?, refID: RefID?, idnID: IdnID?, value: some GEncodable ) throws {
		append( .Val(keyID: keyID, idnID:idnID, refID:refID ), value:value )
	}

	func appendBin( keyID:KeyID?, refID:RefID?, idnID:IdnID?, binaryValue: some GBinaryEncodable ) throws {
		append( .Bin(keyID: keyID, idnID:idnID, refID:refID, binSize: 0 ), value:binaryValue  )
	}

	// FileBlockEncoder protocol end

	func dump() -> String {
		beforeBodyAppend()

		dumpString.append( referenceMapDescription )
		dumpString.append( keyMapDescription )

		if dumpOptions.contains( .hideSectionTitles ) == false {
			dumpString.append( Self.titleString( "" ) )
		}
		
		return dumpString
	}

	// private -----------------------------------
	
	private func beforeBodyAppend() {
		if beforeBody == false {
			beforeBody	= true
			
			dumpString.append( headerDescription )
			dumpString.append( helpDescription )
			
			if dumpOptions.contains( .showBody ) {
				if dumpOptions.contains( .hideSectionTitles ) == false {
					dumpString.append( Self.titleString( "BODY" ) )
				}
				// tabs = dumpOptions.contains( .dontIndentBody ) ? nil : ""
			}
		}
	}
	
	private var headerDescription : String {
		var string = ""
		if dumpOptions.contains( .showHeader ) {
			if dumpOptions.contains( .hideSectionTitles ) == false {
				string.append( Self.titleString( "HEADER" ) )
			}
			string.append( fileHeader.description(fileSize: fileSize) )
			string.append( "\n" )
		}
		return string
	}

	private var helpDescription : String {
		var string = ""
		if dumpOptions.contains( .showHelp ) {
			if dumpOptions.contains( .hideSectionTitles ) == false {
				string.append( Self.titleString( "HELP" ) )
			}
			string.append( Self.helpString )
			string.append( "\n" )
		}
		return string
	}

	private var referenceMapDescription : String {
		func typeString( _ options:GraphDumpOptions, _ classData:ClassData ) -> String {
			var string	= ""
			let qualified	= options.contains( .qualifiedTypeNames )
			
			string.append( "class \(classData.className( qualified: qualified ))" )
			if options.contains( .showMangledClassNames ) {
				let version	= "\(classData.encodedClassVersion)".align(.right, length: 4, filler: "0")
				if qualified == false {
					string.append( "\n  QualifiedName    = \( classData.className(qualified: true) )"  )
				}
				string.append( "\n  MangledClassName = \( classData.mangledClassName )"  )
				string.append( "\n  EncodedVersion   = \( version )"  )
			}
			return string
		}

		var string = ""
		if dumpOptions.contains( .showReferenceMap ) {
			if dumpOptions.contains( .hideSectionTitles ) == false {
				string.append( Self.titleString( "REFERENCEMAP" ) )
			}
			if let description = delegate?.referenceMapDescription {
				string.append( description )
			} else {
				string.append( "Encoded class types:\n" )
				string = delegate?.classDataMap.reduce( into: string ) {
					result, tuple in
					result.append( "- TYPE\( tuple.key ): \( typeString( dumpOptions, tuple.value ) )\n")
				} ?? "UNAVAILABLE DELEGATE \(#function)\n"
			}
		}
		return string
	}
	
	private var keyMapDescription : String {
		var string = ""
		if dumpOptions.contains( .showKeyStringMap ) {
			if dumpOptions.contains( .hideSectionTitles ) == false {
				string.append( Self.titleString( "KEYMAP" ) )
			}
			string = delegate?.keyStringMap.reduce( into: string ) {
				result, tuple in
				result.append( "- KEY\( tuple.key ): \"\( tuple.value )\"\n" )
			} ?? "UNAVAILABLE DELEGATE \(#function)\n"
		}
		return string
	}
	
	
	static private var helpString : String  {
"""
Codes:
\tVAL<idnID?>   = GCodable value tipe
\tREF<idnID?>   = GCodable reference type
\tBIV<idnID?>   = GBinaryCodable value type
\tBIR<idnID?>   = GBinaryCodable reference type
\tNIL<idnID?>   = nil (Optional.none) VAL,REF,BIV,BIR
\tPTS<idnID>    = Strong pointer to VAL,REF,BIV,BIR
\tPTC<idnID>    = Conditional pointer to VAL,REF,BIV,BIR

\t• VAL, REF are followed by their internal fields ending with '.'
\t• The '+ key/KEY<keyID>' symbol precedes keyed fields.
\t• The '-' symbol precedes unkeyed fields.
\t• idnID is an unique integer code associated with REF, VAL, BIV,
\t  BIR, NIL only if they have identities. The PTC and PTS idnID
\t  code is the same as the REF, VAL, BIV, BIR, NIL the pointer
\t  points to.

Other codes:
\tTYPE<refID>  = uniquely identifies the class of a reference
\t                (REF, BIR). Depending on the options selected,
\t                the qualified name of the class may be displayed
\t                alternatively.
\tKEY<keyID>   = uniquely identifies the key used in keyed coding.
\t			    Only used by the VAL and REF fields.
"""
	}

}
