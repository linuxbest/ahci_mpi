#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <malloc.h>
#include <stdarg.h>

#include "dgio.h"

#include "qep_port.h"
#include "sata_mpi.h"
#include "sata_hw.h"

typedef uint32_t __le32;
#include "ahci.h"

#define fmTraceFuncEnter(I)						\
	fprintf(tfile, "%s %8s:%04d enter %s\n", systemc_time(), __FILE__,  __LINE__, __FUNCTION__); \
	fflush(tfile)
#define fmTraceFuncExit(R,I)  \
	fprintf(tfile, "%s %8s:%04d exit %s(%c)\n",systemc_time(), __FILE__, __LINE__, __FUNCTION__, R); \
	fflush(tfile);
#define fmTrace(U,V) \
	fprintf(tfile, "%s %8s:%04d %s %08x\n", systemc_time(), __FILE__, __LINE__, #V, (uint32_t)V); \
	fflush(tfile);

FILE *tfile;
FILE *sfile;

unsigned char *base0;
int mem_size = 32*1024*1024;

static void dispatch(QEvent *e);

static uint32_t rbase;

int osChip_init(uint32_t base)
{
	int i;
	uint32_t val, *p;

	rbase = base;
	base0 = (unsigned char*)memalign(mem_size, mem_size);
	tfile = fopen("ahci.log", "w+b");
	sfile = fopen("fsm.log", "w+b");
	
	osChipRegWrite(base+0x0, 0);
	osChipRegWrite(base+0x4, 0);
	osChipRegWrite(base+0x8, 0);
	osChipRegWrite(base+0xc, 0);

	for (i = 0; i < 40; i ++)
		osChipRegRead(base);
	
	QHsmSata_ctor();
	QHsm_init((QHsm *)HSM_QHsmSata, 0);
	
	SataEvent se;
	
	struct ahci_cmd_hdr *hdrs= (struct ahci_cmd_hdr *)(base0 + 0x40000);
	unsigned char *fis_buf   = (unsigned char *)(base0 + 0x60000);
	unsigned char *cmdtabl   = (unsigned char *)(base0 + 0x80000);
	struct ahci_sg *prd_sgs  = (struct ahci_sg *)cmdtabl + 0x80;
	
	hdrs[0].opts = AHCI_CMD_CLR_BUSY |(1<<16);
	hdrs[1].opts = AHCI_CMD_CLR_BUSY |(1<<16);
	hdrs[0].tbl_addr = (uint32_t)cmdtabl;
	hdrs[1].tbl_addr = (uint32_t)cmdtabl;
	
	prd_sgs[0].addr       = 0xc000;
	prd_sgs[0].flags_size = 0x2fff;

	SataCmd cmd;
	cmd.header = 0x3;
	cmd.d[0] = (uint32_t)(void *)hdrs;
	cmd.d[1] = (uint32_t)(void *)fis_buf;
	
	se.e.sig = HCMD_SIG;
	se.cmd   = &cmd;
	dispatch(&se.e);

	for (i = 0; i < 400; i ++)
		osChipRegRead(base);
	
	cmd.header = 0x1000;
	se.e.sig = HCMD_SIG;
	se.cmd   = &cmd;
	dispatch(&se.e);
	
	return 0;
}

#define IRQ_DMA        (1<<25)
#define IRQ_LINKUP_CG  (1<<26)
#define IRQ_PLLLOCK_CG (1<<27)
#define IRQ_LINKUP     (1<<28)
#define IRQ_PLLLOCK    (1<<29)
#define IRQ_RXFIFO     (1<<30)
#define IRQ_CXFIFO     (1<<31)

#define ROK_CXFIFO     (0<<30)
#define ERR_CXFIFO     (1<<30)

enum {
	IRQSTAT = 0x0,
	/* [11:0]  fis hdr,    RO
	 * [15:12] error code, RO
	 * [25]    dma_irq,    RO
	 * [26]    linkup_cg   RO
	 * [27]    plllock_cg  RO   
	 * [28]    linkup,     WRITE will doing StartComm
	 * [29]    plllock,    RO
	 * [30]    rxfifo_irq, WRITE cxfifo_ok
	 * [31]    cxfifo_irq, WRITE cxfifo_ack
	 */
	DMACTRL = 0x4,
	/* [31]    phyreset,   WR
	 * [30]    dma_req
	 * [29]    dma_ok
	 * [28]    dma_data
	 * [27]    dma_wrt
	 * [26]    dma_sync
	 * [25]    dma_flush
	 * [24]    dma_eof
	 * [19:16] dma_pm
	 * [15:0]  dma_length
	 */
	BUFADDR = 0x8,
};

enum {
	C_ROK  = 1,	
	C_RERR = 2,
	C_SYNC = 3,
	C_SRCV = 6,

	C_GOOD = 4,
	C_BAD  = 5,
};
enum {
	S_IDLE,
	S_RXDMA_DONE,
	S_TXDMA_DONE,
};
int osChip_interrupt(uint32_t base)
{	
	uint32_t irq, ack = 0;
	static int state = 0, i;
	uint32_t fis = 0;
	SataEvent se;
	
	fmTraceFuncEnter("ab");

	for (i = 0; i < 5; i ++)
		osChipRegRead(base);

	irq = osChipRegRead(base+IRQSTAT);
	if (irq & IRQ_LINKUP_CG) {
		ack |= IRQ_LINKUP_CG;
		fprintf(tfile,"%s link %s\n", systemc_time(),
			irq & IRQ_LINKUP ? "UP" : "DOWN");
		
		se.e.sig = irq & (1<<26) ? LINKUP_SIG : LINKDOWN_SIG;
		dispatch(&se.e);
	}
	if (irq & IRQ_PLLLOCK_CG) {
		ack |= IRQ_PLLLOCK_CG;
		fprintf(tfile, "%s link %s\n", systemc_time(),
			irq & IRQ_PLLLOCK ? "UP" : "DOWN");
	}
	if (irq & IRQ_DMA) {
		se.e.sig = DMA_DONE_SIG;
		dispatch(&se.e);
		fprintf(tfile, "%s dma done\n", systemc_time());
		ack |= IRQ_DMA;
	} else if (irq & IRQ_RXFIFO) {
		se.error     = irq >> 12;
		se.fis       = irq & 0xff;
		if (se.fis != 0x46) {
			uint32_t *buf = hw_get_buf(0);
			buf[0] = osChipRegRead(base+0x20);
			buf[1] = osChipRegRead(base+0x24);
			buf[2] = osChipRegRead(base+0x28);
			buf[3] = osChipRegRead(base+0x2C);
			buf[4] = osChipRegRead(base+0x30);
			buf[5] = osChipRegRead(base+0x34);
#if 0
			int i;
			for (i = 0; i < 7; i ++) 
				fprintf(tfile, "[%d] %08x\n", i, buf[i]);
#endif
		}
		fprintf(tfile, "%s rxfifo error %x, fis %x\n", systemc_time(),
			se.error, se.fis);
		se.e.sig = RX_REGFIS_SIG;
		dispatch(&se.e);
	} else if (irq & IRQ_CXFIFO) {
		se.error = irq >> 12;
		switch (se.error) {
		case iFIFO_STS_GOOD:
			se.e.sig = RX_GOOD_SIG;
			break;
		case iFIFO_STS_BAD:
			se.e.sig = RX_BAD_SIG;
			break;
		case iFIFO_STS_ROK:
			se.e.sig = TX_ROK_SIG;
			break;
		case iFIFO_STS_RERR:
			se.e.sig = TX_RERR_SIG;
			break;
		case iFIFO_STS_SYNC:
			se.e.sig = TX_SYNC_SIG;
			break;
		case iFIFO_STS_SRCV:
			se.e.sig = TX_SRCV_SIG;
			break;
		}
		fprintf(tfile, "%s cxfifo %x\n", systemc_time(), se.error);
		dispatch(&se.e);
	}
	osChipRegWrite(base+IRQSTAT, ack);
	fmTraceFuncExit('a', "aa");
}

/* SATA HW interface & API */
/*..........................................................................*/
void Q_onAssert(char const Q_ROM * const Q_ROM_VAR file, int line) {
	fprintf(sfile, "Assertion failed in %s, line %d", file, line);
}
/*..........................................................................*/
void BSP_display(const char *fmt, ...) 
{
	va_list args;
	char msg[1024];
	
	va_start(args, fmt);
	sprintf(msg, fmt, args);
	va_end(args);

	fprintf(sfile, msg);
	fflush(sfile);
}

static uint32_t addr1;

void tx_dma_start(uint8_t port, uint32_t addr, uint32_t opt)
{
	uint32_t val = (0<<27)|(1<<30)|opt;
	osChipRegWrite(rbase + BUFADDR, addr);
	osChipRegWrite(rbase + DMACTRL, val);
	fprintf(sfile, "txdma;");
}

void rx_dma_start(uint8_t port, uint32_t addr, uint32_t opt)
{
	uint32_t val = (1<<27)|(1<<30)|opt;
	osChipRegWrite(rbase + BUFADDR, addr);
	osChipRegWrite(rbase + DMACTRL, val);
	fprintf(sfile, "rxdma;");
	addr1 = addr;
}

void cx_fifo_ack(uint8_t port, uint8_t ok)
{
	uint32_t val = (1<<31);
	if (ok == 0)
		val |= (1<<30);
	osChipRegWrite(rbase + IRQSTAT, val);
	fprintf(sfile, "cx{%d};", ok);

#if 1
	tx_dma_start(0, addr1, 256
			|DMA_SOF
			|DMA_EOF
			|DMA_DAT
			);
#endif
}

void hw_oob(uint8_t port)
{
	osChipRegWrite(rbase + IRQSTAT, REQ_OOB);
	fprintf(sfile, "oob;");
}

void hw_init(uint8_t port)
{
	int i;
	osChipRegWrite(rbase + DMACTRL, (1<<31));
	for (i = 0; i < 3; i ++)
		osChipRegRead(rbase);
	osChipRegWrite(rbase + DMACTRL, 0);
	fprintf(sfile, "init;");
}

void hw_reg_begin(uint8_t port, uint8_t type)
{
	fprintf(sfile, "reg_start{%d[", type);
}

void hw_reg_update(uint8_t port, uint8_t type, uint32_t reg)
{
	fprintf(sfile, ",%d:%x", type, reg);
}

void hw_reg_end(uint8_t port)
{
	fprintf(sfile, "]};");
}

void in_irq_ack()
{
}
/*..........................................................................*/
static char *str[] = {
	[LINKUP_SIG]    = "linkup   ",
	[LINKDOWN_SIG]  = "linkdown ",

	[RX_REGFIS_SIG] = "R regfis ",
	[RX_DATFIS_SIG] = "R datfis ",
	[RX_GOOD_SIG]   = "R good   ",
	[RX_BAD_SIG]    = "R bad    ",

	[TX_ROK_SIG]    = "T ok     ",
	[TX_RERR_SIG]   = "T err    ",
	[TX_SYNC_SIG]   = "T sync   ",
	[TX_SRCV_SIG]   = "T srcv   ",

	[DMA_DONE_SIG]  = "DMA Done ",
	
	[HCMD_SIG]      = "hostcmd  ",
	[StartComm_SIG] = "StartComm",
	[TICK_SIG]      = "tick     ",
};
static void dispatch(QEvent *e) {
	fprintf(sfile, "\n  %s:", str[e->sig]);
	QHsm_dispatch((QHsm *)HSM_QHsmSata, e);    /* dispatch the event */
	fflush(sfile);
}
