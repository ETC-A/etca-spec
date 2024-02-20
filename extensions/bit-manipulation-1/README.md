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
| `0 0000 1000` | `RCL`     | <code>C:A ← (C:A << B) &#124; (C:A >> -B)</code>       | `ZNC` | (1) (2) (3) |
| `0 0000 1001` | `RCR`     | <code>A:C ← (A:C >> B) &#124; (A:C << -B)</code>       | `ZNC` | (1) (2) (3) |
| `0 0000 1010` | `POPCNT`  | <code>A ← POPCNT(B)</code>                             | `Z`   | (4)         |
| `0 0000 1011` | `GREV`    | <code>A ← GREV(A, B)</code>                            | `ZN`  | (5)         |
| `0 0000 1100` | `CTZ`     | <code>A ← CTZ(B)</code>                                | `ZC`  | (6)         |
| `0 0000 1101` | `CLZ`     | <code>A ← CLZ(B)</code>                                | `ZC`  | (7)         |
| `0 0000 1110` | `NOT`     | <code>A ← ~B</code>                                    | `ZN`  |             |
| `0 0000 1111` | `ANDN`    | <code>A ← ~A &#38; B</code>                            | `ZN`  |             |
| `0 0001 1000` | `LSB`     | <code>A ← B &#38; -B</code>                            | `ZNC` |             |
| `0 0001 1001` | `LSMSK`   | <code>A ← B ^ (B - 1)</code>                           | `ZNC` |             |
| `0 0001 1010` | `RLSB`    | <code>A ← B &#38; (B - 1)</code>                       | `ZNC` |             |
| `0 0001 1011` | `ZHIB`    | <code>A ← A &#38; ((1 << B) - 1)</code>                | `ZN`  |             |

1) C in the operation column refers to the carry flag.
2) Only the `M` least significant bits of `B` (or `-B` where applicable) are used for a shift amount.
    `M` is equal to 3, 4, 5, or 6 for SS values of 00, 01, 10, or 11 respectively.
    After these operations, the carry flag contains the last bit shifted out of `A`. For example,
    if `rh0` is `0x80`, then after `rolh rh0,1`, the carry flag will be set and `rh0` will be 1.
    If the shift amount is 0, the carry flag is undefined.
    In all cases, the Z and N flags are set according to the result written.
    For example, if `rh0` is `0x80`, then after `rclh rh0,1`, the carry flag will be set,
    `rh0` will be 0, the negative flag will be cleared, and the zero flag will be set.
3) The notation C:A represents combining the carry flag with the value in register `A`. If the operation
    size is `half`, the value is `C AAAA AAAA`, a 9-bit value. The `RCL` instruction rotates this 9-bit
    value left. The `RCR` instruction rotates the value `AAAA AAAA C` to the right. The operation
    is analogous for other operation sizes.
4) Counts the number of set bits in `B` as if it were zero extended based on the `SS` bits.
5) Performs the generalized swap operation on `A` based on the value in `B`. It acts as follows
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

6) Counts the number of `0` bits before the first `1` bit
7) Counts the number of `0` bits after the last `1` bit
