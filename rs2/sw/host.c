#include <stdio.h>
#include <stdint.h>

static inline unsigned char readb(const volatile void *addr)
{
	return *(volatile unsigned char *)addr;
}

static inline void writeb(const volatile void *addr, unsigned char v)
{
	*(volatile unsigned char *)addr = v;
}

static inline uint32_t readl(const volatile void *addr)
{
	return *(volatile uint32_t *)addr;
}

static inline void writel(const volatile void *addr, uint32_t v)
{
	*(volatile uint32_t *)addr = v;
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
static char *sata_base = (char *)0x85f00000;
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

#include "ahci_mpi_fw.h"

static void memcpy_be32(uint8_t *dst, uint8_t *src, int sz)
{
	int i;
	for (i = 0; i < sz; i += 4) {
		dst[i+0] = src[i+3];
		dst[i+1] = src[i+2];
		dst[i+2] = src[i+1];
		dst[i+3] = src[i+0];
	}
}

int main(int argc, char *argv[])
{
	int i;
	uint32_t *outband_mem  = (uint32_t *)0x40020000; /* 2M offset */
	uint32_t *outband_cons = (uint32_t *)0x40300000; /* 3M offset */
	uint32_t *inband_mem   = (uint32_t *)0x40400000; /* 4M offset */
	uint32_t *inband_prod  = (uint32_t *)0x40500000; /* 5M offset */

	print ("1\r\n");

	/* Pull DBG_STOP */
	writel(sata_base+0x8, 6);

	/* copy fw to ibram */
	memcpy_be32(sata_base+0x4000, (uint8_t *)fw_mpi, fw_mpi_size);

	*inband_prod = 0;

	/* HOST => FW */
	writel(sata_base+0x10, (uint32_t)outband_mem);
	writel(sata_base+0x14, (uint32_t)outband_cons);
	writel(sata_base+0x18, 0);

	/* FW => HOST */
	writel(sata_base+0x20, (uint32_t)inband_mem);
	writel(sata_base+0x24, (uint32_t)inband_prod);
	writel(sata_base+0x28, 0);

	/* enable fw cpu */
	writel(sata_base+0x8, 3);

	/* halt here */
	for (i = 0; i < 0x1000000; i ++) {
		if ((*inband_prod) != 0) {
			print ("d\r\n");
			break;
		}
	}

	print ("2\r\n");
	while (1);
}
