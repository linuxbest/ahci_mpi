// signal.v --- 
// 
// Filename: signal.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Thu Sep 16 10:23:34 2010 (+0800)
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
module signal (/*AUTOARG*/
   // Outputs
   clkB, signalOut,
   // Inputs
   clkA, signalIn
   );
   input clkA;
   input signalIn;

   input  clkB;
   output signalOut;
	  
   reg [1:0] SyncA_ClkB;
   always @(posedge clkB)
     begin
	SyncA_ClkB[0] <= #1 signalIn;
	SyncA_ClkB[1] <= #1 SyncA_ClkB[0];
     end
   assign signalOut = SyncA_ClkB[1];
   // synthesis attribute ASYNC_REG of SyncA_ClkB is TRUE;
endmodule
// 
// signal.v ends here
