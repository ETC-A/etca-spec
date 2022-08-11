# ETCa
Extensible Turing Complete Architecture

This repo is for designing an ISA that has a simple base and multiple extensions that can be added ontop. It's primary goal is to be easy to build in the game
[Turing Complete](https://turingcomplete.game) after the second architecture is completed. Several other goals include being educational and being practical for a real CPU.

An extensible assembler built for this architecture is [here](https://github.com/ETC-A/etca-asm)

## Terminology

_Must_: Specifies that a specific behavior is required by the specification.

_Should_: Specifies that a specific behavior is recommended but not required.

_May_: Specifies that a specific behavior is allowed and not encouraged or discouraged.

_Illegal_: Specifies that a specific behavior or instruction is **NOT** allowed in a compliant implementation and must be handled as specified by the ISA.

_Reserved_: Specifies that the behavior or instruction will be specified in a future extension or feature and should be treated as _illegal_ until it is both specified and implemented.

_Unspecified_: Specifies that the behavior or instruction is intentionally unconstrained and may be freely handled any way an implementation chooses.
