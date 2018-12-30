; IoTa OS Master Boot Record Sector version 0.b
; Common code for read sectors into memory
; Included by iota and loader
; 7/17/2013
; 08/08/2016

;;load sector and put in memory

%macro	readSector 6

	mov bx, %1				;es:bx input buffer
	mov es, bx
	mov bx, %2				;Set offset [ex:bx]
	mov ah, 02h				;Function 02h (read sector)
	mov al, %3				;Read number of sectors
	mov ch, %4				;Cylinder#
	mov cl, %5				;Sector#
	mov dh, %6				;Head# 
	mov dl, 0				;Drive# A, 08h=C
	int 13h

%endmacro