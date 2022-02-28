# General design

- 16bit word size
- 8 16bit registers
- 4 flags set upon (some) ALU operations: Zero (`Z`), Negative (`N`), Carry (`C`), Overflow (`V`)
- CPU Execution starts at address 0x8000

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
| `00 01 CCCC`  | `RRR RRR 00` | 2 register computation                   |
| `00 SS CCCC`  | `RRR RRR ??` | when `SS != 01`, reserved for extensions |
| `00 01 CCCC`  | `RRR RRR ??` | when `?? != 00`, reserved for extensions |
| `00 01 11??`  | `RRR RRR ??` | reserved for extensions                  |
| `01 01 CCCC`  | `RRR IIIII`  | immediate and 1 register computation     |
| `01 SS CCCC`  | `RRR IIIII`  | when `SS != 01`, reserved for extensions |
| `10 0 D CCCC` | `DDDDDDDD`   | (conditional) relative jump instruction  |
| `10 1 ?????`  | `?????????`  | reserved for extension                   |
| `11 ??????`   | `?????????`  | reserved for extensions                  |

| Symbol | Meaning                      |
|--------|------------------------------|
| C      | opcode bit                   |
| R      | register id                  |
| I      | immediate                    |
| D      | displacement                 |
| S      | size (res.d)                 |
| ?      | reserved for unknown purpose |


## Computation Instructions

Both computation formats share a lot of similarities. For both the first byte has the structure `0x SS CCCC`.

- `SS` is a size marker and reserved for extensions. For the base instructions this should always be `01`
- `CCCC` is a 4bit opcode deciding which operation to execute. This can be an ALU or a memory load/store instruction

### 2 Register Computation

The second byte has the format `AAA BBB 00` where `AAA` and `BBB` are references to registers. `AAA` is the destination register and left source register. `BBB` is the right source register. The only exception is the RSUB instruction where `AAA` and `BBB` are swapped for the purpose of being source registers.

### Immediate Computation

The second byte has the format `RRR IIIII`, where the 5bit immediate acts as
operand `B`. The immediate is sign extended for the first 12 operations.

### Opcodes

TODO: This is a baseline, very much still floating

| `CCCC` | NAME       | Operation                          | Flags  | Comment     |
|--------|------------|------------------------------------|--------|-------------|
| `0000` | `ADD`      | `A ← A + B`                        | `ZNCV` |             |
| `0001` | `SUB`      | `A ← A - B`                        | `ZNCV` |             |
| `0010` | `RSUB`     | `A ← B - A`                        | `ZNCV` | (1)         |
| `0011` | `CMP`      | `_ ← A - B`                        | `ZNCV` | (2)         |
| `0100` | `OR`       | <code>A ← A &#124; B</code>        | `ZN`   | (5)         |
| `0101` | `XOR`      | `A ← A ^ B`                        | `ZN`   | (5)         |
| `0110` | `AND`      | `A ← A & B`                        | `ZN`   | (5)         |
| `0111` | `TEST`     | `_ ← A & B`                        | `ZN`   | (2) (5)     |
| `1000` |            |                                    |        |             |
| `1001` | `MOV`      | `A ← B`                            | None   |             |
| `1010` | `LOAD`     | `A ← MEM[B]`                       | None   |             |
| `1011` | `STORE`    | `MEM[A] ← B`                       | None   | (2)         |
| `1100` | `SLO`      | <code>A ← (A << 5) &#124; B</code> | None   | (3) (6)     |
| `1101` |            |                                    |        |             |
| `1110` | `IN`       | `A ← PORT[B]`                      | None   | (4) (6)     |
| `1111` | `OUT`      | `PORT[B] ← A`                      | None   | (2) (4) (6) |


1) Enables NEG and NOT to be encoded as `RSUB r, imm`.
2) Placed here for now to ease decoding; `xx11` => do not store result.
3) Designed to allow for building a larger immediate value. To reach the full 16 bit one extra `NOT` instruction may be required.
4) Primary intent is that these are used with immediate. Exact assignment of ports is still floating. At least the level IO and the CPU status/extension control should be present.
5) The C and O flags are in an undefined state after execution of these instructions. Implementations may do whatever is easiest. An extension may mandate a particular behavior, with good enough reason, but must *not* mandate that the value of these flags after the operation depends on their value before the operation.
6) These instructions do not have a 2 register mode. The corresponding bit patterns (`00 SS 11??`) for the first byte are reserved. This can easily be detected by using similar to 2)

#### Input and Output Instructions

If the LSB of the port number is 0, then the port number refers to a control register. If the LSB of the port number is 1, then the port number refers to an IO device. Undefined control registers are reserved and reading from or writing to them is undefined behavior. No IO devices are specified and how they are used is implementation specific.

| `CRN`  | NAME       | Description                                                                                                              | Comment |
|--------|------------|--------------------------------------------------------------------------------------------------------------------------|---------|
| `0000` | `CPUID`    | Reading from this control register puts the available CPU extensions in the destination register. Writing to it is a NOP | (1)     |
| `0001` | `EXTEN`    | This control register specifies which available extensions are enabled or disabled.                                      | (2)     |

1) CPUID uses a bitfield to specify the available extensions. A value of 0 means no extensions are available.
2) This uses a bitfield in the same format as CPUID. Attempting to enable a non-available extension should leave the bit cleared. Attempting to disable a non-disableable extension should leave the bit set.

## Flag Semantics

Flags conceptually maintain these values. A future, more rigorous specification of this standard will include a detailed description of affected flags for every instruction individually.

1) The `Z` flag indicates that the result was zero.
2) The `N` flag indicates that the result, interpreted as a 2's complement number, was negative.
3) The `C` flag describes whether an additive instruction caused a carry, or a subtractive computation caused a borrow. The concept of "borrow" is exactly the same as in long-hand decimal subtraction the way you might do it on paper. The flag is set if the subtraction would borrow out of the next most significant bit. A borrow happens precisely when the corresponding addition does _not_ carry. In other words, in order to subtract, you (a) complement the B input, (b) set the carry in, (c) set C to the inverse of the carryout.
4) The `V` flag indicates that the operation caused overflow. This means that storing the result in the destination register caused a loss of precision.

## Jump Instructions

Here the first byte has the format `10 0 D CCCC` where `D` fills the high byte of the displacement. `CCCC` is the condition to check. The second byte is a single 8bit immediate representing the low byte of the displacement. This combined 9 bit displacement (sign extended to 16 bits) is added to the base address of the current instruction and stored in the program counter.

### Conditions


| `CCCC` | NAME                    | Flags                            | Comment |
|--------|-------------------------|----------------------------------|---------|
| `0000` | Zero/Equal              | `Z`                              |         |
| `0001` | Not zero/Not equal      | `~Z`                             |         |
| `0010` | Negative                | `N`                              |         |
| `0011` | Not Negative            | `~N`                             |         |
| `0100` | Carry/Below             | `C`                              |         |
| `0101` | No carry/Above or equal | `~C`                             |         |
| `0110` | Overflow                | `V`                              |         |
| `0111` | No Overflow             | `~V`                             |         |
| `1000` | below or equal          | <code> C &#124; Z</code>         |         |
| `1001` | above                   | <code> ~(C &#124; Z) </code>     |         |
| `1010` | less                    | `N ≠ V`                          |         |
| `1011` | greater or equal        | `N = V`                          |         |
| `1100` | less or equal           | <code> Z &#124; (N ≠ V) </code>  |         |
| `1101` | greater                 | <code> ~Z &amp; (N = V) </code>  |         |
| `1110` | always                  |                                  |         |
| `1111` | never                   |                                  |         |

### Execution of Reserved Instructions

When executing a reserved instruction, the CPU must halt normal execution of the program. This can mean Halt and Catch Fire, halt and wait to be interrupted, trigger an interrupt, or other such behaviors. A future extension is expected to tighten this restriction to "the CPU must trigger a specified interrupt."
