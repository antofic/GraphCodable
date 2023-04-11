//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/
//
//	Copyright (c) 2021-2023 Antonino Ficarra

import XCTest
@testable import GraphCodable

//	testClassicParentChildsPattern types
extension Hashable where Self: AnyObject {
	func hash(into hasher: inout Hasher) {
		hasher.combine( ObjectIdentifier(self) )
	}
}

extension Equatable where Self: AnyObject {
	static func == (lhs:Self, rhs:Self) -> Bool {
		return lhs === rhs
	}
}

func == <T:AnyObject>(lhs: T, rhs: T) -> Bool {
	return lhs === rhs
}

func != <T:AnyObject>(lhs: T, rhs: T) -> Bool {
	return lhs !== rhs
}

// --------------------------------------------------------------------------------

final class ClassicParentChildsPattern: XCTestCase {
	class Node : Hashable, GCodable, CustomStringConvertible {
		private weak var _parent : Node?
		private(set) var childs = Set<Node>()
		
		init() {}
		
		var	parent : Node? {
			get { return _parent }
			set {
				if newValue != _parent {
					self._parent?.childs.remove( self )
					self._parent = newValue
					self._parent?.childs.insert( self )
				}
			}
		}
		
		private enum Key : String {
			case childs, _parent
		}
		
		func encode(to encoder: some GEncoder) throws {
			try encoder.encode( childs, for: Key.childs )
			
			//	weak variables should be encoded conditionally
			try encoder.encodeConditional( _parent, for: Key._parent )
		}
		
		required init(from decoder: some GDecoder) throws {
			self.childs	= try decoder.decode( for: Key.childs )
			//	deferDecode for weak variable:
			try decoder.deferDecode( for: Key._parent ) { self._parent = $0 }
		}
		
		var description: String {
			return "\(type(of:self) ) \(childs)"
		}
	}
	class View		: Node {}
	class Window	: View {}	// we make window subclass of view
	class Screen	: View {}	// we make the screen subclass of view
	
	func testClassicParentChildsPattern() throws {
		let screen	= Screen()
		
		let windowA	= Window()
		let windowB	= Window()
		
		let view1	= View()
		let view2	= View()
		let view3	= View()
		let view4	= View()
		
		view4.parent	= view1		// a subview of a view
		
		view1.parent	= windowA	// a view of a window
		view2.parent	= windowA	// a view of a window
		view3.parent	= windowB	// a view of a window
		
		windowA.parent	= screen
		windowB.parent	= screen
		
		let inRoot	= screen as View	// we encode as View
		let data	= try GraphEncoder().encode( inRoot ) as Bytes
		let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
		
		// we obtain the true inRoot type:
		XCTAssertTrue( outRoot is Screen, #function)
		
		print("\n\n\noutRoot: '\(outRoot)'\n\n\n")
		
		//	print(outRoot) == 'Screen = [Window = [View = []], Window = [View = [], View = [View = []]]]'
		//	or a permutation of if
		
		//	we descend the hierarchy to a view and then return to the top
		XCTAssertEqual( outRoot, outRoot.childs.first?.childs.first?.parent?.parent! , #function)
	}
}

