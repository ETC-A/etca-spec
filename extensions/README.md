# Extensions

| CPUID bit | Extension                                  | Dependencies | State             |
|:---------:|--------------------------------------------|:------------:|-------------------|
|     0     | Expanded Immediates                        |     VWI      | Planned           |
|     1     | [Stack & Functions](./stack-and-functions) |     None     | Under Development |
|     2     | Interrupts                                 |      1       | Planned           |
|     3     | [Von Neumann](./von-neumann)               |     None     | Under Development |
|     4     | [Byte Operations](./byte-operations)       |     None     | Under Development |
|     5     | [Expanded Registers](./expanded-registers) |     VWI      | Under Development |
|     6     | 32 Bit Operations                          |     None     | Planned           |
|     7     | 64 Bit Operations                          |     None     | Planned           |
|     8     | Privileged Mode                            |      2       | Planned           |
|     9     | Cache Instructions                         |     VWI      | Planned           |
|     10    | Virtual Memory + Paging                    |      8       | Planned           |


The column Dependencies gives the CPUIDs of the required other extensions (base and recursive requirements are implied). For example, the Interrupts extension, with bit ID 2, depends on "Stack and Functions", with bit ID 1.  Note that only required dependencies are listed. Optional dependencies/interactions with other extensions are not listed here. For example, many extensions will have some interactions with VWI or the byte operations extensions, but those are not visible in the above table.
