# General Design

**Extension State: Under Development**  
**Requires: CP1.14**  
**CPUID Bit: CP1.16**

# Overview

This extension adds a 32-bit addressing mode to the ISA. In particular, this extension focuses on the _Real 32-bit address mode_.

## Real 32-bit Address Mode

A new mode known as _Real 32-bit address mode_ is added, indicated by a value of 2 in `cr17`.

Refer to the [Mode Control Register](../mode-control-register.md) documentation for how real 32-bit addresses behave in relation to other modes.
