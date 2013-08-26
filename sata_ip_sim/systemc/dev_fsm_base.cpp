#include "dev_fsm.h"
#include "ahci_api.h"

#define OP1
#define OP2

static uint32_t tx_buffer[4049];
static int tx_buffer_len = 0;
static int tx_buffer_rd = 0;

static uint32_t rx_buffer[4049];
static int rx_buffer_len = 0;
static int rx_buffer_rd = 0;
static int      receive_start = 0;

static uint32_t dev_tx_kbuf[4049];
static uint32_t dev_tx_buf[4049];
static int dev_tx_buf_len = 0;
static int dev_tx_rd_len = 0;

static uint32_t dev_rx_buf[4049];
static int dev_rx_buf_len = 0;
static uint32_t rx_data;

static uint32_t sata_dev_tx_raw = 0;
static uint32_t sata_dev_tx_cur = 0;

#include "scrambler.h"
#include "crc.h"
#include "dev_link.h"
#include "linuxlist.h"

void dev_fsm::sata_rx_fsm(void)
{
}

enum {
	NON_DATA, 
	/* Sending Status */
	PIO_DIN,  
	/* Sending PIO Setup FIS, Sending Data Fis, Sending R2D */
	PIO_DOUT,
	/* Sending PIO Setup FIS, Receive Data Fis, Sending R2D */
	DMA_DIN,
	/* Sending Data Fis, Sending R2D */
	DMA_DOUT,
	/* Sending DMA Active FIS,Receive Data Fis, Sending R2D */
	PACKET, /* unsupport */
	READ_DMAQ, /* support */
	WRITE_DMAQ,/* support */
	FPDMA_Q, /* must support */
};

static int send_sig = 0;

typedef struct {
	uint32_t buf[2050];
	uint32_t kbuf[2050];
	uint32_t blen;
	uint32_t wait;
	uint32_t raw;
	struct llist_head entry;
} dev_buf_t;

static LLIST_HEAD(dev_buf_head);

static dev_buf_t *dev_buf_alloc(void)
{
	dev_buf_t *t = (dev_buf_t *)malloc(sizeof(*t));
	t->wait = 0;
	t->raw  = 0;
	return t;
}

static uint32_t EndianSwap32(uint32_t Source)
{
	uint16_t LoWord = (uint16_t) ( Source & 0x0000FFFF);
	uint16_t HiWord = (uint16_t) ((Source & 0xFFFF0000) >> 16);
	/* byte swap each of the 16 bit half words */
	LoWord = (((LoWord & 0xFF00) >> 8) | ((LoWord & 0x00FF) << 8));
	HiWord = (((HiWord & 0xFF00) >> 8) | ((HiWord & 0x00FF) << 8));
	return (uint32_t) ((LoWord << 16) | HiWord);
}

static void dev_buf_send(dev_buf_t *t, uint32_t *obuf, uint32_t *kbuf)
{
	int i;
	for (i = 0; i < t->blen; i ++) {
		obuf[i] = t->buf[i];
		kbuf[i] = t->kbuf[i];
	}
	llist_del(&t->entry);
	free(t);
}

struct dev_queue {
	struct llist_head head;
	uint32_t blen;
} dev_queue[32];

static void dev_buf_queue(dev_buf_t *t, int tag, int blen)
{
	struct dev_queue *q;

	if (tag != -1) {
		q = &dev_queue[tag];

		q->blen = blen;
		llist_add_tail(&t->entry, &q->head);
	} else {
		llist_add_tail(&t->entry, &dev_buf_head);
	}
}

void dev_fsm::sata_rx_buf(void)
{
	int i = 0;
	uint32_t *dw = dev_rx_buf, cmd;
	static uint32_t blen = 0;
	static uint32_t ncq  = 0;
	static uint32_t tag  = 0;
	fprintf(tfile, "DEV_FSM: sata_rx_buf: enter, good crc %d/%d\n", 
			dev_link_CRC_GOOD, dev_link_CRC_ERR);
	for (i = 0; i < dev_rx_buf_len; i ++) {
		dev_rx_buf[i] = /*EndianSwap32*/(dev_rx_buf[i]);
		fprintf(tfile, "DEV_FSM: %d: %08x\n", i, dev_rx_buf[i]);
	}

	cmd = dw[0] & 0xff;
	fprintf(tfile, "DEV_FSM: FIS Type: %02x\n", cmd);
	if ((dw[0]&0x8000) == 0 && 
	    (dw[3]&0x40000000) == 0x0 &&
	    cmd == 0) {
		send_sig = 1;
		fprintf(tfile, "DEV_FSM: SRST\n");
		return;
	}
	switch (cmd) {
	case 0x27: /* H2D */
		cmd = (dw[0] >> 16) & 0xff;
		fprintf(tfile, "DEV_FSM: FIS CMD: %02x\n", cmd);
		if (cmd == 0x61) {       /* Write FPDMA */
			ncq = 1;
			blen       = (dw[0] >> 24) * 512;
			tag        = dw[3]>>3;
			int pmp    = (dw[0]>>8) & 0xf;
			fprintf(tfile, "DEV_FSM: Write FPDMA: %08x, tag %08x, blen %08x, pmp %x\n", 
					cmd, tag, blen, pmp);
			/* 1) Transmit DMA Setup  */
			/* 2) Transmit DMA Active */
			/* 3) Receive data        */
			/* 4) Send status         */
			dev_buf_t *t = dev_buf_alloc();
			t->buf[0]    = 0x00500034 | (pmp<<8); /* Register Device to host */
			t->buf[1]    = 0x00000000;
			t->buf[2]    = 0x00000000;
			t->buf[3]    = 0x00000000;
			t->buf[4]    = 0x00000000;
			t->blen      = 5;
			t->wait      = 100;
			dev_buf_queue(t, -1, 0);
			/* DMA setup */
			t = dev_buf_alloc();
			t->buf[0]  = 0x00000041 | (pmp<<8); /* Device to host */
			t->buf[1]  = tag;        /* TAG */
			t->buf[2]  = 0x00000000;
			t->buf[3]  = 0x00000000;
			t->buf[4]  = 0x00000000; /* DMA buffer offset */
			t->buf[5]  = blen;       /* DMA transfer count */
			t->buf[6]  = 0x00000000;
			t->blen    = 7;
			dev_buf_queue(t, -1, 0);
			//int len = blen;
			//do { /* we assue the 8192 per DmaAct */
				t = dev_buf_alloc();
				t->buf[0]  = 0x00000039 | (pmp<<8); /* A */
				t->blen    = 1;
				dev_buf_queue(t, tag, 0);
			//	len -= 8192;
			//} while (len > 0);
		} else if (cmd == 0x60) {/* Read  FPDMA */ 
			blen       = (dw[0] >> 24) * 512;
			tag        = dw[3]>>3;
			int pmp    = (dw[0] >> 8) & 0xf;
			fprintf(tfile, "DEV_FSM: READ FPDMA: %08x, tag %08x, blen %08x, pmp %x\n", 
					cmd, tag, blen, pmp);
			/* 1) Transmit R2H        */
			/* 1) Transmit DMA setup  */
			/* 2) Transmit data       */
			/* 3) Send Status         */
			dev_buf_t *t = dev_buf_alloc();
			t->buf[0]    = 0x00500034 | (pmp<<8); /* Register Device to host & with PM 3*/
			t->buf[1]    = 0x00000000;
			t->buf[2]    = 0x00000000;
			t->buf[3]    = 0x00000000;
			t->buf[4]    = 0x00000000;
			t->blen      = 5;
			dev_buf_queue(t, -1, blen);
			/* DMA setup */
			t = dev_buf_alloc();
			t->buf[0]  = 0x0000A041 | (pmp<<8); /* A & Device to host & with PM 3*/
			t->buf[1]  = dw[3]>>3;   /* TAG */
			t->buf[2]  = 0x00000000;
			t->buf[3]  = 0x00000000;
			t->buf[4]  = 0x00000000; /* DMA buffer offset */
			t->buf[5]  = blen;       /* DMA transfer count */
			t->buf[6]  = 0x00000000;
			t->blen    = 7;
			dev_buf_queue(t, -1, blen);
			/* Data */	
			uint32_t len = blen;
			uint32_t seq = (tag+1) << 24;
			do {
				dev_buf_t *t = dev_buf_alloc();
				uint32_t block, idx = 0, max = 8192;
				block = len > max? max: len;
				t->buf[0]    = 0x00000046 | (pmp<<8); /* DATA */
				for (i = 0; i < block/4; i ++, seq ++)
					t->buf[i+1] = seq;
				t->blen      = block/4 + 1;
				fprintf(tfile, "DEV_FSM: read dma exit: xmit %d, %d\n",
						len, block);
				dev_buf_queue(t, -1, 0);
				len -= block;
				idx ++;
			} while (len > 0);
			/* 2) Transmit Status     */
			t = dev_buf_alloc();
			t->buf[0]  = 0x000040A1 | (pmp << 8);
			t->buf[1]  = 1<<(dw[3]>>3);
			t->blen    = 2;
			dev_buf_queue(t, -1, blen);
		} else if (cmd == 0xec) {/* Identify command */
			/* 1) Transmit PIO setup  */
			dev_buf_t *t = dev_buf_alloc();
			t->buf[0]  = 0x0058605F; /* Device to host Ibit */
			t->buf[1]  = 0xA0000000;
			t->buf[2]  = 0x00000000;
			t->buf[3]  = 0xD0000000;
			t->buf[4]  = 512;
			t->blen    = 5;
			dev_buf_queue(t, -1, 0);
			/* 2) Transmit data       */
			t = dev_buf_alloc();
			uint32_t *p = &t->buf[1];
			t->buf[0]   = 0x00000046;
			for (i = 0; i < 512/4; i ++, p++)
				*p = i;
			t->blen    = 512/4 + 1;
			dev_buf_queue(t, -1, 0);
			/* 3) Send Status         */
			t = dev_buf_alloc();
			t->buf[0]    = 0x0050E034; /* Ibit set */
			t->buf[1]    = 0xE0000000;
			t->buf[2]    = 0x00000000;
			t->buf[3]    = 0x00000000;
			t->buf[4]    = 0x00000000;
			t->blen      = 5;
			dev_buf_queue(t, -1, 0);
		} else if (cmd == 0x30) {/* PIO WRITE */
			/* 1) Transmit PIO setup  */
			blen       = dw[3] * 512;
			dev_buf_t *t = dev_buf_alloc();
			t->buf[0]  = 0x0000005F; /* host to device */
			t->buf[1]  = 0x40000001;
			t->buf[2]  = 0x00000000;
			t->buf[3]  = 0xD0000001;
			t->buf[4]  = blen;
			t->blen    = 5;
			dev_buf_queue(t, -1, 0);
			fprintf(tfile, "DEV_FSM: blen %08d\n", blen);
		} else if (cmd == 0x25) {/* read  dma ext */
			uint32_t len;
			uint32_t seq = 0;
			/* 1) Transmit data       */
			blen       = dw[3] * 512;
			/* 2) Transmit Status     */
			len = blen;
			do {
				dev_buf_t *t = dev_buf_alloc();
				uint32_t block, idx = 0, max = 8192;
				block = len > max? max: len;
				t->buf[0]    = 0x00000046; /* DATA */
				for (i = 0; i < block/4; i ++, seq ++)
					t->buf[i+1] = seq;
				t->blen      = block/4 + 1;
				fprintf(tfile, "DEV_FSM: read dma exit: xmit %d, %d\n",
						len, block);
				dev_buf_queue(t, -1, 0);
				len -= block;
				idx ++;
			} while (len > 0);

			dev_buf_t *t = dev_buf_alloc();
			t->buf[0]    = 0x00506034;
			t->buf[1]    = 0xE0000000;
			t->buf[2]    = 0x00000000;
			t->buf[3]    = 0x00000000;
			t->buf[4]    = 0x00000000;
			t->blen      = 5;
			dev_buf_queue(t, -1, 0);
		} else if (cmd == 0x35) {/* write dma ext */
			blen = dw[3] * 512;
			fprintf(tfile, "DEV_FSM: blen %08d\n", blen);
			/* 1) Transmit DMA Active */
			dev_buf_t *t = dev_buf_alloc();
			t->buf[0]  = 0x00000039; /* A */
			t->blen    = 1;
			dev_buf_queue(t, -1, 0);
			fprintf(tfile, "DEV_FSM: trasnmit DMA Active\n");
			/* 2) Received data       */
			/* 3) Send Status         */
		}
		break;
	case 0x34: /* D2H */
		break;
	case 0x39: /* DMA Activate */
		break;
	case 0x41: /* DMA Setup */
		break;
	case 0x46: /* Data */
		fprintf(tfile, "DEV_FSM: Data blen %d, %d\n", blen, dev_rx_buf_len);
		blen = blen - (dev_rx_buf_len-1)*4;
		if (blen == 0 && ncq == 0) {
			dev_buf_t *t = dev_buf_alloc();
			t->buf[0]    = 0x00506034;
			t->buf[1]    = 0xE0000000;
			t->buf[2]    = 0x00000000;
			t->buf[3]    = 0x00000000;
			t->buf[4]    = 0x00000000;
			t->blen      = 5;
			dev_buf_queue(t, -1, 0);
		} else if (blen == 0 && ncq == 1) {
			dev_buf_t *t = dev_buf_alloc();
#if 1
			t->buf[0]    = 0x000040A1;
			t->buf[1]    = 1<<tag;
			t->blen      = 2;
#else 
			t->buf[0]  = 0xc292362c;
			t->kbuf[0] = 0;
			t->buf[1]  = 0x1f26b369;
			t->kbuf[1] = 0;
			t->buf[2]  = ALIGN_p;
			t->kbuf[2] = 1;
			t->buf[3]  = 0xc2d2a2fe;
			t->kbuf[3] = 0;

			t->raw     = 1;
			t->blen    = 4;
#endif
			dev_buf_queue(t, tag, 0);
			ncq = 0;
		} else if (ncq == 0) {
			dev_buf_t *t = dev_buf_alloc();
			t->buf[0]  = 0x00000039; /* A */
			t->blen    = 1;
			dev_buf_queue(t, -1, 0);
			fprintf(tfile, "DEV_FSM: trasnmit DMA Active\n");
		}
		break;
	case 0x58: /* BIST */
		break;
	case 0x5F: /* PIO Setup */
		break;
	case 0xA1: /* Set Device Bit */
		break;
	default:
		break;
	}
}

int dev_fsm::sata_send_buf(int len, int raw)
{
	int i = 0;
	send_failed = 0;
	send_success = 0;
	dev_tx_buf_len = len-1;
	if (raw == 0) {
		dev_tx_buf[dev_tx_buf_len + 1] = Sata_crc(dev_tx_buf, dev_tx_buf_len);
		Sata_scrambler(dev_tx_buf, dev_tx_buf_len + 1);
	} else {
		sata_dev_tx_raw = 1;
		sata_dev_tx_cur = 0;
		TL_send_FifoRdy = 1;
		dev_tx_rd_len = 0;
		dev_tx_buf_len  = len-2;
		fprintf(tfile, "DEV_FSM: sending raw fis\n");
		for (i=0;;i++) {
			wait (dev_clk_75M->posedge_event());   
			if (sata_dev_tx_raw == 0)
				return 0;
		}
	}
	wait (dev_clk_75M->posedge_event());   
	TL_send_FifoRdy = 1;
	dev_tx_rd_len = 0;
	wait (dev_clk_75M->posedge_event());   
	for (i=0;;i++) {
		wait (dev_clk_75M->posedge_event());
		if(send_success == 1) {
			fprintf(tfile, "DEV_FSM: **************device send data is successful.**************\n");
			return  0;
		} else if (send_failed == 1) {
			fprintf(tfile, "DEV_FSM: **************device send data is failed.**************\n");
			return -1;
		}
//#define TEST_HOLD_DX
//#define TEST_HOLD_DR

#ifdef TEST_HOLD_DX
		if ((i+1)%40 == 0) {
			TL_send_FifoRdy = 0;
		}
		if ((i+1)%50 == 0) {
			TL_send_FifoRdy = 1;
		}
#endif
	}
	return -2;
}

void dev_fsm::tb_main(void)
{
        int i = 0, j = 0;
	int linkup = 0;
	int k;
	static int wait_jiffes = 0;

	for (i = 0; i < 32; i ++) {
		INIT_LLIST_HEAD(&dev_queue[i].head);
	}

        dev_tx_data.write(SYNC_p);   
        dev_tx_charisk.write(1);   
	for (i=0;;i++) {
		wait (dev_clk_75M->posedge_event());
		if (link_up.read() != 0 && linkup == 0) {
			send_sig = 1;
		}
		if (send_sig) {
			send_sig = 0;
			fprintf(tfile, "DEV_FSM: **************device is link up.**************\n");
			dev_buf_t *t = dev_buf_alloc();
			/* Sending SIG FIS */
			t->buf[0]  = 0x01500034;
			t->buf[0] |= (1<<14);  /* Interrupt bit */
			t->buf[1]  = 0x00000001;
			t->buf[2]  = 0x00000000;
			t->buf[3]  = 0x00000001;
			t->buf[4]  = 0x00000000;
			t->blen      = 5;
			dev_buf_queue(t, -1, 0);
		}
		linkup = link_up.read();
#ifdef TEST_HOLD_DR
		if ((i+1)%80 == 0) {
			TL_Rec_FifoRdy = 0;
		}
		if ((i+1)%(100+j) == 0) {
			TL_Rec_FifoRdy = linkup;
			j += 50;
		}
		if (j == 600) {
			j = 0;
		}
#else
		TL_Rec_FifoRdy = linkup;
#endif
		/*if (i < wait_jiffes)
			continue;*/

		dev_buf_t *t, *n;
		llist_for_each_entry_safe(t, n, &dev_buf_head, entry) {
			int len = t->blen;
			dev_buf_send(t, dev_tx_buf, dev_tx_kbuf);
			sata_send_buf(len, t->raw);
		}
		for (int j = 0; j < 32; j++) {
			struct dev_queue *q = &dev_queue[j];
			int len;
			if (!llist_empty(&q->head)) {
				t = llist_entry((&q->head)->next, typeof(*t), entry);
				len = t->blen;
				if (t->wait)
					wait_jiffes = i + t->wait;
				dev_buf_send(t, dev_tx_buf, dev_tx_kbuf);
				sata_send_buf(len, t->raw);
			}
		}
	}
}

SC_MODULE_EXPORT(dev_fsm);
