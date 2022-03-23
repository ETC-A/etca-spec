;-mnaked-reg
;0
; Ported from ../../customasm/test_jumps.asm

test_jmp:
    jmp  test_zero_on
.fail:
    jmp  .fail

test_zero_on:
    mov  r0, 0
    test r0, -1

    jnz  .fail
    jz   test_zero_off
.fail:
    jmp .fail ; program counter will indicate failure

test_zero_off:
    mov  r0, 1
    test r0, -1

    jz   .fail
    jnz  test_negative_on
.fail:
    jmp  .fail

test_negative_on:
    mov  r0, -1
    test r0, -1

    jnn  .fail
    jn   test_negative_off
.fail:
    jmp  .fail

test_negative_off:
    mov  r0, 0
    test r0, -1

    jn   .fail
    jnn  test_carry_on
.fail:
    jmp  .fail

test_carry_on:
    mov  r0, -1
    add  r0, 15

    jnc  .fail
    jc   test_carry_off
.fail:
    jmp  .fail

test_carry_off:
    mov  r0, 15
    add  r0, 15
    jc   .fail
    jnc  test_borrow_on
.fail:
    jmp  .fail

test_borrow_on:
    mov  r0, 0
    cmp  r0, 1
    jnc  .fail
    jc   test_borrow_off
.fail:
    jmp  .fail

test_borrow_off:
    mov  r0, 1
    cmp  r0, 1
    jc   .fail
    jnc  test_overflow_on
.fail:
    jmp  .fail

test_overflow_on:
    mov  r0, 0x7fff
    add  r0, 1
    jnv  .fail
    jv   test_overflow_off
.fail:
    jmp  .fail

test_overflow_off:
    mov  r0, 0x7fff
    sub  r0, 1
    jv   .fail
    jnv  test_equal
.fail:
    jmp  .fail

test_equal:
    cmp  r0, r0
    jne  .fail
    jb   .fail
    ja   .fail
    jl   .fail
    jg   .fail

    je   .s1
    jmp  .fail
.s1:
    jbe  .s2
    jmp  .fail
.s2:
    jae  .s3
    jmp  .fail
.s3:
    jle  .s4
    jmp  .fail
.s4:
    jge  test_not_equal
.fail:
    jmp  .fail

test_not_equal:
    mov  r0, 0
    cmp  r0, 1

    je   .fail
    jne  .s1
    jmp  .fail
.s1:
    jb   .s2
    ja   .s2
    jmp  .fail
.s2:
    jl   test_ucomp_1
    jg   test_ucomp_1
.fail:
    jmp  .fail

test_ucomp_1:
    mov  r0, 10
    cmp  r0, 5
    jb   .fail
    jbe  .fail
    ja   .s1
    jmp  .fail
.s1:
    jae  test_ucomp_2
.fail:
    jmp  .fail

test_ucomp_2:
    mov  r0, 5
    cmp  r0, 10
    ja   .fail
    jae  .fail
    jb   .s
    jmp  .fail
.s:
    jbe  test_ucomp_3
.fail:
    jmp  .fail

test_ucomp_3:
    mov  r0, -10
    cmp  r0, 5
    jb   .fail
    jbe  .fail
    ja   .s
    jmp  .fail
.s:
    jae  test_ucomp_4
.fail:
    jmp  .fail

test_ucomp_4:
    mov  r0, 5
    cmp  r0, -10
    ja   .fail
    jae  .fail
    jb   .s
    jmp  .fail
.s:
    jbe  test_scomp_1
.fail:
    jmp  .fail

test_scomp_1:
    mov  r0, 10
    cmp  r0, 5
    jl   .fail
    jle  .fail
    jg   .s
    jmp  .fail
.s:
    jge  test_scomp_2
.fail:
    jmp  .fail

test_scomp_2:
    mov  r0, 5
    cmp  r0, 10
    jg   .fail
    jge  .fail
    jl   .s
    jmp  .fail
.s:
    jle  test_scomp_3
.fail:
    jmp  .fail

test_scomp_3:
    mov  r0, 5
    cmp  r0, -10
    jl   .fail
    jle  .fail
    jg   .s
    jmp  .fail
.s:
    jge  test_scomp_4
.fail:
    jmp  .fail

test_scomp_4:
    mov  r0, -10
    cmp  r0, 5
    jg   .fail
    jge  .fail
    jl   .s
    jmp  .fail
.s:
    jle  done
.fail:
    jmp  .fail

done:
    mov  r7,1
.hlt:
    jmp  .hlt
