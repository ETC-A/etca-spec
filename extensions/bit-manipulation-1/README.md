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
| `0 0000 1010` | `POPCNT`  | Counts the number of set bits in the `B` input         | `ZN`  | (4)         |
| `0 0000 1011` | `BITSWAP` | Swaps all the bits based on the `SS` bits              | `ZN`  | (5)         |
| `0 0000 1100` | `CTZ`     | Counts the number of `0` bits before the first `1` bit | `ZN`  |             |
| `0 0000 1101` | `CLZ`     | Counts the number of `0` bits after the last `1` bit   | `ZN`  |             |
| `0 0000 1110` | `NOT`     | <code>A ← ~B</code>                                    | `ZN`  |             |
| `0 0000 1111` | `ANDN`    | <code>A ← ~A &#38 B</code>                             | `ZN`  |             |

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
4) The input is effectively zero extended based on the `SS` bits to ensure irrelevant bits are ignored
5) All the bits are swapped so that the highest bits are the lowest and vice-a-versa. For `SS = 11` it
    would act like this: `r[63] <-> r[0], r[62] <-> r[1], ..., r[32] <-> r[31]`. For `SS = 00` it would
    act like this: `r[7] <-> r[0], r[6] <-> r[1], r[5] <-> r[2], r[4] <-> r[3]`.
