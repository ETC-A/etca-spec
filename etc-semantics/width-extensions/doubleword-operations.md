# Doubleword Operations

For the specification of this extension, see the `/extensions/doubleword-operations` folder.

# Extension Hooks

```k
module DOUBLEWORD-OPERATIONS
    imports private ETC
    imports private BASE
    imports EXTENSION
```

Firstly, specify the extension name.

```k
    syntax EtcExtension ::= "DoublewordOperations"
```

This extension gets bit `CP1.14`.
```k
    rule bit2Extension(CP1.14) => DoublewordOperations
    rule extension2Bit(DoublewordOperations) => CP1.14
```

This extension does not depend on any other extensions.

```k
    rule extensionDependsOn(DoublewordOperations) => .List
```

When we detect this extension during initialization, we set the register
width to doubleword. This extension is initialized before `QuadwordOperations`
since it has a lower bit index, so we always do this even if quadword is
also available. Note that the mode is unchanged; that is not an initialization-time
effect.

```k
    rule <k> #initializeExtension(DoublewordOperations) => . ...</k>
         <reg-width> _ => doubleword </reg-width>
```

# Base Hooks

The relevant hook into `base` is for decoding the operand size.
All we need to do is tell `base` how to decode `doubleword` size bits.

```k
    rule decodeOperandSize(2) => doubleword
      requires checkExtension(DoublewordOperations)
```

That is literally it.

```k
endmodule
```