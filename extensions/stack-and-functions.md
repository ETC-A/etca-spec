# General design

**Extension State: Under Development**  
**Enabled by Default: Yes**  
**Always Enabled: Yes**  
**Requires: Base**  
**CPUID Bit: 1**

# Overview

This extension adds instructions to allow for convenient use of the stack as well as instructions for function calls. It also provides a recommended usage for each register to minimize the time spent unneccesarily pushing and popping registers to and from the stack.

| Register | Alias | Who saves it |
|----------|-------|--------------|
| `r0`     | `a0`  | Caller Saved |
| `r1`     | `a1`  | Caller Saved |
| `r2`     | `v0`  | Caller Saved |
| `r3`     | `s0`  | Callee Saved |
| `r4`     | `s1`  | Callee Saved |
| `r5`     | `bp`  | Callee Saved |
| `r6`     | `sp`  | Callee Saved |
| `r7`     | `ln`  | Caller Saved |

- aN registers are argument registers and store the first N arguments to a function call. Additional arguments should be pushed to the stack.
- vN registers are return value registers and store the return values from a function.
- sN registers are registers that must be saved before re-using.
- tN registers are temporary registers which a function can use however it wants.
- bp is the base pointer register and stores the address of the bottom of the stack for this function.
- sp is the stack pointer register and stores the address of the top of the stack for this function. This is hardcoded into the push and pop instructions
- ln is the link register and stores the address that this function should return to. This is hard coded into the call and return instructions

# Added Instructions

The following opcodes are now defined.

| First byte    | Second Byte  | Comment                                       |
|:--------------|:-------------|:----------------------------------------------|
| `00 01 1100`  | `RRR ??? 00` | pop from stack                                |
| `00 01 1101`  | `??? RRR 00` | push register to stack                        |
| `01 01 1101`  | `??? IIIII`  | push immediate to stack                       |
| `10 1 0 CCCC` | `RRR 00000`  | (conditional) absolute register jump          |
| `10 1 0 CCCC` | `RRR 10000`  | (conditional) absolute register function call |
| `10 1 1 IIII` | `IIIIIIII`   | absolute unconditional function call          |

| Symbol | Meaning                      |
|--------|------------------------------|
| C      | opcode bit                   |
| R      | register id                  |
| I      | immediate                    |
| S      | size (reserved)              |
| ?      | reserved for unknown purpose |

## Added Calculation Opcodes

### Register mode

| `CCCC` | NAME    | Operation                                 | Flags  | Comment |
|--------|---------|-------------------------------------------|--------|---------|
| `1100` | `POP`   | <code>A ← mem[SP + 2]; SP ← SP + 2</code> | None   | (1)     |
| `1101` | `PUSH`  | <code>mem[SP] ← B; SP ← SP - 2</code>     | None   | (1)     |

### Immediate mode

| `CCCC` | NAME    | Operation                                 | Flags  | Comment |
|--------|---------|-------------------------------------------|--------|---------|
| `1101` | `PUSH`  | <code>mem[SP] ← B; SP ← SP - 2</code>     | None   | (1)     |

1) If the SS bits (as defined in the base specification) are 00, then instead of + or - 2, you'll do + or - 1. Similarly, if they're set to 10 or 11 it will be 4 or 8 respectively. This is only relevant if the 8 bit, 32 bit, or 64 bit operation extensions are enabled

## Added Jump Instructions

- The conditional absolute register jump instruction will conditionally jump to the address stored inside `RRR`. Function returns can be performed by jumping to the address in the link register.

## Added Call Instructions

- The conditional absolute register function call will conditionally store the next instruction's address in the link register and jump to the address stored inside `RRR`
- The absolute unconditional functional call will store the next instruction's address in the link register and jump to the address specified by `III IIII IIII I000` for the lower 15 bits with any upper bits being preserved from the current instruction address.

# Example Function Call Snippets

Here is an example of how a function call, header, and tail could look when only saving the `ln`, `bp`, and `sp` registers

## Call Site

```
push ln
call fun_addr
pop ln
```

## Function Header

```
push bp
bp = sp
```

## Function Tail

```
sp = bp
pop bp
jmp ln
```
