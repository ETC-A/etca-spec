# Extensions

ETC.A is an _extensible_ architecture. As such, it needs to be possible to
specify the semantics of an extension given the semantics of the rest of the
system.

This module provides the tools for doing so.

### Hooks

To add an extension, you should import this module and define the hooks for your
extension.

There are 5 function(al) hooks:

* `bit2Extension ( CpuidBit )`: the argument describes where in the CPUID to find your extension,
  it should evaluate to something of sort `EtcExtension` which indicates which
  extension the bit represents.

* `extension2Bit ( EtcExtension )`: the inverse of `bit2Extension`.

* `extensionDependsOn ( EtcExtension )`: The list of extensions which you
  depend on

* `#initializeExtension ( EtcExtension )`: Perform any modifications to the base
  machine configuration that this extension entails. For example, the quadword
  operations extension changes the `<full-reg-width>` cell to `quadword`.

Extensions are intialized at startup.

`#checkExtCoherence` is an additional semantic hook which ensures that dependencies are satisfied.
`#initializeExtensions` is another semantic hook to initialize all extensions at startup.

### Additional Notes

Your extension also likely requires adding decoding rules, for which you should
see the Decoding section of `etc.md`. You may also have to implement additional
hooks for extensions or features which you are extending.

Extensions can safely assume that the settings of their dependents are coherent.

# Implementation

```k
module EXTENSION-SYNTAX
    imports private INT
```

Uninterpreted sort `EtcExtension`. Extensions should define a new constructor
under this sort.

```k
    syntax EtcExtension
```

There are two CP registers (the rationale for this is described in the spec).
When identifying extensions with bits, we need to say which register it's in,
and which bit inside the register.

```k
    syntax ExtCReg  ::= "CP1" | "CP2" | "FT"
    syntax ExtBit ::= ExtCReg "." Int

    syntax Int ::= valueInExtCReg ( ExtCReg ) [function, functional]

```

Get the list of dependencies for an extension. This is used to check
coherence at startup.

```k
    syntax List ::= "#extensionDependsOn" "(" EtcExtension ")" [function, functional]
                  | "#extensionDependsOn" "(" ExtBit ")"       [function, functional]
```

Semantic hooks for startup.

```k
    syntax KItem ::= "#checkExtCoherence" | "#initializeExtensions"
```

```k
endmodule
```

The implementation.

```k
module EXTENSION
    imports EXTENSION-SYNTAX
    imports private ETC
```

Define `valueInExtReg`; literally just pick the correct control register
out of the configuration.

```k
    rule [[ valueInExtCReg(CP1) => CPUID1 ]]
      <cpuid1> CPUID1 </cpuid1>
    
    rule [[ valueInExtCReg(CP2) => CPUID2 ]]
      <cpuid2> CPUID2 </cpuid2>
    
    rule [[ valueInExtCReg(FT)  => FEAT   ]]
      <feat> FEAT </feat>
```

If we try to lookup an extension that hasn't been defined, we'll get an `UnknownExtension`.

```k
    syntax MaybeEtcExtension ::= EtcExtension | "UnknownExtension"
```

Hooks for initializing extensions and identifying them with their CPUID bits.
Additional hooks for checking dependencies and extension availability.

```k
    syntax KItem ::= "#initializeExtension" "(" EtcExtension ")"

    syntax MaybeEtcExtension ::= bit2Extension ( ExtBit ) [function, functional]
    syntax ExtBit ::= extension2Bit ( EtcExtension )      [function, functional]

    syntax List ::= extensionDependsOn ( EtcExtension ) [function, functional]

    syntax Bool ::= checkExtension     ( EtcExtension ) [function, functional]
```

If there's no higher-priority association for a CPUID bit, 
then we don't have one.

```k
    rule bit2Extension ( _ ) => UnknownExtension [priority(400)]
```

If there's no higher-priority initializer for an extension, then we initialize it by doing nothing.

```k
  //----------------------------------------------------

    rule <k> #initializeExtension ( _ ) => . ...</k> [priority(400)]
```

Check if an extension is available in the current configuration.
This amounts to identifying which CPUID register it's in, and checking
the corresponding bit.

```k
  //----------------------------------------------------------------

    syntax Bool
      ::= "#checkExtension" "(" ExtBit ")" [function]

    rule  checkExtension(EXT) => #checkExtension(extension2Bit(EXT))
    rule #checkExtension(CR.BIT) => bit(BIT, valueInExtCReg(CR))
```

Convert dependency check from `ExtBit` to one on `EtcExtension`.
It's much easier to iterate over `ExtBit`s, but easier to define
over `EtcExtension`s.

```k
  //-----------------------------------------------------------

    rule #extensionDependsOn(BIT:ExtBit)
         => extensionDependsOn( { bit2Extension(BIT) }:>EtcExtension )
      requires UnknownExtension :/=K bit2Extension(BIT)
    rule #extensionDependsOn(BIT:ExtBit) => .List
      requires UnknownExtension  :=K bit2Extension(BIT)
```

Check coherence of the extension configuration. We can iterate over
each bit in the configuration to check.

```k
  //------------------------------------------------------------------

    syntax KItem
      ::= "#checkExtCoherence" "(" ExtCReg ")"
        | "#checkExtCoherence" "(" ExtCReg "," Int ")"
        | "#checkExtCoherence" "(" List ")"

    rule <k> #checkExtCoherence
          => #checkExtCoherence(CP1)
          ~> #checkExtCoherence(CP2)
          ~> #checkExtCoherence(FT)
          ...</k>
```

Once we have a command to check for each register, we can start iterating
over each bit of that register.

```k
    rule <k> #checkExtCoherence(CR:ExtCReg)
          => #checkExtCoherence(CR, 0)
          ...</k>

    rule <k> #checkExtCoherence(CR:ExtCReg, BIT:Int)
          => #checkExtCoherence(#extensionDependsOn(CR.BIT))
          ~> #checkExtCoherence(CR:ExtCReg, BIT +Int 1)
          ...</k>
      requires (1 <<Int BIT) <=Int valueInExtCReg(CR)

    rule <k> #checkExtCoherence(CR:ExtCReg, BIT:Int) => . ...</k>
      requires (1 <<Int BIT) >Int valueInExtCReg(CR)
```

Every time we try to check a particular `CR.BIT` combo, we get a a list
of dependencies. We have to check each one, and then we're done.
The iterator has already handled putting the next bit in the K cell.

```k
    rule <k> #checkExtCoherence( .List ) => . ...</k>

    rule <k> #checkExtCoherence( ListItem(DEP) REST => REST ) ...</k>
      requires #checkExtension(DEP)

    rule <k> #checkExtCoherence( ListItem(DEP) _REST ) => #EIncoherentExtensions
         ...</k>
      requires notBool #checkExtension(DEP)
```

We use the same iteration pattern to iterate over all of the extensions
and invoke their initializers.

```k
  //------------------------------------------------------------------

    syntax KItem
      ::= "#initializeExtensions" "(" ExtCReg ")"
        | "#initializeExtensions" "(" ExtCReg "," Int ")"

    rule <k> #initializeExtensions
          => #initializeExtensions(CP1)
          ~> #initializeExtensions(CP2)
          ~> #initializeExtensions(FT)
          ...</k>

    rule <k> #initializeExtensions(CR:ExtCReg)
          => #initializeExtensions(CR, 0)
          ...</k>

    rule <k> #initializeExtensions(CR:ExtCReg, BIT:Int)
          => #initializeExtension( { bit2Extension(CR.BIT) }:>EtcExtension )
          ~> #initializeExtensions(CR:ExtCReg, BIT +Int 1)
          ...</k>
      requires (1 <<Int BIT) <=Int valueInExtCReg(CR)
       andBool UnknownExtension :/=K bit2Extension(CR.BIT)

    rule <k> #initializeExtensions(CR:ExtCReg, BIT:Int)
          => #initializeExtensions(CR, BIT +Int 1)
          ...</k>
      requires (1 <<Int BIT) <=Int valueInExtCReg(CR)
       andBool UnknownExtension  :=K bit2Extension(CR.BIT)

    rule <k> #initializeExtensions(CR:ExtCReg, BIT:Int) => . ...</k>
      requires (1 <<Int BIT) >Int valueInExtCReg(CR)
```

```k
endmodule
```
