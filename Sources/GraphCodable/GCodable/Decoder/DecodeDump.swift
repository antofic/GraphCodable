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
	let encodedClassMap	: EncodedClassMap
	let classNameMap	: ClassNameMap?
	let keyStringMap	: KeyStringMap
	let dumpOptions		: GraphDumpOptions
	
	init( from ioDecoder:BinaryIODecoder, classNameMap:ClassNameMap?, options:GraphDumpOptions ) throws {
		var readBlockDecoder	= try DecodeReadBlocks( from: ioDecoder )
		
		self.fileSize			= ioDecoder.fileSize
		self.fileHeader			= readBlockDecoder.fileHeader
		self.readBlocks			= try readBlockDecoder.readBlocks()
		self.encodedClassMap	= try readBlockDecoder.encodedClassMap()
		self.classNameMap		= classNameMap
		self.keyStringMap		= try readBlockDecoder.keyStringMap()
		self.dumpOptions		= options
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
		if dumpOptions.contains( .showFlatBody ) {
			do {
				let (rootNode,nodeMap)	= try BlockNode.flatGraph(
					blocks:	readBlocks
				)
				let string = rootNode.dump(
					nodeMap:			nodeMap,
					encodedClassMap:	encodedClassMap,
					keyStringMap:		keyStringMap,
					options: 			dumpOptions
				)
				encoderDump.append( string )
			} catch {
				encoderDump.append( "Error generating FLAT BODY" )
				encoderDump.append( "\(error)" )
			}
		}
		return encoderDump.dump()
	}
	
	var referenceMapDescription: String? {
		func name( _ type:Any.Type ) -> String {
			EncodedClass.typeName( type, qualified: qualified )
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
		
		let decodedClassMap	= DecodedClass.decodedClassMapNoThrow(
			encodedClassMap: encodedClassMap, classNameMap: classNameMap
		)
		
		if decodedClassMap.isEmpty == false,
		   dumpOptions.contains( .onlyUndecodableClassesInReferenceMap ) == false
		{
			string.append( "Encoded class types will be decoded as:" )
			do {
				let couples	: [(refID:RefID,type:any GDecodable.Type)] = decodedClassMap.map {
					($0.key, $0.value.decodedType)
				}
				string = couples.sorted { $0.refID < $1.refID }.reduce(into: string) {
					$0.append( "\n- TYPE\( $1.refID ): \( typeString($1.type) )" )
				}
			}
			do {
				let couples	: [(refID:RefID,type:any (AnyObject & GDecodable).Type)] = decodedClassMap.compactMap {
					if let replacedClass = $0.value.encodedClass.replacedClass {
						return ($0.key,replacedClass)
					} else {
						return nil
					}
				}
				if couples.isEmpty == false {
					string.append( "\nwhere:" )
					string = couples.sorted { $0.refID < $1.refID }.reduce(into: string) {
						$0.append( "\n- the encoded TYPE\( $1.refID ): \( typeString($1.type) )")
						$0.append( "\n  was replaced by \( typeString($1.type.decodeType) )" )
					}
				}
			}
			string.append( "\n" )
		}
		
		
		let undecodableEncodedClassMap	= DecodedClass.undecodablesEncodedClassMap(
			encodedClassMap: encodedClassMap, classNameMap: classNameMap
		)
		if undecodableEncodedClassMap.isEmpty == false {
			string.append( "Undecodable encoded classes:" )
			string = undecodableEncodedClassMap.sorted { $0.key < $1.key }.reduce(into: string) {
				$0.append( "\n- TYPE\( $1.key ): class \( $1.value.className(qualified: qualified) )")
					if dumpOptions.contains( .showMangledClassNames ) {
						let version	= "\($1.value.encodedClassVersion)".align(.right, length: 4, filler: "0")
						if qualified == false {
							$0.append( "\n  QualifiedName    = \( $1.value.className(qualified: true) )"  )
						}
						$0.append( "\n  MangledClassName = \( $1.value.mangledClassName )" )
						$0.append( "\n  EncodedVersion   = \( version )" )
					}
			}
			string.append( "\n" )
		}
		
		return string
	}
}

