//
//  File.swift
//  
//
//  Created by Antonino Ficarra on 01/03/23.
//

import Foundation

struct ClassNamesDecoder {
	let fileHeader				: FileHeader
	let	classDataMap			: ClassDataMap
	
	init<Q>( from data:Q ) throws where Q:Sequence, Q.Element==UInt8 {
		var binaryDecoder	= try BinaryDecoder( from: data )
		fileHeader			= binaryDecoder.fileHeader
		classDataMap		= try binaryDecoder.classDataMap()
	}
}

