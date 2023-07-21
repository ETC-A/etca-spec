# General design

**Extension State: Under Development**  
**Requires: Base, VWI**  
**CPUID Bit: CP2.0**

# Overview

This extension adds an expanded instruction format to allow for a larger number of opcodes to be used. It also includes a relative jump and call with larger displacements.

# Added Instructions

## Calculation Instructions

| First byte    | Second Byte   | Third Byte   | Comment                      |
|:--------------|:--------------|:-------------|:-----------------------------|
| `111 0 CCCC`  | `C 0 SS CCCC` | `RRR RRR MM` | Register-Register operation  |
| `111 0 CCCC`  | `C 1 SS CCCC` | `RRR IIIII`  | Register-Immediate operation |

| Symbol | Meaning                                    |
|--------|--------------------------------------------|
| C      | opcode bit                                 |
| R      | register id                                |
| I      | immediate                                  |
| S      | size                                       |
| M      | memory mode                                |

### Opcode table

| `C CCCC CCCC` | NAME            | Operation                          | Flags  | Comment     |
|---------------|-----------------|------------------------------------|--------|-------------|
| `0 0000 0000` | `ADC`           | `A ← A + B + C`                    | `ZNCV` | (2)         |
| `0 0000 0001` | `SBB`           | `A ← A - B - C`                    | `ZNCV` | (2)         |
| `0 0000 0010` | `RSBB`          | `A ← B - A - C`                    | `ZNCV` | (1) (2)     |
| `0 0000 0011` | `ASR`           | `A ← A >>> B`                      | `ZNC`    | (3) (4)     |
| `0 0000 0100` | `ROL`           | <code>A ← (A << B) &#124; (A >> -B)</code> | `ZNC` | (3)   |
| `0 0000 0101` | `ROR`           | <code>A ← (A >> B) &#124; (A << -B)</code> | `ZNC` | (3)   |
| `0 0000 0110` | `RCL`           | <code>C:A ← (C:A << B) &#124; (C:A >> -B)</code> | `ZNC` | (2) (3) (5) |
| `0 0000 0111` | `RCR`           | <code>A:C ← (A:C >> B) &#124; (A:C << -B)</code> | `ZNC` | (2) (3) (5) |
| `0 0000 1000` | `SHL`           | `A ← A << B`                       | `ZNC`   | (3)         |
| `0 0000 1001` | `SHR`           | `A ← A >> B`                       | `ZNC`   | (3)         |
| `0 0000 101x` |                 |                                    |        | reserved    |
| `0 0000 11xx` |                 |                                    |        | reserved    |
| `0 0001 xxxx` |                 |                                    |        | reserved    |
| `0 001x xxxx` |                 |                                    |        | reserved    |
| `0 01xx xxxx` |                 |                                    |        | reserved    |
| `0 1xxx xxxx` |                 |                                    |        | reserved    |
| `1 xxxx xxxx` |                 |                                    |        | reserved    |


1) Enables NEG and NOT to be encoded as `RSBB r, imm` for integers larger than supported by the ISA.
2) C in the operation column refers to the carry flag.
3) Only the `M` least significant bits of `B` (or `-B` where applicable) are used for a shift amount.
    `M` is equal to 3, 4, 5, or 6 for SS values of 00, 01, 10, or 11 respectively.
    After these operations, the carry flag contains the last bit shifted out of `A`. For example,
    if `rh0` is `0x80`, then after `rolh rh0,1`, the carry flag will be set and `rh0` will be 1.
    If the shift amount is 0, the carry flag is undefined.
    In all cases, the Z and N flags are set according to the result written.
    For example, if `rh0` is `0x80`, then after `rclh rh0,1`, the carry flag will be set,
    `rh0` will be 0, the negative flag will be cleared, and the zero flag will be set.
4) This is an arithmetic right shift, which shifts in the most significant bit of A instead of always
    shifting in 0.
5) The notation C:A represents combining the carry flag with the value in register `A`. If the operation
    size is `half`, the value is `C AAAA AAAA`, a 9-bit value. The `RCL` instruction rotates this 9-bit
    value left. The `RCR` instruction rotates the value `AAAA AAAA C` to the right. The operation
    is analogous for other operation sizes.

Consider the `rclh` operation. Since only the 3 least significant bits
of `B` are used to determine shift amounts,
`rclh _,8` is identical to `rclh _,0`, even though the results would be
different if a count of 8 were allowed! To achieve the result that a count
of 8 _would_ obtain, instead perform `rcrh _,1`.

### Implementor's Notice:

There is a tentative plan to move the `rcl` and `rcr` instructions to the BM1 extension, when it receives its initial specification. This is due to their increased implementation complexity. For now, a compliant implementation of this extension _must_ provide them.

## Jump and Call

| First byte    | 2nd-9th Byte | Comment                                                             |
|:--------------|:-------------|:--------------------------------------------------------------------|
| `111 10 0 SS` | `DDDD DDDD`  | Relative jump                                                       |
| `111 10 1 SS` | `IIII IIII`  | Absolute jump                                                       |
| `111 11 0 SS` | `DDDD DDDD`  | Relative call if stack extension is implemented, otherwise reserved |
| `111 11 1 SS` | `IIII IIII`  | Absolute call if stack extension is implemented, otherwise reserved |

| Symbol | Meaning                                         |
|--------|-------------------------------------------------|
| S      | the number of bytes to use for the displacement |
| D      | signed displacement                             |
| I      | unsigned immediate                              |

`SS = 00,01,10,11` means that 1,2,4,8 bytes are read as the signed displacement/unsigned immediate. These SS bits are not controlled with the operand size extensions. `SS = 10` is reserved unless the 32 or 64 bit address extensions are enabled. `SS = 11` is reserved unless the 64 bit address extension is enabled.

Absolute jumps only overwrite the lower bits of the program counter.

