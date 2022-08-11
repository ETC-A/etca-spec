# General design

**Feature State: Mostly Stable**  
**FEAT Bit: 0**

* Instruction and data memories must share an address space.
* All addresses mapped to RAM _must_ be coherently readable and writeable. They must also be executable, but not necessarily coherently.
* A future extension describing NX bits, or other technology for controlling what memory addresses have which permissions, may modify these requirements. However, such extensions must not be enabled by default if a program which did not assume them as present could break.

### Concept / Intentionally vague

If the machine connects directly to memory (i.e. not through a cache), then RAM addresses _should_ be coherently executable. If the machine has an instruction cache (even if it does not have a data cache), that cache _may_ be incoherent with data memory.
