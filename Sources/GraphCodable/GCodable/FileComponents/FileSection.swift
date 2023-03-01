//
//  File.swift
//  
//
//  Created by Antonino Ficarra on 01/03/23.
//

import Foundation

typealias UIntID = UInt32

enum FileSection : UInt16, CaseIterable, BinaryIOType {
	case body = 0x0010, classDataMap = 0x0020, keyStringMap = 0x0030
}

//	NEW FILE FORMAT:
//		A) fileHeader		= FileHeader
//		B) sectionMap		= SectionMap	= [FileSection : Range<Int>]
//		C) bodyBlocks		= BodyBlocks	= [FileBlock]
//	then, in any order:
//		D) classDataMap		= ClassDataMap	= [UIntID : ClassData]
//		E) keyStringMap		= KeyStringMap	= [UIntID : String]
//	sectionMap[section] contains the range of the related section in the file
typealias SectionMap		= [FileSection : Range<Int>]
typealias BodyBlocks		= [FileBlock]
typealias ClassDataMap		= [UIntID : ClassData]
typealias KeyStringMap		= [UIntID : String]

