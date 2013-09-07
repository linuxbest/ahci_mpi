// dcr_if.v --- 
// 
// Filename: dcr_if.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Thu Feb 23 16:03:49 2012 (+0800)
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
// rxfifo_irq: clear by starting a dma.
// cxfifo_irq: clear by write ack/ok.
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
module dcr_if (/*AUTOARG*/
   // Outputs
   readdata, irq, StartComm, phyreset, host_rst, gtx_tune, port_state,
   dcr2cs_clk, dcr2cs_pop, dma_address, dma_length, dma_pm, dma_data,
   dma_ok, dma_req, dma_wrt, dma_sync, dma_flush, dma_eof, dma_sof,
   cxfifo_ack, cxfifo_ok, rxfis_raddr,
   // Inputs
   sys_clk, sys_rst, phyclk, address, write, writedata, Trace_FW,
   CommInit, linkup, plllock, cs2dcr_prim, cs2dcr_cnt, link_fsm2dbg,
   rx_cs2dbg, tx_cs2dbg, oob2dbg, error_code, rxfifo_fis_hdr, dma_ack,
   rxfifo_irq, cxfifo_irq, rxfis_rdata
   );
   parameter C_PORT = 0;
   parameter C_SATA_CHIPSCOPE = 0;

   input sys_clk;
   input sys_rst;

   input phyclk;

   input [5:0] address;
   input       write;
   input [31:0] writedata;
   output [31:0] readdata;
   output 	 irq;
   input [127:0] Trace_FW;
   /**********************************************************************/
   output 	 StartComm;
   input 	 CommInit;
   output 	 phyreset;
   output 	 host_rst;
   input 	 linkup;
   input 	 plllock;
   output [31:0] gtx_tune;
   output [7:0]  port_state;
   output 	 dcr2cs_clk;
   output 	 dcr2cs_pop;
   input [35:0]  cs2dcr_prim;
   input [8:0] 	 cs2dcr_cnt;
   input [127:0] link_fsm2dbg;
   input [127:0] rx_cs2dbg;
   input [127:0] tx_cs2dbg;
   input [127:0] oob2dbg;
   /**********************************************************************/   
   input [3:0] 	 error_code;
   input [11:0]  rxfifo_fis_hdr;
   output [31:0] dma_address;
   output [15:0] dma_length;
   output [3:0]  dma_pm;
   output 	 dma_data;
   output 	 dma_ok;
   output 	 dma_req;
   output 	 dma_wrt;
   output 	 dma_sync;
   output 	 dma_flush;
   output 	 dma_eof;
   output 	 dma_sof;
   input 	 dma_ack;
   input 	 rxfifo_irq;
   input 	 cxfifo_irq;
   output 	 cxfifo_ack;
   output 	 cxfifo_ok;
   /**********************************************************************/
   input [31:0]  rxfis_rdata;
   output [4:0]  rxfis_raddr;
   /**********************************************************************/
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg			cxfifo_ack;
   reg			cxfifo_ok;
   reg			dcr2cs_clk;
   reg			dcr2cs_pop;
   reg [31:0]		dma_address;
   reg			dma_data;
   reg			dma_eof;
   reg			dma_flush;
   reg [15:0]		dma_length;
   reg			dma_ok;
   reg [3:0]		dma_pm;
   reg			dma_req;
   reg			dma_sof;
   reg			dma_sync;
   reg			dma_wrt;
   reg [7:0]		port_state;
   reg [31:0]		readdata;
   // End of automatics
   
   /**********************************************************************/
   reg [31:0] 	 readdata_i;
   reg [4:0] 	 irq_stat;
   always @(*)
     begin
	readdata_i = 32'h0;
	case (address)
	  5'h0: begin
	     readdata_i[11:0] = rxfifo_fis_hdr;
	     readdata_i[15:12]= error_code;
	     readdata_i[25]   = irq_stat[4];
	     readdata_i[26]   = irq_stat[0];
	     readdata_i[27]   = irq_stat[1];
	     readdata_i[28]   = linkup;
	     readdata_i[29]   = plllock;
	     readdata_i[30]   = rxfifo_irq;
	     readdata_i[31]   = cxfifo_irq;
	  end
	  5'h4: begin
	     readdata_i[31]   = phyreset;
	     readdata_i[30]   = dma_req;
	     readdata_i[29]   = dma_ok;
	     readdata_i[28]   = dma_data;
	     readdata_i[27]   = dma_wrt;
	     readdata_i[19:16]= dma_pm;
	     readdata_i[15:0] = dma_length;
	  end
	  default: 
	    readdata_i        = rxfis_rdata;
	endcase
     end // always @ (*)
   always @(posedge sys_clk)
     begin
	readdata <= #1 readdata_i;
     end
   assign rxfis_raddr = address[4:2];
   
   reg plllock_cg;
   reg linkup_cg;
   reg [2:0] plllock_d;
   reg [2:0] linkup_d;
   always @(posedge sys_clk)
     begin
	if (sys_rst)
	  begin
	     linkup_d   <= #1 3'h0;
	     plllock_d  <= #1 3'h0;
	  end
	else begin
	   linkup_d[0]  <= #1 linkup;
	   linkup_d[1]  <= #1 linkup_d[0];
	   linkup_d[2]  <= #1 linkup_d[1];
	   plllock_d[0] <= #1 plllock;
	   plllock_d[1] <= #1 plllock_d[0];
	   plllock_d[2] <= #1 plllock_d[1];
	end
     end // always @ (posedge sys_clk)
   always @(posedge sys_clk)
     begin
	if (plllock_d[1] ^ plllock_d[2])
	  begin
	     plllock_cg <= #1 1'b1;
	  end
	else if (write && writedata[27] && address == 5'h0)
	  begin
	     plllock_cg <= #1 1'b0;
	  end
     end
   always @(posedge sys_clk)
     begin
	if (linkup_d[1] ^ linkup_d[2])
	  begin
	     linkup_cg <= #1 1'b1;
	  end
	else if (write && writedata[26] && address == 5'h0)
	  begin
	     linkup_cg <= #1 1'b0;
	  end
     end // always @ (posedge sys_clk)
   reg com;
   reg phyreset_i;
   always @(posedge sys_clk)
     begin
	cxfifo_ack <= #1 write && writedata[31] && address == 5'h0;
	cxfifo_ok  <= #1 write && writedata[30] && address == 5'h0;
	com        <= #1 write && writedata[28] && address == 5'h0;
     end
   always @(posedge sys_clk)
     begin
	if (write && address == 5'h8)
	  dma_address <= #1 writedata;
	if (write && address == 5'h4)
	  begin
	     dma_length <= #1 writedata[15:0];
	     dma_pm     <= #1 writedata[19:16];
	     dma_sof    <= #1 writedata[23];
	     dma_eof    <= #1 writedata[24];
	     dma_flush  <= #1 writedata[25];
	     dma_sync   <= #1 writedata[26];
	     dma_wrt    <= #1 writedata[27];
	     dma_data   <= #1 writedata[28];
	     dma_ok     <= #1 writedata[29];
	     dma_req    <= #1 writedata[30];
	     phyreset_i <= #1 writedata[31];
	  end
	else if (dma_ack)
	  begin
	     dma_req    <= #1 1'b0;
	  end
     end // always @ (posedge sys_clk)
   reg dma_irq;
   always @(posedge sys_clk)
     begin
	if (sys_rst || (write && address == 5'h0 && writedata[25]))
	  begin
	     dma_irq <= #1 1'b0;
	  end
	else if (dma_ack)
	  begin
	     dma_irq <= #1 1'b1;
	  end
     end // always @ (posedge sys_clk)
   always @(posedge sys_clk)
     begin
	irq_stat <= #1 {dma_irq, rxfifo_irq, cxfifo_irq, plllock_cg, linkup_cg};
     end
   assign irq = |irq_stat;

   reg [1:0] phyreset_r;
   reg [2:0] com_sync;
   reg [1:0] com_tag;
   
   assign host_rst = phyreset_r[1];
   assign phyreset = phyreset_r[1];
   assign StartComm= com_sync[2] ^ com_sync[1];
   assign gtx_tune = 32'h0;
   always @(posedge phyclk)
     begin
	phyreset_r[0] <= #1 phyreset_i;
	phyreset_r[1] <= #1 phyreset_r[0];
	com_sync      <= #1 {com_sync[1:0], com_tag[1]};
     end
   always @(posedge sys_clk)
     begin
	if (sys_rst)
	  begin
	     com_tag <= #1 1'b0;
	  end
	else if (com)
	  begin
	     com_tag <= #1 com_tag + 1'b1;
	  end
     end // always @ (posedge sys_clk) 
endmodule
// 
// dcr_if.v ends here
