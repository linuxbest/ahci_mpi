// npi_addr_path.v --- 
// 
// Filename: npi_addr_path.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Tue Jul 31 15:34:15 2012 (+0800)
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
`timescale 1ns / 100ps
module npi_addr_path (/*AUTOARG*/
   // Outputs
   AddrAck, ReqRNW, ReqSize, ReqAddr, ReqEmpty, ReqId, InitDone,
   // Inputs
   Clk, Rst, RNW, Size, Addr, AddrReq, ReqPop, PhyDone
   );
   parameter         C_FAMILY        = "virtex5";
   parameter integer C_PI_ADDR_WIDTH = 32;
   
   input 	     Clk;
   input 	     Rst;
   
   input 	     RNW;
   input [3:0] 	     Size;
   input [C_PI_ADDR_WIDTH-1:0] Addr;
   input 		       AddrReq;
   output 		       AddrAck;

   output 		       ReqRNW;
   output [3:0] 	       ReqSize;
   output [C_PI_ADDR_WIDTH-1:0] ReqAddr;
   output 			ReqEmpty;
   output [2:0]			ReqId;
   input 			ReqPop;

   input 			PhyDone;
   output 			InitDone;

   reg 				InitDone;
   always @(posedge Clk)
     begin
	InitDone  <= #1 PhyDone;
     end
   /***************************************************************************/
   localparam FIFO_WIDTH = C_PI_ADDR_WIDTH + 4 + 1 + 3;

   reg [2:0] 			Id;
   reg 				AddrAck;
   wire 			fifo_pop;
   wire [FIFO_WIDTH-1:0] 	qualifier_i;
   wire 			fifo_empty_i;
   wire 			fifo_empty;
   wire 			fifo_full;
   srl16e_fifo
     #(.c_width  (FIFO_WIDTH),
       .c_awidth (3),
       .c_depth  (8))
   srl16e_fifo
     (.Clk   (Clk),
      .Rst   (Rst),
      .WR_EN (AddrAck),
      .RD_EN (fifo_pop),
      .DIN   ({Id, RNW, Size, Addr}),
      .DOUT  (qualifier_i),
      .FULL  (fifo_full),
      .EMPTY (fifo_empty_i));
   
   fifo_pipeline
     #(.C_DWIDTH     (FIFO_WIDTH),
       .C_INV_EXISTS (1))
   fifo_pipeline
     (.Clk   (Clk),
      .Rst   (Rst),
      .FIFO_Exists (fifo_empty_i),
      .FIFO_Read   (fifo_pop),
      .FIFO_Data   (qualifier_i),
      .PIPE_Exists (ReqEmpty),
      .PIPE_Read   (ReqPop),
      .PIPE_Data   ({ReqId, ReqRNW, ReqSize, ReqAddr}));

   reg [1:0] 			pipe;
   always @(posedge Clk)
     begin
	if (Rst)
	  begin
	     pipe <= #1 0;
	  end
	else
	  case ({AddrAck, ReqPop})
	    2'b10: pipe <= #1 pipe + 1'b1;
	    2'b01: pipe <= #1 pipe - 1'b1;
	  endcase
     end // always @ (posedge Clk)
   
   always @(posedge Clk)
     begin
	if (Rst)
	  begin
	     AddrAck <= #1 1'b0;
	  end
	else 
	  begin
	     AddrAck <= #1 AddrReq && pipe[1] == 0 && ~AddrAck;
	  end
     end // always @ (posedge Clk)
   always @(posedge Clk)
     begin
	if (Rst)
	  begin
	     Id <= #1 0;
	  end
	else if (AddrAck)
	  begin
	     Id <= #1 Id + 1'b1;
	  end
     end // always @ (posedge Clk)
endmodule
// 
// npi_addr_path.v ends here
