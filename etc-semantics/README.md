# ETC.A Semantics

This subdirectory is for maintaining the complete formal semantics of ETC.A implemented in the K Framework language.

I am still working on implementing some of the configurability. For now, I/O on any port happens through `stdin` and `stdout`. I will also provide a makefile soon that packages `ketc` up to into a script for executing programs.

You can get the most recent release of k-framework from [their github repository](https://github.com/runtimeverification/k/releases/tag/v5.2.94).

To build, `kompile etc-driver.md`. It will take a little bit. Then you can run `krun test_jumps` to run the included program, which contains the assembled `test_jumps.asm` program from the `customasm` directory of this repo.

Please ask any questions! Direct them to the `#community-architecture` channel in the Turing Complete discord server, or to an issue on this repository.
