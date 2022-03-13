# Width Extensions

The width extensions comprise 3 extensions total:
* bit 4: Byte Operations
* bit 6: Doubleword Operations
* bit 7: Quadword operations

These extensions essentially behave identically, other than a single number.
If any one of them is enabled, the `movz` instruction is available. Each of
them also adds decoding for a single size bit.

When the doubleword or quadword extensions are first enabled, they cause the
program counter to get sign extended from the current operating width to the
widest width supported by the machine. The `<reg-width>` configuration cell
contains the widest width supported by the machine; the `<reg-mode>` cell
contains the currently configured operating width.

We defer most of implementing this to the individual extensions, but they all
share the implementation of `movz` so we define that separately from them.

```k
module MOVZ-EXTENSION
    imports private ETC
    imports private BASE
    imports EXTENSION
```

## New Instruction

The extensions define a new instruction, `movz`, which behaves by moving
its argument to the destination operand and zero-extending it from the operand
width to the full register width.

```k
    syntax BaseCompOpcode ::= "movz"

    rule decode(BS:Bytes) => decodeBaseCRR(BS)
      requires BS[0] &Int 207 ==Int 8  // 00xx1000
       andBool checkMovzEnabled()
    rule decode(BS:Bytes) => decodeBaseCRI(BS)
      requires BS[0] &Int 207 ==Int 72 // 01xx1000
       andBool checkMovzEnabled()

    rule decodeBaseCompOpcode(8) => movz
      requires checkMovzEnabled()

    rule <k> #operands[_LV,RV] ~> movz _ OPL _
          => #writeWOperandZX(OPL, RV)
         ...</k>
```

The `checkMovzEnabled()` function merely checks if any of the width-operation
bits are enabled in `EXTEN`. A hook for this is probably overkill.

```k
    syntax Bool ::= checkMovzEnabled() [function, functional]

    rule [[ checkMovzEnabled() 
      => bit(4,EXTEN) orBool bit(6,EXTEN) orBool bit(7,EXTEN) ]]
      <exten> EXTEN </exten>
```

```k
endmodule
```
