// rxll_fifo.v --- 
// 
// Filename: rxll_fifo.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Fri Sep 10 12:46:03 2010 (+0800)
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
module rxll_fifo (/*AUTOARG*/
   // Outputs
   wr_count, wr_full, wr_almost_full, rd_count, rd_empty,
   rd_almost_empty, rd_do, rd_eof_rdy,
   // Inputs
   rst, wr_di, wr_en, wr_clk, rd_clk, rd_en
   );
   input rst;
   
   output [9:0] wr_count;
   output 	wr_full;
   output       wr_almost_full;
   input [35:0] wr_di;
   input 	wr_en;
   input 	wr_clk;
   
   output [9:0] rd_count;
   output 	rd_empty;
   output       rd_almost_empty;
   output [35:0] rd_do;
   input 	 rd_clk;
   input 	 rd_en;
   output 	 rd_eof_rdy;
   reg	 	 rd_eof_rdy;
  
   wire          rd_err;
   wire          wr_err;
   FIFO18_36
     fifo16 (
	     // Outputs
	     .ALMOSTEMPTY		(rd_almost_empty),
	     .ALMOSTFULL		(wr_almost_full),
	     .DO			(rd_do[31:0]),
	     .DOP			(rd_do[35:32]),
	     .EMPTY			(rd_empty),
	     .FULL			(wr_full),
	     .RDCOUNT			(rd_count),
	     .RDERR			(rd_err),
	     .WRCOUNT			(wr_count),
	     .WRERR			(wr_err),
	     // Inputs
	     .DI			(wr_di[31:0]),
	     .DIP			(wr_di[35:32]),
	     .RDCLK			(rd_clk),
	     .RDEN			(rd_en),
	     .RST			(rst),
	     .WRCLK			(wr_clk),
	     .WREN			(wr_en));
   defparam fifo16.FIRST_WORD_FALL_THROUGH = "TRUE";
   defparam fifo16.ALMOST_EMPTY_OFFSET = 9'h100;   

   wire 	 wr_eof;
   reg_sync
     eof (.wclk(wr_clk),
	  .rclk(rd_clk),
	  .rst(rst),
	  .set(wr_en && wr_di[34]),
	  .sts(wr_eof));
   always @(posedge rd_clk)
     begin
	if (rst)
	  begin
	     rd_eof_rdy <= #1 1'b0;
	  end
	else if (wr_eof)
	  begin
	     rd_eof_rdy <= #1 1'b1;
	  end
	else if (rd_en && rd_do[34])
	  begin
	     rd_eof_rdy <= #1 1'b0;
	  end
     end
endmodule
// 
// rxll_fifo.v ends here
