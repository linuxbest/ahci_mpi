// host_if.v --- 
// 
// Filename: host_if.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Mon Feb 27 21:33:06 2012 (+0800)
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
module host_if (/*AUTOARG*/
   // Outputs
   outband_base, outband_prod_addr, outband_cons_index, inband_base,
   inband_cons_addr, inband_prod_index, sys_rst, Sl_dcrDBus,
   Sl_dcrAck, interrupt, ring_enable, DBG_STOP, err_req0, err_req1,
   err_req2, err_req3,
   // Inputs
   outband_prod_index, inband_cons_index, sys_clk, DCR_Clk, DCR_Rst,
   DCR_Read, DCR_Write, DCR_ABus, DCR_Sl_DBus, err_ack0, err_ack1,
   err_ack2, err_ack3, phyclk0, phyclk1, phyclk2, phyclk3, dma_state0,
   dma_state1, dma_state2, dma_state3, npi_ict_state
   );
   input sys_clk;
   output sys_rst;
   input DCR_Clk;
   input DCR_Rst;
   
   input DCR_Read;
   input DCR_Write;
   input [0:9] DCR_ABus;
   input [0:31] DCR_Sl_DBus;
   output [0:31] Sl_dcrDBus;
   output 	 Sl_dcrAck;
   output 	 interrupt;

   /*AUTOINOUTCOMP("mb_io", "^inband")*/
   // Beginning of automatic in/out/inouts (from specific module)
   output [31:0]	inband_base;
   output [31:0]	inband_cons_addr;
   output [11:0]	inband_prod_index;
   input [11:0]		inband_cons_index;
   // End of automatics
   /*AUTOINOUTCOMP("mb_io", "^outband")*/
   // Beginning of automatic in/out/inouts (from specific module)
   output [31:0]	outband_base;
   output [31:0]	outband_prod_addr;
   output [11:0]	outband_cons_index;
   input [11:0]		outband_prod_index;
   // End of automatics

   output 		ring_enable;
   output 		DBG_STOP;

   output [7:0] 	err_req0;
   output [7:0] 	err_req1;
   output [7:0] 	err_req2;
   output [7:0] 	err_req3;
   input [7:0] 		err_ack0;   
   input [7:0] 		err_ack1;
   input [7:0] 		err_ack2;
   input [7:0] 		err_ack3;

   input		phyclk0;
   input		phyclk1;
   input		phyclk2;
   input		phyclk3;

   input [31:0] 	dma_state0;
   input [31:0] 	dma_state1;
   input [31:0] 	dma_state2;
   input [31:0] 	dma_state3;
   input [31:0] 	npi_ict_state;
   /**********************************************************************/
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg			DBG_STOP;
   reg			Sl_dcrAck;
   reg [0:31]		Sl_dcrDBus;
   reg [31:0]		inband_base;
   reg [31:0]		inband_cons_addr;
   reg [11:0]		inband_prod_index;
   reg			interrupt;
   reg [31:0]		outband_base;
   reg [11:0]		outband_cons_index;
   reg [31:0]		outband_prod_addr;
   reg			ring_enable;
   // End of automatics
   /**********************************************************************/
   wire [4:0] 		address;
   wire [31:0] 		writedata;
   reg [31:0] 		readdata_i;
   assign address    = DCR_ABus[5:9];
   assign writedata  = DCR_Sl_DBus;
   always @(posedge sys_clk)
     begin
	Sl_dcrAck <= #1 DCR_Write | DCR_Read;
	Sl_dcrDBus<= #1 readdata_i;
     end
   
   reg [31:0] 		irqstat;
   reg [31:0] 		irqen;
   wire [7:0] 		err_sts3;
   wire [7:0] 		err_sts2;
   wire [7:0] 		err_sts1;
   wire [7:0] 		err_sts0;
   always @(*)
     begin
	readdata_i = 32'h0;
	case (address)
	  5'h0: readdata_i = irqstat;
	  5'h1: readdata_i = irqen;
	  5'h2: readdata_i = {sys_rst, ring_enable};
	  5'h4: readdata_i = inband_base;
	  5'h5: readdata_i = inband_cons_addr;
	  5'h6: readdata_i = inband_prod_index;
	  5'h7: readdata_i = inband_cons_index;
	  5'h8: readdata_i = outband_base;
	  5'h9: readdata_i = outband_prod_addr;
	  5'ha: readdata_i = outband_cons_index;
	  5'hb: readdata_i = outband_prod_index;
	  5'hc: readdata_i = {err_sts3, err_sts2, err_sts1, err_sts0};

	  5'h10: readdata_i = dma_state0;
	  5'h11: readdata_i = dma_state1;
	  5'h12: readdata_i = dma_state2;
	  5'h13: readdata_i = dma_state3;
	  
	  5'h1f: readdata_i = npi_ict_state;
	endcase
     end // always @ (*)
   always @(posedge sys_clk)
     begin
	if (DCR_Rst)
	  begin
	     ring_enable <= #1 1'b0;
	  end
	else if (DCR_Write && address == 5'h2)
	  begin
	     ring_enable <= #1 writedata[0];
	  end
     end // always @ (posedge sys_clk)
   reg [31:0] rst_sync;
   reg 	      rst_i;
   always @(posedge sys_clk)
     begin
	if (DCR_Rst || (DCR_Write && address == 5'h2 && writedata[1]))
	  begin
	     rst_sync <= #1 32'hffff_ffff;
	  end
	else
	  begin
	     rst_sync <= #1 rst_sync << 1;
	  end
     end // always @ (posedge sys_clk)
   always @(posedge sys_clk)
     begin
	if (DCR_Rst)
	  begin
	     DBG_STOP <= #1 1'b0;
	  end
	else if (DCR_Write && address == 5'h2)
	  begin
	     DBG_STOP <= #1 writedata[2];
	  end
     end // always @ (posedge sys_clk)
   assign sys_rst = rst_sync[31];
   always @(posedge sys_clk)
     begin
	if (DCR_Write && address == 5'h4 && ~ring_enable)
	  inband_base       <= #1 writedata;
	if (DCR_Write && address == 5'h5 && ~ring_enable)
	  inband_cons_addr  <= #1 writedata;
	if (DCR_Write && address == 5'h6)
	  inband_prod_index <= #1 writedata;
	
	if (DCR_Write && address == 5'h8 && ~ring_enable)
	  outband_base      <= #1 writedata;
	if (DCR_Write && address == 5'h9 && ~ring_enable)
	  outband_prod_addr <= #1 writedata; 
	if (DCR_Write && address == 5'ha)
	  outband_cons_index<= #1 writedata;
     end // always @ (posedge sys_clk)
   always @(posedge sys_clk)
     begin
	irqstat[0]    <= #1 outband_prod_index != outband_cons_index;
	irqstat[31:1] <= #1 0;
     end
   always @(posedge sys_clk)
     begin
	if (sys_rst)
	  begin
	     irqen <= #1 32'h0;
	  end
	else if (DCR_Write && address == 5'h1)
	  begin
	     irqen <= #1 writedata;
	  end
     end // always @ (posedge sys_clk)

   always @(posedge sys_clk)
     begin
	interrupt <= #1 |(irqen & irqstat);
     end

   wire [7:0] err_wdata0;
   wire [7:0] err_wdata1;
   wire [7:0] err_wdata2;
   wire [7:0] err_wdata3;   
   assign err_wdata0 = writedata[7:0];
   assign err_wdata1 = writedata[15:8];
   assign err_wdata2 = writedata[23:16];
   assign err_wdata3 = writedata[31:24];
   
   wire       err_we;
   assign err_we = DCR_Write && address == 5'hc;
   
   /*err_reg AUTO_TEMPLATE "\([0-9]\)"
    (
    .err_req  (err_req@[]),
    .err_ack  (err_ack@[]),
    .err_sts  (err_sts@[]),    
    .err_wdata(err_wdata@[]),
    .phyclk   (phyclk@[]),
    )*/
   err_reg perr0(/*AUTOINST*/
		 // Outputs
		 .err_req		(err_req0[7:0]),	 // Templated
		 .err_sts		(err_sts0[7:0]),	 // Templated
		 // Inputs
		 .sys_clk		(sys_clk),
		 .sys_rst		(sys_rst),
		 .phyclk		(phyclk0),		 // Templated
		 .err_we		(err_we),
		 .err_wdata		(err_wdata0[7:0]),	 // Templated
		 .err_ack		(err_ack0[7:0]));	 // Templated
   err_reg perr1(/*AUTOINST*/
		 // Outputs
		 .err_req		(err_req1[7:0]),	 // Templated
		 .err_sts		(err_sts1[7:0]),	 // Templated
		 // Inputs
		 .sys_clk		(sys_clk),
		 .sys_rst		(sys_rst),
		 .phyclk		(phyclk1),		 // Templated
		 .err_we		(err_we),
		 .err_wdata		(err_wdata1[7:0]),	 // Templated
		 .err_ack		(err_ack1[7:0]));	 // Templated
   err_reg perr2(/*AUTOINST*/
		 // Outputs
		 .err_req		(err_req2[7:0]),	 // Templated
		 .err_sts		(err_sts2[7:0]),	 // Templated
		 // Inputs
		 .sys_clk		(sys_clk),
		 .sys_rst		(sys_rst),
		 .phyclk		(phyclk2),		 // Templated
		 .err_we		(err_we),
		 .err_wdata		(err_wdata2[7:0]),	 // Templated
		 .err_ack		(err_ack2[7:0]));	 // Templated
   err_reg perr3(/*AUTOINST*/
		 // Outputs
		 .err_req		(err_req3[7:0]),	 // Templated
		 .err_sts		(err_sts3[7:0]),	 // Templated
		 // Inputs
		 .sys_clk		(sys_clk),
		 .sys_rst		(sys_rst),
		 .phyclk		(phyclk3),		 // Templated
		 .err_we		(err_we),
		 .err_wdata		(err_wdata3[7:0]),	 // Templated
		 .err_ack		(err_ack3[7:0]));	 // Templated
   
endmodule
// 
// host_if.v ends here
