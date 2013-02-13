// chipscope_ila_128x1.v --- 
// 
// Filename: chipscope_ila_128x1.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Wed Aug 15 20:11:06 2012 (+0800)
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
module chipscope_ila_128x1 (/*AUTOARG*/
   // Outputs
   TRIG_OUT,
   // Inouts
   CONTROL,
   // Inputs
   CLK, TRIG0
   );
   input CLK;
   output TRIG_OUT;
   inout [35 : 0] CONTROL;
   input [127 : 0] TRIG0;
endmodule
// 
// chipscope_ila_128x1.v ends here
