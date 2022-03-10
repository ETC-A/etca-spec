```k
requires "etc.md"
requires "etc-types.md"
requires "extension.md"
requires "flags.md"
requires "simple-instructions.md"

requires "base/spec.md"
requires "byte-operations/spec.md"

module ETC-DRIVER
    imports ETC
    imports BASE

    imports EXTENSION
    imports BYTE-OPERATIONS
endmodule

module ETC-DRIVER-SYNTAX
    imports BYTES-SYNTAX
endmodule
```