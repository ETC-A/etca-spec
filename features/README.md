# Features

| FEAT bit  | Feature                                                                      | Abbr | State             |
|:---------:|------------------------------------------------------------------------------|------|-------------------|
|     0     | [Von Neumann](./von-neumann)                                                 | VON  | Mostly Stable     |
|     1     | [Unaligned Memory Access](./unaligned-memory)                                | UMA  | Mostly Stable     |
|     2     | [Cache Coherency](./cache-coherency)                                         | CC   | Under Development |
|     3     | [Multiple Memory Access Instructions](./multiple-memory-access-instructions) | MMAI | Mostly Stable     |


Features are a second type of extension that __ONLY__ change behavior of the CPU without adding instructions, control registers, or any other similar aspect. They generally only mandate a specific behavior when certain otherwise unspecified actions occur.
