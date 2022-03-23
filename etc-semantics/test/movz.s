;-mstrict
;0,16,80,144
; test that movz works under each mode. ketc will ignore writes to exten bits
; that aren't supported by the cpuid. movz under cpuid 0 should fail unsupported.
; We test movzh and movzx under byte_ops, byte_ops+dops, and byte_ops+qops

    movx  %rx0,%exten
    movx  %rx1,0xd0   ; byte ops, dops, qops
    orx   %rx0,%rx1
    movx  %exten,%rx0 ; and enable them (byte ops were already enabled)
.extension byte_operations
    movzh %rh0,-1     ; %r0 <= 255
    movzx %rx1,-1     ; %r0 <= 65535
end:
    jmp   end
