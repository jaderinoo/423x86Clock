; IoTa OS Master Boot Record Sector version 0.b
; Seven (1+1+5) sectors
; Loader sector into protected mode
; Kernel in elf format and reallocate
; Use asm and c
; Add IDT, clock IRQ,  in kernel
; Reorganize files into directories
; Copy to Sector 0 (C0:H0:S1)
; 7/17/2013
; 08/08/2016

	;bit16			;16 bit by default
	org 0x7c00
	
;====================================================
BaseOfStack			equ	0100h	;this version needs stack
BaseOfLoader		equ	08000h	;segment address of loader.bin
OffsetOfLoader		equ	0000h	;offset address of loader.bin -- 0x8000:0000
NumberOfSectors		equ 1		;loader file size larger than 512 bytes
;=====================================================
	
	jmp short start			;only 1 sector, can use short
	nop
bsOEM	db "IoTa v.0.b"		;OEM String

;;section	.text

%include	"readV0b.inc"

start: 
	mov ax, cs				;default is 0000
	mov	 ds, ax
	mov	 es, ax
	mov	 ss, ax
	mov	 sp, BaseOfStack

;;cls
	mov ah, 06h				;Function 06h (scroll screen)
	mov al, 0				;Scroll all lines
	mov bh, 2fh				;Attribute (white on green) 
	mov ch, 0				;Upper left row is zero
	mov cl, 0					;Upper left column is zero
	mov dh, 24				;Lower left row is 24
	mov dl, 79				;Lower left column is 79
	int 10h					;BIOS Interrupt 10h (video services)
				;Colors from 0: Black Blue Green Cyan Red Magenta Brown White
				;Colors from 8: Gray LBlue LGreen LCyan LRed LMagenta Yellow BWhite

;;printHello
	mov ah, 13h				;Function 13h (display string)
	mov al, 1				;Write mode is zero
	mov bh, 0				;Use video page of zero
	mov bl, 2ah				;Attribute (lightgreen on green)
	mov cx, mlen				;Character string length
	mov dh, 0				;Position on row 0
	mov dl, 0				;And column 0
	lea bp, [msg]				;Load the offset address of string into BP
	int 10h

;;moveCursor
	mov ah, 2				;Function 02h (set cursor position)
;	mov bh, 0				;ActivePageNumber
	mov dh, 04h 				;row
	mov dl, 19h 				;col
	int 10h

	mov ah, 09h				;Function 09h (write a char at cursor position)
	mov al, ' '				;char to write
;	mov bh, 0
	mov bl, 2eh				;color attr
	mov cx, 1				;number of repeat
	int 10h

		
;;load loader.bin from sector 35 and put in memory 0x8000:0000
	readSector BaseOfLoader, OffsetOfLoader, NumberOfSectors, 0, 18, 1
	jmp word BaseOfLoader:OffsetOfLoader

;;section	.data

msg	db 'IoTa, my OS, version 1 (c) ...'
mlen equ $-msg

padding	times 510-($-$$) db 0		;to make MBR 512 bytes
bootSig	db 0x55, 0xaa			;signature
