// dgio.v --- 
// 
// Filename: dgio.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Thu Feb 23 20:37:47 2012 (+0800)
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
module dgio (/*AUTOARG*/
   // Outputs
   write, writedata, address, PIM_AddrAck, PIM_RdFIFO_RdWdAddr,
   PIM_RdFIFO_Data, PIM_RdFIFO_Empty, PIM_RdFIFO_Latency,
   PIM_WrFIFO_Empty, PIM_WrFIFO_AlmostFull, PIM_InitDone,
   // Inputs
   sys_clk, sys_rst, MPMC_Clk, MPMC_Rst, readdata, irq, PIM_Addr,
   PIM_AddrReq, PIM_RNW, PIM_Size, PIM_RdModWr, PIM_RdFIFO_Flush,
   PIM_RdFIFO_Pop, PIM_WrFIFO_Data, PIM_WrFIFO_BE, PIM_WrFIFO_Push,
   PIM_WrFIFO_Flush
   );
   input sys_clk;
   input sys_rst;
   
   input MPMC_Clk;
   input MPMC_Rst;
   
   input [31:0] readdata;
   output 	write;   
   output [31:0] writedata;
   output [5:0]  address;
   input 	 irq;

   input [31:0] PIM_Addr;
   input 	PIM_AddrReq;
   input 	PIM_RNW;
   input [3:0] 	PIM_Size;
   input 	PIM_RdModWr;   
   output 	PIM_AddrAck;
   
   output [3:0] PIM_RdFIFO_RdWdAddr;
   output [31:0] PIM_RdFIFO_Data;
   input 	 PIM_RdFIFO_Flush;
   input 	 PIM_RdFIFO_Pop;
   output 	 PIM_RdFIFO_Empty;
   output [1:0]  PIM_RdFIFO_Latency;
   
   input [31:0]  PIM_WrFIFO_Data;
   input [3:0] 	 PIM_WrFIFO_BE;
   input 	 PIM_WrFIFO_Push;
   input 	 PIM_WrFIFO_Flush;
   output 	 PIM_WrFIFO_Empty;
   output 	 PIM_WrFIFO_AlmostFull;
   
   output	 PIM_InitDone;
endmodule
// 
// dgio.v ends here
