;-mstrict
;8
.extension byte_operations
    movx %rx0,1
    subh %rh0,2  ; should result in -1
    movx %rx1,-1
    andh %rh1,-1 ; also -1
    movx %rx2,-1
    xorh %rh2,15 ; -16
    mov  %rx3,0x11ff ; random bits in top byte, 255 in bottom byte
    sloh %rh3,0  ; -32 (0b11100000) [test sign extended]
end:
    jmp end