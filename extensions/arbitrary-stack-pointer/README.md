# General design

**Extension State: Under Development**  
**Requires: Base, CP1.1**  
**CPUID Bit: CP1.7**

# Overview

This extension allows an arbitrary register to act as the stack pointer. Note that A and B do not have their normal locations here compared to other specification documents. This is to make the operation description match the binary representation.

# Added Instructions

The following opcodes are now defined.

| First byte    | Second Byte  | Comment                                                 |
|:--------------|:-------------|:--------------------------------------------------------|
| `00 SS 1100`  | `AAA BBB 00` | pop from stack                                          |
| `00 SS 1101`  | `BBB AAA 00` | push register to stack                                  |
| `01 SS 1101`  | `BBB IIIII`  | push immediate to stack                                 |

| Symbol | Meaning                                    |
|--------|--------------------------------------------|
| A, B   | register id                                |
| I      | immediate                                  |
| S      | size (reserved)                            |
| ?      | reserved for extensions or another purpose |

## Added Calculation Opcodes

### Register mode

| `CCCC` | NAME    | Operation                                 | Flags  | Comment |
|--------|---------|-------------------------------------------|--------|---------|
| `1100` | `POP`   | <code>B ← B + 2; A ← mem[B]</code>        | None   | (1)     |
| `1101` | `PUSH`  | <code>mem[B] ← A; B ← B - 2</code>        | None   | (1) (2) |

### Immediate mode

| `CCCC` | NAME    | Operation                                 | Flags  | Comment |
|--------|---------|-------------------------------------------|--------|---------|
| `1101` | `PUSH`  | <code>mem[B] ← A; B ← B - 2</code>        | None   | (1)     |

1) If the SS bits (as defined in the base specification) are 00, then instead of + or - 2, you'll do + or - 1. Similarly, if they're set to 10 or 11 it will be 4 or 8 respectively. This is only relevant if the 8 bit, 32 bit, or 64 bit operation extensions are enabled. Note that this can cause the stack pointer to become misaligned.
2) Popping with the `A` and `B` register being equal overwrites the value in `A` with what was read from memory.
