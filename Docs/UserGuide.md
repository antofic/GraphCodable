#  User Guide

- [Initialization](#Initialization)
- [Introduction to type registration](#Introduction-to-type-registration)
- [Code examples](#Code-examples)
	- [Native types and collection support](#Native-types-and-collection-support)
	- [Value types](#Value-types)
		- [Keyed coding](#Keyed-coding)
		- [Unkeyed coding](#Unkeyed-coding)
	- [Reference types](#Reference-types)
		- [No duplication of the same object](#No-duplication-of-the-same-object)
		- [Inheritance](#Inheritance)
		- [Conditional encode](#Conditional-encode)
		- [Directed acyclic graphs](#Directed-acyclic-graphs)
		- [Directed cyclic graphs](#Directed-cyclic-graphs)
	- [Coding rules](#Coding+rules)
	- [Other features](#Other+features)
		- [UserInfo dictionary](#UserInfo-dictionary)
		- [Type version system](#Type-version-system)
		- [Type replacement system](#Type-replacement-system)
- [Type registration](#Type-registration)
	- [Types repository](#Types-repository)
	- [Type names](#Type-names)
- [Final thoughts](#Final-thoughts)
	
## Initialization
GraphCodable must be initialized before using it by calling the function from the main module.
```swift
import GraphCodable

GTypesRepository.initialize()
```
When called with no arguments, GraphCodable uses this function to know the name of the swift main module and remove it from the type name (replacing it with an *asterisk*) so that decoding a file does not depend on this name.
```swift

public final class GTypesRepository {
	public static func initialize( fromFileID fileID:String = #fileID )
	public static func initialize( mainModuleName name:String )
	...
}
```
Swift doesn't provide a way to get this name, not even at runtime. And so it is taken from `#fileID`.

## Introduction to type registration
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
The encoder automatically registers all types it encounters, and so there is no need to register any types if you are decoding a file after encoding it for testing purposes. The next examples will take advantage of this feature and so they just call `GTypesRepository.initialize()`.
I will return to the topic at the end of the document.

## Code examples

Keep in mind that in GraphCodable:
- GEncodable, GDecodable and GCodable have the same roles as Encodable, Decodable and Codable
- GEncoder, GDecoder have the same roles as Encoder, Decoder
- GraphEncoder has the same role as JSONEncoder, PropertyListEncoder
- GraphDecoder has the same role as JSONDecoder, PropertyListDecoder

GraphCodable does not use containers.

To check examples, copy and paste in your file main.swift.

### Native types and collection support
GraphCodable natively supports the following types: Int, Int8, Int16, Int32, Int64, UInt, UInt8, UInt16, UInt32, UInt64, Float, Double, String, Data
GraphCodable make Optional, Array, Set, Dictionary codable if the hold codable types. OptionSet and Enum with rawValue of native type (except Data) are codable, too.

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
### Value types
As can be seen from the following examples, the archiving and unarchiving interface is very similar to that of Codable, except that it does not use containers.

#### Keyed coding
GraphCodable uses enums with string rawValue as keys.

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
You can check if a keyed value is present in the archive with ``try decoder.contains(...)`` before decoding it.
**Values are removed from the decoder as they are decoded**.

#### Unkeyed coding
The same example using unkeyed coding. With unkeyed coding you must decode values in the same order in which they are encoded.

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

		self.reserveCapacity( try decoder.unkeyedCount() )

		while try decoder.unkeyedCount() > 0 {
			self.append( try decoder.decode() )
		}
	}
}
```
The ``init( from:... )`` method clearly shows that **values are removed from the decoder as they are decoded**.

### Reference types
#### No duplication of the same object

Up to now the behavior of GraphCodable is similar to that of Codable. That changes with reference types.
The same example with a reference type will show how GraphCodable don't duplicate the same reference. Codable duplicates it.

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

#### Conditional encode

GraphCodable supports conditional encoding:  `encodeConditional(...)` encodes a reference to the given object only if it is encoded unconditionally elsewhere in the payload (previously, or in the future). Codable appears to be designed for conditional encoding in mind, but neither the JSONEncoder nor the PropertyListEncoder supports it.

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
#### Directed cyclic graphs

What happens if you add a connection from **e** to **b** in the previous example?
- The graph become cyclic (DCG);
- Your code leaks memory: ARC cannot release **e**, **b** and **d** because each retain the other;
- GraphCodable encodes it but generates an exception during decoding;
- Codable EXC_BAD_ACCESS during encoding.

Just like ARC cannot release **e**, **b** and **d** because each retain the other, GraphCodable cannot initialize **e**, **b** and **d** because the initialization of each of them requires that the other be initialized and
Swift does not allow to exit from an init method without inizializing all variables. So, when GraphCodable during decode encounters a cycle that it cannot resolve, it throws an exception.

ARC has a specific solution for these cases: the use of weak variables.
Similarly, GraphCodable uses a slightly different way to decode weak variables used to break strong memory cycles: it postpones, calling a closure with the ``deferDecode(...)`` method, the setting of these variables (remember: they are optional, so they are auto-inizializated to nil) until the objects they point to have been initialized.

There is therefore a **one-to-one** correspondence between using weak variables to break strong memory cycles in ARC and using ``deferDecode(...)`` to allow initialization of such variables. ``deferDecode(...)`` **should not be used in any other case**.

Let's see how with a classic example: the **parent-childs pattern**. In this pattern the parent variable is weak to break the strong cycles (self.parent.child === self) that would otherwise form with his childs.
Similarly, this pattern requires to 'deferDecode' the weak variable (parent) because the initialization of parent depends on that of its childs and vice versa.

*Note:* You should **always** use ``encodeConditional(...)`` to encode a weak variable. Otherwise you run the risk of unnecessarily encode and decode objects that will be immediately released  after decoding.

*Note:* Swift does not allow to call ``deferDecode(...)`` from the init of a value type, but only from that of a reference type and forces to call it **after** super class initialization.

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

let inRoot	= screen
let data	= try GraphEncoder().encode( inRoot )
let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )

print( outRoot )	// print 'Screen [Window [View [], View [View []]], Window [View []]]' or equivalent...

//	To make sure that GraphCodable has correctly rebuilt the graph,
//	we go down two levels and then go up to check if we obtain the same screen object.
//	If parent variables are set correctly the operation will be successful:

print( outRoot === outRoot.childs.first?.childs.first?.parent?.parent! )	// print true
```

For another example of DCG, see ``testDGC()`` in the tests section (DirectedCyclicGraphTests).

### Coding rules

This table summarizes the methods to be used in your `func encode(to encoder: GEncoder) throws { ... }` and `init(from decoder: GDecoder) throws { ... }` depending on the type of variable to be encoded and decoded:

```
┌───────────────────────────────────────────────────────────────────────────────┐
│                           ENCODE/DECODE RULES                                 │
├───────────────────┬───────────────────┬───────────────────────────────────────┤
│                   │    VALUE   TYPE   │            REFERENCE TYPE             │
│      METHOD       ├─────────┬─────────┼─────────┬─────────┬─────────┬─────────┤
│                   │         │    ?    │ strong  │ strong? │ weak? O │ weak? Ø │
╞═══════════════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╡
│ encode            │  █████  │  █████  │  █████  │  █████  │⁵        │⁵        │
├───────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ encodeConditional │¹        │¹        │¹        │  █████  │  █████  │  █████  │
╞═══════════════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╡
│ decode            │  █████  │  █████  │  █████  │  █████  │  █████  │⁴        │
├───────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ deferDecode       │¹        │¹        │¹        │³        │³        │² █████  │
╞═══════════════════╧═════════╧═════════╧═════════╧═════════╧═════════╧═════════╡
│    ?    = optional                                                            │
│ strong  = strong reference                                                    │
│ strong? = optional strong reference                                           │
│  weak?  = weak reference (always optional)                                    │
│    Ø    = weak reference used to prevent strong memory cycles in ARC          │
│    O    = any other use of a weak reference                                   │
├───────────────────────────────────────────────────────────────────────────────┤
│  █████  = mandatory or highly recommended                                     │
│ ¹       = not allowed by Swift                                                │
│ ²       = allowed by Swift only in the init method of a reference type        │
│           Swift forces to call it after super class initialization            │
│ ³       = you don't need deferDecode: use decode(...) instead                 │
│ ⁴       = GraphCodable exception during decode: use deferDecode(...) instead  │
│ ⁵       = allowed but not recommendend: you run the risk of unnecessarily     │
│           encode and decode objects that will be immediately released after   │
│           decoding. Use encodeConditional(...) instead.                       │
└───────────────────────────────────────────────────────────────────────────────┘
```
All GraphCodable protocols are defined [here](/Sources/GraphCodable/GraphCodable.swift).

### Other features
#### UserInfo dictionary

The use is identical to that of Codable.

#### Type version system

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
	
	//	we need to register MyData type because it is a new type
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
#### Type replacement system

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
			case value
		}

		init(from decoder: GDecoder) throws {
			self.value	= try decoder.decode(for: Key.value)
		}
		
		func encode(to encoder: GEncoder) throws {
			try encoder.encode( value, for:Key.value )
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
## Type registration

To register a decodable type ``myType`` in the types repository, you simply call ``myType.register()``.

I suggest creating a function like the following **in your app main module**:
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
and call it after startup. It is important to call it from the main module because GraphCodable needs this name and gets it from the default ``#fileID`` 'hidden' parameter in the ``GTypesRepository.initialize( fromFileID fileID:String = #fileID )`` function. Swift should really offer a function to get the main module name to avoid such tricks.

### Types repository

You can see the contents of the GTypesRepository with ``print( GTypesRepository.shared )``. With the previous example it will print (with some additional indentation for clarity):
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
The types repository is a sigleton object that contain a dictionary of string / type pairs, where the string is a "stabilized" form of type name. The encoder encode the name of every type it encounters. The decoder decode the type name and consults the type repository to get the corresponding type with which to instantiate the value.
And so **you have to register in the repository all possible types that may be encountered during decode** otherwise the decoder can't costruct values from their type. In this case, GraphCodable throws an exception showing which types are missing from the repository.

Maintaining a consistent repository of all types that can be decoded during application development can be a tedious and error prone task.
I can't do much to alleviate this problem, but I have equipped GraphCodable with two functions:

- ``GTypesRepository.shared.help()``
-  ``GraphDecoder().help( from data: Data )``

The first provides in a string the Swift code that contains the function necessary to register all the types currently present in the repository. In other words, the result of all the encodings made automatically by the encoder from the opening of the program or tha last call to `GTypesRepository.initialize()`.

The second provides in a string the Swift code that contains the function necessary to register all types present in the data file that is passed to it. That is, the types that must be in the repository to be able to dearchive that data file.

To clear the content of the repository, simply reinizialize it with `GTypesRepository.initialize()`.
### Type names
By design, GraphCodable **never exposes type names as strings**. Even in the case of type replacements, GraphCodable forces you to define an empty type with the name of the type to replace (as showed in [Type replacement system](#Type-replacement-system)) instead of using the string of its name.

But, as described, encoding / decoding requires the internal use of type names. Swift does not offer a function to obtain a string that can uniquely and stably identify each type. ``String(describing:)`` does not provide enough information, so I must necessarily use ``String(reflecting:)`` to get a suitable string. The aforementioned string is not used as it is; it is recursively decomposed into all component types, context information in the form ``.(____).(____).`` is eliminated where present, and a stable (*within the limits of the possible*) type name is reconstructed. The type name thus obtained is then cached so that this rather expensive operation occurs only once for each type.

## Final thoughts

So why did I call this package "**experimental**"?

Apart from all the possible internal improvements to the package, there are some unsolvable iussues (as far as I know) related to some current Swift features.

- ``String(reflecting:)`` used to obtain type names might change the format to make decoding impossible without a package update. That said, as long as context information is kept inside round brackets, this shouldn't happen.
- An unfortunate, albeit minor, circumstance is that Swift doesn't have a function to get the main module name. A ``#mainModule`` would be greatly appreciated and would remove the need to call `GTypesRepository.initialize()` right after startup (but not the need to register types).
- There is nothing I can do to avoid duplication of the internal object used as storage by collection types like Arrays. Ideally, it should be made GCodable compliant to avoid duplicating it during decode, but I don't have access to it. Therefore, if 10 arrays sharing a single storage object containing 100 integers are encoded, 10 arrays each with its own distinct storage object containing 100 integers are decoded, effectively tenfolding their memory footprint exactly as it happens with Codable. Conversely, I emphasize that GraphCodable, unlike Codable, does not duplicate objects stored as elements of collections, as already demonstrated by the examples in this document. 
- The need to use ``deferDecode(...)`` for weak variables used to break ARC strong memory cycles is not a big problem, in my opinion, because you know exactly what and where they are. Just stick to the [rules](/Docs/CodingRules.md). If anything, the limitation is that these variables must necessarily be owned by a reference type because ``deferDecode(...)`` cannot be called in the ``init(from: ...)`` method of a value type. The ``WeakBox<T>`` used in ``testDGC()`` (see [DirectedCyclicGraphTests](/Tests/GraphCodableTests/5-DirectedCyclicGraphTests.swift)) must be a class.
- The main difficulty, in my opinion, is that you have to keep the type repository updated during the development of an application. The absence of a single 'GCodable' type from the type repository makes it impossible to decode a data file containing it.
 
  Ideally, Swift should make two functions available for transforming types into some form of archivable data and vice versa.
  For example, like these:
  
  ``func serializeType( type:Any.Type ) -> [UInt8]``
  
  ``func deserializeType( from:[UInt8] ) -> Any.Type``
  
  With this functionality **the need to keep a repository of the decoding types vanishes** because the bytes describing the type can be stored during encoding and retrieved during decoding. Then you can:
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
  Furthermore, the need to manage the type names inside the package also disappears, because types suffices.
  
  Beyond the real possibility of offering functions such as ``func serializeType( type:Any.Type ) -> [UInt8]`` and ``func deserializeType( from:[UInt8] ) -> Any.Type``, which I do not discuss because I do not   have the skills, I do not understand what problem such a feature can pose to security.
  There is nothing I can do with the decoded ``Any.type`` if I don't check for conformance to a predefined protocol first. Only after I have done this can I use the type to build instances.
  But this functionality does not exist and therefore it is necessary to keep a repository of all possible types that may be encountered during decode.
  
  Another possibility is to automate the generation of the repository, which however requires the use of some compiler magic (as far as I know): the compiler must keep track of all GCodable types encountered during compilation and automatically generate the code to register them.

