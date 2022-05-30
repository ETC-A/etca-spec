# General design

**Extension State: Under Development**  
**Enabled by Default: Yes**  
**Requires: Base**  
**CPUID1 Bit: 1**

# Overview

This extension adds instructions to allow for convenient use of the stack as well as instructions for function calls. It also provides a recommended usage for each register to minimize the time spent unneccesarily pushing and popping registers to and from the stack.

| Register | Alias     | Who saves it |
|----------|-----------|--------------|
| `r0`     | `a0`/`v0` | Caller Saved |
| `r1`     | `a1`/`v1` | Caller Saved |
| `r2`     | `a2`      | Caller Saved |
| `r3`     | `s0`      | Callee Saved |
| `r4`     | `s1`      | Callee Saved |
| `r5`     | `bp`      | Callee Saved |
| `r6`     | `sp`      | Callee Saved |
| `r7`     | `ln`      | Caller Saved |

- aN registers are argument registers and store the first N arguments to a function call. Additional arguments should be pushed to the stack.
- vN registers are the first N return values to a function call. Additional return values should be pushed to the stack.
- sN registers are registers that must be saved before re-using.
- tN registers are temporary registers which a function can use however it wants.
- bp is the base pointer register and stores the address of the bottom of the stack for this function.
- sp is the stack pointer register and stores the address of the top of the stack for this function. This is hardcoded into the push and pop instructions
- ln is the link register and stores the address that this function should return to. This is hard coded into the call and return instructions

# Added Instructions

The following opcodes are now defined.

| First byte    | Second Byte  | Comment                                                       |
|:--------------|:-------------|:--------------------------------------------------------------|
| `00 SS 1100`  | `RRR 110 00` | pop from stack                                                |
| `00 SS 1100`  | `RRR ??? ??` | when `??? ??` is not `110 00`, reserved for future extensions |
| `00 SS 1101`  | `110 RRR 00` | push register to stack                                        |
| `00 SS 1101`  | `??? RRR ??` | when `??? ??` is not `110 00`, reserved for future extensions |
| `01 SS 1101`  | `110 IIIII`  | push immediate to stack                                       |
| `01 SS 1101`  | `??? IIIII`  | when `???` is not `110`, reserved for future extensions       |
| `10 1 0 1111` | `RRR 0 CCCC` | (conditional) absolute register jump                          |
| `10 1 0 1111` | `RRR 1 CCCC` | (conditional) absolute register function call                 |
| `10 1 0 ????` |              | when `????` is not `1111`, reserved for future extensions     |
| `10 1 1 DDDD` | `DDDDDDDD`   | relative unconditional function call                          |

| Symbol | Meaning                                    |
|--------|--------------------------------------------|
| C      | condition code bit                         |
| R      | register id                                |
| I      | immediate                                  |
| D      | signed displacement                        |
| S      | size (reserved)                            |
| ?      | reserved for extensions or another purpose |

## Added Calculation Opcodes

### Register mode

| `CCCC` | NAME    | Operation                                 | Flags  | Comment |
|--------|---------|-------------------------------------------|--------|---------|
| `1100` | `POP`   | <code>SP ← SP + 2; A ← mem[SP]</code>     | None   | (1)     |
| `1101` | `PUSH`  | <code>mem[SP] ← B; SP ← SP - 2</code>     | None   | (1)     |

### Immediate mode

| `CCCC` | NAME    | Operation                                 | Flags  | Comment |
|--------|---------|-------------------------------------------|--------|---------|
| `1101` | `PUSH`  | <code>mem[SP] ← B; SP ← SP - 2</code>     | None   | (1)     |

1) If the SS bits (as defined in the base specification) are 00, then instead of + or - 2, you'll do + or - 1. Similarly, if they're set to 10 or 11 it will be 4 or 8 respectively. This is only relevant if the 8 bit, 32 bit, or 64 bit operation extensions are enabled. Note that this can cause the stack pointer to become misaligned.

## Added Jump Instructions

| First Byte    | Second Byte  | Operation                   | Comment|
|---------------|--------------|-----------------------------|--------|
| `10 1 0 1111` | `RRR 0 CCCC` | <pre>IF CCCC:<br>  IP ← reg[RRR]<br>FI</pre> | (2) |

2) The conditional absolute register jump instruction will conditionally jump to the address stored inside `RRR`. Function returns can be performed by jumping to the address in the link register.

## Added Call Instructions

| First Byte    | Second Byte  | Operation | Comment |      
|--|--|--|--|
| `10 1 0 1111` | `RRR 1 CCCC` | <pre>IF CCCC:<br>  temp ← IP<br>  IP ← reg[RRR]<br>  reg[7] ← temp + 2<br>FI</pre> | (3) |
| `10 1 1 DDDD` | `DDDDDDDD`   | <pre>reg[7] ← IP + 2<br>IP ← IP + sign_extend(DDDDDDDDDDDD)</pre>                  | (4) |


3) The conditional absolute register function call will conditionally store the next instruction's address in the link register and jump to the address stored inside `RRR`.
4) The relative unconditional functional call will store the next instruction's address in the link register and jump to the address `{IP + DDDD DDDD DDDD}`. That is, the 12 bit displacement will be sign extended and added to the current instruction's address.

## Stack Semantics

- The stack grows down towards address 0.
- Before executing the call instruction, it is the callers job to ensure that SP is properly aligned to register width on systems that do not support unaligned memory access.

# Example Function Call Snippets

Here is an example of how a function call, header, and tail could look when only saving the `ln`, `bp`, and `sp` registers

## Call Site

```
push ln
call fun_addr
pop ln
```

## Function Prologue

```
push bp
bp = sp
```

## Function Epilogue

```
sp = bp
pop bp
jmp ln
```
