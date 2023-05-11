# General design

**Extension State: Under Development**  
**Requires: Base, VWI, CP2.0**  
**CPUID Bit: CP2.3**

# Overview

This extension adds multiplication, division, and remainder instructions. 

# Added Instructions

These instructions are in the expanded calculation opcode section of instructions.

A `U` at the front of an instruction indicates that it treats its operands as unsigned.
An `S` indicates that the operands are treated as signed.

### Opcode table

| `C CCCC CCCC` | NAME     | Operation                                  | Flags  | Comment |
|---------------|----------|--------------------------------------------|--------|---------|
| `0 0001 0000` | `UDIV`   | `A ← A / B`                                | None   | (1)     |
| `0 0001 0001` | `SDIV`   | `A ← A / B`                                | None   | (1)     |
| `0 0001 0010` | `UREM`   | `A ← A % B`                                | None   | (1) (2) |
| `0 0001 0011` | `SREM`   | `A ← A % B`                                | None   | (1) (2) |
| `0 0001 0100` | `UMUL`   | `A ← A × B`                                | `CV`   | (3) (5) |
| `0 0001 0101` | `SMUL`   | `A ← A × B`                                | `CV`   | (3) (6) |                                          
| `0 0001 0110` | `UHMUL`  | `A ← high(A × B)`                          | None   | (4)     |
| `0 0001 0111` | `SHMUL`  | `A ← high(A × B)`                          | None   | (4)     |                                          

1) Non-integral results of divisions are truncated towards zero. Therefore 10 / 3 is 3,
    and -10 / 3 is -3. The result (quotient or remainder) is zero extended for the unsigned
    operations, and sign extended for the signed operations.
2) The remainder of a division is always smaller in magnitude than
    the divisor, and has the sign of the dividend.
3) The multiplication operands are treated as having the operation size (as from the `SS` bits).
    The complete result will have the next size up. If the destination is a register, and it is
    possible to store the complete result, then the complete result is stored.
    If the destination is memory, or if the result cannot be stored in the destination register
    (for example, the operand size
    is `word` and the system does not support [doubleword operations](../double-word-operations)),
    then the truncation to the operation size is stored. The result of `UMUL` is always zero-extended,
    and the result of `SMUL` is always sign-extended.
4) The multiplication operands are treated as having the operation size (as from the `SS` bits).
    The result will have the next size up; these instructions store only the **upper** half.
    The result (that is, the upper half of the product) is zero extended for `UMULH` and sign
    extended for `SMULH`.
5) The `C` and `V` flags are both set to 0 if the upper half of the multiplication is 0,
    even if that half would be discarded by the instruction. Otherwise they are set to 1.
    The values of the `Z` and `N` flags are undefined afterwards.
6) The `C` and `V` flags are set to 1 if the actual signed value of the product is not equal
    to the signed truncated result. Otherwise they are set to 0.
    The values of the `Z` and `N` flags are undefined afterwards.

# Division By Zero

If the [interrupts](../interrupts/README.md) extension is available, then an attempted
`udiv`, `sdiv`, `urem`, or `srem` with a divisor of 0 causes a synchronous Divide Error.

If the interrupts extension is not available, then the behavior is explicitly _unspecified_.
