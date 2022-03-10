# Base ISA

Here we implement the base ISA. This file serves as a good basis for how to
add new instructions to the semantics.

## Base Operands

The Base ISA contains a specification for the two basic operand types, which
are word-size registers and 5- or 9- bit immediates.

```k
module BASE-OPERANDS
    imports private ETC

    syntax ImmWidth = Int
    syntax OperandSize = ByteSize

    syntax Operand ::= RWOperand | ROperand

    // readable and writable
    syntax RWOperand ::= RegOperand(OperandSize, RegisterID)
    // readable only
    syntax ROperand  ::= ImmOperand(ImmWidth, Int)
                       | RWOperand
```

For extensibility, we must provide a hook-able interface into both reading
operands (`evalOperand`) and writing `RWOperand`s via `writeWOperand`.

In order to maintain modularity (as some extensions simply expand the allowable
values of base instruction fields) we instead define these operands fully
generally. They are parameterized over `ByteSize` for registers and `Width` for
immediates. Note that `RWOperand`s **must** respect the `OperandSize` of the
referenced data. For a memory operand, this means that the `RWOperand` must
know the width of the referenced data regardless of the pointer width.

As always when we add things to sort `Operand`, we must define `evalOperand`
over them.

```k
    rule evalOperand(       _, RegOperand(SIZE,  RID)) => Reg[RID : SIZE]
    rule evalOperand(  Signed, ImmOperand(WIDTH, IMM)) => sextFrom(WIDTH, IMM)
    rule evalOperand(Unsigned, ImmOperand(WIDTH, IMM)) => zextFrom(WIDTH, IMM)
```

And for extensibility, we define `#writeWOperand` as well.

```k
    syntax KItem ::= #writeWOperand   ( RWOperand , Int )
                   | #writeWOperandZX ( RWOperand , Int )

    rule <k> #writeWOperand(RegOperand(SIZE, RID), RES)
          => Reg[RID : SIZE] = RES
         ...</k>

    rule <k> #writeWOperandZX(RegOperand(SIZE, RID), RES) => . ...</k>
         <registers> RS => RS [ RID <- zextFrom(SIZE, RES) ] </registers>
         <reg-count> RCOUNT </reg-count>
      requires #range(0 <= RID < RCOUNT)
```

```k
endmodule
```

## Base Instructions

```k
module BASE
    imports private ETC
    imports private ETC-FLAGS
    imports private STRAIGHT-LINE

    imports BASE-OPERANDS
```

The Base ISA defines 3 instruction formats: "Computation reg-reg,"
"Computation reg-imm," and "jump." We'll refer to these as `BaseCRR`,
`BaseCRI`, and `BaseJmp` respectively. However, we'll treat `BaseCRR` and
`BaseCRI` together, so that we can treat the `Operand` sort as a hook.

```k
    syntax BaseInstruction
        ::= BaseCompInstruction
          | BaseJumpInstruction
```

### Decoding

We start by picking out the base instruction patterns, as described in `etc.md`.

If the first two bits are zero, we usually have a `BaseCRRInstruction` (although
we have invalid size or operand-mode bits). The exceptions are if the first two
opcode bits are 3 or the last operand bits are not 0.
Opcodes 12-15 do not have reg-reg modes, and non-0 operand mode bits indicate
something more complex than reg-reg.

```k
    rule decode(BS:Bytes) => decodeBaseCRR(BS)
      requires (BS[0] >>Int 6) &Int 3   ==Int 0  // 00...
       andBool (BS[0] >>Int 2) &Int 3  =/=Int 3  // xxxx11??
       andBool  BS[1]          &Int 3   ==Int 0  // AAABBB00
       andBool  BS[0]          &Int 15 =/=Int 8  // xxxx1000
       andBool  BS[0]          &Int 15 =/=Int 13 // xxxx1101
```

If the first two bits are one, we always have a `BaseCRIInstruction`, again
possibly with invalid size bits.

```k
    rule decode(BS:Bytes) => decodeBaseCRI(BS)
      requires (BS[0] >>Int 6) &Int 3   ==Int 1
       andBool  BS[0]          &Int 15 =/=Int 8  // xxxx1000
       andBool  BS[0]          &Int 15 =/=Int 13 // xxxx1101
```

Finally, if the first three bits are four, we have a `BaseJmpInstruction`.

```k
    rule decode(BS:Bytes) => decodeBaseJmp(BS)
      requires (BS[0] >>Int 5) &Int 7  ==Int 4
```

#### Base Comp Opcodes

```k
    syntax BaseCompOpcode
        ::= "add" | "sub" | "rsub" | "cmp"
          | "or"  | "xor" | "and"  | "test"
                  | "mov" | "load" | "store"
          | "slo"         | "in"   | "out"
          | decodeBaseCompOpcode ( Int )   [function]
          | decodeBaseCompOpcode ( Bytes ) [function]

    rule decodeBaseCompOpcode(BS:Bytes) =>
         decodeBaseCompOpcode(BS[0] &Int 15)

    rule decodeBaseCompOpcode( 0) => add
    rule decodeBaseCompOpcode( 1) => sub
    rule decodeBaseCompOpcode( 2) => rsub
    rule decodeBaseCompOpcode( 3) => cmp
    rule decodeBaseCompOpcode( 4) => or
    rule decodeBaseCompOpcode( 5) => xor
    rule decodeBaseCompOpcode( 6) => and
    rule decodeBaseCompOpcode( 7) => test
  //rule decodeBaseCompOpcode( 8) => // reserved
    rule decodeBaseCompOpcode( 9) => mov
    rule decodeBaseCompOpcode(10) => load
    rule decodeBaseCompOpcode(11) => store
    rule decodeBaseCompOpcode(12) => slo
  //rule decodeBaseCompOpcode(13) => // reserved
    rule decodeBaseCompOpcode(14) => in
    rule decodeBaseCompOpcode(15) => out
```

#### Base CRR Instructions

These instructions have reserved size bits, which we provide a decoding
hook for. The semantics for these instructions given here will correctly
execute for any size which can be passed to `chopTo` and `evaluateOperand`.

```k
    syntax MaybeOperandSize ::= "UnknownOperandSize"
                              | OperandSize
                              | decodeOperandSize ( Int ) [function]

    rule decodeOperandSize(1) => word
    rule decodeOperandSize(_) => UnknownOperandSize [priority(400)]
```

Rules which attempt to decode an operand size will produce an `UnknownInstruction`
if they receive an `UnknownOperandSize`. It is now possible to add a new size
in an extension by defining a decoding rule for it and rules for the appropriate
functions from `etc-types.md`.

Now we define the instruction sort for `Comp` instructions and how to decode them.
By defining `BaseCompInstruction` as a subsort of `StraightLineInstruction`, we
automatically get access to the functionality from the `STRAIGHT-LINE` module in
`../simple-instructions.md`.

Then, note that `Instruction` contains `StraightLineInstruction`, so this
connects the chain all the way up to the `MaybeInstruction` returned by the
decoder.

```k
    syntax StraightLineInstruction ::= BaseCompInstruction
    syntax BaseCompInstruction
        ::= BaseCompOpcode OperandSize RWOperand ROperand

    syntax MaybeInstruction ::= decodeBaseCRR ( Bytes ) [function]

    rule decodeBaseCRR(BS:Bytes) => UnknownInstruction
      requires UnknownOperandSize :=K decodeOperandSize( (BS[0] >>Int 4) &Int 3 )

    rule decodeBaseCRR(BS:Bytes) =>
         #let SIZE:OperandSize = decodeOperandSize( (BS[0] >>Int 4) &Int 3 )
         #in decodeBaseCompOpcode(BS) SIZE
                RegOperand(SIZE,  BS[1] >>Int 5        )
                RegOperand(SIZE, (BS[1] >>Int 2) &Int 7)
                ISize(2)
      requires UnknownOperandSize :/=K decodeOperandSize( (BS[0] >>Int 4) &Int 3 )
```

#### Base CRI Instructions

And now we can easily implement the `CRI` instructions which are very similar.

```k
    syntax MaybeInstruction ::= decodeBaseCRI ( Bytes ) [function]

    rule decodeBaseCRI(BS:Bytes) => UnknownInstruction
      requires UnknownOperandSize  :=K decodeOperandSize( (BS[0] >>Int 4) &Int 3 )

    rule decodeBaseCRI(BS:Bytes) =>
         #let SIZE:OperandSize = decodeOperandSize( (BS[0] >>Int 4) &Int 3 )
         #in decodeBaseCompOpcode(BS) SIZE
             RegOperand(SIZE, BS[1] >>Int 5)
             ImmOperand( 5  , BS[1] &Int 31)
             ISize(2)
      requires UnknownOperandSize :/=K decodeOperandSize( (BS[0] >>Int 4) &Int 3 )
```

#### Base Jump Instructions

These ones have a whole 'nother suite of 16 opcodes, but they all share the
same 9-bit immediate format.

```k
    syntax Instruction ::= BaseJumpInstruction
    syntax BaseJumpInstruction
      ::= BaseJumpOpcode ROperand

    syntax BaseJumpOpcode
      ::= "jcc" Condition
        | "jmp"
        | "jmp_never"
        | decodeBaseJumpOpcode ( Int )   [function]
        | decodeBaseJumpOpcode ( Bytes ) [function]

    rule decodeBaseJumpOpcode(BS:Bytes) => decodeBaseJumpOpcode(BS[0] &Int 15)

    rule decodeBaseJumpOpcode(0 ) => jcc equal
    rule decodeBaseJumpOpcode(1 ) => jcc not-equal
    rule decodeBaseJumpOpcode(2 ) => jcc sign
    rule decodeBaseJumpOpcode(3 ) => jcc not-sign
    rule decodeBaseJumpOpcode(4 ) => jcc carry
    rule decodeBaseJumpOpcode(5 ) => jcc not-carry
    rule decodeBaseJumpOpcode(6 ) => jcc overflow
    rule decodeBaseJumpOpcode(7 ) => jcc not-overflow
    rule decodeBaseJumpOpcode(8 ) => jcc below-equal
    rule decodeBaseJumpOpcode(9 ) => jcc above
    rule decodeBaseJumpOpcode(10) => jcc less
    rule decodeBaseJumpOpcode(11) => jcc greater-equal
    rule decodeBaseJumpOpcode(12) => jcc less-equal
    rule decodeBaseJumpOpcode(13) => jcc greater
    rule decodeBaseJumpOpcode(14) => jmp
    rule decodeBaseJumpOpcode(15) => jmp_never
```

The actual format is extremely simple. The pattern is thus:
```
100DCCCC DDDDDDDD
```

The displacement is split around the opcode for the purposes of simplifying
decoding hardware, which does not really help here.

```k
    syntax MaybeInstruction ::= decodeBaseJmp ( Bytes ) [function]

    rule decodeBaseJmp(BS:Bytes) =>
         decodeBaseJumpOpcode(BS)
         ImmOperand( 9 , ((BS[0] &Int 16) <<Int 4) |Int BS[1] )
         ISize(2)
```



### Execute

* Evaluate the result (of a computation)
* Decide to take a branch, replacing with `jmp` or `jmp_never`

We can split this into two sections. Computations and Jumps.
Then we provide cases for each instruction separately.

It's possible to share some work, and we provide utilities to do so,
but it's most flexible from a semantics standpoint to give semantics to
each operation separately.

#### Computations

All computations need to evaluate both of their operands. However not all of
them want to do it in the same `Signedness` context, so we start by defining
a function to identify the ones that don't use the default.

```k
    syntax Signedness ::= immediateSignedness(BaseCompOpcode) [function, functional]

    rule immediateSignedness(slo #Or in #Or out) => Unsigned
    rule immediateSignedness(_)                  => Signed   [owise]
```

Now we use basically a "heating/cooling" pair of rules to get the values
of the operands for all `BaseCompInstruction`s. We want to leave the operands
themselves around for the arithmetic instructions to give to `#setArithmeticFlags`.

It's important that we `chopTo SIZE` the operands here. If we are given a negative
immediate, we need to ensure that the check for the carry bit (say) doesn't have
to care that the infinite-precision representation of the immediate had the carry
bit already set.

```k
    syntax KItem ::= "#operands" "[" Int "," Int "]"

    rule <k> ((OP:BaseCompOpcode SIZE OPL OPR) #as I):BaseCompInstruction
          => #operands [ chopTo(SIZE, evalOperand(OPL))
                       , chopTo(SIZE, evalOperand(immediateSignedness(OP), OPR))
                       ]
          ~> I
         ...</k>
```

This rule evaluates the operands and puts them above the instruction on the K
cell, whenever the instruction is at the top of the cell (and _only_ at the top).

Now we can individually specify the semantics of each instruction.

Firstly, the `add` instruction. It is quite straightforward: add the operands,
and indicate that the flags must be set.
```k
    rule <k> #operands[LV,RV] ~> add SIZE OPL _OPR => #let RES = LV +Int RV
         #in (#writeWOperand(OPL, RES)
          ~> #setArithmeticFlags( SIZE
                                , RES
                                , isNegative(SIZE,LV)
                                , isNegative(SIZE,RV)
                                ))
         ...</k>
```

We can implement `sub` in terms of `cmp` and then implement `rsub` in terms
of `sub`. We can't
re-use the `add` rules because of the fixed-width semantics; the signs need
to be considered _before_ the "add 1" of 2's complement negation.

However, we can use the fact that `cmp` already handles the complexity
of subtraction flag logic and just throw the result-writeback on top of that.

```k
    rule <k> #operands[LV,RV] 
          ~> (sub => cmp) _SIZE OPL _OPR 
          ~> (. => #writeWOperand(OPL, LV -Int RV))
         ...</k>

    rule <k> #operands[LV => RV, RV => LV] ~> (rsub => sub) _SIZE _OPL _OPR ...</k>
```

`cmp`, however, does not store its result, so we specify its semantics separately.

```k
    rule <k> #operands[LV,RV] ~> cmp SIZE _ _
          => #setArithmeticFlags( SIZE
                                , LV +Int chopTo(SIZE, ~Int RV) +Int 1
                                , isNegative(SIZE, LV)
                                , isNegative(SIZE, ~Int RV)
                                )
          ~> #carryToBorrow
         ...</k>

    syntax KItem ::= "#carryToBorrow"
    rule <k> #carryToBorrow => . ...</k>
         <carry> C => notBool C </carry>
```

Now for logical operations. These all look similar to `add`, and they encompass
more or less the same idea.
```k
    rule <k> #operands[LV,RV] ~> or SIZE OPR _
          => #let RES = LV |Int RV #in
             (#writeWOperand(OPR, RES) ~> #setLogicalFlags(SIZE, RES))
         ...</k>

    rule <k> #operands[LV,RV] ~> xor SIZE OPR _
          => #let RES = LV xorInt RV #in
             (#writeWOperand(OPR, RES) ~> #setLogicalFlags(SIZE, RES))
         ...</k>

    rule <k> #operands[LV,RV] ~> and SIZE OPR _
          => #let RES = LV &Int RV #in
             (#writeWOperand(OPR, RES) ~> #setLogicalFlags(SIZE, RES))
         ...</k>

    rule <k> #operands[LV,RV] ~> test SIZE _ _
          => #setLogicalFlags(SIZE, LV &Int RV)
         ...</k>
```

The base data moves are either simple memory loads/stores or basic `mov`.

When `load` gets its address from a register, we have to ensure that we
take the full-width register even when the operand size is smaller. This
special case is very isolated in the ETC.A semantics, as it is isolated
to base+sizes. The general case of memory access happens via memory modes,
and the process of evaluating address operands will use the full-width
registers in general.

```k
    rule <k> #operands[_LV,RV] ~> mov SIZE OPL _
          => #writeWOperand(OPL, sextFrom(SIZE,RV))
         ...</k>

    rule <k> #operands[_LV,RV] ~> store SIZE RegOperand(_,RID) _
          => Mem[Reg[RID] : SIZE] = RV
         ...</k>
  //-------------------------------------------------------------
    rule <k> #operands[_,_] ~> load SIZE OPL RegOperand(_,RID)
          => #writeWOperand(OPL, Mem[Reg[RID] : SIZE])
         ...</k>

    rule <k> #operands[_,ADDR] ~> load SIZE OPL _
          => #writeWOperand(OPL, Mem[ADDR : SIZE])
         ...</k>
```

`slo` is special... and weird. For one, it only allows immediate modes.
And the semantics are just a strange combination of operations. But this is
what was needed to allow building bigger immediates. Oh well.

```k
    rule <k> #operands[LV,RV] ~> slo _ OPL _
          => #writeWOperand(OPL, (LV <<Int 5) |Int RV)
         ...</k>
```

The LSB of the `in/out` command port number is used to determine if it is
an I/O port or a control register. For the moment, all I/O happens on
stdin and stdout, but in the future `ketc` will be configurable to connect
the ports to arbitrary files.

```k
    rule <k> #operands[_,RV] ~> in _ OPL _
          => #writeWOperand(OPL, INPUT)
         ...</k>
         <in> ListItem(INPUT:Int) => .List ...</in>
      requires RV &Int 1 ==Int 1

    rule <k> #operands[_,RV] ~> in _ OPL _
          => #writeWOperand(OPL, Reg[controlRegFromNum(RV >>Int 1)])
         ...</k>
      requires RV &Int 1 ==Int 0
```
```k
    rule <k> #operands[LV,RV] ~> out _ _ _ => . ...</k>
         <out>... .List => ListItem(LV) </out>
      requires RV &Int 1 ==Int 1

    rule <k> #operands[LV,RV] ~> out _ _ _
          => Reg[controlRegFromNum(RV >>Int 1)] = LV
         ...</k>
      requires RV &Int 1 ==Int 0
```

#### Jumps

To implement jumps, we will rewrite (contextually, based on the current flags)
the conditional jump instructions into unconditional `jmp` or `jmp_never`
instructions, then execute those.

```k
    syntax BaseJumpOpcode ::= decideBranch ( BaseJumpOpcode ) [function, functional]

    rule decideBranch(jcc J) => jmp       requires         condition(J)
    rule decideBranch(jcc J) => jmp_never requires notBool condition(J)
    rule decideBranch( J )   => J         [owise]
```

We want to rewrite a jump instruction as long as it is not `jmp` or `jmp_never`.

```k
    rule <k> (jcc _ #as OP => decideBranch(OP)) _OFFSET ISize(_) ...</k>
```

To execute an unconditional jump, we apply its signed offset to the program counter.
The exception is iff the offset is 0, in which case this is the encoding of a halt.

```k
    rule <k> jmp ImmOperand(_WIDTH, 0)  ISize(_)
          => #halt "Halted successfully!"
         ...</k>
    rule <k> jmp ImmOperand(WIDTH, OFF) ISize(_) => . ...</k>
         <pc> PC => PC +Int sextFrom(WIDTH, OFF) </pc>        [owise]
```

To implement an uncondition never-jump, we bump the program counter by its size.

```k
    rule <k> jmp_never _ ISize(N) => . ...</k>
         <pc> PC => PC +Int N </pc>
```

And that's it!

```k
endmodule
```
