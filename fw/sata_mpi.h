#ifndef _SATA_MPI_H_
#define _SATA_MPI_H_

typedef volatile struct SataMPI {
	uint32_t header;
	uint32_t d[7];
} SataCmd;
/*
 * cmd:
 *  0: Init, d[0] = hdr address
 *  1: StartComm
 *  2: PxCI update, d[0] = new CI
 */

/*
 * HOST => MB message.
 *  header[31:24] 0x0
 *  header[23:16] port number
 *  header[15:8]  cmd
 *  header[7:0]   valid register
 *
 *  cmd: 0x00: INIT_ADDRESS, C_DATA, d[0] = Command Table 
 *       0x01: update PxCI,  C_PxCI, C_PxSACT
 *       0x10: StartComm
 */
/*
 * MB => HOST message.
 *  header[31:24] 0x1
 *  header[23:16] port number
 *  header[15:8]  type
 *  header[7:0]   valid register.
 */
enum {
	INTC_IDLE   = 0,	/* port init finished, 
				 * C_DATA = 0x12345678, 
				 * C_PxCI = fw version 
				 */
	INTC_LINK   = 1,	/* Link state changed
				 * C_DATA = 0x0, LINKUP, PxSSTS valid,
				 * C_DATA = 0x1, LINKDOWN,
				 * C_DATA = other, is error handle by top
				 */
	INTC_REJECT = 2,	/* Command Finished with fatal error 
				 * C_DATA = 0x0, fsm not ready, C_PxCI = cmd header,
				 * C_DATA = 0x1, txdma error, C_SLOT = slot, C_PxCI = opt
				 * C_DATA = 0x2, rxdma error, C_SLOT = slot,
				 */
	INTC_RERR   = 3,	/* TX DATA FIS with RERR 
				 * C_SLOT = slot,
				 * C_DATA = err
				 */
	INTC_CRCERR = 4,	/* RX FIS with CRCERR
				 * C_DATA = 0, non data fis
				 * C_DATA = 1, data fis C_SLOT = slot,
				 */
	INTC_REGFIS = 5,	/* RX REGFIS 
				 * C_DATA = 0, no error, (valid PxTFD)
				 * C_DATA = 1, Taskfile error, (valid PxCI, PxTFD)
				 */
	INTC_SDBFIS = 6,	/* RX SDBFIS
				 * C_DATA = 0, no error (valid PxCI, PxSACT)
				 * C_DATA = 1, taskfile error, (valid PxCI)
				 * C_DATA = 2, Notification, (valid PxSACT)
				 */
	INTC_PIOSFIS= 7,	/* RX PIOFIS
				 * C_DATA = 0, no error (valid PxTFD)
				 * C_DATA = 1, erorr, (valid PxTFD);
				 * C_DATA = 2, error, (valid PxTFD);
				 */
	INTC_UFIS   = 8,	/* RX UFIS
				 * C_DATA = fis type 
				 */
	INTC_PANIC  = 9,	/* PANIC
				 * C_DATA = file 
				 * C_PxCI = line
				 */
	INTC_TRACE  = 0xa,

	C_DATA  = 0,
	C_PxCI  = 1,
	C_PxTFD = 2,
	C_PxSSTS= 3,
	C_PxSACT= 4,
	C_SLOT  = 5,
};

enum {
	_QHsmSata_top 	= 0,
	_do_port_idle 	= 1,
	_do_cfis_xmit 	= 2,
	_do_cfis_done 	= 3,
	_pio_done 	= 4,
	_pio_update 	= 5,
	_dr_done 	= 6,
	_hw_dispatch 	= 7,
};


#endif
