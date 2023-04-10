//
//  File.swift
//  
//
//  Created by Antonino Ficarra on 01/03/23.
//

import Foundation

//---------------------------------------------------------------------------------------------
//	Codable file format:
//	5 parts A, B, C, D, E:
//		A) fileHeader		= FileHeader
//			contains
//		B) sectionMap		= SectionMap	= [FileSection : Range<Int>]
//		C) fileBlocks		= FileBlocks	= [FileBlock]
//	then, in any order:
//		D) classDataMap		= ClassDataMap	= [UIntID : ClassData]
//		E) keyStringMap		= KeyStringMap	= [UIntID : String]
//
//	A) fileHeader: a 24 bytes fixed size header
//	B) sectionMap: a dictionary contains the range of the related section (C, D, E) in the file
//	C) fileBlocks: an array of FileBlock's
//		A Fileblock stores in binary:
//			• a value/reference (.Val)
//		or:
//			• a pointer (.Ptr), strong or conditional, to a value/reference with identity
//		or:
//			• a token (.Nil) when Optional.none is encountered
//		or:
//			• a token (.end) when all fields of a type are encoded
//	D) classDataMap: a dictionary [refID: ClassData]
//		ClassData contains the information needed to construct reference types
//		from the type name to support inheritance
//	E) keyStringMap: a dictionary [keyID: keystring]
//		A table that stores the association between a numeric identifier and
//		each keystring encountered during encoding
//---------------------------------------------------------------------------------------------

enum FileSection : UInt16, CaseIterable, BCodable {
	case body = 0x0010, classDataMap = 0x0020, keyStringMap = 0x0030
}

typealias SectionMap		= [FileSection : Range<Int>]
typealias FileBlocks		= [FileBlock]
typealias ClassDataMap		= [RefID : ClassData]
typealias KeyStringMap		= [KeyID : String]

