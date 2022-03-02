# General design

**Extension State: Under Development**  
**Enabled by Default: Yes**  
**Always Enabled: Yes**  
**Requires: Base**  
**CPUID Bit: 4**  

- The SS bits in the calculation opcode can now be set to 00.
- When the SS bits are set to 00, the calculation is performed as if the operation was for 8 bit values.
- Operations that write to a register _must_ sign extend the value to the register's width before writing it to the register.
- Operations that modify flags _must_ modify them as if the operation was for 8 bit values.
- Memory stores in this mode _must_ only affect the 8 bit section that is being written to.

# Added Instructions

The following calculation opcode is now defined. This instruction follows the same semantics as MOV except that the value written to the destination register is zero extended to the register's full width. `MOVS` is also now an alias for the pre-existing `MOV` instruction.

| `CCCC` | NAME       | Operation                          | Flags  | Comment     |
|--------|------------|------------------------------------|--------|-------------|
| `1000` | `MOVZ`     | `A ← B`                            | None   |             |

As an example, `movz r0, -1` with the SS bits set to 00 will store the value 255 in rx0.
