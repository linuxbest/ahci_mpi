#ifndef _SATA_HW_H_
#define _SATA_HW_H_

#ifndef PORT_NR
#define PORT_NR 4
#endif

enum SataMPISignls {
	LINKUP_SIG = Q_USER_SIG, /* 4 */
	LINKDOWN_SIG,  /* 5 */
	StartComm_SIG, /* 6 */

	RX_REGFIS_SIG, /* 7 */
	RX_DATFIS_SIG, /* 8 */
	RX_GOOD_SIG,   /* 9 */
	RX_BAD_SIG,    /* a */

	TX_ROK_SIG,    /* b */
	TX_RERR_SIG,   /* c */
	TX_SYNC_SIG,   /* d */
	TX_SRCV_SIG,   /* e */

	DMA_DONE_SIG,  /* f */
	
	HCMD_SIG,      /* 10 */
	TICK_SIG,      /* 11 */
	MAX_SIG,       
};

extern struct QHsmSataTag *HSM_QHsmSata;

void QHsmSata_ctor(void);

/* Board Support Package */
#ifdef _SIM_
#include <stdio.h>
void BSP_display(const char *fmt, ...);
void BSP_exit(void);
#else
static void inline display(uint32_t line, char const *fmt, ...)
{
	volatile uint32_t *dbg = (volatile uint32_t *)0xa0000830;
	*dbg = line;
}
#define BSP_display(fmt, ...) display(__LINE__, fmt, ##__VA_ARGS__)
#endif

void tx_dma_start(uint8_t port, uint32_t addr, uint32_t opts);
void rx_dma_start(uint8_t port, uint32_t addr, uint32_t opts);

void cx_fifo_ack(uint8_t port, uint8_t ok);

void hw_oob (uint8_t port);
void hw_init(uint8_t port);

uint32_t *hw_get_buf(uint8_t port);
void hw_dispatch(uint8_t port, QEvent *e);

void hw_reg_begin (uint8_t port, uint8_t type);
void hw_reg_update(uint8_t port, uint8_t index, uint32_t reg);
void hw_reg_end   (uint8_t port);

void in_irq_ack(void);

enum {
	C_RFIS     = 0x34,
	C_SDB      = 0xA1,
	C_DmaAct   = 0x39,
	C_DmaSetup = 0x41,
	C_BIST     = 0x58,
	C_PioSetup = 0x5f,
	C_DFIS     = 0x46,
};

typedef struct SataEvent {
	QEvent e;
	uint8_t error;
	uint16_t fis;
	SataCmd *cmd;
} SataEvent;

#define iFIFO_STS_ROK  (0x1)
#define iFIFO_STS_RERR (0x2)
#define iFIFO_STS_SYNC (0x3)
#define iFIFO_STS_GOOD (0x4)
#define iFIFO_STS_BAD  (0x5)
#define iFIFO_STS_SRCV (0x6)

enum {
	DMA_RESET = (1<<31),
	DMA_REQ   = (1<<30),
	DMA_OK    = (1<<29),
	DMA_DAT   = (1<<28),
	DMA_WRITE = (1<<27),
	DMA_SYNC  = (1<<26),
	DMA_FLUSH = (1<<25),
	DMA_EOF   = (1<<24),
	DMA_SOF   = (1<<23),

	REQ_OOB   = (1<<28),
};

#endif
