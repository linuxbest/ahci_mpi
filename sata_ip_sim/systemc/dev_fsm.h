#include <systemc.h>
#include <stdint.h>
//#include <arpa/inet.h>

//-----------define primitive---------------
#define	 ALIGN_p  0x7b4a4abc
#define	 CONT_p   0x9999aa7c
#define	 DMAT_p   0x3636b57c
#define	 EOF_p    0xd5d5b57c
#define	 HOLD_p   0xd5d5aa7c
#define	 HOLDA_p  0x9595aa7c
#define	 PMACK_p  0x9595957c
#define	 PMNAK_p  0xf5f5957c
#define	 PMREQ_Pp 0x1717b57c
#define	 PMREQ_Sp 0x7575957c
#define	 R_ERR_p  0x5656b57c
#define	 R_IP_p   0x5555b57c
#define	 R_OK_p   0x3535b57c
#define	 R_RDY_p  0x4a4a957c
#define	 SOF_p    0x3737b57c
#define	 SYNC_p   0xb5b5957c
#define	 WTRM_p   0x5858b57c
#define	 X_RDY_p  0x5757b57c

SC_MODULE(dev_fsm)
{
public:
	/* SATA Device data */
	sc_in <bool> dev_clk_75M;
	sc_in <bool> link_up;
	sc_in < sc_uint<32> > dev_rx_data;
	sc_in <bool>          dev_rx_charisk;

	sc_out < sc_uint<32> > dev_tx_data;
	sc_out < bool >        dev_tx_charisk;

	sc_in  <bool>         sata_dcm_lock;
	sc_out <bool>         phy_rst_n;

	void sata_rx_fsm(void);
	void sata_rx_buf(void);
	void sata_dev_rx(void);
	void sata_dev_tx(void);
	void sata_dev_state(void);

	void tb_main(void);

	int sata_send_buf(int len, int raw);

	SC_CTOR(dev_fsm)
	{
		SC_METHOD(sata_rx_fsm);
		sensitive_pos << dev_clk_75M;

		SC_METHOD(sata_dev_tx);
		sensitive_pos << dev_clk_75M;
		
		SC_METHOD(sata_dev_rx);
		sensitive_pos << dev_clk_75M;

		SC_METHOD(sata_dev_state);
		sensitive_pos << dev_clk_75M;

		SC_THREAD(tb_main);
	}

	~dev_fsm()
	{
	}
};
