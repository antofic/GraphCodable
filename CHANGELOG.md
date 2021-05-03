
# 0.1.2

Now encoder is capable of quickly collapsing any combination of arrays, dictionaries and sets containing ultimately native elements (but not optionals) into a sequence of bytes.
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
