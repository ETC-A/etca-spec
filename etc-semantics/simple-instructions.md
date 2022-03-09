# Straight-Line Instructions

By far the most common case of instructions is typical straight-line
behavior. This module provides a utility sort which automatically
converts a `SizedInstruction` containing a `StraightLineInstruction`
into a the `StraightLineInstruction` followed by an increase to the `PC`.

```k
module STRAIGHT-LINE
    imports private ETC

    syntax Instruction ::= StraightLineInstruction
    syntax StraightLineInstruction
    rule <k> (I:StraightLineInstruction ISize(N)):SizedInstruction
          => I ~> #pc [ N ]
         ...</k>

    syntax KItem ::= "#pc" "[" Int "]"
    rule <k> #pc [ OFFSET ] => . ...</k>
         <pc> PC => PC +Int OFFSET </pc>
endmodule
```

Simply subsort your instruction sort to `StraightLineInstruction` to
get these utility rules for free. It's that easy!

# Unsized Instructions

Some classes of control flow instructions are unconditional transfers
whose sizes can be discarded. Subsorting your instruction to `UnsizedInstruction`
will automatically discard the size from your decoder. You must still
produce the size however, as the semantics are allowed to assume that the
`SizedInstruction` sort only has the one constructor.

```k
module UNSIZED-INSTRUCTION
    imports private ETC

    syntax Instruction ::= UnsizedInstruction
    syntax UnsizedInstruction
    rule <k> (I:UnsizedInstruction ISize(_)):SizedInstruction
          => I
         ...</k>
endmodule
```
