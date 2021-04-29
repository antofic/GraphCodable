#  User Guide

## Initialization
GraphCodable must be initialized before using it by calling the function from the main module.
```swift
import GraphCodable

GTypesRepository.initialize()
```
When called with no arguments, GraphCodable uses this function to know the name of the swift main module and remove it from the type name (replacing it with an *asterisk*) so that reading a file does not depend on this name.
```swift

public final class GTypesRepository {
	public static func initialize( fromFileID fileID:String = #fileID )
	public static func initialize( mainModuleName name:String )
	...
}
```
Swift doesn't provide a way to get this name, not even at runtime. And so it is taken from `#fileID`.

## Types registration (first part)
Typically, the initialization is carried out simultaneously with the registration of all the types that can be decoded by defining a specific function as in the following example and calling it from your main module when your software starts.
```swift
import GraphCodable

func initializeGraphCodable() {
	GTypesRepository.initialize()	
	
	Body.register()
	Body.Presence.register()
	Boy.register()
	Girl.register()
	Presence.register()
	Swift.Array<Child>.register()
	Swift.Array<Swift.Int>.register()
	Swift.Dictionary<Swift.Int,Swift.String>.register()
	Swift.Set<Swift.Int>.register()
	Woman.register()
}

// call after startup:
initializeGraphCodable()
```
The encoder automatically registers all types it encounters, and so there is no need to register any types if you are decoding a file after encoding it for testing purposes. The next examples will take advantage of this feature. The following examples take advantage of this functionality, and so they just call `GTypesRepository.initialize()`.
We will return to the topic at the end of the document.

## Code Examples
Copy and paste examples in your main.swift file.

### Native types and collection support
```swift

import Foundation
import GraphCodable

GTypesRepository.initialize()

let inRoot	= [["a":1.5,"b":2.0],nil,["c":2.5,"d":3.0,"e":nil]]

// encode inRoot in data
let data	= try GraphEncoder().encode( inRoot )

// decode outRoot from data
let outRoot	= try GraphDecoder().decode( type(of:inRoot), from: data )

print( outRoot == inRoot )	// prints: true
```
### Complex Value Types

```swift
import Foundation
import GraphCodable

GTypesRepository.initialize()

struct Example : GCodable, Equatable {
	private(set) var name		: String
	private(set) var examples	: [Example]

	init( name : String, examples : [Example] = [Example]()) {
		self.name		= name
		self.examples	= examples
		}

	enum Key: String {
		case name, examples
	}

	init(from decoder: GDecoder) throws {
		self.name		= try decoder.decode( for: Key.name )
		self.examples	= try decoder.decode( for: Key.examples )
	}
	
	func encode(to encoder: GEncoder) throws {
		try encoder.encode( name, for:  Key.name )
		try encoder.encode( examples, for:  Key.examples )
	}
}

let eA	= Example(name: "exampleA")
let eB	= Example(name: "exampleB", examples: [eA,eA,eA] )

let inRoot	= eB

// encode inRoot in data
let data	= try GraphEncoder().encode( inRoot )

// decode outRoot from data
let outRoot	= try GraphDecoder().decode( type(of:inRoot), from: data )

print( outRoot == inRoot )	// prints: true
```
As you can see, GraphCodable uses enums with string rawValue as keys.

### Reference Types - Duplication - Keyed and unkeyed encode/decode

Up to now the behavior of GraphCodable is similar to that of Codable. That changes with reference types.
The same example with a reference type will show how GraphCodable don't duplicate it.  Codable duplicates it.

```swift
import Foundation
import GraphCodable

GTypesRepository.initialize()

final class Example : GCodable, Equatable, Codable {
	private(set) var name		: String
	private(set) var examples	: [Example]
	
	init( name : String, examples : [Example] = [Example]()) {
		self.name		= name
		self.examples	= examples
	}
	
	enum Key: String {
		case name, examples
	}
	
	init(from decoder: GDecoder) throws {
		self.name		= try decoder.decode( for: Key.name )
		self.examples	= try decoder.decode( for: Key.examples )
	}
	
	func encode(to encoder: GEncoder) throws {
		try encoder.encode( name, for:  Key.name )
		try encoder.encode( examples, for:  Key.examples )
	}
	
	static func == (lhs: Example, rhs: Example) -> Bool {
		return lhs.name == rhs.name && lhs.examples == rhs.examples
	}
}

let eA	= Example(name: "exampleA")
let eB	= Example(name: "exampleB", examples: [eA,eA,eA] )

let inRoot	= eB

do {	//	GraphCodable
	let data	= try GraphEncoder().encode( inRoot )
	let outRoot	= try GraphDecoder().decode( type(of:inRoot), from: data )
	
	print( outRoot == inRoot )	// prints: true
	print( outRoot.examples[0] === outRoot.examples[1] )	// prints: true --> we use '===': same reference!
	print( outRoot.examples[0] === outRoot.examples[2] )	// prints: true --> we use '===': same reference!
}

do {	//	Codable
	let data	= try JSONEncoder().encode( inRoot )
	let outRoot	= try JSONDecoder().decode( type(of:inRoot), from: data )
	
	print( outRoot == inRoot )	// prints: true
	print( outRoot.examples[0] === outRoot.examples[1] )	// prints: false --> we use '===': reference duplicated!
	print( outRoot.examples[0] === outRoot.examples[2] )	// prints: false --> we use '===': reference duplicated!
}
```

The same example using unkeyed coding. With unkeyed coding you must decode values in the same order in which they are encoded.

```swift
import Foundation
import GraphCodable

GTypesRepository.initialize()

final class Example : GCodable, Equatable {
	private(set) var name		: String
	private(set) var examples	: [Example]
	
	init( name : String, examples : [Example] = [Example]()) {
		self.name		= name
		self.examples	= examples
	}
	
	init(from decoder: GDecoder) throws {
		self.name		= try decoder.decode()
		self.examples	= try decoder.decode()
	}
	
	func encode(to encoder: GEncoder) throws {
		try encoder.encode( name )
		try encoder.encode( examples )
	}
	
	static func == (lhs: Example, rhs: Example) -> Bool {
		return lhs.name == rhs.name && lhs.examples == rhs.examples
	}
}

let eA	= Example(name: "exampleA")
let eB	= Example(name: "exampleB", examples: [eA,eA,eA] )

let inRoot	= eB

// encode inRoot in data
let data	= try GraphEncoder().encode( inRoot )

// decode outRoot from data
let outRoot	= try GraphDecoder().decode( type(of:inRoot), from: data )

print( outRoot == inRoot )	// prints: true
print( outRoot.examples[0] === outRoot.examples[1] )	// prints: true --> we use '===': same reference!
print( outRoot.examples[0] === outRoot.examples[2] )	// prints: true --> we use '===': same reference!
```
It is recommended that you use unkeyed coding not in cases like this, but rather when you need to store a single value or a sequence of values. The following example shows how array conformance is implemented in the GraphCodable using unkeyed encode/decode:

```swift
extension Array: GCodable where Element:GCodable {
	public func encode(to encoder: GEncoder) throws {
		for element in self {
			try encoder.encode( element )
		}
	}
	public init(from decoder: GDecoder) throws {
		self.init()

		self.reserveCapacity( try decoder.unkeyedCount() )

		while try decoder.unkeyedCount() > 0 {
			self.append( try decoder.decode() )
		}
	}
}
```
The latter case clearly shows that with GraphCodable **the values are removed from the decoder as they are decoded** and this also happens for keyed values.

### Reference Types - Inheritance

GraphCodable **supports inheritance**: in other words, the type of decoded object always corresponds to the real type of the encoded object, as you can see in the next example. Codable lost type information.

```swift
import Foundation
import GraphCodable

GTypesRepository.initialize()

class View : CustomStringConvertible, GCodable, Codable {
	init() {
	}
	required init(from decoder: GDecoder) throws {
	}
	func encode(to encoder: GEncoder) throws {
	}
	var description: String {
		return "\(type(of: self))"
	}
}

class Window : View {}

class Screen : Window {}

let inRoot	= [ View(), Window(), Screen() ]

print( type(of: inRoot) )	// print Array<View>
print( inRoot )				// print [View, Window, Screen]

do {	// GraphCodable
	let data	= try GraphEncoder().encode( inRoot )
	let outRoot	= try GraphDecoder().decode( type(of:inRoot), from: data )
	
	print( type(of: outRoot) )	// print Array<View>
	print( outRoot )			// print [View, Window, Screen]	--> true types are maintained
}

do {	// Codable
	let data	= try JSONEncoder().encode( inRoot )
	let outRoot	= try JSONDecoder().decode( type(of:inRoot), from: data )
	
	print( type(of: outRoot) )	// print Array<View>
	print( outRoot )			// print [View, View, View]	--> true types are lost
}
```

### Reference Types - Conditional encode

GraphCodable supports conditional encoding. Codable appears to be designed for conditional encoding in mind, but neither the JSONEncoder nor the PropertyListEncoder support it.

```swift
import Foundation
import GraphCodable

GTypesRepository.initialize()

class ConditionalList : GCodable {
	private (set) var next : ConditionalList?
	
	init( _ a: ConditionalList? = nil ) {
		self.next = a
	}
	
	private enum Key : String {
		case next
	}
	
	func encode(to encoder: GEncoder) throws {
		// conditionaEncode!
		try encoder.encodeConditional( next, for: Key.next )
	}
	
	required init(from decoder: GDecoder) throws {
		next	= try decoder.decode( for: Key.next )
	}
}

let a = ConditionalList()
let b = ConditionalList( a )
let c = ConditionalList( b )

do {
	let inRoot	= [ "a": a, "b": b, "c" : c ]
	let data	= try GraphEncoder().encode( inRoot )
	let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
	
	// "c.b" must be alive because there is at least one unconditional path from the root to "b"
	print( outRoot["c"]!.next != nil  )	// print true	--> "c.b" is alive
	
	// "b.a" must be alive because there is at least one unconditional path from the root to "a"
	print( outRoot["b"]!.next != nil  )	// print true 	--> "b.a" is alive
}

do {
	let inRoot	= [ "b": b, "c": c ]
	let data	= try GraphEncoder().encode( inRoot )
	let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
	
	// "c.b" must be alive because there is at least one unconditional path from the root to "b"
	print( outRoot["c"]!.next != nil  )	// print true 	--> "c.b" is alive
	
	// "b.a" must be nil because there is no unconditional path from the root to "a"
	print( outRoot["b"]!.next != nil  )	// print false	--> "b.a" is nil
}

do {
	let inRoot	= [ "a": a, "c" : c ]
	let data	= try GraphEncoder().encode( inRoot )
	let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
	
	// "c.b" must be nil because there is no unconditional path from the root to "b"
	print( outRoot["c"]!.next != nil  )	// print false	--> "c.b" is nil
}
```

### Reference Types - Directed Acyclic Graphs (DAG)

The variables that contain objects realize direct type graphs. Arc requires that strong variables do not create direct cyclical graphs because the cycles prevent the release of memory. Graphcodable is perfectly capable of encoding and decoding direct acyclic graphics (DAG) without the need for any special treatment.
The next example shows how GraphCodable encode and decode this [DAG](https://en.wikipedia.org/wiki/Directed_acyclic_graph#/media/File:Tred-G.svg) taken from this [Wikipedia page](https://en.wikipedia.org/wiki/Directed_acyclic_graph).
```
                 ╭───╮
   ┌────────────▶︎│ c │─────┐
   │             ╰───╯     │
   │               │       │
   │               ▼       ▼
 ╭───╮   ╭───╮   ╭───╮   ╭───╮
 │ a │──▶︎│ b │──▶︎│ d │──▶︎│ e │
 ╰───╯   ╰───╯   ╰───╯   ╰───╯
  │ │              ▲       ▲
  │ │              │       │
  │ └──────────────┘       │
  └────────────────────────┘
```
```swift
import Foundation
import GraphCodable

GTypesRepository.initialize()

class Node : Codable, GCodable {
	private (set) var connections = [String:Node]()
	let name : String
	
	subscript( name:String ) -> Node? {
		return connections[name]
	}
	
	func connect( to nodes: Node... ) {
		for node in nodes {
			connections[node.name]	= node
			}
	}
	
	init( _ name:String ) {
		self.name	= name
	}
	
	private enum Key : String {
		case name, connections
	}
	
	required init(from decoder: GDecoder) throws {
		name		= try decoder.decode( for: Key.name )
		connections	= try decoder.decode( for: Key.connections )
	}
	
	func encode(to encoder: GEncoder) throws {
		try encoder.encode(name, 		for: Key.name )
		try encoder.encode(connections, for: Key.connections )
	}
}

let a = Node("a")
let b = Node("b")
let c = Node("c")
let d = Node("d")
let e = Node("e")

/// Wikipedia 'Tred-G.svg' graph:                
///                        ╭───╮
///          ┌────────────▶︎│ c │─────┐
///          │             ╰───╯     │
///          │               │       │
///          │               ▼       ▼
///        ╭───╮   ╭───╮   ╭───╮   ╭───╮
/// root = │ a │──▶︎│ b │──▶︎│ d │──▶︎│ e │
///        ╰───╯   ╰───╯   ╰───╯   ╰───╯
///         │ │              ▲       ▲
///         │ │              │       │
///         │ └──────────────┘       │
///         └────────────────────────┘

a.connect( to: b, c, d, e )
b.connect( to: d )
c.connect( to: d, e )
d.connect( to: e )

do {	
	let inRoot	= a
	let data	= try GraphEncoder().encode( inRoot )
	let out_a	= try GraphDecoder().decode( type(of:inRoot), from:data )
	
	// Now we reach and from to different paths:
	let e1		= out_a["b"]?["d"]?["e"]!
	let e2		= out_a["c"]?["e"]!
	let e3		= out_a["e"]!
	
	print( e1 === e2 )	// prints: true --> we use '===': same reference!
	print( e1 === e3 )	// prints: true --> we use '===': same reference!
	// The graph obtained from GraphCodable is identical to the original
}

do {	// same thing with Codable
	let inRoot	= a
	let data	= try JSONEncoder().encode( inRoot )
	let out_a	= try JSONDecoder().decode( type(of:inRoot), from:data )
	
	// Now we reach and from to different paths:
	let e1		= out_a["b"]?["d"]?["e"]!
	let e2		= out_a["c"]?["e"]!
	let e3		= out_a["e"]!
	
	print( e1 === e2 )	// prints: false --> we use '===': different references!
	print( e1 === e3 )	// prints: false --> we use '===': different references!

	/// This is the graph obtained from Codable:
	///                ╭───╮   ╭───╮
	///                │ d │──▶︎│ e │
	///                ╰───╯   ╰───╯
	///                  ▲
	///                  │
	///                ╭───╮   ╭───╮
	///          ┌────▶︎│ c │──▶︎│ e │
	///          │     ╰───╯   ╰───╯
	///          │
	///        ╭───╮   ╭───╮   ╭───╮   ╭───╮
	/// root = │ a │──▶︎│ b │──▶︎│ d │──▶︎│ e │
	///        ╰───╯   ╰───╯   ╰───╯   ╰───╯
	///         │ │
	///         │ │    ╭───╮
	///         │ └───▶︎│ d │
	///         │      ╰───╯
	///         │      ╭───╮
	///         └─────▶︎│ e │
	///                ╰───╯
}
```
GraphCodable decodes the original structure of the graph.
Codable duplicates the same object reachable through different paths, destroying the original structure of the graph.
The result of Codable decoding is this:
```
         ╭───╮   ╭───╮
         │ d │──▶︎│ e │
         ╰───╯   ╰───╯
           ▲
           │
         ╭───╮   ╭───╮
   ┌────▶︎│ c │──▶︎│ e │
   │     ╰───╯   ╰───╯
   │
 ╭───╮   ╭───╮   ╭───╮   ╭───╮
 │ a │──▶︎│ b │──▶︎│ d │──▶︎│ e │
 ╰───╯   ╰───╯   ╰───╯   ╰───╯
  │ │
  │ │    ╭───╮
  │ └───▶︎│ d │
  │      ╰───╯
  │      ╭───╮
  └─────▶︎│ e │
         ╰───╯
```
### Reference Types - Directed Cyclic Graphs (DCG)

What happens if you add a connection from **e** to **b** in the previous example?
- The graph become cyclic (DCG);
- Your software leaks memory: ARC cannot release **e**, **b** and **d** because each retain the other;
- Graphcodable encodes it but generates an exception during decoding;
- Codable EXC_BAD_ACCESS during encoding.

Just like ARC cannot release **e**, **b** and **d** because each retain the other, GraphCodable cannot initialize **e**, **b** and **d** because the initialization of each of them requires that the other be initialized.
Swift does not allow to create non-initialized values. So, when GraphCodable during decode encounters a cycle that it cannot resolve, it throws an exception.

ARC has a specific solution for these cases: the use of weak variables.
Similarly, GraphCodable uses a slightly different way to decode weak variables used to break strong memory cycles: it postpones, calling a closure with the ``deferDecode(...)`` method, the initialization of these variables until the objects they point to have been initialized.

There is therefore a **one-to-one** correspondence between using weak variables to break strong memory cycles in ARC and using ``deferDecode(...)`` to allow initialization of such variables. ``deferDecode(...)`` **should not be used in any other case**.

Let's see how with a classic example: the **parent-childs pattern**. In this pattern the parent variable is weak to break the strong cycles (self.parent.child === self) that would otherwise form with his childs.
Similarly, this pattern requires to 'deferDecode' the weak variable (parent) because the initialization of parent depends on that of its childs and vice versa.

*Note:* Since a weak variable can become nil at 'any' time, it **must be encoded** with ``encodeConditional(...)``.

*Note:* Swift does not allow calling deferDecode from the init of a value type, but only from that of a reference type and forces to call it **after** super class initialization.

```swift
import Foundation
import GraphCodable

GTypesRepository.initialize()

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
	var description: String {
		return "\( type(of:self) ) \(childs)"
	}
	
	func encode(to encoder: GEncoder) throws {
		try encoder.encode( childs, for: Key.childs )
	
		//	weak variables must always be encoded conditionally:
		try encoder.encodeConditional( _parent, for: Key._parent )
	}

	required init(from decoder: GDecoder) throws {
		self.childs	= try decoder.decode( for: Key.childs )

		//	weak variables used to break strong memory cycles must
		//	be decoded with:
		try decoder.deferDecode( for: Key._parent ) { self._parent = $0 }
	}	
}

class View		: Node {}
class Window	: View {}	// we make window subclass of view
class Screen	: View {}	// we make the screen subclass of view

let screen	= Screen()

let windowA	= Window()
let windowB	= Window()

let view1	= View()
let view2	= View()
let view3	= View()
let view4	= View()

view4.parent	= view1		// make view4 child of view1

view1.parent	= windowA	// make view1 child of windowA
view2.parent	= windowA	// make view2 child of windowA
view3.parent	= windowB	// make view3 child of windowB

windowA.parent	= screen	// make windowA child of screen
windowB.parent	= screen	// make windowB child of screen

let inRoot	= screen as View	// we encode as View
let data	= try GraphEncoder().encode( inRoot )
let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )

print( outRoot )	// print 'Screen [Window [View [], View [View []]], Window [View []]]' or equivalent...

//	To make sure that GraphCodable has correctly rebuilt the graph,
//	we go down two levels and then go up to check if we obtain the same screen object.
//	If parent variables are set correctly the operation will be successful:

print( outRoot === outRoot.childs.first?.childs.first?.parent?.parent! )	// print true
```

For another example of DCG, see testDGC() in the tests section (DirectedCyclicGraphTests).

### Coding Rules

This table summarizes the methods to be used depending on the type of variable to be encoded and decoded:
```
┌─────────────────────────────────────────────────────────────────────────┐
│                          ENCODE/DECODE RULES                            │
├───────────────────┬─────────────────┬───────────────────────────────────┤
│                   │   VALUE  TYPE   │          REFERENCE  TYPE          │
│      METHOD       ├────────┬────────┼────────┬────────┬────────┬────────┤
│                   │        │    ?   │    s   │   s?   │  w? O  │  w? Ø  │
╞═══════════════════╪════════╪════════╪════════╪════════╪════════╪════════╡
│ encode            │ ██████ │ ██████ │ ██████ │ ██████ │        │        │
├───────────────────┼────────┼────────┼────────┼────────┼────────┼────────┤
│ encodeConditional │        │        │        │ ██████ │ ██████ │ ██████ │
╞═══════════════════╪════════╪════════╪════════╪════════╪════════╪════════╡
│ decode            │ ██████ │ ██████ │ ██████ │ ██████ │ ██████ │        │
├───────────────────┼────────┼────────┼────────┼────────┼────────┼────────┤
│ deferDecode       │        │        │        │        │        │ ██████ │
╞═══════════════════╧════════╧════════╧════════╧════════╧════════╧════════╡
│    ?   = optional                                                       │
│    s   = strong reference                                               │
│    s?  = optional strong reference                                      │
│    w?  = weak reference (always optional)                               │
│    Ø   = weak reference used to prevent strong memory cycles in ARC     │
│    O   = any other use of a weak reference                              │
│  Note  : Swift does not allow calling deferDecode from the init of a    │
│          value type, but only from that of a reference type. Swift      │
│          forces to call it after super class initialization.            │
└─────────────────────────────────────────────────────────────────────────┘
```
### UserInfo dictionary

The use is identical to that of Codable.

### Type version system

GraphCodable implements a type version system:

```swift
import Foundation
import GraphCodable

GTypesRepository.initialize()

let data : Data

do {
	struct MyData :GCodable {
		let number : Int
		
		init( number: Int ) {
			self.number	= number
		}
		
		private enum Key : String {
			case number
		}
		
		init(from decoder: GDecoder) throws {
			self.number	= try decoder.decode(for: Key.number)
			}
	
		func encode(to encoder: GEncoder) throws {
			try encoder.encode( number, for:Key.number )
		}
	}

	let inRoot	= MyData(number: 3)

	data = try GraphEncoder().encode( inRoot )
}

do {
	//	Now suppose we want to update MyData to use a more general
	//	string instead of a simple integer
	struct MyData :GCodable {
		let string : String
		
		init( string: String ) {
			self.string	= string
		}
		
		private enum OldKey : String {
			case number
		}
		
		private enum Key : String {
			case string
		}
		
		//	Let's make a new version of MyData... 
		static var	encodeVersion: UInt32 { return 1 }
		
		// ...so that during the dearchive it can be distinguished from the old one: 
		init(from decoder: GDecoder) throws {
			let version = try decoder.encodedVersion( type(of:self) )
			
			switch version {
			case 0:
				print( "updating \(MyData.self) from version 0 to \(Self.encodeVersion)..." )
				self.string	=  String( try decoder.decode( for: OldKey.number ) as Int )
			case Self.encodeVersion:
				print( "decoding the actual (\(Self.encodeVersion)) version of \(MyData.self)..." )
				self.string	=  try decoder.decode( for: Key.string )
			default:
				preconditionFailure( "unknown version \(version) for type \( MyData.self )" )
			}
		}
		
		func encode(to encoder: GEncoder) throws {
			try encoder.encode( string, for:Key.string )
		}
	}
	
	//	we need to register MyData type because it has a new init
	//	this call overwrite the old MyData registration automatically
	//	generated by GraphEncoder().encode( inRoot )
	MyData.register()
	
	var outRoot : MyData
	
	outRoot	= try GraphDecoder().decode( MyData.self, from: data )
	print( outRoot )	// print MyData(string: "3")
	
	outRoot	= try GraphDecoder().decode( MyData.self, from: try GraphEncoder().encode( outRoot ) )
	print( outRoot )	// print MyData(string: "3")
}
```
### Type replacement system

GraphCodable implements a type replacement system:

```swift
import Foundation
import GraphCodable

GTypesRepository.initialize()

let data : Data

do {
	struct MyData :GCodable, CustomStringConvertible {
		let number : Int
		
		init( number: Int ) {
			self.number	= number
		}
		
		private enum Key : String {
			case number
		}
		
		init(from decoder: GDecoder) throws {
			self.number	= try decoder.decode(for: Key.number)
		}
		
		func encode(to encoder: GEncoder) throws {
			try encoder.encode( number, for:Key.number )
		}
		
		var description: String {
			return "\(type(of:self))(number: \(number))"
		}
	}
	
	struct Container<T:GCodable> :GCodable, CustomStringConvertible {
		let value : T

		init( value: T ) {
			self.value	= value
		}

		private enum Key : String {
			case bubbu
		}

		init(from decoder: GDecoder) throws {
			self.value	= try decoder.decode(for: Key.bubbu)
		}
		
		func encode(to encoder: GEncoder) throws {
			try encoder.encode( value, for:Key.bubbu )
		}

		var description: String {
			return "\(type(of:self))(value: \(value))"
		}
	}
	
	let inRoot	= [Container(value: MyData(number: 3))]
	
	data = try GraphEncoder().encode( inRoot )
	print( inRoot )	// print [Container<MyData>(value: MyData(number: 3))]
}

GTypesRepository.initialize()

do {
	//	Now suppose we want to change the type of MyData to MyNewData

	struct MyNewData :GCodable, CustomStringConvertible {
		let number : Int
	
		init( number: Int ) {
			self.number	= number
		}
		
		private enum Key : String {
			case number
		}
		
		init(from decoder: GDecoder) throws {
			self.number	= try decoder.decode(for: Key.number)
		}
		
		func encode(to encoder: GEncoder) throws {
			try encoder.encode( number, for:Key.number )
		}

		var description: String {
			return "\(type(of:self))(number: \(number))"
		}
	}

	//	and the type of Container<...> to NewContainer<...>

	struct NewContainer<T:GCodable> :GCodable, CustomStringConvertible {
		let value : T

		init( value: T ) {
			self.value	= value
		}

		private enum Key : String {
			case bubbu
		}

		init(from decoder: GDecoder) throws {
			self.value	= try decoder.decode(for: Key.bubbu)
		}
		
		func encode(to encoder: GEncoder) throws {
			try encoder.encode( value, for:Key.bubbu )
		}

		var description: String {
			return "\(type(of:self))(value: \(value))"
		}
	}

	//	... and therefore every time the MyData and Container<...>
	//	types are encountered during the decode, the new MyNewData
	//	and NewContainer<...> types must be created in their place.
	
	//	We need dummy structs with the names that we want replace:
	//	(if you need to replace a class, use a dummy class)
	struct MyData {}
	struct Container<T> {}

	//	unregister MyData if needed, register MyNewData and teach
	//	the TypesRepository to replace MyData with MyNewData:
	try MyNewData.replace(type: MyData.self)
	
	//	unregister Container<...> if needed, register NewContainer<...>
	//	and teach the TypesRepository to replace Container<MyData> with
	//	NewContainer<MyNewData>:
	try NewContainer<MyNewData>.replace(type: Container<MyData>.self)

	//	now we need to register the other new type
	//	(This function is normally called at the beginning of the program)
	[NewContainer<MyNewData>].register()
	
	//	notice how substitution also occurs for types nested in other types
	let outRoot	= try GraphDecoder().decode( [NewContainer<MyNewData>].self, from: data )
	print( outRoot )	// print [NewContainer<MyNewData>(value: MyNewData(number: 3))]
}

```
You can see the contents of the GTYpesRepository with ``print( GTypesRepository.shared )``.
In this case (With some additional indentation):

```
GTypesRepository(
	* = "MyCodableApp",
	nativeTypes = [
		"Foundation.Data", "Swift.Bool", "Swift.Double", "Swift.Float",
		"Swift.Int", "Swift.Int16", "Swift.Int32", "Swift.Int64",
		"Swift.Int8", "Swift.String", "Swift.UInt", "Swift.UInt16",
		"Swift.UInt32", "Swift.UInt64", "Swift.UInt8"
	],
	registeredTypes = [
		"*.MyNewData",
		"*.NewContainer<*.MyNewData>",
		"Swift.Array<*.NewContainer<*.MyNewData>>"
	],
	typeReplacementsTable = [
		"*.Container<*.MyData>": "*.NewContainer<*.MyNewData>",
		"*.MyData": "*.MyNewData"
	]
)
```
## Types registration (reprise)
### Premise
Ideally, Swift should make two functions available for transforming types into some form of archivable data and vice versa.
For example, like these:
``func serializeType( type:Any.Type ) -> [UInt8]``
``func deserializeType( from:[UInt8] ) -> Any.Type``

Having this functionality, **the need to keep a repository of the decoding types vanishes**, because the bytes describing the type can be stored during encoding and retrieved during decoding. Then you can:

```swift
// 1) construct the type from its bytes description
let type = deserializeType( from: bytes )

// 2) check that it conforms the desired protocol
guard let decodableType = type as? GCodable.Type else {
	throw ...
}
// 3) istantiate the value
let decodedValue = decodableType(from: ...)
```
Beyond the real possibility of offering functions such as ``func serializeType( type:Any.Type ) -> [UInt8]`` and ``func deserializeType( from:[UInt8] ) -> Any.Type``, which I do not discuss because I do not have the skills, I do not understand what problem such a feature can pose to security.
There is nothing I can do with the decoded ``Any.type`` if I don't check for conformance to a predefined protocol first. Only after I have done this can I use the type to build instances.
But this functionality does not exist and therefore it is necessary to keep a repository of all possible types that may be encountered during decode.
### The Types Repository
The types repository is a sigleton class that contain a dictionary of string / type pairs, wherethe string is the type name. The encoder encode the name of every type it encounters. The decoder decode the type name and consults the type repository to get the corresponding type with which to instantiate the value.
And so **you have to register in the repository all possible types that may be encountered during decode**.

To register a decodable type ``myType`` , you simply call ``myType.register()``

We suggest creating a function like the following **in your app main module**:
```swift

func initializeGraphCodable() {
	GTypesRepository.initialize()	
	
	Body.register()
	Body.Presence.register()
	Boy.register()
	Girl.register()
	Presence.register()
	Swift.Array<Child>.register()
	Swift.Array<Swift.Int>.register()
	Swift.Dictionary<Swift.Int,Swift.String>.register()
	Swift.Set<Swift.Int>.register()
	Woman.register()
	// ...
}
```
and call it after startup. It is important to call it from the main module because GraphCodable needs this name and gets it from the default ``#fileID`` parameter in the ``GTypesRepository.initialize()`` function. Swift should really offer a function to get the main module name to avoid such tricks.

Maintaining a consistent repository of all types that can be decoded during application development can be a tedious task.
To alleviate this problem, GraphCodable offers two help functions.

- ``GTypesRepository.shared.help()``
-  ``GraphDecoder().help( from data: Data )``

The first provides in a string the Swift code that contains the function necessary to register all the types currently present in the repository. In other words, the result of all the recordings made automatically by the encoder from the opening of the program.

The second provides in a string the Swift code that contains the function necessary to register all types present in the data file that is passed to it. That is, the types that must be in the repository to be able to dearchive that data file.

To clear the content of the repository, simply reiniziale it with `GTypesRepository.initialize()`
### Type Names
By design, GraphCodable **never exposes type names as strings**. Even in the case of type replacements, GraphCodable forces you to define an empty type with the name of the type to replace (as showed in "Type replacement system") instead of using the string of its name.

But, as described, encoding / decoding requires the use of type names. Swift does not offer a function to obtain a string that can uniquely and stably identify each type. ``String (describing:)`` does not provide enough information, so we must necessarily use ``String (reflecting:)`` to get a suitable string. The aforementioned string is not used as it is; it is recursively decomposed into all component types, context information in the form ``.(____).(____).`` is eliminated where present, and a stable (*within the limits of the possible*) type name is reconstructed.



