; IoTa OS version 0.b
; Load and call by loader
; elf format in protected mode using asm and c
; Copy to Sector 37 (CHS 1:0:2)
; IDT and IRQ0 handler for clock as int 40h
; 7/17/2013
; 08/08/2016
                
                [bits 32]
[section .text]

extern __disp_str                        ;define in disp.asm __ : asm
extern _begin                        ;define in util.c    _ : c
extern __int0x30

global _start                        ; _start entry

_start:

;============================================================
; Part 1) -- set up GDT and IDT in kernel 
;============================================================
        
;set int 40h offset:
        xor    eax, eax
        mov     eax, __int0x30
;;        add    eax, BaseOfKernelFilePhyAddr ; NO NEED in 32bit elf
        mov word [IDT + 8*48], ax        ;int 30h=48
        shr eax, 16
        mov word [IDT + 8*48 + 6], ax

                                        ;could copy GDT from loader
                                        ;but to make it simple, redefine GDT
        ;lgdt [GDT_ptr]                    ;this has advantage of remap the OS code
        cli
        lidt    [IDT_ptr]
        sti

;============================================================
; Part 2) -- start from functions written in C 
;============================================================

        push word [color_attr]
        push dword kernelMsg
        call    __disp_str

        push dword [ver]                ;push last parameter first
        call _begin

        mov ax, GDT_video
        mov es, ax

        mov al, ''
        mov ah, 2ch
        mov [es:722], ax                ;es<-GDT_video
        
        sti                            ;must for IRQ1
        jmp $                        ;stop PC

;============================================================
; Part 4) -- Data Section 
;============================================================
            
[section .data]

        ;align 32

ver            dd    0bh                    ;iota version
kernelMsg:    db    0ah, 0ah, "", 0ah, 0ah, 0
color_attr:    dw    0x002a                ;push at least a word


;============================================================
; Part 5)  -- GDT *** can be improved to remove this duplicate GDT
;============================================================

[section .gdt]

GDT:
    dd  0                                ;1st entry, null descriptor, reserved by 
    dd  0                                ;intel, should not be changed.
    
                                        ;to simplify,  two segment base from 0000
                                        ;limit to 1MB/4GB
                                        ;address up to 90000 so 10x64KB blocks

GDT_code32        equ $-GDT                ;code segment descriptor
GDT_01:                                    
    dw  0xffff                                ;1 block=64KB
                                            ;loader base=80000 kernel=90000
                                            ;locate enough space
    dw  0x00                                
    db  0x00                                ;base = 0,0000
    db  0x9a                                ;present, read-only, code
    db  0xcf                                ;4Gb limit, 32-bit
    db  0x00                                
    
GDT_data        equ $-GDT                ;data segment descriptor
GDT_02:
    dw 0xffff                                ;1 block = 64KB
                                            ;enough space up to 90000
                                                
    dw  0x00                                ;base = 0,0000
    db  0x00                                    
    db  0x92                                ;present, writeable, data
    db 0xcf                                ;4GB limit, 32-bit
;    db  0x62                                ;1MB limit, 32-bit
    db  0x00
 
GDT_video         equ $-GDT                       ; ie 18h,next gdt entry
   dw 3999                                       ; Limit 80*25*2-1
   dw 0x8000                                       ; Base 0xb8000
   db 0x0b
   db 0x92                                       ; present,ring 0,data,expand-up,writable
   db 0x00                                       ; byte granularity 16 bit
   db 0x00

;GDT_end:

GDT_ptr:                                ;GDT descriptor,  loaded by instruction LGDT
gdt_limit:    dw  $ - GDT - 1                ;limit, length of GDT in byte
gdt_base:    dd  GDT                        ;offset of GDT
                                        ;in 32bit elf, no need to add segment 

;============================================================
; Part 6) -- IDT 
;============================================================

;DA_386IGate        equ      8eh            ;call gate

[section .idt]

IDT:
%rep 0x30
        dw 0                            ;each IDT entry is 8 bytes
        dw GDT_code32
        dw 0x8e00
        dw 0
%endrep
.30h:                                    ;has to reset
        dw 0                            ;offset  lower 4
        dw GDT_code32                    ;selector 
        dw 0x8e00                        ;attr  ((%@ << 8) & 0FF00h)
        dw 0                            ;offset higher 4
        
IDTLen    equ    $ - IDT - 1
IDT_ptr:
idt_limit:    dw    IDTLen                    ;limit
idt_base:    dd    IDT                        ;base, in 32bit elf, offset is 32 bit
                                        ;no more add by segment offset