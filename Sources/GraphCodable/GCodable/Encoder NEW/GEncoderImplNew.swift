//
//  File.swift
//  
//
//  Created by Antonino Ficarra on 09/04/23.
//
/*
import Foundation

struct GEncoderImplNew {
	var userInfo							= [String:Any]()
	private let 		encodeOptions		: GraphEncoder.Options
	let 				userVersion			: UInt32
	let 				archiveIdentifier	: String?

	init( _ options: GraphEncoder.Options, userVersion:UInt32, archiveIdentifier: String? ) {
		#if DEBUG
		self.encodeOptions		= [options, .printWarnings]
		#else
		self.encodeOptions		= options
		#endif
		self.userVersion		= userVersion
		self.archiveIdentifier	= archiveIdentifier
	}
	
	private func ioEncoderAndHeader() -> (BinaryIOEncoder, FileHeader) {
		let ioEncoder		= BinaryIOEncoder(
			userVersion: userVersion,
			archiveIdentifier: archiveIdentifier,
			userData: self,
			enableCompression: !encodeOptions.contains( .disableCompression )
		)
		let fileHeader		= FileHeader(
			binaryIOEncoder: ioEncoder,
			gcoadableFlags: encodeOptions.contains( .dontMoveEncodedData ) ? [] : .useBinaryIOInsert
		)
		return (ioEncoder,fileHeader)
	}

	func encodeRoot<T,Q>( _ value: T ) throws -> Q where T:GEncodable, Q:MutableDataProtocol {
		let (ioEncoder,fileHeader)	= ioEncoderAndHeader()
		
		let binaryEncoder = EncodeBinaryNew<Q>(
			ioEncoder: 		ioEncoder,
			fileHeader: 	fileHeader,
			encodeOptions:	encodeOptions,
			userInfo:		userInfo,
			userVersion:	userVersion
		)
		
		try binaryEncoder.encode( value )
		return try binaryEncoder.output()
	}
	
	func dumpRoot<T>( _ value: T, options: GraphDumpOptions ) throws -> String where T:GEncodable {
		let (_,fileHeader)	= ioEncoderAndHeader()
		
		let dumpEncoder	= EncodeDumpNew(
			fileHeader:		fileHeader,
			dumpOptions:	options,
			fileSize:		nil,	// no data size during encode
			encodeOptions:	encodeOptions,
			userInfo:		userInfo,
			userVersion:	userVersion
		)
		try dumpEncoder.encode( value )
		return dumpEncoder.dump()
	}
}
*/
