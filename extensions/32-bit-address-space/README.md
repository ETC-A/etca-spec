# General Design

**Extension State: Under Development**  
**Requires: CP1.14**  
CPUID Bit: CP1.16**

# Overview

This extension adds a new concept of _modes_ to the ISA. Modes are used to control things about the processor
state which are binary-incompatible - that is, binary code written for a mode other than the mode the
processor is actually in will almost certainly behave incorrectly.

In particular, this extension focuses on the _Real 32-bit address mode_.

# Modes

CR `1111`, equivalently `cr15` or "the MODE control register," holds a value indicating the current
_mode_ of the processor.

## Base Mode

The mode described by [the base isa](../../base-isa.md) is known as the
Base mode. In that mode, pointers are 16 bits and there is no virtual memory, paging, or memory protection.
Base mode is indicated by a value of 0 in `cr15`.

## Real 32-bit Address Mode

A new mode known as _Real 32-bit address mode_ is added, indicated by a value of 2 in `cr15`.
In real 32-bit address mode, all addresses are treated as being 32 bit long. Addresses in Base mode refer to the (real) address which is their sign extension to 32 bits.

Entering real 32-bit
address mode _must_ preserve the program counter. Returning to Base mode from real 32-bit address
mode must preserve the program counter _if possible_ - if the current program counter interpreted
as a 16-bit address would not be the address of the current instruction, the behavior of the
system is _unspecified_.

Program execution starts at (real) address `0xFFFF8000`. This happens naturally due to the Base requirement 
of starting at `0x8000` and the fact that `0x8000` refers to its sign extension to 32-bits.

# Interactions With Other Extensions

Other extensions mention "address modes," in particular when deciding what a particular value
should mean or how many words an immediate should be. The address mode of Real 32-bit Address Mode
is `doubleword`.

(The above language is chosen because other values of the MODE register may also specify
a `doubleword` address mode)

If the system supports [privilege levels](../privileged-mode/), then `cr14` is only writable at the system level.

# Recommendations

This extension does not _require_ behaviors beyond what is specified. However, for compatibility with future
extensions which will require more specifics, the following are recommended:

* The program counter (or equivalent) in the processor itself should always store the sign-
  extended address when operating in Base mode. This way, nothing needs to be done when
  entering or leaving real 32-bit address mode from Base mode.
