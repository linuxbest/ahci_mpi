// txll_ll.v --- 
// 
// Filename: txll_ll.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Fri Sep 10 12:58:06 2010 (+0800)
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
module txll_ll (/*AUTOARG*/
   // Outputs
   trn_td, trn_tsof_n, trn_teof_n, trn_tsrc_rdy_n, trn_tsrc_dsc_n,
   rd_clk, rd_en,
   // Inputs
   phyclk, phyreset, trn_tdst_rdy_n, trn_tdst_dsc_n, rd_count,
   rd_empty, rd_almost_empty, rd_do, rd_eof_rdy
   );
   input phyclk;
   input phyreset;
 
   output [31:0] trn_td;
   output        trn_tsof_n;
   output        trn_teof_n;
   output        trn_tsrc_rdy_n;
   output        trn_tsrc_dsc_n;
   input         trn_tdst_rdy_n;
   input         trn_tdst_dsc_n;
   
   input [9:0] 	 rd_count;
   input 	 rd_empty;
   input 	 rd_almost_empty;
   input [35:0]  rd_do;
   output 	 rd_clk;
   output 	 rd_en;
   input 	 rd_eof_rdy;

   /**********************************************************************/
   /*AUTOREG*/
   /**********************************************************************/
   assign trn_tsrc_dsc_n   = 1'b1; /* TODO */
   assign trn_tsrc_rdy_n   = rd_empty;
   assign rd_en            = trn_tsrc_rdy_n == 1'b0 && trn_tdst_rdy_n == 1'b0;
   assign trn_td           = rd_do[31:0];
   assign trn_tsof_n       = ~rd_do[35];
   assign trn_teof_n       = ~rd_do[34];
   assign rd_clk           = phyclk;
endmodule
// 
// txll_ll.v ends here
