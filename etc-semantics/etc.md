# ETC.A Simulator

```k
requires "etc-types.md"

module ETC
  imports ETC-TYPES
```

## Configuration

The configuration contains all the machine-state information about the hypothetical
ETC.A machine. This includes supported and enabled extensions (configurable),
registers, memory, the program counter, flags, and the I/O streams for K.

```k
    configuration
      <etc>
        <k> load $PGM:Bytes ~> #fetch </k>
        <pc> 32768 /* 0x8000 */:Int </pc>
        <registers>
          makeRegisters(8):Registers
        /*
          <register multiplicity="*" type="Map">
            <reg-id> 0:Int </reg-id>
            <value>  0:Int </value>
          </register>
        */
        </registers>
        <memory> .Memory </memory>
        <flags>
          <carry>    false:Bool </carry>
          <zero>     false:Bool </zero>
          <negative> false:Bool </negative>
          <overflow> false:Bool </overflow>
        </flags>
        <machine-details>
          <cpuid> 0:Int </cpuid>
          <exten> 0:Int </exten>
          <reg-width> word:ByteSize </reg-width>
          <reg-count> 8:Int </reg-count>
          <evil-mode> false:Bool </evil-mode>
        </machine-details>
        <in color="magenta" stream="stdin"> .List </in>
        <out color="Orchid" stream="stdout"> .List </out>
      </etc>
```

The "program" for a simulation loads a program, and starts the simulation.

```k
    syntax EtcSimulation ::= ".EtcSimulation"
                           | EtcCommand EtcSimulation

    rule <k> .EtcSimulation => . ... </k>
    rule <k> ETC ETS:EtcSimulation => ETC ~> ETS ... </k>
  //-----------------------------------------------------

    syntax EtcCommand ::= "load" Bytes

    rule <k> load P => . ... </k>
         <memory> MEM => MEM[32768 /* 0x8000 */ := P] </memory>
  //---------------------------------------------------------------------
```

Another idea for the configuration is to use a multiplicity="\*" cell for
registers, which would probably want something like this for
initialization. The number of registers would depend on `cpuid`.

```
/*
    syntax KItem ::= #makeRegisters ( Int )
    
    rule <k> #makeRegisters(N => (N -Int 1)) ...</k>
         (.Bag =>
         <register>
           <reg-id> N </reg-id>
           <value>  0 </value>
         </register>)
      requires N >=Int 0
    rule <k> #makeRegisters(N) => . ...</k>
      requires N <Int 0
*/
```

Now we describe the execution cycle. Because future extensions will make
instructions variable-width, we can't really bump the program counter
when we fetch. Even worse, relative jump instructions need to know the
value of the program counter at the base of the instruction.

As a solution, we leave the program counter unchanged while executing the
FDE cycle of each instruction. Each instruction knows how many bytes long it
was (cached in the instruction by the decoder). At the end, we insert a
`#pc [ Instruction ]` step which updates the program counter for the next
instruction.

Particularly complex instructions can decode their `#exec` into
micro-ops much as a real processor would. This enables us to specify
one operation as a combination of others. For example, one such rule
in the future will likely look like this:
```
    rule <k> #exec [ movz(DST,SRC) ]
          => #exec [ movs(DST,SRC) ] ~> #exec [ zext(DST) ]
         ...</k>
```

Note that the above code block does not have a `k` markdown selector, and so
it is ignored by the K compiler.

The idea is going to be to overfetch, fetching
(hopefully) enough bytes to contain the whole instruction,
and then trim it back later.
If we discover that we need _more_ bytes, the decoder
can grab more.

instructions will store their size so that they know
how far to push the instruction pointer (assuming no jump).
But a SizedInstruction and a raw Instruction are separate,
because #exec decoding as described above introduces
synthetic instructions with no meaningful size.

`#retire` doesn't technically need to keep the whole instruction around.
However, it aids debugging if stuck configurations show the entire instruction
being executed when possible, so we hold onto it.

```k
    syntax KItem ::= "#fetch"
                   | "#decode"    "[" Bytes "]"
                   | "#exec"      "[" SizedInstruction "]"
                   | "#retire"    "[" SizedInstruction "," Int "]" // operation result, if relevant
//                   | "#pc"        "[" SizedInstruction "]"
                   | "#halt" String

    rule <k> #halt _MSG ~> (_ => .) ...</k>
```

Instructions can have zero, one, or two operands. At the moment we only have
instructions with one or two. Each operand is either a register or an immediate
and each instruction has an operand size. For base, the operand size is
always `word`.

```k
    syntax Operand ::= RegOperand(RegisterID)
                     | ImmOperand(ImmWidth, Int)
    syntax ImmWidth = Int
    syntax OperandSize = ByteSize

    syntax Instruction ::= BaseJumpOpcode Operand
                         | BaseCompOpcode OperandSize Operand Operand
                         | "UnknownInstruction"
    syntax SizedInstruction 
        ::= Instruction InstructionSize
    syntax InstructionSize ::= ISize( Int ) | "NoSize"
  //--------------------------------------------------------------------------

    syntax Opcode ::= instructionOpcode ( Instruction ) [function, functional]
    rule instructionOpcode(J:BaseJumpOpcode _)     => J
    rule instructionOpcode(C:BaseCompOpcode _ _ _) => C
    rule instructionOpcode(UnknownInstruction)     => UnknownOpcode
```

Opcode names are the opcode codenames in the ISA spec, _not_ the mnemonics
from the assembly. We don't want to try and reconstruct the input assembly,
because we don't care that much. Decoding is not disassembling for us!

```k
    syntax Opcode ::= BaseCompOpcode | BaseJumpOpcode
                    | "UnknownOpcode"

    syntax BaseJumpOpcode
        ::= "je" | "jne" // (not) equal          : Z
          | "js" | "jns" // (not) sign           : N
          | "jb" | "jae" // below / above-equal  : C
          | "jv" | "jnv" // (not) overflow       : V
          | "jbe" | "ja" // below-equal / above  : C | Z
          | "jl" | "jge" // less / greater-equal : N != V
          | "jle" | "jg" // less-equal / greater : Z | (N != V)
          | "jmp"        // jump always          : 1
          | "jmp_never"  // ...                  : 0

    syntax BaseCompOpcode
        ::= "add"
          | "sub"
          | "rsub"
          | "cmp"
          | "or"
          | "xor"
          | "and"
          | "test"
          //
          | "mov"
          | "load"
          | "store"
          | "slo"
          //
          | "in"
          | "out"

    syntax FlagClass
        ::= "ArithmeticFlags"
          | "LogicalFlags"
          | "NoFlags"
          | opcode2FlagClass ( Opcode ) [function, functional]

    rule opcode2FlagClass(add)  => ArithmeticFlags
    rule opcode2FlagClass(sub)  => ArithmeticFlags
    rule opcode2FlagClass(rsub) => ArithmeticFlags
    rule opcode2FlagClass(cmp)  => ArithmeticFlags
    rule opcode2FlagClass(or)   => LogicalFlags
    rule opcode2FlagClass(xor)  => LogicalFlags
    rule opcode2FlagClass(and)  => LogicalFlags
    rule opcode2FlagClass(test) => LogicalFlags
    
    rule opcode2FlagClass( _:BaseCompOpcode ) => NoFlags [owise]
    rule opcode2FlagClass( _:BaseJumpOpcode ) => NoFlags
    rule opcode2FlagClass( UnknownOpcode )    => NoFlags

    // take care that this evaluates to `false` on `store` because
    // the result is not stored in a register.
    syntax Bool ::= storesResult ( Opcode ) [function, functional]
                  | flipCarry ( Opcode )    [function, functional]

    rule storesResult(cmp #Or test #Or store #Or out) => false
    rule storesResult( _:BaseCompOpcode ) => true [owise]
    rule storesResult( _:BaseJumpOpcode ) => false
    rule storesResult( UnknownOpcode )    => false
    
    rule flipCarry(cmp #Or sub #Or rsub) => true
    rule flipCarry( _ ) => false [owise]
```

## Execution Cycle

### Fetch

The first step in the execution cycle is to fetch bytes for the next instruction.
At the moment, all instructions are 2 bytes, but in the future we will want to
overfetch bytes so that the decoder doesn't have to grab extras.

Fetching does not modify the program counter. We keep the program counter
unchanged to ease the `#pc` step of jump instructions, which (in base) are
always PC-relative.

```k
    rule <k> #fetch => #decode [ #range(MEM, PC, word) ] ...</k>
         <memory> MEM </memory>
         <pc> PC </pc>
```

### Decode

Now the goal is to decode the instruction so that we can `#exec` it.

```k
    rule <k> #decode [ BS:Bytes ] => #exec [ decode(BS) ] ...</k>
```

The first step is to uncover the instruction format (to the first approx)
and then pass that to a more detailed decoder. In the future, the first step
will be to uncover prefixes.

Data types are cheap, so we start by specifying the instruction formats.
```k
    syntax InstructionFormat
        ::= "BaseRegReg"
          | "BaseRegImm"
          | "BaseJmp"
          | "BaseReserved"
          | decodeFormat ( Bytes ) [function, functional]

    rule decodeFormat(BS) => BaseRegReg
      requires BS[0] >>Int 6 ==Int 0
    rule decodeFormat(BS) => BaseRegImm
      requires BS[0] >>Int 6 ==Int 1
    rule decodeFormat(BS) => BaseJmp
      requires BS[0] >>Int 6 ==Int 2
    rule decodeFormat(BS) => BaseReserved
      requires BS[0] >>Int 6 ==Int 3
```

For now we ignore the size bits, but that should go here.

```k
    // decode size bits
    syntax OperandSize ::= decodeOperandSize ( Bytes ) [function] //,functional]

    rule decodeOperandSize(BS) => half
      requires (BS[0] >>Int 4) &Int 3 ==Int 0
    rule decodeOperandSize(BS) => word
      requires (BS[0] >>Int 4) &Int 3 ==Int 1
```

The last feature of the first byte to extract is the opcode. This, of course,
depends on the format. A `#Or` pattern is a K builtin (directly from Matching
Logic, in fact). It matches if either of its argument patterns match.

```k
    syntax Opcode ::= decodeOpcode ( Bytes , InstructionFormat ) [function, functional]
                    | baseCompOpcode ( Int )                     [function, functional]
                    | baseJumpOpcode ( Int )                     [function, functional]

    rule decodeOpcode(BS, BaseRegReg #Or BaseRegImm) => baseCompOpcode(BS[0] &Int 15)
    rule decodeOpcode(BS, BaseJmp)                   => baseJumpOpcode(BS[0] &Int 15)
    rule decodeOpcode(_ , _      )                   => UnknownOpcode [owise]

    rule baseCompOpcode(0 ) => add
    rule baseCompOpcode(1 ) => sub
    rule baseCompOpcode(2 ) => rsub
    rule baseCompOpcode(3 ) => cmp
    rule baseCompOpcode(4 ) => or
    rule baseCompOpcode(5 ) => xor
    rule baseCompOpcode(6 ) => and
    rule baseCompOpcode(7 ) => test
    rule baseCompOpcode(8 ) => UnknownOpcode
    rule baseCompOpcode(9 ) => mov
    rule baseCompOpcode(10) => load
    rule baseCompOpcode(11) => store
    rule baseCompOpcode(12) => slo
    rule baseCompOpcode(13) => UnknownOpcode
    rule baseCompOpcode(14) => in
    rule baseCompOpcode(15) => out
    rule baseCompOpcode(OP) => UnknownOpcode
      requires notBool #range(0 <= OP <= 15)

    rule baseJumpOpcode(0 ) => je
    rule baseJumpOpcode(1 ) => jne
    rule baseJumpOpcode(2 ) => js
    rule baseJumpOpcode(3 ) => jns
    rule baseJumpOpcode(4 ) => jb
    rule baseJumpOpcode(5 ) => jae
    rule baseJumpOpcode(6 ) => jv
    rule baseJumpOpcode(7 ) => jnv
    rule baseJumpOpcode(8 ) => jbe
    rule baseJumpOpcode(9 ) => ja
    rule baseJumpOpcode(10) => jl
    rule baseJumpOpcode(11) => jge
    rule baseJumpOpcode(12) => jle
    rule baseJumpOpcode(13) => jg
    rule baseJumpOpcode(14) => jmp
    rule baseJumpOpcode(15) => jmp_never
    rule baseJumpOpcode(OP) => UnknownOpcode
      requires notBool #range(0 <= OP <= 15)
```

Now, using the format bits, we want to decode the operand byte(s).

These probably need an `OperandSize` in the future, but maybe not. Perhaps
`#exec` can be responsible for chopping appropriately as it does depend a bit
on the instruction, I think.

```k
    syntax Operand
        ::= decodeFstOperand ( Bytes , InstructionFormat ) [function]
          | decodeSndOperand ( Bytes , InstructionFormat ) [function]

    rule decodeFstOperand(BS, BaseRegReg #Or BaseRegImm) => RegOperand(BS[1] >>Int 5)
    rule decodeFstOperand(BS, BaseJmp)                   => ImmOperand( 9 , -256 |Int BS[1] )
      requires bit(4, BS[0]) // displacement sign bit
    rule decodeFstOperand(BS, BaseJmp)                   => ImmOperand( 9 , BS[1] )
      requires notBool bit(4, BS[0]) // displacement sign bit

    rule decodeSndOperand(BS, BaseRegReg) => RegOperand((BS[1] >>Int 2) &Int 7)
    rule decodeSndOperand(BS, BaseRegImm) => ImmOperand( 5 , BS[1] &Int 31 )
```

Finally, we want to put things together under a single `decode` function.
* Get the format
* Get the size and opcode
* Use opcode information to extract correct number of operands
* Assemble the Instruction

```k
    syntax SizedInstruction
        ::= decode ( Bytes )                                            [function, functional]
    syntax Instruction
        ::= decode ( Bytes , InstructionFormat )                        [function, functional]
          | decode ( Bytes , InstructionFormat , OperandSize , Opcode ) [function, functional]

    rule decode(BS) => decode(BS, decodeFormat(BS)) ISize(2)
  //-------------------------------------------------------------------

    rule decode(BS, FMT) =>
         decode(BS, FMT, decodeOperandSize(BS), decodeOpcode(BS, FMT))
  //-------------------------------------------------------------------

    rule decode(BS, FMT, _SIZE, OP:BaseJumpOpcode)
         => OP decodeFstOperand(BS, FMT)
    rule decode(BS, FMT,  word #as SIZE, OP:BaseCompOpcode)
         => OP SIZE decodeFstOperand(BS, FMT) decodeSndOperand(BS, FMT)
    
    rule decode(_, _, _, _) => UnknownInstruction [owise]
```

### Execute

* Evaluate the result (of a computation)
* Decide to take a branch, replacing with `jmp` or `jmp_never`

We can split this into two sections. Computations and Jumps.
Then we provide cases for each instruction separately.

It's possible to share some work, and we provide utilities to do so,
but it's most flexible from a semantics standpoint to give semantics to
each operation separately. 

#### Utilities

`evalOperand` evaluates an `Operand` to its value in the current execution
context. At the moment, it's always either a register or an immediate.
Signedness is only considered for immediates, which must be extended according
to the instruction semantics. If a Signedness isn't given, it defaults to
`Signed`.

```k
    syntax Int ::= evalOperand ( Operand )              [function]
                 | evalOperand ( Signedness , Operand ) [function]
                 | evalInstruction ( Instruction )      [function]

    // considering the current processor flags, decide whether or not
    // to take a branch. If it's taken, replace the opcode with `jmp`.
    // If it's not taken, replace it with `jmp_never`.
    syntax BaseJumpOpcode ::= decideBranch ( BaseJumpOpcode ) [function]

    rule evalOperand(OP) => evalOperand(Signed, OP)

    rule evalOperand(       _, RegOperand(RID))        => Reg[RID]
    rule evalOperand(  Signed, ImmOperand(WIDTH, IMM)) => sextFrom(WIDTH, IMM)
    rule evalOperand(Unsigned, ImmOperand(WIDTH, IMM)) => zextFrom(WIDTH, IMM)
  //--------------------------------------------------------------------------

    syntax Int ::= negUInt ( OperandSize , Int ) [function, functional]
    rule negUInt ( S , I ) => zextFrom(S, ~Int I) +Int 1
```

#### Type Dispatch

Dispatching based on opcode type to some different evaluators helps alleviate
some of the tension of (mostly) giving each instruction separate semantics.

For example, jumps never need to do math in the `#exec` stage

```k
    rule <k> #exec   [ (_:BaseCompOpcode _OSIZE _OPL _OPR #as I) _SIZE #as SI ] =>
             #retire [ SI , evalInstruction ( I ) ] ...</k>

    rule <k> #exec   [ jmp ImmOperand( _ , 0 ) _SIZE ]  => #halt "halted successfully!" ...</k>
    rule <k> #exec   [ J:BaseJumpOpcode OP SIZE ] =>
             #retire [ decideBranch(J) OP SIZE , evalOperand(OP) ] ...</k> [owise]

    rule <k> #exec [ UnknownInstruction _SIZE ] => #halt "Unknown Instruction!" ...</k>
```

#### Computations

```k
    rule evalInstruction(add _OSIZE OPL OPR) =>
         evalOperand(OPL) +Int evalOperand(OPR)

    rule evalInstruction(sub OSIZE OPL OPR) =>
         evalOperand(OPL) +Int negUInt(OSIZE, evalOperand(OPR))

    rule evalInstruction(rsub OSIZE OPL OPR) =>
         evalOperand(OPR) +Int negUInt(OSIZE, evalOperand(OPL))

    rule evalInstruction(cmp OSIZE OPL OPR) =>
         evalOperand(OPL) +Int negUInt(OSIZE, evalOperand(OPR))

    rule evalInstruction(or _OSIZE OPL OPR) =>
         evalOperand(OPL) |Int evalOperand(OPR)

    rule evalInstruction(xor _OSIZE OPL OPR) =>
         evalOperand(OPL) xorInt evalOperand(OPR)

    rule evalInstruction(and _OSIZE OPL OPR) =>
         evalOperand(OPL) &Int evalOperand(OPR)

    rule evalInstruction(test _OSIZE OPL OPR) =>
         evalOperand(OPL) &Int evalOperand(OPR)

    rule evalInstruction(mov _OSIZE _OPL OPR) =>
         evalOperand(OPR)

    // read OSIZE many bytes, but interpret the pointer as being
    // REG-WIDTH in size.
    // This will be relevant once `evalOperand` takes an `OperandSize`.
    rule evalInstruction(load OSIZE _OPL OPR) =>
         Mem[evalOperand(OPR) : OSIZE]

    rule evalInstruction(store _OSIZE _OPL OPR) =>
         evalOperand(OPR)

    rule evalInstruction(slo _OSIZE OPL OPR) =>
         (evalOperand(OPL) <<Int 5) |Int evalOperand(Unsigned, OPR)

    // Not implemented yet
    //rule evalInstruction((in #Or out) _OSIZE _OPL _OPR)
```

#### Jumps

```k
    rule decideBranch(J) => jmp       requires         brTaken(J)
    rule decideBranch(J) => jmp_never requires notBool brTaken(J)
  //-------------------------------------------------------------

    syntax Bool ::= brTaken ( BaseJumpOpcode ) [function, functional]

    rule [[ brTaken(je)  => Z ]]
         <zero> Z </zero>
    rule brTaken(jne) => notBool brTaken(je)

    rule [[ brTaken(js)  => N ]]
         <negative> N </negative>
    rule brTaken(jns) => notBool brTaken(js)

    rule [[ brTaken(jb)  => C ]]
         <carry> C </carry>
    rule brTaken(jae) => notBool brTaken(jb)

    rule [[ brTaken(jv)  =>         V ]]
         <overflow> V </overflow>
    rule brTaken(jnv) => notBool brTaken(jv)

    rule [[ brTaken(jbe) => C orBool Z ]]
         <carry> C </carry>
         <zero>  Z </zero>
    rule brTaken(ja) => notBool brTaken(jbe)

    rule [[ brTaken(jl)  => N =/=Bool V ]]
         <negative> N </negative>
         <overflow> V </overflow>
    rule brTaken(jge) => notBool brTaken(jl)

    rule [[ brTaken(jle) => Z orBool (N =/=Bool V) ]]
         <zero>     Z </zero>
         <negative> N </negative>
         <overflow> V </overflow>
    rule brTaken(jg) => notBool brTaken(jle)

    rule brTaken(jmp)       => true
    rule brTaken(jmp_never) => false
```

### Retire

* Write the result into the destination (none/register/memory)
* Set flags according to the FlagClass of the opcode and the result
* Advance the program counter

```k
    syntax KItem ::= "#retireWB"    "[" Instruction      "," Int "]"
                   | "#retireFlags" "[" Instruction      "," Int "]"
                   | "#retirePC"    "[" SizedInstruction "," Int "]"

    rule <k> #retire [ I SIZE , RES ] =>
                #retireWB    [ I      , RES ]
             ~> #retireFlags [ I      , RES ]
             ~> #retirePC    [ I SIZE , RES ]
             ~> #fetch
         ...</k>
  //---------------------------------------------------------------

    rule <k> #retireWB [ store OSIZE OPL _OPR , RES ] =>
             Mem[evalOperand(OPL) : OSIZE ] = RES ...</k>

    rule <k> #retireWB [ OP OSIZE RegOperand(RID) _OPR , RES ] =>
             Reg[RID] = chopTo(OSIZE, RES)
         ...</k>
      requires storesResult(OP)

    rule <k> #retireWB [ _ , _ ] => . ...</k> [owise]
  //---------------------------------------------------------------

    rule <k> #retireFlags [ OP OSIZE _OPL _OPR , RES ] => . ...</k>
         <flags>
            <zero>     _ => chopTo(OSIZE, RES)  ==Int 0 </zero>
            <negative> _ => sextFrom(OSIZE, RES) <Int 0 </negative>
            <carry>    _                                </carry>
            <overflow> _                                </overflow>
         </flags>
      requires LogicalFlags :=K opcode2FlagClass(OP)

    rule <k> #retireFlags [ OP OSIZE _OPL _OPR , RES ] => . ...</k>
         <flags>
            <zero>     _ => chopTo    (OSIZE, RES) ==Int 0 </zero>
            <negative> _ => sextFrom  (OSIZE, RES)  <Int 0 </negative>
            <carry>    _ =>
                    flipCarry(OP) xorBool carried(OSIZE, RES) </carry>
            <overflow> _ => overflowed(OSIZE, RES)         </overflow>
         </flags>
      requires ArithmeticFlags :=K opcode2FlagClass(OP)

    rule <k> #retireFlags [ I , _ ] => . ...</k>
      requires NoFlags :=K opcode2FlagClass(instructionOpcode(I))
  //---------------------------------------------------------------

    rule <k> #retirePC [ jmp _OP _SIZE , SIGNEDDISP ] => . ...</k>
         <pc> PC => PC +Int SIGNEDDISP </pc> [priority(49)]
    rule <k> #retirePC [ _ ISize(N) , _ ] => . ...</k>
         <pc> PC => PC +Int N </pc>
    rule <k> #retirePC [ _ NoSize   , _ ] => . ...</k>
```


## EDSL for Reg/Mem Reads/Writes

When performing an operation, we need to access registers and memory
for both reading and writing. Here we implement a tiny EDSL with standard
semantic syntax for these things.

```k
    syntax Int ::= "Mem" "[" Int ":" ByteSize "]" [function]
                 | "Reg" "[" RegisterID "]"  [function]

    rule [[ Mem [ ADDR : WIDTH ]
         => Bytes2Int(#range(MEM, ADDR, WIDTH), LE, Unsigned) ]]
         <memory> MEM </memory>
         <reg-width> RSIZE </reg-width>
      requires #rangeByteSize(RSIZE, ADDR)

    rule [[ Reg [ RID ] => RS[RID] ]]
         <registers> RS </registers>
         <reg-count> RCOUNT </reg-count>
      requires #range(0 <= RID < RCOUNT)
```

That lets us read memory and registers with a K function. We should also be able to
_write_ the memory and registers with the same syntax. These cannot be functions.

```k
    syntax KItem ::= "Mem" "[" Int ":" ByteSize "]" "=" Int
                   | "Reg" "[" RegisterID "]" "=" Int

    rule <k> Mem[ADDR : WIDTH] = R => . ...</k>
         <memory> MEM => MEM [ ADDR := Int2Bytes(ByteSize2NumBytes(WIDTH), R, LE) ] </memory>
         <reg-width> RSIZE </reg-width>
      requires #rangeByteSize(RSIZE, ADDR)
    
    rule <k> Reg[RID] = R => . ...</k>
         <registers> RS => RS [ RID <- R ] </registers>
         <reg-count> RCOUNT </reg-count>
      requires #range(0 <= RID < RCOUNT)
```
```k
endmodule
```
