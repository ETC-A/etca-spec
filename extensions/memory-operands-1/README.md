# General design

**Extension State: Under Development**  
**Requires: Base, VWI**  
**CPUID Bit: CP2.1**

# Overview

This extension enables an operand to most instructions to refer to a memory location.

At most one operand may refer to a memory location. It is not possible to have both a memory
operand and an immediate operand using the encodings from this extension.

Such operations are not atomic by default.

# New Notation

### `SIB` Bytes

Some memory operand modes are complex, and involve some combination of a _scale_, an _index_, and/or a _base_.
These values are taken from a so-called `SIB` byte as shown below. If an `SIB` byte is present,
but either the base or scaled index is unused, the unused fields are don't-cares. Their value
must be ignored.

```
+----+-----+-----+
| SS | XXX | BBB |
+----+-----+-----+
```

These values are referred to as `SIB.S`, `SIB.X`, and `SIB.B` respectively. `SIB.X` and `SIB.B` refer to registers.

### `d8` and `dP`

A `d8` is a 1-byte signed displacement value. A `dP` is a flexibly-sized signed displacement value.
There is a notion of "current address mode," which refers to the logical address size currently selected by
the `EXTEN` control register. By default, the address mode is `word`. With 32-bit addressing enabled,
it is `doubleword`. With 64-bit addressing, it is `quadword`.

A `dP` is the same size as a logical address in the current mode. However, similarly to [full-immediates](../full-immediates/README.md),
this extension cannot encode an 8 byte displacement. In `quadword` address mode, a `dP` is 4 bytes.

If the [register expansion](../expanded-registers/README.md) extension is available, then a `REX.Q` prefix may be used with instructions in these formats if
  - The instruction contains a `dP`
  - The current Addressing Mode is `quadword`

In this case, the `dP` is an 8-byte value rather than a 4-byte value.

For other instructions in these formats, `REX.Q` is **illegal**, not reserved. This terminology means that
if a `REX` prefix is present, the 8s bit must be 0 and that further extensions must not change this.

`REX.Q` remains reserved in formats not specified by this extension.

`REX.A`, `REX.B`, and `REX.X` prefixes are allowed with these instructions, but only if the register expansion prefix is enabled.

# Added Instruction Formats

These instruction formats apply to any instruction which encodes operands using an `ABM` byte, with
some explicit exceptions (TODO: link to a more detailed instruction-by-instruction document describing
exactly what modes/prefixes are valid for each instruction individually).
  * These formats need not be supported for `ld` or `st` opcodes. If they are not supported, they must
    behave as an undefined instruction.

| `ABM` | Followed By 1 | Followed By 2 | Specified Address Format |
|-------|---------------|---------------|-----------|
|<pre>+-----+-----+----+<br>\| AAA \| 000 \| 1D \|<br>+-----+-----+----+</pre> | `SIB` | | `[SIB.B]`
|<pre>+-----+-----+----+<br>\| AAA \| 001 \| 1D \|<br>+-----+-----+----+</pre> | `dP` | | `[dP]`
|<pre>+-----+-----+----+<br>\| AAA \| 010 \| 1D \|<br>+-----+-----+----+</pre> | `SIB` | `d8` | `[SIB.B + d8]`
|<pre>+-----+-----+----+<br>\| AAA \| 011 \| 1D \|<br>+-----+-----+----+</pre> | `SIB` | `dP` | `[SIB.B + dP]`
|<pre>+-----+-----+----+<br>\| AAA \| 100 \| 1D \|<br>+-----+-----+----+</pre> | `SIB` | `d8` | `[2^SIB.S * SIB.X + d8]`
|<pre>+-----+-----+----+<br>\| AAA \| 101 \| 1D \|<br>+-----+-----+----+</pre> | `SIB` | `dP` | `[2^SIB.S * SIB.X + dP]`
|<pre>+-----+-----+----+<br>\| AAA \| 110 \| 1D \|<br>+-----+-----+----+</pre> | `SIB` | `d8` | `[2^SIB.S * SIB.X + SIB.B + d8]`
|<pre>+-----+-----+----+<br>\| AAA \| 111 \| 1D \|<br>+-----+-----+----+</pre> | `SIB` | `dP` | `[2^SIB.S * SIB.X + SIB.B + dP]`

The `D` bit is the less significant `MM` bit, and refers to the "direction" of the operation.

Let `A` refer to the value of the register specified by `AAA`. Let `M` refer to the value in the memory
location denoted by the address as described above. Then all operations using this format have the following operation:
```
if D == 0:
  OP_L ← A
  OP_R ← M
else:
  if dst_is_input(operation):
    OP_L ← M
  OP_R ← A
RES ← operation(OP_L, OP_R)
if stores_result(operation):
  if D == 0:
    A ← RES
  else:
    M ← RES
```
In plain language; when `D` is 0, the `dst` operand is a register and the `src` operand is a memory location.
When `D` is 1, these are swapped. In all cases, the value in the memory location must be loaded from memory.
When the `dst` operation is a memory location, the result of the operation must also be stored there.

If an operation uses an `ABM` byte to encode two operands, but only treats one of them as an input, then this
behavior applies likewise to memory operations; memory must not be (visibly) loaded if the memory operand is not an input
(e.g., as is the case for `mov m, r/i`). If the operation does not store its result, then memory must not be modified.

The instruction's Operand Size (usually from the instruction `SS` bits, but NOT from the `SIB.S` bits) informs the size of the read or writes. These reads
and writes must behave, with regards to how memory is read and modified, the same as `ld` or `st` instructions
to the same address, with the same operand size.

When computing an address, register contents must be treated as if they were the width of an
address in the current address mode. When performing the operation, the operation must be performed
as though the operand values were the size specified by the instruction's Operand Size attribute.

# Added Instruction

| Name | Encoding | Operands | Description |
|------|----------|----------|-------------|
| LEA r, m | `00SS1110` | `ABM` | Loads the address specified by the second operand into the register specified by the first. Note that the address _itself_ is stored in the register, not the contents of memory at that address. The result stored in the register must respect the operand size attribute. The computed address must respect the address mode.

`LEA` means "load effective address." If the first operand is not a register, or the second is not a memory location, the instruction must be treated as an
undefined instruction. Such cases are **not** reserved - they are explicitly undefined.

Note that LEA shares an opcode with `READCR` (aka `mfcr`). `LEA` has no immediate mode, and `READCR` has
no register-to-register mode.

`LEA` does not affect any CPU flags. In addition to its stated purpose, it can be used to perform some "complex" arithmetic such as
copy-and-add operations, in a single instruction and without affecting flags. For example, `LEA` can be used to
encode `rx2 ← r0 + 4 * r1 + 10` in one 4-byte instruction, as `1E 5A 88 0A`.

This same specification of `LEA` is described in [memory-operands-2](../memory-operands-2/README.md), but these extensions
are independent and can each coexist without the other. It is generally recommend, however, that a system supporting
MO2 also support MO1.

# AOE Table

The added instructions can be seen in the complete Advanced Operand Extensions table, which encompasses the FI, MO1, and MO2 extensions. They are under `Mode=1x`.
![AOE Table](../etca_aoe_table.png)
