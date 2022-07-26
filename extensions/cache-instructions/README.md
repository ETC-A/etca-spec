# General design

**Extension State: Under Development**  
**Requires: Base**  
**CPUID Bit: CP1.6**

# Overview

This extension adds several instructions which can be used to control the data and instruction cache if they are present. While the `ALLOC_ZERO` instruction _must_ appear like
a write of 0 to the specified address, the other 6 instructions _may_ be implemented as NOP instructions. This extension does __NOT__ require that an instruction or data cache
are present.

# Added Instructions

| Name                   | 1st Byte    | 2nd Byte     | Description                                                                                                             |
|------------------------|-------------|--------------|-------------------------------------------------------------------------------------------------------------------------|
| `ALLOC_ZERO`           | `0000 1111` | `010 AAA 00` | Sets the data cache entry for the address specified by the A register to 0 without first reading the value from memory. |
| `DCACHE_INVALIDATE`    | `0000 1111` | `011 AAA 00` | Invalidates the data cache entry for the address specified by the A register without flushing it.                       |
| `CACHE_FLUSH_ALL`      | `1000 1111` | `000 000 01` | Flushes and invalidates ALL caches. Possibly useful for inter-process security.                                         |
| `DATA_PREFETCH`        | `1001 1111` | `000 AAA 00` | Prefetches the memory at the address in the register specified by A into the data cache.                                |
| `INSTRUCTION_PREFETCH` | `1001 1111` | `000 AAA 01` | Prefetches the memory at the address in the register specified by A into the instruction cache.                         |
| `DCACHE_FLUSH`         | `1001 1111` | `000 AAA 10` | Flushes and invalidates the data cache entry for the address specified by the A register.                               |
| `ICACHE_INVALIDATE`    | `1001 1111` | `000 AAA 11` | Invalidates the instruciton cache entry for the address specified by the A register.                                    |

Note that the last 5 instructions overlap with the never jump instruction. This is intentional since these instructions don't change a programs behavior.

# Added Control Registers

| CRN    | Name              |
| `1110` | `CACHE_LINE_SIZE` |

`CACHE_LINE_SIZE` is a read-only control register which specifies the number of bytes in a cache line for the data cache. It _must_ be a power of 2 unless no data cache is present
in which case it _may_ be 0.
