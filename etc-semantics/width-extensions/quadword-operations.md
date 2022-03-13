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

This extension gets bit 6.

```k
    rule bit2Extension(7) => QuadwordOperations
    rule extension2Bit(QuadwordOperations) => 7
```

This extension does not depend on any other extensions.

```k
    rule extensionDependsOn(QuadwordOperations) => .List
```

This extension cannot be disabled and is off by default.

```k
    rule extensionCanToggle(QuadwordOperations) => false
    rule extensionDefault  (QuadwordOperations) => false
```

When we detect this extension during initialization, we set the register
width to `quadword`.

```k
    rule <k> #initializeExtension(QuadwordOperations) => . ...</k>
         <reg-width> _ => quadword </reg-width>
```

When we enable this extension, we must switch the `<reg-mode>` to `quadword`
if it is currently less than `quadword`. If this change is made, we must sign
extend the program counter to maintain the memory address mapping.

Note that `quadword` is almost certainly the largest register width that will
be supported for base operations and even more certainly the largest that will
be supported for the program counter. However, there is no cost to
future-proofing here.

```k
    rule <k> #enableExtension(QuadwordOperations) => . ...</k>
         <reg-mode> OLD => quadword </reg-mode>
         <reg-width> RWIDTH </reg-width>
         <pc> PC => zextFrom(RWIDTH, sextFrom(OLD, PC)) </pc>
      requires OLD <ByteSize quadword

    rule <k> #enableExtension(QuadwordOperations) => . ...</k>
         <reg-mode> OLD </reg-mode>
      requires quadword <=ByteSize OLD
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