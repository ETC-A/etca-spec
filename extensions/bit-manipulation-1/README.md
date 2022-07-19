# General design

**Extension State: Under Development**  
**Requires: Base, VWI, CP2.0**  
**CPUID Bit: CP2.3**

# Overview

This extension adds several frequently used and useful bit manipulation operations to improve program efficiency and reduce the overhead of common operations.

# Added Instructions

These instructions are in the expanded calculation opcode section of instructions

### Opcode table

In the below table, only the `M` least significant bits of `B` (or `-B` where applicable) are used for a shift amount. `M` is equal to 3, 4, 5, or 6 for SS values of 00, 01, 10, or 11 respectively.

| `C CCCC CCCC` | NAME   | Operation                                  | Flags  | Comment |
|---------------|--------|--------------------------------------------|--------|---------|
| `0 0000 0011` | `ROR`  | <code>A ← (A >> B) &#124; (A << -B)</code> | `ZN`   |         |
| `0 0000 0100` | `SHL`  | `A ← A << B`                               | `ZN`   |         |
| `0 0000 0101` | `ROL`  | <code>A ← (A << B) &#124; (A >> -B)</code> | `ZN`   |         |
| `0 0000 0110` | `SHR`  | `A ← A >> B`                               | `ZN`   |         |
| `0 0000 0111` | `ASHR` | `A ← A >>> B`                              | `ZN`   | (1)     |

1) The difference between arithmetic right shift and logical right shift is that the high bits which are shifted in are equivalent to the msb of A. While this could be represented similar to the
rotations in the table above except where the third `A` is replaced `msb(A)`, that representation does not correctly handle the case of `B = 0`.
