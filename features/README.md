# Features

| FEAT bit  | Feature                                                   | State             |
|:---------:|-----------------------------------------------------------|-------------------|
|     0     | [Von Neumann](./von-neumann)                              | Mostly Stable     |
|     1     | [Unaligned Memory Access](./unaligned-memory)             | Mostly Stable     |
|     2     | [Cache Coherency](./cache-coherency)                      | Under Development |


Features are a second type of extension that are considered to be UB if they are used on a CPU that does not implement them. They differ from normal extensions in that they do not cause an interrupt when used in an unsupported system with the interrupts extension present.
