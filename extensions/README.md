# Extensions

| CPUID bit | Extension                                  | Requirements | State             |
|:---------:|--------------------------------------------|:------------:|-------------------|
|     0     | VWI                                        |              | Planned           |
|     1     | [Stack & Functions](./stack-and-functions) |              | Under Development |
|     2     | Interrupts                                 |      1       | Planned           |
|     3     | [Von Neumann](./von-neumann)               |              | Under Development |
|     4     | [Byte Operations](./byte-operations)       |              | Under Development |


The column Requirements gives the CPUIDs of the required other extensions (base and recursive requirements are implied). For example, the Interrupts extension, with bit ID 2, depends on "Stack and Functions", with bit ID 1.
