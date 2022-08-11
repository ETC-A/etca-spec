# General design

**Feature State: Under Development**  
**FEAT Bit: 2**

* All caches are coherent. This means that any data written to the data cache automatically is propagated to the instruction cache. If multiple cores are present, their caches must also be coherent with each
other. Multi-level caches must also be coherent between levels.

### Concept / Intentionally vague

This removes the need to manually ensure that caches are coherent which allows for self-modifying code to no longer rely on manual synchronization between the data instruction cache.
