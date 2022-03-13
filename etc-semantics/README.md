# ETC.A Semantics

This subdirectory is for maintaining the complete formal semantics of ETC.A implemented in the K Framework language.

I am still working on implementing some of the configurability. For now, I/O on any port happens through `stdin` and `stdout`.

## K Framework

`KETC` requires the K Framework to be on your path for both building and executing. The K Framework is only aimed at Linux, but it works just fine in WSL 2 if you must use windows.

You can get the most recent release of k-framework from [their github repository](https://github.com/runtimeverification/k/releases/tag/v5.2.94).

## Installation

The `ketc` script in this directory is **not** the `ketc` executable. It is a build artifact which is copied by the `Makefile` when `ketc` is installed. In order to build `ketc`, make sure that the K Framework is installed and on your path. Then run
```bash
$ make build RELEASE=true
```

If you're like me, and you like seeing the output from the compilation as it happens, you can add `VERBOSE=true` as well.

This will probably take a little bit.

After building, the built package should be in `./.build/usr/bin`. You can add that directory to your `PATH` if you don't want to install further.

If you would like to install `ketc`, you can now run `sudo make install` which will copy everything from the build directory to the global install directory. `sudo` is required because `/usr` is protected. As always when using `sudo`, please make sure you understand what the command is doing and don't run anything that you don't trust! :)

## Running

Once installed (either to the build directory or globally), you can run an assembled ETC.A program with `ketc run [FILE]`. The file should be a binary file containing the machine code of the program.

#### Currently Implemented Extensions

We currently implement the following extensions:
* bit 4: Byte Operations
* bit 6: Doubleword Operations
* bit 7: Quadword Operations

#### Machine Mode

`ketc` does not currently understand any kind of ELF- or other object file format that specifies what mode it should run in. By default, the `CPUID` will be 0. You can use `ketc run --cpuid N [FILE]` to use a different `CPUID`.

Currently, if you enable a `CPUID` bit referring to an extension which we have not implemented, it will be silently ignored. In the future, this will hopefully produce a nicer error message.

There is no facility to set the initial `EXTEN`. Extensions are automatically initialized based on the value of `CPUID`.

# Contents

The `etc-driver.md` file is the main file. When `ketc` is compiled, this file governs which files and modules are included in the definition.

The ETC.A semantics are comprised of the following files:
* `etc.md`: describes the configuration and state of an ETC.A machine.
* `etc-types.md`: defines the datatypes used by an ETC.A machine, including word sizes, registers, memory, etc.
* `flags.md`: defines an interface to the machine flags, for both writing them and checking conditions.

The semantics of ETC.A's Base instruction set is comprised of:
* `simple-instructions.md`: defines utility sorts for implementing common instruction behaviors.
* `base/spec.md`: base instruction formats, decoding them, and executing them.

The semantics of ETC.A extensions are comprised of:
* `extension.md`: defines an interface to the EXTEN bits which extensions can implement
* `byte-operations/spec.md`: defines the semantics of the Byte Operations extension.

# Questions

Please ask any questions! Direct them to the `#community-architecture` channel in the Turing Complete discord server, or to an issue on this repository.
