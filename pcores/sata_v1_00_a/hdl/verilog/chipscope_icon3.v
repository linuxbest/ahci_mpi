// chipscope_icon3.v --- 
// 
// Filename: chipscope_icon3.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Wed Aug 15 20:10:29 2012 (+0800)
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
module chipscope_icon3 (/*AUTOARG*/
   // Inouts
   CONTROL0, CONTROL1, CONTROL2
   );
   inout [35 : 0] CONTROL0;
   inout [35 : 0] CONTROL1;
   inout [35 : 0] CONTROL2;
endmodule
// 
// chipscope_icon3.v ends here
