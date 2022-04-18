# Extensions

| CPUID bit | Extension                                                 | Dependencies | State             |
|:---------:|-----------------------------------------------------------|:------------:|-------------------|
|     0     | Memory Mode Operations + Expanded Immediates              | VWI          | Planned           |
|     1     | [Stack & Functions](./stack-and-functions)                | None         | Under Development |
|     2     | Interrupts                                                | 1            | Planned           |
|     3     | [Conditional Execution](./conditional-prefix)             | VWI          | Under Development |
|     4     | [Expanded Registers](./expanded-registers)                | VWI          | Under Development |
|     5     | Privileged Mode                                           | 2            | Planned           |
|     6     | Cache Instructions                                        | VWI          | Planned           |
|     7     | Expanded Opcodes                                          | VWI          | Planned           |
|     8     | 32 Bit Address Space                                      | F2           | Planned           |
|     9     | Virtual Memory + 32 Bit Paging                            | 5, 8         | Planned           |
|     10    | 64 Bit Address Space                                      | F3           | Planned           |
|     11    | Virtual Memory + 64 Bit Paging                            | 5, 10        | Planned           |


The column Dependencies gives the CPUIDs of the required other extensions (base and recursive requirements are implied). For example, the Interrupts extension, with bit ID 2, depends on "Stack and Functions", with bit ID 1.  Note that only required dependencies are listed. Optional dependencies/interactions with other extensions are not listed here. For example, many extensions will have some interactions with VWI or the byte operations extensions, but those are not visible in the above table. A dependency prefixed with an F means it depends on the feature with that bit ID
