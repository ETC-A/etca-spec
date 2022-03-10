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
```

That is literally it.

```k
endmodule
```