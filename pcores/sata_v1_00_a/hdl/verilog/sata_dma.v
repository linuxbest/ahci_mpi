// sata_dma.v --- 
// 
// Filename: sata_dma.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Thu Feb 23 17:44:54 2012 (+0800)
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

// Copyright (C) 2008,2009 Beijing Soul tech.
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
module sata_dma (/*AUTOARG*/
   // Outputs
   txdatak, txdata, readdata, irq, err_ack, dma_state, StartComm,
   PIM_WrFIFO_Push, PIM_WrFIFO_Flush, PIM_WrFIFO_Data, PIM_WrFIFO_BE,
   PIM_Size, PIM_RdModWr, PIM_RdFIFO_Pop, PIM_RdFIFO_Flush, PIM_RNW,
   PIM_AddrReq, PIM_Addr, gtx_tune, phyreset, sata_ledA, sata_ledB,
   // Inputs
   writedata, write, txdatak_pop, rxdatak, rxdata, plllock, phyclk,
   oob2dbg, linkup, gtx_txdatak, gtx_txdata, gtx_rxdatak, gtx_rxdata,
   err_req, address, Trace_FW, PIM_WrFIFO_Empty,
   PIM_WrFIFO_AlmostFull, PIM_RdFIFO_RdWdAddr, PIM_RdFIFO_Latency,
   PIM_RdFIFO_Empty, PIM_RdFIFO_Data, PIM_InitDone, PIM_AddrAck,
   MPMC_Clk, CommInit, sys_clk, sys_rst
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
   input		CommInit;		// To dcr_if of dcr_if.v
   input		MPMC_Clk;		// To dma of dma.v
   input		PIM_AddrAck;		// To dma of dma.v
   input		PIM_InitDone;		// To dma of dma.v
   input [31:0]		PIM_RdFIFO_Data;	// To dma of dma.v
   input		PIM_RdFIFO_Empty;	// To dma of dma.v
   input [1:0]		PIM_RdFIFO_Latency;	// To dma of dma.v
   input [3:0]		PIM_RdFIFO_RdWdAddr;	// To dma of dma.v
   input		PIM_WrFIFO_AlmostFull;	// To dma of dma.v
   input		PIM_WrFIFO_Empty;	// To dma of dma.v
   input [127:0]	Trace_FW;		// To dcr_if of dcr_if.v
   input [5:0]		address;		// To dcr_if of dcr_if.v
   input [7:0]		err_req;		// To sata_link of sata_link.v
   input [31:0]		gtx_rxdata;		// To sata_link of sata_link.v
   input [3:0]		gtx_rxdatak;		// To sata_link of sata_link.v
   input [31:0]		gtx_txdata;		// To sata_link of sata_link.v
   input [3:0]		gtx_txdatak;		// To sata_link of sata_link.v
   input		linkup;			// To dcr_if of dcr_if.v, ...
   input [127:0]	oob2dbg;		// To dcr_if of dcr_if.v
   input		phyclk;			// To txll of txll.v, ...
   input		plllock;		// To dcr_if of dcr_if.v, ...
   input [31:0]		rxdata;			// To sata_link of sata_link.v
   input		rxdatak;		// To sata_link of sata_link.v
   input		txdatak_pop;		// To sata_link of sata_link.v
   input		write;			// To dcr_if of dcr_if.v
   input [31:0]		writedata;		// To dcr_if of dcr_if.v
   // End of automatics
   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output [31:0]	PIM_Addr;		// From dma of dma.v
   output		PIM_AddrReq;		// From dma of dma.v
   output		PIM_RNW;		// From dma of dma.v
   output		PIM_RdFIFO_Flush;	// From dma of dma.v
   output		PIM_RdFIFO_Pop;		// From dma of dma.v
   output		PIM_RdModWr;		// From dma of dma.v
   output [3:0]		PIM_Size;		// From dma of dma.v
   output [3:0]		PIM_WrFIFO_BE;		// From dma of dma.v
   output [31:0]	PIM_WrFIFO_Data;	// From dma of dma.v
   output		PIM_WrFIFO_Flush;	// From dma of dma.v
   output		PIM_WrFIFO_Push;	// From dma of dma.v
   output		StartComm;		// From dcr_if of dcr_if.v
   output [31:0]	dma_state;		// From dma of dma.v
   output [7:0]		err_ack;		// From sata_link of sata_link.v
   output		irq;			// From dcr_if of dcr_if.v
   output [31:0]	readdata;		// From dcr_if of dcr_if.v
   output [31:0]	txdata;			// From sata_link of sata_link.v
   output		txdatak;		// From sata_link of sata_link.v
   // End of automatics

   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [8:0]		cs2dcr_cnt;		// From sata_link of sata_link.v
   wire [35:0]		cs2dcr_prim;		// From sata_link of sata_link.v
   wire			cxfifo_ack;		// From dcr_if of dcr_if.v
   wire			cxfifo_irq;		// From cxll of ctrl.v
   wire			cxfifo_ok;		// From dcr_if of dcr_if.v
   wire			dcr2cs_clk;		// From dcr_if of dcr_if.v
   wire			dcr2cs_pop;		// From dcr_if of dcr_if.v
   wire			dma_ack;		// From dma of dma.v
   wire [31:0]		dma_address;		// From dcr_if of dcr_if.v
   wire			dma_data;		// From dcr_if of dcr_if.v
   wire			dma_eof;		// From dcr_if of dcr_if.v
   wire			dma_flush;		// From dcr_if of dcr_if.v
   wire [15:0]		dma_length;		// From dcr_if of dcr_if.v
   wire			dma_ok;			// From dcr_if of dcr_if.v
   wire [3:0]		dma_pm;			// From dcr_if of dcr_if.v
   wire			dma_req;		// From dcr_if of dcr_if.v
   wire			dma_sof;		// From dcr_if of dcr_if.v
   wire			dma_sync;		// From dcr_if of dcr_if.v
   wire			dma_wrt;		// From dcr_if of dcr_if.v
   wire [3:0]		error_code;		// From cxll of ctrl.v
   wire			host_rst;		// From dcr_if of dcr_if.v
   wire [127:0]		link_fsm2dbg;		// From sata_link of sata_link.v
   wire [7:0]		port_state;		// From dcr_if of dcr_if.v
   wire [127:0]		rx_cs2dbg;		// From sata_link of sata_link.v
   wire			rxfifo_almost_empty;	// From rxll of rxll.v
   wire			rxfifo_clk;		// From dma of dma.v
   wire [31:0]		rxfifo_data;		// From rxll of rxll.v
   wire			rxfifo_empty;		// From rxll of rxll.v
   wire			rxfifo_eof;		// From rxll of rxll.v
   wire			rxfifo_eof_rdy;		// From rxll of rxll.v
   wire [11:0]		rxfifo_fis_hdr;		// From rxll of rxll.v
   wire			rxfifo_irq;		// From dma of dma.v
   wire [9:0]		rxfifo_rd_count;	// From rxll of rxll.v
   wire			rxfifo_rd_en;		// From dma of dma.v
   wire			rxfifo_sof;		// From rxll of rxll.v
   wire [4:0]		rxfis_raddr;		// From dcr_if of dcr_if.v
   wire [31:0]		rxfis_rdata;		// From rxll of rxll.v
   wire [31:0]		trn_cd;			// From sata_link of sata_link.v
   wire			trn_cdst_dsc_n;		// From cxll of ctrl.v
   wire			trn_cdst_lock_n;	// From cxll of ctrl.v
   wire			trn_cdst_rdy_n;		// From cxll of ctrl.v
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
   wire			txfifo_clk;		// From dma of dma.v
   wire [9:0]		txfifo_count;		// From txll of txll.v
   wire [31:0]		txfifo_data;		// From dma of dma.v
   wire			txfifo_eof;		// From dma of dma.v
   wire			txfifo_eof_poped;	// From txll of txll.v
   wire			txfifo_sof;		// From dma of dma.v
   wire			txfifo_wr_en;		// From dma of dma.v
   // End of automatics

   localparam C_HW_CRC = C_FAMILY == "virtex5" ? 1 : 0;
   txll #(.C_FAMILY(C_FAMILY))
   txll(/*AUTOINST*/
	     // Outputs
	     .trn_td			(trn_td[31:0]),
	     .trn_teof_n		(trn_teof_n),
	     .trn_tsof_n		(trn_tsof_n),
	     .trn_tsrc_dsc_n		(trn_tsrc_dsc_n),
	     .trn_tsrc_rdy_n		(trn_tsrc_rdy_n),
	     .txfifo_almost_full	(txfifo_almost_full),
	     .txfifo_count		(txfifo_count[9:0]),
	     .txfifo_eof_poped		(txfifo_eof_poped),
	     // Inputs
	     .sys_clk			(sys_clk),
	     .sys_rst			(sys_rst),
	     .phyclk			(phyclk),
	     .phyreset			(phyreset),
	     .trn_tdst_dsc_n		(trn_tdst_dsc_n),
	     .trn_tdst_rdy_n		(trn_tdst_rdy_n),
	     .txfifo_clk		(txfifo_clk),
	     .txfifo_data		(txfifo_data[31:0]),
	     .txfifo_eof		(txfifo_eof),
	     .txfifo_sof		(txfifo_sof),
	     .txfifo_wr_en		(txfifo_wr_en));
   rxll #(.C_FAMILY(C_FAMILY))
   rxll(/*AUTOINST*/
	     // Outputs
	     .rxfifo_almost_empty	(rxfifo_almost_empty),
	     .rxfifo_data		(rxfifo_data[31:0]),
	     .rxfifo_empty		(rxfifo_empty),
	     .rxfifo_eof		(rxfifo_eof),
	     .rxfifo_eof_rdy		(rxfifo_eof_rdy),
	     .rxfifo_fis_hdr		(rxfifo_fis_hdr[11:0]),
	     .rxfifo_rd_count		(rxfifo_rd_count[9:0]),
	     .rxfifo_sof		(rxfifo_sof),
	     .rxfis_rdata		(rxfis_rdata[31:0]),
	     .trn_rdst_dsc_n		(trn_rdst_dsc_n),
	     .trn_rdst_rdy_n		(trn_rdst_rdy_n),
	     // Inputs
	     .phyclk			(phyclk),
	     .phyreset			(phyreset),
	     .rxfifo_clk		(rxfifo_clk),
	     .rxfifo_rd_en		(rxfifo_rd_en),
	     .rxfis_raddr		(rxfis_raddr[2:0]),
	     .sys_clk			(sys_clk),
	     .sys_rst			(sys_rst),
	     .trn_rd			(trn_rd[31:0]),
	     .trn_reof_n		(trn_reof_n),
	     .trn_rsof_n		(trn_rsof_n),
	     .trn_rsrc_dsc_n		(trn_rsrc_dsc_n),
	     .trn_rsrc_rdy_n		(trn_rsrc_rdy_n));
   dcr_if #(/*AUTOINSTPARAM*/
	    // Parameters
	    .C_PORT			(C_PORT),
	    .C_SATA_CHIPSCOPE		(C_SATA_CHIPSCOPE))
          dcr_if (/*AUTOINST*/
		  // Outputs
		  .readdata		(readdata[31:0]),
		  .irq			(irq),
		  .StartComm		(StartComm),
		  .phyreset		(phyreset),
		  .host_rst		(host_rst),
		  .gtx_tune		(gtx_tune[31:0]),
		  .port_state		(port_state[7:0]),
		  .dcr2cs_clk		(dcr2cs_clk),
		  .dcr2cs_pop		(dcr2cs_pop),
		  .dma_address		(dma_address[31:0]),
		  .dma_length		(dma_length[15:0]),
		  .dma_pm		(dma_pm[3:0]),
		  .dma_data		(dma_data),
		  .dma_ok		(dma_ok),
		  .dma_req		(dma_req),
		  .dma_wrt		(dma_wrt),
		  .dma_sync		(dma_sync),
		  .dma_flush		(dma_flush),
		  .dma_eof		(dma_eof),
		  .dma_sof		(dma_sof),
		  .cxfifo_ack		(cxfifo_ack),
		  .cxfifo_ok		(cxfifo_ok),
		  .rxfis_raddr		(rxfis_raddr[4:0]),
		  // Inputs
		  .sys_clk		(sys_clk),
		  .sys_rst		(sys_rst),
		  .phyclk		(phyclk),
		  .address		(address[5:0]),
		  .write		(write),
		  .writedata		(writedata[31:0]),
		  .Trace_FW		(Trace_FW[127:0]),
		  .CommInit		(CommInit),
		  .linkup		(linkup),
		  .plllock		(plllock),
		  .cs2dcr_prim		(cs2dcr_prim[35:0]),
		  .cs2dcr_cnt		(cs2dcr_cnt[8:0]),
		  .link_fsm2dbg		(link_fsm2dbg[127:0]),
		  .rx_cs2dbg		(rx_cs2dbg[127:0]),
		  .tx_cs2dbg		(tx_cs2dbg[127:0]),
		  .oob2dbg		(oob2dbg[127:0]),
		  .error_code		(error_code[3:0]),
		  .rxfifo_fis_hdr	(rxfifo_fis_hdr[11:0]),
		  .dma_ack		(dma_ack),
		  .rxfifo_irq		(rxfifo_irq),
		  .cxfifo_irq		(cxfifo_irq),
		  .rxfis_rdata		(rxfis_rdata[31:0]));

   ctrl
     cxll(/*AUTOINST*/
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
   
   dma
     dma (/*AUTOINST*/
	  // Outputs
	  .dma_ack			(dma_ack),
	  .txfifo_clk			(txfifo_clk),
	  .txfifo_data			(txfifo_data[31:0]),
	  .txfifo_eof			(txfifo_eof),
	  .txfifo_sof			(txfifo_sof),
	  .txfifo_wr_en			(txfifo_wr_en),
	  .rxfifo_clk			(rxfifo_clk),
	  .rxfifo_rd_en			(rxfifo_rd_en),
	  .PIM_Addr			(PIM_Addr[31:0]),
	  .PIM_AddrReq			(PIM_AddrReq),
	  .PIM_RNW			(PIM_RNW),
	  .PIM_Size			(PIM_Size[3:0]),
	  .PIM_RdModWr			(PIM_RdModWr),
	  .PIM_RdFIFO_Flush		(PIM_RdFIFO_Flush),
	  .PIM_RdFIFO_Pop		(PIM_RdFIFO_Pop),
	  .PIM_WrFIFO_Data		(PIM_WrFIFO_Data[31:0]),
	  .PIM_WrFIFO_BE		(PIM_WrFIFO_BE[3:0]),
	  .PIM_WrFIFO_Push		(PIM_WrFIFO_Push),
	  .PIM_WrFIFO_Flush		(PIM_WrFIFO_Flush),
	  .rxfifo_irq			(rxfifo_irq),
	  .dma_state			(dma_state[31:0]),
	  // Inputs
	  .sys_clk			(sys_clk),
	  .sys_rst			(sys_rst),
	  .dma_address			(dma_address[31:0]),
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
	  .txfifo_count			(txfifo_count[9:0]),
	  .txfifo_eof_poped		(txfifo_eof_poped),
	  .rxfifo_almost_empty		(rxfifo_almost_empty),
	  .rxfifo_data			(rxfifo_data[31:0]),
	  .rxfifo_empty			(rxfifo_empty),
	  .rxfifo_eof			(rxfifo_eof),
	  .rxfifo_eof_rdy		(rxfifo_eof_rdy),
	  .rxfifo_fis_hdr		(rxfifo_fis_hdr[11:0]),
	  .rxfifo_rd_count		(rxfifo_rd_count[9:0]),
	  .rxfifo_sof			(rxfifo_sof),
	  .MPMC_Clk			(MPMC_Clk),
	  .PIM_AddrAck			(PIM_AddrAck),
	  .PIM_RdFIFO_RdWdAddr		(PIM_RdFIFO_RdWdAddr[3:0]),
	  .PIM_RdFIFO_Data		(PIM_RdFIFO_Data[31:0]),
	  .PIM_RdFIFO_Empty		(PIM_RdFIFO_Empty),
	  .PIM_RdFIFO_Latency		(PIM_RdFIFO_Latency[1:0]),
	  .PIM_WrFIFO_Empty		(PIM_WrFIFO_Empty),
	  .PIM_WrFIFO_AlmostFull	(PIM_WrFIFO_AlmostFull),
	  .PIM_InitDone			(PIM_InitDone));
   
   sata_link #(.C_HW_CRC(C_HW_CRC))
     sata_link(/*AUTOINST*/
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
   
endmodule
// 
// sata_dma.v ends here
