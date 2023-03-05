#  User Guide

- [Premise](#Premise)
- [Code examples](#Code-examples)
	- [Native types](#Native-types)
	- [Value types](#Value-types)
		- [Keyed coding](#Keyed-coding)
		- [Unkeyed coding](#Unkeyed-coding)
	- [Reference types](#Reference-types)
		- [Identity](#Identity)
		- [Inheritance](#Inheritance)
		- [Conditional encode](#Conditional-encode)
		- [Directed acyclic graphs](#Directed-acyclic-graphs)
		- [Directed cyclic graphs](#Directed-cyclic-graphs)
	- [ncoding/Decoding Identity for value types](#ncoding/Decoding-Identity-for-value-types)
		- [The GIdentifiable protocol](#The-GIdentifiable-protocol)
		- [Identity for Array and ContiguosArray](#Identity-for-Array-and-ContiguosArray)
	- [GraphCodable protocols](#GraphCodable-protocols)
	- [Other features](#Other-features)
		- [UserInfo dictionary](#UserInfo-dictionary)
		- [Reference type version system](#Reference-type-version-system)
		- [Reference type replacement system](#Reference-type-replacement-system)
	
## Premise
GraphCodable is a Swift encode/decode package (similar to Codable at interface level) that does not treat reference types as second-class citizens. Indeed, it also offers for value types a possibility normally reserved only for reference types: that of taking into account their identity to avoid duplication of data during archiving and de-archiving.

GraphCodable was born as an experiment to understand if it is possible to write in Swift a library that offers for all Swift types the functions that NSCoder, NSKeyedArchiver and NSKeyedUnarchiver have for Objective-C types.

The answer is basically yes and even with improvements in some cases.

There remains a cumbersomeness that becomes apparent only when the data structure forms a *cyclic* graph. In this situation it is necessary to use a different method (`deferDecode`) instead of the usual one (`decode`) during dearchiving to "break" the cycle.
This issue is related to the fact that if the reference type A contains a link to B and B a link to A, then in order to initialize A and B during dearchive it is necessary to partially initialize A or B and this is not allowed in Swift.

Graph Codable uses a very similar interface to Codable:

- GEncodable, GDecodable, GCodable have the same roles as Encodable, Decodable, Codable
- GEncoder, GDecoder have the same roles as Encoder, Decoder
- GraphEncoder has the same role as JSONEncoder, PropertyListEncoder
- GraphDecoder has the same role as JSONDecoder, PropertyListDecoder

GraphCodable does not use containers.

However, it should be emphasized that GraphCodable is not meant to replace Codable, but rather to give all Swift types the functionality that NSCoder, NSKeyedArchiver and NSKeyedUnarchiver have in Objective-C.
In other words, the intent of GraphCodable is not to serialize the data in some public format, but to archive and unarchive your "state" while preserving the real type of the references (**inheritance**) and the structure of the data (**identity**) regardless of its complexity, which Codable doesn't allow you to do.

The purpose of GraphCodable is to get after dearchiving the same "thing" that was archived.

*What is meant by **inheritance** in relation to archiving/dearchiving?*
Suppose `B : A` is a subclass of `A`. If we archive an array `[a,b]` containing one instance `a` of `A` and one instance `b` of `B` with Codable, after dearchiving we get an array containing two instances of `a`. This happens because Codable doesn't encode the type of the instance, and so when decoding it can only see the static type of the array, which is `[A]`, and infer that the array contains only instances of `A`.

*What is meant by **identity** in relation to archiving/dearchiving?*

Suppose that `A` is a class. If we archive an array `[a,a]` containing two times the same instance `a` of `A`  (`(a === a) == true`) with Codable, after decoding we get an array containing two different instances `a` that not anymore share the same *ObjectIdentifier*  (`(a === a) == false`). 

The consequences are more serious than they may appear: now suppose you have references connected as in the following diagram and that the program logic rely on tha fact that `c` is shared by `a` and `b`  so that if `a` changes `c`, `b` sees the change of `c`:

```
         ╭───╮
   ┌────▶︎│ c │
   │     ╰───╯
   │       ▲  
   │       │  
 ╭───╮   ╭───╮
 │ a │──▶︎│ b │
 ╰───╯   ╰───╯
```

Using Codable, after dearchiving we get:

```
         ╭───╮
   ┌────▶︎│ c │
   │     ╰───╯
 ╭───╮   ╭───╮   ╭───╮
 │ a │──▶︎│ b │──▶︎│ c │
 ╰───╯   ╰───╯   ╰───╯
```

Again, the original data structure is lost and furthermore an object has been duplicated, with what follows in terms of memory. This happens because Codable doesn't store the *identity* of the references. Now, for references it is essential that the data structure is preserved: after dearchiving the program logic is compromised if two objects are dearchived instead of one object. In GraphCodable, the identity of references is automatically derived from their *ObjectIdentifier*, although you can change this behavior.

The way value types behave, it makes no sense to talk about which data structure to preserve; conversely, in certain cases their duplication/multiplication can be problematic if they contain a large amount of data. For this reason, in analogy to the `Identifiable` system protocol, GraphCodable allows to define an identity for archiving and dearchiving also for value types (by default they don't have one), via the `GIdentifiable` protocol. Reference types can also make use of the `GIdentifiable`protocol where for some reason it is necessary to define an identity other than the one derived from *ObjectIdentifier*.

Clarified that the purpose of the library is to <u>get after dearchiving the same "thing" that was archived</u>, the characteristics of GraphCodable are illustrated in the next paragraphs with simple but working examples that can be directly tested with copy and paste.

## Supported system types

GraphCodable natively supports most  types of Swift Standard Library, Foundation, SIMD and others. The full list is [here](/Docs/GraphCodableTypes.md). And so, to archive and dearchive these types you don't have to do anything. Just one example:

```swift
import Foundation
import GraphCodable

let inRoot	= [["a":1.5,"b":2.0],nil,["c":2.5,"d":3.0,"e":nil]]

// encode inRoot in data
let data	= try GraphEncoder().encode( inRoot ) as Data

// decode outRoot from data
let outRoot	= try GraphDecoder().decode( type(of:inRoot), from: data )

print( outRoot == inRoot )	// prints: true
```
**Note:** `GraphEncoder().encode( value )` return type is a *generic sequence* of `UInt8`, so you need to specify the concrete type with `as Data`, o, for example, with `as [UInt8]`, generally sligtly more performant. GraphCodable define `Bytes` as typealias of `[UInt8]`.

### Keyed coding
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
let data	= try GraphEncoder().encode( inRoot ) as Bytes

// decode outRoot from data
let outRoot	= try GraphDecoder().decode( type(of:inRoot), from: data )

print( outRoot == inRoot )	// prints: true
```
You can check if a keyed value is present in the archive with `try decoder.contains(_ key:)` before decoding it.
**Values are removed from the decoder as they are decoded**.

### Unkeyed coding
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
let data	= try GraphEncoder().encode( inRoot ) as Bytes

// decode outRoot from data
let outRoot	= try GraphDecoder().decode( type(of:inRoot), from: data )

print( outRoot == inRoot )	// prints: true
```
It is also possible to mix keyed and unkeyed coding, as long as the unkeyed variables are decoded in the same order in which they were encoded.
It is recommended that you use unkeyed coding not in cases like this, but rather when you need to store a single value or a sequence of values. The following example shows how array conformance is implemented in the GraphCodable package using unkeyed encode/decode:

```swift
extension Array: GEncodable where Element:GEncodable {
	public func encode(to encoder: GEncoder) throws {
		for element in self {
			try encoder.encode( element )
		}
	}
}

extension Array: GDecodable where Element:GDecodable {
	public init(from decoder: GDecoder) throws {
		self.init()
		
		self.reserveCapacity( decoder.unkeyedCount )
		while decoder.unkeyedCount > 0 {
			self.append( try decoder.decode() )
		}
	}
}
```
The `init( from:... )` method clearly shows that **values are removed from the decoder as they are decoded**.

### Inheritance

Up to now the behavior of GraphCodable is similar to that of Codable. That changes with reference types. 

Suppose `B : A` is a subclass of `A`. If we archive an array `[a,b]` containing one instance `a` of `A` and one instance `b` of `B` with Codable, after dearchiving we get an array containing two instances of `a`. This happens because Codable doesn't store the type of the instance, and so when dearchiving it can only see the static type of the array, which is `[A]`, and infer that the array contains only instances of `A`.

GraphCodable **supports inheritance**: in other words, <u>the type of decoded reference always corresponds to the type of the encoded reference</u>, as you can see in the next example:

```swift
import Foundation
import GraphCodable

class A : CustomStringConvertible, GCodable, Codable {
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

class B : A {}

let inRoot	= [ A(), B() ]

print( type(of: inRoot) )	// Array<A>
print( inRoot )				// [A, B]

do {	// GraphCodable
	let data	= try GraphEncoder().encode( inRoot ) as Bytes
	let outRoot	= try GraphDecoder().decode( type(of:inRoot), from: data )
	
	print( type(of: outRoot) )	// Array<A>
	print( outRoot )			// [A, B] --> real reference types are maintained
}

do {	// Codable
	let data	= try JSONEncoder().encode( inRoot )
	let outRoot	= try JSONDecoder().decode( type(of:inRoot), from: data )
	
	print( type(of: outRoot) )	// Array<A>
	print( outRoot )			// [A, A]	--> real reference types are lost
}
```

#### Inheritance control (advanced users)

**Very unlikely you will ever need to disable inheritance**, but just in case you can disable it:

- by type, adopting the protocol with `GInheritance` protocol:

  ```swift
  public protocol GInheritance : AnyObject {
  	var disableInheritance : Bool { get }
  }
  ```

  Than, if in the above example you define:

  ```swift
  extension B: GInheritance {
  	var disableInheritance: Bool { true }
  }
  ```

  the encoder will not encode the class name of B and so when dearchiving you will get [A,A] even with GraphCodable.

- globally, using the `.disableClassNames` option in the `GraphEncoder(  _ options: )` method:

  ```swift
  let data	= try GraphEncoder( .disableInheritance ).encode( inRoot ) as Bytes
  ```

Finally, you can choose to globally ignore the adoption of the `GInheritance` protocol using the `.ignoreGInheritanceProtocol` option:

```swift
let data	= try GraphEncoder( .ignoreGInheritanceProtocol ).encode( inRoot ) as Bytes
```

## Identity

Suppose that `A` is a class. If we archive an array `[a,a]` containing two times the same instance `a` of `A`  (`(a === a) == true`) with Codable, after decoding we get an array containing two different instances `a` that not anymore share the same *ObjectIdentifier*  (`(a === a) == false`). 

The consequences are more serious than they may appear: now suppose you have references connected as in the following diagram and that the program logic rely on tha fact that `c` is shared by `a` and `b`  so that if `a` changes `c`, `b` sees the change of `c`:

```
         ╭───╮
   ┌────▶︎│ c │
   │     ╰───╯
   │       ▲  
   │       │  
 ╭───╮   ╭───╮
 │ a │──▶︎│ b │
 ╰───╯   ╰───╯
```

Using Codable, after dearchiving we get:

```
         ╭───╮
   ┌────▶︎│ c │
   │     ╰───╯
 ╭───╮   ╭───╮   ╭───╮
 │ a │──▶︎│ b │──▶︎│ c │
 ╰───╯   ╰───╯   ╰───╯
```

Again, the original data structure is lost and furthermore an object has been duplicated, with what follows in terms of memory. This happens because Codable doesn't store the *identity* of the references. Now, for references it is essential that the data structure is preserved: after dearchiving the program logic is compromised if two objects are dearchived instead of one object. In GraphCodable, the identity of references is automatically derived from their *ObjectIdentifier*, although you can change this behavior.

The way value types behave, it makes no sense to talk about which data structure to preserve; conversely, in certain cases their duplication/multiplication can be problematic if they contain a large amount of data. For this reason, in analogy to the `Identifiable` system protocol, GraphCodable allows to define an identity for archiving and dearchiving also for value types (by default they don't have one), via the `GIdentifiable` protocol. Reference types can also make use of the `GIdentifiable`protocol where for some reason it is necessary to define an identity other than the one derived from *ObjectIdentifier*.

#### Reference types identity

GraphCodable supports reference types identity <u>automatically</u> using the reference *ObjectIdentifier*. If, while encoding, it encounters a reference type that it has already encoded, instead of encoding it normally, it simply encode a token that identifies it. This way reference types are not duplicated. Codable duplicates it.

See the next example:
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
	let data	= try GraphEncoder().encode( inRoot ) as Bytes
	let outRoot	= try GraphDecoder().decode( type(of:inRoot), from: data )
	
	print( outRoot == inRoot )	// prints: true
	print( outRoot.examples[0] === outRoot.examples[1] )	// true --> we use '===': same reference!
	print( outRoot.examples[0] === outRoot.examples[2] )	// true --> we use '===': same reference!
}

do {	//	Codable
	let data	= try JSONEncoder().encode( inRoot )
	let outRoot	= try JSONDecoder().decode( type(of:inRoot), from: data )
	
	print( outRoot == inRoot )	// prints: true
	print( outRoot.examples[0] === outRoot.examples[1] )	// false --> we use '===': reference duplicated!
	print( outRoot.examples[0] === outRoot.examples[2] )	// false --> we use '===': reference duplicated!
}
```

Note: Reference types can also make use of the `GIdentifiable`protocol (see the next chapter) where for some reason it is necessary to define an identity other than the one derived from *ObjectIdentifier* or to "undefine" their identity by make the  `gcodableID`  property return `nil`.

#### Value types identity

Value types usually don't have an identity. In analogy to the `Identifiable` system protocol, GraphCodable allows to define an identity for archiving and dearchiving also for value types (by default they don't have one) adopting the `GIdentifiable` protocol:

```swift
public protocol GIdentifiable<GID> {
	associatedtype GID : Hashable
	var gcodableID: Self.GID? { get }
}

extension GIdentifiable where Self:Identifiable {
	public var gcodableID: Self.ID? { id }
}

```

Note: `gcodableID` automatically returns `id` if the type adopt the Identifiable protocol.

A value type conforming to the `GIdentifiable` protocol acquires the same ability as reference types to not be duplicated during storage. See the next example:

```swift
import Foundation
import GraphCodable

struct Example : GCodable, Equatable, Codable, Identifiable, GIdentifiable {
	var id = UUID()
	
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
	
	enum CodingKeys: String, CodingKey {
		case name, examples
	}
	
	// we dont want to save the ID
	init(from decoder: Decoder) throws {
		let values	= try decoder.container(keyedBy: CodingKeys.self)
		name 		= try values.decode(String.self, forKey: .name)
		examples	= try values.decode([Example].self, forKey: .examples)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(name, forKey: .name)
		try container.encode(examples, forKey: .examples)
	}
	
	static func == (lhs: Example, rhs: Example) -> Bool {
		// first check the id (same id than same data)
		// then check data (different id but same data)
		return (lhs === rhs) || (lhs.name == rhs.name && lhs.examples == rhs.examples)
	}
	
	static func === (lhs: Example, rhs: Example) -> Bool {
		return lhs.id == rhs.id
	}
}

let eA	= Example(name: "exampleA")
let eB	= Example(name: "exampleB", examples: [eA,eA,eA] )

let inRoot	= eB

do {	//	GraphCodable
	let data	= try GraphEncoder().encode( inRoot ) as Bytes
	let outRoot	= try GraphDecoder().decode( type(of:inRoot), from: data )
	
	print( outRoot == inRoot )	// true
	print( outRoot.examples[0] === outRoot.examples[1] )	// true --> we use '===': same id!
	print( outRoot.examples[0] === outRoot.examples[2] )	// true --> we use '===': same id!
}

do {	//	Codable
	let data	= try JSONEncoder().encode( inRoot )
	let outRoot	= try JSONDecoder().decode( type(of:inRoot), from: data )
	
	print( outRoot == inRoot )	// prints: true
	print( outRoot.examples[0] === outRoot.examples[1] )	// false --> we use '===': different id: value duplicated!
	print( outRoot.examples[0] === outRoot.examples[2] )	// false --> we use '===': different id: value duplicated!
}
```

#### Conditional encoding

GraphCodable supports conditional encoding of <u>references and values with identity</u>:  `encodeConditional(...)` encodes the value/reference only if it is encoded unconditionally elsewhere in the payload (previously, or in the future).

Note: Codable appears to be designed for conditional encoding in mind, but neither the JSONEncoder nor the PropertyListEncoder supports it.

This example uses references:

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
	let data	= try GraphEncoder().encode( inRoot ) as Bytes
	let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
	
	// "c.b" must be alive because there is at least one unconditional path from the root to "b"
	print( outRoot["c"]!.next != nil  )	// print true	--> "c.b" is alive
	
	// "b.a" must be alive because there is at least one unconditional path from the root to "a"
	print( outRoot["b"]!.next != nil  )	// print true 	--> "b.a" is alive
}

do {
	let inRoot	= [ "b": b, "c": c ]
	let data	= try GraphEncoder().encode( inRoot ) as Bytes
	let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
	
	// "c.b" must be alive because there is at least one unconditional path from the root to "b"
	print( outRoot["c"]!.next != nil  )	// print true 	--> "c.b" is alive
	
	// "b.a" must be nil because there is no unconditional path from the root to "a"
	print( outRoot["b"]!.next != nil  )	// print false	--> "b.a" is nil
}

do {
	let inRoot	= [ "a": a, "c" : c ]
	let data	= try GraphEncoder().encode( inRoot ) as Bytes
	let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )
	
	// "c.b" must be nil because there is no unconditional path from the root to "b"
	print( outRoot["c"]!.next != nil  )	// print false	--> "c.b" is nil
}
```

The next example uses the value <u>with identity</u> `VeryLargeData` supposed to hold a large quantity of data. `A` contains  `VeryLargeData`  and encode it.  `B` optionally contains  `VeryLargeData`  and conditionally encode it. Finally, Model hold `A` optionally and `B`.

```swift
import Foundation
import GraphCodable

struct VeryLargeData : GCodable, Identifiable, GIdentifiable {
	let id = UUID()
	let veryLargeData : String
	
	init( _ veryLargeData: String = "very large data") {
		self.veryLargeData	= veryLargeData
	}

	func encode(to encoder: GEncoder) throws {
		try encoder.encode( veryLargeData )
	}
	
	init(from decoder: GDecoder) throws {
		veryLargeData	= try decoder.decode()
	}
}

struct A : GCodable {
	var data : VeryLargeData
	
	init( data:VeryLargeData ) {
		self.data	= data
	}
	
	private enum Key : String {
		case data
	}
	
	func encode(to encoder: GEncoder) throws {
		try encoder.encode( data, for: Key.data )
	}
	
	init(from decoder: GDecoder) throws {
		data	= try decoder.decode( for: Key.data )
	}
}

struct B : GCodable {
	var data : VeryLargeData?

	init( data:VeryLargeData ) {
		self.data	= data
	}

	private enum Key : String {
		case data
	}
	
	func encode(to encoder: GEncoder) throws {
		try encoder.encodeConditional( data, for: Key.data )
	}
	
	init(from decoder: GDecoder) throws {
		data	= try decoder.decode( for: Key.data )
	}
}

struct Model : GCodable {
	var a 	: A?
	var b 	: B
	
	init( a:A?, b:B ) {
		self.a	= a
		self.b	= b
	}
	
	private enum Key : String {
		case a,b
	}
	
	func encode(to encoder: GEncoder) throws {
		try encoder.encode( a, for: Key.a )
		try encoder.encode( b, for: Key.b )
	}
	
	init(from decoder: GDecoder) throws {
		a	= try decoder.decodeIfPresent( for: Key.a )
		b	= try decoder.decode( for: Key.b )
	}
}

var a	= A(data: VeryLargeData())
var b	= B(data: a.data)

let inRoot = Model(a: a, b: b)

let data	= try GraphEncoder().encode( inRoot ) as Bytes
let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )

if let oa = outRoot.a {
	print( "outRoot.a.data contains \(oa.data.veryLargeData)" )
} else {
	print( "outRoot.a == nil " )
}

if let obdata = outRoot.b.data {
	print( "outRoot.b.data contains \(obdata.veryLargeData)" )
} else {
	print( "outRoot.b.data == nil " )
}
if let aid = outRoot.a?.data.id, let bid = outRoot.b.data?.id {
	if aid == bid { print( "Very large data NOT duplicated." )}
	else { print( "Very large data duplicated." )}
}
```

The output is:

```
outRoot.a.data contains very large data
outRoot.b.data contains very large data
Very large data NOT duplicated.
```

Now if you change the inRoot line to:

```swift
let inRoot = Model(a: nil, b: b)
```

the output becomes:

```
outRoot.a == nil 
outRoot.b.data == nil 
```

So, `b` encodes `data` conditionally. If `a`, which encodes `data` unconditionally, isn't encoded, `data` isn't encoded either.

#### Directed acyclic graphs

The variables that contain references realize **directed graphs**. ARC requires that strong variables do not create **directed cyclic graphs** (DCG) because the cycles prevent the release of memory. GraphCodable is capable of encoding and decoding **directed acyclic graphs** (DAG) without the need for any special treatment.
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
	let data	= try GraphEncoder().encode( inRoot ) as Bytes
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
}
```
GraphCodable decodes the original structure of the graph. Codable duplicates the same reference reachable through different paths, destroying the original structure of the graph. The result of Codable decoding is this:
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

Just like ARC cannot autamatically release **e**, **b** and **d** because each retain the other, GraphCodable cannot initialize **e**, **b** and **d** because the initialization of each of them requires that the other be initialized and Swift does not allow to exit from an init method without inizializing all variables. So, when GraphCodable during decode encounters a cycle that it cannot resolve, it throws an exception.

##### An example: weak variables
One possible solution for ARC is to use weak variables.
Than, GraphCodable uses a slightly different way to decode weak variables used to break strong memory cycles: it postpones, calling a closure with the `deferDecode(...)` method, the setting of these variables (remember: they are optional, so they are auto-inizializated to nil) until the objects they point to have been initialized.

Let's see how with a classic example: the **parent-childs pattern**. In this pattern the parent variable is weak to break the strong cycles (self.parent.child === self) that would otherwise form with his childs. Similarly, this pattern requires to '*deferDecode*' the weak variable (parent):

```swift
required init(from decoder: GDecoder) throws {
	self.childs	= try decoder.decode( for: Key.childs )
	try decoder.deferDecode( for: Key.parent ) { self.parent = $0 }
}
```

because the initialization of parent depends on that of its childs and vice versa.

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
		lhs === rhs
	}
}

func == <T:AnyObject>(lhs: T, rhs: T) -> Bool {
	lhs === rhs
}

func != <T:AnyObject>(lhs: T, rhs: T) -> Bool {
	lhs !== rhs
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
		"\( type(of:self) ) \(childs)"
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
let data	= try GraphEncoder().encode( inRoot ) as Bytes
let outRoot	= try GraphDecoder().decode( type(of:inRoot), from:data )

print( outRoot )	// print 'Screen [Window [View [], View [View []]], Window [View []]]' or equivalent...

//	To make sure that GraphCodable has correctly rebuilt the graph,
//	we go down two levels and then go up to check if we obtain the same screen object.
//	If parent variables are set correctly the operation will be successful:

print( outRoot === outRoot.childs.first?.childs.first?.parent?.parent! )	// print true

```
##### A more general example: elimination of ARC strong cycles
Another possible workaround with ARC is to manually drop the strong cycles to allow for memory release. In the following example, the Model class contains a collection of Node classes by name in a dictionary. Each node contains an array of nodes it is connected to and may also be connected to itself. To prevent memory from ever being freed, Model's 'deinit' method calls 'removeConnections' for each node it owns. So we have a model where the array of connections in each Node to other Nodes generates reference cycles.

If `decode` is used for those connections, the dearchiving fails due to reference cycles. The solution, as the previous example, is to use `deferDecode` to decode the array:

```swift
required init(from decoder: GDecoder) throws {
	name		= try decoder.decode( for: Key.name  )
  try decoder.deferDecode( for: Key.connections ) { self.connections = $0 }
}
```

See the full example:
```swift
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

let data		= try GraphEncoder().encode( inModel ) as Bytes
let outModel	= try GraphDecoder().decode( type(of:inModel), from:data )

print( "decoded \( outModel ) " )
print( "\( inModel == outModel ) " )
```

The output is:

```
decoded Model:
	• Node 'b' -> ["d", "a", "c", "b", "b", "b"]
	• Node 'd' -> ["e", "d", "e", "a", "c", "b"]
	• Node 'e' -> ["a", "b", "c", "d", "e", "e"]
	• Node 'a' -> ["b", "c", "d", "e"]
	• Node 'c' -> ["d", "e", "a", "c", "b", "b", "b", "c", "e"] 
true 
```



#### Global Identity control (advanced users)

Several options in the `GraphEncoder(  _ options: )` method control the behavior of Identity:



#### Identity for system types

##### Array and ContiguousArray

If you want to give identity to Array and ContiguosArray, avoiding their duplication, copy and paste this code:

```swift
extension Array : GIdentifiable where Element:GCodable {
	public var gcodableID: ObjectIdentifier? {
		withUnsafeBytes { unsafeBitCast( $0.baseAddress, to: ObjectIdentifier?.self) }
	}
}

extension ContiguousArray : GIdentifiable where Element:GCodable {
	public var gcodableID: ObjectIdentifier? {
		withUnsafeBytes { unsafeBitCast( $0.baseAddress, to: ObjectIdentifier?.self) }
	}
}
```

##### Strings

If you want to give identity to Strings, avoiding their duplication, copy and paste this code:

```swift
extension String : GIdentifiable {
	public var gcodableID: String? {
		self
	}
}
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

