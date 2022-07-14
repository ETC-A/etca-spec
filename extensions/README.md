# Extensions

| CPUID1 bit | Extension                                                 | Dependencies  | State             |
|:----------:|-----------------------------------------------------------|:-------------:|-------------------|
|     0      | [Full Immediate](./full-immediates)                       | VWI           | Under Development |
|     1      | [Stack & Functions](./stack-and-functions)                | None          | Mostly Stable     |
|     2      | Interrupts                                                | CP1.1         | Planned           |
|     3      | [8 Bit Operations + Registers](./half-word-operations)    | None          | Mostly Stable     |
|     4      | [Conditional Execution](./conditional-prefix)             | VWI           | Under Development |
|     5      | [Expanded Registers](./expanded-registers)                | VWI           | Under Development |
|     6      | Cache Instructions                                        | VWI           | Planned           |
|     7      | [Arbitrary Stack Pointer](./arbitrary-stack-pointer)      | CP1.1         | Under Development |
|     13     | [Memory Operands 2](./memory-operands-2) (MO2)            | VWI           | Under Development |
|     14     | [32 Bit Operations + Registers](./double-word-operations) | None          | Mostly Stable     |
|     15     | [64 Bit Operations + Registers](./quad-word-operations)   | None          | Mostly Stable     |
|     16     | 32 Bit Address Space                                      | CP1.14        | Planned           |
|     17     | Virtual Memory + 32 Bit Paging                            | CP1.16, CP2.2 | Planned           |
|     32     | 64 Bit Address Space                                      | CP1.15        | Planned           |
|     33     | Virtual Memory + 64 Bit Paging                            | CP1.32, CP2.2 | Planned           |


| CPUID2 bit | Extension                                                 | Dependencies  | State             |
|:----------:|-----------------------------------------------------------|:-------------:|-------------------|
|     0      | [Expanded Opcodes](./expanded-opcodes)                    | VWI           | Under Development |
|     1      | [Memory Operands 1](./memory-operands-1) (MO1)            | VWI           | Under Development |
|     2      | [Privileged Mode](./privileged-mode)                      | CP1.2         | Under Development |
|     3      | Bit Manipulation 1                                        | CP2.0         | Planned           |
|     4      | Bit Manipulation 2                                        | CP2.0         | Planned           |


The column Dependencies gives the CPUIDs of the required other extensions (base and recursive requirements are implied). For example, the Interrupts extension, with bit ID 2, depends on "Stack and Functions", with bit ID 1.  Note that only required dependencies are listed. Optional dependencies/interactions with other extensions are not listed here. For example, many extensions will have some interactions with VWI or the byte operations extensions, but those are not visible in the above table.
