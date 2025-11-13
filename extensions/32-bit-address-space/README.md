# General Design

**Extension State: Under Development**  
**Requires: CP1.14**  
**CPUID Bit: CP1.16**

# Overview

This extension adds a 32-bit addressing mode to the ISA. In particular, this extension focuses on the _Real 32-bit address mode_.

## Real 32-bit Address Mode

A new mode known as _Real 32-bit address mode_ is added, indicated by `MODE[PTRSZ]=1`, `MODE[VM]=0`.

Refer to the [Mode Control Register](../addressing-modes.md#real-n-bit-address-mode) documentation for how real 32-bit addresses behave in relation to other modes.
