CC=mb-gcc
CFLAGS=-mxl-pattern-compare -mno-xl-soft-mul -mxl-barrel-shift

#LDSCRIPTS=bootloader_linker_script_bram.ld
LDSCRIPTS=bootloader_linker_script_ddr.ld

all: host.elf

host.elf: host.c ../../fw/fw/ahci_mpi_fw.h
	${CC} -o $@ ${CFLAGS} -Os -T./${LDSCRIPTS} -Xlinker -Map=host.map -I../../fw/fw $^
