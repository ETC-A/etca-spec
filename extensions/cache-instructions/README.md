# General design

**Extension State: Under Development**  
**Requires: Base**  
**CPUID Bit: CP1.6**

# Overview

This extension adds several instructions which can be used to control the data and instruction cache if they are present. While the `ALLOC_ZERO` instruction _must_ appear like
a write of 0 to the cache line specified by the address, the other 7 instructions _may_ be implemented as NOP instructions (see special cases below). This extension does __NOT__ require that an instruction
cache or data cache is present.

# Added Instructions

| Name                   | 1st Byte     | 2nd Byte     | Description                                                                                                             |
|------------------------|--------------|--------------|-------------------------------------------------------------------------------------------------------------------------|
| `ALLOC_ZERO`           | `00 SS 1111` | `AAA 000 00` | Sets the data cache entry for the address specified by the A register to 0 without first reading the value from memory. |
| `DCACHE_INVALIDATE`    | `00 SS 1111` | `AAA 001 00` | Invalidates the data cache entry for the address specified by the A register without flushing it.                       |
| `CACHE_INVALIDATE_ALL` | `00 11 1111` | `000 100 01` | Invalidates ALL caches. Useful for CPU resets and possibly for inter-process security.                                  |
| `CACHE_FLUSH_ALL`      | `1000 1111`  | `000 000 01` | Flushes ALL dirty caches. Possibly useful for inter-process security.                                                   |
| `DATA_PREFETCH`        | `1001 1111`  | `AAA 000 00` | Prefetches the memory at the address in the register specified by A into the data cache.                                |
| `INSTRUCTION_PREFETCH` | `1001 1111`  | `AAA 000 01` | Prefetches the memory at the address in the register specified by A into the instruction cache.                         |
| `DCACHE_FLUSH`         | `1001 1111`  | `AAA 000 10` | Flushes the data cache entry for the address specified by the A register.                                               |
| `ICACHE_INVALIDATE`    | `1001 1111`  | `AAA 000 11` | Invalidates the instruciton cache entry for the address specified by the A register.                                    |

Note that the last 5 instructions overlap with the never jump instruction. This is intentional since these instructions shouldn't change the behavior of a program in most cases.

`ALLOC_ZERO` and `DCACHE_INVALIDATE` ignore the `SS` bits and the value in the `A` register is treated as address-sized.

### Special cases for implementations

- On a system without a data cache, `ALLOC_ZERO` _must_ be a NOP instruction.
- On a system with an instruction cache which is not fully synchronized with the data cache (or memory when a data cache is not present), `ICACHE_INVALIDATE` _must_ not be a NOP instruction.
- On a system with an instruction cache which is not fully synchronized with the data cache (or memory when a data cache is not present), `CACHE_INVALIDATE_ALL` _must_ not be a NOP instruction.

# Added Control Registers

| CRN      | Name               |
|----------|---------------------|
| `0 1110` | `CACHE_LINE_SIZE` |
| `0 1111` | `NO_CACHE_START`  |
| `1 0000` | `NO_CACHE_END`    |

`CACHE_LINE_SIZE` is a read-only control register which specifies the number of bytes in a cache line for the data cache. It _must_ be a power of 2 unless no data cache is present
in which case it _must_ be 0.

`NO_CACHE_START` is a cache-aligned address which represents the inclusive start of a contiguous range of physical memory addresses which will not be cached when accessed. If the privilege extension is present, this is only accessible in system mode.
This control register is set to 0 on CPU initialization.

`NO_CACHE_END` is a cache-aligned address which represents the inclusive end of a contiguous range of physical memory addresses which will not be cached when accessed. If the privilege extension is present, this is only accessible in system mode.
This control register is set to `-CACHE_LINE_SIZE` on CPU initialization.

## Notes on `NO_CACHE_START` and `NO_CACHE_END`

- The purpose of the initial values for these control registers is to intially disable caching since the location of MMIO is unknown.
- When writing to these control registers, the value will be sign extended from the write width to the maxiumum supported physical address width.
- Writing a non-cache-aligned value is _unspecified_ behavior
- If `NO_CACHE_START` is larger than `NO_CACHE_END`, the non-cacheable address range wraps past the end of the address space back to the beginning.
