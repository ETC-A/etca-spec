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
    syntax Bool ::= #rangeBool ( Int )       [alias]
                  | #rangeSInt ( Int , Int ) [alias]
                  | #rangeUInt ( Int , Int ) [alias]

    rule #rangeBool (      X ) => X ==Int 0 orBool X ==Int 1
    rule #rangeSInt ( 8  , X ) => #range ( minSInt8  <= X <= maxSInt8  )
    rule #rangeSInt ( 16 , X ) => #range ( minSInt16 <= X <= maxSInt16 )
    rule #rangeUInt ( 8  , X ) => #range ( minUInt8  <= X <= maxUInt8  )
    rule #rangeUInt ( 16 , X ) => #range ( minUInt16 <= X <= maxUInt16 )
  //--------------------------------------------------------------------

    syntax Bool ::= "#range" "(" Int "<=" Int "<=" Int ")" [macro]
    
    rule #range ( LB <= X <= UB ) => LB <=Int X andBool X <=Int UB
```

### Numeric Interpretation

Internally of course we are only storing binary. But K's `Int` type is arbitrary
precision and numeric. So we need ways to interpret `Int`s as various widths and
signednesses.

```k
    syntax Int ::= chopTo ( Int , Int ) [function]

    rule chopTo ( 8  , I:Int ) => I modInt pow8  [concrete]
    rule chopTo ( 16 , I:Int ) => I modInt pow16 [concrete]
  //-----------------------------------------------------

    syntax Int ::= zextFrom ( Int , Int ) [function, functional]
                 | sextFrom ( Int , Int ) [function, functional]

    rule zextFrom ( Width , I ) =>           bitRangeInt(I, 0, Width) [concrete]
    rule sextFrom ( Width , I ) => signExtendBitRangeInt(I, 0, Width) [concrete]
```

We also want a couple simple functions to check the sign or magnitude of a
number assumed to currently be in a signed representation (to manipulate the
ALU outputs, for example).

```k
    syntax Bool ::= isNegative ( Int ) [function, functional]
                  | isPositive ( Int ) [function, functional]

    rule isNegative ( I ) =>        I <Int 0
    rule isPositive ( I ) => 0 <Int I
  //----------------------------------------

    syntax Int ::= magnitude ( Int ) [function, functional]

    rule magnitude ( I ) =>        I requires I >=Int 0
    rule magnitude ( I ) => 0 -Int I requires I <Int 0
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

* `M [ N := BS ]` assigns a contiguous chunk of the memory `M` to the bytes `BS`
  starting at position `N`.
* `#range(M, START, WIDTH)` reads off `WIDTH` elements from `M` starting at `START`.
  The result is padded with zeros as needed.

```k
    syntax Memory = Bytes
    syntax Memory ::= Memory "[" Int ":=" Bytes "]" [function, functional]

    rule M [ START := M' ] => replaceAtBytes(padRightBytes(M, START +Int lengthBytes(M'), 0), START, M')
        requires START >=Int 0 [concrete]
    rule _ [ START := _:Bytes ] => .Memory
        requires START <Int 0  [concrete]
  //----------------------------------------------------------------------------------------------------

    syntax Bytes ::= #range ( Memory , Int , Int ) [function, functional]

    rule #range(M, START, WIDTH) => M [ START .. WIDTH ] [concrete]
  //---------------------------------------------------------------------

    syntax Bytes ::= Bytes "[" Int ".." Int "]" [function, functional]

    rule  _ [ START .. WIDTH ] => .Bytes
        requires notBool (WIDTH >=Int 0 andBool START >=Int 0)
    rule BS [ START .. WIDTH ] => substrBytes(padRightBytes(BS, START +Int WIDTH, 0), START, START +Int WIDTH)
        requires WIDTH >=Int 0 andBool START >=Int 0 andBool START <Int lengthBytes(BS)
    rule  _ [ _     .. WIDTH ] => padRightBytes(.Bytes, WIDTH, 0) [owise]
  //-----------------------------------------------------------------------------------------------------

    syntax Memory ::= ".Memory" [macro]
    rule .Memory => .Bytes
  //------------------------------------

    syntax Memory ::= Memory "[" Int ":=" Int "]" [function]

    rule M [ IDX := VAL ] => padRightBytes(M, IDX +Int 1, 0) [ IDX <- VAL ]
```

### Registers

Registers are identified by number and map to their contents, an `Int`. Since
registers are identified by an integer, we can back the register file with an Array.
Arrays in K used to be their own type, but since the List type was improved,
Arrays are just Lists now. It's best to use List directly.

```k
    syntax RegisterID ::= Int
    syntax Registers  ::= Registers ( List )

    syntax Int ::= Registers "[" RegisterID "]" [function]
    rule Registers(RS) [ N::RegisterID ] => {RS [ {N}:>Int ]}:>Int

    syntax Registers ::= Registers "[" RegisterID "<-" Int "]" [function]
    rule Registers(RS) [ N <- VAL ] => Registers(RS) [ N <- VAL ]

    syntax Registers ::= makeRegisters ( Int ) [macro]
    rule makeRegisters( N ) => Registers(makeList(N, 0))
```
```k
endmodule
```
