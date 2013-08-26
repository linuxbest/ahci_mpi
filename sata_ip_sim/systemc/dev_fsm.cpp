#include "dev_fsm.h"
#define OP1
#define OP2

static uint32_t tx_buffer[2049];
static int tx_buffer_len = 0;
static int tx_buffer_rd = 0;

static uint32_t rx_buffer[2049];
static int rx_buffer_len = 0;
static int rx_buffer_rd = 0;
static int      receive_start = 0;

static uint32_t dev_tx_buf[2049];
static int dev_tx_buf_len = 0;
static int dev_tx_rd_len = 0;

static uint32_t dev_rx_buf[2049];
static int dev_rx_buf_len = 0;
static uint32_t rx_data;

#include "scrambler.h"
#include "crc.h"
#include "dev_link.h"
void dev_fsm::sata_rx_buf(void)
{
}

void dev_fsm::sata_rx_fsm(void)
{
}

void dev_fsm::tb_main(void)
{
        int i = 0;  
/*----------- I hardware initialization --------------------------*/
        /* I.I init device interface */          
        dev_tx_data.write(SYNC_p);   
        dev_tx_charisk.write(1);   
	for (;;) {
		wait (dev_clk_75M->posedge_event());
		if(link_up.read() != 0) {
			printf("**************device is link up.**************\n");
			break;
		}
	}
        int k = 0;
#ifdef OP1
/*----------- II host send data -------------------------------*/
	send_failed = 0;
	send_success = 0;
	/*device prepare data*/
	dev_tx_buf_len = 0x100;
        dev_tx_buf[0] = 0x27 << 24 | dev_tx_buf_len;
	for (k = 1; k <= dev_tx_buf_len; k++)
		dev_tx_buf[k] = k;
	dev_tx_buf[dev_tx_buf_len + 1] = Sata_crc(dev_tx_buf, dev_tx_buf_len);
	Sata_scrambler(dev_tx_buf, dev_tx_buf_len + 1);
	wait (dev_clk_75M->posedge_event());   
	TL_send_FifoRdy = 1;
	dev_tx_rd_len = 0;
	wait (dev_clk_75M->posedge_event());   
	for (;;) {
		wait (dev_clk_75M->posedge_event());
		if(send_success == 1) {
			printf("**************device send data is successful.**************\n");
			break;
		} else if(send_failed == 1) {
			printf("**************device send data is failed.**************\n");
			break;
		}
	}
#endif
#ifdef OP2
	wait (dev_clk_75M->posedge_event());   
	TL_Rec_FifoRdy = 1;
	printf("**************Device Receive Fifo is OK.**************\n");
	for (;;) {
		wait (dev_clk_75M->posedge_event());
		if(dev_link_CRC_GOOD == 1) {
			printf("**************Device:Receive data CRC Good.**************\n");
			break;
		} else if(dev_link_CRC_ERR == 1) {
			printf("**************Device:Receive data CRC Bad.**************\n");
			break;
		}
	}
	int rx_len = 0;
	int err = 0;
	printf("Receive data length = %x\n", dev_rx_buf_len);
	rx_len = dev_rx_buf_len;
	for (k = 1; k < rx_len && k < 2048; k++) {
		printf("%d: %08x\n", k, dev_rx_buf[k]);
		if (dev_rx_buf[k] != k) {
			err = 1;
			printf("Device: Receive data %x != %x.----%d\n", dev_rx_buf[k], k, k);
		}
	}
	if (err == 0) {
		printf("Device: Receive data compare passed\n");
	} else {
		printf("Device: Receive data compare failed\n");
	}
	for (;;) {
		wait (dev_clk_75M->posedge_event());
		if(dev_link_CRC_GOOD == 1) {
			printf("**************Device:Receive data CRC Good.**************\n");
			break;
		} else if(dev_link_CRC_ERR == 1) {
			printf("**************Device:Receive data CRC Bad.**************\n");
			break;
		}
	}
	rx_len = 0;
	err = 0;
	printf("Receive data length = %x\n", dev_rx_buf_len);
	rx_len = dev_rx_buf_len;
	for (k = 1; k < rx_len && k < 2048; k++) {
		printf("%d: %08x\n", k, dev_rx_buf[k]);
		if (dev_rx_buf[k] != k) {
			err = 1;
			printf("Device: Receive data %x != %x.----%d\n", dev_rx_buf[k], k, k);
		}
	}
	if (err == 0) {
		printf("Device: Receive data compare passed\n");
	} else {
		printf("Device: Receive data compare failed\n");
	}

//	sc_stop();

#endif
#ifdef OP3
/*----------- II host send data -------------------------------*/
	send_failed = 0;
	send_success = 0;
	send_start = 0;
	/*device prepare data*/
	dev_tx_buf_len = 0xc00;
        dev_tx_buf[0] = 0x27 << 24 | dev_tx_buf_len;
	for (k = 1; k <= dev_tx_buf_len; k++)
		dev_tx_buf[k] = k;
	dev_tx_buf[dev_tx_buf_len + 1] = Sata_crc(dev_tx_buf, dev_tx_buf_len);
	Sata_scrambler(dev_tx_buf, dev_tx_buf_len + 1);
	wait (dev_clk_75M->posedge_event());   
	TL_send_FifoRdy = 1;
	dev_tx_rd_len = 0;
	wait (dev_clk_75M->posedge_event());   
	for (;;) {
		wait (dev_clk_75M->posedge_event());
		if(send_start == 1) {
			break;
		}
	}
	for (;;) {
		wait (dev_clk_75M->posedge_event());
		if(send_start == 1) {
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		TL_send_FifoRdy = (~TL_send_FifoRdy & 0x1) | (TL_send_FifoRdy & 0xFFFFFFFE);			
		printf("run here TL_send_FifoRdy = %x\n", TL_send_FifoRdy);
		} else {
			break;
		}
	}
	TL_send_FifoRdy = 1;			
	for (;;) {
		wait (dev_clk_75M->posedge_event());
		if(send_success == 1) {
			printf("**************device send data is successful.**************\n");
			break;
		} else if(send_failed == 1) {
			printf("**************device send data is failed.**************\n");
			break;
		}
	}
#endif
#ifdef OP4
	wait (dev_clk_75M->posedge_event());   
	Receive_start = 0;
	TL_Rec_FifoRdy = 1;
	printf("**************Device Receive Fifo is OK.**************\n");
	for (;;) {
		wait (dev_clk_75M->posedge_event());
		if(Receive_start == 1) {
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		wait (dev_clk_75M->posedge_event());
		TL_Rec_FifoRdy = (~TL_Rec_FifoRdy & 0x1) | (TL_Rec_FifoRdy & 0xFFFFFFFE);			
		printf("run here TL_Rec_FifoRdy = %x\n", TL_Rec_FifoRdy);
		} else {
			break;
		}
	}
	TL_Rec_FifoRdy = 1;

	for (;;) {
		wait (dev_clk_75M->posedge_event());
		if(dev_link_CRC_GOOD == 1) {
			printf("**************Device:Receive data CRC Good.**************\n");
			break;
		} else if(dev_link_CRC_ERR == 1) {
			printf("**************Device:Receive data CRC Bad.**************\n");
			break;
		}
	}
	int rx_len = 0;
	int err = 0;
	printf("Receive data length = %x\n", dev_rx_buf[0]);
	rx_len = dev_rx_buf[0];
	for (k = 1; k < rx_len; k++) {
		if (dev_rx_buf[k] != k) {
			err = 1;
			printf("Device: Receive data %x != %x.----%d\n", dev_rx_buf[k], k, k);
		}
	}
	if (err == 0) {
		printf("Device: Receive data compare passed\n");
	} else {
		printf("Device: Receive data compare failed\n");
	}
//	sc_stop();

#endif

}

SC_MODULE_EXPORT(dev_fsm);
