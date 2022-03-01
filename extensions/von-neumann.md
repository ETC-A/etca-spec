# General design

#### Extension State: Under Development
#### Enabled by default: yes
#### Always enabled: no (?)
#### Requires: Base

* Instruction memory and data memory must share an address space.
* If an address is both readable and executable, reading from that address must return the value of the instruction there.
* If an address is both writeable and executable, writing to that address and then executing it _should_ execute the written
  instruction, but this specification does not require the type of "instruction cache coherence" protocols that this might entail.
* Any address mapped to RAM must be readable. If it is also writeable, then writing to such an address and then reading it _must_ return the
  written value, even if that address is also executable.

Other situations left unspecified by Base remain as undefined behavior. This is to allow maximum freedom in mapping addresses to
firmware or I/O devices while still ensuring that programmers can expect reasonable memory behavior.

We specify 4 levels of this extension, stored in 2 bits of the CPUID and EXTEN control registers. A mode being enabled implies
that all modes lower than it are also enabled. CPUID must reflect the highest available level. Changing the level of this extension
is to be a privileged action. When attempting to set the level, the actual level set must be the lowest level which is greater
than or equal to the requested level. This ensures backwards compatibility across devices which do not support all levels, but
support for example "level 0 or level 3."

| Level | Concept | Description
|-------|:--------|:-----------
| 0 | Base | No guarantees beyond those specified by Base.
| 1 | Shared-Readable | Instructions and data must share an address space. Any address which is executable must be readable.
| 2 | Shared-W^X | All RAM addresses must be either writeable or executable, but not necessarily both. This specification does _not_ prevent a future extension from specifying a way to change whether a particular address is writeable or executable.
| 3 | Shared | A RAM address can be simultaneously writeable and executable. Each address _should_ be in this state by default. A privileged mechanism should exist (specified by a different extension) to change the properties of some address(es).

# Added Instructions

None.
