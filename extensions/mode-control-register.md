# Overview

This document describes the mode control register in a centralized location so that other extensions which use it can refer to a single document
instead of duplicating it between all relevant extensions. The mode control register adds a new concept of _modes_ to the ISA. Modes are used to
control things about the processor state which are binary-incompatible - that is, code written for a mode other than the mode the
processor is actually in will almost certainly behave incorrectly.

# Modes

CR `1 0001`, equivalently `cr17` or "the MODE control register," holds a value indicating the current
_mode_ of the processor.

![CR17 Layout](resources/vm-diagrams/cr17.svg)

The register contains a bit field with various bits controlling the behavior of address spaces.

| Bit | Name | Initial Value | Meaning |
|-----|------|---------------|---------|
| 0   | `VM` | `0` | When this bit is set, virtual memory is in use. Which extension specifically governs the addressing mode of the CPU depends on the other bits. |
| 1-2 | `PTRSZ` | `00` | These bits describe the width of logical addresses. `00` indicates 16 bits, `01` indicates 32, and `10` indicates 64. |
| 12  | `WP` | `1` | Short for "Write Protect," this bit controls the behavior of memory regions marked read-only. See below. |

All other bits are reserved, including bits above the 15th.

When the `WP` bit is 0 and the `PRIV` extension is available, in system mode any write access controls are ignored.
This allows system-priviledged code to modify memory marked write-only for the user. When `WP` is 1, write access
controls are enforced even for priviledged code.
When `PRIV` is not available, the `WP` bit controls the behavior of all code as if it were priviledged.
Allowing priviledged code to modify memory marked read-only is critical for implementing memory management software with
[16-bit Paging](16-bit-paging/README.md) or [32-bit Paging](32-bit-paging/README.md) enabled.

Note that `WP` only affects write protections described by "protected mode" extensions. Memory that is read-only for
some other reason, such as being mapped to a read-only device, remains read-only. However, enabling the `WP` protect
bit may cause an attempt to write such an address to trigger an exception rather than being silently ignored
(or worse, causing damage) which is helpful for finding kernel bugs.

## Base Mode (Real 16-bit Address Mode)

The mode described by [the base isa](../../base-isa.md) is known as the
Base mode. It is also known as Real 16-bit Address Mode.

In this mode, pointers are 16 bits and there is no virtual memory, paging, or memory protection.
Base mode is indicated by a value of 0 in `cr17`.

## Real n-bit Address Mode

In this mode, all addresses are treated as being `n` bits long. Addresses always refer to their sign extension to the highest supported address size.
Entering this mode from a smaller n-bit address mode _must_ preserve the program counter. Returning to a smaller n-bit address mode must preserve the program
counter _if possible_ - if the current program counter interpreted as the smaller n-bit Address would not refer to the same location, then the behavior of
the system is _unspecified_.

# Address Extension Table

| Mode CR Value | Logical Address Size | Virtual? | Extension                                                   |
|---------------|----------------------|----------|-------------------------------------------------------------|
| 0             | 16 bit               | No       | [Base ISA](../base-isa.md)                                  |
| 1             | 16 bit               | Yes      | [16-bit Paging](16-bit-paging/README.md)                    |
| 2             | 32 bit               | No       | [Real 32-bit Address Space](32-bit-address-space/README.md) |
| 3             | 32 bit               | Yes      | [32-bit Paging](32-bit-paging/README.md)                    |
| 4             | 64 bit               | No       | [Real 64-bit Address Space](64-bit-address-space/README.md) |

# Virtual Address Modes

In virtual addressing modes, also known as "protected" modes, addresses handled by the CPU
("logical" or "virtual" addresses)
may differ from the "physical addresses" used to communicate with memory and memory-mapped devices.
The process of translating from the logical addresses used within the CPU to the physical addresses used
externally is generally controlled by a hardware subsystem known as an MMU, or memory management unit.
(Implementations are **not** required to contain an MMU or equivalent subsystem -- this is simply a description
of _typical_ systems. A compliant system, of course, must only behave as specified.)

The addresses may differ by more than just a single constant value. Virtual addressing modes divide the
logical address space into chunks called "pages," and divide the physical address space into chunks of
the same size called "frames." Any page may be translated into any frame; there is no need for contiguous
pages to map to contiguous frames, to frames in ascending order, or any other such restriction.

<p align="middle">
  <img src="resources/vm-diagrams/mmu-translation-success.svg" width=140>
  <img src="resources/vm-diagrams/mmu-translation-fail.svg"    width=140>
</p>

Virtual address modes also make it possible to configure access protections for pages.
The MMU is also responsible for ensuring that the address is accessible. In the event of a disallowed access,
the MMU triggers #PF -- a "Page Fault exception." It is the job of software (usually a kernel, if PRIV is
available on the system) to handle this exception.
Using this feature, it is possible to reduce actual physical memory usage without reducing virtual address
space size, by marking pages inaccessible and not allocating a physical frame for those pages.
Handling of #PF can then include making the address accessible and allocating a frame before
returning to the interrupted instruction stream to retry the access. It can also involve terminating the
faulting instruction stream entirely if the issue indicates an unrecoverable bug.
Clearly, the ability to trigger #PF is fundamental to virtual memory.
Therefore all virtual address mode extensions require INT.

In some paging modes, the system supports physical addresses wider than the virtual addresses.
Unless the system also supports a wider Real address mode, those physical addresses are inaccessible while
paging is disabled, because there is no way to refer to them.
Implementations may offer some other mechanism to refer to such addresses.

## Address Translation

This section describes the general scheme of address translation in the presence of paging.
For specifics, including about the various involved data structures and extra CRs,
please see a specific extension document.

# Interactions With Other Extensions

Other extensions mention "address modes", in particular when deciding what a particular value
should mean or how many bytes an immediate should be.

| Address Size | Address Mode |
|--------------|--------------|
| 16 bit       | word         |
| 32 bit       | doubleword   |
| 64 bit       | quadword     |

If the system supports [privilege levels](../privileged-mode/), then `cr17` is only writable when in system privilege mode.

# Recommendations

These extensions do not _require_ behaviors beyond what is specified. However, for compatibility with future
extensions which will require more specifics, the following are recommended:

* The program counter (or equivalent) in the processor itself should always store the sign-extended address.
  This way, nothing special needs to be done when entering or leaving address modes with larger or smaller address sizes
