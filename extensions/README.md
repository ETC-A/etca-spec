# Extensions

| CPUID bit | Extension                                                 | Dependencies | State             |
|:---------:|-----------------------------------------------------------|:------------:|-------------------|
|     0     | Memory Mode Operations + Expanded Immediates              | VWI          | Planned           |
|     1     | [Stack & Functions](./stack-and-functions)                | None         | Under Development |
|     2     | Interrupts                                                | 1            | Planned           |
|     3     | [Conditional Execution](./conditional-prefix)             | VWI          | Planned           |
|     4     | [Expanded Registers](./expanded-registers)                | VWI          | Under Development |
|     5     | Privileged Mode                                           | 2            | Planned           |
|     6     | Cache Instructions                                        | VWI          | Planned           |
|     7     | Virtual Memory + Paging                                   | 5            | Planned           |
|     8     | Expanded Opcodes                                          | VWI          | Planned           |
|     9     | 32 Bit Address Space                                      | F2           | Planned           |
|     10    | 64 Bit Address Space                                      | F3           | Planned           |


The column Dependencies gives the CPUIDs of the required other extensions (base and recursive requirements are implied). For example, the Interrupts extension, with bit ID 2, depends on "Stack and Functions", with bit ID 1.  Note that only required dependencies are listed. Optional dependencies/interactions with other extensions are not listed here. For example, many extensions will have some interactions with VWI or the byte operations extensions, but those are not visible in the above table. A dependency prefixed with an F means it depends on the feature with that bit ID
