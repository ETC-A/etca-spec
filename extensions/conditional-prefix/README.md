# General design

**Extension State: Under Development**  
**Enabled by Default: Yes**  
**Requires: Base, VWI**  
**CPUID 1 Bit: 4**

# Overview

This extension adds a prefix for conditionally executing an instruction.

# Added Instructions

The following opcodes are now defined.

| First byte  | Comment                                                                                                                             |
|:------------|:------------------------------------------------------------------------------------------------------------------------------------|
| `1010 CCCC` | when `CCCC` is not 1111 and not 1110, the following instruction is executed if the condition code specified by CCCC in base is true |

| Symbol | Meaning                                    |
|--------|--------------------------------------------|
| C      | condition code bit                         |
