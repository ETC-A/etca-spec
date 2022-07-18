# General design

**Extension State: Under Development**  
**Requires: Base, VWI, CP2.0**  
**CPUID Bit: CP2.3**

# Overview

This extension adds several frequently used and useful bit manipulation operations to improve program efficiency and reduce the overhead of common operations.

# Added Instructions

These instructions are in the expanded calculation opcode section of instructions

### Opcode table

| `C CCCC CCCC` | NAME            | Operation                                                  | Flags  | Comment |
|---------------|-----------------|------------------------------------------------------------|--------|---------|
| `0 0000 0011` | `ROR`           | <code>A ← (A >> B) &#124; (A << (-B &#38; M))</code>       | `ZN`   | (1)     |
| `0 0000 0100` | `SHL`           | `A ← A << B`                                               | `ZN`   |         |
| `0 0000 0101` | `ROL`           | <code>A ← (A << B) &#124; (A >> (-B &#38; M))</code>       | `ZN`   | (1)     |
| `0 0000 0110` | `SHR`           | `A ← A >> B`                                               | `ZN`   |         |
| `0 0000 0111` | `ASHR`          | <code>A ← (A >> B) &#124; (-msb(A) << (-B &#38; M))</code> | `ZN`   | (1) (2) |

1) M refers to a mask based on the size of the operands. The mask is 7, 15, 31, and 63 when the SS bits are 00, 01, 10, and 11 respectively.
2) msb(A) refers to the most significant (highest) bit in A. Conveniently, the 0 based index of that bit is the same as the mask specified above.
