# General design

**Extension State: Under Development**  
**Enabled by Default: Yes**  
**Requires: Base**  
**CPUID Bit: CP1.14**

- All registers (excluding the `PC`) _must_ be able to store 32 bit (double word) values
- The SS bits in the calculation opcode can now be set to 10.
- When the SS bits are set to 10, the calculation is performed as if the operation was for 32 bit values.
- Operations that write to a register _must_ sign extend the value to the register's width before writing it to the register _unless_ the operation is `movz` in which case it _must_ zero extend the value to the register's width before writing it to the register.
- Operations that modify flags _must_ modify them as if the operation was for 32 bit values.
- Memory stores in this mode _must_ only affect the 32 bit section that is being written to.
- Memory stores with the SS bits set to 01 _must_ only affect the 16 bit section that is being written to
- Memory address alignment in this mode is 4 bytes

# Assembly changes

32bit register references/32bit operations are marked by the infix/prefix `d` (i.e. `%rd0`)
