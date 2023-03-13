# General design

**Feature State: Mostly Stable**  
**FEAT Bit: 3**

* The memory instructions, including but not limited to `store`, `load`, `push`, and `pop`, _must_ accept memory operands as specified by the `MO1` and `MO2` extensions.
    * The stack pointer for `push` and `pop` may only be a memory operand if the [../extensions/arbitrary-stack-pointer](Arbitrary Stack Pointer) extension is implemented.
* The `pop` instruction _must_ be treated as an _illegal_ instruction when the RMI byte follows the pattern `xxx 00x 01`.
    * This prevents using an immediate as the stack pointer.

### Concept

Implementing instructions which do multiple memory accesses can be tricky to implement. This feature is meant to signify that you support it for all relevant instructions.
