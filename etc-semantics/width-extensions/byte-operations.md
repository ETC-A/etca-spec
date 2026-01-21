# Byte Operations

For the specification of this extension, see the `/extensions/byte-operations` folder.

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

This extension gets bit `CP1.3`.

```k
    rule bit2Extension(CP1.3) => ByteOperations
    rule extension2Bit(ByteOperations) => CP1.3
```

This extension does not depend on any other extensions.

```k
    rule extensionDependsOn(ByteOperations) => .List
```

Nothing happens when this extension is initialized.

# Base Hooks

The relevant hook into `base` is for decoding the operand size.
All we need to do is tell `base` how to decode `byte` size bits.

```k
    rule decodeOperandSize(0) => half
      requires checkExtension(ByteOperations)
```

That is literally it.

```k
endmodule
```