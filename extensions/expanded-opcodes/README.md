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
| `0 0000 0011` |                 |                                    |        | reserved    |
| `0 0000 01xx` |                 |                                    |        | reserved    |
| `0 0000 1xxx` |                 |                                    |        | reserved    |
| `0 0001 xxxx` |                 |                                    |        | reserved    |
| `0 001x xxxx` |                 |                                    |        | reserved    |
| `0 01xx xxxx` |                 |                                    |        | reserved    |
| `0 1xxx xxxx` |                 |                                    |        | reserved    |
| `1 xxxx xxxx` |                 |                                    |        | reserved    |


1) Enables NEG and NOT to be encoded as `RSBB r, imm` for integers larger than supported by the ISA.
2) C in the operation refers to the carry bit.

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

