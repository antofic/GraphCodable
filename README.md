# GraphCodable

Firstly, I apologize for my poor English. I hope the content remains understandable.

GraphCodable is an **experimental** Swift encode/decode package (similar to Codable at interface level) that does not treat reference types as second-class citizens.
In other words, GraphCodable tries to offer functionalities similar to those of NSCoder within the "limits" of a language (Swift) less dynamic than Objective C.

## Features
GraphCodable:
- saves all type information;
- supports reference types inheritance;
- never duplicates the same object (as defined by ObjectIdentifier);
- in other words, it preserves the structure and the types of your model unaltered during encoding and decoding;
- is fully type checked at compile time (*);
- supports keyed and unkeyed coding, also usable simultaneously;
- supports conditional encoding;
- implements an userInfo dictionary;
- implements a type version system;
- implements a type substitution system during decode;

Check code examples in the [User Guide](/Docs/UserGuide.md). Check the tests section, too.

(*) Fully type checking at compile time is mutually exclusive with the ability to encode/decode heterogeneous collections (i.e. `[Any]`) containing 'codable' elements. I chose to support the first feature while giving up the second.

## Other information
GraphCodable natively supports the following types: Int, Int8, Int16, Int32, Int64, UInt, UInt8, UInt16, UInt32, UInt64, Float, Double, String, Data
GraphCodable make Optional, Array, Set, Dictionary codable if they hold codable types. OptionSet and Enum with rawValue of native type (except Data) are codable, too.

GraphCodable can encode and decode any 'ARC compatible' Swift object graph, regardless of how complex it is, reconstructing its original structure with its original types without duplicating objects.
Weak variables used in the object graph in order to avoid strong memory cycles in ARC require [special treatment](/Docs/UserGuide.md##Directed-cyclic-graphs) during initialization within the `init (from: GDecoder)` method.
One limitation exists: you cannot put a weak variable that must employ the above mechanism inside a value type but only inside a reference type.

[This table](/Docs/CodingRules.md) summarizes the methods to be used depending on the type of variable to be encoded and decoded.

Since, unlike Obiective-C, it is impossible in Swift to construct an object at runtime starting from its type name string (more generally, Swift does not allow you to serialize and deserialize a `type: Any.Type`), it is necessary to "register" (that is, associate the "type" to its "type name") in advance all types which can be decoded. A singleton object (`GTypesRepository.shared`) is used for this, which must be initialized 'very soon' in your program. GraphCodable offers various systems to facilitate this task. First, all types involved in archiving are automatically registered by the encoder to make debugging easier. Second, the decoder has a function (help) that generates a string containing the 'register function' that must be included in the code to decode a particular data file. Third, the same string, relative to all the types registered by all the session encodes, can be generated by the 'help' register function.

GraphCodable does not use a public format for the data (such as JSON or others) but stores the data in a [private binary format](/Docs/DataFormat.md) defined by the package itself. Having to preserve information about the types, GraphCodable creates larger data in bytes than those generated by Codable encoders. Despite this, the time required for encoding and decoding is generally comparable if not faster.

GraphCodable is written entirely in Swift. The use of 'unsafe' methods is limited to a handful of functions related to reading and writing data in binary format (see BinaryIO). Everything else is 'safe'.

## Limitations
The package limitations related to Swift features are described in the [last paragraph](/Docs/UserGuide.md#Final-thoughts) of the user guide. I recommend reading it after reading the entire [User Guide](/Docs/UserGuide.md) and trying code examples.

## Other documents
- [User Guide](/Docs/UserGuide.md)
- [Coding Rules](/Docs/CodingRules.md)
- [Data Format](/Docs/DataFormat.md)

## Simple interface comparison to Swift Codable
In GraphCodable:
- GEncodable, GDecodable and GCodable have the same roles as Encodable, Decodable and Codable
- GEncoder, GDecoder have the same roles as Encoder, Decoder
- GraphEncoder has the same role as JSONEncoder, PropertyListEncoder
- GraphDecoder has the same role as JSONDecoder, PropertyListDecoder

GraphCodable does not use containers.

## Supported technologies

- Swift 5.3

## License

GraphCodable is released under the MIT license. [See LICENSE](/LICENSE.txt) for more details.


