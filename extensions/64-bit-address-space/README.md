# General Design

**Extension State: Under Development**  
**Requires: CP1.15**  
**CPUID Bit: CP1.32**

# Overview

This extension adds a 64-bit addressing mode to the ISA. In particular, this extension focuses on the _Real 64-bit address mode_.

## Real 64-bit Address Mode

A new mode known as _Real 64-bit address mode_ is added, indicated by `MODE[PTRSZ]=2`, `MODE[VM]=0`.

Refer to the [Mode Control Register](../address-modes.md#real-n-bit-address-mode) documentation for how real 64-bit addresses behave in relation to other modes.
