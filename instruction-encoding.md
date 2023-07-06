Here we describe some base instructions (**only in the context of the base ISA**) with their encodings in an easier-to-read format. This format is inspired by the MIPS Instruction Set documentation.

By ensuring that you understand how to arrive at these encodings from
the descriptions in [base-isa.md](base-isa.md), you can ensure that you
understand how to read the byte-wise encoding explanations typical of 
the extension documents.

Notation:
| Symbol | Meaning |
|--------|---------|
|   ←    | assignment |
| +,-    | [two's-complement](https://en.wikipedia.org/wiki/Two%27s_complement) addition or subtraction
|  x<sup>y</sup>    | y copies of bit x |
|  \|    | bit-string concatenation |
| or     | bitwise or |
| nor    | bitwise nor |
| and    | bitwise and |
| xor    | bitwise xor |
| R[x]   | The content of register number x |
| PC     | The current address of execution |
| sign_extend<sub>x</sub>(y) | The sign extension of y from x bits to 16 bits |
| x<sub>y</sub> | Bit y of the value x

More notation may be added in the future.

# Sign Extension

Sign extension is used in mathematical and logical operations taking immediate values,
as well as for jump displacements. The exact meaning of sign extension is:

&nbsp;&nbsp;sign_extend<sub>x</sub>(y) = y<sub>x-1</sub><sup>16-x</sup> | y

For example, sign_extend<sub>5</sub>(31) is -1 when interpreted as a 16-bit two's complement value.

# Flags

Computation operations affect none, some, or all of four "condition flags." These flags are Z, N, C, and V, or "zero," "negative," "carry," and "overflow."

An operation may say "sets Z,N,C,V" or any subset of those flags in its operation section.

Setting Z or N sets them according to the result of the operation,
interpreted as a 16 bit two's complement number.

C and V can only be set by addition and subtraction operations. 
C is set to 1 by addition operations if the result, interpreted as an unsigned number,
would not fit in 16 bits. In other words, if the 17th bit of the result would be a one.
C is set to 1 by subtraction operations in exactly the oposite case;
when the 17th bit would be a zero. Otherwise, C is set to 0.
For V, subtraction operations are to be interpreted as addition of/to a negative number.
V is set to 1 if the operands to that addition are both positive but the result is negative,
or if both operands are negative but the result is positive.
Otherwise, V is set to 0.

If an operation sets a subset of the flags, then the values of all other flags
are **undefined** after that operation. They may maintain their old values,
be set to 1, be set to 0, or even be set randomly or unpredictably.

# ADD (R)

| 15 &ensp; 13 | 12 &ensp; 10 | 9 &ensp; 8 | 7 &ensp; 6 | 5 &ensp; 4 | 3 &ensp; 0 |
|:----:|:---:|:---:|:---:|:---:|:---:|
| rA  | rB | 0 0 | 0 0 | 0 1 | ADD<br>0 0 0 0 |

Syntax: `add rA, rB`

Description: Performs 16-bit two's complement addition of two registers.

Precise operation:
```
R[rA] ← R[rA] + R[rB]
sets Z,N,C,V
```
    
# ADD (I)

| 15 &ensp; 13 | 12 &ensp; 8 | 7 &ensp; 6 | 5 &ensp; 4 | 3 &ensp; 0 |
|:----:|:---:|:---:|:---:|:---:|
| rA  | imm | 0 1 | 0 1 | ADD<br>0 0 0 0 |

Syntax: `add rA, imm`

Description: Adds the sign-extended 5 bit immediate value to a register.

Precise operation:
```
R[rA] ← R[rA] + sign_extend₅(imm)
sets Z,N,C,V
```

# SUB (R)

| 15 &ensp; 13 | 12 &ensp; 10 | 9 &ensp; 8 | 7 &ensp; 6 | 5 &ensp; 4 | 3 &ensp; 0 |
|:----:|:---:|:---:|:---:|:---:|:---:|
| rA  | rB | 0 0 | 0 0 | 0 1 | SUB<br>0 0 0 1 |

Syntax: `sub rA, rB`

Description: Performs 16-bit two's complement subtraction of two registers.

Precise operation:
```
R[rA] ← R[rA] - R[rB]
sets Z,N,C,V
```
    
# SUB (I)

| 15 &ensp; 13 | 12 &ensp; 8 | 7 &ensp; 6 | 5 &ensp; 4 | 3 &ensp; 0 |
|:----:|:---:|:---:|:---:|:---:|
| rA  | imm | 0 1 | 0 1 | SUB<br>0 0 0 1 |

Syntax: `sub rA, imm`

Description: Subtracts the sign-extended 5 bit immediate value to a register.

Precise operation:
```
R[rA] ← R[rA] - sign_extend₅(imm)
sets Z,N,C,V
```

# JZ

| 15 &ensp; 8 | 7 &ensp; 5 | 4 | 3 &ensp; 0 |
|:----:|:---:|:---:|:---:|
| disp | 1 0 0 | sign | Z<br>0 0 0 0 | 0 0 |

Syntax: `jz <label>` or `je <label>`

Description: 

Precise operation:
```
If Z:
    PC ← PC + sign⁸|disp
```
