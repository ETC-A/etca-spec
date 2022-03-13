# Extensions

ETC.A is an _extensible_ architecture. As such, it needs to be possible to
specify the semantics of an extension given the semantics of the rest of the
system.

This module provides the tools for doing so.

### Hooks

To add an extension, you should import this module and define the hooks for your
extension.

There are 5 function(al) hooks:

* `bit2Extension ( Int )`: the argument is the _bit index_ into CPUID and EXTEN,
  it should evaluate to something of sort `EtcExtension` which indicates which
  extension the bit represents.

* `extension2Bit ( EtcExtension )`: the inverse of `bit2Extension`.

* `extensionDependsOn ( EtcExtension )`: The list of extensions which you
  depend on

* `extensionCanToggle ( EtcExtension )`: Returns a boolean indicating if the
  given extension (yours) can be enabled/disabled. You do not need to check
  the CPUID; this will be done automatically. You should merely indicate if
  changing the status of your extension is possible at all.

* `extensionDefault ( EtcExtension )`: `true` if your extension should be
  enabled by default; false otherwise.
  The caller of this hook checks CPUID and will only invoke the hook if
  your extension is available.

There are also 3 semantic hooks. These symbols will do nothing by default,
with very low priority (400). Provide a rule for them if you must do something;
for example, the Doubleword Operations extension must sign-extend PC.

* `#initializeExtension ( EtcExtension )`: Perform any modifications to the base
  machine configuration that this extension entails. For example, the quadword
  operations extension changes the `<full-reg-width>` cell to `quadword`.

* `#enableExtension ( EtcExtension )`: Perform any actions that should be taken
  when this extension is enabled.

* `#disableExtension ( EtcExtension )`: Perform any actions that should be taken
  when this extension is disabled.

Extensions are intialized before being enabled if they are enabled by default.

### Additional Notes

Your extension also likely requires adding decoding rules, for which you should
see the Decoding section of `etc.md`. You may also have to implement additional
hooks for extensions or features which you are extending.

When `EXTEN` is written to, the hooks defined by your extension will automatically
be invoked to actually enable or disable your extension. Your extension is
responsible for handling the semantics difference between when the extension is
on or off. You can use `checkExtension` (passing either the bit index or
`EtcExtension` constructor) to check if your extension is enabled.

Extensions can safely assume that the settings of their dependents are coherent.
The spec requires that `EXTEN` be coherent if the machine is executing.

# Implementation

The details here are somewhat obtuse and I don't feel like documenting them
at the moment... I suggest looking at existing extensions to see what needs
to be defined.

```k
module EXTENSION-SYNTAX
    imports private INT

    syntax KItem ::= "#enableDefaultExtensions"
                   | "#enableDefaultExtensions" "(" Int ")"
                   | "#writeExten" "(" Int ")"
                   | "#writeExten" "(" Int "," Int ")"
                   | "#checkExtenCoherence"
                   | "#checkExtenCoherence" "(" Int ")"
                   | "#checkExtenCoherence" "(" Int "," List ")"

    syntax Int ::= toggleBit ( Int , Int ) [function, functional]

    syntax Bool ::= "#extensionCanToggle" "(" Int ")" [function, functional]
                  | "#extensionDefault"   "(" Int ")" [function, functional]

    syntax List ::= "#extensionDependsOn" "(" Int ")" [function, functional]
endmodule
```

```k
module EXTENSION
    imports private EXTENSION-SYNTAX
    imports private ETC

    syntax EtcExtension
    syntax MaybeEtcExtension ::= EtcExtension | "UnknownExtension"

    syntax KItem ::= "#enableExtension"     "(" EtcExtension ")"
                   | "#disableExtension"    "(" EtcExtension ")"
                   | "#initializeExtension" "(" EtcExtension ")"

    syntax MaybeEtcExtension ::= bit2Extension ( Int ) [function, functional]
    syntax Int ::= extension2Bit ( EtcExtension )      [function, functional]

    syntax List ::= extensionDependsOn ( EtcExtension ) [function, functional]

    syntax Bool ::= extensionCanToggle ( EtcExtension ) [function, functional]
                  | extensionDefault   ( EtcExtension ) [function, functional]
                  | checkExtension     ( EtcExtension ) [function, functional]

    rule bit2Extension ( _ ) => UnknownExtension [owise]
  //----------------------------------------------------

    rule <k> #enableExtension     ( _ ) => . ...</k> [priority(400)]
    rule <k> #disableExtension    ( _ ) => . ...</k> [priority(400)]
    rule <k> #initializeExtension ( _ ) => . ...</k> [priority(400)]
  //----------------------------------------------------------------

    rule [[ checkExtension(EXT) => bit(extension2Bit(EXT), EXTEN) ]]
         <exten> EXTEN </exten>
  //------------------------------------------------------------------------

    rule <k> #enableDefaultExtensions => #enableDefaultExtensions(0) ...</k>

    rule <k> (. => #initializeExtension( { bit2Extension(BIT) } :>EtcExtension )
                ~> #enableExtension( { bit2Extension(BIT) }:>EtcExtension ))
          ~> #enableDefaultExtensions(BIT:Int => BIT +Int 1)
         ...</k>
         <cpuid> CPUID </cpuid>
         <exten> OLD => OLD |Int (1 <<Int BIT) </exten>
      requires (1 <<Int BIT) <=Int CPUID
       andBool bit(BIT, CPUID)
       andBool #extensionDefault(BIT)

    rule <k> (. => #initializeExtension( { bit2Extension(BIT) }:>EtcExtension ))
          ~> #enableDefaultExtensions(BIT:Int => BIT +Int 1)
         ...</k>
         <cpuid> CPUID </cpuid>
      requires (1 <<Int BIT) <=Int CPUID
       andBool bit(BIT, CPUID)
       andBool notBool #extensionDefault(BIT)

    rule <k> #enableDefaultExtensions(BIT:Int => BIT +Int 1) ...</k>
         <cpuid> CPUID </cpuid>
      requires (1 <<Int BIT) <=Int CPUID
       andBool notBool bit(BIT, CPUID)

    rule <k> #enableDefaultExtensions(BIT:Int) => . ...</k>
         <cpuid> CPUID </cpuid>
      requires (1 <<Int BIT) >Int CPUID
  //-------------------------------------------------------------------------

    rule <k> #writeExten(V:Int) => #writeExten(V,0) ...</k>

    rule <k> (. => #enableExtension( { bit2Extension(BIT) }:>EtcExtension ))
          ~> #writeExten(V:Int , BIT:Int => BIT +Int 1)
         ...</k>
         <cpuid> CPUID </cpuid>
         <exten> OLD => toggleBit(BIT , OLD) </exten>
      requires (1 <<Int BIT) <=Int CPUID
       andBool  bit(BIT, CPUID)
       andBool (bit(BIT, OLD) =/=Bool bit(BIT, V))
       andBool  bit(BIT, V)
       andBool  #extensionCanToggle(BIT)

    rule <k> (. => #disableExtension( { bit2Extension(BIT) }:>EtcExtension ))
          ~> #writeExten(V:Int , BIT:Int => BIT +Int 1)
         ...</k>
         <cpuid> CPUID </cpuid>
         <exten> OLD => toggleBit(BIT , OLD) </exten>
      requires (1 <<Int BIT) <=Int CPUID
       andBool  bit(BIT, CPUID)
       andBool (bit(BIT, OLD) =/=Bool bit(BIT, V))
       andBool  notBool bit(BIT, V)
       andBool  #extensionCanToggle(BIT)

    rule <k> #writeExten(V:Int , BIT:Int => BIT +Int 1) ...</k>
         <cpuid> CPUID </cpuid>
         <exten> OLD   </exten>
      requires (1 <<Int BIT) <=Int CPUID
       andBool notBool (
                 bit(BIT, CPUID)
         andBool (bit(BIT, OLD) =/=Bool bit(BIT, V))
         andBool #extensionCanToggle(BIT))

    rule <k> #writeExten(_V, BIT) => #checkExtenCoherence ...</k>
         <cpuid> CPUID </cpuid>
      requires (1 <<Int BIT) >Int CPUID
  //-----------------------------------------------------------

    rule toggleBit(BIT:Int, V:Int) => V &Int ~Int (1 <<Int BIT)
      requires         bit(BIT, V)
    rule toggleBit(BIT:Int, V:Int) => V |Int      (1 <<Int BIT)
      requires notBool bit(BIT, V)
  //-----------------------------------------------------------

    rule bit2Extension( _ ) => UnknownExtension [priority(400)]
  //-----------------------------------------------------------

    rule #extensionCanToggle(BIT:Int) 
         => extensionCanToggle( { bit2Extension(BIT) }:>EtcExtension )
      requires UnknownExtension :/=K bit2Extension(BIT)
    rule #extensionCanToggle(BIT:Int) => false
      requires UnknownExtension  :=K bit2Extension(BIT)

    rule #extensionDefault(BIT:Int)
         => extensionDefault( { bit2Extension(BIT) }:>EtcExtension )
      requires UnknownExtension :/=K bit2Extension(BIT)
    rule #extensionDefault(BIT:Int) => false
      requires UnknownExtension  :=K bit2Extension(BIT)

    rule #extensionDependsOn(BIT:Int)
         => extensionDependsOn( { bit2Extension(BIT) }:>EtcExtension )
      requires UnknownExtension :/=K bit2Extension(BIT)
    rule #extensionDependsOn(BIT:Int) => .List
      requires UnknownExtension  :=K bit2Extension(BIT)
  //------------------------------------------------------------------

    rule <k> #checkExtenCoherence => #checkExtenCoherence(0) ...</k>

    rule <k> #checkExtenCoherence(BIT:Int, .List) 
          => #checkExtenCoherence(BIT +Int 1)
         ...</k>

    rule <k> #checkExtenCoherence(_BIT, ListItem(DEP) REST => REST) ...</k>
         <exten> EXTEN </exten>
      requires bit(DEP, EXTEN)

    rule <k> #checkExtenCoherence(_BIT, ListItem(DEP) _REST) => #EIncoherentEXTEN
         ...</k>
         <exten> EXTEN </exten>
      requires notBool bit(DEP, EXTEN)

    rule <k> #checkExtenCoherence(BIT:Int)
          => #checkExtenCoherence(BIT, #extensionDependsOn(BIT)) ...</k>
endmodule
```
