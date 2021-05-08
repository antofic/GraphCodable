
# 0.2.1

The type construction now relies on `_mangledTypeName(...)` (when available) and on  `_typeByName(...)`, too. On systems where `_mangledTypeName(...)` is available it should always be possible to dearchive the classes that are archived.

**Most Swift Standard Library and Foundation types are supported now.** The list is [here](/Docs/GraphCodableTypes.md).

## Be aware
**The data format may be subject to future changes.**

# 0.2.0

The package has been completely revised. It now relies on `NSStringFromClass(...)` to generate the "type name" and on  `NSClassFromString(...)` to retrieve the class type fro it. At least on Apple systems this procedure should now be stable.

Use `myClass.isGCodable` to check if a class is actually decodable.

At least on Apple systems this procedure should now be stable.

Thanks to this change **it is no longer necessary to register the classes (the repository is gone)** or even set the main module name.

All the previous features are maintained, except for the reference type replacement system which is no longer available at this point in the redesign phase.

## Be aware
**The data format may be subject to future changes.**


# 0.1.3

Previous native types have been dropped en masse, replaced by binary types that act as new native types. Binary types are also better readable in dumps. As a result the encodeOptions have been eliminated and the dump interface returned as in version 0.1.1.

## Be aware
**The data format may be subject to future changes.**

# 0.1.2

Now encoder is capable of quickly collapsing any combination of arrays, dictionaries and sets containing ultimately native elements (including optionals) into a sequence of bytes.
Thanks to this optimization, encoding and decoding are faster and the size of the generated data reduced.
This optimization, active by default, can be disabled using: `GraphEncoder().encode( inRoot, encodeOptions: .readable )`.

## Be aware
**The data format may be subject to future changes.**

# 0.1.1

This minor unstable release mades severale changes. Note that the data format has changed.

## Only reference types need to be registered

Value types no longer need to be registered. It never made sense that they were. This simplifies the maintenance of the repository.

## Native types management revised
Revised the management of native types (even if I am not satisfied yet): faster encoding and decoding and smaller files.

## GEncodable and GDecodable removed
This subdivision is an unnecessary complication: we keep only the GCodable protocol.

## Be aware
**The data format may be subject to future changes.**

# 0.1.0

This is the first minor, unstable release of GraphCodable. The public API for this library is subject to change unexpectedly until 1.0.0 is reached, at which point breaking changes will be mitigated and communicated ahead of time.

## Be aware
**The data format may be subject to future changes.**
