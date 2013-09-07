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
	while (readl(uart_base+ULITE_STATUS) & ULITE_STATUS_TXFULL)
		;
	writel(uart_base+ULITE_TX, c);
}

char inbyte(void)
{
	while (!(readl(uart_base+ULITE_STATUS) & ULITE_STATUS_RXVALID))
		;
	return readl(uart_base+ULITE_RX) & 0xff;
}

int serial_tstc(void)
{
	return readl(uart_base+ULITE_STATUS) & ULITE_STATUS_RXVALID;
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

#define ROLL_LENGTH      (1<<12)
#define ROLL(index, end) ((index)=(((index)+1) & ((end)-1)))
	
volatile uint32_t *outband_mem  = (uint32_t *)0x20410000; /* 2M offset */
volatile uint32_t *outband_cons = (uint32_t *)0x20420000; /* 3M offset */
volatile uint32_t *inband_mem   = (uint32_t *)0x20430000; /* 4M offset */
volatile uint32_t *inband_prod  = (uint32_t *)0x20440000; /* 5M offset */

uint32_t inband_cons = 0;
uint32_t outband_prod = 0;

static void process_inband(void)
{
	while (inband_cons != *inband_prod) {
		volatile uint32_t *mem = inband_mem + inband_cons*8;
		printf("%02x: %08x %08x %08x %08x - %08x %08x %08x %08x\r\n", 
				inband_cons,
				mem[0], mem[1], mem[2], mem[3],
				mem[4], mem[5], mem[6], mem[7]);
		ROLL(inband_cons, ROLL_LENGTH);
	}
	writel(sata_base+0x28, inband_cons);
}

volatile uint32_t *cmd_slot_mem = (uint32_t *)0x20450000; /* 6M offset */
volatile uint32_t *rx_fis_mem   = (uint32_t *)0x20460000; /* 7M offset */

static void ahci_start(void)
{
	volatile uint32_t *mem;

	mem = outband_mem + outband_prod*8;
	mem[0] = 0x200;
	ROLL(outband_prod, ROLL_LENGTH);
	writel(sata_base+0x18, outband_prod);

	/* fis & cmd slot */
	mem = outband_mem + outband_prod*8;
	mem[0] = 0x3;
	mem[1] = (uint32_t)cmd_slot_mem;
	mem[2] = (uint32_t)rx_fis_mem;
	ROLL(outband_prod, ROLL_LENGTH);
	writel(sata_base+0x18, outband_prod);

	/* power up the link */
	mem = outband_mem + outband_prod*8;
	mem[0] = 0x10<<8;
	ROLL(outband_prod, ROLL_LENGTH);
	writel(sata_base+0x18, outband_prod);
}

int main(int argc, char *argv[])
{
	int i, rdy = 0, run = 1;
	print("fw init\r\n");

	/* Pull DBG_STOP */
	writel(sata_base+0x8, 6);

	/* copy fw to ibram */
	memcpy_be32(sata_base+0x4000, (uint8_t *)fw_mpi, fw_mpi_size);

	*inband_prod = 0;
	*outband_cons = 0;

	/* HOST => FW */
	writel(sata_base+0x10, (uint32_t)outband_mem);
	writel(sata_base+0x14, (uint32_t)outband_cons);
	writel(sata_base+0x18, 0);

	/* FW => HOST */
	writel(sata_base+0x20, (uint32_t)inband_mem);
	writel(sata_base+0x24, (uint32_t)inband_prod);
	writel(sata_base+0x28, 0);

	print("enable fw cpu\r\n");

	while (inbyte() != 0x63) ;

	/* enable fw cpu */
	writel(sata_base+0x8, 3);

	/* halt here */
	for (i = 0; i < 0x10000; i++) {
		if ((*inband_prod) != 0) {
			printf("cons: %08x\n", *inband_prod);
			rdy = 1;
			break;
		}
	}

	writel(sata_base+0x8, 0);

	while (run) {
		process_inband();

		if (serial_tstc()) {
			char c = inbyte();
			switch (c) {
			case 'I': printf("Init\n");
				  ahci_start();
				  break;
			case 'd': printf(" out prod: %04x, %04x\n", outband_prod, *outband_cons);
				  printf(" in  prod: %04x, %04x\n", *inband_prod, inband_cons);
				  break;
			case 'q':
				  run = 0;
				  break;
			default:
				  printf("ignore command %c\n", c);
			}
		}
	}
}
