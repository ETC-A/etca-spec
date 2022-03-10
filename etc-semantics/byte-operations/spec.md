# Byte Operations

For the specification of this extension, see the `/byte-operations` folder.

# Extension Hooks

```k
module BYTE-OPERATIONS
    imports private ETC
    imports private BASE
    imports EXTENSION
```

The constructor used to identify this extension doesn't really matter. We
choose a descriptive name :)

```k
    syntax EtcExtension ::= "ByteOperations"
```

This extension gets bit 4.

```k
    rule bit2Extension(4) => ByteOperations
    rule extension2Bit(ByteOperations) => 4
```

This extension does not depend on any other extensions.

```k
    rule extensionDependsOn(ByteOperations) => .List
```

This extension cannot be disabled and is on by default.

```k
    rule extensionCanToggle(ByteOperations) => false
    rule extensionDefault  (ByteOperations) => true
```

# Base Hooks

The relevant hook into `base` is for decoding the operand size.
All we need to do is tell `base` how to decode `byte` size bits.

```k
    rule decodeOperandSize(0) => half
      requires checkExtension(ByteOperations)
```

# New Instruction

The extension defines a new instruction, `movz`, which behaves by moving
its argument to the destination operand and zero-extending it from the operand
width to the full register width.

```k
    syntax BaseCompOpcode ::= "movz"

    rule decode(BS:Bytes) => decodeBaseCRR(BS)
      requires BS[0] &Int 207 ==Int 8  // 00xx1000
       andBool checkExtension(ByteOperations)
    rule decode(BS:Bytes) => decodeBaseCRI(BS)
      requires BS[0] &Int 207 ==Int 72 // 01xx1000
       andBool checkExtension(ByteOperations)

    rule decodeBaseCompOpcode(8) => movz
      requires checkExtension(ByteOperations)

    rule <k> #operands[_LV,RV] ~> movz _ OPL _
          => #writeWOperandZX(OPL, RV)
         ...</k>
```

That is literally it.

```k
endmodule
```