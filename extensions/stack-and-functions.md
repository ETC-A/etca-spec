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
| `00 SS 1100`  | `RRR ?????`  | pop from stack                                |
| `00 SS 1101`  | `??? RRR ??` | push register to stack                        |
| `01 SS 1101`  | `??? IIIII`  | push immediate to stack                       |
| `10 1 0 CCCC` | `RRR 0????`  | (conditional) absolute register jump          |
| `10 1 0 CCCC` | `RRR 1????`  | (conditional) absolute register function call |
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

| `CCCC` | NAME    | Operation                                 | Flags  |
|--------|---------|-------------------------------------------|--------|
| `1100` | `POP`   | <code>A ← mem[SP + 2]; SP ← SP + 2</code> | None   |
| `1101` | `PUSH`  | <code>mem[SP] ← B; SP ← SP - 2</code>     | None   |

### Immediate mode

| `CCCC` | NAME    | Operation                                 | Flags  |
|--------|---------|-------------------------------------------|--------|
| `1101` | `PUSH`  | <code>mem[SP] ← B; SP ← SP - 2</code>     | None   |

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
