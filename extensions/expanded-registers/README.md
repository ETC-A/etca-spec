# General design

**Extension State: Under Development**  
**Enabled by Default: Yes**  
**Requires: Base, VWI**  
**CPUID Bit: CP1.5**

# Overview

This extension adds an instruction prefix byte expanding the number of available registers from 8 registers to 16, and suggests an extension of the [Stack & Functions](../stack-and-functions/readme.md) extension's calling conventions to the added registers.

# Added Instructions

The following 1-byte instruction prefix is now defined.

| `REX`  |     |     |     |     |
|:-------|-----|-----|-----|-----|
| `1100` | `Q` | `A` | `B` | `X` |

When used with an instruction that uses an `A` register, `REX.A` provides a 4th bit to be used as the most significant bit of the register specifier.
When used with an instruction that uses a `B` register (including an `SIB.B` if [MO1](../memory-operands-1/README.md) or [MO2](../memory-operands-2/README.md) is available), `REX.B` provides a 4th bit for the specifier in the same way.
When used with an instruction that uses an `SIB.X` register, `REX.X` provides a 4th bit for the specifier in the same way.

`REX.Q` is reserved.

# Calling Conventions

When used together with the [Stack & Functions](../stack-and-functions/readme.md) extension, the following table gives the recommended interpretation of the expanded registers.

| Register | Alias | Calling Convention |
|----------|-------|----------------|
| `r8`     | `t0`  | call-clobbered |
| `r9`     | `t1`  | call-clobbered |
| `r10`    | `t2`  | call-clobbered |
| `r11`    | `t3`  | call-clobbered |
| `r12`    | `t4`  | call-clobbered |
| `r13`    | `s2`  | call-preserved |
| `r14`    | `s3`  | call-preserved |
| `r15`    | `s4`  | call-preserved |

- sN registers should be saved before, and restored after, use.
- tN registers are temporary registers which a function can use however it wants.

Remember that the above are just suggestions. Until a more complete specification of a standard calling convention for ETC-A is specified, expect some implementations not to follow them. 
