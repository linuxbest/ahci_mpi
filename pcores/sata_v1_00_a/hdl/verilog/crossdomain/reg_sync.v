// reg_sync.v --- 
// 
// Filename: reg_sync.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Fri Sep  3 09:34:21 2010 (+0800)
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
module reg_sync (/*AUTOARG*/
   // Outputs
   sts,
   // Inputs
   wclk, set, rst, rclk
   );
   input wclk;
   input set;
   input rst;

   input rclk;
   output sts;

   reg 	  tag;
   reg [2:0] sync;
   always @(posedge wclk or posedge rst)
     begin
	if (rst)
	  begin
	     tag <= #1 1'b0;
	  end
	else if (set)
	  begin
	     tag <= #1 ~tag;
	  end
     end // always @ (posedge wclk)
   always @(posedge rclk or posedge rst)
     begin
	if (rst)
	  begin
	     sync <= #1 0;	     
	  end
	else
	  begin
	     sync <= #1 {sync[1:0], tag};
	  end
     end
   assign sts = sync[2] ^ sync[1];
   // synthesis attribute ASYNC_REG of tag  is TRUE;
   // synthesis attribute ASYNC_REG of sync is TRUE;
endmodule
// 
// reg_sync.v ends here
