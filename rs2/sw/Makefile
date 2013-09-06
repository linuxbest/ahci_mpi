CC=mb-gcc

all: host.elf

host.elf: host.c 
	${CC} -o $@ -mxl-pattern-compare -mno-xl-soft-mul -mxl-barrel-shift -Os -T./bootloader_linker_script.ld -Xlinker -Map=host.map -I../../fw/fw $^
