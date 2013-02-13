// npi_pi_enable.v --- 
// 
// Filename: npi_pi_enable.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Sun Aug 12 17:57:47 2012 (+0800)
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
module npi_pi_enable (/*AUTOARG*/
   // Outputs
   AddrAck, PIM_AddrReq, PIM_RdFIFO_Pop, PIM_WrFIFO_Push,
   // Inputs
   sys_clk, sys_rst, MPMC_Clk, AddrReq, RdFIFO_Pop, WrFIFO_Push,
   PIM_AddrAck
   );
   input sys_clk;
   input sys_rst;

   input MPMC_Clk;

   // from the dma
   input AddrReq;
   output AddrAck;
   input  RdFIFO_Pop;
   input  WrFIFO_Push;

   // from the  npi
   output PIM_AddrReq;
   input  PIM_AddrAck;
   output PIM_RdFIFO_Pop;
   output PIM_WrFIFO_Push;
   /************************************************************************/
   // base on dualxcl.v   
   wire  clk_pi_enable;   
   mpmc_sample_cycle sample_cycle(.sample_cycle(clk_pi_enable),
				  .fast_clk(MPMC_Clk),
				  .slow_clk(sys_clk));
   reg addrack_hold;
   always @(posedge MPMC_Clk)
     begin
	if (clk_pi_enable)
	  begin
	     addrack_hold <= #1 1'b0;
	  end
	else
	  begin
	     addrack_hold <= #1 PIM_AddrAck;
	  end
     end // always @ (posedge MPMC_Clk)
   assign PIM_AddrReq = AddrReq & ~addrack_hold;
   assign AddrAck     = addrack_hold | PIM_AddrAck;
   
   reg wrfifo_mask;   
   always @(posedge MPMC_Clk)
     begin
	if (clk_pi_enable)
	  begin
	     wrfifo_mask <= #1 1'b0;
	  end
	else
	  begin
	     wrfifo_mask <= #1 WrFIFO_Push;
	  end
     end // always @ (posedge MPMC_Clk)
   assign PIM_WrFIFO_Push = WrFIFO_Push & ~wrfifo_mask;
   assign PIM_RdFIFO_Pop  = RdFIFO_Pop & clk_pi_enable;
endmodule
// 
// npi_pi_enable.v ends here
