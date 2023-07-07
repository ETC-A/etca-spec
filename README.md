# ETCa
Extensible Turing Complete Architecture

This repo is for designing an ISA that has a simple base and multiple extensions that can be added on top. Its primary goal is to be easy to build in the game
[Turing Complete](https://turingcomplete.game) after the second architecture is completed. Several other goals include being educational and being practical for a real CPU.

To get started with the base instruction set, please see [base-isa.md](base-isa.md).

An extensible assembler built for this ISA is [the etca-asm repository](https://github.com/ETC-A/etca-asm) in this organization.

## Terminology

See [RFC-2119](https://www.ietf.org/rfc/rfc2119.txt) for some of the terminology used in the documentation for ETCa.

_Illegal_: Specifies that a specific behavior or instruction is **NOT** allowed in a compliant implementation and must be handled as specified by the ISA.

_Reserved_: Specifies that the behavior or instruction will be specified in a future extension or feature and should be treated as _illegal_ until it is both specified and implemented.

_Unspecified_: Specifies that the behavior or instruction is intentionally unconstrained and may be freely handled any way an implementation chooses. Extensions and features can specify
or restrict _unspecified_ behavior.
