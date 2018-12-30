##################################################
# Makefile of iotaV0x.asm (x=[a, b])
#
# Update: 08/08/2016
# Make sure NO TAB char at the beginning of if then else
# Make sure TAB char at the beginning of each build rule
##################################################

# elf header (0x34) xxd -u -a -g 1 -c 16 -l 0x34 kernelV07.bin
# prog header (0x20) xxd -u -a -g 1 -c 16 -s 0x34 -l 0x20 kernelV07.bin

# special notes
# (1) jmp start, no short except for MBR
# (2) [section .code32] must
# (3)  in 32 bit, all ADDR offset are 32 bits
# (4) move IDT from loader to kernel

VER			= V0b
LSECTORS		= 1
KSECTORS		= 5
IMG			= a.img

ASM			= nasm
BINFLAG		= -f bin -I boot/include/
ELFFLAG		= -f elf
CC				= gcc
CCFLAG			= -m32 -c -I include/

MBR			= boot/iotaV.asm
LDR			= boot/loaderV.asm
KER			= kernel/kernelV.asm
LIBVID			= lib/videoV.asm
LIBC			= kernel/utilV.c
LIB8259		= lib/i8259V.asm

MBR_SRC		= $(subst V,$(VER),$(MBR))
MBR_BIN		= $(subst .asm,.bin,$(MBR_SRC))
LDR_SRC		= $(subst V,$(VER),$(LDR))
LDR_BIN		= $(subst .asm,.bin,$(LDR_SRC))
KER_SRC		= $(subst V,$(VER),$(KER))
KER_BIN		= $(subst .asm,.bin,$(KER_SRC))
KER_O			= $(subst .asm,.o,$(KER_SRC))

LIBVID_SRC		= $(subst V,$(VER),$(LIBVID))
LIBVID_O		= $(subst .asm,.o,$(LIBVID_SRC))
LIB8259_SRC	= $(subst V,$(VER),$(LIB8259))
LIB8259_O		= $(subst .asm,.o,$(LIB8259_SRC))
LIBC_SRC		= $(subst V,$(VER),$(LIBC))
LIBC_O			= $(subst .c,.o,$(LIBC_SRC))

.PHONY : everything

everything : $(MBR_BIN) $(LDR_BIN) $(KER_BIN) 

 ifneq ($(wildcard $(IMG)), )
 else
		dd if=/dev/zero of=$(IMG) bs=512 count=2880
endif
		dd if=$(MBR_BIN) of=$(IMG) bs=512 count=1 conv=notrunc
		dd if=$(LDR_BIN) of=$(IMG) bs=512 count=$(LSECTORS) seek=35 conv=notrunc
		dd if=$(KER_BIN) of=$(IMG) bs=512 count=$(KSECTORS) seek=37 conv=notrunc

$(MBR_BIN) : $(MBR_SRC)
	$(ASM) $(BINFLAG) $< -o $@

$(LDR_BIN) : $(LDR_SRC)
	$(ASM) $(BINFLAG) $< -o $@

$(LIBVID_O) : $(LIBVID_SRC)
	$(ASM) $(ELFFLAG) $< -o $@

$(LIB8259_O) : $(LIB8259_SRC)
	$(ASM) $(ELFFLAG) $< -o $@

$(LIBC_O) : $(LIBC_SRC)
	$(CC) $(CCFLAG) $< -o $@

$(KER_BIN) : $(KER_SRC) $(LIBVID_O) $(LIB8259_O) $(LIBC_O)
	$(ASM) $(ELFFLAG) -o $(KER_O) $(KER_SRC)
	ld -m elf_i386 -Ttext 0x30400 -s -o $@ $(KER_O) $(LIBVID_O) $(LIB8259_O) $(LIBC_O)

clean :
	rm -f $(MBR_BIN) $(LDR_BIN) $(KER_BIN) $(KER_O) $(LIBVID_O) $(LIB8259_O) $(LIBC_O)

reset:
	rm -f $(MBR_BIN) $(LDR_BIN) $(KER_BIN) $(KER_O) $(LIBVID_O) $(LIB8259_O) $(LIBC_O) $(IMG)
	
blankimg:
	dd if=/dev/zero of=$(IMG) bs=512 count=2880
