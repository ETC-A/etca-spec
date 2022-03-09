# General design

**Extension State: Under Development**  
**Enabled by Default: *No***  
**Requires: Base**  
**CPUID Bit: 7**  

- The SS bits in the calculation opcode can now be set to 11.
- The operations change in a 100% analogous way to the [Double Word Operations](../double-word-operations) extension, with 64bit instead of 32bit.

# Added Instructions

The added instructions are the same as for the [Double Word Operations](../double-word-operations) extension.

## Assembly changes

64bit register references/64bit operations are marked by the infix/prefix `q` (i.e. `%rq0`)