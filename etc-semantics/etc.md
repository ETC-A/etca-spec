# ETC.A Simulator

```k
module ETC
  imports ETC-TYPES
  imports private EXTENSION-SYNTAX
```

## Configuration

The configuration contains all the machine-state information about the hypothetical
ETC.A machine. This includes supported and enabled extensions (configurable),
registers, memory, the program counter, flags, and the I/O streams for K.

The `<reg-width>` cell stores the width of a _machine word_ - the widest size that
the registers of the simulated machien can store in any mode. This is determined
by the value of CPUID. The `<reg-mode>` cell stores the current behavioral width.
An ETC.A machine always boots with the `<reg-mode>` set to `word`.

```k
    configuration
      <etc>
        <k parser="PGM, BYTES-SYNTAX">
             #enableDefaultExtensions
          ~> load $PGM:Bytes
          ~> #fetch
        </k>
        <pc format="%1 %2 %3"> 32768 /* 0x8000 */:Int </pc>
        <registers>
          makeRegisters(8):Registers
        </registers>
        <memory> .Memory </memory>
        <flags>
          <carry format="%1    %2 %3"> false:Bool </carry>
          <zero format="%1     %2 %3"> false:Bool </zero>
          <negative format="%1 %2 %3"> false:Bool </negative>
          <overflow format="%1 %2 %3"> false:Bool </overflow>
        </flags>
        <machine-details>
          <cpuid parser="CPUID, INT-SYNTAX"
                 format="%1 %2 %3">
            $CPUID:Int
          </cpuid>
          <exten format="%1 %2 %3"> 0:Int </exten>
          <reg-mode format="%1  %2 %3"> word:ByteSize </reg-mode>
          <reg-width format="%1 %2 %3"> word:ByteSize </reg-width>
          <reg-count format="%1 %2 %3"> 8:Int </reg-count>
          <evil-mode format="%1 %2 %3"> false:Bool </evil-mode>
        </machine-details>
        <in color="magenta" stream="stdin" format="%1 %3"> .List </in>
        <out color="Orchid" stream="stdout" format="%1 %3"> .List </out>
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
         <pc> PC </pc>
         <reg-width> RSIZE </reg-width>
         <reg-mode>  RMODE </reg-mode>
         <memory>
           MEM => MEM[ zextFrom(RSIZE, sextFrom(RMODE, PC)) := P ]
         </memory>
  //----------------------------------------------------------------------
```

## Execution Framework

Now we describe the execution cycle. Because future extensions will make
instructions variable-width, we can't really bump the program counter
when we fetch. Even worse, relative jump instructions need to know the
value of the program counter at the base of the instruction.

As a solution, we leave the program counter unchanged while executing the
FDE cycle of each instruction. Each instruction knows how many bytes long it
was (cached in the instruction by the decoder). At the end, we insert a
`#pc [ Offset ]` step which updates the program counter for the next
instruction. An alternative, `#setPC [ Address ]` can be used for absolute
`PC` changes.

Particularly complex instructions can decode their execution into
micro-ops much as a real processor would. This enables us to specify
one operation as a combination of others. For example, one such rule
in the future will likely look like this:
```
rule <k> movz SIZE DST SRC => movs SIZE DST SRC ~> zext SIZE DST ...</k>
```

Note that the above code block does not have a `k` markdown selector, and so
it is ignored by the K compiler.

The idea is going to be to overfetch, fetching
(hopefully) enough bytes to contain the whole instruction,
and then trim it back later.
If we discover that we need _more_ bytes, the decoder
can grab more.

Decoded instructions must store their size. When defining a new extension
module, there are utilities that you can take advantage of to handle common
patterns. For example, the `StraightLineInstruction` sort from module
`STRAIGHT-LINE` contains this rule, which handles all `PC` updates for the
common case of straight line code:

```
    rule <k> I:StraightLineInstruction ISize(N) => I ~> #pc [ N ] ...</k>
```

By making your new instruction(s) inhabit `StraightLineInstruction`, you get
this rule for free and can focus on the domain logic of the instruction
itself.

Of course, if your instruction is _usually_ straight line, but not always,
you can still use this utility and match on `I ~> #pc [ N ]` later!

## Execution Cycle

Only the most barebones requirements for an execution cycle are defined
here. Utility modules variously provide more features for common functionality.

At its core, an instruction's execution consists of three steps: fetch, decode,
and execute. Some instructions may have complicated result-storing semantics
or complex control flow potential. Such instructions are free to use more
rewrite steps, of course.


```k
    syntax KItem ::= "#fetch"
                   | "#decode" "[" Bytes "]"
                   | "#halt" String

    // Eat the rest of the K cell so that the error message
    // is displayed nicely and without other leftovers.
    // This makes the `#halt` symbol act as HCF.
    rule <k> #halt _MSG ~> (_:KItem ~> _ => .) </k>
```

### Fetch

The first step in the execution cycle is to fetch bytes for the next instruction.
At the moment, all instructions are 2 bytes, but in the future we will want to
overfetch bytes so that the decoder doesn't have to grab extras.

Fetching does not modify the program counter. We keep the program counter
unchanged to ease the `#pc` step of jump instructions, which (in base) are
always PC-relative.

```k
    rule <k> #fetch => #decode [ 
                #range(MEM, zextFrom(RSIZE, sextFrom(RMODE, PC)), word)
             ] ...</k>
         <pc> PC </pc>
         <memory> MEM </memory>
         <reg-width> RSIZE </reg-width>
         <reg-mode>  RMODE </reg-mode>
```

### Decode

Now the goal is to decode the instruction so that we can execute it.

Instructions can be anything, and none are defined here. Instruction modules
should freely and aggressively add constructors and/or subsorts to the `Instruction`
sort for their instructions.

```k
    syntax Instruction
```

A decoded instruction is **required** to mention its size. If, for some reason,
you don't want to keep the size around, you should not make your instruction an
inhabitant of `SizedInstruction` directly. Instead, you should make your
instruction an inhabitant of `UnsizedInstruction`, which will automatically
enable the following rule to trigger (both from `UNSIZED-INSTRUCTION`):
```
/*
    rule <k> (I:UnsizedInstruction _SIZE):SizedInstruction => I ...</k>
*/
```

This rule simply deletes the size from the `<k>` cell. Ensure that the instruction
semantics cause `PC` to get modified, otherwise you will get caught in an infinite
loop! If your instruction is supposed to cause a halt, then this should be
modeled explicitly by rewriting it to `#halt` with some message.

```k
    syntax MaybeInstruction
      ::= "UnknownInstruction"
        | SizedInstruction
        | decode ( Bytes ) [function, functional]

    syntax SizedInstruction 
      ::= Instruction "ISize" "(" Int ")"

    rule <k> #decode [ BS:Bytes ] => decode(BS) ~> #fetch ...</k>

    // priority(400) allows [owise] rules to beat this one!
    // owise == priority(200) and lower priorities win.
    // This way you can still define [owise] rules as long as they have
    // side conditions that meet the responsibility requirement below.
    rule decode ( _:Bytes ) => UnknownInstruction [priority(400)]
    rule <k> UnknownInstruction:MaybeInstruction => #EUnknownInstr ...</k>
```

To hook into the execution cycle, all you need to do is implement the
`decode` function to transform `Bytes` into your instruction (and its size).
If you are not given enough `Bytes`, you can retrieve more; see the `#fetch`
rule above.

Some utility modules require more hooks, but those are not required in general.

You may implement `decode` however you want, except that you **must not** match
any `Bytes` patterns that do not correspond to your instructions. This will
cause your `decode` rules to "steal" those byte patterns from the actual
instructions they correspond to.

There is an exception to the above restriction:
If your instructions explicitly reserve space for a particular purpose
(to be enabled by a different extension), then your instructions _should_ either

* match those reserved patterns and should define or use a utility function to
  decode the reserved sub-patterns so that the relevant extension can hook into
  yours. The size bits in `Base` provide an example of how to do this. If the
  instruction should be treated as unknown (due to mode or extension specification),
  the decoder should explicitly return `UnknownInstruction`. **This still
  terminates the decoding process**, and will cause an `#EUnknownInstr` exception.
* or not match the instruction at all, requiring the other extension to fill in
  the gaps. Note that the other extension can fill in the gaps by using a
  _subsorting hook_ into your extension. If you are able to leave the
  unimplemented part in a sort, the extension can add new constructors and
  evaluation rules for that sort to implement the reserved functionality.
  The operand-mode bits in `Base` provide an example of how to do this.

If it is easy to do so, we recommend implementing the decoder by defining
something like (block ignored by K):
```
    syntax Bool ::= isOneOfMyInstrs ( Bytes ) [function,functional]

    rule decode( BS:Bytes ) => decodeMyInstrs(BS)
      requires isOneOfMyInstrs(BS)
```

Once decoding is isolated to your own domain logic, you no longer have to worry
about being a responsible implementor of `decode`.

## EDSL for Reg/Mem Reads/Writes

When performing an operation, we need to access registers and memory
for both reading and writing. Here we implement a tiny EDSL with standard
semantic syntax for these things.

```k
    syntax Int ::= "Mem" "[" Int ":" ByteSize "]"         [function]
                 | "Reg" "[" RegisterID ":" ByteSize "]"  [function]
                 // this mode always accesses at the full width
                 | "Reg" "[" RegisterID "]"               [function]

    rule [[ Mem [ ADDR : WIDTH ]
         => Bytes2Int
              ( #range(MEM, zextFrom(RSIZE, sextFrom(RMODE, ADDR)), WIDTH)
              , LE
              , Unsigned
              ) 
         ]]
         <memory> MEM      </memory>
         <reg-mode>  RMODE </reg-mode>
         <reg-width> RSIZE </reg-width>
      requires #rangeByteSize(RMODE, ADDR)
  //-------------------------------------------------------------
    
    rule [[ Reg [ RID ] => Reg [ RID : SIZE ] ]]
         <reg-width> SIZE </reg-width>

    rule [[ Reg [ (RID:Int) : SIZE ] => chopTo(SIZE, RS[RID]) ]]
         <registers> RS     </registers>
         <reg-count> RCOUNT </reg-count>
      requires #range(0 <= RID < RCOUNT)

    rule [[ Reg [ CRcpuid : SIZE ] => chopTo(SIZE, CPUID) ]]
         <cpuid> CPUID </cpuid>
    rule [[ Reg [ CRexten : SIZE ] => chopTo(SIZE, EXTEN) ]]
         <exten> EXTEN </exten>

    syntax RegisterID ::= "CRcpuid" | "CRexten"
                        | controlRegFromNum ( Int ) [function]
    rule controlRegFromNum(0) => CRcpuid
    rule controlRegFromNum(1) => CRexten
```

That lets us read memory and registers with a K function. We should also be able to
_write_ the memory and registers with the same syntax. These cannot be functions.

```k
    syntax KItem ::= "Mem" "[" Int ":" ByteSize "]" "=" Int
                   | "Reg" "[" RegisterID ":" ByteSize "]" "=" Int
                   // This always writes to the full width,
                   // useful for getting zero extension
                   | "Reg" "[" RegisterID "]" "=" Int

    rule <k> Mem[ADDR : WIDTH] = R => . ...</k>
         <memory> 
               MEM 
            => MEM [ zextFrom(RSIZE, sextFrom(RMODE, ADDR))
                   := Int2Bytes(ByteSize2NumBytes(WIDTH), R, LE)
                   ] 
         </memory>
         <reg-width> RSIZE </reg-width>
         <reg-mode>  RMODE </reg-mode>
      requires #rangeByteSize(RMODE, ADDR)

    rule [[ Reg [ RID ] => Reg [ RID : SIZE ] ]]
         <reg-width> SIZE </reg-width>
    
    rule <k> Reg [ (RID:Int) : SIZE ] = R => . ...</k>
         <registers> RS => RS [ RID <- sextFrom(SIZE, R) ] </registers>
         <reg-count> RCOUNT </reg-count>
         // <reg-width> RWIDTH </reg-width>
      requires #range(0 <= RID < RCOUNT)

    // CPUID is immutable
    rule <k> Reg [ CRcpuid : _SIZE ] = _R => . ...</k>
    // Writes to EXTEN call out to the `EXTENSION` module, which uses
    // all of the extension hooks to get this right.
    rule <k> Reg [ CRexten : _SIZE ] = R => #writeExten(R) ...</k>
```

## Operands

Operands are not specified here. However, any operand definition must
implement the `evalOperand` utility function, which takes an operand
and whether or not the context is signed and produces the value of the operand.

The ETC.A base operands are defined in `base/spec.md`, in the
`BASE-OPERANDS` module.

```k
    syntax Operand
    syntax Int ::= evalOperand ( Operand )              [function, functional]
                 | evalOperand ( Signedness , Operand ) [function, functional]

    rule evalOperand(OP:Operand) => evalOperand(Signed,OP) [owise]
```

The last rule is marked `[owise]` so that a particular operand constructor
can define its own default rule which takes priority over this one.

```k
endmodule
```
