# Purpose

ETC.A is a community-owned public/open source/what have you Instruction Set Architecture. It is developed by community of the Turing Complete game. We have a few goals:
1) [bare-metal] Being designed for the purpose of having a well-standardized architecture for use in community programming challenges.
2) [approachable] In the most restricted form, be simple enough that newcomers can get involved easily.
3) [extensible] Flexible enough to be extensible (The name, ETC.A, stands for "extensible turing complete architecture"). Code assembled for a hardware with some set of extensions should run on _any_ hardware with a superset of those extensions.
4) [educational] Be interesting, allowing for features and hardware implementations that have educational value.
5) [practicality] Be practical; if in 30 years someone wants to build and use a machine for the ISA, that should be not only reasonable but natural.
6) [common cases] The most common cases of instructions should have a shorter encoding, if possible.

# Individual Decisions

Here we will record some individual decisions and why we made the choices we did. Please don't re-hash a discussion we've already had without bringing a new perspective.

### Lots of Reserved Space in the base ISA

The goal with the base ISA is to be simple enough to build, relatively complete, while also functioning as a compact representation for the most common cases of instructions.
Less common cases can be emulated with the compact instructions, but will have a less compact representation offered by extensions as well.

The most common cases of many types of instructions cannot arise in the base ISA. One of the most common instructions in typical x86 assembly is `call`, which the base ISA
does not even have. Most (but not all) of the reserved space is reserved for such common instructions which do not make sense in the base ISA. The bits labeled `SS` are reserved
as _size bits_, allowing an instruction to have an operational width of 1, 2, 4, or 8 bytes. One of the bits near the jump format is reserved for turning (relative) jumps into
(absolute) calls, while another is for returns. We are not yet sure what we want to use the two LSBs of the operand byte for, but some ideas include a mode switch similar to
x86's `MOD R/M` byte.

The most significant bits of the opcode byte being `11` are reserved for any extensions to use as is relevant to them.

### Only Relative Jumps

Relative jumps are as complete as absolute jumps. The "common cases" of conditional jump instructions are for control flow within a single function.
Such jumps are usually a short distance compared to absolute jumps or calls. With absolute jumps, a jump instruction near the start or end of a "code page boundary"
(least significant byte all 0s, for the base ISA) cannot jump to instructions in the adjacent page. Relative jumps can.

### What the heck is `slo`?

This instruction is "shift-left 5 bits, then OR." Since the base ISA only has 5-bit immediate formats, it is very difficult to build larger constant values with typical operations.
The `slo` operation can be used to build any 16-bit immediate in at most 4 instructions, and most in 3. The first one or two instructions are from the following lines:
```
[movi r,imm[14:10]]                      if bit 15 is the same as bit 14 (this will cause sign extension)
[movi r,imm[15]]; [slo r,imm[14:10]]     if bit 15 is different than bit 15
```
This puts the top 6 bits in `r[5:0]`. The remainder of the construction is `slo r,imm[9:5]; slo r,imm[4:0]`.

### C and O flags: undefined after logic

The spec dictates that the value of the C and O flags is implementation-dependent after a bitwise logical operation. It may seem like a good idea to instead mandate that they
keep their old values. The original microprocessors (such as the Intel 8008/8008-1) did actually work this way. It was determined to be confusing. Additionally, it is more
useful for such operations to provide an easy way to clear the C flag.

There is another very important reason for not keeping the old values. Very advanced processors, called _superscalar processors_, are capable of executing instructions in
a different order than they appear in the program binary, as long as the behavior of the program is unchanged. If flags could keep their own values even through instructions
that modify the flags, then the dependency chain of instructions referring to the flags (called "data hazards") becomes very complicated and hard to track, preventing
out-of-order execution on some cases where it should be possible.
