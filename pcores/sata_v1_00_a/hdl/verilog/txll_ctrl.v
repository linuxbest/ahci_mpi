// txll_ctrl.v --- 
// 
// Filename: txll_ctrl.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Thu Feb 23 17:32:14 2012 (+0800)
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
module txll_ctrl (/*AUTOARG*/
   // Outputs
   rst, wr_clk, wr_en, wr_di, txfifo_eof_poped, txfifo_count,
   txfifo_almost_full,
   // Inputs
   sys_clk, sys_rst, phyreset, wr_count, wr_full, wr_almost_full,
   wr_eof_poped, txfifo_data, txfifo_sof, txfifo_eof, txfifo_wr_en,
   txfifo_clk
   );
   input sys_clk;
   input sys_rst;
   input phyreset;
   
   output rst;
   output wr_clk;
   output wr_en;
   output [35:0] wr_di;
   input [9:0] 	 wr_count;
   input 	 wr_full;
   input 	 wr_almost_full;
   input 	 wr_eof_poped;

   output 	 txfifo_eof_poped;
   output [9:0]  txfifo_count;
   output 	 txfifo_almost_full;
   
   input [31:0]  txfifo_data;
   input 	 txfifo_sof;
   input 	 txfifo_eof;
   input 	 txfifo_wr_en;
   input 	 txfifo_clk;
   
   assign wr_di[35]    = txfifo_sof;
   assign wr_di[34]    = txfifo_eof;
   assign wr_di[33:0]  = txfifo_data;
   assign wr_en        = txfifo_wr_en;
   
   assign txfifo_count       = wr_count;
   assign txfifo_eof_poped   = wr_eof_poped;
   assign txfifo_almost_full = wr_almost_full;
   
   assign rst = phyreset;
   assign wr_clk = txfifo_clk;
endmodule
// 
// txll_ctrl.v ends here
