# General design

**Extension State: Under Development**  
**Requires: Base**  
**CPUID Bit: CP1.8**

# Overview

This extension allows for a larger address space using x86-like memory segmentation. Because crazy people with crazy ideas are expected, this extension uses a 24-bit address in total, unlike x86's 20-bit address.

## The added "register"
There are two hidden registers, which you can access with the following instructions:

|  First byte  | Second byte |
|--------------|-------------|
| `00 01 1001` | `RRR 000 01`|
| `00 01 1001` | `RRR 001 01`|

Segment register 0 is the data segment register, while segment register 1 is the code segment register assuming either a segmented code address space or shared address space with data.

It is suggested, that the segmentation registers are a byte in size, but here the extension is bendable to allow more than 24 bits for addressing. These registers represent the highest bits of an address. Unlike x86's segmentation, you can't access one linear address with more than one combination of a segment register and the memory operand.

## Jumps
Since this extension doesn't operate directly thanks to one of the other extensions and has a use in base, it isn't marked to require one. When it comes to jumps though, do note that this extension is mainly applicable to absolute jumps, for example those added by the Stack & Functions extension, but with a lot of creativity, it may be possible to adapt for relative jumps as well, to allow jumps farther than currently possible.

## Syntax
The suggested syntax is to use either `mov segc, reg` to change the code segment, or `mov segd, reg` to change the data segment, but that's up to the assembler implementation and not dictated by the extension.
