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

import Foundation

final class StringDecoder: FileBlockEncoderDelegate {
	let	dataSize		: Int
	let fileHeader		: FileHeader
	let readBlocks		: ReadBlocks
	let classDataMap	: ClassDataMap
	let classNameMap	: ClassNameMap?
	let keyStringMap	: KeyStringMap
	let dumpOptions		: GraphDumpOptions
	
	init( from readBuffer:BinaryReadBuffer, classNameMap:ClassNameMap?, options:GraphDumpOptions ) throws {
		var readBlockDecoder	= try ReadBlockDecoder( from: readBuffer )
		
		self.dataSize		= readBuffer.dataSize
		self.fileHeader		= readBlockDecoder.fileHeader
		self.readBlocks		= try readBlockDecoder.readBlocks()
		self.classDataMap	= try readBlockDecoder.classDataMap()
		self.classNameMap	= classNameMap
		self.keyStringMap	= try readBlockDecoder.keyStringMap()
		self.dumpOptions	= options
	}

	func dump() throws -> String {
		let stringEncoder	= StringEncoder(
			fileHeader:			fileHeader,
			dumpOptions:		dumpOptions,
			dataSize: 			dataSize
		)
		stringEncoder.delegate	= self
		try readBlocks.forEach { try stringEncoder.append($0.fileBlock, binaryValue: nil) }
		if dumpOptions.contains( .showFlattenedBody ) {
			let (rootElement,elementMap)	= try FlattenedElement.rootElement(
				readBlocks:	readBlocks,
				keyStringMap:	keyStringMap,
				reverse:		true
			)
			let string = rootElement.dump(
				elementMap:		elementMap,
				classDataMap:	classDataMap,
				keyStringMap:	keyStringMap,
				options: 		dumpOptions
			)
			try stringEncoder.append( string )
		}
		if dumpOptions.contains( .showConstructionMap ) {
			try stringEncoder.append( dumpConstructionMap() )
		}
		
		return try stringEncoder.output()
	}
		
	private func dumpConstructionMap() throws -> String {
		func name( _ type:Any.Type ) -> String {
			_typeName( type, qualified:qualified )
		}
		
		func typeString( _ type:Any.Type ) -> String {
			if type is AnyClass {
				return "class \( name( type ) )"
			} else {
				return "struct \( name( type ) )"
			}
		}

		var dump		= ""
		let qualified	= dumpOptions.contains( .qualifiedNamesInConstructionMap )
		
		dump.append( StringEncoder.titleString("CONSTRUCTIONMAP" ) )
		
		let classInfoMap	= ClassInfo.classInfoMapNoThrow(
			classDataMap: classDataMap, classNameMap: classNameMap
		)
		
		if classInfoMap.isEmpty == false,
		   dumpOptions.contains( .onlyUndecodableClassesInConstructionMap ) == false
		{
			dump.append( "Encoded class types will create the following decoded types:" )
			do {
				let couples	: [(TypeID,GDecodable.Type)] = classInfoMap.map {
					($0.key, $0.value.decodedType)
				}
				if dumpOptions.contains( .hideTypeIDsInConstructionMap ) {
					dump = couples.sorted { name( $0.1 ) < name( $1.1 ) }.reduce(into: dump) {
						$0.append( "\n\t- \( typeString($1.1) )" )
					}
				} else {
					dump = couples.sorted { $0.0.id < $1.0.id }.reduce(into: dump) {
						$0.append( "\n\t- TYPE\( $1.0 ): \( typeString($1.1) )" )
					}
				}
			}
			do {
				let couples	: [(TypeID,(AnyObject & GDecodable).Type)] = classInfoMap.compactMap {
					if let replacedClass = $0.value.classData.replacedClass {
						return ($0.key,replacedClass)
					} else {
						return nil
					}
				}
				if couples.isEmpty == false {
					dump.append( "\nwhere:" )
					if dumpOptions.contains( .hideTypeIDsInConstructionMap ) {
						dump = couples.sorted { name( $0.1 ) < name( $1.1 ) }.reduce(into: dump) {
							$0.append( "\n\t- the encoded \( typeString($1.1) )")
							$0.append( "\n\t  was replaced by \( typeString($1.1.decodeType) )" )
						}
					} else {
						dump = couples.sorted { $0.0.id < $1.0.id }.reduce(into: dump) {
							$0.append( "\n\t- the encoded TYPE\( $1.0 ): \( typeString($1.1) )")
							$0.append( "\n\t  was replaced by \( typeString($1.1.decodeType) )" )
						}
					}
				}
			}
			dump.append( "\n" )
		}
		
		
		let undecodableClassDataMap	= ClassInfo.undecodablesClassDataMap(
			classDataMap: classDataMap, classNameMap: classNameMap
		)
		if undecodableClassDataMap.isEmpty == false {
			//	let undecodables	= undecodableClassDataMap.values
			dump.append( "Undecodable encoded classes:" )
			if dumpOptions.contains( .hideTypeIDsInConstructionMap ) {
				dump = undecodableClassDataMap.sorted { $0.1.qualifiedName < $1.1.qualifiedName }.reduce(into: dump) {
					$0.append( "\n\t- class  \( $1.1.qualifiedName )")
					if dumpOptions.contains( .showMangledNames ) {
						$0.append( "\n\t\t  mangledName = \( $1.1.mangledName )" )
					}
				}
			} else {
				dump = undecodableClassDataMap.sorted { $0.0.id < $1.0.id }.reduce(into: dump) {
					$0.append( "\n\t- class  \( $1.1.qualifiedName )")
					if dumpOptions.contains( .showMangledNames ) {
						$0.append( "\n\t\t  mangledName = \( $1.1.mangledName )" )
					}
				}
			}
			dump.append( "\n" )
		}
		
		return dump
	}
}

