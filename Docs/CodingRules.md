#  Coding Rules

This table summarizes the methods to be used in your `func encode(to encoder: GEncoder) throws { ... }` and `init(from decoder: GDecoder) throws { ... }` depending on the type of variable to be encoded and decoded:

```
┌───────────────────────────────────────────────────────────────────────────────┐
│                           ENCODE/DECODE RULES                                 │
├───────────────────┬───────────────────┬───────────────────────────────────────┤
│                   │    VALUE   TYPE   │            REFERENCE TYPE             │
│      METHOD       ├─────────┬─────────┼─────────┬─────────┬─────────┬─────────┤
│                   │         │    ?    │ strong  │ strong? │ weak? O │ weak? Ø │
╞═══════════════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╡
│ encode            │  █████  │  █████  │  █████  │  █████  │⁵        │⁵        │
├───────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│⁶encodeIfPresent   │¹        │  █████  │¹        │  █████  │⁵        │⁵        │
├───────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ encodeConditional │¹        │¹        │¹        │  █████  │  █████  │  █████  │
╞═══════════════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╡
│ decode            │  █████  │  █████  │  █████  │  █████  │  █████  │⁴        │
├───────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│⁶decodeIfPresent   │¹        │  █████  │¹        │  █████  │  █████  │⁴        │
├───────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ deferDecode       │¹        │¹        │¹        │³        │³        │² █████  │
╞═══════════════════╧═════════╧═════════╧═════════╧═════════╧═════════╧═════════╡
│    ?    = optional                                                            │
│ strong  = strong reference                                                    │
│ strong? = optional strong reference                                           │
│  weak?  = weak reference (always optional)                                    │
│    Ø    = weak reference used to prevent strong memory cycles in ARC          │
│    O    = any other use of a weak reference                                   │
├───────────────────────────────────────────────────────────────────────────────┤
│  █████  = mandatory or highly recommended                                     │
│ ¹       = not allowed                                                         │
│ ²       = allowed by Swift only in the init method of a reference type        │
│           Swift forces to call it after super class initialization            │
│ ³       = you don't need deferDecode: use decode(...) instead                 │
│ ⁴       = GraphCodable exception during decode: use deferDecode(...) instead  │
│ ⁵       = allowed but not recommendend: you run the risk of unnecessarily     │
│           encode and decode objects that will be immediately released after   │
│           decoding. Use encodeConditional(...) instead.                       │
│ ⁶       = keyed coding only.                                                  │
│         - encodeIfPresent(...) encode the value only if value != nil          │
│           encode(...) encode nil in the same situation                        │
│         - decodeIfPresent(...) decode the value for the given key if it       │
│           exists ( i.e. contains(key) == true ) and do not generate an        │
│           exception if the key doesn't exists.                                │
└───────────────────────────────────────────────────────────────────────────────┘
```
All GraphCodable protocols are defined [here](/Sources/GraphCodable/GraphCodable.swift)
