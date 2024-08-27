;-mstrict
;8
.extension byte_operations

    movx %rx1,0
    mov  %rx0,0x0aff
    movx [%rx1],%rx0
    movx %rx2,[%rx1]
    movh %rh3,[%rh1]
    addx %rx1,1
    movh %rh4,[%rh1]  
    movh [%rh1],%rh0 ; note 1: not word-aligned
                     ; note 2: config checks *0 unchanged
end:
    jmp  end
