# General design

**Feature State: Mostly Stable**  
**FEAT Bit: 1**

* All memory accesses at arbitrary addresses work as if the backing memory had no alignment requirements. This does **NOT** mean they must perform the same, just that they must work as expected.

### Concept / Intentionally vague

The base specification states that unaligned memory accesses are _unspecified_ behavior. This feature defines that behavior to be what would be expected from a system that supports byte addressable memory accesses of any size.
