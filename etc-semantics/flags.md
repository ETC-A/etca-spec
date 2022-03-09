# Flags

Here we describe the `ETC.A` processor flags and a few simple semantic rules
for updating them.

Note that this code block does not have a `k` selector and is ignored by the
kompiler. It is here to describe the `flags` sub-configuration.

```
module ETC-FLAGS-CONFIG
    imports private BOOL

    configuration
      <etc>
        <flags>
          <carry>    false:Bool </carry>
          <zero>     false:Bool </zero>
          <negative> false:Bool </negative>
          <overflow> false:Bool </overflow>
        </flags>
      </etc>
endmodule
```

We provide a pair of rules for setting the arithmetic flag group and the
logical flag group. Use 
```
#setArithmeticFlags(size, result, left_operand_sign, right_operand_sign)
```
to set the arithmetic flags according to the parameters. The operand signs
(`true` if negative, as usual) are needed for determining overflow.

Use `#setLogicalFlags(result)`
to set the logical flags according to the parameters. The other flags will
be zeroed in normal operating modes. In `evil-mode` (TODO) a value for them
will be selected at random as the spec says they are undefined.

```k
module ETC-FLAGS
    imports private ETC

    syntax KItem ::= "#setArithmeticFlags" "(" ByteSize "," Int "," Bool "," Bool ")"
                   | "#setLogicalFlags"    "(" ByteSize "," Int ")"

    rule <k> #setArithmeticFlags(SIZE, R, LSIGN, RSIGN) => . ...</k>
         <flags>
            <carry>    _ => bit(ByteSize2NumBits(SIZE) +Int 1, R) </carry>
            <zero>     _ => R  ==Int 0                            </zero>
            <negative> _ => isNegative(SIZE, R)                   </negative>
            <overflow> _ =>
              (LSIGN ==Bool RSIGN)
              andBool (LSIGN =/=Bool isNegative(SIZE, R))
            </overflow>
         </flags>

    rule <k> #setLogicalFlags(SIZE,R) => . ...</k>
         <flags>
            <zero>     _ => chopTo(SIZE,R) ==Int 0 </zero>
            <negative> _ => isNegative(SIZE, R)    </negative>
            
            <carry>    _ => false </carry>
            <overflow> _ => false </overflow>
         </flags>
```

And finally, we provide a `condition` function for testing the ETC.A condition
codes with respect to the current flags. Note that we have chosen to refer to
the `carry` and `not-carry` condition codes as `c` and `nc`, but in programs
they more commonly appear as `jae` and `jb`.

```k
    syntax Condition
      ::= "equal"       | "not-equal" | "sign"     | "not-sign"
        | "carry"       | "not-carry" | "overflow" | "not-overflow"
        | "below-equal" | "above"     | "less"     | "greater-equal"
        | "less-equal"  | "greater"


    syntax Bool ::= condition ( Condition ) [function, functional]

    rule [[ condition(equal) => Z ]]
         <zero> Z </zero>
    rule condition(not-equal) => notBool condition(equal)

    rule [[ condition(sign) => N ]]
         <negative> N </negative>
    rule condition(not-sign) => notBool condition(sign)

    rule [[ condition(carry) => C ]]
         <carry> C </carry>
    rule condition(not-carry) => notBool condition(carry)

    rule [[ condition(overflow) => V ]]
         <overflow> V </overflow>
    rule condition(not-overflow) => notBool condition(overflow)

    rule [[ condition(below-equal) => C orBool Z ]]
         <carry> C </carry>
         <zero>  Z </zero>
    rule condition(above) => notBool condition(below-equal)

    rule [[ condition(less)  => N =/=Bool V ]]
         <negative> N </negative>
         <overflow> V </overflow>
    rule condition(greater-equal) => notBool condition(less)

    rule [[ condition(less-equal) => Z orBool (N =/=Bool V) ]]
         <zero>     Z </zero>
         <negative> N </negative>
         <overflow> V </overflow>
    rule condition(greater) => notBool condition(less-equal)
```

```k
endmodule
```
