# General design

**Extension State: Under Development**  
**Enabled by Default: Yes**  
**Requires: Base, VWI**  
**CPUID1 Bit: 5**

# Overview

This extension adds an instruction prefix byte which expands the number of available registers from 8 registers to 32 registers. The aliases below along with who saves it is for if the stack and functions extension is implemented

| Register | Alias | Who saves it |
|----------|-------|--------------|
| `r8`     | `t0`  | Caller Saved |
| `r9`     | `t1`  | Caller Saved |
| `r10`    | `t2`  | Caller Saved |
| `r11`    | `t3`  | Caller Saved |
| `r12`    | `t4`  | Caller Saved |
| `r13`    | `s2`  | Caller Saved |
| `r14`    | `s3`  | Caller Saved |
| `r15`    | `s4`  | Caller Saved |

- aN registers are argument registers and store the first N arguments to a function call. Additional arguments should be pushed to the stack.
- sN registers are registers that must be saved before re-using.
- tN registers are temporary registers which a function can use however it wants.

Remember that the above are just suggestions. A complete specification of a standard calling convention for ETC-A is not yet specified.

# Added Instructions

The following 1-byte instruction prefix is now defined.

| `REX`   | | | | |
|:-------------|---|----|----|----|
| `1100` | `Q` | `A` | `B` | `X` |

When used with an instruction that uses an `A` register, `REX.A` provides a 4th bit to be used as the most significant bit of the register specifier.
When used with an instruction that uses a `B` register (including an `SIB.B` if [MO1](../memory-operands-1/README.md) or [MO2](../memory-operands-2/README.md) is available), `REX.B` provides a 4th bit for the specifier in the same way.
When used with an instruction that uses an `SIB.X` register, `REX.X` provides a 4th bit for the specifier in the same way.

`REX.Q` is reserved.

