// pim_dbg.v --- 
// 
// Filename: pim_dbg.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Tue Aug 14 16:19:41 2012 (+0800)
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
module pim_dbg64 (/*AUTOARG*/
   // Outputs
   PIM_dbg,
   // Inputs
   PIM_Addr, PIM_AddrReq, PIM_AddrAck, PIM_InitDone, PIM_RNW,
   PIM_RdFIFO_Data, PIM_RdFIFO_Empty, PIM_RdFIFO_Flush,
   PIM_RdFIFO_Latency, PIM_RdFIFO_Pop, PIM_RdFIFO_RdWdAddr,
   PIM_RdModWr, PIM_Size, PIM_WrFIFO_AlmostFull, PIM_WrFIFO_BE,
   PIM_WrFIFO_Data, PIM_WrFIFO_Empty, PIM_WrFIFO_Flush,
   PIM_WrFIFO_Push
   );
   input [31:0] 	PIM_Addr;
   input 		PIM_AddrReq;
   input 		PIM_AddrAck;
   input 		PIM_InitDone;	
   input 		PIM_RNW;	
   input [63:0] 	PIM_RdFIFO_Data;
   input 		PIM_RdFIFO_Empty;
   input 		PIM_RdFIFO_Flush;
   input [1:0] 		PIM_RdFIFO_Latency;	
   input 		PIM_RdFIFO_Pop;
   input [3:0] 		PIM_RdFIFO_RdWdAddr;	
   input 		PIM_RdModWr;
   input [3:0] 		PIM_Size;		
   input 		PIM_WrFIFO_AlmostFull;
   input [7:0] 		PIM_WrFIFO_BE;		
   input [63:0] 	PIM_WrFIFO_Data;	
   input 		PIM_WrFIFO_Empty;
   input 		PIM_WrFIFO_Flush;
   input 		PIM_WrFIFO_Push;
   
   output [191:0] 	PIM_dbg;
   
   assign PIM_dbg[31:0]    = PIM_Addr;
   assign PIM_dbg[32]      = PIM_AddrAck;
   assign PIM_dbg[33]      = PIM_InitDone;
   assign PIM_dbg[34]      = PIM_RNW;
   assign PIM_dbg[35]      = PIM_RdFIFO_Empty;
   assign PIM_dbg[36]      = PIM_RdFIFO_Flush;
   assign PIM_dbg[38:37]   = PIM_RdFIFO_Latency;
   assign PIM_dbg[39]      = PIM_RdFIFO_Pop;
   assign PIM_dbg[43:40]   = PIM_RdFIFO_RdWdAddr;
   assign PIM_dbg[44]      = PIM_RdModWr;
   assign PIM_dbg[48:45]   = PIM_Size;
   assign PIM_dbg[49]      = PIM_WrFIFO_AlmostFull;
   assign PIM_dbg[50]      = PIM_WrFIFO_Empty;
   assign PIM_dbg[51]      = PIM_WrFIFO_Flush;
   assign PIM_dbg[59:52]   = PIM_WrFIFO_BE;
   assign PIM_dbg[60]      = PIM_AddrReq;
   assign PIM_dbg[61]      = PIM_WrFIFO_Push;
   
   assign PIM_dbg[127:64]   = PIM_RdFIFO_Data;
   assign PIM_dbg[191:128]  = PIM_WrFIFO_Data;
endmodule
// 
// pim_dbg.v ends here
