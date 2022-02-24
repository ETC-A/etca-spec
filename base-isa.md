# General design

- 16bit word size
- 8 16bit registers
- 4 flags set upon (some) ALU operations: Zero (`Z`), Negative (`N`), Carry (`C`), Overflow (`O`)

# Base Instructions

This is a group of 16bit fixed width instructions. The motivation for the chosen instructions is to be both complete and
easy to build in game.

The highest two bits of the first byte are a format marker:

- `00` this is a computation operation between two registers
- `01` this is a computation operation between a register and an immediate
- `10` this is a (conditional) jump instruction
- `11` this is a variable length instruction and reserved for extensions

# Overview

| First byte    | Second Byte  | Comment                                  |
|:--------------|:-------------|:-----------------------------------------|
| `00 01 CCCC`  | `00 AAA BBB` | 2 register computation                   |
| `01 01 CCCC`  | `AAA IIIII`  | Immediate and 1 register computation     |
| `10 0 0 CCCC` | `SSSSSSSS`   | (conditional) relative jump instruction  |
| `10 0 1 CCCC` | `IIIIIIII`   | (conditional) absolute jump instruction  |
| `10 1 ?????`  | `?????????`  | reserved                                 |
| `00 SS CCCC`  | `00 AAA BBB` | when `SS != 01`, reserved for extensions |
| `01 SS CCCC`  | `AAA IIIII`  | when `SS != 01`, reserved for extensions |
| `11 ??????`   | `?????????`  | reserved for extensions                  |


## Computation Instructions

Both computation formats share a lot of similarities. For both the first byte has the structure `0x SS CCCC`.

- `SS` is a size marker and reserved for extensions. For the base instructions this should always be `01`
- `CCCC` is a 4bit opcode deciding which operation to execute. This can be an ALU or a memory load/store instruction

### 2 Register Computation

For the `00` format the second byte has the format `00 AAA BBB` where `AAA` and `BBB` are references to registers.

### Immediate Computation

For the `01` format the second byte has the format `RRR IIIII`, where the 5bit immediate is sign extended and acts as
operand `B`.

### Opcodes

TODO: This is a baseline, very much still floating

| `CCCC` | NAME    | Operation                      | Flags  | Comment |
|--------|---------|--------------------------------|--------|---------|
| `0000` | `ADD`   | `A ← A + B`                    | `ZNCO` |         |
| `0001` | `SUB`   | `A ← A - B`                    | `ZNCO` |         |
| `0010` | `CMP`   | `_ ← A - B`                    | `ZNCO` |         |
| `0011` | `RSUB`  | `A ← B - A`                    | `ZNCO` |  (1,2)  |
| `0100` | `AND`   | `A ← A & B`                    | `ZN`   |         |
| `0101` | `OR`    | <code>A ← A &#124; B</code>    | `ZN`   |         |
| `0110` | `XOR`   | `A ← A ^ B`                    | `ZN`   |         |
| `0111` | `NOR`   | <code>A ← ~(A &#124; B)</code> | `ZN`   |   (2)   |
| `1000` | `MOV`   | `A ← B`                        |  None  |         |
| `1001` |         |                                |        |         |
| `1010` | `STORE` | `MEM[A] ← B`                   |  None  |         |
| `1011` | `LOAD`  | `A ← MEM[B]`                   |  None  |         |
| `1100` |         |                                |        |         |
| `1101` |         |                                |        |         |
| `1110` | `TEST`  | `_ ← A & B`                    | `ZN`   |   (3)   |
| `1111` |         |                                |        |         |


(1) Enables NEG and NOT to be encoded as `RSUB r, imm`.
(2) Very much in flux, not entirely convinced we want these.
(3) Placed here for now to ease decoding; 3=2 & 1 => do not store result.


## Jump Instructions

Here the first byte has the format `10 0 M CCCC` where `M` is a mode selects between a relative and an absolute jump. `CCCC` is the condition to check. The second byte is a single 8bit immediate representing the jump target. This immediate is signed when the jump mode is relative (`M=0`). When the mode is absolute (`M=1`) it on execution replaces
the low byte of the Program Counter. The high byte stays in this case the same.

### Conditions


| `CCCC` | NAME | Flags                                     | Comment                  |
|--------|------|-------------------------------------------|--------------------------|
| `0000` | NOP  |                                           |                          |
| `0001` | JLT  | <code>N ^ O</code>                        |                          |
| `0010` | JEQ  | <code>Z</code>                            |                          |
| `0011` | JLE  | <code>(N ^ O) &#124; Z</code>             |                          |
| `0100` | JGT  | <code>~(O &#124; Z)</code>                |                          |
| `0101` | JNE  | <code>(N ^ O) &#124; ~(O &#124; Z)</code> |                          |
| `0110` | JGE  | <code>~(O &#124; Z) &#124; Z</code>       | <code>~O &#124; Z</code> |
| `0111` | JMP  |                                           |                          |
| `1000` | JULT | <code>~C &amp; ~Z</code>                  |                          |
| `1001` | JUGT | <code>C &amp; ~Z</code>                   |                          |
| `1010` | JULE | <code>~C &#124; Z</code>                  |                          |
| `1011` | JUGE | <code>C &#124; Z</code>                   |                          |
| `1100` | JCAN | <code>~C</code>                           |                          |
| `1101` | JCAS | <code>C</code>                            |                          |
| `1110` | JOVN | <code>~O</code>                           |                          |
| `1111` | JOVS | <code>O</code>                            |                          |
