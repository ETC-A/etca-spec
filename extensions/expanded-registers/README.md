# General design

**Extension State: Under Development**  
**Requires: Base, VWI**  
**CPUID Bit: CP1.5**

# Overview

This extension adds an instruction prefix byte which expands the number of available registers from 8 registers to 16 registers. The table below contains an extension for the suggested calling convention for if the stack and functions extension is implemented.

| Register | Alias | Who saves it |
|----------|-------|--------------|
| `r8`     | `t0`  | Caller Saved |
| `r9`     | `t1`  | Caller Saved |
| `r10`    | `t2`  | Caller Saved |
| `r11`    | `t3`  | Caller Saved |
| `r12`    | `t4`  | Caller Saved |
| `r13`    | `s2`  | Callee Saved |
| `r14`    | `s3`  | Callee Saved |
| `r15`    | `s4`  | Callee Saved |

- sN registers are registers that must be saved before re-using.
- tN registers are temporary registers which a function can use however it wants.

Remember that the above are just suggestions. A complete specification of a standard calling convention for ETC-A is not yet specified.

# Added Instructions

The following 1-byte instruction prefix is now defined.

| `REX`  |     |     |     |     |
|:-------|-----|-----|-----|-----|
| `1100` | `Q` | `A` | `B` | `X` |

When used with an instruction that uses an `A` register, `REX.A` provides a 4th bit to be used as the most significant bit of the register specifier.
When used with an instruction that uses a `B` register (including a `SIB.B` if [MO1](../memory-operands-1/README.md) or [MO2](../memory-operands-2/README.md) is available), `REX.B` provides a 4th bit for the specifier in the same way.
When used with an instruction that uses an `SIB.X` register, `REX.X` provides a 4th bit for the specifier in the same way.

Unused bits _should_ be set to 0. If unused bits are set for an instruction which does not use them, they _must_ be ignored or treated as an illegal instruction unless specified otherwise.
