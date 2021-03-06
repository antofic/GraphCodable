//	MIT License
//
//	Copyright (c) 2021 Antonino Ficarra
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
@testable import GraphCodable

/*
fileprivate extension Hashable where Self: AnyObject {
	func hash(into hasher: inout Hasher) {
		hasher.combine( ObjectIdentifier(self) )
	}
}

fileprivate extension Equatable where Self: AnyObject {
	static func == (lhs:Self, rhs:Self) -> Bool {
		return lhs === rhs
	}
}

fileprivate func == <T:AnyObject>(lhs: T, rhs: T) -> Bool {
	return lhs === rhs
}

fileprivate func != <T:AnyObject>(lhs: T, rhs: T) -> Bool {
	return lhs !== rhs
}
*/

/*

THESE TESTS ARE DISBLED FOR NOW

*/


final class TypeVersionAndReplaceTests: XCTestCase {
	func testTypeVersion() throws {
	}
	
	/*
	func testTypeVersion() throws {
		var data : Data
		
		do {
			class Person : GCodable {
				let name : String
				
				init( name:String ) {
					self.name	= name
				}
				
				private enum Key : String {
					case name
				}
				
				required init(from decoder: GDecoder) throws {
					name	= try decoder.decode( for:Key.name )
				}
				
				func encode(to encoder: GEncoder) throws {
					try encoder.encode( name, for:Key.name )
				}
			}
			let person	= Person( name:"   Liz   Taylor   " )
			
			//	encoding a Person (with all whitespaces in its name...)
			data	= try GraphEncoder().encode( person )
		}
		
		//	now in new version of of our app we
		//	change the Person implementation
		//	choosing to store the name as components
		//	because we dont because we don't want all
		//	those whitespaces in the name string.
		//	How to decode files that contain the old
		//	version of Person?
		
		do {
			class Person : GCodable {	// Person V1
				let nameComponents	: [String]
				
				var name : String {
					return nameComponents.joined(separator: " ")
				}
				
				private init( nameComponents: [String] ) {
					self.nameComponents = nameComponents
				}
				
				convenience init( name: String ) {
					self.init( nameComponents: name.split { return $0.isWhitespace || $0.isNewline } .map { return String($0) } )
				}
				
				// we change Person encodeVersion
				static var	encodeVersion:	UInt32 {
					return 1
				}
				
				private enum Key : String {
					case name, nameComponents
				}
				
				func encode(to encoder: GEncoder) throws {
					try encoder.encode( nameComponents, for: Key.nameComponents )
				}
				
				required init(from decoder: GDecoder) throws {
					// we get the encondend Person version
					let encodedVersion = try decoder.encodedVersion( Self.self )
					
					switch  encodedVersion {
					case 0:	// previous Person version
						let name = try decoder.decode( for: Key.name ) as String
						self.nameComponents	= name.split { return $0.isWhitespace || $0.isNewline } .map { return String($0) }
					case Self.encodeVersion:	// actual Person version
						self.nameComponents	= try decoder.decode( for: Key.nameComponents )
					default:
						preconditionFailure( "Unknown \(Self.self) version \(encodedVersion)!" )
					}
				}
			}
			
			var person : Person
			
			//	data the previous version of Person...
			person	= try GraphDecoder().decode(Person.self, from: data)
			XCTAssertEqual( person.name , "Liz Taylor" )
			
			//	encoding the actual version of Person
			data	= try GraphEncoder().encode( person )
			
			//	decoding the actual version of Person
			person	= try GraphDecoder().decode(Person.self, from: data)
			XCTAssertEqual( person.name , "Liz Taylor" )
		}
	}
	*/
	
	/*
	func testReplaceTypeAndHelp() throws {
		var data : Data
		
		do {
			struct Pippo : GCodable, Equatable, Hashable, CustomStringConvertible {
				var description: String { return "Pippo" }
				init() {}
				init(from decoder: GDecoder) throws {}
				func encode(to encoder: GEncoder) throws {}
			}
			
			let a = Pippo()
			let b = Pippo()
			let inRoot = [ a : b ]
			XCTAssertEqual( inRoot.description , "[Pippo: Pippo]" )
			
			data = try GraphEncoder().encode( inRoot )
		}
		
		/*
		Suppose we want to change the typeName from Pippo to NewPippo in
		a new software version. How to read the previous data?
		*/
		
		// reinitializa the register to delete all previous registrations
		GTypesRepository.initialize()
		
		do { //	new software version:
			struct NewPippo : GCodable, Equatable, Hashable, CustomStringConvertible {
				var description: String { return "NewPippo" }
				init() {}
				init(from decoder: GDecoder) throws {}
				func encode(to encoder: GEncoder) throws {}
			}
			
			//	we define a dummy typename with the old type Name
			struct Pippo {}
			
			//	So we tell the registry to build a NewPippo every
			//	time a Pippo is encountered in the data:
			try NewPippo.replace(type: Pippo.self)
			
			//	We can also ask the decoder which types must be
			//	registered to open those data.
			//		try GraphDecoder().help(from: data)
			//	provides a string with the appropriate function.
			print( try GraphDecoder().help(from: data) )
			//	Note: help also shows the version of the type in
			//	the comment ( // V=... )
			
			
			//	This is, so we call it.
			func initializeGraphCodable() {
				//	inizializes the register with the main module name
				//	obtained from #fileID:
				GTypesRepository.initialize()
				
				//	register all GCodable types:
				NewPippo.register()	// V=0
				Swift.Dictionary<NewPippo,NewPippo>.register()	// V=0
			}
			initializeGraphCodable()
			
			//	Note: in the real software we will add the registration of
			//	the new types to our already existing:
			//		initializeGraphCodable() { ... }
			//	Note: the substitution of a type is a rather complex
			//	operation because it can be nested inside many other
			//	types. In this case, we have replaced Pippo with NewPippo
			//	within a Dictionary type.
			
			let outRoot = try GraphDecoder().decode( [NewPippo:NewPippo].self, from: data)
			XCTAssertEqual( outRoot.description , "[NewPippo: NewPippo]" )
		}
	}
	*/
	
	/*
	func testReplaceTypeAndHelp() throws {
		var data : Data
		
		do {
			class Pippo : GCodable, Equatable, Hashable, CustomStringConvertible {
				var description: String { return "Pippo" }
				init() {}
				required init(from decoder: GDecoder) throws {}
				func encode(to encoder: GEncoder) throws {}
			}
			
			let a = Pippo()
			let b = Pippo()
			let inRoot = [ a : b ]
			XCTAssertEqual( inRoot.description , "[Pippo: Pippo]" )
			
			data = try GraphEncoder().encode( inRoot )
		}
		
		/*
		Suppose we want to change the typeName from Pippo to NewPippo in
		a new software version. How to read the previous data?
		*/
		
		// reinitializa the register to delete all previous registrations
		GTypesRepository.initialize()
		
		do { //	new software version:
			class NewPippo : GCodable, Equatable, Hashable, CustomStringConvertible {
				var description: String { return "NewPippo" }
				init() {}
				required init(from decoder: GDecoder) throws {}
				func encode(to encoder: GEncoder) throws {}
			}
			
			//	we define a dummy typename with the old type Name
			class Pippo {}
			
			do {
				//	So we tell the registry to build a NewPippo every
				//	time a Pippo is encountered in the data:
				try NewPippo.replace(type: Pippo.self)
				
				//	We can also ask the decoder which types must be
				//	registered to open those data.
				//		try GraphDecoder().help(from: data)
				//	provides a string with the appropriate function.
				print( try GraphDecoder().help(from: data) )
				//	Note: help also shows the version of the type in
				//	the comment ( // V=... )
			}
			
			//	This is, so we call it.
			func initializeGraphCodable() {
				//	inizializes the register with the main module name
				//	obtained from #fileID:
				GTypesRepository.initialize()
				
				//	register all GCodable types:
				NewPippo.register()	// V=0
			}
			initializeGraphCodable()
	
			//	we recall replace because GTypesRepository.initialize()
			//	has reinizialed it.
			try NewPippo.replace(type: Pippo.self)

			//	Note: in the real software we will add the registration of
			//	the new types to our already existing:
			//		initializeGraphCodable() { ... }
			//	Note: the substitution of a type is a rather complex
			//	operation because it can be nested inside many other
			//	types. In this case, we have replaced Pippo with NewPippo
			//	within a Dictionary type.
			
			let outRoot = try GraphDecoder().decode( [NewPippo:NewPippo].self, from: data)
			XCTAssertEqual( outRoot.description , "[NewPippo: NewPippo]" )
		}
	}
	*/
}
