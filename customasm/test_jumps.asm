#include "customasm/base-isa.rules"

#ruledef {
    halt => asm {
        out r0, 1
        hlt
    }
}
jump test_zero_flag_on

fail:
    halt

test_zero_flag_on:
    mov r0, 0
    test r0, -1

    jump_not_zero fail
    jump_zero test_zero_flag_off
    halt

test_zero_flag_off:
    mov r0, 1
    test r0, -1

    jump_zero fail
    jump_not_zero test_negative_flag_on
    halt

test_negative_flag_on:
    mov r0, -1
    test r0, -1

    jump_not_negative fail
    jump_negative test_negative_flag_off
    halt

test_negative_flag_off:
    mov r0, 0
    test r0, -1

    jump_negative fail
    jump_not_negative test_carry_flag_off
    halt


test_carry_flag_off:
    mov r0, 15
    add r0, 15

    jump_carry fail
    jump_not_carry test_carry_flag_on
    halt

test_carry_flag_on:
    mov r0, -1
    add r0, 15

    jump_not_carry fail
    jump_carry test_borrow_flag_off
    halt

test_borrow_flag_off:
    mov r0, 1
    comp r0, 1

    jump_carry fail
    jump_not_carry test_borrow_flag_on
    halt

test_borrow_flag_on:
    mov r0, 0
    comp r0, 1

    jump_not_carry fail
    jump_carry test_overflow_flag_off
    halt

test_overflow_flag_off:
    mov r0, 0
    slo r0, 31
    slo r0, 31
    slo r0, 31
    sub r0, 1

    jump_overflow fail
    jump_not_overflow test_overflow_flag_on
    halt

test_overflow_flag_on:
    mov r0, 0
    slo r0, 31
    slo r0, 31
    slo r0, 31
    add r0, 1

    jump_not_overflow fail
    jump_overflow test_equal
    halt

test_equal:
    comp r0, r0

    jump_not_equal fail
    jump_below fail
    jump_above fail
    jump_less fail
    jump_greater fail

    jump_equal .success_1
    halt
  .success_1:
    jump_below_or_equal .success_2
    halt
  .success_2:
    jump_above_or_equal .success_3
    halt
  .success_3:
    jump_less_or_equal .success_4
    halt
  .success_4:
    jump_greater_or_equal test_not_equal
    halt

test_not_equal:
    mov r0, 0
    test r0, 1

    jump_equal fail
    jump_below_or_equal fail
    jump_above_or_equal fail
    jump_less_or_equal fail
    jump_greater_or_equal fail

    jump_not_equal .success_1
    halt
  .success_1:
    jump_below .success_2
    halt
  .success_2:
    jump_above .success_3
    halt
  .success_3:
    jump_less .success_4
    halt
  .success_4:
    jump_greater test_ucomp_1
    halt

test_ucomp_1:
    mov r0, 10
    comp r0, 5
    jump_below fail
    jump_below_or_equal fail
    jump_above .success
    halt
  .success:
    jump_above_or_equal test_ucomp_2
    halt

test_ucomp_2:
    mov r0, 5
    comp r0, 10
    jump_above fail
    jump_above_or_equal fail
    jump_below .success
    halt
  .success:
    jump_below_or_equal test_ucomp_3
    halt

fail2:
    halt

test_ucomp_3:
    mov r0, -10
    comp r0, 5
    jump_below fail2
    jump_below_or_equal fail2
    jump_above .success
    halt
  .success:
    jump_above_or_equal test_ucomp_4
    halt
    
test_ucomp_4:
    mov r0, 5
    comp r0, -10
    jump_above fail2
    jump_above_or_equal fail2
    jump_below .success
    halt
  .success:
    jump_below_or_equal test_scomp_1
    halt


test_scomp_1:
    mov r0, 10
    comp r0, 5
    jump_less fail2
    jump_less_or_equal fail2
    jump_greater .success
    halt
  .success:
    jump_greater_or_equal test_scomp_2
    halt

test_scomp_2:
    mov r0, 5
    comp r0, 10
    jump_greater fail2
    jump_greater_or_equal fail2
    jump_less .success
    halt
  .success:
    jump_less_or_equal test_scomp_3
    halt

test_scomp_3:
    mov r0, 5
    comp r0, -10
    jump_less fail2
    jump_less_or_equal fail2
    jump_greater .success
    halt
  .success:
    jump_greater_or_equal test_scomp_4
    halt
    
test_scomp_4:
    mov r0, -10
    comp r0, 5
    jump_greater fail2
    jump_greater_or_equal fail2
    jump_less .success
    halt
  .success:
    jump_less_or_equal done
    halt

done:
    jump done

