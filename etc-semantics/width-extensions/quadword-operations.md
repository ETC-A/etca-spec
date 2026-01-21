# Quadword Operations

For the specification of this extension, see the `/extensions/quadword-operations` folder.

# Extension Hooks

```k
module QUADWORD-OPERATIONS
    imports private ETC
    imports private BASE
    imports EXTENSION
```

Firstly, specify the extension name.

```k
    syntax EtcExtension ::= "QuadwordOperations"
```

This extension gets bit `CP1.15`.

```k
    rule bit2Extension(CP1.15) => QuadwordOperations
    rule extension2Bit(QuadwordOperations) => CP1.15
```

This extension does not depend on any other extensions.

```k
    rule extensionDependsOn(QuadwordOperations) => .List
```

When we detect this extension during initialization, we set the register
width to `quadword`.

```k
    rule <k> #initializeExtension(QuadwordOperations) => . ...</k>
         <reg-width> _ => quadword </reg-width>
```

# Base Hooks

The relevant hook into `base` is for decoding the operand size.
All we need to do is tell `base` how to decode `quadword` size bits.

```k
    rule decodeOperandSize(3) => quadword
      requires checkExtension(QuadwordOperations)
```

That is literally it.

```k
endmodule
```