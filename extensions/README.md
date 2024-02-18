# Extensions

| CPUID1 bit | Extension                                                 | Abbr | Dependencies  | State             |
|:----------:|-----------------------------------------------------------|:----:|:-------------:|-------------------|
|     0      | [Full Immediate](./full-immediates)                       |  FI  |      VWI      | Under Development |
|     1      | [Stack & Functions](./stack-and-functions)                | SAF  |     None      | Mostly Stable     |
|     2      | [Interrupts](./interrupts)                                | INT  |  CP1.1, FT.0  | Under Development |
|     3      | [8 Bit Operations + Registers](./half-word-operations)    | BYTE |     None      | Mostly Stable     |
|     4      | [Conditional Execution](./conditional-prefix)             | COND |      VWI      | Under Development |
|     5      | [Expanded Registers](./expanded-registers)                | REX  |      VWI      | Under Development |
|     6      | [Cache Instructions](./cache-instructions)                |  CI  |     None      | Under Development |
|     7      | [Arbitrary Stack Pointer](./arbitrary-stack-pointer)      | ASP  |     CP1.1     | Under Development |
|     13     | [Memory Operands 2](./memory-operands-2)                  | MO2  |      VWI      | Under Development |
|     14     | [32 Bit Operations + Registers](./double-word-operations) |  DW  |     None      | Mostly Stable     |
|     15     | [64 Bit Operations + Registers](./quad-word-operations)   |  QW  |     None      | Mostly Stable     |
|     16     | [32 Bit Address Space](./32-bit-address-space)            | DWAS |    CP1.14     | Under Development |
|     17     | Virtual Memory + 16 Bit Paging                            | PG16 | CP1.16, CP2.2 | Planned           |
|     18     | Virtual Memory + 32 Bit Paging                            | PG32 | CP1.16, CP2.2 | Planned           |
|     32     | [64 Bit Address Space](./64-bit-address-space)            | QWAS |    CP1.15     | Under Development |
|     33     | Virtual Memory + 64 Bit Paging (48 bit VA)                | PG48 | CP1.32, CP2.2 | Planned           |
|     34     | Virtual Memory + 64 Bit Paging (57 bit VA)                | PG57 | CP1.32, CP2.2 | Planned           |
|     35     | Virtual Memory + 64 Bit Paging (64 bit VA)                | PG64 | CP1.32, CP2.2 | Planned           |


| CPUID2 bit | Extension                                | Abbr | Dependencies  | State             |
|:----------:|------------------------------------------|------|:-------------:|-------------------|
|     0      | [Expanded Opcodes](./expanded-opcodes)   | EXOP |      VWI      | Under Development |
|     1      | [Memory Operands 1](./memory-operands-1) | MO1  |      VWI      | Under Development |
|     2      | [Privileged Mode](./privileged-mode)     | PM   |     CP1.2     | Under Development |
|     3      | [Multiply Divide](./multiply-divide)     | MD   |     CP2.0     | Under Development |
|     4      | Bit Manipulation 1                       | BM1  |     CP2.0     | Planned           |
|    8-15    | Reserved for vendor specific extensions  |      |               | Stable            |
|   24-31    | Reserved for vendor specific extensions  |      |               | Stable            |
|   48-63    | Reserved for vendor specific extensions  |      |               | Stable            |


The column `Dependencies` gives the CPUIDs of the required other extensions (base and recursive requirements are implied). For example, the Interrupts extension, with bit ID 2, depends on "Stack and Functions", with bit ID 1.  Note that only required dependencies are listed. Optional dependencies/interactions with other extensions are not listed here. For example, many extensions will have some interactions with VWI or the byte operations extensions, but those are not visible in the above table.

The column `Abbr` list Abbreviations for all extensions. These are used internally in gnu toolchains, but are also quite common in chat discussions and will potentially be used as a UI for defining machine descriptions to pass to a C compiler.
