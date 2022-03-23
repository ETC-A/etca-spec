;-mstrict
;128
    movx %rx0,%exten
    movx %rx1,4
    slox %rx1,0       ; 128
    orx  %rx0,%rx1    ; set q-ops bit
    movx %exten,%rx0  ; enable q-ops
.extension qword_operations
; now we want to test that q-ops work. Simple test is to set any bits
; that don't fit in a dword and look at the result. To do that here,
; we're just sliding some bits over with sloq a bunch. We can't just
; set -1 as a dword because `etc-as` can't encode `zext` yet.
; %r0 already has 128 (at least) in it, so...
    sloq %rq0,0       ; 2^12
    sloq %rq0,0       ; 2^17
    sloq %rq0,0       ; 2^22
    sloq %rq0,0       ; 2^27
    sloq %rq0,0       ; 2^32
end:
    jmp end