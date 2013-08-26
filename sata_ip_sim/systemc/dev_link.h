int TL_send_FifoRdy = 0;
int TL_Rec_FifoRdy = 0;
int TL_indicate_ERR = 0;
int TL_indicate_Good = 1;
int TL_Escape = 0;
int dev_link_CRC_ERR = 0;
int dev_link_CRC_GOOD = 0;
int send_success = 0;
int send_failed = 0;
int send_start = 0;
int send_DMAT = 0;
int Receive_start = 0;

typedef enum {
	SATA_E_STATE_ENTER = 0x10000,
 
	SATA_E_STATE_TPM_PHYRDY,
	SATA_E_PMOFF,
	SATA_E_PMDENY,
	SATA_E_PHYRDYn,

	SATA_E_LRESET,
	SATA_E_PrimtR_RDY = R_RDY_p,
	SATA_E_PrimtX_RDY = X_RDY_p,
	SATA_E_Primt_SYNC = SYNC_p,
	SATA_E_Primt_HOLD = HOLD_p,
	SATA_E_Primt_DMAT = DMAT_p,
	SATA_E_PrimtR_OK  = R_OK_p,
	SATA_E_PrimtR_ERR = R_ERR_p,
	SATA_E_Primt_SOF  = SOF_p,
	SATA_E_Primt_EOF  = EOF_p,
	SATA_E_Primt_WTRM = WTRM_p,
	SATA_E_CRCgood,
	SATA_E_CRCbad,
	SATA_E_TL_Escape,
	SATA_TL_Rec_FifoRdyn,
	SATA_TL_send_FifoRdyn,
	SATA_E_TL_ERR,
	SATA_E_TL_Good,

} SaEvent_e;

typedef void *(SaStateFunc_t)(SaEvent_e Event);

static void SataLinkStateMachine(SaEvent_e Event);
static void *SataLIdle(SaEvent_e Event);
static void *SataLSyncEscape(SaEvent_e Event);
static void *SataLNoCommErr(SaEvent_e Event);
static void *SataLNoComm(SaEvent_e Event);
static void *SataLSendAlign(SaEvent_e Event);
static void *SataLReset(SaEvent_e Event);

static void *SataHLSendChkRdy(SaEvent_e Event);
static void *SataDLSendchkRdy(SaEvent_e Event);
static void *SataLSendSOF(SaEvent_e Event);
static void *SataLSendData(SaEvent_e Event);
static void *SataLRecvrHold(SaEvent_e Event);
static void *SataLSendHold(SaEvent_e Event);
static void *SataLSendCRC(SaEvent_e Event);
static void *SataLSendEOF(SaEvent_e Event);
static void *SataLWait(SaEvent_e Event);

static void *SataLRecvChkRdy(SaEvent_e Event);
static void *SataLRecvWaitFifo(SaEvent_e Event);
static void *SataLRecvData(SaEvent_e Event);
static void *SataLHold(SaEvent_e Event);
static void *SataLRecvHold(SaEvent_e Event);
static void *SataLRecvEOF(SaEvent_e Event);
static void *SataLGoodCRC(SaEvent_e Event);
static void *SataLGoodEnd(SaEvent_e Event);
static void *SataLBadEnd(SaEvent_e Event);

uint32_t dev_prim_tx = SYNC_p;
uint32_t dev_data_tx;
SaStateFunc_t *SataState = SataLIdle;

static void SataLinkStateMachine(SaEvent_e Event)
{
	void *retPtr;

	retPtr = (void *)SataState;
	while (retPtr != NULL) {

		retPtr = SataState(Event);
		if (retPtr != NULL)  {
			SataState = (SaStateFunc_t *)retPtr;
			Event = SATA_E_STATE_ENTER;
		}
	}
}

static void *SataLIdle(SaEvent_e Event)
{
//	printf("%s Event %x\n", __func__,  Event);
	if (TL_send_FifoRdy)
		Event = SATA_TL_send_FifoRdyn;

	switch (Event) {
	case SATA_E_STATE_ENTER: 
		dev_prim_tx = SYNC_p;
		return (void *)NULL;  /* TODO */
	case SATA_TL_send_FifoRdyn:
		return (void *)SataDLSendchkRdy;
	case SATA_E_STATE_TPM_PHYRDY: /* TODO */
		return (void *)NULL;
	case SATA_E_PrimtX_RDY:
		return (void *)SataLRecvWaitFifo;
	case SATA_E_PMOFF:
		return (void *)NULL; /* TODO */
	case SATA_E_PMDENY:
		return (void *)NULL; /* TODO */
	case SATA_E_PHYRDYn:
		return (void *)SataLNoCommErr;
	default:
		return (void *)NULL;
	}
}

static void *SataLSyncEscape(SaEvent_e Event)
{
//	printf("%s Event %x\n", __func__,  Event);

	switch (Event) {
	case SATA_E_STATE_ENTER:
		dev_prim_tx = SYNC_p;
		return (void *)NULL;
	case SATA_E_PrimtX_RDY:
		return (void *)SataLIdle;
	case SATA_E_Primt_SYNC:
		return (void *)SataLIdle;
	case SATA_E_PHYRDYn:
		return (void *)SataLNoCommErr;
	default:
		return (void *)NULL;
	}
}

static void *SataLNoCommErr(SaEvent_e Event)
{
	printf("PHY NOT LINK %s Event %x\n", __func__,  Event);

	switch (Event) {
	case SATA_E_STATE_ENTER:
		dev_prim_tx = SYNC_p;
		return (void *)NULL;  /* TODO */
	default:
		return (void *)SataLNoComm;
	}
}

static void *SataLNoComm(SaEvent_e Event)
{
//	printf("%s Event %x\n", __func__,  Event);

	switch (Event) {
	case SATA_E_STATE_ENTER:
		dev_prim_tx = ALIGN_p;
		return (void *)NULL;  /* TODO */
	case SATA_E_PHYRDYn:
		return (void *)NULL;  /* TODO */
	default:
		return (void *)SataLSendAlign;
	}
}

static void *SataLSendAlign(SaEvent_e Event)
{
//	printf("%s Event %x\n", __func__,  Event);

	switch (Event) {
	case SATA_E_STATE_ENTER:
		dev_prim_tx = ALIGN_p;
		return (void *)NULL;  /* TODO */
	case SATA_E_PHYRDYn:
		return (void *)SataLNoCommErr;
	default:
	//	return (void *)NULL;
		return (void *)SataLIdle;
	}
}

static void *SataLReset(SaEvent_e Event)
{
//	printf("%s Event %x\n", __func__,  Event);
	switch (Event) {
	case SATA_E_STATE_ENTER:
		return (void *)NULL;  /* TODO */
	case SATA_E_LRESET:
		return (void *)SataLNoComm;
	default:
		return (void *)NULL;
	}
}

static void *SataHLSendChkRdy(SaEvent_e Event)
{
//	printf("%s Event %x\n", __func__,  Event);

	switch (Event) {
	case SATA_E_STATE_ENTER:
		dev_prim_tx = X_RDY_p;
		return (void *)NULL;  /* TODO */
	case SATA_E_PrimtR_RDY:
		return (void *)SataLSendSOF;
	case SATA_E_PrimtX_RDY:
		return (void *)SataLRecvWaitFifo;
	case SATA_E_PHYRDYn:
		return (void *)SataLNoCommErr;
	default:
		return (void *)NULL;
	}
}

static void *SataDLSendchkRdy(SaEvent_e Event)
{
//	printf("%s Event %x\n", __func__,  Event);

	switch (Event) {
	case SATA_E_STATE_ENTER:
		dev_prim_tx = X_RDY_p;
		return (void *)NULL;  /* TODO */
	case SATA_E_PrimtR_RDY:
		return (void *)SataLSendSOF;
	case SATA_E_PHYRDYn:
		return (void *)SataLNoCommErr;
	default:
		return (void *)NULL;
	}
}

static void *SataLSendSOF(SaEvent_e Event)
{
//	printf("%s Event %x\n", __func__,  Event);

	switch (Event) {
	case SATA_E_STATE_ENTER:
		dev_prim_tx = SOF_p;
		return (void *)NULL;  /* TODO */
	case SATA_E_PHYRDYn:
		return (void *)SataLNoCommErr;
	case SATA_E_Primt_SYNC:
		return (void *)SataLIdle;
	default:
		return (void *)SataLSendData;
	}
}

static void *SataLSendData(SaEvent_e Event)
{
//	printf("%s Event %x\n", __func__,  Event);
	if(TL_send_FifoRdy == 0) 
		Event = SATA_TL_send_FifoRdyn;
	else if(dev_tx_rd_len == dev_tx_buf_len + 1)   //must be sure dev_tx_buf_len != 0 
		Event = SATA_E_Primt_DMAT;
	else { 
		dev_data_tx = dev_tx_buf[dev_tx_rd_len];
		dev_tx_rd_len++;
	}
	
	switch (Event) {
	case SATA_E_STATE_ENTER:
		send_start = 1;
		return (void *)NULL;  /* TODO */
	case SATA_E_Primt_HOLD:
		dev_tx_rd_len--;
		return (void *)SataLRecvrHold;
	case SATA_TL_send_FifoRdyn:
		return (void *)SataLSendHold;
	case SATA_E_Primt_DMAT:
		send_start = 0;
		return (void *)SataLSendCRC;
	case SATA_E_PHYRDYn:
		return (void *)SataLNoCommErr;
	case SATA_E_Primt_SYNC:
		send_start = 0;
		return (void *)SataLIdle;
	case SATA_E_TL_Escape:
		send_start = 0;
		return (void *)SataLSyncEscape;
	default:
		return (void *)NULL;		
	}
}

static void *SataLRecvrHold(SaEvent_e Event)
{
//	printf("%s Event %x\n", __func__,  Event);
	switch (Event) {
	case SATA_E_STATE_ENTER:
		dev_prim_tx = HOLDA_p;
		return (void *)NULL;  /* TODO */
	case SATA_E_Primt_HOLD:
		return (void *)NULL;
	case SATA_E_Primt_DMAT:
		return (void *)SataLSendCRC;
	case SATA_E_PHYRDYn:
		return (void *)SataLNoCommErr;
	case SATA_E_Primt_SYNC:
		return (void *)SataLIdle;
	case SATA_E_TL_Escape:
		return (void *)SataLSyncEscape;
	default:
		return (void *)SataLSendData;
	}
}

static void *SataLSendHold(SaEvent_e Event)
{
//	printf("%s Event %x\n", __func__,  Event);

	switch (Event) {
	case SATA_E_STATE_ENTER:
		dev_prim_tx = HOLD_p;
		if(TL_send_FifoRdy == 0) { 
			Event = SATA_TL_send_FifoRdyn;
		}
		return (void *)NULL;  /* TODO */
	case SATA_E_Primt_HOLD:
		return (void *)SataLRecvrHold;
	case SATA_TL_send_FifoRdyn:
		return (void *)NULL;
	case SATA_E_Primt_DMAT:
		return (void *)SataLSendCRC;
	case SATA_E_PHYRDYn:
		return (void *)SataLNoCommErr;
	case SATA_E_Primt_SYNC:
		return (void *)SataLIdle;
	default:
		return (void *)SataLSendData;
	}
}

static void *SataLSendCRC(SaEvent_e Event)
{
//	printf("%s Event %x\n", __func__,  Event);
	dev_data_tx = dev_tx_buf[dev_tx_rd_len];
	dev_tx_rd_len++;

	switch (Event) {
	case SATA_E_STATE_ENTER:
		return (void *)NULL;  /* TODO */
	case SATA_E_PHYRDYn:
		return (void *)SataLNoCommErr;
	case SATA_E_Primt_SYNC:
		return (void *)SataLIdle;
	default:
		return (void *)SataLSendEOF;
	}
}

static void *SataLSendEOF(SaEvent_e Event)
{
//	printf("%s Event %x\n", __func__,  Event);
	switch (Event) {
	case SATA_E_STATE_ENTER:
		dev_prim_tx = EOF_p;
		return (void *)NULL;  /* TODO */
	case SATA_E_Primt_SYNC:
		return (void *)SataLIdle;
	case SATA_E_PHYRDYn:
		return (void *)SataLNoCommErr;
	default:
		return (void *)SataLWait;
	}
}

static void *SataLWait(SaEvent_e Event)
{
//	printf("%s Event %x\n", __func__,  Event);
	switch (Event) {
	case SATA_E_STATE_ENTER:
		dev_prim_tx = WTRM_p;
		return (void *)NULL;  /* TODO */
	case SATA_E_PrimtR_OK:
		send_success = 1;
		return (void *)SataLIdle;
	case SATA_E_PrimtR_ERR:
		send_failed = 1;
		return (void *)SataLIdle;
	case SATA_E_Primt_SYNC:
		return (void *)SataLIdle;
	case SATA_E_PHYRDYn:
		return (void *)SataLNoCommErr;
	default:
		return (void *)NULL;
	}
}

static void *SataLRecvChkRdy(SaEvent_e Event)
{
//	printf("%s Event %x\n", __func__,  Event);

	switch (Event) {
	case SATA_E_STATE_ENTER:
		dev_prim_tx = R_RDY_p;
		return (void *)NULL;  /* TODO */
	case SATA_E_PrimtX_RDY:
		return (void *)NULL;
	case SATA_E_Primt_SOF:
		return (void *)SataLRecvData;
	case SATA_E_PHYRDYn:
		return (void *)SataLNoCommErr;
	default:
		return (void *)SataLIdle;
	}
}

static void *SataLRecvWaitFifo(SaEvent_e Event)
{
//	printf("%s Event %x\n", __func__,  Event);

	if (TL_Rec_FifoRdy == 0)	
		Event = SATA_TL_Rec_FifoRdyn;

	switch (Event) {
	case SATA_E_STATE_ENTER:
		dev_rx_buf_len = 0;
		dev_prim_tx = SYNC_p;
		return (void *)NULL;  /* TODO */
	case SATA_TL_Rec_FifoRdyn:
		return (void *)NULL;
	case SATA_E_PrimtX_RDY:
		return (void *)SataLRecvChkRdy;
	case SATA_E_PHYRDYn:
		return (void *)SataLNoCommErr;
	default:
		return (void *)SataLIdle;
	}
}

static void *SataLRecvData(SaEvent_e Event)
{
//	printf("%s Event %x\n", __func__,  Event);
	if (TL_Rec_FifoRdy == 0) {	
		printf("**********FIFO FULL = %d\n", TL_Rec_FifoRdy);
		Event = SATA_TL_Rec_FifoRdyn;
	}

	switch (Event) {
	case SATA_E_STATE_ENTER:
		if (send_DMAT == 1) {
		dev_prim_tx = DMAT_p;
		} else {
		dev_prim_tx = R_IP_p;
		}
		Receive_start = 1;
		return (void *)NULL;  /* TODO */
	case SATA_TL_Rec_FifoRdyn:
		return (void *)SataLHold;
	case SATA_E_Primt_HOLD:
		return (void *)SataLRecvHold;
	case SATA_E_Primt_EOF:
		Receive_start = 0;
		return (void *)SataLRecvEOF;
	case SATA_E_Primt_WTRM:
		Receive_start = 0;
		return (void *)SataLBadEnd;
	case SATA_E_Primt_SYNC:
		Receive_start = 0;
		return (void *)SataLIdle;
	case SATA_E_PHYRDYn:
		Receive_start = 0;
		return (void *)SataLNoCommErr;
	case SATA_E_TL_Escape:
		Receive_start = 0;
		return (void *)SataLSyncEscape;
	default:
		if (send_DMAT == 1) {
		dev_prim_tx = DMAT_p;
		} 
		return (void *)NULL;
	}
}

static void *SataLHold(SaEvent_e Event)
{
//	printf("%s Event %x\n", __func__,  Event);

	switch (Event) {
	case SATA_E_STATE_ENTER:
		dev_prim_tx = HOLD_p;
		return (void *)NULL;  /* TODO */
	if (TL_Rec_FifoRdy == 0)	
		Event = SATA_TL_Rec_FifoRdyn;
	case SATA_E_Primt_HOLD:
		return (void *)SataLRecvHold;
	case SATA_TL_Rec_FifoRdyn:
		return (void *)NULL;
	case SATA_E_Primt_EOF:
		return (void *)SataLRecvEOF;
	case SATA_E_Primt_SYNC:
		return (void *)SataLIdle;
	case SATA_E_PHYRDYn:
		return (void *)SataLNoCommErr;
	case SATA_E_TL_Escape:
		return (void *)SataLSyncEscape;
	default:
		return (void *)SataLRecvData;
	}
}

static void *SataLRecvHold(SaEvent_e Event)
{
//	printf("%s Event %x\n", __func__,  Event);

	switch (Event) {
	case SATA_E_STATE_ENTER:
		dev_prim_tx = HOLDA_p;
		return (void *)NULL;  /* TODO */
	case SATA_E_Primt_HOLD:
		return (void *)NULL;
	case SATA_E_Primt_EOF:
		return (void *)SataLRecvEOF;
	case SATA_E_Primt_SYNC:
		return (void *)SataLIdle;
	case SATA_E_PHYRDYn:
		return (void *)SataLNoCommErr;
	case SATA_E_TL_Escape:
		return (void *)SataLSyncEscape;
	default:
		return (void *)SataLRecvData;
	}
}

static void *SataLRecvEOF(SaEvent_e Event)
{
//	printf("%s Event %x\n", __func__,  Event);
	if (dev_link_CRC_GOOD == 1)
		Event = SATA_E_CRCgood;
	else if (dev_link_CRC_ERR == 1)
		Event = SATA_E_CRCbad;

	switch (Event) {
	case SATA_E_STATE_ENTER:
		dev_prim_tx = R_IP_p;
		return (void *)NULL;  /* TODO */
	case SATA_E_CRCgood:
		return (void *)SataLGoodCRC;
	case SATA_E_CRCbad:
		return (void *)SataLBadEnd;
	case SATA_E_PHYRDYn:
		return (void *)SataLNoCommErr;
	default:
		return (void *)NULL;
	}
}

static void *SataLGoodCRC(SaEvent_e Event)
{
//	printf("%s Event %x\n", __func__,  Event);
	if (TL_indicate_ERR == 1)
		Event = SATA_E_TL_ERR;
	else if (TL_indicate_Good == 1)
		Event = SATA_E_TL_Good;

	switch (Event) {
	case SATA_E_STATE_ENTER:
		dev_prim_tx = R_IP_p;
		return (void *)NULL;  /* TODO */
	case SATA_E_TL_ERR:
		return (void *)SataLBadEnd;
	case SATA_E_TL_Good:
		return (void *)SataLGoodEnd;
	case SATA_E_PHYRDYn:
		return (void *)SataLNoCommErr;
	default:
		return (void *)NULL;
	}
}

static void *SataLGoodEnd(SaEvent_e Event)
{
//	printf("%s Event %x\n", __func__,  Event);

	switch (Event) {
	case SATA_E_STATE_ENTER:
		dev_prim_tx = R_OK_p;
		return (void *)NULL;  /* TODO */
	case SATA_E_Primt_SYNC:
		return (void *)SataLIdle;
	case SATA_E_PHYRDYn:
		return (void *)SataLNoCommErr;
	default:
		return (void *)NULL;
	}
}

static void *SataLBadEnd(SaEvent_e Event)
{
//	printf("%s Event %x\n", __func__,  Event);

	switch (Event) {
	case SATA_E_STATE_ENTER:
		dev_prim_tx = R_ERR_p;
		return (void *)NULL;  /* TODO */
	case SATA_E_Primt_SYNC:
		return (void *)SataLIdle;
	case SATA_E_PHYRDYn:
		return (void *)SataLNoCommErr;
	default:
		return (void *)NULL;
	}
}

/********************************************************************/
void dev_fsm::sata_dev_rx()
{
	uint32_t prim;
	int TL_Escape = 0;
	if (link_up.read() == 0) {
		prim = SATA_E_PHYRDYn;
		/*printf("link up down\n");*/
	}
	else if (TL_Escape == 1)
		prim = SATA_E_TL_Escape;
	else if (dev_rx_charisk.read() != 0) {
		prim = dev_rx_data.read();
	} else if (dev_rx_charisk.read() == 0) {
	}
	
	SataLinkStateMachine((SaEvent_e)prim);
}

void dev_fsm::sata_dev_state()
{
	if (SataState == SataLRecvEOF) {
		dev_rx_buf_len -= 1;
		Sata_scrambler(dev_rx_buf, dev_rx_buf_len);
		printf("**************state is EOF.**************\n");
		printf("**************dev_rx_buf_len = %d.**************\n", dev_rx_buf_len);
		if(dev_rx_buf[dev_rx_buf_len] == Sata_crc(dev_rx_buf, dev_rx_buf_len - 1))
			dev_link_CRC_GOOD = 1;
		else
			dev_link_CRC_ERR = 1;
		sata_rx_buf();
	}
	else if (SataState == SataLRecvData ||
			 SataState == SataLHold ||
				SataState == SataLRecvHold) {
		if (dev_rx_charisk.read() == 0) {
			rx_data = dev_rx_data.read();
			dev_rx_buf[dev_rx_buf_len] = rx_data; 
			printf("receive data = 0x%x  dev_rx_buf_len = %d\n", dev_rx_buf[dev_rx_buf_len], dev_rx_buf_len);
			dev_rx_buf_len++;
//			if (dev_rx_buf_len == 5) {
//				send_DMAT = 1;
//			}
		}
		dev_link_CRC_ERR = 0;
		dev_link_CRC_GOOD = 0;
	}
	else if (SataState == SataLWait) {
		TL_send_FifoRdy = 0;
	}
	else if (SataState == SataLRecvEOF) {
		send_DMAT = 0;
	}
}

void dev_fsm::sata_dev_tx()
{
	if (SataState == SataLSendData || SataState == SataLSendCRC) {
		dev_tx_data.write(dev_data_tx);    
		dev_tx_charisk.write(0);
//		printf("**************send data**************\n");
//		printf("send data = 0x%x\n", dev_data_tx);
	} else {
		dev_tx_data.write(dev_prim_tx);    //device send X_RDY
//		printf("**************send prim**************\n");
		dev_tx_charisk.write(1);
	}
}
