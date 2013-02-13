// txll.v --- 
// 
// Filename: txll.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Thu Feb 23 17:32:18 2012 (+0800)
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
module txll (/*AUTOARG*/
   // Outputs
   txfifo_eof_poped, txfifo_count, txfifo_almost_full, trn_tsrc_rdy_n,
   trn_tsrc_dsc_n, trn_tsof_n, trn_teof_n, trn_td,
   // Inputs
   txfifo_wr_en, txfifo_sof, txfifo_eof, txfifo_data, txfifo_clk,
   trn_tdst_rdy_n, trn_tdst_dsc_n, phyreset, phyclk, sys_clk, sys_rst
   );
   input sys_clk;
   input sys_rst;

   /*AUTOINPUT*/
   // Beginning of automatic inputs (from unused autoinst inputs)
   input		phyclk;			// To txll_ll of txll_ll.v
   input		phyreset;		// To txll_ll of txll_ll.v, ...
   input		trn_tdst_dsc_n;		// To txll_ll of txll_ll.v
   input		trn_tdst_rdy_n;		// To txll_ll of txll_ll.v
   input		txfifo_clk;		// To txll_ctrl of txll_ctrl.v
   input [31:0]		txfifo_data;		// To txll_ctrl of txll_ctrl.v
   input		txfifo_eof;		// To txll_ctrl of txll_ctrl.v
   input		txfifo_sof;		// To txll_ctrl of txll_ctrl.v
   input		txfifo_wr_en;		// To txll_ctrl of txll_ctrl.v
   // End of automatics
   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output [31:0]	trn_td;			// From txll_ll of txll_ll.v
   output		trn_teof_n;		// From txll_ll of txll_ll.v
   output		trn_tsof_n;		// From txll_ll of txll_ll.v
   output		trn_tsrc_dsc_n;		// From txll_ll of txll_ll.v
   output		trn_tsrc_rdy_n;		// From txll_ll of txll_ll.v
   output		txfifo_almost_full;	// From txll_ctrl of txll_ctrl.v
   output [9:0]		txfifo_count;		// From txll_ctrl of txll_ctrl.v
   output		txfifo_eof_poped;	// From txll_ctrl of txll_ctrl.v
   // End of automatics

   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire			rd_almost_empty;	// From txll_fifo of txll_fifo.v
   wire			rd_clk;			// From txll_ll of txll_ll.v
   wire [9:0]		rd_count;		// From txll_fifo of txll_fifo.v
   wire [35:0]		rd_do;			// From txll_fifo of txll_fifo.v
   wire			rd_empty;		// From txll_fifo of txll_fifo.v
   wire			rd_en;			// From txll_ll of txll_ll.v
   wire			rd_eof_rdy;		// From txll_fifo of txll_fifo.v
   wire			rst;			// From txll_ctrl of txll_ctrl.v
   wire			wr_almost_full;		// From txll_fifo of txll_fifo.v
   wire			wr_clk;			// From txll_ctrl of txll_ctrl.v
   wire [9:0]		wr_count;		// From txll_fifo of txll_fifo.v
   wire [35:0]		wr_di;			// From txll_ctrl of txll_ctrl.v
   wire			wr_en;			// From txll_ctrl of txll_ctrl.v
   wire			wr_eof_poped;		// From txll_fifo of txll_fifo.v
   wire			wr_full;		// From txll_fifo of txll_fifo.v
   // End of automatics

   txll_ll
     txll_ll (/*AUTOINST*/
	      // Outputs
	      .trn_td			(trn_td[31:0]),
	      .trn_tsof_n		(trn_tsof_n),
	      .trn_teof_n		(trn_teof_n),
	      .trn_tsrc_rdy_n		(trn_tsrc_rdy_n),
	      .trn_tsrc_dsc_n		(trn_tsrc_dsc_n),
	      .rd_clk			(rd_clk),
	      .rd_en			(rd_en),
	      // Inputs
	      .phyclk			(phyclk),
	      .phyreset			(phyreset),
	      .trn_tdst_rdy_n		(trn_tdst_rdy_n),
	      .trn_tdst_dsc_n		(trn_tdst_dsc_n),
	      .rd_count			(rd_count[9:0]),
	      .rd_empty			(rd_empty),
	      .rd_almost_empty		(rd_almost_empty),
	      .rd_do			(rd_do[35:0]),
	      .rd_eof_rdy		(rd_eof_rdy));

   txll_fifo
     txll_fifo (/*AUTOINST*/
		// Outputs
		.wr_count		(wr_count[9:0]),
		.wr_full		(wr_full),
		.wr_almost_full		(wr_almost_full),
		.wr_eof_poped		(wr_eof_poped),
		.rd_count		(rd_count[9:0]),
		.rd_empty		(rd_empty),
		.rd_almost_empty	(rd_almost_empty),
		.rd_do			(rd_do[35:0]),
		.rd_eof_rdy		(rd_eof_rdy),
		// Inputs
		.rst			(rst),
		.wr_di			(wr_di[35:0]),
		.wr_en			(wr_en),
		.wr_clk			(wr_clk),
		.rd_clk			(rd_clk),
		.rd_en			(rd_en));
   txll_ctrl
     txll_ctrl (/*AUTOINST*/
		// Outputs
		.rst			(rst),
		.wr_clk			(wr_clk),
		.wr_en			(wr_en),
		.wr_di			(wr_di[35:0]),
		.txfifo_eof_poped	(txfifo_eof_poped),
		.txfifo_count		(txfifo_count[9:0]),
		.txfifo_almost_full	(txfifo_almost_full),
		// Inputs
		.sys_clk		(sys_clk),
		.sys_rst		(sys_rst),
		.phyreset		(phyreset),
		.wr_count		(wr_count[9:0]),
		.wr_full		(wr_full),
		.wr_almost_full		(wr_almost_full),
		.wr_eof_poped		(wr_eof_poped),
		.txfifo_data		(txfifo_data[31:0]),
		.txfifo_sof		(txfifo_sof),
		.txfifo_eof		(txfifo_eof),
		.txfifo_wr_en		(txfifo_wr_en),
		.txfifo_clk		(txfifo_clk));
   
endmodule
// 
// txll.v ends here
