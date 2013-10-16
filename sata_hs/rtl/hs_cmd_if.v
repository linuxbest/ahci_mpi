// hs_cmd_if.v --- 
// 
// Filename: hs_cmd_if.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Tue Oct 15 12:09:06 2013 (-0700)
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
module hs_cmd_if(/*AUTOARG*/
   // Outputs
   PhyReady, CmdAck, cmd_req, cmd_rdata,
   // Inputs
   sys_clk, sys_rst, PhyReset, CmdReq, CmdId, Cmd, CmdAddr, CmdWr,
   cmd_done, cmd_raddr
   );
   input sys_clk;
   input sys_rst;

   input PhyReset;
   output PhyReady;
   
   input         CmdReq;
   output 	 CmdAck;
   input [4:0] 	 CmdId;
   input [31:0]  Cmd;
   input [3:0] 	 CmdAddr;
   input 	 CmdWr;

   input 	 cmd_done;
   output 	 cmd_req;
   input [4:0] 	 cmd_raddr;
   output [31:0] cmd_rdata;
	 
endmodule // hs_cmd_if
// Local Variables:
// verilog-library-directories:("." "../../pcores/sata_v1_00_a/hdl/verilog" )
// verilog-library-files:(".")
// verilog-library-extensions:(".v" ".h")
// End:
// 
// hs_cmd_if.v ends here
