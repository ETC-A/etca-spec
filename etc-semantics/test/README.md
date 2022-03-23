# Concrete Tests

Each test in here is an assembly file and a golden output file (containing the whole output configuration).
These tests currently can't use in/out instructions.

Each test consists of:
* A comment containing extra arguments to pass to `etc-as` (empty if none)
* A comment containing the CPUIDs that that test should be run with. If empty, `0` is assumed.
* The assembly code to run.
Paired with a `testname.cpuid.expected` file for each specified `cpuid` containing the expected output.

Run `make build-test-concrete` (in the `etc-semantics` dir) to regenerate all of the files needed to run the tests. Then
run `make test-concrete` to run them. Outputs that differ from the expected output will be reported and saved. Outputs
that match will be cleaned up.

To accept a new differing output as being expected, perhaps after fixing a bug, replace `testname.cpuid.out` with `testname.cpuid.actual`. The make target `test/testname.cpuid.accept` can be used to do this automatically.

`build-test-concrete` requires `python3.10` to be installed and for `etc-as.py` to be on your path.