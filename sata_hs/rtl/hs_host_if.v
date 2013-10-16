// hs_host_if.v --- 
// 
// Filename: hs_host_if.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Mon Feb 27 21:33:06 2012 (+0800)
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
module hs_host_if (/*AUTOARG*/
   // Outputs
   outband_base, outband_prod_addr, outband_cons_index, inband_base,
   inband_cons_addr, inband_prod_index, sys_rst, ring_enable,
   DBG_STOP, err_req0, err_req1, err_req2, err_req3,
   // Inputs
   outband_prod_index, inband_cons_index, sys_clk, err_ack0, err_ack1,
   err_ack2, err_ack3, phyclk0, phyclk1, phyclk2, phyclk3, dma_state0,
   dma_state1, dma_state2, dma_state3
   );
   input sys_clk;
   output sys_rst;

   /*AUTOINOUTCOMP("hs_mb_io", "^inband")*/
   // Beginning of automatic in/out/inouts (from specific module)
   output [31:0]	inband_base;
   output [31:0]	inband_cons_addr;
   output [11:0]	inband_prod_index;
   input [11:0]		inband_cons_index;
   // End of automatics
   /*AUTOINOUTCOMP("hs_mb_io", "^outband")*/
   // Beginning of automatic in/out/inouts (from specific module)
   output [31:0]	outband_base;
   output [31:0]	outband_prod_addr;
   output [11:0]	outband_cons_index;
   input [11:0]		outband_prod_index;
   // End of automatics

   output 		ring_enable;
   output 		DBG_STOP;

   output [7:0] 	err_req0;
   output [7:0] 	err_req1;
   output [7:0] 	err_req2;
   output [7:0] 	err_req3;
   input [7:0] 		err_ack0;   
   input [7:0] 		err_ack1;
   input [7:0] 		err_ack2;
   input [7:0] 		err_ack3;

   input		phyclk0;
   input		phyclk1;
   input		phyclk2;
   input		phyclk3;

   input [31:0] 	dma_state0;
   input [31:0] 	dma_state1;
   input [31:0] 	dma_state2;
   input [31:0] 	dma_state3;
   /**********************************************************************/
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg			DBG_STOP;
   reg [7:0]		err_req0;
   reg [7:0]		err_req1;
   reg [7:0]		err_req2;
   reg [7:0]		err_req3;
   reg [31:0]		inband_base;
   reg [31:0]		inband_cons_addr;
   reg [11:0]		inband_prod_index;
   reg [31:0]		outband_base;
   reg [11:0]		outband_cons_index;
   reg [31:0]		outband_prod_addr;
   reg			ring_enable;
   reg			sys_rst;
   // End of automatics
  
endmodule
// 
// hs_host_if.v ends here
