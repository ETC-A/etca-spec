```k
requires "etc.md"
requires "etc-types.md"
requires "extension.md"
requires "flags.md"
requires "simple-instructions.md"

requires "base/spec.md"
requires "width-extensions/width-extensions.md"
requires "width-extensions/byte-operations.md"
requires "width-extensions/doubleword-operations.md"
requires "width-extensions/quadword-operations.md"

module ETC-DRIVER
    imports ETC
    imports BASE

    imports EXTENSION
    imports MOVZ-EXTENSION
    imports BYTE-OPERATIONS
    imports DOUBLEWORD-OPERATIONS
    imports QUADWORD-OPERATIONS
endmodule

module ETC-DRIVER-SYNTAX
    imports BYTES-SYNTAX
endmodule
```