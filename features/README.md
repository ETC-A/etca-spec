# Features

| FEAT bit  | Feature                                                   | State             |
|:---------:|-----------------------------------------------------------|-------------------|
|     0     | [Von Neumann](./von-neumann)                              | Under Development |
|     1     | [8 Bit Operations + Registers](./half-word-operations)    | Under Development |
|     2     | [32 Bit Operations + Registers](./double-word-operations) | Under Development |
|     3     | [64 Bit Operations + Registers](./quad-word-operations)   | Under Development |


Features is a second set of extensions that follow are considered to be UB if they are used on a CPU that does not implement them. This differs from normal extensions in that they cause an interrupt when used with the interrupts extension present and enabled.
