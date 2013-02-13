// ctrl.v --- 
// 
// Filename: ctrl.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Thu Feb 23 18:13:44 2012 (+0800)
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
module ctrl (/*AUTOARG*/
   // Outputs
   trn_cdst_rdy_n, trn_cdst_dsc_n, trn_cdst_lock_n, cxfifo_irq,
   error_code,
   // Inputs
   trn_csof_n, trn_ceof_n, trn_cd, trn_csrc_rdy_n, trn_csrc_dsc_n,
   phyclk, phyreset, sys_clk, sys_rst, cxfifo_ack, cxfifo_ok, dma_req
   );
   input phyclk;
   input phyreset;

   input sys_clk;
   input sys_rst;

   /*AUTOINOUTCOMP("sata_link", "^trn_c")*/
   // Beginning of automatic in/out/inouts (from specific module)
   output		trn_cdst_rdy_n;
   output		trn_cdst_dsc_n;
   output		trn_cdst_lock_n;
   input		trn_csof_n;
   input		trn_ceof_n;
   input [31:0]		trn_cd;
   input		trn_csrc_rdy_n;
   input		trn_csrc_dsc_n;
   // End of automatics
   /**********************************************************************/
   input 		cxfifo_ack;
   input 		cxfifo_ok;
   output 		cxfifo_irq;
   output [3:0] 	error_code;
   /**********************************************************************/
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg			cxfifo_irq;
   reg [3:0]		error_code;
   reg			trn_cdst_lock_n;
   // End of automatics
   input 		dma_req;
   /**********************************************************************/
   reg [7:0] 		src_rdyn;
   reg [3:0] 		cd0;
   reg [3:0] 		cd1;
   always @(posedge sys_clk)
     begin
	src_rdyn[0] <= #1 trn_csrc_rdy_n;
	src_rdyn[1] <= #1 src_rdyn[0];
	src_rdyn[2] <= #1 src_rdyn[1];
	src_rdyn[3] <= #1 src_rdyn[2];
	src_rdyn[4] <= #1 src_rdyn[3];
	src_rdyn[5] <= #1 src_rdyn[4];
	src_rdyn[6] <= #1 src_rdyn[5];
	src_rdyn[7] <= #1 src_rdyn[6];
	cd0         <= #1 trn_cd;
	cd1         <= #1 cd0;
     end // always @ (posedge sys_clk)
   always @(posedge sys_clk)
     begin
	cxfifo_irq <= #1 ~src_rdyn[7] & ~dma_req && ~src_rdyn[1];
	error_code <= #1 cd1;
     end

   reg tag_ack;
   reg tag_ok;
   always @(posedge sys_clk)
     begin
	if (sys_rst)
	  begin
	     tag_ack <= #1 1'b0;
	  end
	else if (cxfifo_ack)
	  begin
	     tag_ack <= #1 ~tag_ack;
	  end
     end // always @ (posedge sys_clk)
   always @(posedge sys_clk)
     begin
	if (sys_rst)
	  begin
	     tag_ok <= #1 1'b0;
	  end
	else if (cxfifo_ok)
	  begin
	     tag_ok <= #1 ~tag_ok;
	  end
     end // always @ (posedge sys_clk)

   reg [2:0] sync_ack;
   reg [2:0] sync_ok;
   always @(posedge phyclk)
     begin
	sync_ack <= #1 {sync_ack[1:0], tag_ack};
	sync_ok  <= #1 {sync_ok[1:0], tag_ok};
     end
   
   assign trn_cdst_rdy_n = ~(sync_ack[2] ^ sync_ack[1]);
   assign trn_cdst_dsc_n = ~(sync_ok[2] ^ sync_ok[1]);
endmodule
// 
// ctrl.v ends here
