# General design

**Extension State: Under Development**  
**Enabled by Default: Yes**  
**Requires: Base**  
**CPUID Bit: 8**

# Overview

This extension allows an arbitrary register to act as the stack pointer.

# Added Instructions

The following opcodes are now defined.

| First byte    | Second Byte  | Comment                                                 |
|:--------------|:-------------|:--------------------------------------------------------|
| `00 SS 1100`  | `AAA BBB 00` | pop from stack                                          |
| `00 SS 1101`  | `AAA BBB 00` | push register to stack                                  |
| `01 SS 1101`  | `AAA IIIII`  | push immediate to stack                                 |

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
| `1100` | `POP`   | <code>A ← A + 2; B ← mem[A]</code>        | None   | (1)     |
| `1101` | `PUSH`  | <code>mem[A] ← B; A ← A - 2</code>        | None   | (1)     |

### Immediate mode

| `CCCC` | NAME    | Operation                                 | Flags  | Comment |
|--------|---------|-------------------------------------------|--------|---------|
| `1101` | `PUSH`  | <code>mem[A] ← I; A ← A - 2</code>        | None   | (1)     |

1) If the SS bits (as defined in the base specification) are 00, then instead of + or - 2, you'll do + or - 1. Similarly, if they're set to 10 or 11 it will be 4 or 8 respectively. This is only relevant if the 8 bit, 32 bit, or 64 bit operation extensions are enabled. Note that this can cause the stack pointer to become misaligned.
