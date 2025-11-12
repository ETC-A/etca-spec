# Overview

This document describes ETCa's memory addressing modes in a centralized location referred to by many other extensions.
This central document describes many common, defining characteristics of several addressing modes.

Memory addressing modes are generally binary-incompatible: code running in a mode other than the mode it was
written for is almost certain to behave incorrectly.

# Added Instructions

This section is very WIP.

| Name   | First Byte  | Second Byte | Description  |
|--------|-------------|-------------|--------------|
| `INVLPG` | `TODO` | `TODO` | See [TLB Invalidation](#tlb-invalidation) below. |

The following instruction is required when the `CIDE` feature bit is present,
but _may_ be implemented even if the feature bit is not present.

| Name   | First Byte  | Second Byte | Description  |
|--------|-------------|-------------|--------------|
| `TLBI` | `TODO` | `TODO` | See [Context Identifiers](#optional-feature-cid) below. |

TODO: `TLBI` should be exop-format, but we've discussed modifying exop format encoding,
so I'm holding off on defining this for the moment.

> [!NOTE]
> The `CIDE` feature bit depends on the `EXOP` extension, but most mode-related extensions
> do not. The same purpose can be accomplished (much) less efficiently using the
> `INVLPG` instruction.

# Modes and Definitions

Memory addressing modes are mutually-exclusive operating modes which determine how
the system interprets memory addresses. Fundamentally, the differences lie in what
happens between when a value that should be an address is read from a register,
and when a corresponding (but possibly different) value is issued as an address to
access memory.

The CPU is always in exactly one mode, and the possibly modes can be broadly divided
into two categories: _real modes_ and _virtual modes_. Virtual modes are sometimes
called "protected" modes; these terms are interchangeable.

### Logical Addresses

In any case, a _logical address_ is a value in a general-purpose register that the
CPU will interpret as a memory address. The values in a few special-purpose
registers are also logical addresses but are subject to slightly different rules
from those in general-purpose registers. Depending on the current mode,
a logical address is either a physical address or a virtual address.
When logical addresses are read from **general-purpose** registers, only the
bits in the smallest subregister that can contain a logical address for the
current mode are considered. For example, in PG16 mode (with virtual 16-bit addresses),
a logical address in `%r0` is the value in `%rx0`. The bits of `%rd0` above the
15th are ignored. When logical addresses are read from the program counter or from
control registers, the behavior is unspecified; higher bits might be included
(in real modes, this can be useful), higher bits might be discarded,
or an exception is raised (this exception should be `#GP`).
Implementations are encouraged to document which behavior they follow.

> [!NOTE]
> This section has a subtle, but still required, implication for `lea` instructions.
> In a mode where logical addresses are 16 bits, the `lead` instruction
> reads _word-size_ subregisters to obtain logical addresses, performs the
> address calculation to obtain a _word-size_ address, and then _zero-extends_
> this address into the double-word destination register.
> The analogous behavior is the case for `leaq` under 16- or 32-bit addressing
> modes.

### Physical Addresses

A _physical address_ is an address that will be issued from the CPU as an address
to access memory. The number of bits in a physical address is at most the
number of bits in the CPU's general-purpose registers and at least 16. 
The number of bits in a physical address can be determined by accessing the
FEAT control register; as long as the CPU supports at least two addressing modes
(including the base mode), `FEAT[21:16]` contains one less than the number of
physical address bits supported. (This value is stored above bit 15 because
the `DW` extension is required to make use of _every_ non-base addressing mode.)
The number of physical address bits supported is sometimes called `M`,
for "maximum bit." (Bits are zero-indexed, so bit `M` is the first bit that is
too significant for a physical address.)

For a value to be considered a _physical address_, it must be zero-extended
starting from (and including) bit `M`. A value attempting to be used as a
physical address but which is not zero-extended in this way is called an
_invalid physical address_. Generally, any situation that would produce
an invalid physical address is the result of a catastrophic software bug.

Some control registers (`VM_ROOT`, `TLBLO`) interact with physical addresses
even while a virtual addressing mode is active. The values written to these
registers **must** be valid, otherwise a `#GP` exception is raised.

A physical address is further called _generatable_ or _real_ if a program
running in the current addressing mode can refer to it. Since the current mode
might have smaller logical addresses than the CPU's physical addresses,
it is possible that only a low-address region of the available physical memory
can be referenced. For example, if `M` is 22, then in 16-bit real mode the
largest generatable address is `0x00FFFF`. The addresses in the range
`0x010000` to `0x3FFFFF` in this example are called _unreal_.

In a particular implementation, it **may** be possible for the program counter
in a real mode to contain a logical address which would be unreal if interpreted
directly as a physical address. This may occur in three ways:

1. A switch to a narrower real addressing mode from a wider addressing mode
    while the PC is unreal.
2. Taking an exception or interrupt while the value of the `INT_PC` control
    register is unreal.
3. Executing an `eret` instruction while the value of the `INT_RET_PC` control
    register is unreal.

Each of these three situations are under the purview of privileged software,
and privileged software can prevent all three of them from occurring.
If any of these situations occur, the behavior of the system is unspecified.
It can be useful to allow fetching instructions from such unreal physical
addresses, but this specification does not require that to work.

### Virtual Addresses

A _virtual address_ is a value that must be consumed by some kind of translation
process to obtain a physical address. See [Virtual Address Modes](#virtual-address-modes)
below.

In some virtual address modes, the number of virtual address bits is between
32 and 64. Such modes require the use of quadword registers but do not use the
entire register. In such address modes, a value to be used as a virtual address
is called a _canonical virtual address_ if it is sign-extended from the most
significant virtual address bit. The attempted use of a non-canonical virtual
address to access memory is a software bug, and raises a `#GP` exception.

> [!NOTE]
> When extending a physical address from a narrow real address mode,
> ETCa zero-extends logical address to a physical one. When using virtual
> addressing extensions such as PG48 and PG57, which use more bits than
> a doubleword register but not an entire quadword register, ETCa follows
> the convention that the canonical virtual address is the sign-extended one.

> [!NOTE]
> It is only an error to use a non-canonical virtual address to _access memory_.
> If a non-canonical virtual address appears in the intermediate computation
> or the result of an `lea` instruction, it is not an error.
> This is only relevant under PG48 or PG57 as a "noncanonical virtual address"
> is impossible under both PG16 and PG32.

In other virtual address modes, the number of virtual address bits matches the
width of a subregister and, as described above, the bits higher than that subregister
are simply ignored.

In 16- and 32-bit paging modes, where only the 16- or 32-bit subregisters
respectively are used by the processor to read logical addresses,
a value containing bits set outside that subregister is called an _invalid_
_virtual address_. For example, `0x1FFFF` is an invalid virtual address in
16-bit virtual address mode. It is not usually possible to refer to an invalid
virtual address because the CPU only looks at the appropriate subregister.
However, it is possible to load an invalid virtual address into the
`INT_PC` and `INT_RET_PC` control registers. If taking an interrupt/exception
or executing the `eret` instruction would load the PC with an invalid virtual
address, the behavior is unspecified. The PC _cannot_ become invalid as the
result of switching into a narrower virtual address mode because this behavior
raises a `#GP` exception; see [Switching Modes](#switching-modes) below.

## The MODE Control Register

CR `1 0001`, equivalently `CR 17` or "the MODE control register," holds a value indicating the current
mode of the processor, as well as a few control bits that may modify the processor's addressing
behavior.

![CR17 Layout](resources/vm-diagrams/cr17.svg)

The register contains a bit field with various bits controlling the behavior of address spaces.

| Bit | Name | Initial Value | Meaning |
|-----|------|---------------|---------|
| 0   | `VM` | `0` | When this bit is set, virtual memory is in use. Which extension specifically governs the addressing mode of the CPU depends on the other bits. |
| 1-2 | `PTRSZ` | `00` | These bits describe the width of logical addresses. `00` indicates 16 bits, `01` indicates 32, and `10` indicates 64. |
| 12  | `WP` | `1` | Short for "Write Protect," this bit controls the behavior of memory regions marked read-only. See [WP](#write-protect) below. |
| 13  | `CID` | `0` | When set, context identifiers other than 0 are allowed; see [TLB Invalidation, Optional Feature](#optional-feature-cid) below. |

The `CID` bit is a WARL, or "write any, read legal" bit. Software may determine if
CIDs are supported by attempting to set the bit and then reading the register back
to see if that write succeeded. If it did not, CIDs are not supported and were
(obviously) not enabled by the write.

All other bits are reserved for extensions, including bits above the 15th. Attempts to write reserved bits must raise `#GP`
unless the relevant extension is available.

### Related Control Registers

When `MODE[VM]=1`, the system additionally uses the control registers CR 18 (`VM_ROOT`), CR 19 (`INT_ECODE`),
and possibly CRs 20-22 (`TLBX`, `TLBLO`, and `TLBHI`). The purpose of each of these registers is discussed [below](#soft-virtual-modes).
`INT_ECODE` is read-only; `VM_ROOT` and the three `TLB` CRs are read-write.
When `MODE[VM]=0`, reading or writing these registers has no immediate effect on addressing
behavior. All of these registers are privileged, if `PM` is available.

Regardless of mode, attempting to write a reserved bit of
`VM_ROOT` must raise `#GP`. Writing reserved bits of
`TLBLO` and `TLBHI` is permitted, but will result in `#PF`
exceptions if the corresponding TLB entries are ever used
in an address translation. Note that the set of reserved
bits may change in the future, but that CPUID bits will ensure
it is possible to test for extension presence before writing a
CR bit that might fault.

# Real Address Modes

In real address modes, logical addresses are treated directly as physical addresses.
No translation is performed; software has direct access to (a subset of) the physical
address range.

It is permitted in an implementation that `M`, the number of physical address bits,
be wider than the widest real address mode. In such implementations, a virtual
addressing mode will be required to access the rest of the physical address range.

## n-bit Real Address Mode

This family contains 3 modes, for 16-, 32-, and 64-bit real addressing modes.

In this mode, logical addresses read from GPRs are `n` bits long, and are read from
the subregister of that width. Bits outside of that subregister are **ignored**
(it is not an error for such bits to be set). Logical addresses read from the PC,
or loaded into the PC from control registers, and which have set bits at or above
bit index `n`, are _unreal physical addresses_ and cause unspecified behavior.
Implementations are permitted to fetch and execute instructions from unreal
addresses, but there is no way for those instructions to load or store to an
unreal address.

The instructions which manipulate addresses, being `load`, `store`, `call`,
register `call`, register `jmp`, and any ABM instruction with a memory operand,
manipulate logical addresses read from GPRs. Therefore, bits outside the appropriate
subregister are **ignored** by the instruction, and the value in the subregister
is zero-extended if necessary.

> [!CAUTION]
> In real modes, it is not possible to
> use a register jump or register call to transfer control to an unreal address.
> This also makes it impossible to _return to_ an unreal address.
> If the implementation supports execution from unreal addresses, a relative
> displacement `call` instruction from an unreal address will correctly transfer
> control to the target address but will write the _real truncation_ of the return
> address into `%r7`.

Logical addresses refer to the physical address which is the zero-extension to `M` bits.
Switching into `n`-bit real address mode from a narrower `m`-bit real address mode
(that is, `m < n`) preserves the program counter. Switching to a wider real address
mode (that is, `m > n`) is unspecified behavior, but preserves the program counter
if unreal execution is supported by the implementation.

## Base Mode (16-bit Real Address Mode)

The mode described by [the base isa](../../base-isa.md) is the 16-bit real address
mode. This mode is therefore also referred to as Base Mode.

In this mode, addresses are 16 bits. Base mode is indicated by `MODE[PTRSZ]=0` and `MODE[VM]=0`.

# Virtual Address Modes

In virtual addressing modes, also known as "protected" modes, the logical address
manipulated by the software may differ significantly from the physical addresses
used to communicate with memory and memory-mapped devices.

The process of translating from the logical addresses used within the CPU to the physical addresses used
externally is generally controlled by a hardware subsystem known as an MMU, or memory management unit.
These subsystems are also sometimes called translation units.
(Implementations are **not** required to contain an MMU or equivalent subsystem -- this is simply a description
of _typical_ systems. A compliant system, of course, must only behave as specified.)

The addresses may differ by more than just a single constant value. Virtual addressing modes divide the
logical address space into chunks called "pages," and divide the physical address space into chunks of
the same size called "frames." Any page may be translated into any frame; there is no need for contiguous
pages to map to contiguous frames, to frames in ascending order, to distinct frames, or any other such
restriction.

> [!CAUTION]
> When setting `MODE[VM]`, care must be taken to ensure that the instruction pointer
> is valid for the corresponding virtual address mode and will map to either the same
> frame as is currently executing, or to a physical frame with a copy of the code.
> Otherwise, setting `MODE[VM]` can effectuate a hard-to-predict control transfer.
> See [Switching Modes](#switching-modes) below.

<p align="middle">
  <img src="resources/vm-diagrams/mmu-translation-success.svg" width=350>
  <img src="resources/vm-diagrams/mmu-translation-fail.svg"    width=350>
</p>

Virtual address modes also make it possible to configure access protections for pages.
These protections are called _storage attributes_ and may include "writable,"
"executable," "user-accessible," and more.
The MMU is responsible for checking that each access is permitted by the storage attributes.
In the event of a disallowed access,
the MMU `#PF` -- a "Page Fault exception." It is the job of software (usually a kernel, if `PM` is
available on the system) to handle this exception.
Using this feature, it is possible to reduce actual physical memory usage without reducing virtual address
space size, by marking pages inaccessible and not allocating a physical frame for those pages.
Handling of `#PF` can then include marking the address accessible and allocating a frame before
returning to the interrupted instruction stream to retry the access. It can also involve terminating the
faulting instruction stream entirely if the issue indicates an unrecoverable bug.
The ability to raise `#PF` is fundamental to virtual memory; therefore all virtual
address mode extensions require INT.

In some paging modes, the translation can refer to physical addresses wider than the virtual addresses.
Unless the system also supports a sufficiently-wide real address mode,
those physical addresses are inaccessible to software while paging is disabled,
because there is no other way to refer to them.
(Unreal execution from those addresses may be supported, however.)

Implementations may offer some other mechanism to refer to such addresses, but there is no standard.

### Write Protect

When `MODE[WP]=0`, and execution is in system mode, write access controls on pages are ignored.
This includes the case where the [`PM`](../privileged-mode/) extension is not available.
(All code is considered to run in system mode if `PM` is not availble.)
This allows system-privileged code to modify memory marked read-only for the user.
When `WP` is 1, write access controls are enforced even for privileged code.
Allowing privileged code to modify memory marked read-only is critical for
implementing memory management software with [16-bit Paging](16-bit-paging/README.md)
or [32-bit Paging](32-bit-paging/README.md) enabled. With the wider virtual address
modes, it is useful but not critical.

It is recommended that software usually leave the bit set,
disabling it only for short periods of time when required.

## Address Translation

This section describes the general scheme of address translation in the presence of paging.
For specifics, including about the various involved data structures and extra CRs,
please see a specific extension document.

### Page Tables

The fundamental data structure for virtual memory is the so-called _Page Table_.

At their heart, page tables are simple arrays where each element, known as a _Page Table Entry_,
corresponds to a single page in the virtual address space and contains the (physical) address of
the physical frame to which it is mapped.
Each entry contains some additional metadata about the page,
such as whether it is mapped at all and its storage attributes.

To use the Page Table, each virtual address is decomposed into a bitfield. The less-significant bits
are the "Offset" field, determining an address _within_ a page. The more-significant bits are the
"Page Number," which is used to index the page table. Once a frame number is obtained,
that number corresponds 1-to-1 with a physical frame; by concatenating the frame number with as many
zero bits as there are offset bits, the base physical address of the frame is obtained.
Replacing the zero bits with the offset bits from the virtual address,
the final physical address is obtained.

For example, with the 16-bit paging extension, the translation process is shown in the following diagram:

![16-bit paging example](resources/vm-diagrams/16-bit-paging-transl.svg)

The page table itself lives in physical memory. Part of the address of the currently active
page table is stored in CR 18 (`VM_ROOT`). That said, it is generally not required for the active
page table to be mapped into the virtual address space that it describes (i.e. mapped into itself).
Still, this table consumes physical space. Each additional table existing on the system consumes more
space. But how much?

The amount of space consumed by each table depends on which paging extension is used.
For the above example, there are 128 entries per table (as there are 7 Page Number bits).
Each entry (shown below) is 2 bytes, so each table consumes 256 bytes. With this extension,
each page is _512_ bytes, so it is possible to fit two page tables in a single frame.
Correspondingly, the 16-bit paging extension interprets one more phyiscal address bit
from `VM_ROOT` than from page table entries. A kernel is free to arrange tables 2-per-frame,
or to use one frame per table and spend the other half of the frame on metadata.

Unless [soft paging](#soft-virtual-modes) is in use, paging structures must reside in normal cacheable memory.

### Page Table Entries

![16-bit page table entry](resources/vm-diagrams/16-bit-paging-pte.svg)

For 16-bit paging, each of the 128 entries in a page table has the above format.
Each of these bit fields is present in all paging extensions, though the others extensions
also support additional configuration. Each of the 3 named bits describe an access
control on the page; see the extension for more details.
Attempting to access a page in a way disallowed by the control bits causes the
MMU to raise `#PF`, which software is responsible for handling appropriately.

> [!INFO]
> The `P` (or "present") bit indicates that the table entry represents a valid,
> mapped page. When the `P` bit is zero, accesses to the page will be rejected
> and the other bits of the page table entry are **ignored**. This allows memory
> management software to use the other bits of invalid entries for metadata
> about the page, for example, information about how to retrieve the page
> contents.
>
> This is true for all virtual address extensions.
> All such extensions provide a `P` bit in page table entries,
> and it is always the least significant bit.

Notice that the VPN in a 16-bit virtual address is 7 bits, but corresponding
frame number is 13. This gives a 6-bit (64x) extension to the physical address
space, making it possible to access 13 frame bits + 9 offset bits = 22 total
physical address bits, or 4MiB of physical memory.

### Larger Address Spaces

Suppose the same mechanism were applied to 32-bit paging. A typical offset size
is 12 bits, leaving 20 for the virtual page number. Each page table entry would
be at least 4 bytes to have space for a frame number. At minimum, that would
make each page table... 4MiB in size! It would take _1024_ pages (each 4KiB)
just to store a complete page table. If we apply the same system to 64-bit paging,
the table takes space in the exabytes. Clearly, this would not work.

Larger address space extensions apply a technique known as _multilevel paging_.
Each huge page table is chopped up into page-size segments, and a higher-level
_Page Directory_ (also page-sized) is then used to identify the correct page table.
This transforms the page table from a linear array to a Radix Tree.

For example, consider 32-bit paging. The translation scheme looks like this:

![32-bit paging translation](resources/vm-diagrams/32-bit-paging-transl.svg)

This helps save space because 32-bit virtual address spaces, unlike 16-bit ones,
are typically very sparsely used. Most programs need only a few kilobytes or megabytes
of memory -- to use a full 4 GB is rather rare (at least, for the kind of text-based
or computational tasks typically performed on such systems... of course, modern
graphical games might use much more!). With the 16-bit paging extension, pages that
are not mapped can have the `P` bit of their entry cleared, indicating the lack
of mapping, but this does not reduce the size of the table.
With 32-bit paging, clearing the `P` bit of a page directory entry indicates that
there _is no page table at all_ for that address range, making it possible
to drastically reduce the number of frames consumed by page tables.
Additionally, it is not necessary to allocate the frames for the page tables
contiguously. Overall, these are huge wins.

Paging extensions which add more levels refer to higher level page directories
as "Page Directory Level 1," "Page Directory Level 2," etc, where higher-numbered
levels contain a frame number for the next lower-numbered level.
The 32-bit paging system above contains only PDL1s.

## Translation Lookaside Buffers

Consider the 32-bit translation scheme above. Each memory access requested by
the running code now requires _three_ accesses to physical RAM -- one to fetch
the correct PDL1 entry, one to fetch the correct page table entry, and one
to perform the requested access. Even for 16-bit paging, there's a factor of
two increase. Since memory access is typically much slower than other CPU
operations, a factor of two slowdown is already unacceptable. Increasing
slowdowns as more directory levels are added would only get worse.

To mitigate this issue, MMUs often contain a specialized cache called a
TLB, or Translation Lookaside Buffer. Each entry in a TLB is a mapping from
a page number to a frame number, as well as other necessary metadata
like storage attributes for that page.

Despite being caches, TLBs are usually incoherent; modifying a page table
in memory which is cached in a TLB does not automatically update the copy
cached in the TLB. Incoherent TLBs (and other paging-structure caches)
are permitted even when the [Cache Coherency](../features/cache-coherency/)
feature is present.

### Soft Virtual Modes

With a TLB in the MMU, it is possible to drastically reduce hardware
complexity by first demanding that software decide which page-to-frame
mappings should reside in the TLB, and then further demanding that software
also be responsible for _computing the translations_. This removes any need
for "page table walkers" in the hardware, at a fairly signficant performance
cost. In educational settings, this cost is acceptable, though it is
recommended that practical implementations include at least one hard
table walker.

Virtual modes are further subdivided into _soft virtual modes_ and
_hard virtual modes_ (aka _soft paging_ and _hard paging_, which we often
abbreviate to simply "soft" or "hard").
In hard virtual modes, the MMU handles address
translations and manages its own TLB(s). In soft virtual modes,
TLB misses raise `#PF` exceptions with the `INT_ECODE[MISS]` bit set
(see [Page Faults](#page-faults) below).
An implementation compliant with a paging extension must implement
**either hard or soft operation** but should not implement both.
There is no standardized way to switch between hard and soft virtual
modes because a system with support for hard virtual modes does not benefit
from even temporary usage of soft virtual modes.

When handling a `#PF` caused by a TLB miss, software should perform
the address translation and choose a TLB entry to place it into.
Once this is complete, returning from the handler will naturally
retry the faulting instruction which should now succeed.

Soft TLBs must be fully associative, such that any TLB entry can contain
a mapping for any page.

> [!CAUTION]
> When using a virtual address mode, ensure that the virtual address
> contained in `INT_PC` is accessible at all times. In soft modes,
> further ensure that it is always available in a TLB entry.
> Failure to do so will cause a double fault and CPU reset as soon
> as any exception or interrupt is raised.

> [!CAUTION]
> If software inserts multiple TLB entries for the same page,
> the behavior of the MMU is _undefined_. It is **not**
> required that one of the mappings be used arbitrarily;
> implementations are permitted to do anything at all.

Three control registers are available for managing the MMU:

| CRN    | Name          | Description                                       |
|:-------|:--------------|:--------------------------------------------------|
| `1 0100` | `TLBX` | Control the TLB entry mapped onto `TLBLO` and `TLBHI`. |
| `1 0101` | `TLBLO` | Maps the low part of the TLB entry identified by `TLBX`. |
| `1 0110` | `TLBHI` | Maps the high part of the TLB entry identified by `TLBX`. |

For hard virtual modes, writes to TLB entries must be ignored and reads
must produce all zeroes.

> [!NOTE]
> If the processor supports hard virtual operation in one paging mode,
> and soft virtual operation in another, the behavior of TLB CRs should be
> determined by which mode would be in effect if `MODE[VM]` were set
> and all other bits were unchanged.

This makes it possible for software to determine if paging will be hard
or soft before enabling it, making it possible for software which cannot
handle the responsibilities of soft paging to fail gracefully.

The TLB entries must be mapped by the contiguous `TLBX` values from 0 to the maximum
entry index supported. Software can discover how many entries are supported
by attempting to modify each TLB entry until the writes fail.
A soft paging implementation _must_ provide at least two
TLB entries, but _should_ provide at least 16.

Therefore, the properties of the paging implementation can be discovered as follows:
```py
def paging_properties(ptrsz):
  # ensure MODE[VM] = 0
  # and that code is running in a ptrsz-real address range.
  MODE[PTRSZ] = ptrsz
  writecr(TLBX, 1)
  old_TLBLO = readcr(TLBLO)
  writecr(TLBLO, old_TLBLO ^ 1) # flip the P bit
  if readcr(TLBLO) == old_TLBLO:
    return HARD_PAGING
  while True:
    writecr(TLBX, readcr(TLBX) + 1)
    old_TLBLO = readcr(TLBLO)
    writecr(TLBLO, old_TLBLO ^ 1)
    if readcr(TLBLO) == old_TLBLO:
      return SOFT_PAGING, num_entries = readcr(TLBX)
```

The exact format of TLB entries, in particular how they map onto `TLBLO`
and `TLBHI`, must be specified by each paging extension.
Any other responsibilities of the software must also be specified.
A compliant hard paging implementation, of course, can completely ignore
such specification (as software can't interact with a hard paging TLB).

> [!NOTE]
> Soft paging hardware never reads `VM_ROOT` or inspects page tables
> for the purposes of address translation.
> Soft paging _software_ is therefore free to organize its paging data
> structures however it pleases, and is **not** obligated to follow
> the table formats described by the particular extension in use.

## TLB Invalidation

TLBs are usually implemented as _incoherent_ caches, meaning that when the
backing data cached by a TLB is updated in RAM, the TLB will maintain its
stale copy.

After modifying an entry in the active page table, software must invalidate
the TLB entries for the affected pages. Two ISA-level mechanisms for doing
this are provided. When using soft paging, software may instead update the
TLB entry directly.
(Invalidating entries and fixing them via a normal TLB miss exception
is a simpler, but less efficient, option.)

> [!CAUTION]
> Soft paging implementations must be constantly concerned that any performance
> or efficiency feature which accidentally invalidates both the TLB entries
> containing the current instruction pointer and the page fault handler
> will immediately cause a CPU reset. The restrictions on invalidation
> instructions for soft paging implementations help to prevent this.

### Reducing the Need for TLB Invalidation

In any case, excessive TLB invalidations are an expensive operation and it
is often desirable to avoid them if possible. Two optional features, described
below, are provided to reduce TLB invalidations: [Global Pages](#optional-feature-global-pages)
and [Context Identifiers](#optional-feature-cid).

#### Optional Feature: Global Pages

Most paging extensions reserve a bit in the TLB and/or page table
layouts labeled `G`. This is known as the "global page" bit.
When `FEAT.PGE` bit is present, the `G` bit
in paging structures is no longer reserved and can be set to 1 by software
managing the structures. Attempting to set `G` bits in TLB entries
when `FEAT.PGE` is not present raises `#GP`, whether by hard or soft paging.

A page marked global is assumed to be present in every address space
being managed. That is, if the page number is `P`, and the page table entry
in the current `VM_ROOT` address space is valid (it must be if the `G` bit
is set), then it is assumed that an identical page table entry for page `P`
exists until the implementation is explicitly told otherwise, even if the
value of `VM_ROOT` changes. This is conceptual description; behavioral
specification follows in the description of the TLB invalidation methods.

#### Optional Feature: CID

Invalidating all (non-global) TLB entries has a harsh performance cost when
writes to `VM_ROOT` are frequent, for example in certain 16-bit paging
applications or in any kernel implementing address space isolation.
To lower this cost, implementations may optionally support a feature known as
_context identifiers_ or CIDs. Support for CIDs is identified by attempting
to set the `MODE[CID]` bit (whether or not paging is enabled) and then checking
if the write succeeded. (`MODE[CID]` is a "write any, read legal" bit.)

When CIDs are supported, the use of context identifiers must be
explicitly enabled by setting `MODE[CID]=1`. Attempting to set the current CID
to a non-zero value while `MODE[CID]=0` raises `#GP`.
Attempting to clear `MODE[CID]` while the current CID is not zero raises `#GP`
(unless this write also disabled paging by clearing `MODE[VM]`).

When performing an address translation, a particular TLB entry is only considered
if
  1. the CID in the entry matches the current CID, which is configured with bits in
`VM_ROOT`, or
  2. the entry is marked global.

Which bits determine the CID, and the number of available CIDs, is
extension-dependent.

> [!WARNING]
> Because TLB matching for global pages does not consider the current CID,
> it is possible for the MMU to find global TLB entries for pages that are
> not mapped in the current `VM_ROOT` until those entries are invalidated
> either manually or by the processor (which can be very difficult to predict).
> Such entries must be explicitly invalidated when this is not acceptable behavior.
> It is advisable to only mark a page global if it is in **every** address
> space that the software is maintaining.

When `MODE[CID]=1`, writes to `VM_ROOT` are not required to invalidate any TLB
entries.

To prevent the possibility of stale TLB entries for a CID when CIDs are
disabled and then later re-enabled, disabling CIDs while virtual memory
is enabled invalidates all TLB entries.

### Write to `MODE`

Hardware complications can arise if TLB entries persist through changes
to `MODE` which change the translation behavior. The requirements in this
section invalidate entries accross such changes in a way that is sufficiently
predictable for software.

Writes to `MODE` which disable paging (by clearing `MODE[VM]`) must invalidate
all TLB entries. For the same reasons, a write to `MODE` while paging is
enabled, which disables CIDs, also invalidates all TLB entries.
(That is, a write by which `MODE[VM]=1` both before and after,
`MODE[CID]=1` before, and `MODE[CID]=0` after.)

Mode switches may involve significant other hardware performance considerations
and are not a recommended way to invalidate TLB entries if that is the only
goal.

> [!CAUTION]
> To disable CIDs with a soft paging implementation, the software must switch
> to a real mode at the same time (or before). Clearing `MODE[CID]`
> without doing so will invalidate _all_ TLB entries and cause a double fault.

### Write to `VM_ROOT`

While `MODE[CID]=0`, a compliant hard paging implementation must invalidate
all TLB entries, except those for global pages, on writing to the `VM_ROOT` CR.
Global entries are permitted to be invalidated, but should not be.
A soft paging implementation is not permitted to invalidate **any** entries.

While `MODE[CID]=1`, a compliant hard paging implementation is **not** required
to invalidate any TLB entries on writes to the `VM_ROOT` CR.
Soft paging implementations remain not permitted to invalidate any as well.

### The TLBI Instruction

Both single-page and mass invalidations can be performed by the `TLBI`
or "TLB Invalidate" instruction.

When the `TLBI` instruction is used, _at least_ the TLB entries specified
below are invalidated. It is permitted to invalidate more entries than
specified, however soft paging implementations _must not_ invalidate entries
for global pages except where specified.

> [!CAUTION]
> Use of the `TLBI ALL` instruction will certainly cause a double fault
> while a soft paging mode is active.

| Mnemonic | Encoding | Description |
|:---------|:----:|:---:|:------------|
| `TLBI PG,  A, B` | TODO | Invalidate all non-global TLB entries for the page addressed that would be addressed by `A` if the current CID were the value of `B`. |
| `TLBI GPG, A`    | TODO | Invalidate all TLB entries for the page addressed by `A`. |
| `TLBI CID, A`    | TODO | Invalidate all non-global TLB entries with the CID in `A`. |
| `TLBI ANG`       | TODO | Invalidate all non-global TLB entries. |
| `TLBI ALL`       | TODO | Invalidate all TLB entries. |

If CIDs are not supported or are disabled, `TLBI PG` and `TLBI CID` will
invalidate pages if (and only if) the value of `A` is zero.

## Page Faults

On systems supporting any of `PG16`, `PG32`, `PG48`, or `PG57`, a new exception type is defined.

| Name                     | Type         | Mask/Pending Bit | Description                                          |
|:-------------------------|:-------------|:-----------------|:-----------------------------------------------------|
| Page Fault               | Synchronous  | 6                | Raised by the MMU when address translation fails.    |

The short name for the page fault exception is `#PF`. The notation `#PF(...)`
describes a page fault with particular `INT_ECODE` bits set as described below.

When a page fault is raised and control is transferred to the exception handler,
`INT_DATA` will contain the logical address for which access faulted and
`INT_ECODE` (CR 19) will contain an "exception code" describing the fault.

The exception code contains several bits explaining why the address translation failed.
It is possible for multiple of these bits to be set simultaneously.

| Name    | Bit      | Description          |
|:-------:|:--------:|:---------------------|
| `P`     | 0        | Set if the required paging structure entry's `P` ("present") bit was set. |
| `W`     | 1        | Set if the access causing the fault was a write. Otherwise, it was a read. |
| `U`     | 2        | Set if the access was attempted from user mode. |
| `X`     | 3        | Set if the access was an instruction fetch. |
| `R`     | 4        | Set if any reserved bit in a required paging structure entry was set. |
| `MISS`  | 5        | Set by soft paging implementations if the required mapping was not in the TLB. |

If the `P` bit of a required paging structure entry is not set, a `#PF`
is raised immediately with `INT_ECODE[P]` _cleared_ (to match the `P` bit
of the entry). The other bits of the entry are **ignored**; the software is
permitted to use other bits of non-present entries for whatever it wants.

For present entries; the write, user, and execute storage attributes
are all checked against the requested access. If the access is disallowed,
or if any reserved bits in the entry are set, or both,
A single `#PF` is raised with the `P` bit and all other corresponding
error code bits set. A `#PF` stops the translation process immediately.

A future extension or feature is very likely to add more `#PF` code bits.

### Checking Storage Attributes

A write to a page is disallowed if

  1. the `W` bit in a required paging structure is not set, and
  2. the system was executing in System mode and `MODE[WP]=1`, or
  3. the system was executing in User mode.

An instruction fetch from a page is disallowed if the `X` bit in a required
paging structure is not set.

Any access (write, read, or fetch) is disallowed if it is attempted from
User mode and the `U` bit of a required paging structure is not set.

Note that the page fault exception code bits describe the attempted access,
_not_ the reason that the access failed. `W`, `U`, `X`, and `R` bits are
_all_ set appropriately regardless of why the access did not succeed.

### #PF with Soft Paging

Soft paging implementations first determine if there is a matching TLB entry
for the address. If there is not, `#PF(MISS)` is raised.
Once a matching entry is found, soft paging implementations must still raise
appropriate `#PF` exceptions based on the bits in that entry.

# Switching Modes

First, some terminology is a required:

1. A "write which sets a bit" is a write before which the bit is clear and
  after which it is set. If the bit is set before the write, the write did
  not set it.
2. A "write which clears a bit" is the dual; the bit must have been set before
  and cleared after.

The following rules apply to changing modes and to other writes to the
relevant control registers.

1. `MODE[PTRSZ]` can only be edited if `MODE[VM]` was clear either before
  or after the write (or both). In other words, you cannot switch between
  virtual modes of different virtual address sizes directly.
2. Writes which clear `MODE[CID]` are only allowed if the current CID
  would be zero. This can be determined by bits of `VM_ROOT`, but which
  bits exactly depends on the paging extension that will be in effect after
  the write. The same applies to a write which would set `MODE[VM]` if
  `MODE[CID]` was clear both before and after: the current CID must be zero.
3. Writes to `VM_ROOT` which would set a non-zero current CID are allowed
  only while paging is disabled or `MODE[CID]` is set.
4. While not a restriction, note as stated above that writes which clear
  `MODE[CID]` _or_ `MODE[VM]` invalidate all TLB entries.

These restrictions collectively make it illegal to have a non-zero current
CID while paging is enabled and CIDs are not. They also ensure that TLB
entries will never be persisted across behavioral mode changes that affect
the behavior of the TLB, including disabling it entirely or enabling/disabling
CIDs.

Changing `MODE[PTRSZ]` while enabling or disabling virtual addressing in the
same write is permitted. Enabling virtual addressing and CIDs in the same
write is permitted, including when the current CID would not be zero.

# Interactions With Other Extensions

Other extensions mention "address modes", in particular when deciding what a particular value
should mean or how many bytes an immediate should be. This usually refers to the
_address size attribute_.

| Address Bits | Address Size Attribute |
|--------------|--------------|
| 16 bit       | word         |
| 32 bit       | doubleword   |
| 48 bit       | quadword     |
| 57 bit       | quadword     |
| 64 bit       | quadword     |

This corresponds to which subregister of a GPR is used to read a logical
address from that register in each mode.

## `PM`

If the system supports [privilege levels](../privileged-mode/), then CRs 17-22
are only accessible to privileged code.

## `CI`

Some aspects of [cache control](../cache-instructions/) will support global configuration with `MODE[11:10]`,
but this is WIP.

## `DWAS`, `QWAS`

These extensions define specific behaviors for real modes with address widths of 32 and 64 respectively.

## `PG16`, `PG32`, `PG48`, `PG57`

These extensions define specific behaviors for protected modes with address widths of 16, 32, 48, and 57 respectively.
When any of these extensions are present, the `MODE[VM]` bit is writable. Attempting to set `MODE` to a value that
would correspond to a configuration not supported by the system raises a `#GP`.

Paging extensions support additional configuration via other `MODE` bits, such as `MODE[CID]`.
Such bits are writable even when `MODE[VM]` is zero, because the system would not be in a
paging mode and the configuration is therefore still supported.

# Recommendations

These extensions do not _require_ behaviors beyond what is specified. However, for compatibility with future
extensions which will require more specifics, the following are recommended:

* The program counter (or equivalent) in the processor itself should always store the zero-extended
  logical address.
* Do not attempt to support more than one paging mode in a completely hardware design unless you
  are willing to multiply the complexity of your MMU subsystem.
  On the other hand, supporting multiple real modes is comparatively simple.
* Many designs (including many real life, high-performance processors) use internal software
  ("microcode assists") to handle accessed/dirty bit updates.
  This technique is highly versatile and can make it simple and straightforward to handle
  those updates for a variety of paging extensions. (It may or may not help with the page
  table walks for TLB misses -- real life processors don't do that.)
* If you find your software needs additional ISA-level knobs to control the behavior of a
  memory system, report the issue to us rather than using special additional control
  registers (or other approach),
  so that we can apply a unified fix across all of the relevant addressing modes.
