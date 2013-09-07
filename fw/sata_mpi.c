#include "qep_port.h"
#include "sata_mpi.h"
#include "sata_hw.h"

typedef uint32_t __le32;
#include "ahci.h"

#define DMA_TICK_CNT 0x8000

/* QHsmSata class ----------------------------------------------------------*/
typedef struct QHsmSataTag {
	QHsm super;

	uint8_t  pUpdateSig;
	uint8_t  pDevIssue;
	uint16_t pBsy;
	uint16_t pDrq;
	uint8_t  pPmpCur;
	uint8_t  pIssueSlot[16];
	uint8_t  pDataSlot[16];
	uint8_t  pPMP;
	uint8_t  pXferAtapi[16];
	uint8_t  pPioXfer[16];
	uint8_t  pPioEsts[16];
	uint8_t  pPioErr[16];
	uint8_t  pPiolbit[16];
	uint32_t pDmaXferCnt;
	uint8_t  pCmdToIssue;
	uint8_t  pPrdIntr[16];
	uint32_t pSActive;
	uint8_t  pSlotLoc;
	uint32_t fb_ci, ci;
	uint16_t len, left;
	uint8_t  port;
	uint8_t  fbs;
	
	uint32_t PxCI;
	uint32_t PxSACT;
	uint32_t PxSIG;
	uint32_t PxSSTS;
	uint32_t PxTFD;
	uint32_t PxSCTL;
	uint32_t PxSERR;
	uint32_t pDmaTickCnt;

	struct ahci_cmd_hdr *host_hdr;     /* point to hostmemory */
	struct ahci_cmd_hdr hdr[32]; /* local memory */
	uint32_t *rx;
	uint32_t fis_buf[8];
	uint32_t rx_fis;
} QHsmSata;

void QHsmSata_ctor(void);

QState QHsmSata_initial(QHsmSata *me, QEvent const *e);
QState QHsmSata_top(QHsmSata *me, QEvent const *e);
QState QHsmSata_linkdown(QHsmSata *me, QEvent const *e);

QState Ht_HostIdle(QHsmSata *me, QEvent const *e);

QState Ht_CmdFis(QHsmSata *me, QEvent const *e);
QState Ht_CmdTransStatus(QHsmSata *me, QEvent const *e);

QState Ht_ChkTyp(QHsmSata *me, QEvent const *e);
QState Ht_RegFis(QHsmSata *me, QEvent const *e);
QState Ht_DbFis(QHsmSata *me, QEvent const *e);
QState Ht_DmaFis(QHsmSata *me, QEvent const *e);
QState Ht_PsFis(QHsmSata *me, QEvent const *e);
QState Ht_DsFis(QHsmSata *me, QEvent const *e);
QState Ht_ufis(QHsmSata *me, QEvent const *e);

QState Ht_DmaITrans(QHsmSata *me, QEvent const *e);
QState Ht_DmaOTrans(QHsmSata *me, QEvent const *e);

QState ERR_FatalTaskFile(QHsmSata *me, QEvent const *e);
QState ERR_NotFatal(QHsmSata *me, QEvent const *e);
QState ERR_Fatal(QHsmSata *me, QEvent const *e);

/* global objects ----------------------------------------------------------*/
static QHsmSata _HSM_QHsmSata[PORT_NR];
QHsmSata *HSM_QHsmSata = _HSM_QHsmSata;

uint32_t prd_get_al(struct ahci_cmd_hdr *hdr, uint32_t *addr, uint32_t mlen, uint8_t *eof);
QState pio_update(QHsmSata *me, uint8_t pPmpCur);

static int test_bit(uint32_t val, uint8_t bit)
{
	return (val & (1<<bit)) != 0;
}

static int pBsy_pDrq_get(QHsmSata *me, uint8_t slot)
{
	uint32_t bit = 1<<slot;
	return (me->pBsy & bit) | (me->pDrq & bit);
}

static int pBsy_get(QHsmSata *me, uint8_t slot)
{
	return me->pBsy & (1<<slot);
}
static void pBsy_set(QHsmSata *me, uint8_t slot, int bit)
{
	if (bit)
		me->pBsy |= (1<<slot);
	else
		me->pBsy &= ~(1<<slot);
}
static int pDrq_get(QHsmSata *me, uint8_t slot)
{
	return me->pDrq & (1<<slot);
}
static void pDrq_set(QHsmSata *me, uint8_t slot, int bit)
{
	if (bit)
		me->pDrq |= (1<<slot);
	else
		me->pDrq &= ~(1<<slot);
}
/*..........................................................................*/
void QHsmSata_init(QHsmSata *me)
{
	me->PxSIG       = ~0;
	me->PxSSTS      = 0;
	
	me->pUpdateSig  = 1;
	me->pDevIssue   = 0;
	me->pPmpCur     = 0;
	me->pPMP        = 0;
	me->pCmdToIssue = 0;
	me->pSActive    = 0;
	me->pSlotLoc    = 0;
	me->pDmaXferCnt = 0;
	
	me->PxCI   = 0;
	me->PxSACT = 0;

	int i;
	for (i = 0; i < 16; i ++) {
		me->pBsy = 0;
		me->pDrq = 0;
		me->pIssueSlot[i] = 32;
		me->pDataSlot[i] = 0;
		me->pPioXfer[i] = 0;
		me->pPrdIntr[i] = 0;
		me->pPioEsts[i] = 0;
		me->pPioErr[i]  = 0;
		me->pPiolbit[i] = 0;
		me->pXferAtapi[i] = 0;
	}
	pBsy_set(me, 0, 0);
	pBsy_set(me, 0, 1);
	me->PxTFD = 0x7F;
	me->pUpdateSig = 1;

	hw_init(me->port);
}
/*..........................................................................*/
void QHsmSata_ctor(void) 
{
	int i;
	for (i = 0; i < PORT_NR; i ++) {
		HSM_QHsmSata[i].port = i;
		QHsmSata_init(&HSM_QHsmSata[i]);
		QHsm_ctor(&HSM_QHsmSata[i].super, (QStateHandler)&QHsmSata_initial);
	}
}
/*..........................................................................*/
QState QHsmSata_initial(QHsmSata *me, QEvent const *e)
{
	BSP_display("top-INIT;");
	return Q_TRAN(&QHsmSata_top);
}
/*..........................................................................*/
void top_init(QHsmSata *me)
{
	int i;
	for (i = 0; i < 16; i ++) {
		me->pIssueSlot[i] = 32;
		if (i) { /* 1 to 15 */
			pBsy_set(me, i, 0);
			pDrq_set(me, i, 0);
		}
	}
	me->pSlotLoc = 31;

	hw_reg_begin (me->port, INTC_IDLE);
	hw_reg_update(me->port, 0, GITVERSION);
	/* version 01.00.00.00 */
	hw_reg_update(me->port, 1, 0x01000000);
	hw_reg_end   (me->port);
}
/*..........................................................................*/
QState QHsmSata_top(QHsmSata *me, QEvent const *e)
{
	switch (e->sig) {
	case Q_ENTRY_SIG: 
		BSP_display("top-ENTRY;");
		return Q_HANDLED();
	case Q_EXIT_SIG:
		BSP_display("top-EXIT;");
		return Q_HANDLED();
	case Q_INIT_SIG:
		BSP_display("top-INIT;");
		top_init(me);
		return Q_TRAN(&QHsmSata_linkdown);
	case LINKUP_SIG:
		BSP_display("top-UP;");
		me->PxSSTS = 0x123;
		hw_reg_begin (me->port, INTC_LINK);
		hw_reg_update(me->port, C_DATA, 0x0);
		hw_reg_update(me->port, C_PxSSTS, me->PxSSTS);
		hw_reg_end   (me->port);
		return Q_TRAN(&Ht_HostIdle);
	case HCMD_SIG: {
		SataEvent *se = (SataEvent *)e;
		if ((se->cmd->header & 0xffff) == 0x0003) {
			/* cmd is x00, valid bit is 2'b11 */
			BSP_display("top-CMD(ADDR);");
			me->host_hdr = (struct ahci_cmd_hdr *)(se->cmd->d[0] + 0xC0000000);
			me->rx_fis = se->cmd->d[1];
			in_irq_ack();
#ifdef MPI_TRACE
			hw_reg_begin (me->port, INTC_TRACE);
			hw_reg_update(me->port, C_DATA, __LINE__ | _QHsmSata_top<<16);
			hw_reg_update(me->port, 1, me->host_hdr);
			hw_reg_update(me->port, 2, me->rx_fis);
			hw_reg_end   (me->port);
#endif
		} else if ((se->cmd->header & 0xffff) == 0x1000) { /* StartComm */
			/* cmd is x10, valid bit is 2'b00 */
			BSP_display("top-StartComm;");
			me->PxTFD = 0x7F;
			me->pUpdateSig = 1;
			pBsy_set(me, 0, 0);
			pDrq_set(me, 0, 1);
			hw_oob(me->port);
			in_irq_ack();
#ifdef MPI_TRACE
			hw_reg_begin (me->port, INTC_TRACE);
			hw_reg_update(me->port, C_DATA, __LINE__ | _QHsmSata_top<<16);
			hw_reg_end   (me->port);
#endif
			return Q_HANDLED();
		} else if ((se->cmd->header & 0xffff) == 0x0200) { /* start engine */
			in_irq_ack();
#ifdef MPI_TRACE
			hw_reg_begin (me->port, INTC_TRACE);
			hw_reg_update(me->port, C_DATA, __LINE__ | _QHsmSata_top<<16);
			hw_reg_end   (me->port);
#endif
			return Q_HANDLED();
		} else {
			BSP_display("top-CMD(ERROR);");
			hw_reg_begin (me->port, INTC_REJECT);
			hw_reg_update(me->port, C_DATA, 0x0);
			hw_reg_update(me->port, C_PxCI, se->cmd->header);
			hw_reg_end (me->port);
			in_irq_ack();
		}
		return Q_HANDLED();
	}
	case RX_REGFIS_SIG:
		BSP_display("top-RFIS(SYNC);");
		rx_dma_start(me->port, 0x0, 1<<25);
		cx_fifo_ack(me->port, 0);
		hw_reg_begin (me->port, INTC_REGFIS);
		hw_reg_update(me->port, C_DATA, 3);
		hw_reg_end   (me->port);
		return Q_HANDLED();
		
	case RX_DATFIS_SIG:
	case RX_GOOD_SIG:
	case RX_BAD_SIG:
	case TX_ROK_SIG:
	case TX_RERR_SIG:
	case TX_SYNC_SIG:
	case TX_SRCV_SIG:
		BSP_display("TOP-%d(ERROR);", e->sig);
		
		hw_reg_begin (me->port, INTC_PANIC);
		hw_reg_update(me->port, C_DATA, 0x1);
		hw_reg_update(me->port, C_PxCI, e->sig);
		hw_reg_end   (me->port);

		return Q_HANDLED();
	}
	return Q_SUPER(&QHsm_top);
}
/*..........................................................................*/
QState QHsmSata_linkdown(QHsmSata *me, QEvent const *e)
{
	switch (e->sig) {
	case Q_ENTRY_SIG: 
		hw_reg_begin (me->port, INTC_LINK);
		hw_reg_update(me->port, C_DATA, 0x1);
		hw_reg_end   (me->port);
		BSP_display("down-ENTRY;");
		return Q_HANDLED();
	case Q_EXIT_SIG:
		BSP_display("down-EXIT;");
		return Q_HANDLED();
	}
	return Q_SUPER(&QHsmSata_top);
}
/*..........................................................................*/
QState do_port_idle(QHsmSata *me)
{
	if (me->PxCI && me->pIssueSlot[0] == 32 && me->pDmaXferCnt == 0) {
		/* Port SelectCmd */
		me->pDevIssue = 0;
		for (;;) {
			me->pSlotLoc = (me->pSlotLoc + 1) & 0x1f;
			if (me->PxCI & (1<<me->pSlotLoc))
				break;
		}
		uint8_t slot = me->pSlotLoc;
		struct ahci_cmd_hdr *src_hdr = &me->host_hdr[slot];
		struct ahci_cmd_hdr *hdr = &me->hdr[slot];
#ifndef _SIM_
		__invalidate_dcache_wb(src_hdr, 0);
#endif
		hdr->opts      = src_hdr->opts;
		hdr->tbl_addr  = src_hdr->tbl_addr;
#ifdef MPI_TRACE
		hw_reg_begin (me->port, INTC_TRACE);
		hw_reg_update(me->port, C_DATA, __LINE__ | _do_port_idle<<16);
		hw_reg_update(me->port, 1, slot);
		hw_reg_update(me->port, 2, hdr->opts);
		hw_reg_update(me->port, 3, hdr->tbl_addr);
		hw_reg_update(me->port, 4, me->PxCI);
		hw_reg_update(me->port, 5, src_hdr);
		hw_reg_end   (me->port);
#endif
		uint32_t tbl_addr = hdr->tbl_addr + 0x80 + 0xC0000000;
		uint32_t sg_cnt = hdr->opts >> 16;
		uint32_t i;
#ifndef _SIM_
		for (i = 0; i < sg_cnt; i++, tbl_addr += 32)
			__invalidate_dcache_wb(tbl_addr, 0);
#endif
		hdr->sg_cnt    = 0;
		hdr->sg_offset = 0;
		/* Port FetchCmd */
		me->pIssueSlot[0] = me->pSlotLoc;
		me->pCmdToIssue = 1;
		return Q_TRAN(&Ht_CmdFis);
	}
	if (me->pCmdToIssue && me->pDmaXferCnt == 0) {
		BSP_display("port_idle{%x};", me->pIssueSlot[0]);
		return Q_TRAN(&Ht_CmdFis);
	}
	BSP_display("port_idle{%x,%x,%x};",
	       me->PxCI, me->pIssueSlot[0], me->pDmaXferCnt);
	return Q_HANDLED();
}
/*..........................................................................*/
QState do_fbs_idle(QHsmSata *me)
{
	/* TODO */
	return Q_HANDLED();
}
/*..........................................................................*/
QState Ht_HostIdle(QHsmSata *me, QEvent const *e)
{
	switch (e->sig) {
	case Q_ENTRY_SIG: 
		BSP_display("idle-ENTRY;");
		return Q_HANDLED();
	case Q_EXIT_SIG:
		BSP_display("idle-EXIT;");
		return Q_HANDLED();
	case HCMD_SIG: {
		SataEvent *se = (SataEvent *)e;
		if ((se->cmd->header & 0xff00) == 0x0100) {
			me->PxCI   |= se->cmd->d[0];
			me->PxSACT |= se->cmd->d[1];
			BSP_display("idle-HCMD;");
#ifdef MPI_TRACE
			hw_reg_begin (me->port, INTC_TRACE);
			hw_reg_update(me->port, C_DATA, __LINE__);
			hw_reg_update(me->port, 1, me->PxSACT);
			hw_reg_update(me->port, 2, me->PxCI);
			hw_reg_update(me->port, 3, me->pIssueSlot[0]);
			hw_reg_update(me->port, 4, me->pDmaXferCnt);
			hw_reg_update(me->port, 5, me->pCmdToIssue);
			hw_reg_end   (me->port);
#endif
			in_irq_ack();
			return Q_HANDLED();
		} else {
			return Q_SUPER(&QHsmSata_top);
		}
	}
	case RX_REGFIS_SIG:
		BSP_display("idle-rreg;");
		return Ht_ChkTyp(me, e);
	case RX_DATFIS_SIG:
		BSP_display("idle-data;");
		return Ht_ChkTyp(me, e);
	case TICK_SIG:
		BSP_display("idle-TICK;");
		if (me->fbs)
			return do_fbs_idle(me);
		else 
			return do_port_idle(me);
	}
	return Q_SUPER(&QHsmSata_top);
}
/*..........................................................................*/
void do_cfis_xmit(QHsmSata *me)
{
	uint8_t slot = me->pIssueSlot[me->pDevIssue];
	struct ahci_cmd_hdr *hdr = &me->hdr[slot];
	uint32_t opts;

#ifdef MPI_TRACE
	hw_reg_begin (me->port, INTC_TRACE);
	hw_reg_update(me->port, C_DATA, __LINE__ | _do_cfis_xmit<<16);
	hw_reg_update(me->port, 1, slot);
	hw_reg_update(me->port, 2, me->pDevIssue);
	hw_reg_end   (me->port);
#endif

	opts = (hdr->opts & 0x1f)<<2; /* len */
	if (hdr->opts & (AHCI_CMD_RESET)) {
		me->pUpdateSig = 1;
		opts |= DMA_SYNC;/* SYNC */
	}
	opts |= (DMA_SOF|DMA_EOF);	 /* SOF|EOF */
	
	me->PxTFD                    |= (1<<7);
	pBsy_set(me, me->pDevIssue, 1);
	me->pDataSlot[me->pDevIssue]  = slot;
	me->pPMP                      = (hdr->opts >> 12) & 0xf;
	me->pXferAtapi[me->pDevIssue] = (hdr->opts & AHCI_CMD_ATAPI) != 0;
	me->pDmaXferCnt               = 0;
	
	tx_dma_start(me->port,
		     hdr->tbl_addr,  /* address */
		     opts);	     /* length */
}
/*..........................................................................*/
void do_cfis_done(QHsmSata *me)
{
	uint8_t slot = me->pIssueSlot[me->pDevIssue];
	struct ahci_cmd_hdr *hdr = &me->hdr[slot];
	me->pCmdToIssue = 0;
	if (hdr->opts & AHCI_CMD_CLR_BUSY) {
		me->PxTFD &= ~(1<<7); /* BSY */
		pBsy_set(me, me->pDevIssue, 0);
		me->PxCI &= ~(1<<slot);
		me->pIssueSlot[me->pDevIssue] = 32;
	}
#ifdef MPI_TRACE
	hw_reg_begin (me->port, INTC_TRACE);
	hw_reg_update(me->port, C_DATA, __LINE__ | _do_cfis_done<<16);
	hw_reg_update(me->port, 1, hdr->opts & AHCI_CMD_CLR_BUSY);
	hw_reg_update(me->port, 2, slot);
	hw_reg_end   (me->port);
#endif
}
static QState Ht_Start(QHsmSata *me, SataEvent *se)
{
	if ((se->cmd->header & 0xff00) == 0x0200) {
		int i;
		me->PxCI = 0;
		me->PxSACT = 0;
		me->pCmdToIssue = 0;
		me->PxTFD = 0;
		me->pDmaXferCnt = 0;
		for (i = 0; i < 16; i ++) {
			me->pIssueSlot[i] = 32;
			pBsy_set(me, i, 0);
			pDrq_set(me, i, 0);
		}
		in_irq_ack();
		return Q_TRAN(&Ht_HostIdle);
	}
	return Q_HANDLED();
}
/*..........................................................................*/
QState Ht_CmdFis(QHsmSata *me, QEvent const *e)
{
	switch (e->sig) {
	case Q_ENTRY_SIG: 
		BSP_display("CmdFis-ENTRY;");
		do_cfis_xmit(me);
		return Q_HANDLED();
	case Q_EXIT_SIG:
		BSP_display("CmdFis-EXIT;");
		return Q_HANDLED();
	case TX_ROK_SIG:
		BSP_display("CmdFis-ROK;");
		do_cfis_done(me);
		cx_fifo_ack(me->port, 1);
		return Q_TRAN(&Ht_HostIdle);
	case TX_RERR_SIG:
		BSP_display("CmdFis-RERR;");
		cx_fifo_ack(me->port, 1);
		return Q_TRAN(&Ht_HostIdle);
	case TX_SYNC_SIG:
		BSP_display("CmdFis-SYNC;");
		cx_fifo_ack(me->port, 1);
		return Q_TRAN(&Ht_HostIdle);
	case TX_SRCV_SIG:
		BSP_display("CmdFis-SRCV;");
		cx_fifo_ack(me->port, 1);
		return Q_TRAN(&Ht_HostIdle);
	case RX_REGFIS_SIG:
	case RX_DATFIS_SIG:
	case RX_GOOD_SIG:
	case RX_BAD_SIG:
		BSP_display("CmdFis-RX;");
		return Q_TRAN(&Ht_HostIdle);
	case HCMD_SIG:
		BSP_display("CmdFis-NotHandle;");
		SataEvent *se = (SataEvent *)e;
		return Ht_Start(me, se);
	}
	return Q_SUPER(&QHsm_top);
}
/*..........................................................................*/
QState Ht_ChkTyp(QHsmSata *me, QEvent const *e)
{
	SataEvent *se = (SataEvent *)e;
	uint8_t type = se->fis & 0xff;
	if (type != C_DFIS && se->error != iFIFO_STS_GOOD) {
		/* flush the rx fifo */
		rx_dma_start(me->port, 0x0, 1<<25);
		cx_fifo_ack(me->port, 0);

		hw_reg_begin (me->port, INTC_CRCERR);
		hw_reg_update(me->port, C_DATA, 0);
		hw_reg_end   (me->port);

		return Q_TRAN(&Ht_HostIdle);
	}
	me->pPmpCur = me->fbs ? se->fis >> 8 : 0;
	switch (type)  {
	case C_RFIS:
		return Q_TRAN(&Ht_RegFis);
	case C_SDB:
		return Q_TRAN(&Ht_DbFis);
	case C_DmaAct:
		return Q_TRAN(&Ht_DmaFis);
	case C_PioSetup:
		return Q_TRAN(&Ht_PsFis);
	case C_DmaSetup:
		return Q_TRAN(&Ht_DsFis);
	case C_DFIS:
		return Q_TRAN(&Ht_DmaITrans);
	}
	return Q_TRAN(&Ht_ufis);
}
/*..........................................................................*/
void regfis_entry(QHsmSata *me, QEvent const *e)
{
	SataEvent *se = (SataEvent *)e;
	uint16_t pmp = me->fbs ? se->fis & 0x1f00 : 0;
	uint32_t addr = me->rx_fis + pmp + 0x00;
	rx_dma_start(me->port,
		     addr,	/* address */
		     0x20);	/* length */
}
/*..........................................................................*/
QState regfis_done(QHsmSata *me)
{
	uint32_t fis = me->fis_buf[0];
	uint16_t tfd = fis >> 16;
	uint8_t pPmpCur = me->pPmpCur;
	uint8_t bsy = tfd & (1<<7);
	uint8_t drq = tfd & (1<<3);
	uint8_t slot = me->pIssueSlot[pPmpCur];
	
	me->PxTFD = tfd;
	pBsy_set(me, pPmpCur, bsy);
	pBsy_set(me, pPmpCur, drq);
	me->pDmaXferCnt = 0;
	
	if (tfd & 1) {	/* ERR */
		hw_reg_begin (me->port,  INTC_REGFIS);
		hw_reg_update(me->port, C_DATA, 1);
		hw_reg_update(me->port, C_PxTFD, me->PxTFD);
		hw_reg_update(me->port, C_SLOT, slot);
		hw_reg_update(me->port, 6, fis);
		hw_reg_end   (me->port);
		return Q_TRAN(&ERR_FatalTaskFile);
	}
	if (~bsy && ~drq) {
		me->PxCI &= ~(1<<slot);
		me->pIssueSlot[pPmpCur] = 32;
	}
	if (fis & (1<<14)) {	/* Interrupt bit */
		hw_reg_begin (me->port,  INTC_REGFIS);
		hw_reg_update(me->port, C_DATA,  0);
		hw_reg_update(me->port, C_PxCI,  me->PxCI);
		hw_reg_update(me->port, C_PxSACT, me->PxSACT);
		hw_reg_update(me->port, C_PxTFD, me->PxTFD);
		hw_reg_update(me->port, C_SLOT, slot);
		hw_reg_update(me->port, 6, fis);
		hw_reg_end   (me->port);
	}
	if (me->pUpdateSig) {
		hw_reg_begin (me->port, INTC_REGFIS);
		hw_reg_update(me->port, C_DATA, 2);
		hw_reg_update(me->port, 6, fis);
		hw_reg_end   (me->port);
		me->pUpdateSig = 0;
	}
	return Q_TRAN(&Ht_HostIdle);
}
/*..........................................................................*/
QState Ht_RegFis(QHsmSata *me, QEvent const *e)
{
	switch (e->sig) {
	case Q_ENTRY_SIG:
		BSP_display("RegFis-ENTRY;");
		regfis_entry(me, e);
		return Q_HANDLED();
	case Q_EXIT_SIG:
		BSP_display("RegFis-EXIT;");
		return Q_HANDLED();
	case DMA_DONE_SIG:
		BSP_display("RegFis-DMA;");
		return Q_HANDLED();
	case RX_GOOD_SIG:
		BSP_display("RegFis-GOOD;");
		cx_fifo_ack(me->port, 0x1);
		return regfis_done(me);
	case RX_BAD_SIG:
		BSP_display("RegFis-BAD;");
		/* never happen */
		return Q_TRAN(&Ht_HostIdle);
	}
	return Q_SUPER(&QHsm_top);
}
/*..........................................................................*/
void sdb_entry(QHsmSata *me, QEvent const *e)
{
	SataEvent *se = (SataEvent *)e;
	uint16_t pmp = me->fbs ? se->fis & 0x1f00 : 0;
	uint32_t addr = me->rx_fis + pmp + 0x20;
	rx_dma_start(me->port,
		     addr,
		     0x20);
}
/*..........................................................................*/
QState sdb_done(QHsmSata *me)
{
	uint32_t fis = me->fis_buf[0];
	uint16_t tfd = (fis >> 16) & 0xff77;

	me->PxTFD = tfd;
	me->pSActive = me->fis_buf[1];
	me->PxSACT &= ~(me->pSActive);
	me->pDmaXferCnt = 0;
	
	if (tfd & (1<<0)) {	/* ERR */
		hw_reg_begin (me->port,  INTC_SDBFIS);
		hw_reg_update(me->port, C_DATA, 0x1);
		hw_reg_update(me->port, C_PxTFD, me->PxTFD);
		hw_reg_update(me->port, C_PxSACT, me->PxSACT);
		hw_reg_end   (me->port);
		return Q_TRAN(&ERR_FatalTaskFile);
	}
	if (tfd & (1<<15)) {	/* notification */
		hw_reg_begin (me->port,  INTC_SDBFIS);
		hw_reg_update(me->port, C_DATA, 0x2);
		hw_reg_update(me->port, C_PxCI,   me->PxCI);
		hw_reg_update(me->port, C_PxSACT, me->PxSACT);
		hw_reg_end   (me->port);
		return Q_TRAN(&Ht_HostIdle);
	}
	if (fis & (1<<14)) {	/* Interrupt */
		hw_reg_begin (me->port, INTC_SDBFIS);
		hw_reg_update(me->port, C_DATA, 0x0);
		hw_reg_update(me->port, C_PxCI,   me->PxCI);
		hw_reg_update(me->port, 2, me->pDmaXferCnt);
		hw_reg_update(me->port, C_PxSACT, me->pSActive);
		hw_reg_update(me->port, 6, fis);
		hw_reg_end   (me->port);
		return Q_TRAN(&Ht_HostIdle);
	}
	return Q_TRAN(&Ht_HostIdle);
}
/*..........................................................................*/
QState Ht_DbFis(QHsmSata *me, QEvent const *e)
{
	switch (e->sig) {
	case Q_ENTRY_SIG: 
		BSP_display("SDB-ENTRY;");
		sdb_entry(me, e);
		return Q_HANDLED();
	case Q_EXIT_SIG:
		BSP_display("SDB-EXIT;");
		return Q_HANDLED();
	case DMA_DONE_SIG:
		BSP_display("SDB-DMA;");
		return Q_HANDLED();
	case RX_GOOD_SIG:
		BSP_display("SDB-GOOD;");
		cx_fifo_ack(me->port, 1);
		return sdb_done(me);
	case RX_BAD_SIG:
		BSP_display("SDB-BAD;");
		/* never happen */
		return Q_TRAN(&Ht_HostIdle);
	}
	return Q_SUPER(&QHsm_top);
}
/*..........................................................................*/
void dmaa_entry(QHsmSata *me, QEvent const *e)
{
	SataEvent *se = (SataEvent *)e;
	uint16_t pmp = me->fbs ? se->fis & 0x1f00 : 0;
	uint32_t addr = me->rx_fis + pmp + 0x40;
	rx_dma_start(me->port,
		     addr,
		     0x20);
}
/*..........................................................................*/
QState Ht_DmaFis(QHsmSata *me, QEvent const *e)
{
	switch (e->sig) {
	case Q_ENTRY_SIG: 
		BSP_display("DAct-ENTRY;");
		dmaa_entry(me, e);
		return Q_HANDLED();
	case Q_EXIT_SIG:
		BSP_display("DAct-EXIT;");
		return Q_HANDLED();
	case DMA_DONE_SIG:
		BSP_display("DAct-DMA;");
		return Q_HANDLED();
	case RX_GOOD_SIG:
		BSP_display("DAct-GOOD;");
		cx_fifo_ack(me->port, 1);
		return Q_TRAN(&Ht_DmaOTrans);
	case RX_BAD_SIG:
		BSP_display("DAct-BAD;");
		/* never happen */
		return Q_TRAN(&Ht_HostIdle);
	}
	return Q_SUPER(&QHsm_top);
}
/*..........................................................................*/
void pio_entry(QHsmSata *me, QEvent const *e)
{
	SataEvent *se = (SataEvent *)e;
	uint16_t pmp = me->fbs ? se->fis & 0x1f00 : 0;
	uint32_t addr = me->rx_fis + pmp + 0x80;
	rx_dma_start(me->port,
		     addr,
		     0x20);
}
/*..........................................................................*/
QState pio_done(QHsmSata *me)
{
	uint32_t fis = me->fis_buf[0];
	uint8_t pPmpCur = me->pPmpCur;
	uint16_t tfd = fis>>16;
	me->pPioXfer[pPmpCur] = 1;
	me->pPioEsts[pPmpCur] = me->fis_buf[3]>>24;
	me->pPioErr[pPmpCur]  = fis >> 24;
	me->pPiolbit[pPmpCur] = test_bit(fis, 14);
	me->pDmaXferCnt       = me->fis_buf[4];
	me->PxTFD             = tfd;
	pBsy_set(me, pPmpCur, tfd & (1<<7));
	pDrq_set(me, pPmpCur, tfd & (1<<3));
#ifdef MPI_TRACE
	hw_reg_begin (me->port, INTC_TRACE);
	hw_reg_update(me->port, C_DATA, __LINE__ | _pio_done<<16);
	hw_reg_update(me->port, 1, me->pDmaXferCnt);
	hw_reg_update(me->port, 2, pPmpCur);
	hw_reg_update(me->port, 3, fis);
	hw_reg_end   (me->port);
#endif
	if (tfd & (1<<0)) {	/* ERR */
		hw_reg_begin (me->port, INTC_PIOSFIS);
		hw_reg_update(me->port, C_DATA, 1);
		hw_reg_update(me->port, C_PxTFD, me->PxTFD);
		hw_reg_end   (me->port);
		return Q_TRAN(&ERR_FatalTaskFile);
	}
	if ((fis & (1<<13)) == 0 && me->pXferAtapi[pPmpCur] == 0) {
		return Q_TRAN(&Ht_DmaOTrans);
	}
	if ((fis & (1<<13)) == 0 && me->pXferAtapi[pPmpCur] == 1) {
		/* TODO: ATAPI_ENTRY */
	}
	return Q_TRAN(&Ht_HostIdle);
}
/*..........................................................................*/
QState Ht_PsFis(QHsmSata *me, QEvent const *e)
{
	switch (e->sig) {
	case Q_ENTRY_SIG: 
		BSP_display("Ps-ENTRY;");
		pio_entry(me, e);
		return Q_HANDLED();
	case Q_EXIT_SIG:
		BSP_display("Ps-EXIT;");
		return Q_HANDLED();
	case DMA_DONE_SIG:
		BSP_display("Ps-DMA;");
		return Q_HANDLED();
	case RX_GOOD_SIG:
		BSP_display("Ps-GOOD;");
		cx_fifo_ack(me->port, 1);
		return pio_done(me);
	case RX_BAD_SIG:
		BSP_display("Ps-BAD;");
		/* never happen */
		return Q_TRAN(&Ht_HostIdle);
	}
	return Q_SUPER(&QHsm_top);
}
/*..........................................................................*/
void dmaset_entry(QHsmSata *me, QEvent const *e)
{
	SataEvent *se = (SataEvent *)e;
	uint16_t pmp = me->fbs ? se->fis & 0x1f00 : 0;
	uint32_t addr = me->rx_fis + pmp + 0x60;
	rx_dma_start(me->port, 
		     addr,
		     0x20);
}
/*..........................................................................*/
QState dmaset_done(QHsmSata *me)
{
	uint32_t fis = me->fis_buf[0];
	me->pDmaXferCnt = me->fis_buf[5];
	uint8_t pPmpCur = me->pPmpCur;
	uint8_t tag = me->fis_buf[1] & 0x1f;
	me->pDataSlot[pPmpCur] = tag;
	struct ahci_cmd_hdr *hdr = me->hdr + me->pDataSlot[pPmpCur];
	if ((hdr->opts & AHCI_CMD_WRITE) && (fis & (1<<15))) {/* AutoActive */
		return Q_TRAN(&Ht_DmaOTrans);
	}
	return Q_TRAN(&Ht_HostIdle);
}
/*..........................................................................*/
QState Ht_DsFis(QHsmSata *me, QEvent const *e)
{
	switch (e->sig) {
	case Q_ENTRY_SIG: 
		BSP_display("Ds-ENTRY;");
		dmaset_entry(me, e);
		return Q_HANDLED();
	case Q_EXIT_SIG:
		BSP_display("Ds-EXIT;");
		return Q_HANDLED();
	case DMA_DONE_SIG:
		BSP_display("Ds-DMA;");
		return Q_HANDLED();
	case RX_GOOD_SIG:
		BSP_display("Ds-GOOD;");
		cx_fifo_ack(me->port, 1);
		return dmaset_done(me);
	case RX_BAD_SIG:
		BSP_display("Ds-BAD;");
		/* never happen */
		return Q_TRAN(&Ht_HostIdle);
	}
	return Q_SUPER(&QHsm_top);
}
/*..........................................................................*/
void ufis_entry(QHsmSata *me, QEvent const *e)
{
	SataEvent *se = (SataEvent *)e;
	uint16_t pmp = me->fbs ? se->fis & 0x1f00 : 0;
	uint32_t addr = me->rx_fis + pmp + 0xA0;
	rx_dma_start(me->port,
		     addr,
		     0x20);
}
/*..........................................................................*/
void ufis_done(QHsmSata *me)
{
	hw_reg_begin (me->port, INTC_UFIS);
	hw_reg_update(me->port, C_DATA, me->fis_buf[0]);
	hw_reg_end   (me->port);
}
/*..........................................................................*/
QState Ht_ufis(QHsmSata *me, QEvent const *e)
{
	switch (e->sig) {
	case Q_ENTRY_SIG: 
		BSP_display("UFIS-ENTRY;");
		ufis_entry(me, e);
		return Q_HANDLED();
	case Q_EXIT_SIG:
		BSP_display("UFIS-EXIT;");
		return Q_HANDLED();
	case DMA_DONE_SIG:
		BSP_display("UFIS-DMA;");
		return Q_HANDLED();
	case RX_GOOD_SIG:
		BSP_display("UFIS-GOOD;");
		cx_fifo_ack(me->port, 1);
		ufis_done(me);
		return Q_TRAN(&Ht_HostIdle);
	case RX_BAD_SIG:
		BSP_display("UFIS-BAD;");
		return Q_TRAN(&Ht_HostIdle);
	}
	return Q_SUPER(&QHsm_top);
}
/*..........................................................................*/
QState dx_entry(QHsmSata *me, int mlen)
{
	uint8_t pPmpCur = me->pPmpCur;
	uint8_t slot = me->pDataSlot[pPmpCur];
	struct ahci_cmd_hdr *hdr = me->hdr + slot;
	uint16_t tl = hdr->opts >> 16;
	if (tl == 0) {
		if (me->pPioXfer[pPmpCur]) {
			return pio_update(me, pPmpCur);
		}
		hw_reg_begin (me->port, INTC_REJECT);
		hw_reg_update(me->port, C_DATA, 0x1);
		hw_reg_update(me->port, C_SLOT, slot);
		hw_reg_update(me->port, C_PxCI, pPmpCur);
		hw_reg_end   (me->port);
		return Q_TRAN(&Ht_HostIdle);
	}
	uint8_t pmp = (hdr->opts >> 12) & 0xf, eof = 0;
	uint32_t addr, opt;

	if (mlen != 0x2000) {/* again */
		hdr->sg_offset += me->len;
		me->pDmaXferCnt -= me->len;
	}

	me->len = opt = prd_get_al(me->hdr + slot, &addr, mlen, &eof);
	if (opt == 0) {
		hw_reg_begin (me->port, INTC_REJECT);
		hw_reg_update(me->port, C_DATA, 0x3);
		hw_reg_update(me->port, C_SLOT, slot);
		hw_reg_update(me->port, C_PxCI, opt);
		hw_reg_end   (me->port);
		return Q_TRAN(&Ht_HostIdle);
	}
	me->left -= opt;
	if (eof)
		me->left = 0;

	opt |= (pmp << 16);	/* PMP */
	opt |= DMA_DAT;		/* DataFis */
	opt |= mlen == 0x2000 ? DMA_SOF : 0;    /* SOF */
	opt |= me->left == 0 ? DMA_EOF : 0;	/* EOF */
	tx_dma_start(me->port,
		     addr,
		     opt);
	return Q_HANDLED();
}
/*..........................................................................*/
QState dx_done(QHsmSata *me, int err)
{
	uint8_t pPmpCur = me->pPmpCur;
	uint8_t slot = me->pDataSlot[pPmpCur];
	struct ahci_cmd_hdr *hdr = me->hdr + slot;
	if (err == 0) {
		me->pDmaXferCnt -= me->len;
		hdr->sg_offset += me->len;
		return Q_TRAN(&Ht_HostIdle);
	}
	hw_reg_begin (me->port, INTC_RERR);
	hw_reg_update(me->port, C_SLOT, slot);
	hw_reg_update(me->port, C_DATA, err);
	hw_reg_end   (me->port);
	if (me->fbs)
		return Q_TRAN(&ERR_NotFatal);
	return Q_TRAN(&ERR_Fatal);
}
/*..........................................................................*/
QState Ht_DmaOTrans(QHsmSata *me, QEvent const *e)
{
	switch (e->sig) {
	case Q_ENTRY_SIG: 
		BSP_display("DmaO-ENTRY;");
		me->left = 0x2000;
		me->pDmaTickCnt = DMA_TICK_CNT;
		return dx_entry(me, me->left);
	case Q_EXIT_SIG:
		BSP_display("DmaO-EXIT;");
		return Q_HANDLED();
	case DMA_DONE_SIG:
		BSP_display("DmaO-DMA;");
		if (me->left)
			return dx_entry(me, me->left);
		return Q_HANDLED();
	case TX_ROK_SIG:
		BSP_display("DmaO-ROK;");
		cx_fifo_ack(me->port, 1);
		dx_done(me, 0);
		return Q_TRAN(&Ht_HostIdle);
	case TX_RERR_SIG:
		BSP_display("DmaO-RERR;");
		cx_fifo_ack(me->port, 1);
		return dx_done(me, 1);
	case TX_SYNC_SIG:
		BSP_display("DmaO-SYNC;");
		cx_fifo_ack(me->port, 1);
		return dx_done(me, 2);
	case TX_SRCV_SIG:
		BSP_display("DmaO-SRCV;");
		cx_fifo_ack(me->port, 1);
		return dx_done(me, 3);
	case RX_REGFIS_SIG:
		BSP_display("DmaO-REG(SYNC);");
		cx_fifo_ack(me->port, 0);
		return Q_HANDLED();
	case TICK_SIG:
		BSP_display("DmaO-TICK;");
		me->pDmaTickCnt --;
		if (me->pDmaTickCnt == 0) {
			me->pDmaTickCnt = DMA_TICK_CNT;
			hw_reg_begin (me->port, INTC_TRACE);
			hw_reg_update(me->port, C_DATA, __LINE__);
			hw_reg_update(me->port, 1, me->len);
			hw_reg_end   (me->port);
		}
		return Q_SUPER(&Ht_HostIdle);
	}
	return Q_SUPER(&Ht_HostIdle);
}
/*..........................................................................*/
QState dr_entry(QHsmSata *me, QEvent const *e, int mlen)
{
	SataEvent *se = (SataEvent *)e;
	me->pPmpCur = me->fbs ? se->fis >> 8 : 0;
	uint8_t slot = me->pDataSlot[me->pPmpCur];
	struct ahci_cmd_hdr *hdr = me->hdr + slot;
	uint32_t len = 0;
	uint32_t addr= 0;
	uint8_t eof = 0;

	if (mlen != 0x2000) {/* again */
		hdr->status += me->len;
		hdr->sg_offset += me->len;
		me->pDmaXferCnt -= me->len;
	}

	me->len = len = prd_get_al(hdr, &addr, mlen, &eof);
	if (len == 0) {
		hw_reg_begin (me->port, INTC_REJECT);
		hw_reg_update(me->port, C_DATA, 0x2);
		hw_reg_update(me->port, C_SLOT, slot);
		hw_reg_end   (me->port);
		return Q_SUPER(&QHsmSata_top);
	}
	rx_dma_start(me->port,
		     addr,	/* addr */
		     len);	/* length */
	
	return Q_HANDLED();
}
/*..........................................................................*/
QState pio_update(QHsmSata *me, uint8_t pPmpCur)
{
	uint16_t tfd = me->pPioEsts[pPmpCur] | (me->pPioErr[pPmpCur] << 8);
	me->PxTFD = tfd;
	pBsy_set(me, pPmpCur, tfd & (1<<7));
	pDrq_set(me, pPmpCur, tfd & (1<<3));
	me->fb_ci = 0;
	me->pPioXfer[pPmpCur] = 0;
#ifdef MPI_TRACE
	hw_reg_begin (me->port, INTC_TRACE);
	hw_reg_update(me->port, C_DATA, __LINE__ | (_pio_update<<16));
	hw_reg_update(me->port, 1, tfd);
	hw_reg_update(me->port, 2, pPmpCur);
	hw_reg_update(me->port, 3, me->pPiolbit[pPmpCur]);
	hw_reg_end   (me->port);
#endif
	if (tfd & (1<<0)) {
		hw_reg_begin (me->port, INTC_PIOSFIS);
		hw_reg_update(me->port, C_DATA, 2);
		hw_reg_update(me->port, C_PxTFD, me->PxTFD);
		hw_reg_end   (me->port);
		return Q_TRAN(&ERR_FatalTaskFile);
	}
	if (((tfd & (1<<7)) == 0) && ((tfd & (1<<3)) == 0)) {
		uint8_t slot = me->pIssueSlot[pPmpCur];
		me->PxCI &= ~(1<<slot);
		me->pIssueSlot[pPmpCur] = 32;
	}
	if (me->pPiolbit[pPmpCur]) {	/* Interrupt */
		hw_reg_begin (me->port, INTC_PIOSFIS);
		hw_reg_update(me->port, C_DATA, 0);
		hw_reg_update(me->port, C_PxTFD, me->PxTFD);
		hw_reg_update(me->port, C_PxCI, me->PxCI);
		hw_reg_update(me->port, C_PxSACT, me->PxSACT);
		hw_reg_update(me->port, 6, pPmpCur<<8);
		hw_reg_end   (me->port);
	}
	return Q_TRAN(&Ht_HostIdle);
}
/*..........................................................................*/
QState dr_done(QHsmSata *me, int err)
{
	uint8_t pPmpCur = me->pPmpCur;
	uint8_t slot = me->pDataSlot[pPmpCur];
	struct ahci_cmd_hdr *hdr = me->hdr + slot;

	if (err == 1) {
		hw_reg_begin (me->port, INTC_CRCERR);
		hw_reg_update(me->port, C_DATA, 1);
		hw_reg_update(me->port, C_SLOT, slot);
		hw_reg_end   (me->port);
		return Q_TRAN(&ERR_Fatal);
	}
	
#ifdef MPI_TRACE
	hw_reg_begin (me->port, INTC_TRACE);
	hw_reg_update(me->port, C_DATA, __LINE__ | (_dr_done<<16));
	hw_reg_update(me->port, 1, me->len);
	hw_reg_update(me->port, 2, pPmpCur);
	hw_reg_end   (me->port);
#endif

	hdr->status += me->len;
	hdr->sg_offset += me->len;
	me->pDmaXferCnt -= me->len;
	if (me->pPioXfer[pPmpCur]) { /* pio_update */
		return pio_update(me, pPmpCur);
	}
	
	return Q_TRAN(&Ht_HostIdle);
}
/*..........................................................................*/
QState Ht_DmaITrans(QHsmSata *me, QEvent const *e)
{
	switch (e->sig) {
	case Q_ENTRY_SIG: 
		BSP_display("DmaI-ENTRY;");
		me->left = 0x2000;
		me->pDmaTickCnt = DMA_TICK_CNT;
		return dr_entry(me, e, me->left);
	case Q_EXIT_SIG:
		BSP_display("DmaI-EXIT;");
		return Q_HANDLED();
	case DMA_DONE_SIG:
		BSP_display("DmaI-DMA;");
		return Q_HANDLED();
	case RX_REGFIS_SIG:
		BSP_display("DmaI-AGAIN;");
		me->left -= me->len;
		return dr_entry(me, e, me->left);
	case RX_GOOD_SIG:
		BSP_display("DmaI-GOOD;");
		cx_fifo_ack(me->port, 0x1);
		return dr_done(me, 0);
	case RX_BAD_SIG:
		BSP_display("DmaI-BAD;");
		cx_fifo_ack(me->port, 0x0);
		return dr_done(me, 1);
	case TICK_SIG:
		BSP_display("DmaI-TICK;");
		me->pDmaTickCnt --;
		if (me->pDmaTickCnt == 0) {
			me->pDmaTickCnt = DMA_TICK_CNT;
			hw_reg_begin (me->port, INTC_TRACE);
			hw_reg_update(me->port, C_DATA, __LINE__);
			hw_reg_update(me->port, 1, me->len);
			hw_reg_end   (me->port);
		}
		return Q_SUPER(&Ht_HostIdle);
	}
	/* other SIG is error, so passed to top level */
	return Q_SUPER(&Ht_HostIdle);
}
/*..........................................................................*/
uint32_t prd_get_al(struct ahci_cmd_hdr *hdr, uint32_t *addr,
		uint32_t mlen, uint8_t *eof)
{
	struct ahci_sg *sg = (struct ahci_sg *)(hdr->tbl_addr + 0x80 + 0xC0000000);
	uint32_t len = mlen, adr, olen;
	uint16_t max = hdr->opts >> 16;

	sg += hdr->sg_cnt;

	len = sg->flags_size;
	len ++;

	if (hdr->sg_offset == len) {
		hdr->sg_cnt ++;
		sg ++;
		hdr->sg_offset = 0;
		if (hdr->sg_cnt == max)
			return 0;
	}

	len = sg->flags_size;
	len ++;
	olen = len;
	len -= hdr->sg_offset;

	adr = sg->addr;
	if (len > mlen) /* 8K */
		len = mlen;

	*addr = adr + hdr->sg_offset;

	if (hdr->sg_offset + len == olen && hdr->sg_cnt + 1 == max)
		*eof = 1;

	return len;
}

/*..........................................................................*/
QState ERR_FatalTaskFile(QHsmSata *me, QEvent const *e)
{
	switch (e->sig) {
	case Q_ENTRY_SIG:
		BSP_display("ERR_FatalTaskFile-ENTRY;");
		return Q_HANDLED();
	case Q_EXIT_SIG:
		BSP_display("ERR_FatalTaskFile-EXIT;");
		return Q_HANDLED();
	case TICK_SIG:
		BSP_display("ERR_FatalTaskFile-TICK;");
		/* send to host */
		return Q_HANDLED();
	case HCMD_SIG:
		BSP_display("ERR_FatalTaskFile-HCMD;");
		SataEvent *se = (SataEvent *)e;
		return Ht_Start(me, se);
	}
	return Q_SUPER(&QHsmSata_top);
}

/*..........................................................................*/
QState ERR_NotFatal(QHsmSata *me, QEvent const *e)
{
	switch (e->sig) {
	case Q_ENTRY_SIG:
		BSP_display("ERR_NotFatal-ENTRY;");
		return Q_HANDLED();
	case Q_EXIT_SIG:
		BSP_display("ERR_NotFatal-EXIT;");
		return Q_HANDLED();
	case TICK_SIG:
		BSP_display("ERR_NotFatal-TICK;");
		/* send to host */
		return Q_HANDLED();
	case HCMD_SIG:
		BSP_display("ERR_NotFatal-HCMD;");
		return Q_HANDLED();
	}
	return Q_SUPER(&QHsmSata_top);
}

/*..........................................................................*/
QState ERR_Fatal(QHsmSata *me, QEvent const *e)
{
	switch (e->sig) {
	case Q_ENTRY_SIG:
		BSP_display("ERR_Fatal-ENTRY;");
		return Q_HANDLED();
	case Q_EXIT_SIG:
		BSP_display("ERR_Fatal-EXIT;");
		return Q_HANDLED();
	case TICK_SIG:
		BSP_display("ERR_Fatal-TICK;");
		/* send to host */
		return Q_HANDLED();
	case HCMD_SIG:
		BSP_display("ERR_Fatal-HCMD;");
		SataEvent *se = (SataEvent *)e;
		return Ht_Start(me, se);
	}
	return Q_SUPER(&QHsmSata_top);
}

/*..........................................................................*/
uint32_t * hw_get_buf(uint8_t port)
{
	port &= 0x3;
	return _HSM_QHsmSata[port].fis_buf;
}

/*..........................................................................*/
void hw_dispatch(uint8_t port, QEvent *e)
{
	port &= 0x3;
#ifdef MPI_TRACE
	if (e->sig != TICK_SIG) {
		hw_reg_begin (port, INTC_TRACE);
		hw_reg_update(port, C_DATA, __LINE__  | (_hw_dispatch << 16));
		hw_reg_update(port, 1, e->sig);
		hw_reg_end   (port);
	}
#endif
	QHsm_dispatch(&_HSM_QHsmSata[port].super, e);
}
