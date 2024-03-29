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
| `0100` | `INT_PC`      | Specifies where the system interrupt handler is located in memory.                                |         |
| `0101` | `INT_RET_PC`  | Stores the address that the system interrupt should return to.                                    |         |
| `0110` | `INT_MASK`    | Specifies the mask for system interrupts.                                                         | (1)     |
| `0111` | `INT_PENDING` | Records which system interrupts are pending.                                                      | (1) (3) |
| `1000` | `INT_CAUSE`   | Stores the cause of the current system interrupt.                                                 | (2) (3) |
| `1001` | `INT_DATA`    | Stores data relevant to the interrupt.                                                            | (3)     |
| `1010` | `INT_SCRATCH_0` | A scratch register available for privileged use.                                     | (4)     |
| `1011` | `INT_SCRATCH_1` | A second scratch register available privileged use. | (4)     |

When the CPU is first initialized, `INT_MASK` should be set to 0.

As a reminder, if [Privileged Mode](../privileged-mode/README.md) is supported, control registers whose names begin with `INT_` are only accessible in system mode. Attempts to access them in user mode
must trigger a #GP fault.

1) This is a bitfield where each bit corresponds to a specific interrupt based on the table below.
2) This stores the number which refers to the current interrupt. It's value is the bit number in the mask and pending control registers.
3) These control registers are not writable through the `writecr` instruction and are effectively read-only. Writing to them is a NOP.
4) The intent of these registers is to provide a space to save general-purpose registers at the start of an interrupt handler to get the scratch (general-purpose) registers necessary to set up a stack. This is necessary on systems not supporting [FI](../full-immediates/README.md) nor [MO1](../memory-operands-1/README.md). Regardless, they are available for any (privileged) purpose.

## Flags CR

The following table specifies which flag is associated with which bit in the `FLAGS` CR. Unused bits are reserved for future extensions

| Bit | Flag     |
|-----|----------|
| 0   | Zero     |
| 1   | Negative |
| 2   | Carry    |
| 3   | Overflow |

# Added Interrupts

| Name                     | Type         | Mask/Pending Bit | Description                                                                                                        |
|:-------------------------|:-------------|:-----------------|:-------------------------------------------------------------------------------------------------------------------|
| System Call              | Synchronous  | 0                | Used by programs to ask the operating system to do something.                                                      |
| Timer                    | Asynchronous | 1                | Occurs when a timer causes an interrupt.                                                                           |
| Illegal Instruction      | Synchronous  | 2                | Occurs when execution of a reserved, or illegal instruction is attempted.                                          |
| Memory Alignment Error   | Synchronous  | 3                | Occurs when an attempt to read or write to memory at an unaligned address occurs and is not supported.             |
| General Protection Fault | Synchronous  | 4                | Occurs when the CPU needs the operating system to handle an unexpected event for stability or consistency reasons. |
| Divide Error             | Synchronous  | 5                | Occurs when a division by zero is attempted.                                                                       |
| External Interrupt       | Asynchronous | 8                | Occurs when an external interrupt occurs (eg. keyboard, mouse, etc.).                                              |

Synchronous interrupts are interrupts which are triggered directly by the currently running code and must be handled immediately before normal execution can resume.  
Asynchronous interrupts are interrupts which are triggered by another piece of hardware or indirectly from code and do not need to be handled immediately.

Unused mask/pending bits are reserved for future extensions. External interrupt is at bit 8 to leave a bit of space for other internal exceptions.

# Added Instructions

The following opcodes are now defined. The bits which are normally reserved for specifying operation/operand size are repurposed here.

| Name   | First Byte    | Second Byte  | Description                                                                                                                                                                                                                                |
|:-------|:--------------|:-------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `SYSCALL` | `00 00 1111`  | `000 100 01` | Causes a system call interrupt.                                                                                |
| `ERET`    | `00 01 1111`  | `000 100 01` | Returns from the current exception handler. Executing this when not in an exception handler causes a General Protection Fault. |

The operating system or kernel ABI must specify how to pass service numbers and service arguments when using `syscall`. Our expectation is that they be passed in general-purpose registers specified by the ABI, but we set no requirements.

Note: the term "exception handler" applies to handlers for all exceptional situations: interrupts, faults, and `syscall`.

# Interrupt Flow

CPU interrupts from external hardware are rising edge triggered.

If a synchronous interrupt occurs while the CPU is already handling another interrupt, the CPU _must_ reset or halt execution as there is no way for it to handle the interrupt. If the CPU is not handling an interrupt
when a synchronous exception occurs, the system state is _restored_ to just before the execution of the current instruction began (transparent state such as caches need not be restored).
Then, the corresponding bit in the `INT_PENDING` CR will be set and the CPU will immediately transition to handling that exception.
This means that the CPU _must_ be in the same effective state as before execution of the instruction was attempted aside from changes specified below. One of the
implied effects of this is that the `INT_RET_PC` CR points to the instruction which caused the interrupt. Another implied effect is that synchronous interrupts _cannot_ be masked.

When an asynchronous interrupt occurs, the relevant bit in the pending interrupt CR will be set. If the CPU is not handling an interrupt and any bit in the result of ANDing the `INT_PENDING` CR with the `INT_MASK` CR
is set, the interrupt for the lowest set bit of that result will be handled. This _must not_ be checked
during the execution of an instruction; that is, interrupt handling can only begin between instructions.
This _should_ be checked as soon as possible, however, exact timing is system dependent. Systems are permitted to wait to allow them to ensure progress during interrupt storms, or for microarchitectural reasons.

In order to handle an interrupt, the CPU _must_ do the following.

1. Set the `INT_CAUSE` CR to the bit index of the interrupt to be handled based on the table above.
2. Set the `INT_DATA` CR based on the following:
    - If the cause is a memory alignment error, use the address that caused the error.
    - If the cause is an external interrupt, and some (system-dependent) value can be used to identify the device which caused the interrupt (possibly externally supplied), that value is used.
    - Otherwise the value is _unspecified_.
3. Set the `INT_RET_PC` CR to the current `PC` register.
4. Set the `PC` register to the value in the `INT_PC` CR.
5. Mark that it is handling an interrupt. This is to prevent multiple interrupts from being handled at the same time.

At this point, the CPU can now resume code execution. When the `ERET` instruction is encountered, the following _must_ occur.

1. Set the `PC` register to the value in `INT_RET_PC`.
2. Mark that it is no longer handling an interrupt.

At this point, the CPU can now resume code execution.

Note: As always, systems are only required to maintain the _effect_ of the steps described. So, if another interrupt would immediately be handled, redundant steps that would occur when returning from an exception and immediately entering another may be optimized away.

# Reset Semantics

When the CPU resets, it _must_ set all registers and control registers to their initial values if one is specified.
