#include "qep_port.h"
#include "qassert.h"

#include "sata_mpi.h"
#include "sata_hw.h"

typedef uint32_t __le32;
#include "ahci.h"

volatile struct ctrl_register {
#define DMA0_IRQ 0x0001
#define DMA1_IRQ 0x0002
#define DMA2_IRQ 0x0004
#define DMA3_IRQ 0x0008
#define HOST_IRQ 0x8000
	uint32_t irq;		 /* 0x00 readonly */
	uint32_t irqen;		 /* 0x04 readonly */
	uint32_t enable;	 /* 0x08 readonly */
	uint32_t reserved;	 /* 0x0C readonly */
	/* inband   HOST => MB */
	uint32_t in_base_addr;	 /* 0x10 readonly */
	uint32_t in_cons_addr;	 /* 0x14 readonly */
	uint32_t in_prod_index;	 /* 0x18 readonly */
	uint32_t in_cons_index;	 /* 0x1c readwrite */
	/* outband  MB => HOST */
	uint32_t out_base_addr;	 /* 0x20 readonly */
	uint32_t out_prod_addr;	 /* 0x24 readonly */
	uint32_t out_cons_index; /* 0x28 readonly */
	uint32_t out_prod_index; /* 0x2c readwrite */
} * ctrl = (volatile struct ctrl_register *)0xa0000800;

/*..........................................................................*/
struct port_register {
	uint32_t irqstat;	/* 0x00 */
	uint32_t ctrl;		/* 0x04 */
	uint32_t bufaddr;	/* 0x08 */
	uint32_t reserved[5];	/* 0x0C-0x1C */
	uint32_t buf[8];	/* 0x20-0x3C */
};
enum {
	DmaDone_IRQ    = (1<<25),
	LinkChange_IRQ = (1<<26),
	PLLChange_IRQ  = (1<<27),
	RXFIFO_IRQ     = (1<<30),
	CXFIFO_IRQ     = (1<<31),

	LINKUP_STS     = (1<<28),
	PLLLOCK_STS    = (1<<29),

	CXFIFO_ACK     = (1<<31),
	CXFIFO_ROK     = (0<<30),
	CXFIFO_SYNC    = (1<<30),
	
};

enum {
	_tx_dma_start 	= 0,
	_rx_dma_start 	= 1,
	_cx_fifo_ack 	= 2,
	_hw_oob 	= 3,
};

#define RX_ERROR_CODE(irq) ((irq>>12) & 0xf)
#define RX_TYPE_FIS(irq)   (irq & 0xfff)
#define CX_ERROR_CODE(irq) ((irq>>12) & 0xf)

#define DATA_CACHE_ENABLE

void fw_irq_handler(uint8_t port)
{
	uint32_t base = 0xa0000000 + (port << 8);
	volatile struct port_register *io = (struct port_register *)base;
	uint32_t irqstat = io->irqstat;
	
	if (irqstat & LinkChange_IRQ) {
		static QEvent linkup = {.sig = LINKUP_SIG};
		static QEvent linkdown = {.sig = LINKDOWN_SIG};
		QEvent *e = (irqstat & LINKUP_STS) ? &linkup : &linkdown;
		/* disaptch signal */
		hw_dispatch(port, e);
		/* clear irq */
		io->irqstat =  LinkChange_IRQ;
	} else if (irqstat & DmaDone_IRQ) {
		static QEvent dmadone = {.sig = DMA_DONE_SIG};
		/* dispatch */
		hw_dispatch(port, &dmadone);
		/* clear */
		io->irqstat = DmaDone_IRQ;
	} else if (irqstat & RXFIFO_IRQ) {
		static SataEvent rxevent;
		rxevent.e.sig = RX_REGFIS_SIG;
		rxevent.error = RX_ERROR_CODE(irqstat);
		rxevent.fis = RX_TYPE_FIS(irqstat);
		if (rxevent.fis != 0x46) {
			uint32_t *buf = hw_get_buf(port);
			buf[0] = io->buf[0];
			buf[1] = io->buf[1];
			buf[2] = io->buf[2];
			buf[3] = io->buf[3];
			buf[4] = io->buf[4];
			buf[5] = io->buf[5];
		}
		/* dispatch */
		hw_dispatch(port, &rxevent.e);
		/* will clear by hsm */
	} else if (irqstat & CXFIFO_IRQ) {
		static QEvent cxevent;
		static uint8_t map[] = {
			/* unused */ 0x0, 
			/* ROK    */ TX_ROK_SIG,
			/* RERR   */ TX_RERR_SIG,
			/* SYNC   */ TX_SYNC_SIG,
			/* GOOD   */ RX_GOOD_SIG,
			/* BAD    */ RX_BAD_SIG,
			/* SRV    */ TX_SRCV_SIG,
		};
		cxevent.sig = map[CX_ERROR_CODE(irqstat)];
		/* dispatch */
		hw_dispatch(port, &cxevent);
		/* clear by hsm */
	}
}
/*..........................................................................*/
static uint32_t in_cons_index;
static SataCmd *in_head_cmd;
void in_irq_handler(void)
{
	static SataEvent inevent = {.e.sig = HCMD_SIG,};
	uint8_t port;	/* why uint8_t port not works? */
	uint32_t header;
	SataCmd *cmd = in_head_cmd + in_cons_index;
#ifdef DATA_CACHE_ENABLE
	__invalidate_dcache_wb(cmd, 0);
#endif
	inevent.cmd = cmd;
	header = cmd->header;
	port = (header >> 16);
	hw_dispatch(port, &inevent.e);
}
void in_irq_ack(void)
{
	uint32_t *cons_addr  = (uint32_t *)(ctrl->in_cons_addr + 0xC0000000);
	in_cons_index = (in_cons_index + 1) & 0xfff;
	*cons_addr = in_cons_index;
#ifdef DATA_CACHE_ENABLE 
	__flush_dcache(cons_addr);
#endif
	ctrl->in_cons_index = in_cons_index;
}
/*..........................................................................*/
void fw_tick_event(void)
{
	static QEvent tick_event = {
		.sig = TICK_SIG,
	};
	uint8_t i;
	for (i = 0; i < PORT_NR; i ++) 
		hw_dispatch(i, &tick_event);
}
/*..........................................................................*/
static uint32_t out_prod_index;
static SataCmd *out_head_cmd;
int main(int argc, char *argv[])
{
	int i;
	while (ctrl->enable == 0) ;

	/* reseting the ring */
	ctrl->out_prod_index = 0;
	ctrl->in_cons_index  = 0;
	out_prod_index       = 0;
	in_cons_index        = 0;

#ifdef DATA_CACHE_ENABLE
	__enable_dcache_msr();
#else
	__disable_dcache_msr();
#endif

	in_head_cmd  = (SataCmd *)(ctrl->in_base_addr + 0xC0000000);
	out_head_cmd = (SataCmd *)(ctrl->out_base_addr+ 0xC0000000);
 	
	QHsmSata_ctor();                             /* instantiate the HSM */

	for (i = 0; i < PORT_NR; i ++) 
		hw_dispatch(0, 0);

	for (;;) {
		if (ctrl->irq & DMA0_IRQ)
			fw_irq_handler(0);
#ifdef PORT_NR > 1
		if (ctrl->irq & DMA1_IRQ)
			fw_irq_handler(1);
#endif
#ifdef PORT_NR > 2
		if (ctrl->irq & DMA2_IRQ)
			fw_irq_handler(2);
#endif
#ifdef PORT_NR > 3
		if (ctrl->irq & DMA3_IRQ)
			fw_irq_handler(3);
#endif
		if (ctrl->irq & HOST_IRQ)
			in_irq_handler();
		if (ctrl->irq == 0)
			fw_tick_event();
	}

	return 0;
}
/*..........................................................................*/
#ifdef SPY
QSTimeCtr QS_onGetTime(void )
{
	return 0;
}
#endif
/*..........................................................................*/
void tx_dma_start(uint8_t port, uint32_t addr, uint32_t opt)
{
	uint32_t base = 0xa0000000 + (port << 8);
	volatile struct port_register *io = (struct port_register *)base;
	io->bufaddr = addr;
	io->ctrl = DMA_REQ|opt;
#ifdef MPI_TRACE
	hw_reg_begin (port, INTC_TRACE);
	hw_reg_update(port, C_DATA, __LINE__ | 1<<31 | (_tx_dma_start<<16));
	hw_reg_update(port, 1, addr);
	hw_reg_update(port, 2, opt);
	hw_reg_end   (port);
#endif
}
/*..........................................................................*/
void rx_dma_start(uint8_t port, uint32_t addr, uint32_t opt)
{
	uint32_t base = 0xa0000000 + (port << 8);
	volatile struct port_register *io = (struct port_register *)base;
	io->bufaddr = addr;
	io->ctrl = DMA_REQ|DMA_WRITE|opt;
#ifdef MPI_TRACE
	hw_reg_begin (port, INTC_TRACE);
	hw_reg_update(port, C_DATA, __LINE__ | 1<<31 | _rx_dma_start<<16);
	hw_reg_update(port, 1, addr);
	hw_reg_update(port, 2, opt);
	hw_reg_end   (port);
#endif
}
/*..........................................................................*/
void cx_fifo_ack(uint8_t port, uint8_t ok)
{
	uint32_t base = 0xa0000000 + (port << 8);
	volatile struct port_register *io = (struct port_register *)base;
	uint32_t ack = CXFIFO_ACK;
	if (ok)
		ack |= CXFIFO_ROK;
	else 
		ack |= CXFIFO_SYNC;
	io->irqstat = ack; 
#ifdef MPI_TRACE
	hw_reg_begin (port, INTC_TRACE);
	hw_reg_update(port, C_DATA, __LINE__ | 1<<31 | _cx_fifo_ack<<16);
	hw_reg_update(port, 1, ok);
	hw_reg_end   (port);
#endif
}
/*..........................................................................*/
void hw_oob(uint8_t port)
{
	uint32_t base = 0xa0000000 + (port << 8);
	volatile struct port_register *io = (struct port_register *)base;
	io->irqstat = REQ_OOB;
#ifdef MPI_TRACE
	hw_reg_begin (port, INTC_TRACE);
	hw_reg_update(port, C_DATA, __LINE__ | 1<<31 |_hw_oob<<16);
	hw_reg_end   (port);
#endif
}
/*..........................................................................*/
void hw_init(uint8_t port)
{
	uint32_t base = 0xa0000000 + (port << 8);
	volatile struct port_register *io = (volatile struct port_register *)base;
	io->irqstat     = 0;
	io->ctrl        = 0;
	io->bufaddr     = 0;
	io->reserved[0] = 0;
	io->reserved[1] = 0;
	/* taggle the reset */
	io->ctrl        = DMA_RESET;
	/* reset done */
	io->irqstat     = LinkChange_IRQ | PLLChange_IRQ;
	io->ctrl        = 0;
}
/*..........................................................................*/
static SataCmd *msg; 
static uint32_t header;
static uint32_t next_prod_index;
void hw_reg_begin(uint8_t port, uint8_t type)
{
	next_prod_index = (out_prod_index + 1) & 0xfff;
	while (next_prod_index == ctrl->out_cons_index)
		;
	msg = out_head_cmd + out_prod_index;
#ifdef DATA_CACHE_ENABLE
	msg->header = 0;
	msg->d[0] = 0;
	msg->d[1] = 0;
	msg->d[2] = 0;
	msg->d[3] = 0;
	msg->d[4] = 0;
	msg->d[5] = 0;
	msg->d[6] = 0;
#endif
	header = (0x1<<24) | (port<<16) | (type<<8);
}
/*..........................................................................*/
void hw_reg_update(uint8_t port, uint8_t type, uint32_t reg)
{
	msg->d[type] = reg;
	header |= (1<<type);
}
/*..........................................................................*/
void hw_reg_end(uint8_t port)
{
	uint32_t *prod_addr  = (uint32_t *)(ctrl->out_prod_addr + 0xC0000000);
	msg->header = header;
	/* cal next produce index */
	out_prod_index = next_prod_index;
	/* update the host memory  */
	*prod_addr = out_prod_index;
#ifdef DATA_CACHE_ENABLE
	/* flush the data */
	__flush_dcache(msg);
	__flush_dcache(prod_addr);
#endif
	/* update the prod index register */
	ctrl->out_prod_index = out_prod_index;
}
/*..........................................................................*/
void Q_onAssert(char const Q_ROM * const Q_ROM_VAR file, int line) 
{
	hw_reg_begin (0x8, INTC_PANIC);
	hw_reg_update(0x8, C_DATA, (uint32_t)file);
	hw_reg_update(0x8, C_PxCI, line);
	hw_reg_end   (0x8);
	
	do { } while (1);
}
void exit(int stat)
{
	do { } while (1);
}
