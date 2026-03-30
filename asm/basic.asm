start:
    ldi r16, 10
    ldi r17, 20
    and r16, r17
    tst r16
    ori r16, 240
    dec r16
    mul r16, r17
    muls r16, r17
    clr r17
    sts 128, r16
    lds r18, 128
    push r16
    pop r0
    mov r19, r18
    out 5, r19
    in r20, 5
outer_loop:
    ldi r16, 3
loop:
    call subroutine_dec_r16
    brne loop
    rjmp outer_loop

subroutine_dec_r16:
    dec r16
    ret
