// err_reg.v --- 
// 
// Filename: err_reg.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Thu May 10 10:21:30 2012 (+0800)
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
module err_reg (/*AUTOARG*/
   // Outputs
   err_req, err_sts,
   // Inputs
   sys_clk, sys_rst, phyclk, err_we, err_wdata, err_ack
   );
   input sys_clk;
   input sys_rst;
   input phyclk;
   
   input err_we;
   input [7:0] err_wdata;
   
   input [7:0] err_ack;
   output [7:0] err_req;
   output [7:0] err_sts;

   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [7:0]		err_req;
   reg [7:0]		err_sts;
   // End of automatics

   wire [7:0] 	err_ack_sync;
   genvar 	i;
   generate
      for (i = 0; i < 8; i = i + 1)
	begin: err_reg_block
	   always @(posedge sys_clk)
	     begin
		if (sys_rst || err_ack_sync[i])
		  begin
		     err_sts[i] <= #1 1'b0;
		  end
		else if (err_we && err_wdata[i])
		  begin
		     err_sts[i] <= #1 1'b1;
		  end
	     end // always @ (posedge sys_clk)
	   reg_sync ack_sync (.wclk(phyclk),
			      .rclk(sys_clk),
			      .rst(sys_rst),
			      .set(err_ack[i]),
			      .sts(err_ack_sync[i]));
	end
   endgenerate

   reg [7:0] err_sts_d0;
   // sync err_sts -> err_req
   always @(posedge phyclk)
     begin
	err_sts_d0  <= #1 err_sts;
	err_req     <= #1 err_sts_d0;
     end
endmodule
// 
// err_reg.v ends here
