#  Data Format
GraphEncoder encode data in binary format. You can get a readable representation of the data in a string with the `dump()` function.

## Readable output of the encoded data
Let's consider this example:
```swift
import Foundation
import GraphCodable

GTypesRepository.initialize()

struct AStruct : Equatable, GCodable {
	var array	= [1,2,3]
	var dict	= ["4":4,"5":5]
	
	init() {}
	
	private enum Key : String {
		case array, dict
	}
	
	func encode(to encoder: GEncoder) throws {
		try encoder.encode( array, for: Key.array )
		try encoder.encode( dict, for: Key.dict )
	}
	
	init(from decoder: GDecoder) throws {
		array	= try decoder.decode(for: Key.array )
		dict	= try decoder.decode(for: Key.dict )
	}
}

class AClass : GCodable {
	var astruct	= AStruct()
	var aclass	: AClass?
	
	private enum Key : String {
		case astruct, aclass
	}
	
	init() {}
	
	func encode(to encoder: GEncoder) throws {
		try encoder.encode( astruct, for: Key.astruct )
		// note:
		try encoder.encodeConditional( aclass,  for: Key.aclass )
	}
	
	required init(from decoder: GDecoder) throws {
		astruct	= try decoder.decode(for: Key.astruct )
		aclass	= try decoder.decode(for: Key.aclass )
	}
}

let a = AClass()
let b = AClass()

//	we store a in b.aclass while a.aclass remains nil
b.aclass	= a

let	inRoot = [b, b, b, b, a]

print( try GraphEncoder().dump( inRoot ) )
```
The result:

```
== HEADER ========================================================
^ Filetype = gcodable V0, * = GCodable, U1 = 0, U2 = 0
== GRAPH =========================================================
- STRUCT Swift.Array<*.AClass>
	- CLASS *.AClass Obj1000
		+ "astruct": STRUCT *.AStruct
			+ "array": STRUCT Swift.Array<Swift.Int>
				- Swift.Int 1
				- Swift.Int 2
				- Swift.Int 3
			.
			+ "dict": STRUCT Swift.Dictionary<Swift.String,Swift.Int>
				- Swift.String "4"
				- Swift.Int 4
				- Swift.String "5"
				- Swift.Int 5
			.
		.
		+ "aclass": POINTER? Obj1001
	.
	- POINTER Obj1000
	- POINTER Obj1000
	- POINTER Obj1000
	- CLASS *.AClass Obj1001
		+ "astruct": STRUCT *.AStruct
			+ "array": STRUCT Swift.Array<Swift.Int>
				- Swift.Int 1
				- Swift.Int 2
				- Swift.Int 3
			.
			+ "dict": STRUCT Swift.Dictionary<Swift.String,Swift.Int>
				- Swift.String "5"
				- Swift.Int 5
				- Swift.String "4"
				- Swift.Int 4
			.
		.
		+ "aclass": nil
	.
.
==================================================================
```
 You can see:

The **HEADER**, with the file format name (gcodable), its version, a the placeholder ``* = MainModuleName`` and some unused fields.
The main module name purposely has no effect when unarchiving and for this reason is replaced by an asterisk in the following type definitions.
This way you can open the same file from an app with a different main module name.
GrapCodable does not currently allow access to the data contained in the header.

The **GRAPH** that contains the structured data, organized in:
- *Sequences*: a list of items preceded by the **-** symbol.
- *Dictionaries*: a list of items (in the form "key": value) preceded by the **+** symbol.
Both lists end when the symbol **.** is encountered.
The root is always the only item of the first sequence.

Rows by rows:
-	``STRUCT Swift.Array<*.AClass>``, which is a value type (``STRUCT``), is the root.
-	It contains 5 elements corresponding to ``[b, b, b, b, a]``:
	-	The first element ``CLASS *.AClass Obj1000`` is a reference (``CLASS``) type.
		GraphCodable assigns a unique numeric ``ID (ObjXXXX)`` to each object it encounters.
		This object in turn contains a structure corresponding to the key 'astruct' and an object corresponding to the key 'aclass'
		-	First, you see the complete definition of the struct ``*.AStruct``, with its array and its dictionary. They contain native types.
			-	GraphCodable treats the following types as "native" (knows how to save them):
				-	**Int**, **Int8**, **Int16**, **Int32**, **Int64**, **UInt**, **UInt8**, **UInt16**, **UInt32**, **UInt64**
				-	**Float**, **Double**
				-	**String**, **Data**
			-	In addition, GraphCodable conforms the following types to GCodable:
				-	**Array**, **Dictionary**, **Set**, **Optional**, **OptionSet**
				-	 any **enum** whose rawValue is a native type, except **Data**
		- 	Then you see: ``"aclass": POINTER? Obj1001`` This is because aclass has been conditionally archived.
			The encoder assigns it an attempt ``ID (POINTER?)`` and waits for it to be stored unconditionally if it happens.
	-	The second, third and fourth element of the array are always **b**, which has already been stored with ``ID=Obj1000``.
		Therefore the encoder only stores the ``ID``, which this time is certain (``POINTER``without question mark).
	-	The fifth element is ``a`` which was not archived previously and is therefore archived now.

*As an exercise*: see what happens when you delete ``a`` from the array.

*As an exercise*: try to see what happens by encoding ``"aclass"`` *not-conditionally*.

## Binary like output of the encoded data

GraphCodable employs some tricks to reduce the size of the data to be stored.
For example, types and keys are saved only once in special tables and are addressed to them through a unique ID.
By using the '.binaryLike' option you can see the data saved in a format that more closely resembles the binary format actually used.

`print( try GraphEncoder().dump( inRoot, options: .binaryLike ) )`

```
== HEADER ========================================================
^ Filetype = gcodable V0, * = GCodable, U1 = 0, U2 = 0
== TYPEMAP =======================================================
# Type101: V0 *.AClass
# Type104: V0 Swift.Int
# Type106: V0 Swift.String
# Type105: V0 Swift.Dictionary<Swift.String,Swift.Int>
# Type103: V0 Swift.Array<Swift.Int>
# Type102: V0 *.AStruct
# Type100: V0 Swift.Array<*.AClass>
== GRAPH =========================================================
- STRUCT Type100
	- CLASS Type101 Obj1000
		+ Key100: STRUCT Type102
			+ Key101: STRUCT Type103
				- Type104 1
				- Type104 2
				- Type104 3
			.
			+ Key102: STRUCT Type105
				- Type106 "4"
				- Type104 4
				- Type106 "5"
				- Type104 5
			.
		.
		+ Key103: POINTER? Obj1001
	.
	- POINTER Obj1000
	- POINTER Obj1000
	- POINTER Obj1000
	- CLASS Type101 Obj1001
		+ Key100: STRUCT Type102
			+ Key101: STRUCT Type103
				- Type104 1
				- Type104 2
				- Type104 3
			.
			+ Key102: STRUCT Type105
				- Type106 "5"
				- Type104 5
				- Type106 "4"
				- Type104 4
			.
		.
		+ Key103: nil
	.
.
== KEYMAP ========================================================
# Key103: "aclass"
# Key102: "dict"
# Key100: "astruct"
# Key101: "array"
==================================================================
```
We see how the **GRAPH** section uses IDs for types and keys, while the type and key strings are stored once in only two tables, one (**TYPEMAP**) preceding the **GRAPH** section and another (**KEYMAP**) following it. The version of the type (**V...**) is also stored in the type table.


