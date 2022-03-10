# General design

**Extension State: Under Development**  
**Enabled by Default: *No***  
**Requires: Base**  
**CPUID Bit: 6**  

- All registers (including the `PC`) _must_ be able to store 32 bit (double word) values
- The SS bits in the calculation opcode can now be set to 10.
- When the SS bits are set to 10, the calculation is performed as if the operation was for 32 bit values.
- Operations that write to a register _must_ sign extend the value to the register's width before writing it to the register.
- Operations that modify flags _must_ modify them as if the operation was for 32 bit values.
- Memory stores in this mode _must_ only affect the 32 bit section that is being written to.
- Memory stores with the SS bits set to 01 _must_ only affect the 16 bit section that is being written to
- Memory address alignment in this mode is 4 bytes

# Added Instructions

The following calculation opcode is now defined. This instruction follows the same semantics as MOV except that the value written to the destination register is zero extended to the register's full width. `MOVS` is also now an alias for the pre-existing `MOV` instruction.


| `CCCC` | NAME       | Operation                          | Flags  | Comment     |
|--------|------------|------------------------------------|--------|-------------|
| `1000` | `MOVZ`     | `A ← B`                            | None   |             |

As an example, `movz r0, -1` with the SS bits set to 01 will store the value 65535 in r0, even if that register has a 32bit maximum width.

# Assembly changes

32bit register references/32bit operations are marked by the infix/prefix `d` (i.e. `%rd0`)

# Memory Address Space Changes and Consistency

- The address range 0x0000 to 0x7FFF when this extension is disabled must still be contiguous when this extension is enabled
- The address range 0x8000 to 0xFFFF when this extension is disabled must still be contiguous when this extension is enabled
