//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import XCTest
import GraphCodable

//	••••••• We compare GraphCoder() with Codable JSON and PropertyList Coders
//	••••••• Use 'Release' build configuration


// --------------------------------------------------------------------------------

final class PerformanceTests: XCTestCase {
	struct RecursiveData : Codable, GCodable, BCodable {
		var larges	: [RecursiveData]
		var string	: String
		var array	: [Int]
		
		private enum Key : String {
			case larges, string, array
		}

		// Create count! (factorial) RecursiveData struct, so keep this number down!!!
		init( count:Int = 0 ) {
			self.larges	= count > 0 ? [RecursiveData](repeating: RecursiveData( count: count - 1 ), count: count) : [RecursiveData]()
			self.string	= "ABCDEFG"
			self.array	= [Int](repeating: Int.max - count, count:30)
		}
		
		func encode(to encoder: some GEncoder) throws {
			try encoder.encode( larges, for: Key.larges )
			try encoder.encode( string, for: Key.string )
			try encoder.encode( array,  for: Key.array  )
		}
		
		init(from decoder: some GDecoder) throws {
			larges	= try decoder.decode( for: Key.larges )
			string	= try decoder.decode( for: Key.string )
			array	= try decoder.decode( for: Key.array )
		}
		
		init(from decoder: inout some GraphCodable.BDecoder) throws {
			larges	= try decoder.decode()
			string	= try decoder.decode()
			array	= try decoder.decode()
		}
		
		func encode(to encoder: inout some GraphCodable.BEncoder) throws {
			try encoder.encode( larges )
			try encoder.encode( string )
			try encoder.encode( array )
		}
	}

	
	let input	= RecursiveData( count:7 )
	
	func testDataSize() throws {
		// just to print generated file size.
		print("\n\n\n- DATA SIZES ----------------------------------")
		print("GraphEncoder (bin=on)  : \( try GraphEncoder().encode(input) as Data )")
		print("GraphEncoder (bin=off) : \( try GraphEncoder().encode(input) as Data )")
		print("BinariIOReader         : \( try input.binaryIOData(userVersion: 0) as Data )")
		print("JSONEncoder            : \( try JSONEncoder().encode(input) )")
		print("PropertyListEncoder    : \( try PropertyListEncoder().encode(input) )")
		print("-----------------------------------------------\n\n\n")
	}
	
	func testGraphEncoder() throws {
		measure {
			do {
				let _		= try GraphEncoder().encode(input) as Bytes
			} catch {}
		}
	}

	func testGraphEncoderBinOff() throws {
		measure {
			do {
				let _		= try GraphEncoder().encode(input) as Bytes
			} catch {}
		}
	}

	func testBinaryWriter() throws {
		measure {
			do {
				let _		= try input.binaryIOData(userVersion: 0) as Bytes
			} catch {}
		}
	}

	func testJSONEncoder() throws {
		measure {
			do {
				let _		= try JSONEncoder().encode(input)
			} catch {}
		}
	}
	
	func testPropertyListEncoder() throws {
		measure {
			do {
				let _		= try PropertyListEncoder().encode(input)
			} catch {}
		}
	}


	func testGraphDecoder() throws {
		let data	= try GraphEncoder().encode(input) as Bytes
		measure {
			do {
				let	_		= try GraphDecoder().decode( type(of:input), from: data )
			} catch {}
		}
	}

	func testGraphDecoderBinOff() throws {
		let data	= try GraphEncoder().encode(input) as Bytes
		measure {
			do {
				let	_		= try GraphDecoder().decode( type(of:input), from: data )
			} catch {}
		}
	}

	func testBinaryReader() throws {
		let data	= try input.binaryIOData(userVersion: 0) as Bytes
		measure {
			do {
				let	_		= try type(of:input).init( binaryIOData: data)
			} catch {}
		}
	}

	func testJSONDecoder() throws {
		let data	= try JSONEncoder().encode(input)
		measure {
			do {
				let	_		= try JSONDecoder().decode( type(of:input), from: data )
			} catch {}
		}
	}
	
	func testPropertyListDecoder() throws {
		let data	= try PropertyListEncoder().encode(input)
		measure {
			do {
				let	_		= try PropertyListDecoder().decode( type(of:input), from: data )
			} catch {}
		}
	}

}

