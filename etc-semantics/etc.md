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
        <k> $PGM:EtcSimulation </k>
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
        <cpuid> 0:Int </cpuid>
        <exten> 0:Int </exten>
        <evil-mode> false:Bool </evil-mode>

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

    syntax EtcCommand ::= "load" String
                        | "start"

    rule <k> load P => . ... </k>
         <memory> M => M[32768 /* 0x8000 */ := String2Bytes(P)] </memory>
    rule <k> start => /*#makeRegisters(7) ~>*/ #next ... </k>
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
instructions variable-width, 

Particularly complex instructions can decode their `#exec` into
micro-ops much as a real processor would. This enables us to specify
one operation as a combination of others. For example, one such rule
in the future will likely look like this:
```
    rule <k> #exec [ movz(DST,SRC) ]
          => #exec [ movs(DST,SRC) ] ~> #exec [ zext(DST) ]
         ...</k>
```

```k
    syntax KItem ::= "#next"
                   // The idea is going to be to overfetch, fetching
                   // (hopefully) enough bytes to contain the whole instruction,
                   // and then trim it back later.
                   // If we discover that we need _more_ bytes, the decoder
                   // can grab more.
                   | "#fetch" "[" Int "]" // instruction pointer
                   | "#decode" "[" Int ":" Bytes "]"
                   | "#exec" "[" Int ":" Instruction "]"
                   // instructions will store their size so that they know
                   // how far to push the instruction pointer (assuming no jump).
                   | "#pc" "[" Int ":" Instruction "]"
```

Specification of the Instruction sort will come soon.

```k
    syntax Instruction ::= "undef"
```

The remainder of the file is left-overs from the proof-of-concept definition,
which I am leaving here because I suspect parts of the decoding logic will be
useful as I rewrite the definition.

```
  syntax KItem ::= "#cycle"
                 | "#fetch" | "#decode" Byte Byte | "#exec" Instruction
                 | "#halt" String

  rule <k> #cycle => #fetch ~> #cycle ... </k>
  rule <k> #halt _MSG ~> (_ => .) ... </k>

  rule <k> #fetch => #decode P[PC] P[PC +Int 1] ... </k>
       <program-counter> PC => PC +Int 2 </program-counter>
       <program> P </program>
    requires 0 <=Int PC andBool PC <Int lengthBytes(P)
  rule <k> #fetch => #halt "ran off end" ... </k>
       <program-counter> PC </program-counter>
       <program> P </program>
    requires 0 >Int PC orBool PC >=Int lengthBytes(P)

  rule <k> #decode LB UB => #exec decode(LB,UB) ... </k>
  
  syntax Instruction
    ::= decode(Byte, Byte) [function, functional]
      | decodeCompRR(Byte, Byte) [function]
      | decodeCompRI(Byte, Byte) [function]
      | decodeCond(Byte, Byte)   [function]
//----------------------------------------------------------------
  rule decode(LB,UB) => decodeCompRR(LB,UB)
    requires LB &Int 192 ==Int 0
  rule decode(LB,UB) => decodeCompRI(LB,UB)
    requires LB &Int 192 ==Int 64
  rule decode(LB,UB) => decodeCond(LB,UB)
    requires LB &Int 192 ==Int 128
  rule decode(LB,_UB) => Reserved
    requires LB &Int 192 ==Int 192

//----------------------------------------------------------------------
  rule decodeCompRR(LB,UB) => Reserved
    requires LB &Int 48 =/=Int 16
      orBool UB &Int 3  =/=Int 0
  rule decodeCompRR(LB,UB) => opcode(LB){0, extractDest(UB), regOperand(UB)}
    requires LB &Int 48 ==Int 16
     andBool UB &Int 3  ==Int 0
  rule decodeCompRR(_,_) => Reserved [owise]
  
  rule decodeCompRI(LB,_UB) => Reserved
    requires LB &Int 48 =/=Int 16
  rule decodeCompRI(LB,UB) => opcode(LB){1, extractDest(UB), extractImm(LB, UB)}

  syntax RegisterID ::= extractDest(Byte) [function, functional]
//------------------------------------------------------------
  rule extractDest(B) => (B &Int 224) >>Int 5

  syntax Operand ::= regOperand(Byte) [function]
//-----------------------------------------------------------
  rule regOperand(B) => Register ((B &Int 28) >>Int 2)
    requires B &Int 3 ==Int 0

  syntax Operand ::= extractImm(Byte, Byte) [function, functional]
//----------------------------------------------------------------
  rule extractImm(LB,UB) => Immediate signExtendBitRangeInt(UB,0,5)
    requires (LB &Int 15) <Int 12 // sign extend
  rule extractImm(LB,UB) => Immediate bitRangeInt(UB,0,5)
    requires (LB &Int 15) >=Int 12 // zero extend

  syntax String ::= opcode(Int) [function]
//--------------------------------------------------------
  rule opcode(B) => opcode(B &Int 15)
    requires (B &Int 15) =/=Int B

  rule opcode(0)  => "add"
  rule opcode(1)  => "sub"
  rule opcode(2)  => "rsub"
  rule opcode(3)  => "cmp"
  rule opcode(4)  => "xor"
  rule opcode(5)  => "or"
  rule opcode(6)  => "and"
  rule opcode(7)  => "test"
  rule opcode(8)  => "store"
  rule opcode(9)  => "load"
  rule opcode(10) => "mov"
//rule opcode(11) => undefined
  rule opcode(12) => "out"
  rule opcode(13) => "inp"
  rule opcode(14) => "slo"
  rule opcode(15) => "sar"
```

Now we can specify how to execute instructions.

This is a dumb prototype and should NOT be extended in the future.
Rewrite it in a smarter way. Sorry for the debt, I just wanted a proof of concept.

Or, you know, just rewrite this whole thing.

We start with a bit of a helper to reduce duplication. Get the value of
the non-destination operand. Then we can just do a big case for execution.

Now again, I'm just trying to make a proof of concept and a simple prototype,
so the semantics are actually wrong here in a couple places (for now). Flags are always set,
is the biggest incorrect behavior. However CMP and TEST do correctly not write their results.


```
  syntax Operand ::= Int //subsort

  rule <k> #exec Reserved => #halt "reserved instruction" ...</k>
  rule <k> (. => eval(OP, X, IMM)) ~> #exec OP{_, DST, (Immediate IMM => IMM)} ...</k>
       <registers>... DST |-> X ...</registers>
  rule <k> (. => eval(OP, X, Y)) ~> #exec OP{_, DST, (Register RID => Y)} ...</k>
       <registers>... DST |-> X RID |-> Y ...</registers>

  rule <k> R:Int ~> #exec OP{_, DST, Y:Int} => . ...</k>
       <registers>... DST |-> (X => writeResult(X,R,OP)) ...</registers>
       <carry> _ => bitRangeInt(R,16,1) =/=Int 0 </carry>
       <overflow> _ => checkOverflow(X,Y,R) </overflow>
       <zero> _ => R ==Int 0 </zero>
       <negative> _ => checkNegative(R) </negative>
```

We need a couple functions to check the values of the dest/flags after operations:
```
  syntax Int ::= writeResult(Int, Int, String) [function]
//--------------------------------------------
  rule writeResult( OLD, _NEW, OP ) => OLD
    requires OP ==String "cmp" orBool OP ==String "test"
  rule writeResult( _OLD, NEW, OP ) => NEW
    requires notBool (OP ==String "cmp" orBool OP ==String "test")

  syntax Bool ::= checkNegative( Int )         [function]
                | checkOverflow(Int, Int, Int) [function]
//-------------------------------------------------------
  rule checkNegative(R) => bitRangeInt(R,15,1) =/=Int 0
  rule checkOverflow(X,Y,R)
        => (checkNegative(X) ==Bool checkNegative(Y))
           andBool (checkNegative(X) =/=Bool checkNegative(R))
```

And finally, we need to actually perform the operation.

```
  syntax Int ::= eval( String, Int, Int ) [function]
//--------------------------------------------------
  rule eval("add",   X, Y) => X +Int Y
  rule eval("sub",   X, Y) => X -Int Y
  rule eval("rsub",  X, Y) => Y -Int X
  rule eval("cmp",   X, Y) => X -Int Y
  rule eval("xor",   X, Y) => X xorInt Y
  rule eval("or",    X, Y) => X |Int Y
  rule eval("and",   X, Y) => X &Int Y
  rule eval("test",  X, Y) => X &Int Y
//rule eval("store", X, Y) => not implemented
//rule eval("load",  X, Y) => not implemented
  rule eval("mov",   _X, Y) => Y
//rule eval("out",   X, Y) => not implemented
//rule eval("inp",   X, Y) => not implemented
  rule eval("slo",   X, Y) => (X <<Int 5) |Int Y
  rule eval("sar",   X, Y) => signExtendBitRangeInt(X, 0, 16) >>Int Y
```

```k
endmodule
```
