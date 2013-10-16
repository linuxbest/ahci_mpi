// hs_if.v --- 
// 
// Filename: hs_if.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Mon Oct 14 14:39:23 2013 (-0700)
// Version: 
// Last-Updated: 
//           By: 
//     Update #: 0
// URL: 
// Keywords: 
// Compatibility: 
// 
// 

// Commentary: 
// 
// 
// 
// 

// Change log:
// 
// 
// 

// -------------------------------------
// Naming Conventions:
// 	active low signals                 : "*_n"
// 	clock signals                      : "clk", "clk_div#", "clk_#x"
// 	reset signals                      : "rst", "rst_n"
// 	generics                           : "C_*"
// 	user defined types                 : "*_TYPE"
// 	state machine next state           : "*_ns"
// 	state machine current state        : "*_cs"
// 	combinatorial signals              : "*_com"
// 	pipelined or register delay signals: "*_d#"
// 	counter signals                    : "*cnt*"
// 	clock enable signals               : "*_ce"
// 	internal version of output port    : "*_i"
// 	device pins                        : "*_pin"
// 	ports                              : - Names begin with Uppercase
// Code:

module hs_if (/*AUTOARG*/
   // Outputs
   txdatak, txdata, readdata, irq, err_ack, cmd_req, WrFIFO_Full,
   WrFIFO_Empty, WrFIFO_DataSize, WrFIFO_DataReq, WrFIFO_DataId,
   StartComm, RspSts, RspReq, RspId, Rsp, RdFIFO_Full, RdFIFO_Empty,
   RdFIFO_DataSize, RdFIFO_DataReq, RdFIFO_DataId, RdFIFO_Data,
   PhyReady, CmdAck, gtx_tune, phyreset, sata_ledA, sata_ledB,
   // Inputs
   writedata, write, txdatak_pop, rxfifo_irq, rxdatak, rxdata,
   plllock, phyclk, oob2dbg, linkup, gtx_txdatak, gtx_txdata,
   gtx_rxdatak, gtx_rxdata, err_req, address, WrFIFO_Push,
   WrFIFO_DataAck, WrFIFO_Data, Trace_FW, RspAddr, RspAck, RdFIFO_Pop,
   RdFIFO_DataAck, PhyReset, CommInit, CmdWr, CmdReq, CmdId, CmdAddr,
   Cmd, sys_clk, sys_rst
   );
   parameter C_FAMILY = "virtex5";
   parameter C_PORT = 0;
   parameter C_SATA_CHIPSCOPE = 0;

   input sys_clk;
   input sys_rst;

   output [31:0] gtx_tune;
   output 	 phyreset;
   output 	 sata_ledA;
   output 	 sata_ledB;
 
   /*AUTOINPUT*/
   // Beginning of automatic inputs (from unused autoinst inputs)
   input [31:0]		Cmd;			// To hs_cmd_if of hs_cmd_if.v
   input [3:0]		CmdAddr;		// To hs_cmd_if of hs_cmd_if.v
   input [4:0]		CmdId;			// To hs_cmd_if of hs_cmd_if.v
   input		CmdReq;			// To hs_cmd_if of hs_cmd_if.v
   input		CmdWr;			// To hs_cmd_if of hs_cmd_if.v
   input		CommInit;		// To hs_dcr_if of hs_dcr_if.v
   input		PhyReset;		// To hs_cmd_if of hs_cmd_if.v
   input		RdFIFO_DataAck;		// To hs_dma of hs_dma.v
   input		RdFIFO_Pop;		// To hs_dma of hs_dma.v
   input		RspAck;			// To hs_rsp_if of hs_rsp_if.v
   input [3:0]		RspAddr;		// To hs_rsp_if of hs_rsp_if.v
   input [127:0]	Trace_FW;		// To hs_dcr_if of hs_dcr_if.v
   input [31:0]		WrFIFO_Data;		// To hs_dma of hs_dma.v
   input		WrFIFO_DataAck;		// To hs_dma of hs_dma.v
   input		WrFIFO_Push;		// To hs_dma of hs_dma.v
   input [5:0]		address;		// To hs_dcr_if of hs_dcr_if.v
   input [7:0]		err_req;		// To sata_link of sata_link.v
   input [31:0]		gtx_rxdata;		// To sata_link of sata_link.v
   input [3:0]		gtx_rxdatak;		// To sata_link of sata_link.v
   input [31:0]		gtx_txdata;		// To sata_link of sata_link.v
   input [3:0]		gtx_txdatak;		// To sata_link of sata_link.v
   input		linkup;			// To sata_link of sata_link.v, ...
   input [127:0]	oob2dbg;		// To hs_dcr_if of hs_dcr_if.v
   input		phyclk;			// To txll of txll.v, ...
   input		plllock;		// To sata_link of sata_link.v, ...
   input [31:0]		rxdata;			// To sata_link of sata_link.v
   input		rxdatak;		// To sata_link of sata_link.v
   input		rxfifo_irq;		// To hs_dcr_if of hs_dcr_if.v
   input		txdatak_pop;		// To sata_link of sata_link.v
   input		write;			// To hs_dcr_if of hs_dcr_if.v
   input [31:0]		writedata;		// To hs_dcr_if of hs_dcr_if.v
   // End of automatics
   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output		CmdAck;			// From hs_cmd_if of hs_cmd_if.v
   output		PhyReady;		// From hs_cmd_if of hs_cmd_if.v
   output [31:0]	RdFIFO_Data;		// From hs_dma of hs_dma.v
   output [4:0]		RdFIFO_DataId;		// From hs_dma of hs_dma.v
   output		RdFIFO_DataReq;		// From hs_dma of hs_dma.v
   output [7:0]		RdFIFO_DataSize;	// From hs_dma of hs_dma.v
   output		RdFIFO_Empty;		// From hs_dma of hs_dma.v
   output		RdFIFO_Full;		// From hs_dma of hs_dma.v
   output [31:0]	Rsp;			// From hs_rsp_if of hs_rsp_if.v
   output [4:0]		RspId;			// From hs_rsp_if of hs_rsp_if.v
   output		RspReq;			// From hs_rsp_if of hs_rsp_if.v
   output		RspSts;			// From hs_rsp_if of hs_rsp_if.v
   output		StartComm;		// From hs_dcr_if of hs_dcr_if.v
   output [4:0]		WrFIFO_DataId;		// From hs_dma of hs_dma.v
   output		WrFIFO_DataReq;		// From hs_dma of hs_dma.v
   output [7:0]		WrFIFO_DataSize;	// From hs_dma of hs_dma.v
   output		WrFIFO_Empty;		// From hs_dma of hs_dma.v
   output		WrFIFO_Full;		// From hs_dma of hs_dma.v
   output		cmd_req;		// From hs_cmd_if of hs_cmd_if.v
   output [7:0]		err_ack;		// From sata_link of sata_link.v
   output		irq;			// From hs_dcr_if of hs_dcr_if.v
   output [31:0]	readdata;		// From hs_dcr_if of hs_dcr_if.v
   output [31:0]	txdata;			// From sata_link of sata_link.v
   output		txdatak;		// From sata_link of sata_link.v
   // End of automatics

   /**********************************************************************/   
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire			cmd_done;		// From hs_dcr_if of hs_dcr_if.v
   wire [4:0]		cmd_raddr;		// From hs_dcr_if of hs_dcr_if.v
   wire [31:0]		cmd_rdata;		// From hs_cmd_if of hs_cmd_if.v
   wire [8:0]		cs2dcr_cnt;		// From sata_link of sata_link.v
   wire [35:0]		cs2dcr_prim;		// From sata_link of sata_link.v
   wire			cxfifo_ack;		// From hs_dcr_if of hs_dcr_if.v
   wire			cxfifo_irq;		// From ctrl of ctrl.v
   wire			cxfifo_ok;		// From hs_dcr_if of hs_dcr_if.v
   wire			dcr2cs_clk;		// From hs_dcr_if of hs_dcr_if.v
   wire			dcr2cs_pop;		// From hs_dcr_if of hs_dcr_if.v
   wire			dma_ack;		// From hs_dma of hs_dma.v
   wire [31:0]		dma_address;		// From hs_dcr_if of hs_dcr_if.v
   wire			dma_data;		// From hs_dcr_if of hs_dcr_if.v
   wire			dma_eof;		// From hs_dcr_if of hs_dcr_if.v
   wire			dma_flush;		// From hs_dcr_if of hs_dcr_if.v
   wire [15:0]		dma_length;		// From hs_dcr_if of hs_dcr_if.v
   wire			dma_ok;			// From hs_dcr_if of hs_dcr_if.v
   wire [3:0]		dma_pm;			// From hs_dcr_if of hs_dcr_if.v
   wire			dma_req;		// From hs_dcr_if of hs_dcr_if.v
   wire			dma_sof;		// From hs_dcr_if of hs_dcr_if.v
   wire			dma_sync;		// From hs_dcr_if of hs_dcr_if.v
   wire			dma_wrt;		// From hs_dcr_if of hs_dcr_if.v
   wire [3:0]		error_code;		// From ctrl of ctrl.v
   wire			host_rst;		// From hs_dcr_if of hs_dcr_if.v
   wire [127:0]		link_fsm2dbg;		// From sata_link of sata_link.v
   wire [7:0]		port_state;		// From hs_dcr_if of hs_dcr_if.v
   wire			rsp_done;		// From hs_dcr_if of hs_dcr_if.v
   wire [4:0]		rsp_waddr;		// From hs_dcr_if of hs_dcr_if.v
   wire [31:0]		rsp_wdata;		// From hs_dcr_if of hs_dcr_if.v
   wire			rsp_we;			// From hs_dcr_if of hs_dcr_if.v
   wire [127:0]		rx_cs2dbg;		// From sata_link of sata_link.v
   wire			rxfifo_almost_empty;	// From rxll of rxll.v
   wire			rxfifo_clk;		// From hs_dma of hs_dma.v
   wire [31:0]		rxfifo_data;		// From rxll of rxll.v
   wire			rxfifo_empty;		// From rxll of rxll.v
   wire			rxfifo_eof;		// From rxll of rxll.v
   wire			rxfifo_eof_rdy;		// From rxll of rxll.v
   wire [11:0]		rxfifo_fis_hdr;		// From rxll of rxll.v
   wire [9:0]		rxfifo_rd_count;	// From rxll of rxll.v
   wire			rxfifo_rd_en;		// From hs_dma of hs_dma.v
   wire			rxfifo_sof;		// From rxll of rxll.v
   wire [4:0]		rxfis_raddr;		// From hs_dcr_if of hs_dcr_if.v
   wire [31:0]		rxfis_rdata;		// From rxll of rxll.v
   wire [31:0]		trn_cd;			// From sata_link of sata_link.v
   wire			trn_cdst_dsc_n;		// From ctrl of ctrl.v
   wire			trn_cdst_lock_n;	// From ctrl of ctrl.v
   wire			trn_cdst_rdy_n;		// From ctrl of ctrl.v
   wire			trn_ceof_n;		// From sata_link of sata_link.v
   wire			trn_csof_n;		// From sata_link of sata_link.v
   wire			trn_csrc_dsc_n;		// From sata_link of sata_link.v
   wire			trn_csrc_rdy_n;		// From sata_link of sata_link.v
   wire [31:0]		trn_rd;			// From sata_link of sata_link.v
   wire			trn_rdst_dsc_n;		// From rxll of rxll.v
   wire			trn_rdst_rdy_n;		// From rxll of rxll.v
   wire			trn_reof_n;		// From sata_link of sata_link.v
   wire			trn_rsof_n;		// From sata_link of sata_link.v
   wire			trn_rsrc_dsc_n;		// From sata_link of sata_link.v
   wire			trn_rsrc_rdy_n;		// From sata_link of sata_link.v
   wire [31:0]		trn_td;			// From txll of txll.v
   wire			trn_tdst_dsc_n;		// From sata_link of sata_link.v
   wire			trn_tdst_rdy_n;		// From sata_link of sata_link.v
   wire			trn_teof_n;		// From txll of txll.v
   wire			trn_tsof_n;		// From txll of txll.v
   wire			trn_tsrc_dsc_n;		// From txll of txll.v
   wire			trn_tsrc_rdy_n;		// From txll of txll.v
   wire [127:0]		tx_cs2dbg;		// From sata_link of sata_link.v
   wire			txfifo_almost_full;	// From txll of txll.v
   wire			txfifo_clk;		// From hs_dma of hs_dma.v
   wire [9:0]		txfifo_count;		// From txll of txll.v
   wire [31:0]		txfifo_data;		// From hs_dma of hs_dma.v
   wire			txfifo_eof;		// From hs_dma of hs_dma.v
   wire			txfifo_eof_poped;	// From txll of txll.v
   wire			txfifo_sof;		// From hs_dma of hs_dma.v
   wire			txfifo_wr_en;		// From hs_dma of hs_dma.v
   // End of automatics
   
   /**********************************************************************/
   localparam C_HW_CRC = C_FAMILY == "virtex5" ? 1 : 0;
   txll #(.C_FAMILY(C_FAMILY))
   txll  (/*AUTOINST*/
	  // Outputs
	  .trn_td			(trn_td[31:0]),
	  .trn_teof_n			(trn_teof_n),
	  .trn_tsof_n			(trn_tsof_n),
	  .trn_tsrc_dsc_n		(trn_tsrc_dsc_n),
	  .trn_tsrc_rdy_n		(trn_tsrc_rdy_n),
	  .txfifo_almost_full		(txfifo_almost_full),
	  .txfifo_count			(txfifo_count[9:0]),
	  .txfifo_eof_poped		(txfifo_eof_poped),
	  // Inputs
	  .sys_clk			(sys_clk),
	  .sys_rst			(sys_rst),
	  .phyclk			(phyclk),
	  .phyreset			(phyreset),
	  .trn_tdst_dsc_n		(trn_tdst_dsc_n),
	  .trn_tdst_rdy_n		(trn_tdst_rdy_n),
	  .txfifo_clk			(txfifo_clk),
	  .txfifo_data			(txfifo_data[31:0]),
	  .txfifo_eof			(txfifo_eof),
	  .txfifo_sof			(txfifo_sof),
	  .txfifo_wr_en			(txfifo_wr_en));
   rxll #(.C_FAMILY(C_FAMILY))
   rxll  (/*AUTOINST*/
	  // Outputs
	  .rxfifo_almost_empty		(rxfifo_almost_empty),
	  .rxfifo_data			(rxfifo_data[31:0]),
	  .rxfifo_empty			(rxfifo_empty),
	  .rxfifo_eof			(rxfifo_eof),
	  .rxfifo_eof_rdy		(rxfifo_eof_rdy),
	  .rxfifo_fis_hdr		(rxfifo_fis_hdr[11:0]),
	  .rxfifo_rd_count		(rxfifo_rd_count[9:0]),
	  .rxfifo_sof			(rxfifo_sof),
	  .rxfis_rdata			(rxfis_rdata[31:0]),
	  .trn_rdst_dsc_n		(trn_rdst_dsc_n),
	  .trn_rdst_rdy_n		(trn_rdst_rdy_n),
	  // Inputs
	  .phyclk			(phyclk),
	  .phyreset			(phyreset),
	  .rxfifo_clk			(rxfifo_clk),
	  .rxfifo_rd_en			(rxfifo_rd_en),
	  .rxfis_raddr			(rxfis_raddr[2:0]),
	  .sys_clk			(sys_clk),
	  .sys_rst			(sys_rst),
	  .trn_rd			(trn_rd[31:0]),
	  .trn_reof_n			(trn_reof_n),
	  .trn_rsof_n			(trn_rsof_n),
	  .trn_rsrc_dsc_n		(trn_rsrc_dsc_n),
	  .trn_rsrc_rdy_n		(trn_rsrc_rdy_n));
   ctrl
     ctrl(/*AUTOINST*/
	  // Outputs
	  .trn_cdst_rdy_n		(trn_cdst_rdy_n),
	  .trn_cdst_dsc_n		(trn_cdst_dsc_n),
	  .trn_cdst_lock_n		(trn_cdst_lock_n),
	  .cxfifo_irq			(cxfifo_irq),
	  .error_code			(error_code[3:0]),
	  // Inputs
	  .phyclk			(phyclk),
	  .phyreset			(phyreset),
	  .sys_clk			(sys_clk),
	  .sys_rst			(sys_rst),
	  .trn_csof_n			(trn_csof_n),
	  .trn_ceof_n			(trn_ceof_n),
	  .trn_cd			(trn_cd[31:0]),
	  .trn_csrc_rdy_n		(trn_csrc_rdy_n),
	  .trn_csrc_dsc_n		(trn_csrc_dsc_n),
	  .cxfifo_ack			(cxfifo_ack),
	  .cxfifo_ok			(cxfifo_ok),
	  .dma_req			(dma_req));
   sata_link #(.C_HW_CRC(C_HW_CRC))
   sata_link  (/*AUTOINST*/
	       // Outputs
	       .trn_rsof_n		(trn_rsof_n),
	       .trn_reof_n		(trn_reof_n),
	       .trn_rd			(trn_rd[31:0]),
	       .trn_rsrc_rdy_n		(trn_rsrc_rdy_n),
	       .trn_rsrc_dsc_n		(trn_rsrc_dsc_n),
	       .trn_tdst_rdy_n		(trn_tdst_rdy_n),
	       .trn_tdst_dsc_n		(trn_tdst_dsc_n),
	       .trn_csof_n		(trn_csof_n),
	       .trn_ceof_n		(trn_ceof_n),
	       .trn_cd			(trn_cd[31:0]),
	       .trn_csrc_rdy_n		(trn_csrc_rdy_n),
	       .trn_csrc_dsc_n		(trn_csrc_dsc_n),
	       .txdata			(txdata[31:0]),
	       .txdatak			(txdatak),
	       .rx_cs2dbg		(rx_cs2dbg[127:0]),
	       .tx_cs2dbg		(tx_cs2dbg[127:0]),
	       .link_fsm2dbg		(link_fsm2dbg[127:0]),
	       .cs2dcr_prim		(cs2dcr_prim[35:0]),
	       .cs2dcr_cnt		(cs2dcr_cnt[8:0]),
	       .err_ack			(err_ack[7:0]),
	       // Inputs
	       .phyclk			(phyclk),
	       .host_rst		(host_rst),
	       .trn_rdst_rdy_n		(trn_rdst_rdy_n),
	       .trn_rdst_dsc_n		(trn_rdst_dsc_n),
	       .trn_tsof_n		(trn_tsof_n),
	       .trn_teof_n		(trn_teof_n),
	       .trn_td			(trn_td[31:0]),
	       .trn_tsrc_rdy_n		(trn_tsrc_rdy_n),
	       .trn_tsrc_dsc_n		(trn_tsrc_dsc_n),
	       .trn_cdst_rdy_n		(trn_cdst_rdy_n),
	       .trn_cdst_dsc_n		(trn_cdst_dsc_n),
	       .trn_cdst_lock_n		(trn_cdst_lock_n),
	       .txdatak_pop		(txdatak_pop),
	       .rxdata			(rxdata[31:0]),
	       .rxdatak			(rxdatak),
	       .linkup			(linkup),
	       .plllock			(plllock),
	       .dcr2cs_pop		(dcr2cs_pop),
	       .dcr2cs_clk		(dcr2cs_clk),
	       .port_state		(port_state[7:0]),
	       .gtx_txdata		(gtx_txdata[31:0]),
	       .gtx_txdatak		(gtx_txdatak[3:0]),
	       .gtx_rxdata		(gtx_rxdata[31:0]),
	       .gtx_rxdatak		(gtx_rxdatak[3:0]),
	       .gtx_tune		(gtx_tune[31:0]),
	       .err_req			(err_req[7:0]));
   hs_dcr_if #(/*AUTOINSTPARAM*/
	       // Parameters
	       .C_PORT			(C_PORT),
	       .C_SATA_CHIPSCOPE	(C_SATA_CHIPSCOPE))
   hs_dcr_if (/*AUTOINST*/
	      // Outputs
	      .readdata			(readdata[31:0]),
	      .irq			(irq),
	      .StartComm		(StartComm),
	      .phyreset			(phyreset),
	      .host_rst			(host_rst),
	      .gtx_tune			(gtx_tune[31:0]),
	      .port_state		(port_state[7:0]),
	      .dcr2cs_clk		(dcr2cs_clk),
	      .dcr2cs_pop		(dcr2cs_pop),
	      .dma_address		(dma_address[31:0]),
	      .dma_length		(dma_length[15:0]),
	      .dma_pm			(dma_pm[3:0]),
	      .dma_data			(dma_data),
	      .dma_ok			(dma_ok),
	      .dma_req			(dma_req),
	      .dma_wrt			(dma_wrt),
	      .dma_sync			(dma_sync),
	      .dma_flush		(dma_flush),
	      .dma_eof			(dma_eof),
	      .dma_sof			(dma_sof),
	      .cxfifo_ack		(cxfifo_ack),
	      .cxfifo_ok		(cxfifo_ok),
	      .rxfis_raddr		(rxfis_raddr[4:0]),
	      .cmd_raddr		(cmd_raddr[4:0]),
	      .cmd_done			(cmd_done),
	      .rsp_wdata		(rsp_wdata[31:0]),
	      .rsp_waddr		(rsp_waddr[4:0]),
	      .rsp_we			(rsp_we),
	      .rsp_done			(rsp_done),
	      // Inputs
	      .sys_clk			(sys_clk),
	      .sys_rst			(sys_rst),
	      .phyclk			(phyclk),
	      .address			(address[5:0]),
	      .write			(write),
	      .writedata		(writedata[31:0]),
	      .Trace_FW			(Trace_FW[127:0]),
	      .CommInit			(CommInit),
	      .linkup			(linkup),
	      .plllock			(plllock),
	      .cs2dcr_prim		(cs2dcr_prim[35:0]),
	      .cs2dcr_cnt		(cs2dcr_cnt[8:0]),
	      .link_fsm2dbg		(link_fsm2dbg[127:0]),
	      .rx_cs2dbg		(rx_cs2dbg[127:0]),
	      .tx_cs2dbg		(tx_cs2dbg[127:0]),
	      .oob2dbg			(oob2dbg[127:0]),
	      .error_code		(error_code[3:0]),
	      .rxfifo_fis_hdr		(rxfifo_fis_hdr[11:0]),
	      .dma_ack			(dma_ack),
	      .rxfifo_irq		(rxfifo_irq),
	      .cxfifo_irq		(cxfifo_irq),
	      .rxfis_rdata		(rxfis_rdata[31:0]),
	      .cmd_rdata		(cmd_rdata[31:0]));
   hs_dma
     hs_dma(/*AUTOINST*/
	    // Outputs
	    .dma_ack			(dma_ack),
	    .txfifo_clk			(txfifo_clk),
	    .txfifo_data		(txfifo_data[31:0]),
	    .txfifo_eof			(txfifo_eof),
	    .txfifo_sof			(txfifo_sof),
	    .txfifo_wr_en		(txfifo_wr_en),
	    .rxfifo_clk			(rxfifo_clk),
	    .rxfifo_rd_en		(rxfifo_rd_en),
	    .WrFIFO_Empty		(WrFIFO_Empty),
	    .WrFIFO_Full		(WrFIFO_Full),
	    .WrFIFO_DataReq		(WrFIFO_DataReq),
	    .WrFIFO_DataSize		(WrFIFO_DataSize[7:0]),
	    .WrFIFO_DataId		(WrFIFO_DataId[4:0]),
	    .RdFIFO_Data		(RdFIFO_Data[31:0]),
	    .RdFIFO_Empty		(RdFIFO_Empty),
	    .RdFIFO_Full		(RdFIFO_Full),
	    .RdFIFO_DataReq		(RdFIFO_DataReq),
	    .RdFIFO_DataSize		(RdFIFO_DataSize[7:0]),
	    .RdFIFO_DataId		(RdFIFO_DataId[4:0]),
	    // Inputs
	    .sys_clk			(sys_clk),
	    .sys_rst			(sys_rst),
	    .dma_address		(dma_address[31:0]),
	    .dma_length			(dma_length[15:0]),
	    .dma_pm			(dma_pm[3:0]),
	    .dma_data			(dma_data),
	    .dma_ok			(dma_ok),
	    .dma_req			(dma_req),
	    .dma_wrt			(dma_wrt),
	    .dma_sync			(dma_sync),
	    .dma_flush			(dma_flush),
	    .dma_eof			(dma_eof),
	    .dma_sof			(dma_sof),
	    .txfifo_almost_full		(txfifo_almost_full),
	    .txfifo_count		(txfifo_count[9:0]),
	    .txfifo_eof_poped		(txfifo_eof_poped),
	    .rxfifo_almost_empty	(rxfifo_almost_empty),
	    .rxfifo_data		(rxfifo_data[31:0]),
	    .rxfifo_empty		(rxfifo_empty),
	    .rxfifo_eof			(rxfifo_eof),
	    .rxfifo_eof_rdy		(rxfifo_eof_rdy),
	    .rxfifo_fis_hdr		(rxfifo_fis_hdr[11:0]),
	    .rxfifo_rd_count		(rxfifo_rd_count[9:0]),
	    .rxfifo_sof			(rxfifo_sof),
	    .WrFIFO_Data		(WrFIFO_Data[31:0]),
	    .WrFIFO_Push		(WrFIFO_Push),
	    .WrFIFO_DataAck		(WrFIFO_DataAck),
	    .RdFIFO_Pop			(RdFIFO_Pop),
	    .RdFIFO_DataAck		(RdFIFO_DataAck));
   hs_cmd_if
     hs_cmd_if (/*AUTOINST*/
		// Outputs
		.PhyReady		(PhyReady),
		.CmdAck			(CmdAck),
		.cmd_req		(cmd_req),
		.cmd_rdata		(cmd_rdata[31:0]),
		// Inputs
		.sys_clk		(sys_clk),
		.sys_rst		(sys_rst),
		.PhyReset		(PhyReset),
		.CmdReq			(CmdReq),
		.CmdId			(CmdId[4:0]),
		.Cmd			(Cmd[31:0]),
		.CmdAddr		(CmdAddr[3:0]),
		.CmdWr			(CmdWr),
		.cmd_done		(cmd_done),
		.cmd_raddr		(cmd_raddr[4:0]));
   hs_rsp_if
     hs_rsp_if (/*AUTOINST*/
		// Outputs
		.RspReq			(RspReq),
		.RspSts			(RspSts),
		.RspId			(RspId[4:0]),
		.Rsp			(Rsp[31:0]),
		// Inputs
		.sys_clk		(sys_clk),
		.sys_rst		(sys_rst),
		.RspAck			(RspAck),
		.RspAddr		(RspAddr[3:0]),
		.rsp_done		(rsp_done),
		.rsp_we			(rsp_we),
		.rsp_waddr		(rsp_waddr[4:0]),
		.rsp_wdata		(rsp_wdata[31:0]));
endmodule // hs
// Local Variables:
// verilog-library-directories:("." "../../pcores/sata_v1_00_a/hdl/verilog" )
// verilog-library-files:(".")
// verilog-library-extensions:(".v" ".h")
// End:
// 
// hs_if.v ends here
