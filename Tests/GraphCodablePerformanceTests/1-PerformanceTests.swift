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

import XCTest
import GraphCodable

//	••••••• We compare GraphCoder() with Codable JSON and PropertyList Coders
//	••••••• Use 'Release' build configuration


// --------------------------------------------------------------------------------

final class PerformanceTests: XCTestCase {
	struct RecursiveData : Codable, GCodable, BinaryIOType {
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
		
		func encode(to encoder: GEncoder) throws {
			try encoder.encode( larges, for: Key.larges )
			try encoder.encode( string, for: Key.string )
			try encoder.encode( array,  for: Key.array  )
		}
		
		init(from decoder: GDecoder) throws {
			larges	= try decoder.decode( for: Key.larges )
			string	= try decoder.decode( for: Key.string )
			array	= try decoder.decode( for: Key.array )
		}
		
		func write(to wbuffer: inout GraphCodable.BinaryWriteBuffer) throws {
			try larges.write(to: &wbuffer)
			try string.write(to: &wbuffer)
			try array.write(to: &wbuffer)
		}
		
		init(from rbuffer: inout GraphCodable.BinaryReadBuffer) throws {
			larges	= try [RecursiveData](from: &rbuffer)
			string	= try String( from: &rbuffer )
			array	= try [Int]( from: &rbuffer )
		}
	}

	
	let input	= RecursiveData( count:7 )
	
	func testDataSize() throws {
		// just to print generated file size.
		print("\n\n\n- DATA SIZES ----------------------------------")
		print("GraphEncoder (bin=on)  : \( try GraphEncoder( .enableLibraryBinaryIOTypes ).encode(input) as Data )")
		print("GraphEncoder (bin=off) : \( try GraphEncoder( .disableLibraryBinaryIOTypes ).encode(input) as Data )")
		print("BinariIOReader         : \( try input.binaryData() as Data )")
		print("JSONEncoder            : \( try JSONEncoder().encode(input) )")
		print("PropertyListEncoder    : \( try PropertyListEncoder().encode(input) )")
		print("-----------------------------------------------\n\n\n")
	}
	
	func testGraphEncoder() throws {
		measure {
			do {
				let _		= try GraphEncoder( .enableLibraryBinaryIOTypes ).encode(input) as Bytes
			} catch {}
		}
	}

	func testGraphEncoderBinOff() throws {
		measure {
			do {
				let _		= try GraphEncoder( .disableLibraryBinaryIOTypes ).encode(input) as Bytes
			} catch {}
		}
	}

	func testBinaryWriter() throws {
		measure {
			do {
				let _		= try input.binaryData() as Bytes
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
		let data	= try GraphEncoder( .disableLibraryBinaryIOTypes ).encode(input) as Bytes
		measure {
			do {
				let	_		= try GraphDecoder().decode( type(of:input), from: data )
			} catch {}
		}
	}

	func testBinaryReader() throws {
		let data	= try input.binaryData() as Bytes
		measure {
			do {
				let	_		= try type(of:input).init( binaryData: data)
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

