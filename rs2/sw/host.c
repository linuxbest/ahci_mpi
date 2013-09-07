#include <stdio.h>
#include <stdint.h>

typedef uint32_t __le32;
#include "ahci.h"

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

void hexdump(void *data, unsigned size)
{
	while (size) {
		unsigned char *p;
		int w = 16, n = size < w? size: w, pad = w - n;
		printf("%p:  ", data);
		for (p = data; p < (unsigned char *)data + n;)
			printf("%02hx ", *p++);
		printf("%*.s  \"", pad*3, "");
		for (p = data; p < (unsigned char *)data + n;) {
			int c = *p++;
			printf("%c", c < ' ' || c > 127 ? '.' : c);
		}
		printf("\"\n");
		data += w;
		size -= n;
	}
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
	
volatile uint32_t *outband_mem  = (uint32_t *)0x20410000;
volatile uint32_t *outband_cons = (uint32_t *)0x20420000;
volatile uint32_t *inband_mem   = (uint32_t *)0x20430000;
volatile uint32_t *inband_prod  = (uint32_t *)0x20440000;
volatile void     *rx_fis_mem   = (void     *)0x20460000;

volatile void *cmd_slot_mem = (void *)0x20450000;
volatile void *tbl_mem      = (void *)0x20470000;
volatile void *tmem         = (void *)0x20480000;

uint32_t inband_cons = 0;
uint32_t outband_prod = 0;

static void mpi_trace(volatile uint32_t *mem)
{
	uint8_t port = mem[0] >> 16;
	uint16_t line= mem[1];

	if (mem[1] & 0x80000000) { /* fw_main.c */
		printf(" p#%02x fw_main.c line %d\r\n", port, line);
	} else {
		printf(" p#%02x sata_mpi.c line %d\r\n", port, line);
	}
}

static void (*done_cb)(int err);

static void mpi_regfis(volatile uint32_t *mem)
{
	uint8_t port = mem[0] >> 16;
	volatile uint32_t *fis = rx_fis_mem + 0x00;
	uint8_t reason = mem[1];

	printf(" p#%02x: rfis(%s) %08x %08x %08x %08x - %08x %08x %08x %08x\r\n",
			port,
			reason == 0x1 ? "error" : reason == 0x2 ?  "update sig" : "ok",
			fis[0], fis[1], fis[2], fis[3],
			fis[4], fis[5], fis[6], fis[7]);

	if (done_cb) {
		done_cb(reason == 0x1);
		done_cb = 0;
	}
}

static void mpi_piofis(volatile uint32_t *mem)
{
	uint8_t port = mem[0] >> 16;
	volatile uint32_t *fis = rx_fis_mem + 0x80;
	uint8_t reason = mem[1];

	printf(" p#%02x: pfis(%s) %08x %08x %08x %08x - %08x %08x %08x %08x\r\n",
			port,
			reason == 0x0 ? "ok" : "err",
			fis[0], fis[1], fis[2], fis[3],
			fis[4], fis[5], fis[6], fis[7]);

	if (done_cb) {
		done_cb(reason != 0x0);
		done_cb = 0;
	}
}

static void process_inband(void)
{
	while (inband_cons != *inband_prod) {
		volatile uint32_t *mem = inband_mem + inband_cons*8;
		uint8_t port, type, valid;
		printf("%02x: %08x %08x %08x %08x - %08x %08x %08x %08x\r\n", 
				inband_cons,
				mem[0], mem[1], mem[2], mem[3],
				mem[4], mem[5], mem[6], mem[7]);
		port = mem[0] >> 16;
		type = mem[0] >> 0x8;
		valid= mem[0];
		switch (type) {
		case 0x0: /* IDLE */
			break;
		case 0x1: /* LINK */
			printf(" p#%02x link %s(%d)\r\n", port, mem[1] ? "down" : "up", mem[1]);
			break;
		case 0x2: /* REJECT */
			printf(" REJECT(%d), PxCI(%08x), SLOT(%d)\r\n", mem[1], mem[2], mem[6]);
			break;
		case 0x3: /* RERR */
			printf(" RERR Detected\r\n");
			break;
		case 0x4: /* CRC ERROR */
			printf(" CRC ERROR Deteced\r\n");
			break;
		case 0x5: /* REG FIS */
			mpi_regfis(mem);
			break;
		case 0x6: /* SDB FIS */
			printf(" SDB FIS recv\r\n");
			break;
		case 0x7: /* PIO FIS */
			mpi_piofis(mem);
			break;
		case 0x8: /* UNKNOWN FIS */
			printf(" UNKNOWN FIS recv\r\n");
			break;
		case 0x9: /* PANIC */
			printf(" FW PANIC\r\n");
			break;
		case 0xa: /* TRACE */
			mpi_trace(mem);
		default:
			break;
		}
		ROLL(inband_cons, ROLL_LENGTH);
	}
	writel(sata_base+0x28, inband_cons);
}

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

static void ata_inquiry_done(int err)
{
	printf(" ata inquiry done(%d)\n", err);
	if (err == 0)
		hexdump(tmem, 512);
}

static void ata_inquiry(void)
{
	volatile uint32_t *req   = outband_mem + outband_prod*8;
	uint8_t *fis             = tbl_mem;
	struct ahci_cmd_hdr *cmd = cmd_slot_mem + 0;
	struct ahci_sg *sg       = tbl_mem + 0x80;

	memset(fis, 0, 20);
	fis[0] = 0x27;
	fis[1] = 1<<7;
	fis[2] = 0xEC;

	sg->addr         = tmem;
	sg->addr_hi      = 0;
	sg->reserved     = 0;
	sg->flags_size   = 511;

	cmd->opts        = (1<<16)|5;
	cmd->status      = 0;
	cmd->tbl_addr    = tbl_mem;
	cmd->tbl_addr_hi = 0;
	cmd->sg_cnt      = 0;
	cmd->sg_offset   = 0;
	cmd->reserved[0] = 0;
	cmd->reserved[1] = 0;

	done_cb = ata_inquiry_done;

	/* send to fw */
	req[0] = 0x0101; /* command */
	req[1] = 0x1;    /* slot 0 */
	req[2] = 0x0;    /* sact 0 */
	ROLL(outband_prod, ROLL_LENGTH);
	writel(sata_base+0x18, outband_prod);
}

static void ata_read_done(int err)
{
	printf(" ata read done(%d)\n", err);
	if (err == 0)
		hexdump(tmem, 512);
}

static void ata_read_ext(void)
{
	volatile uint32_t *req   = outband_mem + outband_prod*8;
	uint8_t *fis             = tbl_mem;
	struct ahci_cmd_hdr *cmd = cmd_slot_mem + 0;
	struct ahci_sg *sg       = tbl_mem + 0x80;

	uint32_t len = 512;
	uint32_t lba = 0x0;

	memset(fis, 0, 20);
	fis[0] = 0x27;
	fis[1] = 1<<7;
	fis[2] = 0x25;

	fis[4] = lba;
	fis[5] = lba>> 8;
	fis[6] = lba>>16;
	fis[7] = (lba>>24) | 0xE0;

	fis[12] = len>>(9+0);
	fis[13] = len>>(9+8);
	hexdump(fis, 20);

	sg->addr         = tmem;
	sg->addr_hi      = 0;
	sg->reserved     = 0;
	sg->flags_size   = len - 1;

	cmd->opts        = (1<<16)|5;
	cmd->status      = 0;
	cmd->tbl_addr    = tbl_mem;
	cmd->tbl_addr_hi = 0;
	cmd->sg_cnt      = 0;
	cmd->sg_offset   = 0;
	cmd->reserved[0] = 0;
	cmd->reserved[1] = 0;

	done_cb = ata_read_done;

	/* send to fw */
	req[0] = 0x0101; /* command */
	req[1] = 0x1;    /* slot 0 */
	req[2] = 0x0;    /* sact 0 */
	ROLL(outband_prod, ROLL_LENGTH);
	writel(sata_base+0x18, outband_prod);
}

static void ata_read_ncq(void)
{
	volatile uint32_t *req   = outband_mem + outband_prod*8;
	uint8_t *fis             = tbl_mem;
	struct ahci_cmd_hdr *cmd = cmd_slot_mem + 0;
	struct ahci_sg *sg       = tbl_mem + 0x80;

	uint32_t len = 512;
	uint32_t lba = 0x0;

	memset(fis, 0, 20);
	fis[0] = 0x27;
	fis[1] = 1<<7;
	fis[2] = 0x60;

	fis[4] = lba;
	fis[5] = lba>> 8;
	fis[6] = lba>>16;
	fis[7] = (lba>>24) | 0xE0;

	fis[12] = len>>(9+0);
	fis[13] = len>>(9+8);
	hexdump(fis, 20);

	sg->addr         = tmem;
	sg->addr_hi      = 0;
	sg->reserved     = 0;
	sg->flags_size   = len - 1;

	cmd->opts        = (1<<16)|5;
	cmd->status      = 0;
	cmd->tbl_addr    = tbl_mem;
	cmd->tbl_addr_hi = 0;
	cmd->sg_cnt      = 0;
	cmd->sg_offset   = 0;
	cmd->reserved[0] = 0;
	cmd->reserved[1] = 0;

	done_cb = ata_read_done;

	/* send to fw */
	req[0] = 0x0101; /* command */
	req[1] = 0x1;    /* slot 0 */
	req[2] = 0x1;    /* sact 0 */
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
#if 0
	while (inbyte() != 0x63) ;
#endif
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
			case 'I': printf("Command Init\n");
				  ahci_start();
				  break;
			case 'i': printf("Command Inquiry\n");
				  ata_inquiry();
				  break;
			case 'r': printf("Command Read EXT\n");
				  ata_read_ext();
				  break;
			case 'R': printf("Command Read NCQ\n");
				  ata_read_ncq();
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
