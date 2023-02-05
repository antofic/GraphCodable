#  User Guide

- [Premise](#Premise)
- [Code examples](#Code-examples)
	- [Native types](#Native-types)
	- [Value types](#Value-types)
		- [Keyed coding](#Keyed-coding)
		- [Unkeyed coding](#Unkeyed-coding)
	- [Reference types](#Reference-types)
		- [No duplication of the same object](#No-duplication-of-the-same-object)
		- [Inheritance](#Inheritance)
		- [Conditional encode](#Conditional-encode)
		- [Directed acyclic graphs](#Directed-acyclic-graphs)
		- [Directed cyclic graphs](#Directed-cyclic-graphs)
	- [Coding rules](#Coding-rules)
	- [Other features](#Other-features)
		- [UserInfo dictionary](#UserInfo-dictionary)
		- [Reference type version system](#Reference-type-version-system)
		- [Reference type replacement system](#Reference-type-replacement-system)
	
## Premise
GraphCodable has been completely revised. It now relies on `_mangledTypeName(...)` (when available) and `NSStringFromClass(...)` to generate the "type name" and on `_typeByName(...)` and `NSClassFromString(...)` to retrieve the class type from it.


Thanks to this change **it is no longer necessary to register the classes (the repository is gone)** or even set the main module name.

All the previous features are maintained, except for the reference type replacement system which is no longer available at this point in the redesign phase.

Use `myClass.isGCodable` to check if a class is actually decodable.

## Code examples

Keep in mind that in GraphCodable:
- GCodable, GCodable and GCodable have the same roles as Encodable, Decodable and Codable
- GEncoder, GDecoder have the same roles as Encoder, Decoder
- GraphEncoder has the same role as JSONEncoder, PropertyListEncoder
- GraphDecoder has the same role as JSONDecoder, PropertyListDecoder

GraphCodable does not use containers.

To check examples, copy and paste in your file main.swift.

### Native types

GraphCodable natively supports most  types of Swift Standard Library and Foundation. The full list is [here](/Docs/GraphCodableTypes.md).
Just one example:

```swift

import Foundation
import GraphCodable

let inRoot	= [["a":1.5,"b":2.0],nil,["c":2.5,"d":3.0,"e":nil]]

// encode inRoot in data
let data	= try GraphEncoder().encode( inRoot )

// decode outRoot from data
let outRoot	= try GraphDecoder().decode( type(of:inRoot), from: data )

print( outRoot == inRoot )	// prints: true
```
### Value types
As can be seen from the following examples, the archiving and unarchiving interface is very similar to that of Codable, except that it does not use containers.

#### Keyed coding
GraphCodable uses enums with string rawValue as keys.

```swift
import Foundation
import GraphCodable

struct Example : GCodable, Equatable {
	private(set) var name		: String
	private(set) var examples	: [Example]

	init( name : String, examples : [Example] = [Example]()) {
		self.name		= name
		self.examples	= examples
		}

	private enum Key: String {
		case name, examples
	}

	init(from decoder: GDecoder) throws {
		self.name	= try decoder.decode( for: Key.name )
		self.examples	= try decoder.decode( for: Key.examples )
	}
	
	func encode(to encoder: GEncoder) throws {
		try encoder.encode( name, for: Key.name )
		try encoder.encode( examples, for: Key.examples )
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
You can check if a keyed value is present in the archive with `try decoder.contains(...)` before decoding it.
**Values are removed from the decoder as they are decoded**.

#### Unkeyed coding
The same example using unkeyed coding. With unkeyed coding you must decode values in the same order in which they are encoded.

```swift
import Foundation
import GraphCodable

struct Example : GCodable, Equatable {
	private(set) var name		: String
	private(set) var examples	: [Example]

	init( name : String, examples : [Example] = [Example]()) {
		self.name		= name
		self.examples	= examples
		}

	private enum Key: String {
		case name, examples
	}

	init(from decoder: GDecoder) throws {
		self.name	= try decoder.decode()
		self.examples	= try decoder.decode()
	}
	
	func encode(to encoder: GEncoder) throws {
		try encoder.encode( name )
		try encoder.encode( examples )
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
It is also possible to mix keyed and unkeyed coding, as long as the unkeyed variables are decoded in the same order in which they were encoded.
It is recommended that you use unkeyed coding not in cases like this, but rather when you need to store a single value or a sequence of values. The following example shows how array conformance is implemented in the GraphCodable package using unkeyed encode/decode:

```swift
extension Array: GCodable where Element:GCodable {
	public func encode(to encoder: GEncoder) throws {
		for element in self {
			try encoder.encode( element )
		}
	}
	public init(from decoder: GDecoder) throws {
		self.init()

		self.reserveCapacity( try decoder.unkeyedCount )

		while try decoder.unkeyedCount > 0 {
			self.append( try decoder.decode() )
		}
	}
}
```
The `init( from:... )` method clearly shows that **values are removed from the decoder as they are decoded**.

### Reference types
#### No duplication of the same object

Up to now the behavior of GraphCodable is similar to that of Codable. That changes with reference types.
The same example with a reference type will show how GraphCodable don't duplicate the same reference. Codable duplicates it.

```swift
import Foundation
import GraphCodable

final class Example : GCodable, Equatable, Codable {
	private(set) var name		: String
	private(set) var examples	: [Example]
	
	init( name : String, examples : [Example] = [Example]()) {
		self.name		= name
		self.examples	= examples
	}
	
	private enum Key: String {
		case name, examples
	}
	
	init(from decoder: GDecoder) throws {
		self.name	= try decoder.decode( for: Key.name )
		self.examples	= try decoder.decode( for: Key.examples )
	}
	
	func encode(to encoder: GEncoder) throws {
		try encoder.encode( name, for: Key.name )
		try encoder.encode( examples, for: Key.examples )
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

### Inheritance

GraphCodable **supports inheritance**: in other words, the type of decoded object always corresponds to the real type of the encoded object, as you can see in the next example. Codable lost type information.

```swift
import Foundation
import GraphCodable

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

#### Conditional encode

GraphCodable supports conditional encoding:  `encodeConditional(...)` encodes a reference to the given object only if it is encoded unconditionally elsewhere in the payload (previously, or in the future). Codable appears to be designed for conditional encoding in mind, but neither the JSONEncoder nor the PropertyListEncoder supports it.

```swift
import Foundation
import GraphCodable

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

#### Directed acyclic graphs

The variables that contain objects realize **directed graphs**. ARC requires that strong variables do not create **directed cyclic graphs** (DCG) because the cycles prevent the release of memory. GraphCodable is capable of encoding and decoding **directed acyclic graphs** (DAG) without the need for any special treatment.
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
		try encoder.encode(name, for: Key.name )
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
	
	// Now we reach "e" from different paths:
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
	
	// Now we reach "e" from different paths:
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
	///         │ │    ╭───╮   ╭───╮
	///         │ └───▶︎│ d │──▶︎│ e │
	///         │      ╰───╯   ╰───╯
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
  │ │    ╭───╮   ╭───╮
  │ └───▶︎│ d │──▶︎│ e │
  │      ╰───╯   ╰───╯
  │      ╭───╮
  └─────▶︎│ e │
         ╰───╯
```
#### Directed cyclic graphs

What happens if you add a connection from **e** to **b** in the previous example?
- The graph become cyclic (DCG);
- Your code leaks memory: ARC cannot release **e**, **b** and **d** because each retain the other;
- GraphCodable encodes it but generates an exception during decoding;
- Codable EXC_BAD_ACCESS during encoding.

Just like ARC cannot release **e**, **b** and **d** because each retain the other, GraphCodable cannot initialize **e**, **b** and **d** because the initialization of each of them requires that the other be initialized and
Swift does not allow to exit from an init method without inizializing all variables. So, when GraphCodable during decode encounters a cycle that it cannot resolve, it throws an exception.

##### An example: weak variables
One possible solution for ARC is to use weak variables.
Than, GraphCodable uses a slightly different way to decode weak variables used to break strong memory cycles: it postpones, calling a closure with the `deferDecode(...)` method, the setting of these variables (remember: they are optional, so they are auto-inizializated to nil) until the objects they point to have been initialized.

Let's see how with a classic example: the **parent-childs pattern**. In this pattern the parent variable is weak to break the strong cycles (self.parent.child === self) that would otherwise form with his childs.
Similarly, this pattern requires to 'deferDecode' the weak variable (parent) because the initialization of parent depends on that of its childs and vice versa.

```swift
import Foundation
import GraphCodable

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
	private(set) var childs = Set<Node>()

	weak var parent : Node? {
		willSet {
			if newValue != parent {
				parent?.childs.remove( self )
			}
		}
		didSet {
			if parent != oldValue {
				parent?.childs.insert( self )
			}
		}
		
	}
	
	init() {}

	private enum Key : String {
		case childs, parent
	}
	var description: String {
		return "\( type(of:self) ) \(childs)"
	}
	
	func encode(to encoder: GEncoder) throws {
		try encoder.encode( childs, for: Key.childs )
	
		//	weak variables should always be encoded conditionally:
		try encoder.encodeConditional( parent, for: Key.parent )
	}

	required init(from decoder: GDecoder) throws {
		self.childs	= try decoder.decode( for: Key.childs )

		//	weak variables used to break strong memory cycles must
		//	be decoded with:
		try decoder.deferDecode( for: Key.parent ) { self.parent = $0 }
	}
}

class View	: Node {}
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

let inRoot	= screen
let data	= try GraphEncoder().encode( inRoot )
let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )

print( outRoot )	// print 'Screen [Window [View [], View [View []]], Window [View []]]' or equivalent...

//	To make sure that GraphCodable has correctly rebuilt the graph,
//	we go down two levels and then go up to check if we obtain the same screen object.
//	If parent variables are set correctly the operation will be successful:

print( outRoot === outRoot.childs.first?.childs.first?.parent?.parent! )	// print true
```
##### A more general example: elimination of ARC trong cycles
Another possible workaround with ARC is to manually drop the strong cycles to allow for memory release.
In the following example, the Model class contains a collection of Node classes by name in a dictionary.
Each node contains an array of nodes it is connected to and may also be connected to itself.
To prevent memory from ever being freed, Model's 'deinit' method calls 'removeConnections' for each node it owns.

So we have a model where the array of connections in each Node to other Nodes generates reference cycles.

If `decode` is used for those connections, the dearchiving fails due to reference cycles.
The solution, as per the following example, is to use `deferDecode` to dearchive the array.

See the example:
```
import Foundation
import GraphCodable

class Model : GCodable, Equatable, CustomStringConvertible {
	class Node : GCodable, Equatable, CustomStringConvertible {
		static func == (lhs: Node, rhs: Node) -> Bool {
			return lhs.name == rhs.name && lhs.connections.map { $0.name } == rhs.connections.map { $0.name }
		}
		
		private var connections = [Node]()
		let name : String

		func connect( to nodes: Node... ) {
			connections.append(contentsOf: nodes)
		}
		
		init( _ name:String ) {
			self.name	= name
		}
		
		private enum Key : String {
			case name, connections
		}
		
		required init(from decoder: GDecoder) throws {
			name		= try decoder.decode( for: Key.name  )
			// *** SEE HERE:  *** SEE HERE:  *** SEE HERE:  *** SEE HERE: ***
			try decoder.deferDecode( for: Key.connections ) { self.connections = $0 }
		}
		
		func encode(to encoder: GEncoder) throws {
			try encoder.encode( name,  for: Key.name  )
			try encoder.encode( connections, for: Key.connections )
		}
		
		func removeConnections() {
			connections.removeAll()
		}

		var description: String {
			return "\( Self.self ) '\(name)' -> \( connections.map { $0.name } )"
		}
	}

	
	private (set) var nodes = [String:Node]()
	
	init() {}

	static func == (lhs: Model, rhs: Model) -> Bool {
		return lhs.nodes == rhs.nodes
	}

	private enum Key : String {
		case nodes
	}

	required init(from decoder: GDecoder) throws {
		nodes	= try decoder.decode( for: Key.nodes )
		//	deferDecode can be used here, but is not required
		//	try decoder.deferDecode( for: Key.nodes ) { self.nodes = $0 }
	}
	
	func encode(to encoder: GEncoder) throws {
		try encoder.encode(nodes, for: Key.nodes )
	}
	
	func newNode( _ name: String ) -> Node {
		if let node = nodes[name] {
			return node
		} else {
			let node = Node( name )
			nodes[name]	= node
			return node
		}
	}
	
	subscript( _ name: String ) -> Node? {
		return nodes[name]
	}
			
	deinit {
		// avoid strong memory cycles
		nodes.forEach { $0.value.removeConnections() }
	}
	
	var description: String {
		return nodes.values.reduce(into: "\(Self.self):" ) { $0.append( "\n\t• \($1.description )" ) }
	}
}

let inModel	= Model()

let a 		= inModel.newNode("a")
let b 		= inModel.newNode("b")
let c 		= inModel.newNode("c")
let d 		= inModel.newNode("d")
let e 		= inModel.newNode("e")

//	A cyclic graph
a.connect( to: b,c,d,e )
b.connect( to: d,a,c,b,b,b )
c.connect( to: d,e,a,c,b,b,b,c,e )
d.connect( to: e,d,e,a,c,b )
e.connect( to: a,b,c,d,e,e )

let data		= try GraphEncoder().encode( inModel )
let outModel	= try GraphDecoder().decode( type(of:inModel), from:data )

print( "decoded \( outModel ) " )
print( "\( inModel == outModel ) " )
```

### GraphCodable protocols

All GraphCodable protocols are defined [here](/Sources/GraphCodable/GraphCodable.swift).

### Other features
#### UserInfo dictionary

The use is identical to that of Codable.

#### Reference type version system

GraphCodable implements a reference type version system.

Suppose our program saves its data in the "Documents/MyFile.graph" file:
```swift
import Foundation
import GraphCodable

class MyData :GCodable, CustomStringConvertible {
	let number : Int
	
	init( number: Int ) {
		self.number	= number
	}
	
	private enum Key : String {
		case number
	}
	
	required init(from decoder: GDecoder) throws {
		self.number	= try decoder.decode(for: Key.number)
		}

	func encode(to encoder: GEncoder) throws {
		try encoder.encode( number, for:Key.number )
	}

	var description: String {
		return "\(type(of:self))(number: \(number))"
	}
}

let inRoot	= MyData(number: 3)
print( inRoot )
// print: MyData(number: 3)

let data = try GraphEncoder().encode( inRoot )

let path = FileManager.default.urls(
	for: .documentDirectory, in: .userDomainMask
)[0].appendingPathComponent("MyFile.graph")

try data.write(to: path)
```
The new version of the program uses a different implementation of the MyData class. It is therefore necessary to be able to read the data saved by both versions of MyData. That's how:

```swift
import Foundation
import GraphCodable

class MyData :GCodable, CustomStringConvertible {
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
	class var currentVersion: UInt32 {
		return 1
	}
	
	// ...so that during the dearchive it can be distinguished from the old one:
	required init(from decoder: GDecoder) throws {
		let version = try decoder.encodedVersion
		
		switch version {
		case 0:
			print( "decoding \(MyData.self) version 0 and updating to \(Self.currentVersion)..." )
			self.string	=  String( try decoder.decode( for: OldKey.number ) as Int )
		case Self.currentVersion:
			print( "decoding the actual (\(Self.currentVersion)) version of \(MyData.self)..." )
			self.string	=  try decoder.decode( for: Key.string )
		default:
			preconditionFailure( "unknown version \(version) for type \( MyData.self )" )
		}
	}
	
	func encode(to encoder: GEncoder) throws {
		try encoder.encode( string, for:Key.string )
	}
	
	var description: String {
		return "\(type(of:self))(string: \(string))"
	}
}

let path = FileManager.default.urls(
	for: .documentDirectory, in: .userDomainMask
)[0].appendingPathComponent("MyFile.graph")

let data	= try Data(contentsOf: path)

let outRoot	= try GraphDecoder().decode( MyData.self, from: data )
// print: decoding MyData version 0 and updating to 1...
print( outRoot )
// print: MyData(string: "3")

let outRoot2	= try GraphDecoder().decode( MyData.self, from: GraphEncoder().encode( outRoot ) )
// print: decoding the actual (1) version of MyData...
print( outRoot2 )
// print: MyData(string: "3")
```
#### Reference type replacement system

Now suppose we need to change the name from `MyData` to `MyNewData`.
The problem is that there are already saved files in which objects of type MyData are stored and it is therefore necessary, during dearchiving, that objects of the new type MyNewData be created instead of these.

To achieve this you shouldn't eliminate MyData from your code, but rather remove all content and implement the GCodableObsolete protocol by indicating in the `replacementType` method that
`MyNewData` replaces `MyData`.

```swift
class MyData :GCodableObsolete {
	static var replacementType: (AnyObject & GCodable).Type {
		return MyNewData.self
	}
}
```
Here is the full code:
```swift
import Foundation
import GraphCodable

class MyData :GCodableObsolete {
	static var replacementType: (AnyObject & GCodable).Type {
		return MyNewData.self
	}
}

class MyNewData :GCodable, CustomStringConvertible {
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
		
	required init(from decoder: GDecoder) throws {
		if let replacedType	= try decoder.replacedType {
			// I'm decoding MyData and replacing with MyNewData
			print( "decoding \(replacedType.self) and replacing with \(Self.self)..." )
			self.string	=  String( try decoder.decode( for: OldKey.number ) as Int )
		} else {
			// I'm decoding MyNewData
			print( "decoding \(Self.self)..." )
			self.string	=  try decoder.decode( for: Key.string )
		}
	}
	
	func encode(to encoder: GEncoder) throws {
		try encoder.encode( string, for:Key.string )
	}
	
	var description: String {
		return "\(type(of:self))(string: \(string))"
	}
}

let path = FileManager.default.urls(
	for: .documentDirectory, in: .userDomainMask
)[0].appendingPathComponent("MyFile.graph")

let data	= try Data(contentsOf: path)

let outRoot	= try GraphDecoder().decode( MyNewData.self, from: data )
// print: decoding MyData and replacing with MyNewData...
print( outRoot )
// print: MyData(string: "3")

let outRoot2	= try GraphDecoder().decode( MyNewData.self, from: GraphEncoder().encode( outRoot ) )
// print: decoding MyNewData...
print( outRoot2 )
// print: MyData(string: "3")
```
Multiple classes can be replaced by only one if necessary: use `decoder.replacedType` to find out which one was replaced during dearchiving.

Version and replacement system can be combined.
