#  Coding Rules

This table summarizes the methods to be used in your `func encode(to encoder: GEncoder) throws { ... }` and `func encode(to encoder: GEncoder) throws { ... }` depending on the type of variable to be encoded and decoded:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          ENCODE/DECODE RULES                            │
├───────────────────┬─────────────────┬───────────────────────────────────┤
│                   │   VALUE  TYPE   │          REFERENCE  TYPE          │
│      METHOD       ├────────┬────────┼────────┬────────┬────────┬────────┤
│                   │        │    ?   │    s   │   s?   │  w? O  │  w? Ø  │
╞═══════════════════╪════════╪════════╪════════╪════════╪════════╪════════╡
│ encode            │ ██████ │ ██████ │ ██████ │ ██████ │        │        │
├───────────────────┼────────┼────────┼────────┼────────┼────────┼────────┤
│ encodeConditional │        │        │        │ ██████ │ ██████ │ ██████ │
╞═══════════════════╪════════╪════════╪════════╪════════╪════════╪════════╡
│ decode            │ ██████ │ ██████ │ ██████ │ ██████ │ ██████ │        │
├───────────────────┼────────┼────────┼────────┼────────┼────────┼────────┤
│ deferDecode       │        │        │        │        │        │ ██████ │
╞═══════════════════╧════════╧════════╧════════╧════════╧════════╧════════╡
│    ?   = optional                                                       │
│    s   = strong reference                                               │
│    s?  = optional strong reference                                      │
│    w?  = weak reference (always optional)                               │
│    Ø   = weak reference used to prevent strong memory cycles in ARC     │
│    O   = any other use of a weak reference                              │
│  Note  : Swift does not allow calling deferDecode from the init of a    │
│          value type, but only from that of a reference type. Swift      │
│          forces to call it after super class initialization.            │
└─────────────────────────────────────────────────────────────────────────┘
```
All GraphCodable protocols are defined [here](/Sources/GraphCodable/GraphCodable.swift)