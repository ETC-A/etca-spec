# Variable Width Instruction Standard

This aims to define how variable width instructions affect the behavior of the CPU.

## Variable Width Instructions

Variable Width Instructions (VWI) are a sequence of one or more bytes which count as a single instruction. For all observable purposes, the instruction pointer must always point to the start of the current instruction.

Note that this does not preclude pipelining, so long as any references to the instruction pointer in the specification of an instruction correctly refer to the base address of that instruction being executed.

If the first byte of an instruction is `11xx xxxx`, it is a VWI

## Single Byte NOP

All CPUs which support at least 1 VWI extension must also accept `1010 1110` as a single byte NOP instruction

## Instruction Prefixes

Instruction prefixes are a sequence of one or more bytes which modify the instruction immediately after it. The prefix and the instruction after it are considered as a single VWI. Multiple prefixes can be used on a single instruction at once but they _must_ be in the following order when present.

1. Conditional Prefix
2. Expanded Registers

Unless specified otherwise, each prefix can only be used _at most_ once per instruction.

### Defined Prefix Sequences

| Prefix      | Description                                                   |
|:------------|:--------------------------------------------------------------|
| `1010 xxxx` | When `xxxx` is neither `1110` nor `1111`, conditional prefix. |
| `1100 xxxx` | Expanded registers prefix and large immediate bit.            |
| `1101 xxxx` | Unused                                                        |

