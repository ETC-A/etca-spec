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
| `0 0001 0000` | `UDIV`   | `A ← A / B`                                | `Z`    | (1)     |
| `0 0001 0001` | `SDIV`   | `A ← A / B`                                | `ZN`   | (1)     |
| `0 0001 0010` | `UREM`   | `A ← A % B`                                | `Z`    | (1) (2) |
| `0 0001 0011` | `SREM`   | `A ← A % B`                                | `ZN`   | (1) (2) |
| `0 0001 0100` | `UMUL`   | `A ← low(A × B)`                           | `CZ`   | (3) (5) |
| `0 0001 0101` | `SMUL`   | `A ← low(A × B)`                           | `CZN`  | (3) (6) |                                          
| `0 0001 0110` | `UHMUL`  | `A ← high(A × B)`                          | `Z`    | (4)     |
| `0 0001 0111` | `SHMUL`  | `A ← high(A × B)`                          | `ZN`   | (4)     |                                          

1) Non-integral results of divisions are truncated towards zero.
    Therefore 10 / 3 is 3, and -10 / 3 is -3.
    Also, see section [Division by zero](#division-by-zero).
2) The remainder of a division is always smaller in magnitude than
    the divisor, and has the sign of the dividend.
3) The result of a multiplication at size `SS` is at most twice as large.
    These instructions store only the **lower** half.
    This extension provides no way to get both halves at the same time,
    but we expect that a future extension will do so.
    If you require both halves of the result, the recommended sequence is
    `mov hidst, src1` / `mul src1, src2` / `hmul hidst, src2`.
    Very high-performance hardware may recognize such sequences and
    "fuse" them into a single multiplication.
4) The result of a multiplication at size `SS` is at most twice as large.
    These instructions store only the **upper** half.
5) The `C` flag is set to 0 if the upper half of the multiplication is 0,
    even if that half would be discarded by the instruction. Otherwise it is set to 1.
    The values of the `Z` and `N` flags are set according to the value of the result written.
6) The `C` flag is set to 1 if the actual signed value of the product is not equal
    to the signed truncated result. Otherwise it is set to 0.
    The values of the `Z` and `N` flags are set according to the value of the result written.

Note that for operand sizes smaller than the width of registers
(for example, word operands on a doubleword system),
the results are always sign-extended, even for the
unsigned operations. See [Doubleword Operations](../double-word-operations/) for example.

# Division By Zero

If the [interrupts](../interrupts/README.md) extension is available, then an attempted
`udiv`, `sdiv`, `urem`, or `srem` with a divisor of 0 causes a synchronous Divide Error.

If the interrupts extension is not available, then the behavior is explicitly _unspecified_.
