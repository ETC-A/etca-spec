# General design

**Extension State: Under Development**  
**Requires: Base, VWI, CP2.0**  
**CPUID Bit: CP2.4**

# Overview

This extension adds rotate with carry and various bit operations.

# Added Instructions

These instructions are in the expanded calculation opcode section of instructions.

### Opcode table

| `C CCCC CCCC` | NAME      | Operation                                              | Flags | Comment     |
|---------------|-----------|--------------------------------------------------------|-------|-------------|
| `0 0000 1000` | `RCL`     | <code>C:A ← (C:B << 1) &#124; C</code>                 | `ZNC` | (1) (2) (3) |
| `0 0000 1001` | `RCR`     | <code>A:C ← (B:C >> 1) &#124; (C << -1)</code>         | `ZNC` | (1) (2) (3) |
| `0 0000 1010` | `POPCNT`  | <code>A ← POPCNT(B)</code>                             | `Z`   | (4)         |
| `0 0000 1011` | `GREV`    | <code>A ← GREV(A, B)</code>                            | `ZN`  | (5)         |
| `0 0000 1100` | `CTZ`     | <code>A ← CTZ(B)</code>                                | `ZC`  | (6) (7)     |
| `0 0000 1101` | `CLZ`     | <code>A ← CLZ(B)</code>                                | `ZC`  | (6) (8)     |
| `0 0000 1110` | `NOT`     | <code>A ← ~B</code>                                    | `ZN`  |             |
| `0 0000 1111` | `ANDN`    | <code>A ← ~A &#38; B</code>                            | `ZN`  |             |
| `0 0001 1000` | `LSB`     | <code>A ← B &#38; -B</code>                            | `ZN`  | (9)         |
| `0 0001 1001` | `LSMSK`   | <code>A ← B ^ (B - 1)</code>                           | `ZNC` | (6) (10)    |
| `0 0001 1010` | `RLSB`    | <code>A ← B &#38; (B - 1)</code>                       | `ZNC` | (6) (11)    |
| `0 0001 1011` | `ZHIB`    | <code>A ← A &#38; ((1 << B) - 1)</code>                | `ZN`  | (12)        |

1) C in the operation column refers to the carry flag.
2) The `-1` in the operation equivalently indicates a shift amount of one less than the operation size.
   `rcl A, B` is nearly equivalent to `adc B, B`, except that the result is stored in operand `A`
   and the `V` flag is undefined after the operation.
3) The notation C:A represents combining the carry flag with the value in register `A`. If the operation
    size is `half`, the value is `C AAAA AAAA`, a 9-bit value. The `RCL` instruction rotates this 9-bit
    value left. The `RCR` instruction rotates the value `AAAA AAAA C` to the right. Therefore, for
    `rcl`, the `C` flag will be set to the most significant bit of the input, and for `rcl` it will be
    set to the least significant bit of the input.
   The operation is analogous for other operation sizes.
5) Counts the number of set bits in `B` as if it were zero extended based on the `SS` bits.
6) Performs the generalized swap operation on `A` based on the value in `B`. It acts as follows
```
int64_t grev(int64_t a, int b, int ss)
{
    if (b &  1)           a = ((a & 0x5555_5555_5555_5555) <<  1) | ((a & 0xAAAA_AAAA_AAAA_AAAA) >>  1);
    if (b &  2)           a = ((a & 0x3333_3333_3333_3333) <<  2) | ((a & 0xCCCC_CCCC_CCCC_CCCC) >>  2);
    if (b &  4)           a = ((a & 0x0F0F_0F0F_0F0F_0F0F) <<  4) | ((a & 0xF0F0_F0F0_F0F0_F0F0) >>  4);
    if (b &  8 && ss > 0) a = ((a & 0x00FF_00FF_00FF_00FF) <<  8) | ((a & 0xFF00_FF00_FF00_FF00) >>  8);
    if (b & 16 && ss > 1) a = ((a & 0x0000_FFFF_0000_FFFF) << 16) | ((a & 0xFFFF_0000_FFFF_0000) >> 16);
    if (b & 32 && ss > 2) a = ((a & 0x0000_0000_FFFF_FFFF) << 32) | ((a & 0xFFFF_FFFF_0000_0000) >> 32);

    return sign_extend(a, ss);
}
```

- Byte swap can be formulated in terms of GREV where B=24 (for `SS = 10`).
- Bit Reverse can be formulated in terms of GREV where B=31 (for `SS = 10`).

6) These operations set the carry flag if their input was 0,
    and set the `Z` and/or `N` flags according to the result.
7) Counts the number of `0` bits more significant than the most significant `1` bit.
   If there is no such `1` bit, produces the operand size. For example,
   `clzd r0, 0` results in `32` in `r0`, and `clzx r0, 0x0700` results in `5`.
8) Counts the number of `0` bits less significant than the least-significant `1` bit.
   `ctz A,B` behaves as the following sequence:
```
        mov    A,B
        grev   A,-1
        clz    A,A
```
9) Notes 9, 10, 11, and 12 give examples of the remaining operations; however the behavior
    of these operations is fully specified in the table and comment (6).
   `lsb` isolates the least significant `1` bit of `B`. For example, `lsbx r0, 0xFFA0`
    will result in `0x0020` in `rx0`.
11) Get a mask of all bits up to and including the least significant `1` bit of `B`.
    If there is no such bit, the mask is `-1`. For example, `lsmskx r0, 0xFFA0`
    will result in `0x003F` in `rx0`.
12) Reset (set to `0`) the least significant `1` bit of `B`. For example,
    `rlsbx r0, 0xFFA0` will result in `0xFF80` in `rx0`.
13) Zero out the bits of `A` at higher bit indices at least `B`. For example,
    if `0xABCD` is in `rx0`, then `zhibx r0, 7` results in `0x004D` in `rx0`.
