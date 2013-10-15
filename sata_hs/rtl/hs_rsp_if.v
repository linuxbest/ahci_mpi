// hs_rsp_if.v --- 
// 
// Filename: hs_rsp_if.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Tue Oct 15 12:21:24 2013 (-0700)
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
module hs_rsp_if (/*AUTOARG*/
   // Outputs
   outband_base, outband_prod_addr, outband_cons_index,
   // Inputs
   outband_prod_index, sys_clk, sys_rst
   );
   input sys_clk;
   input sys_rst;

   /*AUTOINOUTCOMP("mb_io", "^outband")*/   
   // Beginning of automatic in/out/inouts (from specific module)
   output [31:0]	outband_base;
   output [31:0]	outband_prod_addr;
   output [11:0]	outband_cons_index;
   input [11:0]		outband_prod_index;
   // End of automatics

   output 	 RspReq;
   output 	 RspSts;
   input 	 RspAck;
   output [4:0]  RspId;
   output [31:0] Rsp;
   input [3:0] 	 RspAddr;
   
endmodule // hs_rsp_if
// Local Variables:
// verilog-library-directories:("." "../../pcores/sata_v1_00_a/hdl/verilog" )
// verilog-library-files:(".")
// verilog-library-extensions:(".v" ".h")
// End:
// 
// hs_rsp_if.v ends here
