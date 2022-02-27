# General design

**Extension State: Under Development**

**Enabled by default: yes**

**Always enabled: yes**

- The SS bits in the calculation opcode can now be set to 00.
- When the SS bits are set to 00, the calculation is performed as if the operation was for 8 bit values.
- Operations that write to a register _must_ sign extend the value to the register's width before writing it to the register.
- Operations that modify flags _must_ modify them as if the operation was for 8 bit values.
- Memory stores in this mode _must_ only affect the 8 bit section that is being written to.
- The corresponding bit for this extension in the CPUID and EXTEN control registers is bit 0
