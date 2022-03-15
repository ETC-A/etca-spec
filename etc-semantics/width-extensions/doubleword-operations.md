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

This extension gets bit 6.

```k
    rule bit2Extension(6) => DoublewordOperations
    rule extension2Bit(DoublewordOperations) => 6
```

This extension does not depend on any other extensions.

```k
    rule extensionDependsOn(DoublewordOperations) => .List
```

This extension can be toggled but is off by default.

```k
    rule extensionCanToggle(DoublewordOperations) => true
    rule extensionDefault  (DoublewordOperations) => false
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

When we enable this extension, we must switch the `<reg-mode>` to `doubleword`
if it is currently less than `doubleword`. If this change is made, we must sign
extend the program counter to maintain the memory address mapping.

```k
    rule <k> #enableExtension(DoublewordOperations) => . ...</k>
         <reg-mode> OLD => doubleword </reg-mode>
         <reg-width> RWIDTH </reg-width>
         <pc> PC => zextFrom(doubleword, sextFrom(OLD, PC)) </pc>
      requires OLD <ByteSize doubleword

    rule <k> #enableExtension(DoublewordOperations) => . ...</k>
         <reg-mode> OLD </reg-mode>
      requires doubleword <=ByteSize OLD
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