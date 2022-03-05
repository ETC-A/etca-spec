# ETC.A Data Types

ETC.a uses 16-bit registers by default. It also has byte-addressable memory, and extensions that modify the
register size and other things. As a result, we need a fair degree of generality in our data structures.

We mainly want to operate over bytes and words at the moment. We also want to keep the control registers
in the configuration so that we can check them in the future.

We also want functions for sign extension, zero extension, range-checking, and chopping.
We want these to have a degree of generality as well.

Since we want generality, everything is implemented over K's `Int`. K has a `MInt{Width}` parametric
type, but the fixed width reduces generality and it also appears to have some bugs. Other projects
like `kframework/evm-semantics` have demonstrate that `Int` is sufficient even for large projects.
```k
module ETC-TYPES
    imports INT
    imports STRING
    imports COLLECTIONS
    imports BOOL
    imports BYTES
```

## Utilities

### Important Sizes

ETC.A machines frequently refer to the various power-of-2 numbers of bytes to
describe features like register width and operand size.

```k
    syntax ByteSize ::= "half"       // 1 byte
                      | "word"       // 2 bytes
                      /*
                      | "doubleword" // 4 bytes
                      | "quadword"   // 8 bytes
                      */

    syntax Int ::= ByteSize2NumBits  ( ByteSize ) [function, functional]
                 | ByteSize2NumBytes ( ByteSize ) [function, functional]
    rule ByteSize2NumBits ( half ) => 8
    rule ByteSize2NumBits ( word ) => 16

    rule ByteSize2NumBytes ( half ) => 1
    rule ByteSize2NumBytes ( word ) => 2
```

### Important Powers

Some important numbers come up often, especially when chopping and range-checking. Giving them aliases
allows us to refer to them by name instead of with a `^Int` expression everywhere. These aliases are
expanded wherever they appear in rules.

```k
    syntax Int ::= "pow16" [alias] /* 2 ^Int 16 */
                 | "pow8"  [alias] /* 2 ^Int 8  */

    rule pow16 => 65536
    rule pow8  => 256
 //------------------------------------------------
    syntax Int ::= "minSInt8"  [alias]
                 | "maxSInt8"  [alias]
                 | "minUInt8"  [macro]
                 | "maxUInt8"  [alias]
                 | "minSInt16" [alias]
                 | "maxSInt16" [alias]
                 | "minUInt16" [macro]
                 | "maxUInt16" [alias]

    rule minSInt8  => -128    /* -2^7      */
    rule maxSInt8  =>  127    /*  2^7  - 1 */

    rule minUInt8  =>  0
    rule maxUInt8  =>  255    /*  2^8  - 1 */

    rule minSInt16 => -32768  /* -2^15     */
    rule maxSInt16 =>  32767  /*  2^15 - 1 */

    rule minUInt16 =>  0
    rule maxUInt16 =>  65535  /*  2^16 - 1 */
```

### Ranges

Syntax for specifying the range of a value. This is useful for checking invariants
but also for determining things like overflow and address validity.
Since K `Int`s are arbitrary-precision, this allows us to bounds-check memory access,
for example.

```k
    syntax Bool ::= #rangeBool ( Int )       [macro]
                  | #rangeSInt ( Int , Int ) [macro]
                  | #rangeUInt ( Int , Int ) [macro]
                  | #rangeByteSize ( ByteSize , Int ) [macro]

    rule #rangeBool (      X ) => X ==Int 0 orBool X ==Int 1
    rule #rangeSInt ( 8  , X ) => #range ( minSInt8  <= X <= maxSInt8  )
    rule #rangeSInt ( 16 , X ) => #range ( minSInt16 <= X <= maxSInt16 )
    rule #rangeSInt ( _  ,_X ) => false [owise]
    rule #rangeUInt ( 8  , X ) => #range ( minUInt8  <= X <= maxUInt8  )
    rule #rangeUInt ( 16 , X ) => #range ( minUInt16 <= X <= maxUInt16 )
    rule #rangeUInt ( _  ,_X ) => false [owise]
    
    rule #rangeByteSize ( half , X ) => #rangeUInt ( 8  , X )
    rule #rangeByteSize ( word , X ) => #rangeUInt ( 16 , X )
    // this rule is not possible, but the LLVM code generator gets really angry
    // if it is not present.
    rule #rangeByteSize ( _   , _X ) => false [owise]
  //--------------------------------------------------------------------

    syntax Bool ::= "#range" "(" Int "<=" Int "<=" Int ")" [macro]
                  | "#range" "(" Int "<=" Int "<"  Int ")" [macro]
    
    rule #range ( LB <= X <= UB ) => LB <=Int X andBool X <=Int UB
    rule #range ( LB <= X <  UB ) => LB <=Int X andBool X <Int  UB
```

### Numeric Interpretation

Internally of course we are only storing binary. But K's `Int` type is arbitrary
precision and numeric. So we need ways to interpret `Int`s as various widths and
signednesses.

```k
    syntax Int ::= chopTo ( ByteSize , Int ) [function]

    rule chopTo ( half , I:Int ) => I modInt pow8  [concrete]
    rule chopTo ( word , I:Int ) => I modInt pow16 [concrete]
  //-----------------------------------------------------

    syntax Int ::= zextFrom ( Int      , Int ) [function, functional]
                 | zextFrom ( ByteSize , Int ) [function, functional]
                 | sextFrom ( Int      , Int ) [function, functional]
                 | sextFrom ( ByteSize , Int ) [function, functional]

    rule zextFrom ( Width , I ) =>           bitRangeInt(I, 0, Width) [concrete]
    rule sextFrom ( Width , I ) => signExtendBitRangeInt(I, 0, Width) [concrete]
    rule zextFrom ( SIZE  , I ) => zextFrom(ByteSize2NumBits(SIZE), I) [concrete]
    rule sextFrom ( SIZE  , I ) => sextFrom(ByteSize2NumBits(SIZE), I) [concrete]
```

We also want a couple simple functions to check the sign or magnitude of a
number assumed to currently be a 2's complement number. They take a ByteSize
so that they can identify the sign bit.

```k
    syntax Bool ::= isNegative    ( ByteSize , Int ) [function, functional]
                  | isNonNegative ( ByteSize , Int ) [function, functional]

    rule isNegative    ( SIZE , I ) => sextFrom(SIZE, I) <Int 0
    rule isNonNegative ( SIZE , I ) => notBool isNegative(SIZE, I)
  //----------------------------------------

    syntax Int ::= magnitude ( Int ) [function, functional]

    rule magnitude ( I ) =>        I requires I >=Int 0
    rule magnitude ( I ) => 0 -Int I requires I <Int 0
```

For the purpose of checking flags, we want functions to check if a result of
arbitrary precision causes a loss of precision in either unsigned or signed
arithmetic when stored at a given `ByteSize`. In unsigned arithmetic, such
loss of precision is a carry, and in signed, it is an overflow!

```k
    syntax Bool ::= carried    ( ByteSize , Int )               [function, functional]
                  | overflowed ( ByteSize , Bool , Bool , Int ) [function, functional]

    rule carried(SIZE, V) =>
         zextFrom(SIZE, V) =/=Int zextFrom(ByteSize2NumBits(SIZE) +Int 1, V)

    rule overflowed(SIZE, LSign, RSign, RES) =>
         (LSign ==Bool RSign) andBool (LSign =/=Bool isNegative(SIZE, RES))
```

We also have numeric values in the `cpuid` and `exten` control registers.
We want to be able to check these on a bit-by-bit basis.

```k
    syntax Bool ::= bit ( Int , Int ) [function, functional]

    rule bit(N, I) => bitRangeInt(I, N, 1) ==Int 1 [concrete]
```

### Memory

Everything happens in memory. The first thing that the interpreter does is load
the given binary into the memory at address 0x8000. Addresses below 0x8000 are
writeable, readable, and executable. Addresses at or above 0x8000 are only
readable and executable. It is planned for future configurability to let users
map addresses in a more customizable way.

We use a sparse "paged" representation of memory. The non-bottom address bytes
are used to select a 256 byte "page" of memory and the bottom byte is used to
index within that page. Cross-page access is supported by both of the following
functions.

* `M [ N := BS ]` assigns a contiguous chunk of the memory `M` to the bytes `BS`
  starting at position `N`.
* `#range(M, START, WIDTH)` reads off `WIDTH` elements from `M` starting at `START`.
  The result is padded with zeros as needed.

```k
    syntax Memory = Map // Map{Int,Bytes}
    syntax Memory ::= ".Memory" [macro]
    rule .Memory => .Map

    syntax Memory ::= Memory "[" Int ":=" Bytes "]" [function, functional]

    rule MEM [ START := BS' ]
         => MEM [ START >>Int 8 <-
                replaceAtBytes(
                    padRightBytes(
                        {MEM[START >>Int 8] orDefault .Bytes}:>Bytes,
                        pow8,
                        0
                    ),
                    chopTo(half, START),
                    BS'
                )
            ]
      requires START >=Int 0
       andBool chopTo(half, START) +Int lengthBytes(BS') <=Int pow8 [concrete]

    rule MEM [ START := BS' ]
         => (MEM [ START >>Int 8 <-
                replaceAtBytes(
                    padRightBytes(
                        {MEM[START >>Int 8] orDefault .Bytes}:>Bytes,
                        pow8,
                        0
                    ),
                    chopTo(half, START),
                    substrBytes(BS', 0, pow8 -Int chopTo(half, START))
                )
            ]) [  (((START >>Int 8) +Int 1) <<Int 8)
               := substrBytes(BS', pow8 -Int chopTo(half, START), lengthBytes(BS'))
               ]
      requires START >=Int 0
       andBool chopTo(half, START) +Int lengthBytes(BS') >Int pow8 [concrete]

    rule _:Map [ START := _:Bytes ] => .Memory
      requires START <Int 0 [concrete]
  //----------------------------------------------------------------------------------------------------

    syntax Bytes ::= #range ( Memory , Int , Int )      [function, functional]
                   | #range ( Memory , Int , ByteSize ) [function, functional]

    rule #range(MEM, START, WIDTH:ByteSize) => #range(MEM, START, ByteSize2NumBytes(WIDTH))

    rule #range(_, START, WIDTH) => .Bytes
      requires notBool(START >=Int 0 andBool WIDTH >=Int 0) [concrete]

    rule #range(MEM, START, WIDTH)
         => substrBytes(
                padRightBytes({MEM[START >>Int 8] orDefault .Bytes}:>Bytes, pow8, 0),
                chopTo(half, START),
                chopTo(half, START) +Int WIDTH
            )
      requires START >=Int 0
       andBool WIDTH >=Int 0
       andBool chopTo(half, START) +Int WIDTH <=Int pow8 [concrete]

    rule #range(MEM, START, WIDTH)
         => substrBytes(
                padRightBytes({MEM[START >>Int 8] orDefault .Bytes}:>Bytes, pow8, 0),
                chopTo(half, START),
                pow8
            )
            +Bytes #range(MEM, 0, WIDTH -Int (pow8 -Int chopTo(half, START)))
      requires START >=Int 0
       andBool WIDTH >=Int 0
       andBool chopTo(half, START) +Int WIDTH >Int pow8 [concrete]
```

### Registers

Registers are identified by number and map to their contents, an `Int`.

We keep the `Int` a positive value and interpret it as signed with `sextFrom`
when needed.

```k
    syntax RegisterID ::= Int
    syntax Registers  ::= Registers ( Map )

    syntax Int ::= Registers "[" RegisterID "]" [function]
    rule Registers(RS) [ N::RegisterID ] => {RS [ N ]}:>Int

    syntax Registers ::= Registers "[" RegisterID "<-" Int "]" [function]
    rule Registers(RS) [ N <- VAL ] => Registers(RS [ N <- VAL ])

    syntax Registers ::= makeRegisters ( Int ) [macro]
    rule makeRegisters( N ) => Registers( fillMap(N -Int 1, 0) )
    
    syntax Map ::= fillMap ( Int , KItem ) [function, functional]
    rule fillMap(0, V) => 0 |-> V
    rule fillMap(N, V) => N |-> V fillMap(N -Int 1, V)
      requires N >Int 0
    rule fillMap(N, _) => .Map
      requires N <Int 0
```
```k
endmodule
```
