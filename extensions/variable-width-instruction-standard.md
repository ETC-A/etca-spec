# Variable Width Instruction Standard

This aims to define how variable width instructions affect the behavior the behavior of the CPU.

## Variable Width Instructions

Variable Width Instructions (VWI) are a sequence of one or more bytes which count as a single instruction. For all observable purposes, the instruction pointer must always point to the start of the current instruction.

Note that this does not preclude pipelining, so long as any references to the instruction pointer in the specification of an instruction correctly refer to the base address of that instruction being executed.

If the first byte of an instruction is `11xx xxxx`, it is a VWI

## Instruction Prefixes

Instruction prefixes are a sequence of one or more bytes which modify the instruction immediately after it. The prefix and the instruction after it are considered as a single VWI

### Defined Prefix Sequences

`110x xxxx`
