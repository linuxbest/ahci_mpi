#include "qep_port.h"
#include "qassert.h"

#include "sata_mpi.h"
#include "sata_hw.h"

#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <time.h>
#include <termios.h>
#include <unistd.h>

typedef uint32_t __le32;
#include "ahci.h"

/* local objects -----------------------------------------------------------*/
static FILE *l_outFile;
static void dispatch(QEvent *e);
static struct ahci_cmd_hdr hdrs[32];
static unsigned char fis_buf[8192];
static unsigned char cmdtabl[8192];
static struct ahci_sg *prd_sgs;
/*..........................................................................*/
int main(int argc, char *argv[]) {
	SataEvent se;
	uint32_t *fis;

	QHsmSata_ctor();                             /* instantiate the HSM */

	l_outFile = stdout;
	
        QHsm_init((QHsm *)HSM_QHsmSata, 0); /* take the initial transitioin */

	hdrs[0].opts = AHCI_CMD_CLR_BUSY |(1<<16);
	hdrs[1].opts = AHCI_CMD_CLR_BUSY |(1<<16);
	hdrs[0].tbl_addr = cmdtabl;
	hdrs[1].tbl_addr = cmdtabl;
	
	prd_sgs = cmdtabl + 0x80;
	prd_sgs[0].addr       = 0xc000;
	prd_sgs[0].flags_size = 0x2fff;

	SataCmd cmd;
	cmd.type = 0x0;
	cmd.port = 0;
	cmd.cmd  = 0x0;
	cmd.d[0] = (uint32_t)(void *)hdrs;
	cmd.d[1] = (uint32_t)(void *)fis_buf;
	
	printf("setup hdr address");
	se.e.sig = HCMD_SIG;
	se.a.cmd = &cmd;
	dispatch(&se.e);

	printf("\n\n1: StartComm");
	se.e.sig = StartComm_SIG;
	dispatch(&se.e);

	se.e.sig = LINKUP_SIG;
	dispatch(&se.e);

	printf("\n\n2: Sending CMD with ROK");
	/* testing send cmd with ok */
	cmd.cmd  = 0x2;
	cmd.d[0] = 0x1;
	se.e.sig = HCMD_SIG;
	se.a.cmd = &cmd;
	dispatch(&se.e);

	se.e.sig = TICK_SIG;
	dispatch(&se.e);	

	se.e.sig = TX_ROK_SIG;
	dispatch(&se.e);

	printf("\n\n3: Sending CMD with RERR");
	/* testing send cmd with err */
	cmd.cmd  = 0x2;
	cmd.d[0] = 0x1;
	se.e.sig = HCMD_SIG;
	se.a.cmd = &cmd;
	dispatch(&se.e);

	se.e.sig = TICK_SIG;
	dispatch(&se.e);	

	se.e.sig = TX_RERR_SIG;
	dispatch(&se.e);

	se.e.sig = TICK_SIG;
	dispatch(&se.e);	

	se.e.sig = TX_ROK_SIG;
	dispatch(&se.e);

	/* testing recv register fis */
	printf("\n\n4a: Received RFIS with good");
	se.error = iFIFO_STS_GOOD;
	se.e.sig = RX_REGFIS_SIG;
	se.a.fis = C_RFIS;
	dispatch(&se.e);
	se.e.sig = RX_GOOD_SIG;
	dispatch(&se.e);

	printf("\n\n4b: Received RFIS with BAD");
	se.error = iFIFO_STS_BAD;
	se.e.sig = RX_REGFIS_SIG;
	se.a.fis = C_RFIS;
	dispatch(&se.e);

	printf("\n\n5: Received RFIS with good");
	se.error = iFIFO_STS_GOOD;
	se.e.sig = RX_REGFIS_SIG;
	se.a.fis = C_RFIS;
	dispatch(&se.e);
	se.e.sig = RX_GOOD_SIG;
	dispatch(&se.e);

	se.e.sig = TICK_SIG;
	dispatch(&se.e);	

	printf("\n\n6: Received DmaAct with good");
	se.error = iFIFO_STS_GOOD;
	se.e.sig = RX_REGFIS_SIG;
	se.a.fis = C_DmaAct;
	dispatch(&se.e);
	se.e.sig = RX_GOOD_SIG;
	dispatch(&se.e);
	se.e.sig = RX_REGFIS_SIG;
	dispatch(&se.e);
	se.e.sig = TX_ROK_SIG;
	dispatch(&se.e);

	printf("\n\n7(0): Sending A dmaSetup");
	se.error = iFIFO_STS_GOOD;
	se.e.sig = RX_REGFIS_SIG;
	se.a.fis = C_DmaSetup;
	dispatch(&se.e);
	
	fis = fis_buf + 0x60;
	fis[0] = C_DmaSetup;
	fis[5] = 0x2000;
	se.e.sig = RX_GOOD_SIG;
	dispatch(&se.e);

	
	printf("\n\n7(1): Received DataFis with good");
	se.e.sig = RX_DATFIS_SIG;
	se.a.fis = C_DFIS;
	dispatch(&se.e);

	se.error = iFIFO_STS_GOOD;
	se.e.sig = RX_REGFIS_SIG;
	se.a.fis = C_DmaSetup;
	dispatch(&se.e);

	se.e.sig = RX_GOOD_SIG;
	dispatch(&se.e);

	se.e.sig = RX_DATFIS_SIG;
	se.a.fis = C_DFIS;
	dispatch(&se.e);

	se.e.sig = RX_GOOD_SIG;
	dispatch(&se.e);

	printf("\n\n8: Cmd fis");
	cmd.type = 0x0;
	cmd.port = 0;
	cmd.cmd  = 0x2;	
	cmd.d[0] = 0x3;
	se.e.sig = HCMD_SIG;
	se.a.cmd = &cmd;
	dispatch(&se.e);
	dispatch(&se.e);
	/* this tick will sending cmd fis */
	se.e.sig = TICK_SIG;
	dispatch(&se.e);	
	/* but remote sync it */
	se.e.sig = TX_SYNC_SIG;
	dispatch(&se.e);	
	/* this tick will send again */
	se.e.sig = TICK_SIG;
	dispatch(&se.e);	
	/* next command */
	se.e.sig = HCMD_SIG;
	se.a.cmd = &cmd;
	dispatch(&se.e);
	/* next tick */
	se.e.sig = TICK_SIG;
	dispatch(&se.e);
	/* next tick */
	se.e.sig = TICK_SIG;
	dispatch(&se.e);
	/* OK */
	se.e.sig = TX_ROK_SIG;
	dispatch(&se.e);

	se.e.sig = TICK_SIG;
	dispatch(&se.e);
	/* OK */
	se.e.sig = TX_ROK_SIG;
	dispatch(&se.e);

	se.e.sig = TICK_SIG;
	dispatch(&se.e);
	se.e.sig = TICK_SIG;
	dispatch(&se.e);

	printf("\n\n9: Received DmaAct with good");
	se.error = iFIFO_STS_GOOD;
	se.e.sig = RX_REGFIS_SIG;
	se.a.fis = C_SDB;
	dispatch(&se.e);
	se.e.sig = RX_GOOD_SIG;
	dispatch(&se.e);

	printf("\n\n10: Received UFIS with good");
	se.error = iFIFO_STS_GOOD;
	se.e.sig = RX_REGFIS_SIG;
	se.a.fis = C_SDB+1;
	dispatch(&se.e);
	se.e.sig = RX_GOOD_SIG;
	dispatch(&se.e);
	
	printf("\n");

	return 0;
}
/*..........................................................................*/
void Q_onAssert(char const Q_ROM * const Q_ROM_VAR file, int line) {
	fprintf(stderr, "Assertion failed in %s, line %d", file, line);
	exit(-1);
}
/*..........................................................................*/
void BSP_display(const char *fmt, ...) 
{
	va_list args;
	char msg[1024];
	
	va_start(args, fmt);
	sprintf(msg, fmt, args);
	va_end(args);

	fprintf(l_outFile, msg);
	fflush(l_outFile);
}
/*..........................................................................*/
void BSP_exit(void) {
	printf("Bye, Bye!\n");
	exit(0);
}
/*..........................................................................*/
char *str[] = {
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

	[HCMD_SIG]      = "hostcmd  ",
	[StartComm_SIG] = "StartComm",
	[TICK_SIG]      = "tick     ",
};
static void dispatch(QEvent *e) {
	fprintf(l_outFile, "\n  %s:", str[e->sig]);
	QHsm_dispatch((QHsm *)HSM_QHsmSata, e);    /* dispatch the event */
#if 0
	SataEvent se;
	se.e.sig = TICK_SIG;
	e = &se.e;
	fprintf(l_outFile, "\n  %s:", str[e->sig]);
	QHsm_dispatch((QHsm *)&HSM_QHsmSata, e);    /* dispatch the event */
#endif
}

void tx_dma_start(uint8_t port, uint32_t addr, uint32_t opt)
{
	printf("txdma{%x/%x};", addr, opt);
}

void rx_dma_start(uint8_t port, uint32_t addr, uint32_t opt)
{
	printf("rxdma{%x/%x/%s};", addr, opt, opt&(1<<31) ? "flush" : "normal");
}

void cx_fifo_ack(uint8_t port, uint8_t ok)
{
	printf("cx{%s};", ok ? "OK" : "SYNC");
}

void hw_oob(uint8_t port)
{
}

void hw_init(uint8_t port)
{
}

void hw_reg_begin(uint8_t port, uint8_t type)
{
}

void hw_reg_update(uint8_t port, uint8_t type, uint32_t reg)
{
}

void hw_reg_end(uint8_t port)
{
}

