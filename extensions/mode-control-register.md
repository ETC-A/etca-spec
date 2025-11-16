# Overview

This document describes the mode control register in a centralized location so that other extensions which use it can refer to a single document
instead of duplicating it between all relevant extensions. The mode control register adds a new concept of _modes_ to the ISA. Modes are used to
control things about the processor state which are binary-incompatible - that is, code written for a mode other than the mode the
processor is actually in will almost certainly behave incorrectly.

# Modes

CR `1 0001`, equivalently `cr17` or "the MODE control register," holds a value indicating the current
_mode_ of the processor. This has an initial value of `0`.

## Base Mode (Real 16-bit Address Mode)

The mode described by [the base isa](../../base-isa.md) is known as the
Base mode. In that mode, pointers are 16 bits and there is no virtual memory, paging, or memory protection.
Base mode is indicated by a value of 0 in `cr17`.

## Real n-bit Address Mode

In this mode, all addresses are treated as being `n` bits long. Addresses always refer to their sign extension to the highest supported address size.
Entering this mode from a smaller n-bit address mode _must_ preserve the program counter. Returning to a smaller n-bit address mode must preserve the program
counter _if possible_ - if the current program counter interpreted as the smaller n-bit Address would not refer to the same location, then the behavior of
the system is _unspecified_.

# Address Extension Table

| Mode CR Value | Address Size | Extension                                                   |
|---------------|--------------|-------------------------------------------------------------|
| 0             | 16 bit       | [Base ISA](../base-isa.md)                                  |
| 2             | 32 bit       | [Real 32-bit Address Space](32-bit-address-space/README.md) |
| 4             | 64 bit       | [Real 64-bit Address Space](64-bit-address-space/README.md) |

# Interactions With Other Extensions

Other extensions mention "address modes", in particular when deciding what a particular value
should mean or how many bytes an immediate should be.

| Address Size | Address Mode |
|--------------|--------------|
| 16 bit       | word         |
| 32 bit       | doubleword   |
| 64 bit       | quadword     |

When an instruction "reads an address" from a register, bits beyond those specified by the current Address Size attribute are ignored.
Similarly, when an instruction "stores an address" (or "writes") to a register, bits in the result
beyond those specified by the curernt Address Size attribute are unspecified.
For example, if the address size is `word`, after a `call` only the lower 16 bits of the link register are specified.
The higher bits may be anything, though we offer recommendations.

If the current addressing mode is a virtual mode, be aware that the addressing mode will be a power-of-two number of
bits even if the virtual pointer widths are not (e.g. virtual 48-bit pointers are used with a `quadword` addressing mode).
In this case, the bits between the pointer width and the addressing mode **must** be specified by the extension
introducing the addressing mode. In particular, when storing an address to a register, those bits must be the sign
extension of the virtual address. We leave the semantics of reading such an address from a register to the relevant
extensions.

If the system supports [privilege levels](../privileged-mode/), then `cr17` is only writable when in system privilege mode.

# Recommendations

These extensions do not _require_ behaviors beyond what is specified. However, for compatibility with future
extensions which will require more specifics, the following are recommended:

* The program counter (or equivalent) in the processor itself should always store the sign-extended address.
  This way, nothing special needs to be done when entering or leaving address modes with larger or smaller address sizes

* When storing addresses to registers, the values stored _should_ be their sign-extension to the full width of the
  register. Barring that, the values _should_ be their sign extension to the widest supported address width, and
  be zero-extended from there. We strongly recommend that the choice be consistent across all relevant instructions
  and that documentation about processor describe what is done.
