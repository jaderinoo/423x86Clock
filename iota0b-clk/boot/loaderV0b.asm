; IoTa OS version 0.b
; Load and call by MBR
; Loader kernel and enter protected mode
; Then reallocate kernel to 30000:0000 based on elf format
; Kernel in asm and c
; IDT is moved to kernel
; Bios only, No DOS, No Linux, No any OS
; Copy to Sector 35 (CHS 0:1:18)
; 7/17/2013
; 08/08/2016

	org 00h						;Set addressing to begin at 00H for actual run
	[bits 16]						;by default bits 16	
	jmp 	start					;DO NOT use short
	nop
	
bsOEM	db "IoTa v.0.b"			;OEM String

%include	"readV0b.inc"

%macro	csVal 2
		shr cx, %1		
		mov bl, cl
		and bl, 0x0f						
		add bl, 0x30						;ascii
		;mov [csMsg+%2], bl				;cs value in ascii
%endmacro

;====================================================
BaseOfStack					equ	0400h		;this version needs stack
BaseOfLoaderPhyAddr		equ	0x80000		;BaseOfLoader * 10h	

BaseOfKernelFile				equ	09000h		;segment address of loader.bin
OffsetOfKernelFile			equ	0000h		;offset address of loader.bin -- 0x9000:0000
BaseOfKernelFilePhyAddr		equ 0x90000		;base:offset combined

NumberOfSectors			equ 5			;kernel file size larger than 512 bytes
KernelEntryPointPhyAddr		equ	030400h		;ld -Ttext 0x30400
;=====================================================

;============================================================
; Part 1)  -- GDT 
;============================================================

[section .gdt]

GDT:
	dd  0								;1st entry, null descriptor, reserved by 
	dd  0								;intel, should not be changed.
    
										;to simplify,  two segment base from 0000
										;limit to 1MB/4GB
										;address up to 90000 so 10x64KB blocks

GDT_code32		equ $-GDT				;code segment descriptor
GDT_01:									
    dw  0x0a								;1 block=64KB
    										;loader base=80000 kernel=90000
    										;locate enough space -> 10 0000
    dw  0x00								
    db  0x00								;base = 0,0000
    db  0x9a								;present, read-only, code
    db  0xcf								;4Gb limit, 32-bit
    db  0x00								
    
GDT_data		equ $-GDT				;data segment descriptor
GDT_02:
    dw 0x0a								;1 block = 64KB
    										;enough space up to 90000
    											
    dw  0x00								;base = 0,0000
    db  0x00									
    db  0x92								;present, writeable, data
    db 0xcf								;4GB limit, 32-bit
;    db  0x62								;1MB limit, 32-bit
    db  0x00
 
GDT_video	 	equ $-GDT	 		      	; ie 18h,next gdt entry
   dw 3999	       							; Limit 80*25*2-1
   dw 0x8000	       							; Base 0xb8000
   db 0x0b
   db 0x92							       	; present,ring 0,data,expand-up,writable
   db 0x00	       							; byte granularity 16 bit
   db 0x00

;GDT_end:

GDT_dscr:								;GDT descriptor,  loaded by instruction LGDT
gdt_limit:	dw  $ - GDT - 1				;limit, length of GDT in byte
gdt_base:	dd  BaseOfLoaderPhyAddr+GDT
										;address of the GDT table, 80000::GDT										;can be put anywhere, not just the end

;============================================================
; Part 2) -- boot into real mode 
;============================================================

		[bits 16]	
[section .code16]
		
start:
		mov ax, cs						;Since code is in 0x8000:0000, must reset data segment
		mov ds, ax
		mov	 ss, ax
		mov	 sp, BaseOfStack
		
;		mov cx, ax						;in 8000:0000, save code space
;		csVal 0,14
;		csVal 4,12
;		csVal 4,10
;		csVal 4, 8
		
;dispstr:
		mov bx,0xb800
		mov es, bx						;cs=ds=0000 by default
		lea si, [welMsg]					;load the offset address of string
		mov di, 160						;skip 1 row ds:si to es:di
		mov cx, welLen					;length of message string
		cld								;clear DF (direction flag)
		rep movsb						;move string to video memory

;;load loader.bin from sector 37 and put in memory 0x9000:0000
		readSector BaseOfKernelFile, OffsetOfKernelFile, NumberOfSectors, 1, 2, 0

;============================================================
; Part 3) -- set GDT entry values, set in GDT already 
;============================================================

;============================================================
; Part 4) -- prepare for protected mode 
;============================================================

		lgdt [GDT_dscr]					;load physical address of GDT
		cli								;disable interrupt
		
		;in al, 92h						;open A20
		;or al, 00000010b
		;out 92h, al
		
		mov eax,cr0						;set the PE (protected mode enable) flag
		or al,1							;0th bit of the CR0 register
		mov cr0,eax						;enter protected mode
		
;to Proteced Mode:
		jmp dword GDT_code32:(BaseOfLoaderPhyAddr + protected_code)
										;GDT_code32 base is 0,0000
										;must, PMode needs descriptor:offset
										;cs<-GDT_code32's base
										
;============================================================
; Part 5) -- code in 32bit protected mode 
;============================================================
				
		[bits 32]							;must indicate
[section .code32]							;if use GDT_code32:protected_code
										;Int21Handeler uses $-$$,  must have section here		

protected_code: 
		mov ax,  GDT_video				; value is 0x18 (offset 24 bytes)
		mov es, ax						; in 32bit mode, es=[GDT:ax] offset not ax value
		
		mov ax, GDT_data				;value is 0x10 (offset 16 bytes)
		mov ds, ax						;data segment description is the 2nd in GDT			
										;need set ds for data
		mov ss, ax
		mov esp, TopOfStack
				
		lea	esi, [pmMsg]
		add esi, BaseOfLoaderPhyAddr
										;load the offset address of string
		mov edi, 80 * 3					;skip 1.5 rows, ds:esi/es:edi 32 bits now
		mov ecx, pmLen					;length of message string
		cld								;clear DF (direction flag)
		rep movsb						;move string to video memory
										;no bios int 10h in protected mode	

;============================================================
; Part 6) -- relocate kernel based on elf format
;============================================================	
			
		;;jmp dword GDT_code32:(BaseOfKernelFilePhyAddr + 0x400)
										; 0x90400	
										;09000::00400 is the entry of code
										;need to move to 30000::00000

		mov ax, GDT_data				;set ds=es for memcopy
		mov ds, ax
		mov es, ax	

		;align 32							;must, otherwise strange!!??

		call initKernel
		
		mov ax,  GDT_video				;reset es for display
		mov es, ax
		
		jmp dword GDT_code32:KernelEntryPointPhyAddr
										; 30400
												
initKernel:
		xor esi, esi
		mov cx, word [BaseOfKernelFilePhyAddr + 0x2c]		;pELFHeader->e_phnum (1)
		movzx ecx, cx
		mov esi, [BaseOfKernelFilePhyAddr + 0x1c]  		;pELFHeader->e_phoff (34h)
		add esi, BaseOfKernelFilePhyAddr					;end of pELFHeader
														;beginning of pHeader
.begin:
		mov eax, [esi + 0]									;pHeaser->p_type
		cmp eax, 0										;PT_NULL
		jz .noAction
		
		push  dword [esi + 010h]    				;size		; | PHeader->p_filesz (040dh)
		mov eax, [esi + 04h]								; | PHeader->p_offset (0)				
		add eax, BaseOfKernelFilePhyAddr					; | memcpy((void*)(pPHdr->p_vaddr),
		push eax								;src		; |      uchCode + pPHdr->p_offset,
		push dword [esi + 08h]    					;dst		; |      pPHdr->p_filesz;
		call  memCpy										; |
		add esp, 12										;/	clean stack
.noAction:
		add esi, 020h 									;esi += pELFHeader->e_phentsize
		dec ecx
        	jnz   .begin

		ret

; void* memCpy(void* es:pDest, void* ds:pSrc, int iSize);
memCpy:		
		push ebp
		mov	 ebp, esp
		
		push esi
		push edi
		push ecx

		mov	 edi, [ebp + 8]			;Destination
		mov	 esi, [ebp + 12]			;Source
		mov	 ecx, [ebp + 16]			;Counter
		
.1:
		cmp	ecx, 0					; compare counter
		jz .2							; break when counter be 0

		mov	 al, [ds:esi]				; ┓
		inc esi						; ┃
									; ┣ move byte by byte
		mov	byte [es:edi], al			; ┃ need set ds=es
		inc edi						; ┛

		dec	ecx
		jmp	.1
.2:
		mov	 eax, [ebp + 8]			; return value

		pop	ecx
		pop	edi
		pop	esi
		mov	 esp, ebp
		pop	ebp
		
		ret

;		mov ax,si					;needs alian 32
;		mov	 ah, 2dh					;lightred on green
;		;mov	 al, cl
;		and al, 0x0f
;		add al, 0x30
;		mov	 [es:((80 * 4 + 34) * 2)], ax	;row 1 col 34

;============================================================
; Part 7) -- message, data
;============================================================		

	[bits 16]	
[section	.data]

LABEL_DATA_SEG:

; / = 0xf2 -- white on green
welMsg	db ' '
csMsg db ' '
welLen equ $-welMsg

; . = 0xe2 -- yellow on green
pmMsg db ' '
pmLen equ $-pmMsg

;;StackSpace:	times	1000h	db	0
TopOfStack	equ	BaseOfLoaderPhyAddr + 400h


