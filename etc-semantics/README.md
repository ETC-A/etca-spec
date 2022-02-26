# ETC.A Semantics

This subdirectory will hopefully eventually contain a complete formal semantics of ETC.A implemented in the K Framework language.

The current semantics file is incorrect in a few ways. It's just a prototype/proof of concept. Do NOT treat the derived interpreter as a reference interpretation. It's wrong.

You can get the most recent release of k-framework from [their github repository](https://github.com/runtimeverification/k/releases/tag/v5.2.94).

To build, `kompile etc.md`. It will take a little bit. Then you can run `krun pgm` to run the included program, which is `add A,1; slo A,5`. Run `cat pgm` to see the syntax that the derived interpreter expects.

Please ask any questions, as we are not yet sure if we want to put the effort into maintaining this from the start.
