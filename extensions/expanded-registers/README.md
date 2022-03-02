# General design

**Extension State: Under Development**  
**Enabled by Default: Yes**  
**Always Enabled: Yes**  
**Requires: Base**  
**CPUID Bit: 5**

# Overview

This extension adds an instruction prefix byte which expands the number of available registers from 8 registers to 32 registers. The aliases below along with who saves it is for if the stack and functions extension is implemented

| Register | Alias | Who saves it |
|----------|-------|--------------|
| `r8`     | `a2`  | Caller Saved |
| `r9`     | `a3`  | Caller Saved |
| `r10`    | `a4`  | Caller Saved |
| `r11`    | `a5`  | Caller Saved |
| `r12`    | `a6`  | Caller Saved |
| `r13`    | `a7`  | Caller Saved |
| `r14`    | `t0`  | Caller Saved |
| `r15`    | `t1`  | Caller Saved |
| `r16`    | `t2`  | Caller Saved |
| `r17`    | `t3`  | Caller Saved |
| `r18`    | `t4`  | Caller Saved |
| `r19`    | `t5`  | Caller Saved |
| `r20`    | `t6`  | Caller Saved |
| `r21`    | `t7`  | Caller Saved |
| `r22`    | `t8`  | Caller Saved |
| `r23`    | `t9`  | Caller Saved |
| `r24`    | `s2`  | Callee Saved |
| `r25`    | `s3`  | Callee Saved |
| `r26`    | `s4`  | Callee Saved |
| `r27`    | `s5`  | Callee Saved |
| `r28`    | `s6`  | Callee Saved |
| `r29`    | `s7`  | Callee Saved |
| `r30`    | `s8`  | Callee Saved |
| `r31`    | `s9`  | Callee Saved |

- aN registers are argument registers and store the first N arguments to a function call. Additional arguments should be pushed to the stack.
- vN registers are return value registers and store the return values from a function.
- sN registers are registers that must be saved before re-using.
- tN registers are temporary registers which a function can use however it wants.

# Added Instructions

The following prefix is now defined.

| First byte   |
|:-------------|
| `1100 AA BB` |

AA is used for bits 3 and 4 of the A register and BB is used for bits 3 and 4 of the B register. This gives us a 5 bit register index instead of the original 3 bit index. If an instruction only has one register parameter, the unused bits in this prefix are ignored.
