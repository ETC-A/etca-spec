# General design

**Extension State: Under Development**  
**Enabled by Default: Yes**  
**Requires: Base, CP1.1, FT.0**  
**CPUID Bit: CP1.2**

# Overview

This extension adds interrupts which allows for the separation of system management code from program code, allows external devices to communicate with the CPU, and allows for transparent exception handling.

# Added Control Registers

| CRN    | Name          | Description                                                                                       | Comment |
|:-------|:--------------|:--------------------------------------------------------------------------------------------------|:--------|
| `0011` | `FLAGS`       | Stores the ALU flags and allows them to be set to specific values.                                |         |
| `0100` | `INT_MASK`    | Specifies the mask for system interrupts.                                                         | (1)     |
| `0101` | `INT_PC`      | Specifies where the system interrupt handler is located in memory.                                |         |
| `0110` | `INT_SP`      | Specifies the stack pointer for the system interrupt handler.                                     |         |
| `0111` | `INT_CAUSE`   | Stores the cause of the current system interrupt.                                                 | (2)     |
| `1000` | `INT_PENDING` | Records which system interrupts are pending.                                                      | (1)     |
| `1001` | `INT_RET_SP`  | Stores the stack pointer that the system interrupt should restore after the interrupt is handled. |         |
| `1010` | `INT_RET_PC`  | Stores the address that the system interrupt should return to.                                    |         |

When the CPU is first initialized, `INT_MASK` should be set to 0.

1) This is a bitfield where each bit corresponds to a specific interrupt based on the table below.
2) This stores the number which refers to the current interrupt. It's value is the bit number in the mask and pending control registers.

# Added Interrupts

| Name                     | Type         | Mask/Pending Bit | Description                                                                                                        |
|:-------------------------|:-------------|:-----------------|:-------------------------------------------------------------------------------------------------------------------|
| System Call              | Synchronous  | 0                | Used by programs to ask the operating system to do something.                                                      |
| Timer                    | Asynchronous | 1                | Occurs when a timer causes an interrupt.                                                                           |
| Illegal Instruction      | Synchronous  | 2                | Occurs when execution of an undefined, reserved, or illegal instruction is attempted.                              |
| Memory Alignment Error   | Synchronous  | 3                | Occurs when an attempt to read or write to memory at an unaligned address occurs and is not supported.             |
| General Protection Fault | Synchronous  | 4                | Occurs when the CPU needs the operating system to handle an unexpected event for stability or consistency reasons. |
| External Interrupt       | Asynchronous | 5                | Occurs when an external interrupt occurs (eg. keyboard, mouse, etc.).                                              |

Synchronous interrupts are interrupts which are triggered directly by the currently running code and must be handled immediately before normal execution can resume.  
Asynchronous interrupts are interrupts which are triggered by another piece of hardware or indirectly from code and do not need to be handled immediately.

# Added Instructions

The following opcodes are now defined. The bits which are normally reserved for specifying operation/operand size are repurposed here.

| Name   | First byte    | Second Byte | Description                                                                                                                                          |
|:-------|:--------------|:------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------|
| `INT`  | `00 00 1111`  | `????????`  | Causes a software interrupt. The second byte is not processed as normal and is only used as a way to specify an operation for the interrupt handler. |
|        | `00 01 1111`  | `????????`  | Reserved for future extensions.                                                                                                                      |
| `IRET` | `00 10 1111`  | `0000 0000` | Returns from the current interrupt. Executing this when not in an interrupt causes a General Protection Fault.                                       |
|        | `00 1? 1111`  | `???? ????` | When `? ???? ????` is not `0 0000 0000`, reserved for future extensions.                                                                             |

# Interrupt Flow

CPU interrupts from external hardware are rising edge triggered.

If a synchronous interrupt occurs while the CPU is already handling another interrupt or the corresponding bit in the `INT_MASK` CR is unset, the CPU _must_ reset as there is no way for it to handle the interrupt.
If the CPU is not handling an interrupt when a synchronous interrupt occurs and the corresponding mask bit is set, then the corresponding bit in the `INT_PENDING` CR will be set and the CPU will immediately
transition to handling that interrupt without finishing it's current instruction. This means that the CPU _must_ be in the same effective state as before execution of the instruction was attempted aside from what is
required to handle the interrupt caused by the exceptional instruction. One of the implied effects of this is that the `INT_RET_PC` CR points to the instruction which caused the interrupt.

When an asynchronous interrupt occurs, the relevant bit in the pending interrupt CR will be set. If the CPU is not handling an interrupt and any bit in the result of ANDing the `INT_PENDING` CR with the `INT_MASK`
CR is set, the interrupt for the lowest set bit of that result will be handled.

In order to handle an interrupt, the CPU _must_ do the following.

1. Set the `INT_CAUSE` CR to the bit index of the interrupt to be handled based on the table above.
2. Set the `INT_RET_SP` CR to the current `SP` register.
3. Set the `INT_RET_PC` CR to the current `PC` register.
4. Set the `PC` register to the value in the `INT_PC` CR.
5. Set the `SP` register to the value in the `INT_SP` CR.
6. Mark that it is handling an interrupt. This is to prevent multiple interrupts from being handled at the same time.

At this point, the CPU can now resume code execution. When the `IRET` instruction is encountered, the following _must_ occur

1. Set the `PC` register to the value in `INT_RET_PC`.
2. Set the `SP` register to the value in `INT_RET_SP`.
3. Mark that it is no longer handling an interrupt.

At this point, the CPU can now resume code execution.
