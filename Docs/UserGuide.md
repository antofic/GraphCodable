#  User Guide

- [Premise](#Premise)
- [Supported system types](#Supported-system-types)
- [Keyed coding](#Keyed-coding)
- [Unkeyed coding](#Unkeyed-coding)
- [Inheritance](#Inheritance)
  - [How does inheritance work?](#How-does-inheritance-work?)
  - [Disable inheritance](#Disable-inheritance)
  - [Control inheritance globally](#Control-inheritance-globally)
- [Identity](#Identity)
  - [Reference types identity](#Reference-types-identity)
  - [Value types identity](#Value-types-identity)
  - [Conditional encoding](#Conditional-encoding)
  - [Directed acyclic graphs (DAG)](#Directed-acyclic-graphs-(DAG))
  - [Directed cyclic graphs (DCG): using `deferDecode(...)`](#Directed-cyclic-graphs-(DCG):-using-`deferDecode(...)`)
    - [Weak variables example](#Weak-variables-example)
    - [A more general example](#A-more-general-example)
  - [Identity for value types that use copy on write (COW)](#Identity-for-value-types-that-use-copy-on-write-(COW))
  - [Identity for swift system value types that use copy on write (COW)](#Identity-for-swift-system-value-types-that-use-copy-on-write-(COW))
  - [Identity alternative design](#Identity-alternative-design)
  - [Control identity globally](#Control-identity-globally)
- [UserInfo dictionary](#UserInfo-dictionary)
- [Versioning with `userVersion`](#Versioning-with-`userVersion`)
- [Versioning of reference types](#Versioning-of-reference-types)
- [Renaming reference types](#Renaming-reference-types)
  - [Non generic references](#Non-generic-references)
  - [Generic references](#Generic-references)
  - [Using class name strings](#Using-class-name-strings)
- [GraphCodable and BinaryIO](#GraphCodable-and-BinaryIO)
  - [An example](#An-example)
  - [The `BCodable` protocol](#The-`BCodable`-protocol)
  - [The `GBinaryCodable` protocol](#The-`GBinaryCodable`-protocol)
  - [The `GPackCodable` protocol](#The-`GPackCodable`-protocol)
  - [Switch from `GCodable` to `GBinary/PackCodable` and vice versa](#Switch-from-`GCodable`-to-`GBinary/PackCodable`-and-vice-versa)
  - [UserInfo dictionary and other informations](#UserInfo-dictionary-and-other-informations)
  - [BinaryIO versioning](#BinaryIO-versioning)
  - [GraphCodable and BinaryIO for some system types](#GraphCodable-and-BinaryIO-for-som-system-types)
    - [Foundation type `CGSize`](#Foundation-type-`CGSize`)
    - [Swift standard library type `String`](#Swift-standard-library-type-`String`)
    - [Swift standard library type `Array`](#Swift-standard-library-type-`Array`)
    - [Foundation type `PersonNameComponents`](#Foundation-type-`PersonNameComponents`)
  - [Final Advice](#Final-Advice)
- [BinaryIO as standalone package](#BinaryIO-as-standalone-package)

## Premise

GraphCodable is a Swift encode/decode package (similar to Codable at interface level) that does not treat reference types as second-class citizens. Indeed, it also offers for value types a possibility normally reserved only for reference types: that of taking into account their identity to avoid duplication of data during encoding and decoding.

GraphCodable was born as an experiment to understand if it is possible to write in Swift a package that offers for all Swift types the functions that NSCoder, NSKeyedArchiver and NSKeyedUnarchiver have for Objective-C types.

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

Clarified that the purpose of the package is to <u>get after decoding the same "thing" that was encoded</u>, the characteristics of GraphCodable are illustrated in the next paragraphs with simple but working examples that can be directly tested with copy and paste.

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

## Keyed coding

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

## Unkeyed coding

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

## Inheritance

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

### How does inheritance work?

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

### Disable inheritance

There are situations where it is necessary or desirable to **disable** inheritance:

- A **private** reference type cannot be decoded because it cannot be constructed from its type name. The encoder always checks if a type is constructible: if not, it throws an exception at runtime. You can also check whether a `GEncodable` reference type is constructible by calling the `supportsCodableInheritance` property.
- If a reference type **is not part of a class hierarchy**, encoding its type name to support inheritance is unnecessary.

For cases like these, the `GEncodable` protocol provides  the `inheritanceEnabled` property:

```swift
public protocol GEncodable {
	var inheritanceEnabled : Bool { get }
  /* ... */
}

extension GEncodable {
	public var inheritanceEnabled : Bool { false }
  /* ... */  
}

extension GEncodable where Self:AnyObject {
	public var inheritanceEnabled : Bool { true }
    /* ... */  
}

```

So by default  `inheritanceEnabled` returns `false` for value types and `true` for reference types. A reference type can disable inheritance by "overriding" the `inheritanceEnabled` property and return `false`:

```swift
class MyReferenceType: GEncodable {
	var inheritanceEnabled: Bool { false }
  /* ... */
}
```

**Note**: `inheritanceEnabled`  has no effect for a value type.

### Control inheritance globally

Some options in the `GraphEncoder(  _ options: )` method control inheritance **globally**, that is, they apply to all encoded reference types:

- the `.disableInheritance` option disable inheritance for all reference types, regardless of protocol `GInheritance`;

## Identity

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

The way value types behave, it makes no sense to talk about which data structure to preserve; conversely, in certain cases their duplication/multiplication can be problematic if they contain a large amount of data. Consider for example a value type that implements the copy-on-write (COW) mechanism. Each time an instance of the type is archived, its internal buffer (a reference type) is encoded and re-encoded multiple times even though it is shared (i.e.: when `isKnownUniquelyReferenced( buffer )` returns `false`), multiplying the size of the encoded data. During decoding separate buffers are created, all with identical content, multiplying the the memory required after dearchiving.

For this reason, in analogy to the `Identifiable` system protocol, GraphCodable allows to define an identity for encoding and decoding also for value types (by default they don't have one), via the `GIdentifiable` protocol. Reference types can also make use of the `GIdentifiable`protocol where for some reason it is necessary to define an identity other than the one derived from *ObjectIdentifier* or remove at all their identity.

### Reference types identity

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

### Value types identity

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

### Conditional encoding

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

### Directed acyclic graphs (DAG)

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

### Directed cyclic graphs (DCG): using `deferDecode(...)`

What happens if you add a connection from `e` to `b` in the previous example?

- The graph become cyclic (DCG);
- Your code leaks memory: ARC cannot release `e`, `b` and `d` because each retain the other;
- GraphCodable encodes it but generates an exception during decoding;
- Codable generates an exception during encoding.

Just like ARC cannot autamatically release `e`, `b` and d because each retain the other, GraphCodable cannot initialize `e`, `b` and `d` because the initialization of each of them requires that the other be initialized and Swift does not allow to exit from an init method without inizializing all variables. So, when GraphCodable during decode encounters a cycle that it cannot resolve, it throws an exception.

#### Weak variables example

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

#### A more general example

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

### Identity for value types that use copy on write (COW)

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

Of course, identity for value types is not limited only to those implementing the COW mechanism, but can be used any time that it makes sense to talk about identity for the type in question in order to avoid "identical" instances being encoded and decoded multiple times.

### Identity for swift system value types that use copy on write (COW)

Many swift system value types use the copy on write (COW) mechanism. Among these, the most common are `Array`, `ContiguousArray`, `Data`, `Set`, `Dictionary` and presumably `String` beyond a certain number of characters. Unfortunately, none of these types exposes the *ObjectIdentifier* of the reference type used as storage, otherwise it would be very simple to provide them with identities, exactly as it was done in the example of the previous paragraph with `MyArray`.

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

each string (a string is `Hashable`) acquires its own self-defined identity, and all equal strings are encoded only once. However, care must be taken when using this method (or generalizing it) because it involves checking potentially complex and large values for equality during encoding, which can slow down the procedure. This is very different from checking the equality of *ObjectIdentifiers* (which are 64bit values) or *UUIDs* (which are 128bit values).

For this reason GraphCodable does not implement a *hashable-based* automatic identity for strings or any other type, although this is not a trick, and leaves that choice up to the user. However, it is possible to activate it with two options, as we will see in the next paragraph.

### Identity alternative design

An alternative design of the same functionality could have been the following which does not employ the additional `GIdentifiable` protocol:

```swift
public protocol GEncodable<GID> {
	associatedtype GID : Hashable
	var gcodableID: Self.GID? { get }
  /* ... */
}

extension GEncodable {
	public var gcodableID: Self.GID? { nil }
	/* ... */
}

extension GEncodable where Self:AnyObject {
	public var gcodableID: ObjectIdentifier? {
		ObjectIdentifier( self )
	}
  /* ... */
}

```

In fact it was the first choice, because it was simpler, but in this way it would have been impossible for the user to choose to provide identities to system types (like `String`) that already adopt the `GEncodable` protocol in the library. This is why I then chose to adopt a separate protocol.

### Control identity globally

Some options in the `GraphEncoder( _ options: )` init method control identity **globally**, that is, they apply to all encoded types.

- the `.disableIdentity` option disable identity for all types, regardless of protocol `GIdentifiable` and any other options.

If the `.disableIdentity` option is **not** set:

- the `.tryHashableIdentityAtFirst` option causes all *hashable* types to use themselves as an identity. The other options only come into play if the types are not *hashable*;
- the `.tryHashableIdentityAtLast` option causes all *hashable* types to use themselves as the identity if they haven't obtained an identity otherwise.

You can use one of these last two options to check if and how expensive it actually is to employ an identity of *hashable* types based on their own value.

It should be noted that if the two options  `.disableIdentity`  and `.disableInheritance` are used together, the GraphCodable encoder behaves exactly like the swift Codable one, ignoring inheritance and identity. These two options are collected together in `.mimicSwiftCodable`.

## UserInfo dictionary

Both `GraphEncoder` and `GraphDecoder` allow setting a dictionary accessible during encoding and decoding respectively with the aim of adopting appropriate strategies. Usage is identical to that of Codable.

## Versioning with `userVersion`

What to do if during the evolution of the program it becomes necessary to modify a type that uses `GCodable` and it is therefore necessary to archive additional and/or different fields? How to distinguish old versions of a type from the current one so that it can be decoded correctly?

- If the type uses keyed encoding, employing new keys while retaining the ability to read the old ones is generally the easiest way to manage different versions of a type.
- Reference types have the ability to store a version (a `UInt32` value) per type (see  [Versioning of reference types](#Versioning-of-reference-types)).
- If the type doesn't use keyed encoding, you can use a **global** version  (a `UInt32` value) named `userVersion`.

The current version of the archive is set with:

```swift
let myCurrentGlobalVersion	= UInt32(3)
let graphEncoder = GraphEncoder(userVersion: myCurrentGlobalVersion)
...
```

During decoding you can access the encoded version with:

```swift
init(from decoder: GDecoder) throws {
	let version = decoder.encodedUserVersion
  /* ... */
}
```

This  version is also available during encoding (useful if the program should support the possibility of saving a document also in previous formats):

```swift
func encode(to encoder: GEncoder) throws {
	let version = encoder.userVersion
  /* ... */
}

```

It is **important** to note that the **`userVersion`** is unique and global for the entire archive and is shared with the BinaryIO package (see [GraphCodable and BinaryIO](#GraphCodable-and-BinaryIO)). It follows that whenever any `GCodable` or  `BCodable` type changes encoding it is necessary to increment **`userVersion`** (see [BinaryIO versioning](#BinaryIO-versioning)).

**Note**: **`userVersion`** is really a feature of BinaryIO that GraphCodable takes advantage of.

## Versioning of reference types

Reference types can use the `classVersion` property in `GEncodable` protocol:

```swift
public protocol GEncodable {
	/* ... */
  static var classVersion : UInt32 { get }
}

extension GEncodable {
	public static var classVersion : UInt32 { 0 }
}

```

 to define the version (a `UInt32` value) of their type so that they can handle different decoding strategies depending on it. The default `classVersion` value is 0. This is a unique value available to each reference type and not shared with other types.

The encoder stores the value returned by `classVersion` together with the reference type information, only once for each reference type. During decoding, the version of the encoded reference type can be accessed through the decoder property `encodedClassVersion`.

```swift
public protocol GDecoder {
	...
	var encodedClassVersion : UInt32  { get throws }
  ...
}

```

**Note**: If inheritance is disabled, information about reference types (including classVersion) is not encoded and therefore versions cannot be used.

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

The new version of the program uses a different implementation of the MyData class. It is therefore necessary to be able to read the data saved by both versions of `MyData`. That's how:

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
		let version = try decoder.encodedClassVersion
		
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

## Renaming reference types

Now suppose it is absolutely necessary to change some class `MyData` to `MyNewData`. The problem is that there are already saved files in which reference of class `MyData` are stored and it is therefore necessary, during decoding, that objects of the new type `MyNewData` be created instead of these.

To solve the problem the old objective-c `NSKeyedUnarchiver` offers the possibility to map the new class to the encoded class name using the function (and class function) `setClass( _ cls: AnyClass?, forClassName:String)`.

On the other hand, in swift, class names are much more complicated than in objective-c, more difficult to manage and therefore GraphCodable employs a different method **which uses the swift type system avoiding the use of class name strings**. However, it is still possible to use strings for class names as a (discouraged) alternative.

**Note**: A reference type can be replaced by either another reference type or a value type.

### Non generic references

The `GDecodable` protocol defines the static property `decodeType` which by default returns `Self.self`. 

```swift
public protocol GDecodable {
	init(from decoder: GDecoder) throws
	
	static var decodeType : GDecodable.Type { get }
}

public extension GDecodable {
	static var decodeType : GDecodable.Type { Self.self }
}
```

And so, `MyData` remains in the code, "emptied" of all its internal code, and `decodeType` is used to indicate the `MyData`  replacement type: `MyNewData`. Notice how `MyData.decodeType` does not return `MyNewData.self`, but `MyNewData.decodeType`. This is the correct thing to do: `MyNewData` could in turn indicate a type that replaces it. The further reason will become clearer in the next paragraph.

```swift
class MyData: GCodable {
	class var decodeType: GDecodable.Type {
		return MyNewData.decodeType
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

To make this easier, GraphCodable provides the `GObsolete` protocol, which has no function in the package, but implements the two required but now unreachable methods `init(from decoder: GDecoder)` and `encode(to encoder: GEncoder)` of `GCodable` and allows you to mark the classes that have been replaced in a clear way. The code then becomes:

```swift
class MyData : GObsolete {
	class var decodeType: GDecodable.Type {
		return MyNewData.decodeType
	}
}
```

Here is the full code:

```swift
import Foundation
import GraphCodable

class MyData : GObsolete {
	class var decodeType: GDecodable.Type {
		return MyNewData.decodeType
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
		if try decoder.replacedClass != nil {
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

Multiple classes can be replaced by only one if necessary. Use `decoder.replacedClass` to find out which one was replaced during decoding. Versioning and class replacement can be combined.

### Generic references

The illustrated mechanism **breaks down** when the class whose name is changed can be used as *a parameter types of a generic class* that adopts the `GDecodable` protocol:

```swift
class Generic<T:GDecodable> : GDecodable {
	let data : T
	
	required init(from decoder: GDecoder) throws {
		self.data = try decoder.decode()
	}
}
```

Now suppose you encoded an instance of `Generic<MyData>`and replaced `MyData` with `MyNewData`.  During decoding, the decoder encounters the `Generic<MyData>` class and calls `Generic<MyData>.decodeType`, getting `Generic<MyData>.self` instead of  `Generic<MyNewData>.self`.

It follows that any generic class that adopts `GCodable` protocol **must** correctly implement `decodeType` if there is a chance that its parameter types are **replaced**. That's how:

```swift
extension Generic {
	class var decodeType: GDecodable.Type {
		func buildSelf<T>( _ typeT:T.Type ) -> GDecodable.Type
		where T:GDecodable { Generic<T>.self }

		let typeT = T.decodeType

		return buildSelf( typeT )
	}
}
```

**Note**: For some strange reason swift doesn't allow you to write `buildSelf( T.decodeType )` directly.

What follows is a slightly more complex example. We have a generic class `Pair<T,Q>`:

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
```

We have a generic class `Model<S>`:

```swift
final class Model<S:GDecodable> : GDecodable {
	let value	: Pair<Pair<S,String>,Pair<Pair<S,String>,String>>
	
	init( string:String, value:S ) {
		let inner	= Pair(value,string)
		self.value	= Pair(inner, Pair(inner, string))
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

extension Model where S:GEncodable {
	func encode( _ fileName:String, verbose:Bool ) throws {
		let graphEncoder	= GraphEncoder()
		if verbose {
			print( "••• Encoding:\n\t\(self)\n••• to file:\n\t'\(fileName)'" )
			print( try graphEncoder.dump(self, options: [.showBody,.showValueDescriptionInBody]))
		}
		
		let data = try graphEncoder.encode(self) as Data
		try data.write( to: Self.path( fileName:fileName ) )
	}
}

extension Model {
	static func path( fileName:String ) -> URL {
		return FileManager.default.urls(
			for: .documentDirectory, in: .userDomainMask
		)[0].appendingPathComponent( fileName )
	}
	
	static func decode( _ fileName:String, verbose:Bool ) throws -> Model {
		print( "••• Decoding from file\n\t'\(fileName)'" )
		let data			= try Data.init(contentsOf: path( fileName:fileName ))
		let graphDecoder	= GraphDecoder()
		
		if verbose {
			print( try graphDecoder.dump(from: data, options: [
				.showBody,.showConstructionMap
			]))
		}
		
		let root = try graphDecoder.decode( Model.self, from: data )
		if verbose {
			print( "••• Decoded:\n\t\(root)" )
		}
		return root
	}
}
```

In the last two extensions we have included the functions to archive a `Model` instance on a file in the *Documents* folder and to dearchive it, in both cases with a suitable `verbose` option. Let's do it:

```swift
typealias Two 		= Pair
typealias DataModel = Model<Two<Double, Int>>

let fileName = "ModelPair.graph"
var model	: DataModel

model	= Model( string: "A", value: Two(1.0,3) )

try model.encode( fileName, verbose: false )

model	= try DataModel.decode( fileName, verbose: true )
```

The program prints:

```
••• Encoding:
	Model<Pair<Double, Int>> = { value = (((1.0 <-> 3) <-> A) <-> (((1.0 <-> 3) <-> A) <-> A)) }
••• to file:
	'ModelPair.graph'
= BODY =================================================================================
- REF0001 TYPE0001
	- REF0002 TYPE0002
		- REF0003 TYPE0003
			- REF0004 TYPE0004
				- BIV 1.0
				- BIV 3
			.
			- BIV "A"
		.
		- REF0005 TYPE0005
			- PTS0003
			- BIV "A"
		.
	.
.
========================================================================================

••• Decoding from file
	'ModelPair.graph'
= BODY =================================================================================
- REF0001 TYPE0001
	- REF0002 TYPE0002
		- REF0003 TYPE0003
			- REF0004 TYPE0004
				- BIV { 8 bytes }
				- BIV { 8 bytes }
			.
			- BIV { 2 bytes }
		.
		- REF0005 TYPE0005
			- PTS0003
			- BIV { 2 bytes }
		.
	.
.
= CONSTRUCTIONMAP ======================================================================
Encoded class types will create the following decoded types:
	- TYPE0001: class Model<Pair<Double, Int>>
	- TYPE0002: class Pair<Pair<Pair<Double, Int>, String>, Pair<Pair<Pair<Double, Int>, String>, String>>
	- TYPE0003: class Pair<Pair<Double, Int>, String>
	- TYPE0004: class Pair<Double, Int>
	- TYPE0005: class Pair<Pair<Pair<Double, Int>, String>, String>
========================================================================================

••• Decoded:
	Model<Pair<Double, Int>> = { value = (((1.0 <-> 3) <-> A) <-> (((1.0 <-> 3) <-> A) <-> A)) }
```

Now suppose that in the new version of our program we want to change the name of the `Pair` class to `Couple`:

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

And then we updated `Model` to contain `Couples`:

```swift
final class Model<S:GDecodable> : GDecodable {
	let value	: Couple<Couple<S,String>,Couple<Couple<S,String>,String>>
	/* ... */
}
```

First, `Model` is a generic class whose type could depend on `Pair` when passed as `S`. If `Pair` becomes `Couple`, the names of `Model` specializations that have `Pair` as a type parameter must also change accordingly. To handle during decoding **all situations** in which the name of `Model` argument types changes,  `Model` implements the `decodeType` static property:

```swift
extension Model {
	class var decodeType: GDecodable.Type {
		func buildSelf<T>( _ typeT:T.Type ) -> GDecodable.Type
		where T:GDecodable { Model<T>.self }
		
		let typeT = S.decodeType
		
		return buildSelf( typeT )
	}
}
```

The code is substantially identical to the one already seen by `Generic` `decodeType`. Similarly, `Couple`, being generic, must implements the `decodeType` static property to handle during decoding **all situations** in which the name of one or more of its argument types changes:

```swift
extension Couple {
	static var decodeType: GDecodable.Type {
		func buildSelf<newT,newQ>( _ typeT:newT.Type, _ typeQ:newQ.Type ) -> GDecodable.Type
		where newT:GDecodable, newQ:GDecodable { Couple<newT,newQ>.self }
		
		let typeT = T.decodeType
		let typeQ = Q.decodeType
		
		return buildSelf( typeT, typeQ )
	}
}
```

Compare these two properties! I hope the mechanism is clear:`buildSelf` is a generic sub-function that returns the class specialization based on the parameter types it receives. `Couple` has 2 type parameters, `Model` has one type parameter and at least until variadic generics are available, it doesn't seem possible to generalize this functionality over different classes;

The final touch is to make the `Pair` class obsolete by telling us to replace it with `Couple`.

```swift
final class Pair<T,Q> : GObsolete
where T:GCodable, Q:GCodable {
	class var decodeType: GDecodable.Type {
		return Couple<T,Q>.decodeType
	}
}
```

Note how decodeType must return `Couple<T,Q>.decodeType` and not just `Couple<T,Q>` to account for the fact that `T` and `Q` themselves could be replaced. The replacement process is therefore effectively recursive.

Now let's try to decode the file and encode it with a new name:

```swift
typealias Two 		= Couple
typealias DataModel = Model<Two<Double, Int>>

let fileName = "ModelPair.graph"
var model	: DataModel

model	= try DataModel.decode( fileName, verbose: true )

let newFileName = "ModelPair2.graph"
try model.encode( newFileName, verbose: true )
```

The program now print:

```
••• Decoding from file
	'ModelPair.graph'
= BODY =================================================================================
- REF0001 TYPE0001
	- REF0002 TYPE0002
		- REF0003 TYPE0003
			- REF0004 TYPE0004
				- BIV { 8 bytes }
				- BIV { 8 bytes }
			.
			- BIV { 2 bytes }
		.
		- REF0005 TYPE0005
			- PTS0003
			- BIV { 2 bytes }
		.
	.
.
= CONSTRUCTIONMAP ======================================================================
Encoded class types will create the following decoded types:
	- TYPE0001: class Model<Couple<Double, Int>>
	- TYPE0002: class Couple<Couple<Couple<Double, Int>, String>, Couple<Couple<Couple<Double, Int>, String>, String>>
	- TYPE0003: class Couple<Couple<Double, Int>, String>
	- TYPE0004: class Couple<Double, Int>
	- TYPE0005: class Couple<Couple<Couple<Double, Int>, String>, String>
where:
	- the encoded TYPE0001: class Model<Pair<Double, Int>>
	  was replaced by class Model<Couple<Double, Int>>
	- the encoded TYPE0002: class Pair<Pair<Pair<Double, Int>, String>, Pair<Pair<Pair<Double, Int>, String>, String>>
	  was replaced by class Couple<Couple<Couple<Double, Int>, String>, Couple<Couple<Couple<Double, Int>, String>, String>>
	- the encoded TYPE0003: class Pair<Pair<Double, Int>, String>
	  was replaced by class Couple<Couple<Double, Int>, String>
	- the encoded TYPE0004: class Pair<Double, Int>
	  was replaced by class Couple<Double, Int>
	- the encoded TYPE0005: class Pair<Pair<Pair<Double, Int>, String>, String>
	  was replaced by class Couple<Couple<Couple<Double, Int>, String>, String>
========================================================================================

••• Decoded:
	Model<Couple<Double, Int>> = { value = (((1.0 <-> 3) <-> A) <-> (((1.0 <-> 3) <-> A) <-> A)) }
••• Encoding:
	Model<Couple<Double, Int>> = { value = (((1.0 <-> 3) <-> A) <-> (((1.0 <-> 3) <-> A) <-> A)) }
••• to file:
	'ModelPair2.graph'
= BODY =================================================================================
- REF0001 TYPE0001
	- REF0002 TYPE0002
		- REF0003 TYPE0003
			- REF0004 TYPE0004
				- BIV 1.0
				- BIV 3
			.
			- BIV "A"
		.
		- REF0005 TYPE0005
			- PTS0003
			- BIV "A"
		.
	.
.
========================================================================================
```

The `.showConstructionMap` option shows the *Construction Map* giving an overview of which type is actually being built and which is being replaced during decoding. In this it differs from the *Reference Map* which is instead the list of classes encoded in the file. 

It is also possible to replace a reference type with a value type:

```swift
struct Couple<T,Q> : GDecodable
where T:GDecodable, Q:GDecodable {
	/* ... */
}

extension Couple {
	static var decodeType: GDecodable.Type {
	/* ... */
  }
}
```

The program now print:

```
••• Decoding from file
	'ModelPair.graph'
= BODY =================================================================================
- REF0001 TYPE0001
	- REF0002 TYPE0002
		- REF0003 TYPE0003
			- REF0004 TYPE0004
				- BIV { 8 bytes }
				- BIV { 8 bytes }
			.
			- BIV { 2 bytes }
		.
		- REF0005 TYPE0005
			- PTS0003
			- BIV { 2 bytes }
		.
	.
.
= CONSTRUCTIONMAP ======================================================================
Encoded class types will create the following decoded types:
	- TYPE0001: class Model<Couple<Double, Int>>
	- TYPE0002: struct Couple<Couple<Couple<Double, Int>, String>, Couple<Couple<Couple<Double, Int>, String>, String>>
	- TYPE0003: struct Couple<Couple<Double, Int>, String>
	- TYPE0004: struct Couple<Double, Int>
	- TYPE0005: struct Couple<Couple<Couple<Double, Int>, String>, String>
where:
	- the encoded TYPE0001: class Model<Pair<Double, Int>>
	  was replaced by class Model<Couple<Double, Int>>
	- the encoded TYPE0002: class Pair<Pair<Pair<Double, Int>, String>, Pair<Pair<Pair<Double, Int>, String>, String>>
	  was replaced by struct Couple<Couple<Couple<Double, Int>, String>, Couple<Couple<Couple<Double, Int>, String>, String>>
	- the encoded TYPE0003: class Pair<Pair<Double, Int>, String>
	  was replaced by struct Couple<Couple<Double, Int>, String>
	- the encoded TYPE0004: class Pair<Double, Int>
	  was replaced by struct Couple<Double, Int>
	- the encoded TYPE0005: class Pair<Pair<Pair<Double, Int>, String>, String>
	  was replaced by struct Couple<Couple<Couple<Double, Int>, String>, String>
========================================================================================

••• Decoded:
	Model<Couple<Double, Int>> = { value = (((1.0 <-> 3) <-> A) <-> (((1.0 <-> 3) <-> A) <-> A)) }
••• Encoding:
	Model<Couple<Double, Int>> = { value = (((1.0 <-> 3) <-> A) <-> (((1.0 <-> 3) <-> A) <-> A)) }
••• to file:
	'ModelPair2.graph'
= BODY =================================================================================
- REF0001 TYPE0001
	- VAL
		- VAL
			- VAL
				- BIV 1.0
				- BIV 3
			.
			- BIV "A"
		.
		- VAL
			- VAL
				- VAL
					- BIV 1.0
					- BIV 3
				.
				- BIV "A"
			.
			- BIV "A"
		.
	.
.
========================================================================================
```

In the *Construction Map* you can now see that all `Pair` reference types have been replaced by `Couple` value types. And because `Couple` is a value type, during the next archive `Couple(1.0,3)` was archived twice. But you can always provide an identity to `Couple`:

```swift
struct Couple<T,Q> : GDecodable, GIdentifiable
where T:GDecodable, Q:GDecodable {
	let gcodableID : UUID? = UUID()
	/* ... */	
}

```

thus obtaining:

```
••• Encoding:
	Model<Couple<Double, Int>> = { value = (((1.0 <-> 3) <-> A) <-> (((1.0 <-> 3) <-> A) <-> A)) }
••• to file:
	'ModelPair2.graph'
= BODY =================================================================================
- REF0001 TYPE0001
	- VAL0002
		- VAL0003
			- VAL0004
				- BIV 1.0
				- BIV 3
			.
			- BIV "A"
		.
		- VAL0005
			- PTS0003
			- BIV "A"
		.
	.
.
========================================================================================
```

### Using class name strings

It is still possible to use strings for class names. Let's go back to the example that used the `MyData` class. You can view the name of the encoded classes:

```swift
let path = FileManager.default.urls(
	for: .documentDirectory, in: .userDomainMask
)[0].appendingPathComponent("MyFile.graph")

let data	= try Data(contentsOf: path)

let dump	= try GraphDecoder().dump(from: data, options: [.showReferenceMap,.showMangledNamesInReferenceMap])

print(dump)
```

The output is:

```
= REFERENCEMAP =========================================================================
TYPE0001:	QualifiedName  = MyGraphCodableApp.MyData
			MangledName    = 17MyGraphCodableApp0A4DataC
			EncodedVersion = 0
========================================================================================
```

You then see that the `MyData` class has been stored with the qualified name `MyGraphCodableApp.MyData` and the mangledName `17MyGraphCodableApp0A4DataC`. Then you can use the GraphDecoder function:

```swift
func setType( _ type:GDecodable.Type, for className:ClassName )
```

to match the encoded name to the class to decode. `ClassName` allows you to choose between the qualified name and the mangledName of the encoded class:

```swift
public enum ClassName : Hashable {
	case mangledName( _:String )
	case qualifiedName( _:String )
}
```

It's best to use the mangledName, as in the following example:

```swift
import Foundation
import GraphCodable

class MyNewData: GCodable, CustomStringConvertible {
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
		let version = try decoder.encodedClassVersion
		
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

let graphDecoder = GraphDecoder()
// set up the dictionary
graphDecoder.setType( MyNewData.self, for: .mangledName("17MyGraphCodableApp0A4DataC") )

let outRoot	= try graphDecoder.decode( MyNewData.self, from: data )
print( outRoot )	// MyNewData(string: 3)

```

This system becomes very difficult to manage especially if generic classes are employed. The type can also be a **value type**.  In the following example we substitute `struct MyNewData:...` for `class MyNewData:...`:

```swift
import Foundation
import GraphCodable

struct MyNewData: GCodable, CustomStringConvertible {
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
	
	init(from decoder: GDecoder) throws {
		let version = try decoder.encodedClassVersion
		
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

let graphDecoder = GraphDecoder()
// set up the dictionary
graphDecoder.setType( MyNewData.self, for: .mangledName("17MyGraphCodableApp0A4DataC") )

let outRoot	= try graphDecoder.decode( MyNewData.self, from: data )
print( outRoot )	// MyNewData(string: 3)
```

## GraphCodable and BinaryIO

### An example

In the following example, `Model` stores a value (pivot) of type `NumericData` and an array of instances of `NumericData`. `Model` employs *keyed* encoding, `NumericData` employs *unkeyed* encoding.

```swift
import Foundation
import GraphCodable
import simd

struct NumericData {
	let	vector : SIMD3<Double>
	let	matrix : simd_double3x3

	init(vector: SIMD3<Double>, matrix: simd_double3x3) {
		self.vector = vector
		self.matrix = matrix
	}
}

extension NumericData : GCodable {
	init(from decoder: GDecoder) throws {
		self.vector = try decoder.decode()
		self.matrix = try decoder.decode()
	}
	
	func encode(to encoder: GEncoder) throws {
		try encoder.encode(vector)
		try encoder.encode(matrix)
	}
}

struct Model {
	var pivot : NumericData
	var array : [NumericData]
	
	init( count:Int, range: ClosedRange<Double> ) {
		precondition( count > 0)
		let array = (0..<count).map {
			_ in NumericData(
				vector: SIMD3<Double>.random(in: range),
				matrix: simd_double3x3.init(diagonal: SIMD3<Double>.random(in: range)))
		}
		self.pivot	= array.randomElement()!
		self.array	= array
	}
}

extension Model : GCodable {
	private enum Key : String { case pivot,array }

	init(from decoder: GDecoder) throws {
		self.pivot	= try decoder.decode(for: Key.pivot)
		self.array	= try decoder.decode(for: Key.array)
	}
	
	func encode(to encoder: GEncoder) throws {
		try encoder.encode(pivot, for: Key.pivot)
		try encoder.encode(array, for: Key.array)
	}
}

let largeCount	= 3
let inRoot		= Model( count: largeCount, range: -1.0...1.0 )
let encoder		= GraphEncoder()
let dump		= try encoder.dump( inRoot, options:[.readable,.showHelp] )
print( dump )
```

The `.showHelp` option in tha penultimate line prints a little help in addition. So the program prints:

```
= HELP =================================================================================
Codes:
	VAL<objID?>   = GCodable value tipe
	REF<objID?>   = GCodable reference type
	BIV<objID?>   = BinaryIO value type
	BIR<objID?>   = BinaryIO reference type
	NIL<objID?>   = nil (Optional.none) VAL,REF,BIV,BIR
	PTS<objID>    = Strong pointer to VAL,REF,BIV,BIR
	PTC<objID>    = Conditional pointer to VAL,REF,BIV,BIR

	• VAL, REF are followed by their internal fields ending with '.'
	• The '+ key/KEY<keyID>' symbol precedes keyed fields.
	• The '-' symbol precedes unkeyed fields.
	• objID is an unique integer code associated with REF, VAL, BIV,
	  BIR, NIL only if they have identities. The PTC and PTS objID
	  code is the same as the REF, VAL, BIV, BIR, NIL the pointer
	  points to.

Other codes:
	TYPE<typeID>  = uniquely identifies the class of a reference
	                (REF, BIR). Depending on the options selected,
	                the qualified name of the class may be displayed
	                alternatively.
	KEY<keyID>    = uniquely identifies the key used in keyed coding.
				    Only used by the VAL and REF fields.
= BODY =================================================================================
- VAL
	+ "pivot": VAL
		- BIV SIMD3<Double>(-0.2725589512361022, 0.7122552082341422, 0.0625146…
		- BIV simd_double3x3([[0.16157689531179997, 0.0, 0.0], [0.0, 0.3656748…
	.
	+ "array": VAL
		- VAL
			- BIV SIMD3<Double>(0.9414066953372839, 0.24043265597465324, -0.115703…
			- BIV simd_double3x3([[-0.44418940482243396, 0.0, 0.0], [0.0, -0.55923…
		.
		- VAL
			- BIV SIMD3<Double>(-0.2725589512361022, 0.7122552082341422, 0.0625146…
			- BIV simd_double3x3([[0.16157689531179997, 0.0, 0.0], [0.0, 0.3656748…
		.
		- VAL
			- BIV SIMD3<Double>(0.6624169536017868, 0.2376033765091996, -0.0233138…
			- BIV simd_double3x3([[0.9841120917825208, 0.0, 0.0], [0.0, -0.7105751…
		.
	.
.
========================================================================================
```

The structure of the encoded data is easy to recognize. But a question arises: `SIMD3<Double>` and `simd_double3x3` are respectively vectors of 3 double values and matrices of 3x3 double values. How come their structure is not visible but they appear to be stored as <u>single data unit</u> of type `BIV` = *BinaryIO value type*? This is because GraphCodable uses the BinaryIO package to store "simple" types, and `SIMD3<Double>` and `simd_double3x3` are considered "simple" types, as are single integers or float values. The GraphCodable encoded structure is in fact a graph whose terminal elements are **always** "simple" types encoded by BinaryIO. Storing a matrix of 3x3 elements directly with BinaryIO is much faster than storing these 9 elements with GraphCodable.

This mechanism is accessible to the user: let's see how.

### The `BCodable` protocol

First, we can see that in the proposed example `NumericData`, unlike `Model`, seems to be the ideal candidate to be encoded directly with BinaryIO: it's a trivial structure. The protocol to be used is `BCodable`, defined as `typealias BCodable	= BDecodable & BEncodable` in the BinaryIO package:

```swift
public protocol BEncodable {
	func write( to encoder: inout BinaryIOEncoder ) throws
}

public protocol BDecodable {
	init( from decoder: inout BinaryIODecoder ) throws
}

public typealias BCodable	= BDecodable & BEncodable
```

You can see how with BinaryIO the type that adopt the `BCodable` protocol is stored by "writing" its fields to a `BEncoder`and instantiated by "reading" its fields **in the same order** from a `BDecoder`:

```swift
extension NumericData : BCodable {
	init(from decoder: inout some BDecoder) throws {
		self.vector = try decoder.decode()
		self.matrix = try decoder.decode()
	}
	
	func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode(vector)
		try encoder.encode(matrix)
	}
}
```

BinaryIO is a fast low-level package and no keys are available. Also note that  `BDecoder` and  `BEncoder` are protocols for value types.

### The `GBinaryCodable` protocol

Make `NumericData` adopt the `BCodable` protocol doesn't change the output of our program though. In order for GraphCodable to realize that `NumericData` can be stored directly by BinayIO it is necessary to adopt the protocol `GBinaryCodable` defined in GraphCodable package as:

```swift
public protocol	GBinaryEncodable : BEncodable, GEncodable {}
public protocol	GBinaryDecodable : BDecodable, GDecodable {}
public typealias GBinaryCodable = GBinaryEncodable & GBinaryDecodable

extension GBinaryEncodable {
	public func encode(to encoder: GEncoder) throws	{
		throw GraphCodableError.internalInconsistency(
			Self.self, GraphCodableError.Context(
				debugDescription: "Unreachable code."
			)
		)
	}
}
extension GBinaryDecodable {
	public init(from decoder: GDecoder) throws {
		throw GraphCodableError.internalInconsistency(
			Self.self, GraphCodableError.Context(
				debugDescription: "Unreachable code."
			)
		)
	}
}
```

So let's change the extension of `NumericData` to:

```swift
extension NumericData : GBinaryCodable {
	init(from decoder: inout BinaryIODecoder) throws {
		self.vector = try SIMD3<Double>( from:&decoder )
		self.matrix = try simd_double3x3( from:&decoder )
	}
	
	func write(to encoder: inout BinaryIOEncoder) throws {
		try vector.write(to: &encoder)
		try matrix.write(to: &encoder)
	}
}
```

We can also remove the extension of `NumericData` which adopts the `GCodable` protocol, because `GBinaryCodable` adopts itself `GCodable` and implements the functions `encode(to: GEncoder) throws` and `init(from: GDecoder) throws` as "unreachable".

Now the program prints:

```
= BODY =================================================================================
- VAL
	+ "pivot": BIV NumericData(vector: SIMD3<Double>(0.33286539114840163, 0.0492638…
	+ "array": VAL
		- BIV NumericData(vector: SIMD3<Double>(-0.11284242645824238, 0.563343…
		- BIV NumericData(vector: SIMD3<Double>(0.33286539114840163, 0.0492638…
		- BIV NumericData(vector: SIMD3<Double>(0.879366714506493, 0.640246215…
	.
.
========================================================================================
```

You see how each instance of NumericData is now encoded as a <u>single data unit</u>.

Thus, to use BinaryIO it is sufficient to adopt the `GBinaryCodable` protocol <u>instead</u> of `GCodable` protocol.

### The `GPackCodable` protocol

But that's not all: just add one more line of code:

```swift
extension NumericData : GPackable {}
```

Now the program prints:

```
= BODY =================================================================================
- VAL
	+ "pivot": BIV NumericData(vector: SIMD3<Double>(0.045236581447066104, 0.951692…
	+ "array": BIV [MyGraphCodableApp.NumericData(vector: SIMD3<Double>(0.735150985…
.
========================================================================================
```

You can see how now the entire array has been stored as a <u>single data unit</u>!

The same result would have been obtained by adopting the `GPackCodable` protocol instead of `GBinaryEncodable`:

```swift
extension NumericData : GPackCodable /* GBinaryCodable */ {
	init(from decoder: inout some BDecoder) throws {
		self.vector = try decoder.decode()
		self.matrix = try decoder.decode()
	}
	
	func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode(vector)
		try encoder.encode(matrix)
	}
}
```

In this way it is possible to encode and decode large arrays (or other containers) very quickly when they contain "simple" elements, where "simple" elements mean elements that adopt the `GPackCodable` protocol.

Here is how the `GPackCodable` protocol is defined in GraphCodable:

```swift
public protocol GPackable {}

public typealias GPackEncodable	= GBinaryEncodable & GPackable
public typealias GPackDecodable	= GBinaryDecodable & GPackable
public typealias GPackCodable	= GPackEncodable & GPackDecodable
```

Just to get an idea of the difference, these are the cumulative encode + decode times with `largeCount = 100000`:

```
iMac i7 2017:
   NumericData adopt GCodable protocol:         713.36ms (σ/avg = 2.1%) size = 10200229 bytes
   NumericData adopt GBinaryCodable protocol:   330.02ms (σ/avg = 1.9%) size =  9800225 bytes
   NumericData adopt GPackCodable protocol:      63.81ms (σ/avg = 7.6%) size =  9600236 bytes
Mac Studio Ultra 2022:
   NumericData adopt GCodable protocol:         355.69ms (σ/avg = 2.0%) size = 10200229 bytes
   NumericData adopt GBinaryCodable protocol:   160.20ms (σ/avg = 2.7%) size =  9800225 bytes
   NumericData adopt GPackCodable protocol:      37.71ms (σ/avg = 3.6%) size =  9600236 bytes
```

### Switch from `GCodable` to `GBinary/PackCodable` and vice versa

If some archives where `NumericData` adopts `GCodable` exist and you want to keep the ability to read them when adopting `GBinaryCodable` or `GPackCodable` protocol, just keep the `init` method of `GDecodable` and the program will keep the ability to read the old archives which employ  `GCodable`:

```swift
extension NumericData : GDecodable {
	init(from decoder: GDecoder) throws {
		self.vector = try decoder.decode()
		self.matrix = try decoder.decode()
	}
}

extension NumericData : GPackCodable /* or GBinaryCodable */ {
	init(from decoder: inout some BDecoder) throws {
		self.vector = try decoder.decode()
		self.matrix = try decoder.decode()
	}
	
	func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode(vector)
		try encoder.encode(matrix)
	}
}
```

Conversely, if some archives in which `NumericData` adopts `GBinaryCodable` or `GPackCodable` exist and you want to keep the ability to read them when adopting only `GCodable` protocol, just keep the init method of `GBinaryDecodable` and the program will keep the ability to read old archives which employ  `GBinaryCodable` or `GPackCodable`:

```swift
extension Model : GCodable {
	private enum Key : String { case pivot,array }

	init(from decoder: GDecoder) throws {
		self.pivot	= try decoder.decode(for: Key.pivot)
		self.array	= try decoder.decode(for: Key.array)
	}
	
	func encode(to encoder: GEncoder) throws {
		try encoder.encode(pivot, for: Key.pivot)
		try encoder.encode(array, for: Key.array)
	}
}

extension NumericData : GBinaryDecodable {
	init(from decoder: inout some BDecoder) throws {
		self.vector = try decoder.decode()
		self.matrix = try decoder.decode()
	}
}
```

### UserInfo dictionary and other informations

The `userInfo` dictionary set in the `GraphEncoder` is accessible to types adopting the `GBinaryEncodable` protocol with:

```swift
	func write(to encoder: inout some BEncoder) throws {
		let encoderView	= try encoder.encoderView
		let userInfo	= encoderView.userInfo
		/* ... */
	}

```

The `userInfo` dictionary set in the `GraphDecoder` is accessible to types adopting the `GBinaryDecodable` protocol with:

```swift
	init(from decoder: inout some BDecoder) throws {
		let decoderView	= try decoder.decoderView
		let userInfo = decoderView.userInfo
		/* ... */
	}

```

When dearchiving `GBinaryDecodable` **reference** types, you may also need access to `encodedClassVersion` and `replacedClass`:

```swift
	init(from decoder: inout BinaryIODecoder) throws {
		let decoderView					= try decoder.decoderView
		let encodedClassVersion	= try decoderView.encodedClassVersion
		let replacedClass				= try decoderView.replacedClass
	}

```

`encodedClassVersion` and `replacedClass` have no meaning for **value** types and in general for `GPackDecodable` types.

### BinaryIO versioning

What to do if during the evolution of the program it becomes necessary to modify a type that uses BinaryIO?

BinaryIO uses two `UInt32` values to globally specify a version:

- an internal value (`binaryIOVersion`) to handle any changes to the package's predefined types;
- a second value (`userVersion`) to allow the user to manage any changes of its BinaryIO types. 

**Note**: `userVersion` is shared with GraphCodable. 

Starting from the previous example we add a flag of tipe `Flag` in `NumericData` and define two versions of BinaryIO `userVersion` in the `MyFileVersion` enum: the initial (`.initial`) one, which does not include it, and the subsequent one (`.newNumericData`) which does include it. During decoding the `NumericData` type must be able to instantiate itself according to the encoded version `encodedUserVersion` which is the encoded `userVersion`. And maybe we also want to provide in the function `write(to: inout BinaryIOEncoder) throws` the ability to continue using the initial version for archiving as well.

Here's how you can do it:

```swift
import Foundation
import GraphCodable
import simd

enum MyFileVersion : UInt32 {
	case initial, newNumericData
}

struct NumericData {
	enum Flag : UInt8, BCodable { case even, odd }
	
	let	vector	: SIMD3<Double>
	let	matrix	: simd_double3x3
	let flag	: Flag	// new field
	
	init( vector: SIMD3<Double>, matrix: simd_double3x3, flag:Flag ) {
		self.vector = vector
		self.matrix = matrix
		self.flag	= flag
	}
}

extension NumericData : GPackCodable {
	//	her we implement the ability to read all versions:
	init(from decoder: inout some BDecoder) throws {
		self.vector = try decoder.decode()
		self.matrix = try decoder.decode()

		// let's take the encoded version:
		switch decoder.encodedUserVersion {
			case MyFileVersion.newNumericData.rawValue...:
				//	it is at least the 'newNumericData' version
				self.flag = try Flag( from:&decoder )
			default:
				//	the version is less than .newNumericData
				self.flag = .even
		}
	}
	
	//	here we implement the possibility to write also
	//	in previous versions
	func encode(to encoder: inout some GraphCodable.BEncoder) throws {
		try encoder.encode( vector )
		try encoder.encode( matrix )

		//	we encode according to the requested version:
		switch encoder.userVersion {
			case MyFileVersion.newNumericData.rawValue...:
				//	it is at least the .newNumericData version
				try encoder.encode( flag )
			default:
				//	the version is less than .newNumericData
				break
		}
	}
}

struct Model {
	var pivot : NumericData
	var array : [NumericData]
	
	init( count:Int, range: ClosedRange<Double> ) {
		precondition( count > 0)
		let array = (0..<count).map {
			_ in NumericData(
				vector	: SIMD3<Double>.random(in: range),
				matrix	: simd_double3x3.init(diagonal: SIMD3<Double>.random(in: range)),
				flag	: count.isMultiple(of: 2) ? .even : .odd
			)
		}
		self.pivot	= array.randomElement()!
		self.array	= array
	}
}

extension Model : GCodable {
	private enum Key : String { case pivot,array }
	
	init(from decoder: GDecoder) throws {
		self.pivot	= try decoder.decode(for: Key.pivot)
		self.array	= try decoder.decode(for: Key.array)
	}
	
	func encode(to encoder: GEncoder) throws {
		try encoder.encode(pivot, for: Key.pivot)
		try encoder.encode(array, for: Key.array)
	}
}
```

With this other extension we directly give `Model` the possibility of encoding (in a `MyFileVersion` of your choice) and decoding itself from a `URL`:

```swift
extension Model {
	func write( fileVersion:MyFileVersion, path:URL, dump:Bool ) throws {
		let encoder	= GraphEncoder( userVersion: fileVersion.rawValue )
		if dump {	// -- just to show what is being encoded
			print( "Encoding and writing version: '\(fileVersion)(\(fileVersion.rawValue))':")
			print( try encoder.dump( self, options:[.readable,.showHeader] ) )
		}
		let data	= try encoder.encode( self ) as Data
		try data.write( to: path )
	}
	
	static func read( path:URL, dump:Bool ) throws -> Model {
		let data	= try Data.init(contentsOf: path)
		let decoder	= GraphDecoder()
		if dump {	// -- just to show what will be decoded
			print( "Reading and decoding:")
			print( try decoder.dump( from: data, options:[.readable,.showHeader] ) )
		}
		// -----------------------------------
		return try decoder.decode( Model.self, from: data )
	}
}
```

Note how the BinaryIO version must be specified in the GraphEncoder init method:

```swift
let encoder	= GraphEncoder( userVersion: fileVersion.rawValue )
```

We also put the `dump` option to print the archive contents when reading and writing. In particular, in addition to the structure (BODY) of the archive, we also choose to print the header as well using the `.showHeader` flag.

And so we can test the program by trying to encode and decode the file in different versions:

```swift
let fileURL	 = FileManager.default.urls(
	for: .documentDirectory, in: .userDomainMask
   )[0].appendingPathComponent("NumericModel.graph")


let largeCount	= 3
var model 		= Model( count: largeCount, range: -1.0...1.0 )

try model.write( fileVersion: .initial, path: fileURL, dump:true )

model = try Model.read( path:fileURL, dump:true )

try model.write( fileVersion: .newNumericData, path: fileURL, dump:true )

model = try Model.read( path:fileURL, dump:true )
```

The program prints:

```
Encoding and writing version: 'initial(0)':
= HEADER ===============================================================================
- fileType            =       'gcod' {4 bytes}
- userVersion         =            0 {4 bytes}
- gcodableVersion     =            4 {4 bytes}
- binaryIOVersion     =            0 {4 bytes}
- flags               =            1 {2 bytes}
= BODY =================================================================================
- VAL
	+ "pivot": BIV NumericData(vector: SIMD3<Double>(0.986647922492967, 0.471000163…
	+ "array": BIV [MyGraphCodableApp.NumericData(vector: SIMD3<Double>(0.374499004…
.
========================================================================================

Reading and decoding:
= HEADER ===============================================================================
- fileType            =       'gcod' {4 bytes}
- userVersion         =            0 {4 bytes}
- gcodableVersion     =            4 {4 bytes}
- binaryIOVersion     =            0 {4 bytes}
- flags               =            1 {2 bytes}
- data size           =          521 bytes
= BODY =================================================================================
- VAL
	+ "pivot": BIV { 96 bytes }
	+ "array": BIV { 296 bytes }
.
========================================================================================

Encoding and writing version: 'newNumericData(1)':
= HEADER ===============================================================================
- fileType            =       'gcod' {4 bytes}
- userVersion         =            1 {4 bytes}
- gcodableVersion     =            4 {4 bytes}
- binaryIOVersion     =            0 {4 bytes}
- flags               =            1 {2 bytes}
= BODY =================================================================================
- VAL
	+ "pivot": BIV NumericData(vector: SIMD3<Double>(0.986647922492967, 0.471000163…
	+ "array": BIV [MyGraphCodableApp.NumericData(vector: SIMD3<Double>(0.374499004…
.
========================================================================================

Reading and decoding:
= HEADER ===============================================================================
- fileType            =       'gcod' {4 bytes}
- userVersion         =            1 {4 bytes}
- gcodableVersion     =            4 {4 bytes}
- binaryIOVersion     =            0 {4 bytes}
- flags               =            1 {2 bytes}
- data size           =          525 bytes
= BODY =================================================================================
- VAL
	+ "pivot": BIV { 97 bytes }
	+ "array": BIV { 299 bytes }
.
========================================================================================
```

You can see how  **`userVersion`** both in reading and in writing is indicated in the header. Also note that during encoding the **value** of the types adopting the `BEncodable` protocol is displayed, while during encoding the size in bytes of the types adopting the `BDecodable` protocol is displayed because the values have not been instantiated yet.

Instead, `gcodableVersion` and `binaryIOVersion` are versions for internal use of the two packages and the user cannot use them.

Finally, it is **important** to note that the **userVersion** of BinaryIO is unique and global for the entire archive and shared with GraphCodable. It follows that whenever any BinaryIO type (or any GraphCodable type using it) being encoded changes  it is necessary to increment **`userVersion`**.

### GraphCodable and BinaryIO for some system types

To further clarify how GraphCodable and BinaryIO interact, let's see how some system types adopt their protocols.

#### Foundation type `CGSize`

**BinaryIO package**:

```swift
extension CGSize : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( width )
		try encoder.encode( height )
	}
}

extension CGSize : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		let width	= try decoder.decode() as CGFloat
		let height	= try decoder.decode() as CGFloat
		self.init(width: width, height: height)
	}
}
```

**GraphCodable package**: GraphCodable always uses BinaryIO to encode/decode `CGSize`.

```swift
extension CGSize 			: GBinaryEncodable {}
extension CGSize 			: GBinaryDecodable {}
extension CGSize 			: GPackable {}
```

#### Swift standard library type `String`

**BinaryIO package**:

```swift
extension String	: BEncodable {
  public func encode(to encoder: inout some BEncoder) throws {
    try encoder.encodeString( self )
  }
}

extension String	: BDecodable {
  public init(from decoder: inout some BDecoder) throws {
    self = try decoder.decodeString()
  }
}
```

**GraphCodable package**: GraphCodable always uses BinaryIO to encode/decode `String`.

```swift
extension String : GBinaryEncodable {}
extension String : GBinaryDecodable {}
```

Note the difference with `CGSize`: `CGSize` adopt the `GPackCodable` protocol because it doesn't make sense that they can use identities, `String` adopt the `GBinaryCodable` protocol because they could use identities. This implies that `CGSize` arrays are encoded as a single data unit while `String` arrays are not.

#### Swift standard library type `Array`

Let's see how GraphCodable implements these mechanisms for swift containers, taking into consideration the case of `Array` (the others are completely analogous).

**BinaryIO package**: `Array` adopts the `BCodable` protocols: if the elements are `BCodable`, Array is `BCodable` so BinaryIO can encode ed decode it.

```swift
extension Array : BEncodable where Element : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( count )
		for element in self {
			try encoder.encode( element )
		}
	}
}

extension Array : BDecodable where Element : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self.init()
		let count = try decoder.decode() as Int
		self.reserveCapacity( count )
		for _ in 0..<count {
			self.append( try decoder.decode() )
		}
	}
}
```

**GraphCodable package**: `Array` adopts the `GCodable` protocols: if the elements are `GCodable`, Array is `GCodable` so GraphCodable can encode ed decode it.

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

This additional line of code allows array to encode its elements with BinaryIO when they adopt `PackCodable`:

```swift
extension Array : GBinaryEncodable where Element : GPackEncodable {}
extension Array : GBinaryDecodable where Element : GPackDecodable {}
```

#### Foundation type `PersonNameComponents`

**BinaryIO package**:

```swift
extension PersonNameComponents : BEncodable {
	public func encode(to encoder: inout some BEncoder) throws {
		try encoder.encode( namePrefix )
		try encoder.encode( givenName )
		try encoder.encode( middleName )
		try encoder.encode( familyName )
		try encoder.encode( nameSuffix )
		try encoder.encode( nickname )
	}
}
extension PersonNameComponents : BDecodable {
	public init(from decoder: inout some BDecoder) throws {
		self.init()
		
		namePrefix	= try decoder.decode()
		givenName	= try decoder.decode()
		middleName	= try decoder.decode()
		familyName	= try decoder.decode()
		nameSuffix	= try decoder.decode()
		nickname	= try decoder.decode()
	}
}
```

**GraphCodable package**: In this case GraphCodable does not use BinaryIO but stores `PersonNameComponents` using keys with `GCodable` methods. This means that the BinaryIO implementation in `PersonNameComponents` is only accessible by extracting the BinaryIO package and using it without the GraphCodable.

```swift
extension PersonNameComponents {
	private enum Key : String {
		case namePrefix
		case givenName
		case middleName
		case familyName
		case nameSuffix
		case nickname
	}
}

extension PersonNameComponents : GDecodable {
	public init(from decoder: GDecoder) throws {
		self.init()
		
		namePrefix = try decoder.decodeIfPresent( for: Key.namePrefix )
		givenName  = try decoder.decodeIfPresent( for: Key.givenName )
		middleName = try decoder.decodeIfPresent( for: Key.middleName )
		familyName = try decoder.decodeIfPresent( for: Key.familyName )
		nameSuffix = try decoder.decodeIfPresent( for: Key.nameSuffix )
		nickname   = try decoder.decodeIfPresent( for: Key.nickname )
	}
}

extension PersonNameComponents : GEncodable {
	public func encode(to encoder: GEncoder) throws {
		try encoder.encodeIfPresent( namePrefix, for: Key.namePrefix)
		try encoder.encodeIfPresent( givenName, for: Key.givenName)
		try encoder.encodeIfPresent( middleName, for: Key.middleName)
		try encoder.encodeIfPresent( familyName, for: Key.familyName)
		try encoder.encodeIfPresent( nameSuffix, for: Key.nameSuffix)
		try encoder.encodeIfPresent( nickname, 	for: Key.nickname)
	}
}
```

### Final Advice

A type that adopts the `GBinaryCodable` protocol:

- gain faster encoding and decoding speed;
- if it is a value type, it can have an identity;
- if it is a reference type, it maintains identity, inheritance, can be versioned and can be obsoleted;
- but its fields, being encoded with BinaryIO, cannot use keys, do not benefit from inheritance, identity, cannot be versioned, and cannot be obsoleted.

A type that adopts the `GPackCodable` protocol:

- gain even faster encoding and decoding speed when it is an element of suitably prepared containers;
- loses **itself** (as its fileds) identity, inheritance, cannot be versioned, and cannot be obsoleted because encoded directly by BinaryIO bypassing GraphCodable features;

**<u>IMPORTANT!</u>** It is recommended to use BinaryIO only if strictly necessary (encoding and decoding too slow), following these rules:

- a **value** type should adopt the `GPackCodable` protocol only if it is trivial, that is, if `_isPOD( type )` returns `true`. Reference types are not trivial.
- a **value** or **reference** type can adopt protocol  `GBinaryCodable` if it is a user-defined container of types that adopt protocol `GPackCodable` or if its fields adopt protocol `GBinaryCodable` and do not need the functions of GraphCodable (identity, inheritance, etc…).

## BinaryIO as standalone package

**To do ...**
