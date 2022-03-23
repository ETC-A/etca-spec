;-mstrict
;64,192
    movx %rx0,%exten
    movx %rx1,2
    slox %rx1,0       ; 64
    orx  %rx0,%rx1    ; set d-ops bit
    movx %exten,%rx0  ; enable d-ops
.extension dword_operations
; now we want to test that d-ops work. Simple test is to set any bits
; that don't fit in a word and look at the result. To do that here,
; we're just sliding some bits over with slod a bunch. We can't just
; set -1 as a word because `etc-as` can't encode `zext` yet.
; %r0 already has 64 (at least) in it, so...
    slod %rd0,0       ; 2^11
    slod %rd0,0       ; 2^16
    slod %rd0,0       ; 2^21
end:
    jmp end