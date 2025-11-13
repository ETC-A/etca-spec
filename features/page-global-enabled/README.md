# General design

**Feature State: Under Development**  
**FEAT Bit: 4**

When this feature bit is present, configuration bits marked `G` in paging structures
may be set to 1.

Such bits are mark that a page is "global" and should not be invalidated during mass TLB
invalidation. See our section on [TLB Invalidation](../../extensions/mode-control-register.md#tlb-invalidation).

# Specific Behavioral Changes

* Setting a `G` bit in a paging structure no longer raises `#GP`
  when that structure is accessed.
* Setting a `G` bit in a TLB entry (when using soft paging) no longer raises `#GP`.
* During writes to `VM_ROOT` causing TLB invalidations, pages marked global are not
  required to be invalidated. Hard paging implementations _should_ avoid invalidating
  them. Soft paging implementations _must not_ invalidate them.

> [!NOTE]
> `INVLPG` continues to invalidate entries for global pages.

See the discussion of this feature in our [paging documentation](../../extensions/mode-control-register.md#optional-feature-global-pages).
