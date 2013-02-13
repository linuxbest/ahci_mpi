// rxll.v --- 
// 
// Filename: rxll.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Thu Feb 23 17:12:53 2012 (+0800)
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
module rxll (/*AUTOARG*/
   // Outputs
   trn_rdst_rdy_n, trn_rdst_dsc_n, rxfis_rdata, rxfifo_sof,
   rxfifo_rd_count, rxfifo_fis_hdr, rxfifo_eof_rdy, rxfifo_eof,
   rxfifo_empty, rxfifo_data, rxfifo_almost_empty,
   // Inputs
   trn_rsrc_rdy_n, trn_rsrc_dsc_n, trn_rsof_n, trn_reof_n, trn_rd,
   sys_rst, sys_clk, rxfis_raddr, rxfifo_rd_en, rxfifo_clk, phyreset,
   phyclk
   );
   /*AUTOINPUT*/
   // Beginning of automatic inputs (from unused autoinst inputs)
   input		phyclk;			// To rxll_ll of rxll_ll.v
   input		phyreset;		// To rxll_ll of rxll_ll.v, ...
   input		rxfifo_clk;		// To rxll_ctrl of rxll_ctrl.v
   input		rxfifo_rd_en;		// To rxll_ctrl of rxll_ctrl.v
   input [2:0]		rxfis_raddr;		// To rxll_ll of rxll_ll.v
   input		sys_clk;		// To rxll_ll of rxll_ll.v, ...
   input		sys_rst;		// To rxll_ctrl of rxll_ctrl.v
   input [31:0]		trn_rd;			// To rxll_ll of rxll_ll.v
   input		trn_reof_n;		// To rxll_ll of rxll_ll.v
   input		trn_rsof_n;		// To rxll_ll of rxll_ll.v
   input		trn_rsrc_dsc_n;		// To rxll_ll of rxll_ll.v
   input		trn_rsrc_rdy_n;		// To rxll_ll of rxll_ll.v
   // End of automatics
   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output		rxfifo_almost_empty;	// From rxll_ctrl of rxll_ctrl.v
   output [31:0]	rxfifo_data;		// From rxll_ctrl of rxll_ctrl.v
   output		rxfifo_empty;		// From rxll_ctrl of rxll_ctrl.v
   output		rxfifo_eof;		// From rxll_ctrl of rxll_ctrl.v
   output		rxfifo_eof_rdy;		// From rxll_ctrl of rxll_ctrl.v
   output [11:0]	rxfifo_fis_hdr;		// From rxll_ll of rxll_ll.v
   output [9:0]		rxfifo_rd_count;	// From rxll_ctrl of rxll_ctrl.v
   output		rxfifo_sof;		// From rxll_ctrl of rxll_ctrl.v
   output [31:0]	rxfis_rdata;		// From rxll_ll of rxll_ll.v
   output		trn_rdst_dsc_n;		// From rxll_ll of rxll_ll.v
   output		trn_rdst_rdy_n;		// From rxll_ll of rxll_ll.v
   // End of automatics

   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire			rd_almost_empty;	// From rxll_fifo of rxll_fifo.v
   wire			rd_clk;			// From rxll_ctrl of rxll_ctrl.v
   wire [9:0]		rd_count;		// From rxll_fifo of rxll_fifo.v
   wire [35:0]		rd_do;			// From rxll_fifo of rxll_fifo.v
   wire			rd_empty;		// From rxll_fifo of rxll_fifo.v
   wire			rd_en;			// From rxll_ctrl of rxll_ctrl.v
   wire			rd_eof_rdy;		// From rxll_fifo of rxll_fifo.v
   wire			rst;			// From rxll_ctrl of rxll_ctrl.v
   wire			wr_almost_full;		// From rxll_fifo of rxll_fifo.v
   wire			wr_clk;			// From rxll_ll of rxll_ll.v
   wire [9:0]		wr_count;		// From rxll_fifo of rxll_fifo.v
   wire [35:0]		wr_di;			// From rxll_ll of rxll_ll.v
   wire			wr_en;			// From rxll_ll of rxll_ll.v
   wire			wr_full;		// From rxll_fifo of rxll_fifo.v
   // End of automatics

   rxll_ll
     rxll_ll (/*AUTOINST*/
	      // Outputs
	      .wr_di			(wr_di[35:0]),
	      .wr_en			(wr_en),
	      .wr_clk			(wr_clk),
	      .trn_rdst_rdy_n		(trn_rdst_rdy_n),
	      .trn_rdst_dsc_n		(trn_rdst_dsc_n),
	      .rxfifo_fis_hdr		(rxfifo_fis_hdr[11:0]),
	      .rxfis_rdata		(rxfis_rdata[31:0]),
	      // Inputs
	      .phyclk			(phyclk),
	      .phyreset			(phyreset),
	      .sys_clk			(sys_clk),
	      .wr_count			(wr_count[9:0]),
	      .wr_full			(wr_full),
	      .wr_almost_full		(wr_almost_full),
	      .rd_empty			(rd_empty),
	      .trn_rsof_n		(trn_rsof_n),
	      .trn_reof_n		(trn_reof_n),
	      .trn_rd			(trn_rd[31:0]),
	      .trn_rsrc_rdy_n		(trn_rsrc_rdy_n),
	      .trn_rsrc_dsc_n		(trn_rsrc_dsc_n),
	      .rxfis_raddr		(rxfis_raddr[2:0]));
   rxll_fifo
     rxll_fifo(/*AUTOINST*/
	       // Outputs
	       .wr_count		(wr_count[9:0]),
	       .wr_full			(wr_full),
	       .wr_almost_full		(wr_almost_full),
	       .rd_count		(rd_count[9:0]),
	       .rd_empty		(rd_empty),
	       .rd_almost_empty		(rd_almost_empty),
	       .rd_do			(rd_do[35:0]),
	       .rd_eof_rdy		(rd_eof_rdy),
	       // Inputs
	       .rst			(rst),
	       .wr_di			(wr_di[35:0]),
	       .wr_en			(wr_en),
	       .wr_clk			(wr_clk),
	       .rd_clk			(rd_clk),
	       .rd_en			(rd_en));

   rxll_ctrl
     rxll_ctrl (/*AUTOINST*/
		// Outputs
		.rd_clk			(rd_clk),
		.rst			(rst),
		.rd_en			(rd_en),
		.rxfifo_data		(rxfifo_data[31:0]),
		.rxfifo_sof		(rxfifo_sof),
		.rxfifo_eof		(rxfifo_eof),
		.rxfifo_rd_count	(rxfifo_rd_count[9:0]),
		.rxfifo_empty		(rxfifo_empty),
		.rxfifo_almost_empty	(rxfifo_almost_empty),
		.rxfifo_eof_rdy		(rxfifo_eof_rdy),
		// Inputs
		.sys_clk		(sys_clk),
		.sys_rst		(sys_rst),
		.phyreset		(phyreset),
		.rd_almost_empty	(rd_almost_empty),
		.rd_count		(rd_count[9:0]),
		.rd_do			(rd_do[35:0]),
		.rd_empty		(rd_empty),
		.rd_eof_rdy		(rd_eof_rdy),
		.rxfifo_rd_en		(rxfifo_rd_en),
		.rxfifo_clk		(rxfifo_clk));
   
endmodule
// 
// rxll.v ends here
