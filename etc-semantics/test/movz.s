;-mstrict
;0,8,16392,32776
; movz under cpuid 0 should fail unsupported.
; We test movzh and movzx under byte_ops, byte_ops+dops, and byte_ops+qops
.extension byte_operations
    mov   %rx0,-1     ; %r0 <= 65535
    movzx %rx1,%rx0   ; %r1 <= 65535
    movzh %rh0,%rh0   ; %r0 <= 255
end:
    jmp   end
