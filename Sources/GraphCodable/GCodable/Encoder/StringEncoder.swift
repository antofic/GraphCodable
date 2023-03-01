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
