# GraphCodable

Firstly, I apologize for my poor English. I hope the content remains understandable.

GraphCodable is a Swift encode/decode package (similar to Codable at interface level) that does not treat reference types as second-class citizens.
 
With version **0.3.0** and later versions, the package has been completely revised. It now relies on `_mangledTypeName(...)` (when available) and `NSStringFromClass(...)` to generate the "type name" and on `_typeByName(...)` and `NSClassFromString(...)` to retrieve the class type from it.

## Features
GraphCodable:
- encodes type information (for reference types);
- supports reference inheritance;
- never duplicates the same object (as defined by ObjectIdentifier);
- in other words, it preserves the structure and the types of your model unaltered during encoding and decoding;
- is fully type checked at compile time (*);
- supports keyed and unkeyed coding, also usable simultaneously;
- supports conditional encoding;
- implements an userInfo dictionary;
- implements a reference type version system;
- implements a reference type substitution system during decode;

Check code examples in the [User Guide](/Docs/UserGuide.md). Check the tests section, too.

(*) Fully type checking at compile time is mutually exclusive with the ability to encode/decode heterogeneous collections (i.e. `[Any]`) containing 'codable' elements. I chose to support the first feature while giving up the second.

## Other information
**Most Swift Standard Library and Foundation types are supported now.** The list is [here](/Docs/GraphCodableTypes.md).

GraphCodable can encode and decode any Swift object graph, regardless of how complex it is, reconstructing its [original structure](/Docs/UserGuide.md#Directed-acyclic-graphs) with its original types without duplicating objects.
If the reference types form an acyclic graph, only `decode` should be used in the `init (from: GDecoder)` method.
If the reference types form a cyclic graph, `deferDecode` must be used in the `init (from: GDecoder)` method to "break" the cycle.

GraphCodable does not use a public format for the data (such as JSON or others) but stores the data in a [private binary format](/Docs/DataFormat.md) defined by the package itself. Having to preserve information about the types, GraphCodable creates larger data in bytes than those generated by Codable encoders. Despite this, the time required for encoding and decoding is generally comparable if not faster.

GraphCodable is written entirely in Swift. The use of 'unsafe' methods is limited to a handful of functions related to reading and writing data in binary format (see BinaryIO). Everything else is 'safe'.

## Be aware
For now, **the data format may be subject to future changes.**

## Other documents
- [User Guide](/Docs/UserGuide.md)
- [Data Format](/Docs/DataFormat.md)
- [GraphCodable Types](/Docs/GraphCodableTypes.md)

## Simple interface comparison to Swift Codable
In GraphCodable:
- GCodable have the same roles as Codable
- GEncoder, GDecoder have the same roles as Encoder, Decoder
- GraphEncoder has the same role as JSONEncoder, PropertyListEncoder
- GraphDecoder has the same role as JSONDecoder, PropertyListDecoder

GraphCodable does not use containers.

## Supported technologies

- Swift 5.3

## Changelog

Check it [here](/CHANGELOG.md).

## License

GraphCodable is released under the MIT license. [See LICENSE](/LICENSE.txt) for more details.


