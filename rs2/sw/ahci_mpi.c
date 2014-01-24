#include <stdio.h>

static inline unsigned char readb(const volatile void *addr)
{
	return *(volatile unsigned char *)addr;
}

static inline void writeb(const volatile void *addr, unsigned char v)
{
	*(volatile unsigned char *)addr = v;
}

#define ULITE_RX                0x00
#define ULITE_TX                0x04
#define ULITE_STATUS            0x08
#define ULITE_CONTROL           0x0c

#define ULITE_REGION            16

#define ULITE_STATUS_RXVALID    0x01
#define ULITE_STATUS_RXFULL     0x02
#define ULITE_STATUS_TXEMPTY    0x04
#define ULITE_STATUS_TXFULL     0x08
#define ULITE_STATUS_IE         0x10
#define ULITE_STATUS_OVERRUN    0x20
#define ULITE_STATUS_FRAME      0x40
#define ULITE_STATUS_PARITY     0x80

#define ULITE_CONTROL_RST_TX    0x01
#define ULITE_CONTROL_RST_RX    0x02
#define ULITE_CONTROL_IE        0x10

static char *uart_base = (char *)0x84000000;

void outbyte(char c)
{
	while ((readb(uart_base+ULITE_STATUS) & ULITE_STATUS_TXFULL) ==
			ULITE_STATUS_TXFULL);
	writeb(uart_base+ULITE_TX, c);
}

char inbyte(void)
{
	/* TODO */
	return 0;
}

const char fw_mpi[] __attribute__((section("ddr")));
#include "ahci_mpi_fw.h"

int main(int argc, char *argv[])
{
	print ("1\r\n");

	/* halt here */
	while (1) { };
}
