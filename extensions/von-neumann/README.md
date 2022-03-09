# General design

**Extension State: Under Development**  
**Enabled by Default: Yes**  
**Requires: Base**  
**CPUID Bit: 3**

* Instruction and data memories must share an address space.
* All addresses mapped to RAM must be coherently readable and writeable. They must also be executable, but not necessarily coherently.
* A future extension describing NX bits, or other technology for controlling what memory addresses have which permissions, may relax these restrictions.
  However, such extensions must not be enabled by default if a program which did not assume their restrictions could break.

### Concept / Intentionally vague

If the machine connects directly to memory (i.e. not through a cache), then RAM addresses _should_ be coherently executable. If the
machine has an instruction cache (even if it does not have a data cache), that cache _may_ be incoherent with data memory. Such an
implementation must include at least one official caching extension that offers an instruction which acts as a cache coherence barrier.

Quote from Discord:
> maybe we just specify it as a single bit that says "addresses are shared, implementations need not keep a coherent instruction cache but all addresses mapped to RAM must be coherently readable and writeable, and must also be executable (but not necessarily coherently). A future extension describing NX bits may relax this restriction but (as that requires paging) must not be enabled by default."
