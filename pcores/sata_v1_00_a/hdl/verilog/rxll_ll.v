// rxll_ll.v --- 
// 
// Filename: rxll_ll.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Fri Sep 10 12:52:26 2010 (+0800)
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
module rxll_ll (/*AUTOARG*/
   // Outputs
   wr_di, wr_en, wr_clk, trn_rdst_rdy_n, trn_rdst_dsc_n,
   rxfifo_fis_hdr, rxfis_rdata,
   // Inputs
   phyclk, phyreset, sys_clk, wr_count, wr_full, wr_almost_full,
   rd_empty, trn_rsof_n, trn_reof_n, trn_rd, trn_rsrc_rdy_n,
   trn_rsrc_dsc_n, rxfis_raddr
   );
   input phyclk;
   input phyreset;

   input sys_clk;
   
   output [35:0] wr_di;
   output 	 wr_en;
   output 	 wr_clk;
   input [9:0] 	 wr_count;
   input 	 wr_full;	// unused
   input 	 wr_almost_full;
   input         rd_empty;	// unused

   input         trn_rsof_n;
   input         trn_reof_n;
   input [31:0]  trn_rd;
   input         trn_rsrc_rdy_n;
   output        trn_rdst_rdy_n; // almostfull
   input         trn_rsrc_dsc_n; 
   output        trn_rdst_dsc_n; // unused
   
   output [11:0] rxfifo_fis_hdr;

   output [31:0] rxfis_rdata;
   input [2:0] 	 rxfis_raddr;
   /**********************************************************************/
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [11:0]		rxfifo_fis_hdr;
   reg [35:0]		wr_di;
   reg			wr_en;
   // End of automatics

   /**********************************************************************/
   reg 			ram_we;
   reg [3:0] 		waddr;
   
   reg [11:0] 		fis_hdr;
   wire [7:0]           fis_type;
   assign fis_type    = trn_rd[7:0];
   always @(posedge wr_clk)
     begin
	if (trn_rsrc_rdy_n == 1'b0 &&
	    trn_rdst_rdy_n == 1'b0 &&
	    trn_rsof_n == 1'b0 &&
	    trn_reof_n == 1'b1)/* SOF */
	  begin
	     fis_hdr           <= #1 trn_rd[11:0];
	     wr_en             <= #1 fis_type != 8'h46;
	     ram_we            <= #1 1'b1;
	     waddr             <= #1 4'h0;
	     wr_di[35]         <= #1 1'b1; /* SOF */
	     wr_di[34]         <= #1 1'b0; /* EOF */
	     wr_di[33]         <= #1 fis_type == 8'h46;
	     wr_di[32]         <= #1 1'b0;
	     wr_di[31:0]       <= #1 trn_rd;
	  end
	else if (trn_rsrc_rdy_n == 1'b0 &&
		 trn_rsof_n == 1'b1 &&
	         trn_reof_n == 1'b1) /* Data */
	  begin
	     ram_we            <= #1 1'b1;
	     waddr             <= #1 waddr + 1'b1;
	     wr_en             <= #1 1'b1;
	     wr_di[35]         <= #1 1'b0;
	     wr_di[31:0]       <= #1 trn_rd;
	  end
	else if (trn_rsrc_rdy_n == 1'b0 &&
		 trn_rsof_n == 1'b1 &&
		 trn_reof_n == 1'b0) /* EOF */
	  begin
	     ram_we            <= #1 1'b1;
	     waddr             <= #1 waddr + 1'b1;
	     wr_en             <= #1 1'b1;
	     wr_di[35]         <= #1 1'b0;
	     wr_di[34]         <= #1 1'b1;
	     wr_di[31:0]       <= #1 trn_rd;
	  end
	else if (trn_rsrc_rdy_n == 1'b0 &&
		 trn_rdst_rdy_n == 1'b0 &&
		 trn_rsof_n == 1'b0 &&
		 trn_reof_n == 1'b0) /* SOF & EOF */
	  begin
	     fis_hdr           <= #1 trn_rd[11:0];
	     ram_we            <= #1 1'b1;
	     waddr             <= #1 4'h0;
	     wr_en             <= #1 1'b1;
	     wr_di[35]         <= #1 1'b1; /* EOF */
	     wr_di[34]         <= #1 1'b1;
	     wr_di[31:0]       <= #1 trn_rd;
	  end
	else
	  begin
	     ram_we            <= #1 1'b0;
	     wr_en             <= #1 1'b0;
	  end // else: !if(link2dma_rx_push && link2dma_rx_sof && link2dma_rx_eof)
     end // always @ (posedge wr_clk)
   assign trn_rdst_dsc_n = 1'b1;
   assign trn_rdst_rdy_n = wr_almost_full;
   assign wr_clk = phyclk;
   
   reg [11:0] fis_hdr_sync;
   always @(posedge sys_clk)
     begin
	fis_hdr_sync   <= #1 fis_hdr;
	rxfifo_fis_hdr <= #1 fis_hdr_sync;
     end

   reg [31:0] ram [0:15];
   wire [31:0] ram_di;
   assign ram_di = wr_di[31:0];
   always @(posedge phyclk)
     begin
	if (ram_we)
	  begin
	     ram[waddr] <= #1 ram_di;
	  end
     end
   assign rxfis_rdata = ram[rxfis_raddr];
endmodule
// 
// rxll_ll.v ends here
