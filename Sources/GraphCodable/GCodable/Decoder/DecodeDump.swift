//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import Foundation

final class DecodeDump: EncodeFileBlocksDelegate {
	let	fileSize		: Int
	let fileHeader		: FileHeader
	let readBlocks		: ReadBlocks
	let classDataMap	: ClassDataMap
	let classNameMap	: ClassNameMap?
	let keyStringMap	: KeyStringMap
	let dumpOptions		: GraphDumpOptions
	
	init( from ioDecoder:BinaryIODecoder, classNameMap:ClassNameMap?, options:GraphDumpOptions ) throws {
		var readBlockDecoder	= try DecodeReadBlocks( from: ioDecoder )
		
		self.fileSize		= ioDecoder.fileSize
		self.fileHeader		= readBlockDecoder.fileHeader
		self.readBlocks		= try readBlockDecoder.readBlocks()
		self.classDataMap	= try readBlockDecoder.classDataMap()
		self.classNameMap	= classNameMap
		self.keyStringMap	= try readBlockDecoder.keyStringMap()
		self.dumpOptions	= options
	}

	func dump() -> String {
		let encoderDump	= EncodeDump(
			fileHeader:			fileHeader,
			dumpOptions:		dumpOptions,
			fileSize: 			fileSize
		)
		encoderDump.delegate	= self
		readBlocks.forEach {
			encoderDump.append( $0.fileBlock, value: nil )
		}
		if dumpOptions.contains( .showFlattenedBody ) {
			do {
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
				encoderDump.append( string )
			} catch {
				encoderDump.append( "Error generating FLATTENED BODY" )
				encoderDump.append( "\(error)" )
			}
		}
		return encoderDump.dump()
	}
	
	var referenceMapDescription: String? {
		func name( _ type:Any.Type ) -> String {
			ClassData.typeName( type, qualified: qualified )
		}
		
		func typeString( _ type:Any.Type ) -> String {
			if type is AnyClass {
				return "class \( name( type ) )"
			} else {
				return "struct \( name( type ) )"
			}
		}

		var string		= ""
		let qualified	= dumpOptions.contains( .qualifiedTypeNames )
		
		let classInfoMap	= ClassInfo.classInfoMapNoThrow(
			classDataMap: classDataMap, classNameMap: classNameMap
		)
		
		if classInfoMap.isEmpty == false,
		   dumpOptions.contains( .onlyUndecodableClassesInReferenceMap ) == false
		{
			string.append( "Encoded class types will be decoded as:" )
			do {
				let couples	: [(RefID,any GDecodable.Type)] = classInfoMap.map {
					($0.key, $0.value.decodedType)
				}
				string = couples.sorted { $0.0.id < $1.0.id }.reduce(into: string) {
					$0.append( "\n- TYPE\( $1.0 ): \( typeString($1.1) )" )
				}
			}
			do {
				let couples	: [(RefID,any (AnyObject & GDecodable).Type)] = classInfoMap.compactMap {
					if let replacedClass = $0.value.classData.replacedClass {
						return ($0.key,replacedClass)
					} else {
						return nil
					}
				}
				if couples.isEmpty == false {
					string.append( "\nwhere:" )
					string = couples.sorted { $0.0.id < $1.0.id }.reduce(into: string) {
						$0.append( "\n- the encoded TYPE\( $1.0 ): \( typeString($1.1) )")
						$0.append( "\n  was replaced by \( typeString($1.1.decodeType) )" )
					}
				}
			}
			string.append( "\n" )
		}
		
		
		let undecodableClassDataMap	= ClassInfo.undecodablesClassDataMap(
			classDataMap: classDataMap, classNameMap: classNameMap
		)
		if undecodableClassDataMap.isEmpty == false {
			string.append( "Undecodable encoded classes:" )
				string = undecodableClassDataMap.sorted { $0.0.id < $1.0.id }.reduce(into: string) {
					$0.append( "\n- TYPE\( $1.0 ): class \( $1.1.className(qualified: qualified) )")
					if dumpOptions.contains( .showMangledClassNames ) {
						let version	= "\($1.1.encodedClassVersion)".align(.right, length: 4, filler: "0")
						if qualified == false {
							$0.append( "\n  QualifiedName    = \( $1.1.className(qualified: true) )"  )
						}
						$0.append( "\n  MangledClassName = \( $1.1.mangledClassName )" )
						$0.append( "\n  EncodedVersion   = \( version )" )
					}
			}
			string.append( "\n" )
		}
		
		return string
	}
}

