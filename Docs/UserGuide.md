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
	- [Encoding/Decoding Identity for value types](#ncoding/Decoding-Identity-for-value-types)
		- [The GIdentifiable protocol](#The-GIdentifiable-protocol)
		- [Identity for Array and ContiguosArray](#Identity-for-Array-and-ContiguosArray)
	- [GraphCodable protocols](#GraphCodable-protocols)
	- [Other features](#Other-features)
		- [UserInfo dictionary](#UserInfo-dictionary)
		- [Versioning of reference types](#Versioning-of-reference-types)
		- [Obsolete reference types](#Obsolete-reference-types)
	
## Premise
GraphCodable is a Swift encode/decode package (similar to Codable at interface level) that does not treat reference types as second-class citizens. Indeed, it also offers for value types a possibility normally reserved only for reference types: that of taking into account their identity to avoid duplication of data during encoding and decoding.

GraphCodable was born as an experiment to understand if it is possible to write in Swift a library that offers for all Swift types the functions that NSCoder, NSKeyedArchiver and NSKeyedUnarchiver have for Objective-C types.

The answer is basically yes and even with improvements in some cases.

There remains a cumbersomeness that becomes apparent only when the data structure forms a *cyclic* graph. In this situation it is necessary to use a different method (`deferDecode`) instead of the usual one (`decode`) to "break the cycle" and bring the decoding to a successful completion. This issue is related to the fact that if the reference type **A** contains a link to **B** and **B** a link to **A**, then in order to initialize **A** and **B** during decoding it is necessary to partially initialize **A** or **B** and this is not allowed in Swift.

Also, GraphCodable cannot rely on compiler magic that allows Codable to encode and decode value types without writing code. In this regard, I intend to evaluate whether the next developments of the language (in particular, *reflection* and *macros*) will allow such "magic" to be implemented in GraphCodable.

Graph Codable uses a very similar interface to Codable:

- `GEncodable`, `GDecodable`, `GCodable` have the same roles as `Encodable`, `Decodable`, `Codable`
- `GEncoder`, `GDecoder` have the same roles as `Encoder`, `Decoder`
- `GraphEncoder` has the same role as `JSONEncoder` or `PropertyListEncoder`
- `GraphDecoder` has the same role as `JSONDecoder` or `PropertyListDecoder`

GraphCodable does not use containers.

However, it should be emphasized that GraphCodable is not meant to replace Codable, but rather to give all Swift types the functionality that NSCoder, NSKeyedArchiver and NSKeyedUnarchiver have in Objective-C.
In other words, the intent of GraphCodable is not to serialize the data in some public format, but to encode and decode your "state" while preserving the real type of the references (**inheritance**) and the structure of the data (**identity**) regardless of its complexity, which Codable doesn't allow you to do.

**Ultimatelly, the purpose of GraphCodable is to get after decode the same "thing" that was encoded.**

*What is meant by **inheritance** in relation to encoding/decoding?*
Suppose `B : A` is a subclass of `A`. If we encode an array `[a,b]` containing one instance `a` of `A` and one instance `b` of `B` with Codable, after decoding we get an array containing two instances of `a`. This happens because Codable doesn't encode the type of the instance, and so when decoding it can only see the static type of the array, which is `[A]`, and infer that the array contains only instances of `A`.

*What is meant by **identity** in relation to encoding/decoding?*

Suppose that `A` is a class. If we encode an array `[a,a]` containing two times the same instance `a` of `A`  (`(a === a) == true`) with Codable, after decoding we get an array containing two different instances `a` that not anymore share the same *ObjectIdentifier*  (`(a === a) == false`). 

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

Using Codable, after decoding we get:

```
         ╭───╮
   ┌────▶︎│ c │
   │     ╰───╯
 ╭───╮   ╭───╮   ╭───╮
 │ a │──▶︎│ b │──▶︎│ c │
 ╰───╯   ╰───╯   ╰───╯
```

Again, the original data structure is lost and furthermore an object has been duplicated, with what follows in terms of memory. This happens because Codable doesn't store the *identity* of the references. Now, for references, it is essential that the data structure is preserved: after decoding the program logic is compromised if two objects are decoded instead of one object. In GraphCodable, the identity of references is automatically derived from their *ObjectIdentifier*, although you can change this behavior.

The way value types behave, it makes no sense to talk about which data structure to preserve; conversely, in certain cases their duplication/multiplication can be problematic if they contain a large amount of data. For this reason, in analogy to the `Identifiable` system protocol, GraphCodable allows to define an identity for encoding and decoding also for value types (by default they don't have one), via the `GIdentifiable` protocol. Reference types can also make use of the `GIdentifiable`protocol where for some reason it is necessary to define an identity other than the one derived from *ObjectIdentifier*.

Clarified that the purpose of the library is to <u>get after decoding the same "thing" that was encoded</u>, the characteristics of GraphCodable are illustrated in the next paragraphs with simple but working examples that can be directly tested with copy and paste.

## Supported system types

GraphCodable natively supports most  types of Swift Standard Library, Foundation, SIMD and others. The full list is [here](/Docs/GraphCodableTypes.md). And so, to encode and decode these types you don't have to do anything. Just one example:

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
**Note**: Values are removed from the decoder data basket as they are decoded.

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
It is recommended that you use unkeyed coding not in cases like this, but rather when you need to encode only a single value or a sequence of values. The following example shows how array conformance is implemented in the GraphCodable package using unkeyed encode/decode:

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
The `while decoder.unkeyedCount > 0 {…}` in the  `init( from:... )` method clearly shows that **values are removed from the decoder data basket as they are decoded**.

### Inheritance

Up to now the behavior of GraphCodable is similar to that of Codable. That changes with reference types. 

Suppose `B : A` is a subclass of `A`. If we encode an array `[a,b]` containing one instance `a` of `A` and one instance `b` of `B` with Codable, after decoding we get an array containing two instances of `a`. This happens because Codable doesn't store the type of the instance, and so when decoding it can only see the static type of the array, which is `[A]`, and infer that the array contains only instances of `A`.

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

#### How does inheritance work?

The encoder stores the following information for each reference type:

- the qualified name of the class produced by `_typeName( type, qualified:true )` for informational purposes only;
- the mangled name of the class produced by `_mangledTypeName( type );`
- a `UInt32` user defined version of the class (see paragraph [Versioning of reference types](#Versioning-of-reference-types)).

During decoding, the class is *reified* using `_typeByName( mangledName )` and used to construct all of its instances in the archive.

**Note**: When used on classes, `_mangledTypeName()` and `_typeByName()` are respectively equivalent to `NSStringFromClass()` and `NSClassFromString()`, although they produce a slightly different mangling. But the former are faster, so I chose them.

It is therefore evident that **if you change the name of a class it becomes impossible to decode archives created before the change**. For this reason it is very important to:

- carefully choose the name of a class intended to be archived so that it is not necessary to change it later;
- use all available strategies (a `typealias`, for example) to keep using the name initially chosen;

If all possible alternatives have been exhausteds, GraphCodable offers two methods for handling class renaming (see paragraph [Obsolete reference types](#Obsolete-reference-types)).

#### Disable inheritance

There are situations where it is necessary or desirable to **disable** inheritance:

- A **private** reference type cannot be decoded because it cannot be constructed from its type name. The encoder always checks if a type is constructible: if not, it throws an exception at runtime. You can also check whether a `GEncodable` reference type is constructible by calling the `supportsCodableInheritance` property.
- If a reference type **is not part of a class hierarchy**, encoding its type name to support inheritance is unnecessary.

For cases like these, GraphCodable provides the `GInheritance` protocol:

```swift
public protocol GInheritance : AnyObject {
	var disableInheritance : Bool { get }
}
```

To disable inheritance it is therefore sufficient to adopt the `GInheritance` protocol and define the `disableInheritance` property so that it returns `true`:

```swift
extension MyReferenceType: GInheritance {
	var disableInheritance: Bool { true }
}
```

#### Control inheritance globally

Some options in the `GraphEncoder(  _ options: )` method control inheritance **globally**, that is, they apply to all encoded reference types.

- the `.disableInheritance` option disable inheritance for all reference types, regardless of protocol `GInheritance`;
- the `.ignoreGInheritanceProtocol` option override the adoption of the `GInheritance` protocol and make the encoder ignore it.

### Identity

Suppose that `A` is a class. If we encode an array `[a,a]` containing two times the same instance `a` of `A`  (`(a === a) == true`) with Codable, after decoding we get an array containing two different instances `a` that not anymore share the same *ObjectIdentifier*  (`(a === a) == false`). 

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

Using Codable, after decoding we get:

```
         ╭───╮
   ┌────▶︎│ c │
   │     ╰───╯
 ╭───╮   ╭───╮   ╭───╮
 │ a │──▶︎│ b │──▶︎│ c │
 ╰───╯   ╰───╯   ╰───╯
```

Again, the original data structure is lost and furthermore an object has been duplicated, with what follows in terms of memory. This happens because Codable doesn't store the *identity* of the references. Now, for references it is essential that the data structure is preserved: after decoding the program logic is compromised if two objects are decoded instead of one object. In GraphCodable, the identity of references is automatically derived from their *ObjectIdentifier*, although you can change this behavior.

The way value types behave, it makes no sense to talk about which data structure to preserve; conversely, in certain cases their duplication/multiplication can be problematic if they contain a large amount of data. For this reason, in analogy to the `Identifiable` system protocol, GraphCodable allows to define an identity for encoding and decoding also for value types (by default they don't have one), via the `GIdentifiable` protocol. Reference types can also make use of the `GIdentifiable`protocol where for some reason it is necessary to define an identity other than the one derived from *ObjectIdentifier*.

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

**Note**: Reference types can also make use of the `GIdentifiable`protocol (see the next chapter) where for some reason it is necessary to define an identity other than the one derived from *ObjectIdentifier* or to "undefine" their identity by make the  `gcodableID`  property return `nil`.

#### Value types identity

Value types usually don't have an identity. In analogy to the `Identifiable` system protocol, GraphCodable allows to define an identity for encoding and decoding also for value types (by default they don't have one) adopting the `GIdentifiable` protocol:

```swift
public protocol GIdentifiable<GID> {
	associatedtype GID : Hashable
	var gcodableID: Self.GID? { get }
}

extension GIdentifiable where Self:Identifiable {
	public var gcodableID: Self.ID? { id }
}

```

**Note**: `gcodableID` automatically returns the `Identifiable.id` as `gcodableID` if the type adopt the `Identifiable` protocol. 

A value type conforming to the `GIdentifiable` protocol acquires the same ability as reference types to not be duplicated during encoding and decoding. See the next example:

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

**Note**: Codable appears to be designed for conditional encoding in mind, but neither the JSONEncoder nor the PropertyListEncoder supports it. And it's not clear how it could, given that conditional storage is only possible for types with identities, which Codable doesn't support.

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

The next example uses the value <u>with identity</u>. `A` contains  `VeryLargeData`  and encode it.  `B` optionally contains  `VeryLargeData`  and conditionally encode it. Finally, Model hold `A` optionally and `B`.

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

So, `b` encodes `data` conditionally. If `Model` don't encode  `a`, which encodes `data` unconditionally, `data` isn't encoded att all.

If you try to **conditionally** encode a value **without identity**, GraphCodable encodes it **unconditionally**. If it happens and the `.printWarnings` option in the `GraphEncoder(  _ options: )` method is selected, GraphCodable prints a warning message during encoding.

#### Directed acyclic graphs (DAG)

Connections between reference types often create complex graphs where the same object "points" and "is pointed to" by many other objects. ARC, for example, requires that strong variables do not create **directed cyclic graphs** (DCG) because the cycles prevent the release of memory. The GraphCodable decoder implements an algorithm that allows it to **always** decode  **directed acyclic graphs** (DAG) without any special treatment of the variables to decode.

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
#### Directed cyclic graphs (DCG)

What happens if you add a connection from `e` to `b` in the previous example?
- The graph become cyclic (DCG);
- Your code leaks memory: ARC cannot release `e`, `b` and `d` because each retain the other;
- GraphCodable encodes it but generates an exception during decoding;
- Codable generates an exception during encoding.

Just like ARC cannot autamatically release `e`, `b` and d because each retain the other, GraphCodable cannot initialize `e`, `b` and `d` because the initialization of each of them requires that the other be initialized and Swift does not allow to exit from an init method without inizializing all variables. So, when GraphCodable during decode encounters a cycle that it cannot resolve, it throws an exception.

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
Another possible workaround with ARC is to manually break the strong cycles to allow for memory release. In the following example, the Model class contains a collection of Node classes by name in a dictionary. Each node contains an array of nodes it is connected to and may also be connected to itself. To prevent memory from ever being freed, Model's `deinit` method calls `removeConnections` for each node it owns. So we have a model where the array of connections in each Node to other Nodes generates reference cycles.

If `decode` is used for those connections, the decoding fails due to reference cycles. The solution, as the previous example, is to use `deferDecode` to decode the array:

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

#### Identity for value types that use copy on write (COW)

The following example demonstrates how to give identity to an *Array-like* type that implements the COW mechanism. The buffer (for simplicity a standard Array is used) is contained in a box reference so that it can be copied only when the box is shared by multiple arrays.

```swift
struct MyArray<Element> {
	private final class RefBox<Element> {
		var value : Element
		
		init( _ value:Element )  {
			self.value	= value
		}
	}
	
	//	It's just an example, so let's use an Array
  //	as internal buffer:
	typealias	Buffer	= [Element]
	private var box : RefBox<Buffer>
	
	init()  {
		box	= RefBox( Buffer() )
	}
	
	private mutating func updateCOW() {
		if !isKnownUniquelyReferenced( &box ) {
			box = RefBox( box.value )
		}
	}
}

extension MyArray : RandomAccessCollection, RangeReplaceableCollection {
	var startIndex: Int					{ box.value.startIndex }
	var endIndex: Int					{ box.value.endIndex }
	func index(before i: Int) -> Int	{ box.value.index(before: i) }
	func index(after i: Int) -> Int		{ box.value.index(after: i) }
	
	subscript(i: Int) -> Element {
		get {
			box.value[i]
		}
		set {
			updateCOW()
			box.value[i] = newValue
		}
	}
	
	mutating func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C)
  where C : Collection, C.Element == Element {
		updateCOW()
		box.value.replaceSubrange(subrange, with: newElements)
	}
}

extension MyArray : CustomStringConvertible {
	var description: String	{
		box.value.description
	}
}

extension MyArray : Equatable where Element:Equatable {
	static func == (lhs: MyArray, rhs: MyArray) -> Bool {
		return lhs.box === rhs.box || lhs.box.value == rhs.box.value
	}
}
```

First of all, let's adopt the `GCodable` protocol:

```swift
extension MyArray: GCodable where Element:GCodable {
	init(from decoder: GDecoder) throws {
		box	= RefBox( try decoder.decode() )
	}
	func encode(to encoder: GEncoder) throws {
		try encoder.encode( box.value )
	}
}
```

Let's see what happens by encoding a composition of MyArray and printing the result of the encoding in readable format.

```swift
let a 			= MyArray( [1,2] )
let b			= MyArray( [a,a] )
let inRoot		= MyArray( [b,b] )
print("••• MYArray = \(inRoot) ")
print( try GraphEncoder().dump( inRoot ) )
```

The output shows that the array `a ` has been encoded 4 times and that's not what we want:

```
••• MYArray = [[[1, 2], [1, 2]], [[1, 2], [1, 2]]] 
== BODY ==========================================================
- VAL
	- VAL
		- VAL
			- VAL
				- VAL
					- BIV [1, 2]
				.
				- VAL
					- BIV [1, 2]
				.
			.
		.
		- VAL
			- VAL
				- VAL
					- BIV [1, 2]
				.
				- VAL
					- BIV [1, 2]
				.
			.
		.
	.
.
==================================================================
```

The solution is to adopt the `GIdentifiable` protocol to give an identity to MyArray and the identity is obviously the *ObjectIdentifier* of the box.

```swift
extension MyArray: GIdentifiable {
	var gcodableID: ObjectIdentifier? { return ObjectIdentifier(box) }
}
```

The output becomes now:

```
••• MYArray = [[[1, 2], [1, 2]], [[1, 2], [1, 2]]] 
== BODY ==========================================================
- VAL0001
	- VAL
		- VAL0002
			- VAL
				- VAL0003
					- BIV [1, 2]
				.
				- PTS0003
			.
		.
		- PTS0002
	.
.
==================================================================
```

Not only array `a` (VAL0003) is encoded only once, but array `b` (VAL0002) is also encoded once.

##### Optimization for trivial types  (advanced users).

You can streamline and speed up encoding/decoding of **trivial** types using the BinaryIO library (see the BinaryIO documentation). The first step is to adopt the `BinaryIOType` protocol:

```swift
extension MyArray: BinaryIOType where Element:BinaryIOType {
	init(from rbuffer: inout BinaryReadBuffer) throws {
		box	= RefBox( try Buffer(from: &rbuffer) )
	}
	
	func write(to wbuffer: inout BinaryWriteBuffer) throws {
		try box.value.write(to: &wbuffer)
	}
}
```

Next you need to specify when GraphCodable should use BinaryIO:

```swift
extension MyArray: GBinaryCodable where Element:GTrivialCodable {}
```

In essence we are telling the encoder that when the elements of `MyArray` are trivial (they adopt the `GTrivialCodable` protocol), the array can use BinaryIO. So a `GBinaryCodable` type **is** a `GCodable` type, but all its fields, elements, etc… are trivial, and therefore the encoder can use BinaryIO to encode them. The output becomes this:

```
••• MYArray = [[[1, 2], [1, 2]], [[1, 2], [1, 2]]] 
== BODY ==========================================================
- VAL0001
	- VAL
		- VAL0002
			- VAL
				- BIV0003 [1, 2]
				- PTS0003
			.
		.
		- PTS0002
	.
.
==================================================================
```

GraphCodable marks commons trivial types with the dummy protocol `GTrivial` to speed up encoding and decoding. GraphCodable check during encoding if a value is really trivial with the function `_isPOD( _:)`; if not, the encoder generate an exception.

If you have defined trivial types and want to take advantage of the functionality described, adopt the `GTrivial` or `GTrivialCodable` protocol for them.

#### Identity for swift system value types that use copy on write (COW)

Many swift system value types use the copy on write (COW) mechanism. Among these, the most common are `Array`, `ContiguousArray`, `Data`, `Set`, `Dictionary` and presumably `String`. Unfortunately, none of these types exposes the *ObjectIdentifier* of the reference type used as storage, otherwise it would be very simple to provide them with identities, exactly as it was done in the example of the previous paragraph with `MyArray`.

In the case of `Array` and `ContiguousArray` it is possible to obtain the *ObjectIdentifier* of the internal storage with the following trick:

```swift
extension Array : GIdentifiable where Element:GCodable {
	var gcodableID: ObjectIdentifier? {
		withUnsafeBytes { unsafeBitCast( $0.baseAddress, to: ObjectIdentifier?.self) }
	}
}

extension ContiguousArray : GIdentifiable where Element:GCodable {
	var gcodableID: ObjectIdentifier? {
		withUnsafeBytes { unsafeBitCast( $0.baseAddress, to: ObjectIdentifier?.self) }
	}
}
```

While this appears to work, it's still a hack and therefore GraphCodable doesn't implement it. **Use it at your own risk.** Also, the exact same trick doesn't seem to work for `Data` at all, while a similar trick doesn't seem to be available for `Set`, `Dictionary`, and `String`.

Another possibility is to use the value **itself** as identifier, if it adopts the `Hashable` protocol. For example, with this code:

```swift
extension String : GIdentifiable {
	public var gcodableID: String? {
		self
	}
}
```

each string (a string is `Hashable`) acquires its own self-defined identity, and all equal strings are encoded only once. However, care must be taken when using this method (or generalize it) because it involves checking potentially complex and large values for equality during encoding, which can slow down the procedure. This is very different from checking the equality of *ObjectIdentifiers* (which are 64bit values) or *UUIDs* (which are 128bit values).

For this reason GraphCodable does not implement a *hashable-based* automatic identity for strings or any other type, although this is not a trick, and leaves that choice up to the user. However, it is possible to activate it with two options, as we will see in the next paragraph.

#### Control identity globally

Some options in the `GraphEncoder(  _ options: )` method control identity **globally**, that is, they apply to all encoded reference types.

- the `.disableIdentity` option disable identity for all types, regardless of protocol `GIdentifiable` and any other options.

If the `.disableIdentity` option is **not** set:

- the `.ignoreGIdentifiableProtocol` option override the adoption of the `GIdentifiable` protocol and make the encoder ignore it. This implies that reference types will have the identity defined by their *ObjectIdentifier* and value types will have no identity;
- the `.disableAutoObjectIdentifierIdentityForReferences` option prevents reference types from automatically receiving the identity defined by their *ObjectIdentifier* (they can receive it adopting the `GIdentifiable` protocol, like value types);
- the `.tryHashableIdentityAtFirst` option causes all *hashable* types to use themselves as an identity. The other options only come into play if the types are not *hashable*;
- the `.tryHashableIdentityAtLast` option causes all *hashable* types to use themselves as the identity if they haven't obtained an identity otherwise.

You can use one of these last two options to check if and how expensive it actually is to employ an identity of *hashable* types based on their own value.

It should be noted that if the two options  `.disableIdentity`  and `.disableInheritance` are used together, the GraphCodable encoder behaves exactly like the swift Codable one, ignoring inheritance and identity. These two options are collected together in `.mimicSwiftCodable`.

**Note**: if a reference type adopt the the `GIdentifiable` protocol and `gcodableID` returns `nil`, the type don't receive an identity unless the `.ignoreGIdentifiableProtocol`  option is set.

### UserInfo dictionary

Both `GraphEncoder` and `GraphDecoder` allow setting a dictionary accessible during encoding and decoding respectively with the aim of adopting appropriate strategies. Usage is identical to that of Codable.

### Versioning of reference types

Reference types can adopt the `GVersion` protocol to define the version (a `UInt32` value) of their type so that they can handle different decoding strategies depending on it.

```swift
public protocol GVersion : AnyObject {
	static var encodeVersion : UInt32 { get }
}
```

The encoder stores the value returned by `encodeVersion` together with the reference type information, only once for each reference type. During decoding, the version of the encoded reference type can be accessed through the decoder property `encodedVersion`.

```swift
public protocol GDecoder {
	...
	var encodedVersion : UInt32  { get throws }
  ...
}

```

If the type does not adopt the GVersion protocol, `encodedVersion` returns 0. If the `GVersion` protocol is adopted, it is therefore appropriate that `encodeVersion` returns at least 1.

**Note**: If inheritance is disabled, information about reference types, including version, is not encoded and therefore versions cannot be used.

A very simple example: suppose that your program saves its data in the "Documents/MyFile.graph" file:

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
print( inRoot )	// MyData(number: 3)

let data = try GraphEncoder().encode( inRoot ) as Data

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
	
	required init(from decoder: GDecoder) throws {
		let version = try decoder.encodedVersion
		
		switch version {
		case 0:		// previous version
			self.string	=  String( try decoder.decode( for: OldKey.number ) as Int )
		default:	// current version
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

let outRoot	= try GraphDecoder().decode( MyData.self, from: data )
print( outRoot )	// MyData(string: "3")
```
### Obsolete reference types

##### The easy part

Now suppose it is absolutely necessary to change some class `MyData` to `MyNewData`. The problem is that there are already saved files in which reference of class `MyData` are stored and it is therefore necessary, during decoding, that objects of the new type `MyNewData` be created instead of these.

To solve the problem the old objective-c NSKeyedUnarchiver offers the possibility to map the new class to the encoded class name using the function (and class function) `setClass( _ cls: AnyClass?, forClassName:String)`.

On the other hand, in swift, class names are much more complicated than in objective-c, more difficult to manage and therefore GraphCodable employs a different method **which uses the swift type system avoiding the use of class name strings**.

The `GDecodable` protocol defines the static property `replacementType` which by default returns `Self.self`. 

```swift
public protocol GDecodable {
	init(from decoder: GDecoder) throws
	
	static var replacementType : GDecodable.Type { get }
}

public extension GDecodable {
	static var replacementType : GDecodable.Type { Self.self }
}
```

And so, `MyData` remains in the code, "emptied" of all its internal code, and `replacementType` is used to indicate the type that `MyData` replaces. Notice how `replacementType` does not return `MyNewData.self`, but `MyNewData.replacementType`. This is the correct thing to do, for reasons that will become clearer in the next paragraph.

```swift
class MyData: GCodable {
	class var replacementType: GDecodable.Type {
		return MyNewData.replacementType
	}
	
	required init(from decoder: GDecoder) throws {
		preconditionFailure("Unreachable \(#function)")
	}
	
	func encode(to encoder: GEncoder) throws {
		preconditionFailure("Unreachable \(#function)")
	}
  // no other code
}
```
To make this easier, GraphCodable provides the `GObsolete` protocol, which has no function in the library, but implements the two required but now unreachable methods `init(from decoder: GDecoder)` and `encode(to encoder: GEncoder)` of `GCodable` and allows you to mark the classes that have been replaced in a clear way. The code then becomes:

```swift
class MyData : GObsolete {
	class var replacementType: GDecodable.Type {
		return MyNewData.replacementType
	}
}
```

Here is the full code:

```swift
import Foundation
import GraphCodable

class MyData : GObsolete {
	class var replacementType: GDecodable.Type {
		return MyNewData.replacementType
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
		if try decoder.replacedType != nil {
			// I'm decoding MyData and replacing with MyNewData
			self.string	=  String( try decoder.decode( for: OldKey.number ) as Int )
		} else {
			// I'm decoding MyNewData
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
print( outRoot )	// MyNewData(string: 3)
```
Multiple classes can be replaced by only one if necessary. Use `decoder.replacedType` to find out which one was replaced during decoding. Versioning and class replacement can be combined.

##### The hard part

The illustrated mechanism **breaks down** when the class whose name is changed can be used as *a parameter types of a generic class* that adopts the `GDecodable` protocol:

```swift
class Generic<T:GDecodable> : GDecodable {
	let data : T
	
	required init(from decoder: GDecoder) throws {
		self.data = try decoder.decode()
	}
}
```

Now suppose you encoded an instance of `Generic<MyData>`and replaced `MyData` with `MyNewData`.  During decoding, the decoder encounters the `Generic<MyData>` class and calls `Generic<MyData>.replacementType`, getting `Generic<MyData>.self` instead of  `Generic<MyNewData>.self`.

It follows that any generic class that adopts `GCodable` protocol **must** correctly implement `replacementType` if there is a chance that its parameter types are **renamed** classes. That's how:

```swift
extension Generic {
	class var replacementType: GDecodable.Type {
		func buildSelf<T>( _ typeT:T.Type ) -> GDecodable.Type
		where T:GDecodable { Generic<T>.self }

		let typeT = T.replacementType

		return buildSelf( typeT )
	}
}
```

**Note**: For some strange reason swift doesn't allow you to write `buildSelf( T.replacementType )` directly.

What follows is a slightly more complex example. First we have some utility functions for the next code example (`GraphCodableUti.checkEncoder` and `GraphCodableUti.checkDecoder` are two utility/debug functions defined in GraphCodableUti.swift):

```swift
func path( number:Int ) -> URL {
	let string = number > 0 ? String(number) : ""
	return FileManager.default.urls(
		for: .documentDirectory, in: .userDomainMask
	)[0].appendingPathComponent("ModelNumber\(string).graph")
}

typealias DataModel = Model<Two<Double, Int>>

func encode( _ phase:Int ) throws {
	let inRoot : DataModel = Model(integer: 1, string: "P", value: Two(1.0,3))
	print( "••• Encoding format \(phase):" )
	print( "\t\(inRoot)" )
	try (
		try GraphCodableUti.checkEncoder( root: inRoot ) as Data
	).write( to: path(number: phase) )
	print()
}

func decode( _ phase:Int ) throws {
	print( "••• Decoding format \(phase):" )
	let outRoot	= try GraphCodableUti.checkDecoder(
		type: DataModel.self,
		data: try Data.init(contentsOf: path(number: phase)),
		qualifiedClassNames: false
	)
	print( "Result:\n\t\(outRoot)" )
	print()
}
```

and this is the **first version** of our code:

```swift
final class Pair<T,Q> : GDecodable
where T:GDecodable, Q:GDecodable {
	let lhs	: T
	let rhs	: Q
	
	init( _ lhs: T, _ rhs: Q ) {
		self.lhs	= lhs
		self.rhs	= rhs
	}
	
	init(from decoder: GDecoder) throws {
		lhs	= try decoder.decode()
		rhs	= try decoder.decode()
	}
}

extension Pair: GEncodable
where T:GEncodable, Q:GEncodable {
	func encode(to encoder: GEncoder) throws {
		try encoder.encode( lhs )
		try encoder.encode( rhs )
	}
}

extension Pair: CustomStringConvertible {
	var description: String {
		return "(\(lhs) <-> \(rhs))"
	}
}
// ----------------------------------------------
final class Model<S:GDecodable> : GDecodable {
	let value	: Pair<Pair<S,Int>,String>
	
	init( integer:Int, string:String, value:S ) {
		self.value = Pair(Pair(value,integer), string)
	}
	
	init(from decoder: GraphCodable.GDecoder) throws {
		value	= try decoder.decode()
	}
}
extension Model: GEncodable where S:GEncodable {
	func encode(to encoder: GraphCodable.GEncoder) throws {
		try encoder.encode( value )
	}
}

extension Model: CustomStringConvertible {
	var description: String {
		return "\(Self.self) = { value = \(value) }"
	}
}
// ----------------------------------------------
typealias Two = Pair
try encode( 0 )	// encode old version
try decode( 0 )	// decode old version

```

This first version (format 0) encodes the data in the file *ModelNumber0.graph* and is able to decode it, as you can see from the console output. In particular, all classes encountered during dearchiving are shown:

```
••• Encoding format 0:
	Model<Pair<Double, Int>> = { value = (((1.0 <-> 3) <-> 1) <-> P) }

••• Decoding format 0:
Decoded Classes: --------------------------
	'Model<Pair<Double, Int>>'
	'Pair<Double, Int>'
	'Pair<Pair<Double, Int>, Int>'
	'Pair<Pair<Pair<Double, Int>, Int>, String>'
Result:
	Model<Pair<Double, Int>> = { value = (((1.0 <-> 3) <-> 1) <-> P) }
```

Now suppose that in the new version (format 1) of the code we want to change the name of the `Pair` class to `Couple`:

```swift
final class Couple<T,Q> : GDecodable
where T:GDecodable, Q:GDecodable {
	let lhs	: T
	let rhs	: Q
	
	init( _ lhs: T, _ rhs: Q ) {
		self.lhs	= lhs
		self.rhs	= rhs
	}
	
	init(from decoder: GDecoder) throws {
		lhs	= try decoder.decode()
		rhs	= try decoder.decode()
	}
}

extension Couple: GEncodable
where T:GEncodable, Q:GEncodable {
	func encode(to encoder: GEncoder) throws {
		try encoder.encode( lhs )
		try encoder.encode( rhs )
	}
}

extension Couple: CustomStringConvertible {
	var description: String {
		return "(\(lhs) <-> \(rhs))"
	}
}
```

First, `Model` is a generic class whose type could depend on `Pair` when passed as `S`. If `Pair` becomes `Couple`, the names of `Model` specializations that have `Pair` as a type parameter must also change accordingly. To handle during decoding **all situations** in which the name of `Model` argument types changes,  `Model` implements the `replacementType` static property:

```swift
extension Model {
	class var replacementType: GDecodable.Type {
		func buildSelf<T>( _ typeT:T.Type ) -> GDecodable.Type
		where T:GDecodable { Model<T>.self }

		let typeT = S.replacementType

		return buildSelf( typeT )
	}
}

```

The code is substantially identical to the one already seen by `Generic` `replacementType`. Similarly, `Couple`, being generic, must implements the `replacementType` static property to handle during decoding **all situations** in which the name of one or more of its argument types changes:

```swift
extension Couple {
	class var replacementType: GDecodable.Type {
		func buildSelf<newT,newQ>( _ typeT:newT.Type, _ typeQ:newQ.Type ) -> GDecodable.Type
		where newT:GDecodable, newQ:GDecodable { Couple<newT,newQ>.self }
		
		let typeT = T.replacementType
		let typeQ = Q.replacementType
		
		return buildSelf( typeT, typeQ )
	}
}
```

Compare these two properties! I hope the mechanism is clear:`buildSelf` is a generic sub-function that returns the class specialization based on the parameter types it receives. `Couple` has 2 type parameters, `Model` has one type parameter and at least until variadic generics are available, it doesn't seem possible to generalize this functionality over different classes;

The final touch is to make the `Pair` class obsolete by telling us to replace it with `Couple`.

```swift
final class Pair<T,Q> : GObsolete
where T:GCodable, Q:GCodable {
	static var replacementType: GDecodable.Type {
		return Couple<T,Q>.replacementType
	}
}
```

Note how replacementType must return `Couple<T,Q>.replacementType` and not just `Couple<T,Q>` to account for the fact that `T` and `Q` themselves could be replaced. The replacement process is therefore effectively recursive.

Code summary (format 1) for easy copy and paste:

```swift
final class Pair<T,Q> : GObsolete
where T:GCodable, Q:GCodable {
	static var replacementType: GDecodable.Type {
		return Couple<T,Q>.replacementType
	}
}

final class Couple<T,Q> : GDecodable
where T:GDecodable, Q:GDecodable {
	let lhs	: T
	let rhs	: Q
	
	init( _ lhs: T, _ rhs: Q ) {
		self.lhs	= lhs
		self.rhs	= rhs
	}
	
	init(from decoder: GDecoder) throws {
		lhs	= try decoder.decode()
		rhs	= try decoder.decode()
	}
}

extension Couple: GEncodable
where T:GEncodable, Q:GEncodable {
	func encode(to encoder: GEncoder) throws {
		try encoder.encode( lhs )
		try encoder.encode( rhs )
	}
}

extension Couple: CustomStringConvertible {
	var description: String {
		return "(\(lhs) <-> \(rhs))"
	}
}

extension Couple {
	class var replacementType: GDecodable.Type {
		func buildSelf<newT,newQ>( _ typeT:newT.Type, _ typeQ:newQ.Type ) -> GDecodable.Type
		where newT:GDecodable, newQ:GDecodable { Couple<newT,newQ>.self }
		
		let typeT = T.replacementType
		let typeQ = Q.replacementType
		
		return buildSelf( typeT, typeQ )
	}
}

// ----------------------------------------------
final class Model<S:GDecodable> : GDecodable {
	let value	: Couple<Couple<S,Int>,String>
	
	init( integer:Int, string:String, value:S ) {
		self.value = Couple(Couple(value,integer), string)
	}
	
	init(from decoder: GraphCodable.GDecoder) throws {
		value	= try decoder.decode()
	}
}
extension Model: GEncodable where S:GEncodable {
	func encode(to encoder: GraphCodable.GEncoder) throws {
		try encoder.encode( value )
	}
}

extension Model: CustomStringConvertible {
	var description: String {
		return "\(Self.self) = { value = \(value) }"
	}
}

extension Model {
	class var replacementType: GDecodable.Type {
		func buildSelf<T>( _ typeT:T.Type ) -> GDecodable.Type
		where T:GDecodable { Model<T>.self }

		let typeT = S.replacementType

		return buildSelf( typeT )
	}
}
 
typealias Two = Couple
try decode( 0 )	// decode the old (format 0) file
try encode( 1 )	// encode the new (format 1) file
try decode( 1 )	// decode the new (format 1) file
```

This second version was able to decode the data in the file *ModelNumber0.graph* (format 0), encode the data in the file *ModelNumber1.graph* (format 1) and is able to decode it. In particular, you can see all **classes replaced** when the new version of the code decodes the format 0 file:

```
••• Decoding format 0:
Decoded Classes: --------------------------
	'Couple<Couple<Couple<Double, Int>, Int>, String>'
	'Couple<Couple<Double, Int>, Int>'
	'Couple<Double, Int>'
	'Model<Couple<Double, Int>>'
where:
	'Model<Pair<Double, Int>>'
		was replaced by 'Model<Couple<Double, Int>>'
	'Pair<Double, Int>'
		was replaced by 'Couple<Double, Int>'
	'Pair<Pair<Double, Int>, Int>'
		was replaced by 'Couple<Couple<Double, Int>, Int>'
	'Pair<Pair<Pair<Double, Int>, Int>, String>'
		was replaced by 'Couple<Couple<Couple<Double, Int>, Int>, String>'
Result:
	Model<Couple<Double, Int>> = { value = (((1.0 <-> 3) <-> 1) <-> P) }

••• Encoding format 1:
	Model<Couple<Double, Int>> = { value = (((1.0 <-> 3) <-> 1) <-> P) }

••• Decoding format 1:
Decoded Classes: --------------------------
	'Couple<Couple<Couple<Double, Int>, Int>, String>'
	'Couple<Couple<Double, Int>, Int>'
	'Couple<Double, Int>'
	'Model<Couple<Double, Int>>'
Result:
	Model<Couple<Double, Int>> = { value = (((1.0 <-> 3) <-> 1) <-> P) }

```

