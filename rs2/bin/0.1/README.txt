
1. Connect RedggedStone J9 to A SATA harddisk using Crosswire cable.
2. Connect RedggedStone USB RS232 to computer, using 115200n8.
3. Connect RedggedStone Jtag to computer.
4. using xmd 
 fpga -f rs2.bit
 connect mb mdm -debugdevice cpunr 1
 down /tmp/host.elf
 run
