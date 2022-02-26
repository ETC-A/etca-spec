We start by aggregating the K modules we want to have for data representations.
```k
module ETC-TYPES
  imports INT
  imports BOOL
  imports COLLECTIONS
```

For now, we're going to use Strings to match mnemonics when we decode.

```k
  imports STRING
```

We want to operate on binary programs, as that is the most cononical form.
We store the program in a Bytes array.
```k
  imports BYTES
```

There are several points where we want to be able to talk about small ints of
specific fixed widths. K wants us to specify which widths we want in advance.
For now, we need 2bit ints for various format/size/mode bit fields, 3 bit ints
for registers, 4 bits for opcodes, and 5 bit ints for immediates.

This is temporarily out-of-use as the builtin MInt type is rarely used
and I appear to have found some bugs with it :P

```k
//  syntax MInt{2}
//  syntax MInt{3}
//  syntax MInt{4}
//  syntax MInt{5}
```

It's useful to be able to talk about individual bytes in a fixed-precision way.

```k
//  syntax MInt{8}
//  syntax Byte = MInt{8}
  syntax Byte = Int
  syntax Int ::= chopByte( Int ) [function, functional, concrete]
  rule chopByte(I) => bitRangeInt(I,0,8)
```

The word size on a base ETC.A machine is 16 bits.
```k
//  syntax MInt{16}
//  syntax Word = MInt{16}
  syntax Word = Int
  syntax Int ::= chopWord( Int ) [function, functional, concrete]
  rule chopWord(I) => bitRangeInt(I,0,16)
```

The program is a byte-addressable Bytes array. This does not quite match the spec
that the code and RAM must share an address space. This is OK for this prototype.
```k
//  syntax Byte ::= Bytes "[" Word "]" [function]
//------------------------------------------------
//  rule P:Bytes [ PC:Word ] => Int2MInt(P[MInt2Unsigned(PC)])
```

For now we just want a prototype, so we store memory as a literal map from addresses to bytes.
```k
  syntax Memory = Map
  syntax Memory ::= Memory "[" Word ":=" Word "]" [function, functional]
//--------------------------------------------------------------------
  rule M [ ADDR := VALUE ] => M [ ADDR <- VALUE ]
endmodule
```

This module describes the behavior of ETC.A machine code.
We operate on the program binary, assembler(s) may be provided in separate
modules in the future.

```k
module ETC
  imports ETC-TYPES
```

The configuration consists of a few components representing the machine state. The program
is in a Bytes array. The registers are stored in a map. The program counter is maintained,
as are the flags. We don't try to use an efficient representation, for now.

```k
  configuration
    <etc>
      <k> $PGM:EtcSimulation </k>
      <program> .Bytes </program>
      <registers>
        0 |-> 0 //p16:Word
        1 |-> 0 //p16:Word
        2 |-> 0 //p16:Word
        3 |-> 0 //p16:Word
        4 |-> 0 //p16:Word
        5 |-> 0 //p16:Word
        6 |-> 0 //p16:Word
        7 |-> 0 //p16:Word
      </registers>
      <program-counter> 0/*p16:Word*/ </program-counter>
      <carry>    false:Bool </carry>
      <zero>     false:Bool </zero>
      <negative> false:Bool </negative>
      <overflow> false:Bool </overflow>
    </etc>
```

When we decode instructions, we need a structure to represent what we're looking at.

```k
//syntax RegisterID = MInt{3}
  syntax RegisterID = Int
  syntax Operand ::= "Register"  RegisterID
                   | "Immediate" Int //MInt{5}

  syntax Format = Int //MInt{2}
  syntax Instruction
    ::= String "{" Format "," RegisterID "," Operand "}"
      | "Reserved"
```

And finally we need some stuff to drive execution with rewrite rules.

```k
  syntax EtcSimulation ::= ".EtcSimulation"
                         | EtcCommand EtcSimulation
//-------------------------------------------------
  rule <k> .EtcSimulation => . ... </k>
  rule <k> ETC ETS:EtcSimulation => ETC ~> ETS ... </k>
  
  syntax EtcCommand ::= "load" String | "start"
//--------------------------------------------
  rule <k> load P => . ... </k>
       <program> _ => String2Bytes(P) </program>
  rule <k> start => #cycle ... </k>
```

Now we describe a simple execution cycle. Fetch, decode, execute.
```k
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


```k
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
```k
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

```k
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
endmodule
```
