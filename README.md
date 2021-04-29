# GraphCodable

Firstly, I apologize for my poor English. I hope the content remains understandable.

GraphCodable is an **experimental** encode/decode library (similar to Codable at interface level) that does not treat reference types as second-class citizens.
In other words, GraphCodable tries to offer functionalities similar to those of NSCoder within the "limits" of a language (Swift) less dynamic than Objective C.

Specifically, GraphCodable:
- [x] saves all type information;
- [x] supports reference types inheritance;
- [x] never duplicates the same object (as defined by ObjectIdentifier) during the decoding process;
- [x] is fully type checked at compile time (*);
- [x] supports keyed and unkeyed storage, also employed simultaneously in the same type;
- [x] supports conditional encoding;
- [x] implements a type version system;
- [x] implements a type substitution system during decode;

GraphCodable natively supports the following types: Int, Int8, Int16, Int32, Int64, UInt, UInt8, UInt16, UInt32, UInt64, Float, Double, String, Data
GraphCodable make Optional, Array, Set, Dictionary codable if the hold codable types. OptionSet and Enum with rawValue of native type (except Data) are codable, too.

GraphCodable can dearchive any ARC compatible Swift object graph, regardless of how complex it is, reconstructing its original structure with its original types.
Only the weak variables possibly used in the object graph in order to avoid strong memory cycles in ARC require special treatment during initialization from the decoder within the 'init (from: GDecoder)' method.
One limitation exists: you cannot put a weak variable that must employ the above mechanism inside a value type (i.e. a struct). The "container" type must be a reference type.

Since, unlike Obiective-C, it is impossible in Swift to construct an object at runtime starting from its name string, it is necessary to "register" (that is, associate the "type" to its "type name") in advance all types which can be decoded. A singleton object (GTypesRepository) is used for this, which must be initialized 'very soon' in your program. GraphCodable offers various systems to facilitate this task. First, all types involved in archiving are automatically registered by the encoder to make debugging easier. Second, the decoder has a function (help) that generates a string containing the 'register function' that must be included in the code to decode a particular data file. Third, the same string, relative to all the types registered by all the session encodes, can be generated by the 'help' register function.

GraphCodable does not use a "public" format for the data (such as JSON or others) but stores the data in a binary format defined in the library itself. Having to preserve information about the types, GraphCodable creates larger data in bytes than those generated by Codable encoders. Despite this, the time required for encoding and decoding is generally comparable if not faster.

GraphCodable is written entirely in Swift. The use of 'unsafe' methods is limited to a handful of functions related to reading and writing data in binary format (see BinaryIO). Everything else is 'safe'.

(*) Fully type checking at compile time is mutually exclusive with the ability to encode/decode heterogeneous collections (i.e. [Any]) containing 'codable' elements. I chose to support the first feature while giving up the second.

## Simple interface comparison to Swift Codable
In GraphCodable:
- [x] GEncodable, GDecodable and GCodable have the same roles as Encodable, Decodable and Codable
- [x] GEncoder, GDecoder have the same roles as Encoder, Decoder
- [x] GraphEncoder has the same role as JSONEncoder, PropertyListEncoder
- [x] GraphDecoder has the same role as JSONDecoder, PropertyListDecoder

GraphCodable does not use containers.

## License

GraphCodable is released under the MIT license. ![See LICENSE](/Docs/LICENSE) for more details.


