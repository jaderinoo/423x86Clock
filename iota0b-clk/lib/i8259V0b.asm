
;For testing IRQ0 (clock) in protected mode 
;Clock interrupt by default is int 08h but can not be used 
;Redirect IRQ00 to int 40h 
; 7/17/2013 
; 08/08/2016 
                                         
        [bits 32]                            ;must indicate 
[section .code32]                            ;must put a section     
 
global    __init8259                        ;__ : asm util file, _ : c util file 
global    __int0x30
extern _inc_clock	; ok
 
 
;============================================================ 
; Func 1) -- void __init8259(), unmask IRQ0 and maps to int 40h 
;============================================================ 
 
__init8259: 
 
        mov     al, 0x11                            ;ICW1 and need ICW4 
        out    20h, al                            ;master 8259, ICW1 
        call    io_wait 
 
        out    0A0h, al                            ;slave 8259, ICW1 
        call    io_wait 
 
        mov al, 0x30                            ;IRQ0 maps to 0x30  
                                            ;This is key step to link IRQ1 to INT XX 
                                            ;lower 3 bits in ICW2 must be 0 
        out    21h, al                            ;master 8259, ICW2 
        call    io_wait 
 
        mov al, 0x38                             ;IRQ8 maps to 0x38 
        out    0a1h, al                            ;master 8259, ICW2 
        call    io_wait 
 
        mov     al, 0x04                            ;IR2 has slave 8259 
        out    21h, al                            ;master8259, ICW3 
        call    io_wait 
 
        mov     al, 0x02                            ;master 8259 IR2 
        out    0a1h, al                            ;slave 8259, ICW3 
        call    io_wait 
 
        mov al, 0x01                            ;80x86 mode 
        out    21h, al                            ;master 8259, ICW4 
        call    io_wait 
 
        out    0a1h, al                            ;slave 8259, ICW4 
        call    io_wait 
 
        mov     al, 11111110b                    ;only open IRQ1=KBD 
        out    21h, al                            ;master 8259, OCW1 
        call    io_wait 
 
        mov al, 11111111b                    ;mask all interrupts 
        out    0a1h, al                            ;slave 8259, OCW1 
        call    io_wait 
 
        ret 
 
io_wait: 
        nop                                    ; 
        nop 
        nop 
        nop 
         
        ret 
 
;============================================================
; Func 6) -- void int0x30 (), very trivial
;============================================================
__int0x30:
			call _inc_clock
			mov al, 20h
			out 20h, al
			iret
		