// hs_dma.v --- 
// 
// Filename: hs_dma.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Mon Oct 14 16:38:29 2013 (-0700)
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
module hs_dma (/*AUTOARG*/
   // Outputs
   rxfifo_clk, rxfifo_rd_en, txfifo_clk, txfifo_data, txfifo_eof,
   txfifo_sof, txfifo_wr_en, dma_ack,
   // Inputs
   rxfifo_almost_empty, rxfifo_data, rxfifo_empty, rxfifo_eof,
   rxfifo_eof_rdy, rxfifo_fis_hdr, rxfifo_rd_count, rxfifo_sof,
   txfifo_almost_full, txfifo_count, txfifo_eof_poped, dma_address,
   dma_length, dma_pm, dma_data, dma_ok, dma_req, dma_wrt, dma_sync,
   dma_flush, dma_eof, dma_sof, sys_clk, sys_rst
   );
   input sys_clk;
   input sys_rst;

   /*AUTOINOUTCOMP("hs_dcr_if", "^dma_")*/
   // Beginning of automatic in/out/inouts (from specific module)
   output		dma_ack;
   input [31:0]		dma_address;
   input [15:0]		dma_length;
   input [3:0]		dma_pm;
   input		dma_data;
   input		dma_ok;
   input		dma_req;
   input		dma_wrt;
   input		dma_sync;
   input		dma_flush;
   input		dma_eof;
   input		dma_sof;
   // End of automatics
   /*AUTOINOUTCOMP("txll", "^txfifo")*/
   // Beginning of automatic in/out/inouts (from specific module)
   output		txfifo_clk;
   output [31:0]	txfifo_data;
   output		txfifo_eof;
   output		txfifo_sof;
   output		txfifo_wr_en;
   input		txfifo_almost_full;
   input [9:0]		txfifo_count;
   input		txfifo_eof_poped;
   // End of automatics
   /*AUTOINOUTCOMP("rxll", "^rxfifo")*/
   // Beginning of automatic in/out/inouts (from specific module)
   output		rxfifo_clk;
   output		rxfifo_rd_en;
   input		rxfifo_almost_empty;
   input [31:0]		rxfifo_data;
   input		rxfifo_empty;
   input		rxfifo_eof;
   input		rxfifo_eof_rdy;
   input [11:0]		rxfifo_fis_hdr;
   input [9:0]		rxfifo_rd_count;
   input		rxfifo_sof;
   // End of automatics

   /**********************************************************************/
   input [31:0] 	WrFIFO_Data;
   input 		WrFIFO_Push;
   output 		WrFIFO_Empty;
   output 		WrFIFO_Full;

   output 		WrFIFO_DataReq;
   input 		WrFIFO_DataAck;
   output [7:0] 	WrFIFO_DataSize;
   output [4:0] 	WrFIFO_DataId;

   output [31:0] 	RdFIFO_Data;
   input 		RdFIFO_Pop;
   output 		RdFIFO_Empty;
   output 		RdFIFO_Full;
   
   output 		RdFIFO_DataReq;
   input 		RdFIFO_DataAck;
   output [7:0] 	RdFIFO_DataSize;
   output [4:0] 	RdFIFO_DataId;
   /**********************************************************************/
   
endmodule
// Local Variables:
// verilog-library-directories:("." "../../pcores/sata_v1_00_a/hdl/verilog" )
// verilog-library-files:(".")
// verilog-library-extensions:(".v" ".h")
// End:
// 
// hs_dma.v ends here
