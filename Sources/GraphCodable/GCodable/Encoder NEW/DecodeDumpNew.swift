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

/*
import Foundation

final class DecodeDumpNew: DumpProtocol {
	var	fileHeader		: FileHeader
	var	options			: GraphDumpOptions
	var	dataSize		: Int?
	var	dumpString		= String()
	var beforeBody		= false
	var tabs			: String?

	var classDataMap	: ClassDataMap
	var keyStringMap	: KeyStringMap

	let readBlocks		: ReadBlocks
	let classNameMap	: ClassNameMap?

	
	init(
		from ioDecoder:BinaryIODecoder, classNameMap:ClassNameMap?, options:GraphDumpOptions
	) throws {
		var readBlockDecoder	= try DecodeReadBlocks( from: ioDecoder )
	
		self.dataSize		= ioDecoder.fileSize
		self.fileHeader		= readBlockDecoder.fileHeader
		self.readBlocks		= try readBlockDecoder.readBlocks()
		self.classDataMap	= try readBlockDecoder.classDataMap()
		self.classNameMap	= classNameMap
		self.keyStringMap	= try readBlockDecoder.keyStringMap()
		self.options		= options
	}
	
	var referenceMapDescription: String? {
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

		var string		= ""
		let qualified	= options.contains( .qualifiedNamesInConstructionMap )
		
		let classInfoMap	= ClassInfo.classInfoMapNoThrow(
			classDataMap: classDataMap, classNameMap: classNameMap
		)
		
		if classInfoMap.isEmpty == false,
		   options.contains( .onlyUndecodableClassesInConstructionMap ) == false
		{
			string.append( "Encoded class types will be decoded as:" )
			do {
				let couples	: [(TypeID,any GDecodable.Type)] = classInfoMap.map {
					($0.key, $0.value.decodedType)
				}
				if options.contains( .hideTypeIDsInConstructionMap ) {
					string = couples.sorted { name( $0.1 ) < name( $1.1 ) }.reduce(into: string) {
						$0.append( "\n- \( typeString($1.1) )" )
					}
				} else {
					string = couples.sorted { $0.0.id < $1.0.id }.reduce(into: string) {
						$0.append( "\n- TYPE\( $1.0 ): \( typeString($1.1) )" )
					}
				}
			}
			do {
				let couples	: [(TypeID,any (AnyObject & GDecodable).Type)] = classInfoMap.compactMap {
					if let replacedClass = $0.value.classData.replacedClass {
						return ($0.key,replacedClass)
					} else {
						return nil
					}
				}
				if couples.isEmpty == false {
					string.append( "\nwhere:" )
					if options.contains( .hideTypeIDsInConstructionMap ) {
						string = couples.sorted { name( $0.1 ) < name( $1.1 ) }.reduce(into: string) {
							$0.append( "\n- the encoded \( typeString($1.1) )")
							$0.append( "\n  was replaced by \( typeString($1.1.decodeType) )" )
						}
					} else {
						string = couples.sorted { $0.0.id < $1.0.id }.reduce(into: string) {
							$0.append( "\n- the encoded TYPE\( $1.0 ): \( typeString($1.1) )")
							$0.append( "\n  was replaced by \( typeString($1.1.decodeType) )" )
						}
					}
				}
			}
			string.append( "\n" )
		}
		
		
		let undecodableClassDataMap	= ClassInfo.undecodablesClassDataMap(
			classDataMap: classDataMap, classNameMap: classNameMap
		)
		if undecodableClassDataMap.isEmpty == false {
			//	let undecodables	= undecodableClassDataMap.values
			string.append( "Undecodable encoded classes:" )
			if options.contains( .hideTypeIDsInConstructionMap ) {
				string = undecodableClassDataMap.sorted { $0.1.qualifiedName < $1.1.qualifiedName }.reduce(into: string) {
					$0.append( "\n- class  \( $1.1.qualifiedName )")
					if options.contains( .showMangledNames ) {
						$0.append( "\n\t  mangledName = \( $1.1.mangledName )" )
					}
				}
			} else {
				string = undecodableClassDataMap.sorted { $0.0.id < $1.0.id }.reduce(into: string) {
					$0.append( "\n\t- class  \( $1.1.qualifiedName )")
					if options.contains( .showMangledNames ) {
						$0.append( "\n\t  mangledName = \( $1.1.mangledName )" )
					}
				}
			}
			string.append( "\n" )
		}
		
		return string
	}
}
*/