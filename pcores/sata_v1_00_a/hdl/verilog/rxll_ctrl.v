// rxll_ctrl.v --- 
// 
// Filename: rxll_ctrl.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Thu Feb 23 17:16:19 2012 (+0800)
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
module rxll_ctrl (/*AUTOARG*/
   // Outputs
   rd_clk, rst, rd_en, rxfifo_data, rxfifo_sof, rxfifo_eof,
   rxfifo_rd_count, rxfifo_empty, rxfifo_almost_empty, rxfifo_eof_rdy,
   // Inputs
   sys_clk, sys_rst, phyreset, rd_almost_empty, rd_count, rd_do,
   rd_empty, rd_eof_rdy, rxfifo_rd_en, rxfifo_clk
   );
   input sys_clk;
   input sys_rst;
   input phyreset;
   
   output rd_clk;
   output rst;
   input  rd_almost_empty;
   input [9:0] rd_count;
   input [35:0] rd_do;
   input 	rd_empty;
   output 	rd_en;
   input 	rd_eof_rdy;
   
   output [31:0] rxfifo_data;
   input 	 rxfifo_rd_en;
   output 	 rxfifo_sof;
   output 	 rxfifo_eof;
   output [9:0]  rxfifo_rd_count;
   output 	 rxfifo_empty;
   output 	 rxfifo_almost_empty;
   output 	 rxfifo_eof_rdy;
   input 	 rxfifo_clk;
   
   assign rxfifo_data     = rd_do[31:0];
   assign rxfifo_rd_count = rd_count;
   assign rxfifo_sof      = rd_do[35];
   assign rxfifo_eof      = rd_do[34];
   assign rxfifo_empty    = rd_empty;
   assign rxfifo_almost_empty = rd_almost_empty;
   assign rxfifo_eof_rdy  = rd_eof_rdy;
   
   assign rd_en           = rxfifo_rd_en;
   assign rst             = phyreset;
   assign rd_clk          = rxfifo_clk;
endmodule
// 
// rxll_ctrl.v ends here
