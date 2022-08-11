# Features

| FEAT bit  | Feature                                                   | State             |
|:---------:|-----------------------------------------------------------|-------------------|
|     0     | [Von Neumann](./von-neumann)                              | Mostly Stable     |
|     1     | [Unaligned Memory Access](./unaligned-memory)             | Mostly Stable     |
|     2     | [Cache Coherency](./cache-coherency)                      | Under Development |


Features are a second type of extension that __ONLY__ change behavior of the CPU without adding instructions, control registers, or any other similar aspect. They generally mandate a specific behavior when certain actions occur but do __NOT__
change how instructions are decoded.
