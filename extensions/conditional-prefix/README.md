# General design

**Extension State: Under Development**  
**Requires: Base, VWI**  
**CPUID Bit: CP1.4**

# Overview

This extension adds a prefix for conditionally executing an instruction.

This prefix is _not_ allowed on an instruction which already has a conditional in it. Attempting to do so is _illegal_.

# Added Instructions

The following prefix opcodes are now defined.

| First byte  | Comment                                                                                                                              |
|:------------|:-------------------------------------------------------------------------------------------------------------------------------------|
| `1010 CCCC` | when `CCCC` is not 1111 and not 1110, the following instruction is executed if the condition code specified by CCCC in base is true. |

| Symbol | Meaning                                    |
|--------|--------------------------------------------|
| C      | condition code bit                         |
