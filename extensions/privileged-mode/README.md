# General design

**Extension State: Under Development**  
**Enabled by Default: Yes**  
**Requires: Base, CP1.2**  
**CPUID Bit: CP2.2**

# Overview

This extension adds the concept of privileged execution which can be used to isolate an operating system from user code.

While this extension by itself doesn't do much, it's a pre-requisite for more advanced extensions.

# Added Control Registers

| CRN    | Name           | Description                                                                                |
|:-------|:---------------|:-------------------------------------------------------------------------------------------|
| `1100` | `PRIV`         | Specifies the current privilege mode the CPU is running in.                                |
| `1101` | `INT_RET_PRIV` | Stores the privilege mode that the system should return to after the interrupt is handled. |

# Added Privilege Modes

| Name        | Value | Description                                                           |
|:------------|:------|:----------------------------------------------------------------------|
| User Mode   | 0     | This is the least privileged mode and is used by user space programs. |
| System Mode | 1     | This is the most privileged mode and is used by the operating system. |

The `PRIV` CR is only writable in system mode. Attempting to write to it in user mode _must_ trigger a general protection fault.

All CRs prefixed by `INT_` are only accessible in system mode. Attempting to access them in user mode _must_ trigger a general protection fault.

At startup, the `PRIV` CR must be set to 1.

# Added Instructions

The instruction `1000 1111 0000 0010`, referred to as `halt`, is now only usable in system mode. Attempting to use it in user mode _must_ trigger
a general protection fault. When this instruction is executed in system mode, the CPU stops executing further instructions until an interrupt occurs.

**Note:** The `halt` instruction is similar to the relative jump by 0 instruction, but the instruction pointer still advances to the next instruction
with `halt` unlike the relative jump by 0 instruction.

# Interrupt Flow

The interrupt flow is modified by adding the following additional requirements.

In order to handle an interrupt, the CPU _must_ also do the following beforehand.

1. Set the `INT_RET_PRIV` CR to the current `PRIV` CR.
2. Set the `PRIV` CR to 1.

When the `IRET` instruction is encountered, the following _must_ also occur

1. Set the `PRIV` CR to the `INT_RET_PRIV` CR.
