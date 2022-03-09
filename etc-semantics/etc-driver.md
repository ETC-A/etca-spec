```k
requires "etc.md"
requires "etc-types.md"
requires "extension.md"
requires "flags.md"
requires "simple-instructions.md"

requires "base/spec.md"

module ETC-DRIVER
    imports ETC
    imports BASE
    imports EXTENSION
endmodule

module ETC-DRIVER-SYNTAX
    imports BYTES-SYNTAX
endmodule
```