# Extensions

| CPUID bit | Extension                                                 | Dependencies | State             |
|:---------:|-----------------------------------------------------------|:------------:|-------------------|
|     0     | Memory Mode Operations + Expanded Immediates              | VWI          | Planned           |
|     1     | [Stack & Functions](./stack-and-functions)                | None         | Under Development |
|     2     | Interrupts                                                | 1            | Planned           |
|     3     | [8 Bit Operations + Registers](./half-word-operations)    | None         | Under Development |
|     4     | [Conditional Execution](./conditional-prefix)             | VWI          | Under Development |
|     5     | [Expanded Registers](./expanded-registers)                | VWI          | Under Development |
|     6     | Privileged Mode                                           | 2            | Planned           |
|     7     | Cache Instructions                                        | VWI          | Planned           |
|     8     | Expanded Opcodes                                          | VWI          | Planned           |
|     9     | [32 Bit Operations + Registers](./double-word-operations) | None         | Under Development |
|     10    | 32 Bit Address Space                                      | 9            | Planned           |
|     11    | Virtual Memory + 32 Bit Paging                            | 6, 10        | Planned           |
|     12    | [64 Bit Operations + Registers](./quad-word-operations)   | None         | Under Development |
|     13    | 64 Bit Address Space                                      | 12           | Planned           |
|     14    | Virtual Memory + 64 Bit Paging                            | 6, 13        | Planned           |


The column Dependencies gives the CPUIDs of the required other extensions (base and recursive requirements are implied). For example, the Interrupts extension, with bit ID 2, depends on "Stack and Functions", with bit ID 1.  Note that only required dependencies are listed. Optional dependencies/interactions with other extensions are not listed here. For example, many extensions will have some interactions with VWI or the byte operations extensions, but those are not visible in the above table.
