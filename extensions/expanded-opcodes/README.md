# General design

**Extension State: Under Development**  
**Enabled by Default: Yes**  
**Requires: Base, VWI**  
**CPUID Bit: 9**

# Overview

This extension adds an expanded instruction format to allow for a larger number of opcodes to be used. It also includes a relative jump and call with larger displacements.

# Added Instructions

The following opcodes are now defined.

| First byte    | Second Byte  | Third Byte   | Comment                                                                   |
|:--------------|:-------------|:-------------|:--------------------------------------------------------------------------|
| `111 00 000`  | `SS CCCCCC`  | `RRR RRR MM` | Register-Register operation                                               |
| `111 00 ???`  | `SS CCCCCC`  | `RRR RRR MM` | When `???` is not `000`, reserved                                         |
| `111 01 000`  | `SS CCCCCC`  | `RRR IIIII`  | Register-Immediate operation                                              |
| `111 01 ???`  | `SS CCCCCC`  | `RRR IIIII`  | When `???` is not `000`, reserved                                         |
| `111 10 DDD`  | `DDDD DDDD`  | `DDDD DDDD`  | Large relative jump                                                       |
| `111 11 DDD`  | `DDDD DDDD`  | `DDDD DDDD`  | Large relative call if stack extension is implemented, otherwise reserved |

| Symbol | Meaning                                    |
|--------|--------------------------------------------|
| C      | condition code bit                         |
| R      | register id                                |
| I      | immediate                                  |
| D      | signed displacement                        |
| S      | size                                       |
| M      | memory mode                                |
| ?      | reserved for extensions or another purpose |

## Mapping from the base ISA opcodes to this extension

When the base opcode `CCCC` matches `0xxx`, the new opcode is `0 CCCC 0`

When the base opcode `CCCC` matches `1xxx`, the new opcode is `01 CCCC`

## Opcode mapping table

| `CCCCCC` | NAME            | Operation                          | Flags  | Comment     |
|----------|-----------------|------------------------------------|--------|-------------|
| `000000` | `ADD`           | `A ← A + B`                        | `ZNCV` |             |
| `000001` | `ADC`           | `A ← A + B + C`                    | `ZNCV` |             |
| `000010` | `SUB`           | `A ← A - B`                        | `ZNCV` |             |
| `000011` | `SBB`           | `A ← A - B - C`                    | `ZNCV` |             |
| `000100` | `RSUB`          | `A ← B - A`                        | `ZNCV` | (1)         |
| `000101` | `RSBB`          | `A ← B - A - C`                    | `ZNCV` |             |
| `000110` | `CMP`           | `_ ← A - B`                        | `ZNCV` |             |
| `000111` | `RCMP`          | `_ ← B - A`                        | `ZNCV` |             |
| `001000` | `OR`            | <code>A ← A &#124; B</code>        | `ZN`   | (5)         |
| `001001` | `NOR`           | <code>A ← ~(A &#124; B)</code>     | `ZN`   | (5)         |
| `001010` | `XOR`           | `A ← A ^ B`                        | `ZN`   | (5)         |
| `001011` | `XNOR`          | `A ← ~(A ^ B)`                     | `ZN`   | (5)         |
| `001100` | `AND`           | `A ← A & B`                        | `ZN`   | (5)         |
| `001101` | `NAND`          | `A ← ~(A & B)`                     | `ZN`   | (5)         |
| `001110` | `TEST`          | `_ ← A & B`                        | `ZN`   | (5)         |
| `001111` |                 |                                    |        | reserved    |
| `010000` | `SHL`           | `A ← A << B`                       | `ZN`   | (5)         |
| `010001` | `ROL`           | `A ← A rotate left B`              | `ZN`   | (5)         |
| `010010` | `LSHR`          | `A ← A >>> B`                      | `ZN`   | (5)         |
| `010011` | `ASHR`          | `A ← A >> B`                       | `ZN`   | (5)         |
| `010100` |                 |                                    |        | reserved    |
| `010101` |                 |                                    |        | reserved    |
| `010110` |                 |                                    |        | reserved    |
| `010111` |                 |                                    |        | reserved    |
| `011000` | `MOVZ`          | `A ← B`                            | None   | (7)         |
| `011001` | `MOV` or `MOVS` | `A ← B`                            | None   | (8)         |
| `011010` | `LOAD`          | `A ← MEM[B]`                       | None   |             |
| `011011` | `STORE`         | `MEM[B] ← A`                       | None   | (2)         |
| `011100` | `SLO`           | <code>A ← (A << 5) &#124; B</code> | None   | (3) (6)     |
| `011101` |                 |                                    |        | reserved    |
| `011110` | `READCR`        | `A ← CR[B]`                        | None   | (4) (6)     |
| `011111` | `WRITECR`       | `CR[B] ← A`                        | None   | (2) (4) (6) |
| `1xxxxx` |                 |                                    |        | reserved    |


1) Enables NEG and NOT to be encoded as `RSUB r, imm`.
3) Designed to allow for building a larger immediate value. To reach a full 16 bit immediate, a 4th `SLO` or an additional `NOT` may be required.
4) Primary intent is that these are used with immediate. Exact assignment of control registers is still floating. At least the the CPU status/extension/feature control registers should be present.
5) The C and O flags are in an undefined state after execution of these instructions. Implementations may do whatever is easiest. An extension may mandate a particular behavior, with good enough reason, but must *not* mandate that the value of these flags after the operation depends on their value before the operation.
6) These instructions do not have a 2 register mode.
7) This instruction zero extends argument B as if the value read is of the size specified by the SS bits in the instruction (assuming the relevant feature is present)
8) This instruction sign extends argument B as if the value read is of the size specified by the SS bits in the instruction (assuming the relevant feature is present)

