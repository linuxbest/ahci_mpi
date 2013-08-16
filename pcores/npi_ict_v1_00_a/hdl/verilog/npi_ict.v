// npi_ict.v --- 
// 
// Filename: npi_ict.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Tue Jul 31 17:01:39 2012 (+0800)
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

// Copyright (C) 2008;2009 Beijing Soul tech.
// -------------------------------------
// Naming Conventions:
// 	active low signals                 : "*_n"
// 	clock signals                      : "clk"; "clk_div#"; "clk_#x"
// 	reset signals                      : "rst"; "rst_n"
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
`timescale 1ns / 1ns
module npi_ict (/*AUTOARG*/
   // Outputs
   PIM0_AddrAck, PIM0_RdFIFO_Data, PIM0_RdFIFO_RdWdAddr,
   PIM0_WrFIFO_Empty, PIM0_WrFIFO_AlmostFull, PIM0_RdFIFO_Empty,
   PIM0_RdFIFO_Latency, PIM0_InitDone, PIM1_AddrAck, PIM1_RdFIFO_Data,
   PIM1_RdFIFO_RdWdAddr, PIM1_WrFIFO_Empty, PIM1_WrFIFO_AlmostFull,
   PIM1_RdFIFO_Empty, PIM1_RdFIFO_Latency, PIM1_InitDone,
   PIM2_AddrAck, PIM2_RdFIFO_Data, PIM2_RdFIFO_RdWdAddr,
   PIM2_WrFIFO_Empty, PIM2_WrFIFO_AlmostFull, PIM2_RdFIFO_Empty,
   PIM2_RdFIFO_Latency, PIM2_InitDone, PIM3_AddrAck, PIM3_RdFIFO_Data,
   PIM3_RdFIFO_RdWdAddr, PIM3_WrFIFO_Empty, PIM3_WrFIFO_AlmostFull,
   PIM3_RdFIFO_Empty, PIM3_RdFIFO_Latency, PIM3_InitDone,
   PIM4_AddrAck, PIM4_RdFIFO_Data, PIM4_RdFIFO_RdWdAddr,
   PIM4_WrFIFO_Empty, PIM4_WrFIFO_AlmostFull, PIM4_RdFIFO_Empty,
   PIM4_RdFIFO_Latency, PIM4_InitDone, PIM_Addr, PIM_AddrReq, PIM_RNW,
   PIM_Size, PIM_RdModWr, PIM_WrFIFO_Data, PIM_WrFIFO_BE,
   PIM_WrFIFO_Push, PIM_WrFIFO_Flush, PIM_RdFIFO_Pop,
   PIM_RdFIFO_Flush, npi_ict_state,
   // Inputs
   MPMC_Clk, MPMC_Rst, PIM0_Addr, PIM0_AddrReq, PIM0_RNW, PIM0_Size,
   PIM0_RdModWr, PIM0_WrFIFO_Data, PIM0_WrFIFO_BE, PIM0_WrFIFO_Push,
   PIM0_RdFIFO_Pop, PIM0_WrFIFO_Flush, PIM0_RdFIFO_Flush, PIM1_Addr,
   PIM1_AddrReq, PIM1_RNW, PIM1_Size, PIM1_RdModWr, PIM1_WrFIFO_Data,
   PIM1_WrFIFO_BE, PIM1_WrFIFO_Push, PIM1_RdFIFO_Pop,
   PIM1_WrFIFO_Flush, PIM1_RdFIFO_Flush, PIM2_Addr, PIM2_AddrReq,
   PIM2_RNW, PIM2_Size, PIM2_RdModWr, PIM2_WrFIFO_Data,
   PIM2_WrFIFO_BE, PIM2_WrFIFO_Push, PIM2_RdFIFO_Pop,
   PIM2_WrFIFO_Flush, PIM2_RdFIFO_Flush, PIM3_Addr, PIM3_AddrReq,
   PIM3_RNW, PIM3_Size, PIM3_RdModWr, PIM3_WrFIFO_Data,
   PIM3_WrFIFO_BE, PIM3_WrFIFO_Push, PIM3_RdFIFO_Pop,
   PIM3_WrFIFO_Flush, PIM3_RdFIFO_Flush, PIM4_Addr, PIM4_AddrReq,
   PIM4_RNW, PIM4_Size, PIM4_RdModWr, PIM4_WrFIFO_Data,
   PIM4_WrFIFO_BE, PIM4_WrFIFO_Push, PIM4_RdFIFO_Pop,
   PIM4_WrFIFO_Flush, PIM4_RdFIFO_Flush, PIM_AddrAck,
   PIM_WrFIFO_Empty, PIM_WrFIFO_AlmostFull, PIM_RdFIFO_Data,
   PIM_RdFIFO_RdWdAddr, PIM_RdFIFO_Empty, PIM_RdFIFO_Latency,
   PIM_InitDone
   );
   parameter C_FAMILY = "virtex5";
   parameter C_NUM_PORTS = 5;

   parameter C_PIM0_DATA_WIDTH = 32;
   parameter C_PIM0_RD_FIFO_TYPE = "BRAM";
   parameter C_PIM0_WR_FIFO_TYPE = "BRAM";
   parameter C_PIM0_RD_FIFO_APP_PIPELINE = 1;
   parameter C_PIM0_RD_FIFO_MEM_PIPELINE = 1;
   parameter C_PIM0_WR_FIFO_APP_PIPELINE = 1;
   parameter C_PIM0_WR_FIFO_MEM_PIPELINE = 1;

   parameter C_PIM1_DATA_WIDTH = 32;
   parameter C_PIM1_RD_FIFO_TYPE = "BRAM";
   parameter C_PIM1_WR_FIFO_TYPE = "BRAM";
   parameter C_PIM1_RD_FIFO_APP_PIPELINE = 1;
   parameter C_PIM1_RD_FIFO_MEM_PIPELINE = 1;
   parameter C_PIM1_WR_FIFO_APP_PIPELINE = 1;
   parameter C_PIM1_WR_FIFO_MEM_PIPELINE = 1;

   parameter C_PIM2_DATA_WIDTH = 32;
   parameter C_PIM2_RD_FIFO_TYPE = "BRAM";
   parameter C_PIM2_WR_FIFO_TYPE = "BRAM";
   parameter C_PIM2_RD_FIFO_APP_PIPELINE = 1;
   parameter C_PIM2_RD_FIFO_MEM_PIPELINE = 1;
   parameter C_PIM2_WR_FIFO_APP_PIPELINE = 1;
   parameter C_PIM2_WR_FIFO_MEM_PIPELINE = 1;

   parameter C_PIM3_DATA_WIDTH = 32;
   parameter C_PIM3_RD_FIFO_TYPE = "BRAM";
   parameter C_PIM3_WR_FIFO_TYPE = "BRAM";
   parameter C_PIM3_RD_FIFO_APP_PIPELINE = 1;
   parameter C_PIM3_RD_FIFO_MEM_PIPELINE = 1;
   parameter C_PIM3_WR_FIFO_APP_PIPELINE = 1;
   parameter C_PIM3_WR_FIFO_MEM_PIPELINE = 1;

   parameter C_PIM4_DATA_WIDTH = 32;
   parameter C_PIM4_RD_FIFO_TYPE = "BRAM";
   parameter C_PIM4_WR_FIFO_TYPE = "BRAM";
   parameter C_PIM4_RD_FIFO_APP_PIPELINE = 1;
   parameter C_PIM4_RD_FIFO_MEM_PIPELINE = 1;
   parameter C_PIM4_WR_FIFO_APP_PIPELINE = 1;
   parameter C_PIM4_WR_FIFO_MEM_PIPELINE = 1;

   parameter C_PIM_DATA_WIDTH = 64;
   parameter C_NPI_CHIPSCOPE = 0;

   input MPMC_Clk;
   input MPMC_Rst;
   
   input [31:0]                      PIM0_Addr;
   input 			     PIM0_AddrReq;
   output 			     PIM0_AddrAck;
   input 			     PIM0_RNW;
   input [3:0] 			     PIM0_Size;
   input 			     PIM0_RdModWr;
   input [C_PIM0_DATA_WIDTH-1:0]     PIM0_WrFIFO_Data;
   input [(C_PIM0_DATA_WIDTH/8)-1:0] PIM0_WrFIFO_BE;
   input 			     PIM0_WrFIFO_Push;
   output [C_PIM0_DATA_WIDTH-1:0]    PIM0_RdFIFO_Data;
   input 			     PIM0_RdFIFO_Pop;
   output [3:0] 		     PIM0_RdFIFO_RdWdAddr;
   output 			     PIM0_WrFIFO_Empty;
   output 			     PIM0_WrFIFO_AlmostFull;
   input 			     PIM0_WrFIFO_Flush;
   output 			     PIM0_RdFIFO_Empty;
   input 			     PIM0_RdFIFO_Flush;
   output [1:0] 		     PIM0_RdFIFO_Latency;
   output 			     PIM0_InitDone;
   
   input [31:0] 		     PIM1_Addr;
   input 			     PIM1_AddrReq;
   output 			     PIM1_AddrAck;
   input 			     PIM1_RNW;
   input [3:0] 			     PIM1_Size;
   input 			     PIM1_RdModWr;
   input [C_PIM1_DATA_WIDTH-1:0]     PIM1_WrFIFO_Data;
   input [(C_PIM1_DATA_WIDTH/8)-1:0] PIM1_WrFIFO_BE;
   input 			     PIM1_WrFIFO_Push;
   output [C_PIM1_DATA_WIDTH-1:0]    PIM1_RdFIFO_Data;
   input 			     PIM1_RdFIFO_Pop;
   output [3:0] 		     PIM1_RdFIFO_RdWdAddr;
   output 			     PIM1_WrFIFO_Empty;
   output 			     PIM1_WrFIFO_AlmostFull;
   input 			     PIM1_WrFIFO_Flush;
   output 			     PIM1_RdFIFO_Empty;
   input 			     PIM1_RdFIFO_Flush;
   output [1:0] 		     PIM1_RdFIFO_Latency;
   output 			     PIM1_InitDone;
   
   input [31:0] 		     PIM2_Addr;
   input 			     PIM2_AddrReq;
   output 			     PIM2_AddrAck;
   input 			     PIM2_RNW;
   input [3:0] 			     PIM2_Size;
   input 			     PIM2_RdModWr;
   input [C_PIM2_DATA_WIDTH-1:0]     PIM2_WrFIFO_Data;
   input [(C_PIM2_DATA_WIDTH/8)-1:0] PIM2_WrFIFO_BE;
   input 			     PIM2_WrFIFO_Push;
   output [C_PIM2_DATA_WIDTH-1:0]    PIM2_RdFIFO_Data;
   input 			     PIM2_RdFIFO_Pop;
   output [3:0] 		     PIM2_RdFIFO_RdWdAddr;
   output 			     PIM2_WrFIFO_Empty;
   output 			     PIM2_WrFIFO_AlmostFull;
   input 			     PIM2_WrFIFO_Flush;
   output 			     PIM2_RdFIFO_Empty;
   input 			     PIM2_RdFIFO_Flush;
   output [1:0] 		     PIM2_RdFIFO_Latency;
   output 			     PIM2_InitDone;
   
   input [31:0] 		     PIM3_Addr;
   input 			     PIM3_AddrReq;
   output 			     PIM3_AddrAck;
   input 			     PIM3_RNW;
   input [3:0] 			     PIM3_Size;
   input 			     PIM3_RdModWr;
   input [C_PIM3_DATA_WIDTH-1:0]     PIM3_WrFIFO_Data;
   input [(C_PIM3_DATA_WIDTH/8)-1:0] PIM3_WrFIFO_BE;
   input 			     PIM3_WrFIFO_Push;
   output [C_PIM3_DATA_WIDTH-1:0]    PIM3_RdFIFO_Data;
   input 			     PIM3_RdFIFO_Pop;
   output [3:0] 		     PIM3_RdFIFO_RdWdAddr;
   output 			     PIM3_WrFIFO_Empty;
   output 			     PIM3_WrFIFO_AlmostFull;
   input 			     PIM3_WrFIFO_Flush;
   output 			     PIM3_RdFIFO_Empty;
   input 			     PIM3_RdFIFO_Flush;
   output [1:0] 		     PIM3_RdFIFO_Latency;
   output 			     PIM3_InitDone;

   input [31:0] 		     PIM4_Addr;
   input 			     PIM4_AddrReq;
   output 			     PIM4_AddrAck;
   input 			     PIM4_RNW;
   input [3:0] 			     PIM4_Size;
   input 			     PIM4_RdModWr;
   input [C_PIM4_DATA_WIDTH-1:0]     PIM4_WrFIFO_Data;
   input [(C_PIM4_DATA_WIDTH/8)-1:0] PIM4_WrFIFO_BE;
   input 			     PIM4_WrFIFO_Push;
   output [C_PIM4_DATA_WIDTH-1:0]    PIM4_RdFIFO_Data;
   input 			     PIM4_RdFIFO_Pop;
   output [3:0] 		     PIM4_RdFIFO_RdWdAddr;
   output 			     PIM4_WrFIFO_Empty;
   output 			     PIM4_WrFIFO_AlmostFull;
   input 			     PIM4_WrFIFO_Flush;
   output 			     PIM4_RdFIFO_Empty;
   input 			     PIM4_RdFIFO_Flush;
   output [1:0] 		     PIM4_RdFIFO_Latency;
   output 			     PIM4_InitDone;   

   output [31:0] 		     PIM_Addr;
   output 			     PIM_AddrReq;
   input 			     PIM_AddrAck;
   output 			     PIM_RNW;
   output [3:0] 		     PIM_Size;
   output 			     PIM_RdModWr;
   
   output [C_PIM_DATA_WIDTH-1:0]     PIM_WrFIFO_Data;
   output [(C_PIM_DATA_WIDTH/8)-1:0] PIM_WrFIFO_BE;
   output 			     PIM_WrFIFO_Push;
   output 			     PIM_WrFIFO_Flush;
   input 			     PIM_WrFIFO_Empty;
   input 			     PIM_WrFIFO_AlmostFull;
   
   input [C_PIM_DATA_WIDTH-1:0]      PIM_RdFIFO_Data;
   output 			     PIM_RdFIFO_Pop;
   input [3:0] 			     PIM_RdFIFO_RdWdAddr;
   input 			     PIM_RdFIFO_Empty;
   output 			     PIM_RdFIFO_Flush;
   input [1:0] 			     PIM_RdFIFO_Latency;
   
   input 			     PIM_InitDone;
   output [31:0] 		     npi_ict_state;
   /***************************************************************************/
   localparam C_PIX_ADDR_WIDTH_MAX = 32;
   localparam C_PIM_SIZE_WIDTH = 4;
   localparam C_PIM_ADDR_WIDTH = 32;
   
   localparam C_MEM_DATA_WIDTH = C_PIM_DATA_WIDTH;
   localparam C_MEM_BE_WIDTH   = C_MEM_DATA_WIDTH/8;
   
   wire [C_NUM_PORTS-1:0] 	     ReqRNW;
   wire [C_NUM_PORTS*4-1:0] 	     ReqSize;
   wire [C_NUM_PORTS*3-1:0] 	     ReqId;
   wire [C_NUM_PORTS*32-1:0] 	     ReqAddr;
   wire [C_NUM_PORTS-1:0] 	     ReqEmpty;
   wire [C_NUM_PORTS-1:0] 	     ReqPending;
   wire [C_NUM_PORTS-1:0] 	     ReqPop;
   
   wire [C_NUM_PORTS-1:0] 	     ReqWrPop;
   wire [C_NUM_PORTS-1:0] 	     ReqWrBeRst;
   wire [C_NUM_PORTS-1:0] 	     ReqWrEmpty;
   wire [C_NUM_PORTS*C_MEM_DATA_WIDTH-1:0] ReqWrData;
   wire [C_NUM_PORTS*C_MEM_BE_WIDTH-1:0]   ReqWrBE;
   
   wire [C_NUM_PORTS-1:0] 		   ReqRdAlmostFull;
   wire [C_NUM_PORTS-1:0] 		   ReqRdPush;
   wire [C_NUM_PORTS*C_MEM_DATA_WIDTH-1:0] ReqRdData;

   wire 				   PIM_RdFIFO_Push;
   wire [2:0] 				   PIM_RdFIFO_Push_sel;
   wire [C_MEM_DATA_WIDTH-1:0] 		   PIM_RdFIFO_Push_Data;

   wire 				   rdsts_afull;	
   wire [5:0] 				   rdsts_len;	
   wire [2:0] 				   rdsts_nr;	
   wire 				   rdsts_wren;	
   wire [15:0] 				   npi_ict_dbg;
   
   /* npi_addr_path AUTO_TEMPLATE "_\([0-9]\)" (
    .C_FAMILY        (C_FAMILY),
    .C_PI_ADDR_WIDTH (32),
    
    .Clk      (MPMC_Clk),
    .Rst      (MPMC_Rst),
    .RNW      (PIM@_RNW),
    .Size     (PIM@_Size[C_PIM_SIZE_WIDTH-1:0]),
    .Addr     (PIM@_Addr[C_PIM_ADDR_WIDTH-1:0]),
    .AddrReq  (PIM@_AddrReq),
    .AddrAck  (PIM@_AddrAck),
    .InitDone (PIM@_InitDone),    
    .ReqRNW   (ReqRNW[@]),
    .ReqSize  (ReqSize[(@+1)*4-1:@*4]),
    .ReqId    (ReqId[(@+1)*3-1:@*3]),    
    .ReqAddr  (ReqAddr[(@+1)*32-1:@*32]),
    .ReqEmpty (ReqEmpty[@]),
    .ReqPop   (ReqPop[@]),
    .PhyDone  (PIM_InitDone),
    )*/
   /* mpmc_write_fifo AUTO_TEMPLATE "_\([0-9]\)" (
    .C_FAMILY          (C_FAMILY),
    .C_USE_INIT_PUSH   (0),
    .C_FIFO_TYPE       (C_PIM@_WR_FIFO_TYPE == "BRAM" ? 2'b11 : 2'b10),
    .C_PI_PIPELINE     (C_PIM@_WR_FIFO_APP_PIPELINE),
    .C_MEM_PIPELINE    (1),
    .C_PI_ADDR_WIDTH   (32),
    .C_PI_DATA_WIDTH   (C_PIM@_DATA_WIDTH),
    .C_MEM_DATA_WIDTH  (C_MEM_DATA_WIDTH),
    
    .Clk               (MPMC_Clk),
    .Rst               (MPMC_Rst),
    .AddrAck           (PIM@_AddrAck),
    .Size              (PIM@_Size[C_PIM_SIZE_WIDTH-1:0]),
    .Addr              (PIM@_Addr[C_PIM_ADDR_WIDTH-1:0]),
    .RNW               (PIM@_RNW),
    .InitPush          (1'b0),
    .InitData          (128'h0),
    .InitDone          (1'b0),
    .Flush             (PIM@_WrFIFO_Flush),
    .Push              (PIM@_WrFIFO_Push),
    .Pop               (ReqWrPop[@]),
    .BE_Rst            (ReqWrBeRst[@]),
    .Empty             (PIM@_WrFIFO_Empty),
    .AlmostFull        (PIM@_WrFIFO_AlmostFull),
    .PushData          (PIM@_WrFIFO_Data[C_PIM@_DATA_WIDTH-1:0]),
    .PushBE            (PIM@_WrFIFO_BE[(C_PIM@_DATA_WIDTH/8)-1:0]),
    .PopData           (ReqWrData[(@+1)*C_MEM_DATA_WIDTH-1:@*C_MEM_DATA_WIDTH]),
    .PopBE             (ReqWrBE[(@+1)*C_MEM_BE_WIDTH-1:@*C_MEM_BE_WIDTH]),
    )*/

   /* mpmc_read_fifo AUTO_TEMPLATE "_\([0-9]\)" (
    .C_FAMILY          (C_FAMILY),
    .C_FIFO_TYPE       (C_PIM@_RD_FIFO_TYPE == "BRAM" ? 2'b11 : 2'b10),
    .C_PI_PIPELINE     (C_PIM@_RD_FIFO_APP_PIPELINE),
    .C_MEM_PIPELINE    (C_PIM@_RD_FIFO_MEM_PIPELINE),    
    .C_PI_ADDR_WIDTH   (32),
    .C_PI_DATA_WIDTH   (C_PIM@_DATA_WIDTH),
    .C_MEM_DATA_WIDTH  (C_MEM_DATA_WIDTH),
    .C_IS_DDR          (1),
    
    .Clk               (MPMC_Clk),
    .Rst               (MPMC_Rst),
    .AddrAck           (PIM@_AddrAck),
    .Size              (PIM@_Size[C_PIM_SIZE_WIDTH-1:0]),
    .Addr              (PIM@_Addr[C_PIM_ADDR_WIDTH-1:0]),
    .RNW               (PIM@_RNW),
    .Flush             (PIM@_RdFIFO_Flush),
    .Push              (PIM_RdFIFO_Push_sel == @ && PIM_RdFIFO_Push),
    .Pop               (PIM@_RdFIFO_Pop),
    .Empty             (PIM@_RdFIFO_Empty),
    .AlmostFull        (ReqRdAlmostFull[@]),
    .PushData          (PIM_RdFIFO_Push_Data),
    .PopData           (PIM@_RdFIFO_Data[C_PIM@_DATA_WIDTH-1:0]),
    .RdWdAddr          (PIM@_RdFIFO_RdWdAddr[]),
    )*/

generate if (C_NUM_PORTS > 0) begin: pim_port_0
   npi_addr_path #(/*AUTOINSTPARAM*/
		    // Parameters
		    .C_FAMILY		(C_FAMILY),		 // Templated
		    .C_PI_ADDR_WIDTH	(32))			 // Templated
   addr_0 (/*AUTOINST*/
	   // Outputs
	   .AddrAck			(PIM0_AddrAck),		 // Templated
	   .ReqRNW			(ReqRNW[0]),		 // Templated
	   .ReqSize			(ReqSize[(0+1)*4-1:0*4]), // Templated
	   .ReqAddr			(ReqAddr[(0+1)*32-1:0*32]), // Templated
	   .ReqEmpty			(ReqEmpty[0]),		 // Templated
	   .ReqId			(ReqId[(0+1)*3-1:0*3]),	 // Templated
	   .InitDone			(PIM0_InitDone),	 // Templated
	   // Inputs
	   .Clk				(MPMC_Clk),		 // Templated
	   .Rst				(MPMC_Rst),		 // Templated
	   .RNW				(PIM0_RNW),		 // Templated
	   .Size			(PIM0_Size[C_PIM_SIZE_WIDTH-1:0]), // Templated
	   .Addr			(PIM0_Addr[C_PIM_ADDR_WIDTH-1:0]), // Templated
	   .AddrReq			(PIM0_AddrReq),		 // Templated
	   .ReqPop			(ReqPop[0]),		 // Templated
	   .PhyDone			(PIM_InitDone));		 // Templated
   mpmc_write_fifo #(/*AUTOINSTPARAM*/
		     // Parameters
		     .C_FAMILY		(C_FAMILY),		 // Templated
		     .C_USE_INIT_PUSH	(0),			 // Templated
		     .C_FIFO_TYPE	(C_PIM0_WR_FIFO_TYPE == "BRAM" ? 2'b11 : 2'b10), // Templated
		     .C_PI_PIPELINE	(C_PIM0_WR_FIFO_APP_PIPELINE), // Templated
		     .C_MEM_PIPELINE	(1),			 // Templated
		     .C_PI_ADDR_WIDTH	(32),			 // Templated
		     .C_PI_DATA_WIDTH	(C_PIM0_DATA_WIDTH),	 // Templated
		     .C_MEM_DATA_WIDTH	(C_MEM_DATA_WIDTH))	 // Templated
   writefifo_0 (/*AUTOINST*/
		// Outputs
		.Empty			(PIM0_WrFIFO_Empty),	 // Templated
		.AlmostFull		(PIM0_WrFIFO_AlmostFull), // Templated
		.PopData		(ReqWrData[(0+1)*C_MEM_DATA_WIDTH-1:0*C_MEM_DATA_WIDTH]), // Templated
		.PopBE			(ReqWrBE[(0+1)*C_MEM_BE_WIDTH-1:0*C_MEM_BE_WIDTH]), // Templated
		// Inputs
		.Clk			(MPMC_Clk),		 // Templated
		.Rst			(MPMC_Rst),		 // Templated
		.AddrAck		(PIM0_AddrAck),		 // Templated
		.RNW			(PIM0_RNW),		 // Templated
		.Size			(PIM0_Size[C_PIM_SIZE_WIDTH-1:0]), // Templated
		.Addr			(PIM0_Addr[C_PIM_ADDR_WIDTH-1:0]), // Templated
		.InitPush		(1'b0),			 // Templated
		.InitData		(128'h0),		 // Templated
		.InitDone		(1'b0),			 // Templated
		.Flush			(PIM0_WrFIFO_Flush),	 // Templated
		.Push			(PIM0_WrFIFO_Push),	 // Templated
		.Pop			(ReqWrPop[0]),		 // Templated
		.BE_Rst			(ReqWrBeRst[0]),	 // Templated
		.PushData		(PIM0_WrFIFO_Data[C_PIM0_DATA_WIDTH-1:0]), // Templated
		.PushBE			(PIM0_WrFIFO_BE[(C_PIM0_DATA_WIDTH/8)-1:0])); // Templated
   mpmc_read_fifo #(/*AUTOINSTPARAM*/
		    // Parameters
		    .C_FAMILY		(C_FAMILY),		 // Templated
		    .C_FIFO_TYPE	(C_PIM0_RD_FIFO_TYPE == "BRAM" ? 2'b11 : 2'b10), // Templated
		    .C_PI_PIPELINE	(C_PIM0_RD_FIFO_APP_PIPELINE), // Templated
		    .C_MEM_PIPELINE	(C_PIM0_RD_FIFO_MEM_PIPELINE), // Templated
		    .C_PI_ADDR_WIDTH	(32),			 // Templated
		    .C_PI_DATA_WIDTH	(C_PIM0_DATA_WIDTH),	 // Templated
		    .C_MEM_DATA_WIDTH	(C_MEM_DATA_WIDTH),	 // Templated
		    .C_IS_DDR		(1))			 // Templated
   readfifo_0 (/*AUTOINST*/
	       // Outputs
	       .Empty			(PIM0_RdFIFO_Empty),	 // Templated
	       .AlmostFull		(ReqRdAlmostFull[0]),	 // Templated
	       .PopData			(PIM0_RdFIFO_Data[C_PIM0_DATA_WIDTH-1:0]), // Templated
	       .RdWdAddr		(PIM0_RdFIFO_RdWdAddr[3:0]), // Templated
	       // Inputs
	       .Clk			(MPMC_Clk),		 // Templated
	       .Rst			(MPMC_Rst),		 // Templated
	       .AddrAck			(PIM0_AddrAck),		 // Templated
	       .RNW			(PIM0_RNW),		 // Templated
	       .Size			(PIM0_Size[C_PIM_SIZE_WIDTH-1:0]), // Templated
	       .Addr			(PIM0_Addr[C_PIM_ADDR_WIDTH-1:0]), // Templated
	       .Flush			(PIM0_RdFIFO_Flush),	 // Templated
	       .Push			(PIM_RdFIFO_Push_sel == 0 && PIM_RdFIFO_Push), // Templated
	       .Pop			(PIM0_RdFIFO_Pop),	 // Templated
	       .PushData		(PIM_RdFIFO_Push_Data));	 // Templated
   assign ReqWrEmpty[0] = PIM0_WrFIFO_Empty;
end
endgenerate

generate if (C_NUM_PORTS > 1) begin: pim_port_1
   npi_addr_path #(/*AUTOINSTPARAM*/
		    // Parameters
		    .C_FAMILY		(C_FAMILY),		 // Templated
		    .C_PI_ADDR_WIDTH	(32))			 // Templated
   addr_1 (/*AUTOINST*/
	   // Outputs
	   .AddrAck			(PIM1_AddrAck),		 // Templated
	   .ReqRNW			(ReqRNW[1]),		 // Templated
	   .ReqSize			(ReqSize[(1+1)*4-1:1*4]), // Templated
	   .ReqAddr			(ReqAddr[(1+1)*32-1:1*32]), // Templated
	   .ReqEmpty			(ReqEmpty[1]),		 // Templated
	   .ReqId			(ReqId[(1+1)*3-1:1*3]),	 // Templated
	   .InitDone			(PIM1_InitDone),	 // Templated
	   // Inputs
	   .Clk				(MPMC_Clk),		 // Templated
	   .Rst				(MPMC_Rst),		 // Templated
	   .RNW				(PIM1_RNW),		 // Templated
	   .Size			(PIM1_Size[C_PIM_SIZE_WIDTH-1:0]), // Templated
	   .Addr			(PIM1_Addr[C_PIM_ADDR_WIDTH-1:0]), // Templated
	   .AddrReq			(PIM1_AddrReq),		 // Templated
	   .ReqPop			(ReqPop[1]),		 // Templated
	   .PhyDone			(PIM_InitDone));		 // Templated
   mpmc_write_fifo #(/*AUTOINSTPARAM*/
		     // Parameters
		     .C_FAMILY		(C_FAMILY),		 // Templated
		     .C_USE_INIT_PUSH	(0),			 // Templated
		     .C_FIFO_TYPE	(C_PIM1_WR_FIFO_TYPE == "BRAM" ? 2'b11 : 2'b10), // Templated
		     .C_PI_PIPELINE	(C_PIM1_WR_FIFO_APP_PIPELINE), // Templated
		     .C_MEM_PIPELINE	(1),			 // Templated
		     .C_PI_ADDR_WIDTH	(32),			 // Templated
		     .C_PI_DATA_WIDTH	(C_PIM1_DATA_WIDTH),	 // Templated
		     .C_MEM_DATA_WIDTH	(C_MEM_DATA_WIDTH))	 // Templated
   writefifo_1 (/*AUTOINST*/
		// Outputs
		.Empty			(PIM1_WrFIFO_Empty),	 // Templated
		.AlmostFull		(PIM1_WrFIFO_AlmostFull), // Templated
		.PopData		(ReqWrData[(1+1)*C_MEM_DATA_WIDTH-1:1*C_MEM_DATA_WIDTH]), // Templated
		.PopBE			(ReqWrBE[(1+1)*C_MEM_BE_WIDTH-1:1*C_MEM_BE_WIDTH]), // Templated
		// Inputs
		.Clk			(MPMC_Clk),		 // Templated
		.Rst			(MPMC_Rst),		 // Templated
		.AddrAck		(PIM1_AddrAck),		 // Templated
		.RNW			(PIM1_RNW),		 // Templated
		.Size			(PIM1_Size[C_PIM_SIZE_WIDTH-1:0]), // Templated
		.Addr			(PIM1_Addr[C_PIM_ADDR_WIDTH-1:0]), // Templated
		.InitPush		(1'b0),			 // Templated
		.InitData		(128'h0),		 // Templated
		.InitDone		(1'b0),			 // Templated
		.Flush			(PIM1_WrFIFO_Flush),	 // Templated
		.Push			(PIM1_WrFIFO_Push),	 // Templated
		.Pop			(ReqWrPop[1]),		 // Templated
		.BE_Rst			(ReqWrBeRst[1]),	 // Templated
		.PushData		(PIM1_WrFIFO_Data[C_PIM1_DATA_WIDTH-1:0]), // Templated
		.PushBE			(PIM1_WrFIFO_BE[(C_PIM1_DATA_WIDTH/8)-1:0])); // Templated
   mpmc_read_fifo #(/*AUTOINSTPARAM*/
		    // Parameters
		    .C_FAMILY		(C_FAMILY),		 // Templated
		    .C_FIFO_TYPE	(C_PIM1_RD_FIFO_TYPE == "BRAM" ? 2'b11 : 2'b10), // Templated
		    .C_PI_PIPELINE	(C_PIM1_RD_FIFO_APP_PIPELINE), // Templated
		    .C_MEM_PIPELINE	(C_PIM1_RD_FIFO_MEM_PIPELINE), // Templated
		    .C_PI_ADDR_WIDTH	(32),			 // Templated
		    .C_PI_DATA_WIDTH	(C_PIM1_DATA_WIDTH),	 // Templated
		    .C_MEM_DATA_WIDTH	(C_MEM_DATA_WIDTH),	 // Templated
		    .C_IS_DDR		(1))			 // Templated
   readfifo_1 (/*AUTOINST*/
	       // Outputs
	       .Empty			(PIM1_RdFIFO_Empty),	 // Templated
	       .AlmostFull		(ReqRdAlmostFull[1]),	 // Templated
	       .PopData			(PIM1_RdFIFO_Data[C_PIM1_DATA_WIDTH-1:0]), // Templated
	       .RdWdAddr		(PIM1_RdFIFO_RdWdAddr[3:0]), // Templated
	       // Inputs
	       .Clk			(MPMC_Clk),		 // Templated
	       .Rst			(MPMC_Rst),		 // Templated
	       .AddrAck			(PIM1_AddrAck),		 // Templated
	       .RNW			(PIM1_RNW),		 // Templated
	       .Size			(PIM1_Size[C_PIM_SIZE_WIDTH-1:0]), // Templated
	       .Addr			(PIM1_Addr[C_PIM_ADDR_WIDTH-1:0]), // Templated
	       .Flush			(PIM1_RdFIFO_Flush),	 // Templated
	       .Push			(PIM_RdFIFO_Push_sel == 1 && PIM_RdFIFO_Push), // Templated
	       .Pop			(PIM1_RdFIFO_Pop),	 // Templated
	       .PushData		(PIM_RdFIFO_Push_Data));	 // Templated
   assign ReqWrEmpty[1] = PIM1_WrFIFO_Empty;   
end   
endgenerate

generate if (C_NUM_PORTS > 2) begin: pim_port_2
   npi_addr_path #(/*AUTOINSTPARAM*/
		    // Parameters
		    .C_FAMILY		(C_FAMILY),		 // Templated
		    .C_PI_ADDR_WIDTH	(32))			 // Templated
   addr_2 (/*AUTOINST*/
	   // Outputs
	   .AddrAck			(PIM2_AddrAck),		 // Templated
	   .ReqRNW			(ReqRNW[2]),		 // Templated
	   .ReqSize			(ReqSize[(2+1)*4-1:2*4]), // Templated
	   .ReqAddr			(ReqAddr[(2+1)*32-1:2*32]), // Templated
	   .ReqEmpty			(ReqEmpty[2]),		 // Templated
	   .ReqId			(ReqId[(2+1)*3-1:2*3]),	 // Templated
	   .InitDone			(PIM2_InitDone),	 // Templated
	   // Inputs
	   .Clk				(MPMC_Clk),		 // Templated
	   .Rst				(MPMC_Rst),		 // Templated
	   .RNW				(PIM2_RNW),		 // Templated
	   .Size			(PIM2_Size[C_PIM_SIZE_WIDTH-1:0]), // Templated
	   .Addr			(PIM2_Addr[C_PIM_ADDR_WIDTH-1:0]), // Templated
	   .AddrReq			(PIM2_AddrReq),		 // Templated
	   .ReqPop			(ReqPop[2]),		 // Templated
	   .PhyDone			(PIM_InitDone));		 // Templated
   mpmc_write_fifo #(/*AUTOINSTPARAM*/
		     // Parameters
		     .C_FAMILY		(C_FAMILY),		 // Templated
		     .C_USE_INIT_PUSH	(0),			 // Templated
		     .C_FIFO_TYPE	(C_PIM2_WR_FIFO_TYPE == "BRAM" ? 2'b11 : 2'b10), // Templated
		     .C_PI_PIPELINE	(C_PIM2_WR_FIFO_APP_PIPELINE), // Templated
		     .C_MEM_PIPELINE	(1),			 // Templated
		     .C_PI_ADDR_WIDTH	(32),			 // Templated
		     .C_PI_DATA_WIDTH	(C_PIM2_DATA_WIDTH),	 // Templated
		     .C_MEM_DATA_WIDTH	(C_MEM_DATA_WIDTH))	 // Templated
   writefifo_2 (/*AUTOINST*/
		// Outputs
		.Empty			(PIM2_WrFIFO_Empty),	 // Templated
		.AlmostFull		(PIM2_WrFIFO_AlmostFull), // Templated
		.PopData		(ReqWrData[(2+1)*C_MEM_DATA_WIDTH-1:2*C_MEM_DATA_WIDTH]), // Templated
		.PopBE			(ReqWrBE[(2+1)*C_MEM_BE_WIDTH-1:2*C_MEM_BE_WIDTH]), // Templated
		// Inputs
		.Clk			(MPMC_Clk),		 // Templated
		.Rst			(MPMC_Rst),		 // Templated
		.AddrAck		(PIM2_AddrAck),		 // Templated
		.RNW			(PIM2_RNW),		 // Templated
		.Size			(PIM2_Size[C_PIM_SIZE_WIDTH-1:0]), // Templated
		.Addr			(PIM2_Addr[C_PIM_ADDR_WIDTH-1:0]), // Templated
		.InitPush		(1'b0),			 // Templated
		.InitData		(128'h0),		 // Templated
		.InitDone		(1'b0),			 // Templated
		.Flush			(PIM2_WrFIFO_Flush),	 // Templated
		.Push			(PIM2_WrFIFO_Push),	 // Templated
		.Pop			(ReqWrPop[2]),		 // Templated
		.BE_Rst			(ReqWrBeRst[2]),	 // Templated
		.PushData		(PIM2_WrFIFO_Data[C_PIM2_DATA_WIDTH-1:0]), // Templated
		.PushBE			(PIM2_WrFIFO_BE[(C_PIM2_DATA_WIDTH/8)-1:0])); // Templated
   mpmc_read_fifo #(/*AUTOINSTPARAM*/
		    // Parameters
		    .C_FAMILY		(C_FAMILY),		 // Templated
		    .C_FIFO_TYPE	(C_PIM2_RD_FIFO_TYPE == "BRAM" ? 2'b11 : 2'b10), // Templated
		    .C_PI_PIPELINE	(C_PIM2_RD_FIFO_APP_PIPELINE), // Templated
		    .C_MEM_PIPELINE	(C_PIM2_RD_FIFO_MEM_PIPELINE), // Templated
		    .C_PI_ADDR_WIDTH	(32),			 // Templated
		    .C_PI_DATA_WIDTH	(C_PIM2_DATA_WIDTH),	 // Templated
		    .C_MEM_DATA_WIDTH	(C_MEM_DATA_WIDTH),	 // Templated
		    .C_IS_DDR		(1))			 // Templated
   readfifo_2 (/*AUTOINST*/
	       // Outputs
	       .Empty			(PIM2_RdFIFO_Empty),	 // Templated
	       .AlmostFull		(ReqRdAlmostFull[2]),	 // Templated
	       .PopData			(PIM2_RdFIFO_Data[C_PIM2_DATA_WIDTH-1:0]), // Templated
	       .RdWdAddr		(PIM2_RdFIFO_RdWdAddr[3:0]), // Templated
	       // Inputs
	       .Clk			(MPMC_Clk),		 // Templated
	       .Rst			(MPMC_Rst),		 // Templated
	       .AddrAck			(PIM2_AddrAck),		 // Templated
	       .RNW			(PIM2_RNW),		 // Templated
	       .Size			(PIM2_Size[C_PIM_SIZE_WIDTH-1:0]), // Templated
	       .Addr			(PIM2_Addr[C_PIM_ADDR_WIDTH-1:0]), // Templated
	       .Flush			(PIM2_RdFIFO_Flush),	 // Templated
	       .Push			(PIM_RdFIFO_Push_sel == 2 && PIM_RdFIFO_Push), // Templated
	       .Pop			(PIM2_RdFIFO_Pop),	 // Templated
	       .PushData		(PIM_RdFIFO_Push_Data));	 // Templated
   assign ReqWrEmpty[2] = PIM2_WrFIFO_Empty;      
end   
endgenerate

generate if (C_NUM_PORTS > 3) begin: pim_port_3
   npi_addr_path #(/*AUTOINSTPARAM*/
		    // Parameters
		    .C_FAMILY		(C_FAMILY),		 // Templated
		    .C_PI_ADDR_WIDTH	(32))			 // Templated
   addr_3 (/*AUTOINST*/
	   // Outputs
	   .AddrAck			(PIM3_AddrAck),		 // Templated
	   .ReqRNW			(ReqRNW[3]),		 // Templated
	   .ReqSize			(ReqSize[(3+1)*4-1:3*4]), // Templated
	   .ReqAddr			(ReqAddr[(3+1)*32-1:3*32]), // Templated
	   .ReqEmpty			(ReqEmpty[3]),		 // Templated
	   .ReqId			(ReqId[(3+1)*3-1:3*3]),	 // Templated
	   .InitDone			(PIM3_InitDone),	 // Templated
	   // Inputs
	   .Clk				(MPMC_Clk),		 // Templated
	   .Rst				(MPMC_Rst),		 // Templated
	   .RNW				(PIM3_RNW),		 // Templated
	   .Size			(PIM3_Size[C_PIM_SIZE_WIDTH-1:0]), // Templated
	   .Addr			(PIM3_Addr[C_PIM_ADDR_WIDTH-1:0]), // Templated
	   .AddrReq			(PIM3_AddrReq),		 // Templated
	   .ReqPop			(ReqPop[3]),		 // Templated
	   .PhyDone			(PIM_InitDone));		 // Templated
   mpmc_write_fifo #(/*AUTOINSTPARAM*/
		     // Parameters
		     .C_FAMILY		(C_FAMILY),		 // Templated
		     .C_USE_INIT_PUSH	(0),			 // Templated
		     .C_FIFO_TYPE	(C_PIM3_WR_FIFO_TYPE == "BRAM" ? 2'b11 : 2'b10), // Templated
		     .C_PI_PIPELINE	(C_PIM3_WR_FIFO_APP_PIPELINE), // Templated
		     .C_MEM_PIPELINE	(1),			 // Templated
		     .C_PI_ADDR_WIDTH	(32),			 // Templated
		     .C_PI_DATA_WIDTH	(C_PIM3_DATA_WIDTH),	 // Templated
		     .C_MEM_DATA_WIDTH	(C_MEM_DATA_WIDTH))	 // Templated
   writefifo_3 (/*AUTOINST*/
		// Outputs
		.Empty			(PIM3_WrFIFO_Empty),	 // Templated
		.AlmostFull		(PIM3_WrFIFO_AlmostFull), // Templated
		.PopData		(ReqWrData[(3+1)*C_MEM_DATA_WIDTH-1:3*C_MEM_DATA_WIDTH]), // Templated
		.PopBE			(ReqWrBE[(3+1)*C_MEM_BE_WIDTH-1:3*C_MEM_BE_WIDTH]), // Templated
		// Inputs
		.Clk			(MPMC_Clk),		 // Templated
		.Rst			(MPMC_Rst),		 // Templated
		.AddrAck		(PIM3_AddrAck),		 // Templated
		.RNW			(PIM3_RNW),		 // Templated
		.Size			(PIM3_Size[C_PIM_SIZE_WIDTH-1:0]), // Templated
		.Addr			(PIM3_Addr[C_PIM_ADDR_WIDTH-1:0]), // Templated
		.InitPush		(1'b0),			 // Templated
		.InitData		(128'h0),		 // Templated
		.InitDone		(1'b0),			 // Templated
		.Flush			(PIM3_WrFIFO_Flush),	 // Templated
		.Push			(PIM3_WrFIFO_Push),	 // Templated
		.Pop			(ReqWrPop[3]),		 // Templated
		.BE_Rst			(ReqWrBeRst[3]),	 // Templated
		.PushData		(PIM3_WrFIFO_Data[C_PIM3_DATA_WIDTH-1:0]), // Templated
		.PushBE			(PIM3_WrFIFO_BE[(C_PIM3_DATA_WIDTH/8)-1:0])); // Templated
   mpmc_read_fifo #(/*AUTOINSTPARAM*/
		    // Parameters
		    .C_FAMILY		(C_FAMILY),		 // Templated
		    .C_FIFO_TYPE	(C_PIM3_RD_FIFO_TYPE == "BRAM" ? 2'b11 : 2'b10), // Templated
		    .C_PI_PIPELINE	(C_PIM3_RD_FIFO_APP_PIPELINE), // Templated
		    .C_MEM_PIPELINE	(C_PIM3_RD_FIFO_MEM_PIPELINE), // Templated
		    .C_PI_ADDR_WIDTH	(32),			 // Templated
		    .C_PI_DATA_WIDTH	(C_PIM3_DATA_WIDTH),	 // Templated
		    .C_MEM_DATA_WIDTH	(C_MEM_DATA_WIDTH),	 // Templated
		    .C_IS_DDR		(1))			 // Templated
   readfifo_3 (/*AUTOINST*/
	       // Outputs
	       .Empty			(PIM3_RdFIFO_Empty),	 // Templated
	       .AlmostFull		(ReqRdAlmostFull[3]),	 // Templated
	       .PopData			(PIM3_RdFIFO_Data[C_PIM3_DATA_WIDTH-1:0]), // Templated
	       .RdWdAddr		(PIM3_RdFIFO_RdWdAddr[3:0]), // Templated
	       // Inputs
	       .Clk			(MPMC_Clk),		 // Templated
	       .Rst			(MPMC_Rst),		 // Templated
	       .AddrAck			(PIM3_AddrAck),		 // Templated
	       .RNW			(PIM3_RNW),		 // Templated
	       .Size			(PIM3_Size[C_PIM_SIZE_WIDTH-1:0]), // Templated
	       .Addr			(PIM3_Addr[C_PIM_ADDR_WIDTH-1:0]), // Templated
	       .Flush			(PIM3_RdFIFO_Flush),	 // Templated
	       .Push			(PIM_RdFIFO_Push_sel == 3 && PIM_RdFIFO_Push), // Templated
	       .Pop			(PIM3_RdFIFO_Pop),	 // Templated
	       .PushData		(PIM_RdFIFO_Push_Data));	 // Templated
   assign ReqWrEmpty[3] = PIM3_WrFIFO_Empty;      
end   
endgenerate

generate if (C_NUM_PORTS > 4) begin: pim_port_4
   npi_addr_path #(/*AUTOINSTPARAM*/
		    // Parameters
		    .C_FAMILY		(C_FAMILY),		 // Templated
		    .C_PI_ADDR_WIDTH	(32))			 // Templated
   addr_4 (/*AUTOINST*/
	   // Outputs
	   .AddrAck			(PIM4_AddrAck),		 // Templated
	   .ReqRNW			(ReqRNW[4]),		 // Templated
	   .ReqSize			(ReqSize[(4+1)*4-1:4*4]), // Templated
	   .ReqAddr			(ReqAddr[(4+1)*32-1:4*32]), // Templated
	   .ReqEmpty			(ReqEmpty[4]),		 // Templated
	   .ReqId			(ReqId[(4+1)*3-1:4*3]),	 // Templated
	   .InitDone			(PIM4_InitDone),	 // Templated
	   // Inputs
	   .Clk				(MPMC_Clk),		 // Templated
	   .Rst				(MPMC_Rst),		 // Templated
	   .RNW				(PIM4_RNW),		 // Templated
	   .Size			(PIM4_Size[C_PIM_SIZE_WIDTH-1:0]), // Templated
	   .Addr			(PIM4_Addr[C_PIM_ADDR_WIDTH-1:0]), // Templated
	   .AddrReq			(PIM4_AddrReq),		 // Templated
	   .ReqPop			(ReqPop[4]),		 // Templated
	   .PhyDone			(PIM_InitDone));		 // Templated
   mpmc_write_fifo #(/*AUTOINSTPARAM*/
		     // Parameters
		     .C_FAMILY		(C_FAMILY),		 // Templated
		     .C_USE_INIT_PUSH	(0),			 // Templated
		     .C_FIFO_TYPE	(C_PIM4_WR_FIFO_TYPE == "BRAM" ? 2'b11 : 2'b10), // Templated
		     .C_PI_PIPELINE	(C_PIM4_WR_FIFO_APP_PIPELINE), // Templated
		     .C_MEM_PIPELINE	(1),			 // Templated
		     .C_PI_ADDR_WIDTH	(32),			 // Templated
		     .C_PI_DATA_WIDTH	(C_PIM4_DATA_WIDTH),	 // Templated
		     .C_MEM_DATA_WIDTH	(C_MEM_DATA_WIDTH))	 // Templated
   writefifo_4 (/*AUTOINST*/
		// Outputs
		.Empty			(PIM4_WrFIFO_Empty),	 // Templated
		.AlmostFull		(PIM4_WrFIFO_AlmostFull), // Templated
		.PopData		(ReqWrData[(4+1)*C_MEM_DATA_WIDTH-1:4*C_MEM_DATA_WIDTH]), // Templated
		.PopBE			(ReqWrBE[(4+1)*C_MEM_BE_WIDTH-1:4*C_MEM_BE_WIDTH]), // Templated
		// Inputs
		.Clk			(MPMC_Clk),		 // Templated
		.Rst			(MPMC_Rst),		 // Templated
		.AddrAck		(PIM4_AddrAck),		 // Templated
		.RNW			(PIM4_RNW),		 // Templated
		.Size			(PIM4_Size[C_PIM_SIZE_WIDTH-1:0]), // Templated
		.Addr			(PIM4_Addr[C_PIM_ADDR_WIDTH-1:0]), // Templated
		.InitPush		(1'b0),			 // Templated
		.InitData		(128'h0),		 // Templated
		.InitDone		(1'b0),			 // Templated
		.Flush			(PIM4_WrFIFO_Flush),	 // Templated
		.Push			(PIM4_WrFIFO_Push),	 // Templated
		.Pop			(ReqWrPop[4]),		 // Templated
		.BE_Rst			(ReqWrBeRst[4]),	 // Templated
		.PushData		(PIM4_WrFIFO_Data[C_PIM4_DATA_WIDTH-1:0]), // Templated
		.PushBE			(PIM4_WrFIFO_BE[(C_PIM4_DATA_WIDTH/8)-1:0])); // Templated
   mpmc_read_fifo #(/*AUTOINSTPARAM*/
		    // Parameters
		    .C_FAMILY		(C_FAMILY),		 // Templated
		    .C_FIFO_TYPE	(C_PIM4_RD_FIFO_TYPE == "BRAM" ? 2'b11 : 2'b10), // Templated
		    .C_PI_PIPELINE	(C_PIM4_RD_FIFO_APP_PIPELINE), // Templated
		    .C_MEM_PIPELINE	(C_PIM4_RD_FIFO_MEM_PIPELINE), // Templated
		    .C_PI_ADDR_WIDTH	(32),			 // Templated
		    .C_PI_DATA_WIDTH	(C_PIM4_DATA_WIDTH),	 // Templated
		    .C_MEM_DATA_WIDTH	(C_MEM_DATA_WIDTH),	 // Templated
		    .C_IS_DDR		(1))			 // Templated
   readfifo_4 (/*AUTOINST*/
	       // Outputs
	       .Empty			(PIM4_RdFIFO_Empty),	 // Templated
	       .AlmostFull		(ReqRdAlmostFull[4]),	 // Templated
	       .PopData			(PIM4_RdFIFO_Data[C_PIM4_DATA_WIDTH-1:0]), // Templated
	       .RdWdAddr		(PIM4_RdFIFO_RdWdAddr[3:0]), // Templated
	       // Inputs
	       .Clk			(MPMC_Clk),		 // Templated
	       .Rst			(MPMC_Rst),		 // Templated
	       .AddrAck			(PIM4_AddrAck),		 // Templated
	       .RNW			(PIM4_RNW),		 // Templated
	       .Size			(PIM4_Size[C_PIM_SIZE_WIDTH-1:0]), // Templated
	       .Addr			(PIM4_Addr[C_PIM_ADDR_WIDTH-1:0]), // Templated
	       .Flush			(PIM4_RdFIFO_Flush),	 // Templated
	       .Push			(PIM_RdFIFO_Push_sel == 4 && PIM_RdFIFO_Push), // Templated
	       .Pop			(PIM4_RdFIFO_Pop),	 // Templated
	       .PushData		(PIM_RdFIFO_Push_Data));	 // Templated
   assign ReqWrEmpty[4] = PIM4_WrFIFO_Empty;      
end   
endgenerate   

   wire [4:0] ReqGrant;
   wire [4:0] grant_ns;
   wire [4:0] current_master;
   reg [2:0]  ReqGrant_nr;
   wire   upd_last_master;
   assign ReqPending      = ~ReqEmpty;
   
   round_robin_arb #(.TCQ(1),.WIDTH(C_NUM_PORTS))
   cmd_arbiter (.grant_ns        (grant_ns),
		.grant_r         (ReqGrant),
		.clk             (MPMC_Clk),
		.rst             (MPMC_Rst),
		.req             (ReqPending),
		.disable_grant   (0),
		.current_master  (current_master),
		.upd_last_master (upd_last_master));

   always @(posedge MPMC_Clk)
     begin
	ReqGrant_nr <= #1 grant_ns[0] ? 3'h0 :
		          grant_ns[1] ? 3'h1 :
		          grant_ns[2] ? 3'h2 :
		          grant_ns[3] ? 3'h3 : 3'h4;
     end

   npi_ict_fsm #(/*AUTOINSTPARAM*/
		 // Parameters
		 .C_NUM_PORTS		(C_NUM_PORTS),
		 .C_PIX_ADDR_WIDTH_MAX	(C_PIX_ADDR_WIDTH_MAX),
		 .C_MEM_DATA_WIDTH	(C_MEM_DATA_WIDTH),
		 .C_MEM_BE_WIDTH	(C_MEM_BE_WIDTH),
		 .C_PIM_DATA_WIDTH	(C_PIM_DATA_WIDTH))
   npi_ict_fsm  (
		 .Clk			(MPMC_Clk),
		 .Rst			(MPMC_Rst),
		 /*AUTOINST*/
		 // Outputs
		 .ReqPop		(ReqPop[C_NUM_PORTS-1:0]),
		 .ReqWrBeRst		(ReqWrBeRst[C_NUM_PORTS-1:0]),
		 .ReqWrPop		(ReqWrPop[C_NUM_PORTS-1:0]),
		 .upd_last_master	(upd_last_master),
		 .current_master	(current_master[C_NUM_PORTS-1:0]),
		 .PIM_Addr		(PIM_Addr[31:0]),
		 .PIM_AddrReq		(PIM_AddrReq),
		 .PIM_RNW		(PIM_RNW),
		 .PIM_Size		(PIM_Size[3:0]),
		 .PIM_RdModWr		(PIM_RdModWr),
		 .PIM_WrFIFO_Data	(PIM_WrFIFO_Data[C_PIM_DATA_WIDTH-1:0]),
		 .PIM_WrFIFO_BE		(PIM_WrFIFO_BE[(C_PIM_DATA_WIDTH/8)-1:0]),
		 .PIM_WrFIFO_Push	(PIM_WrFIFO_Push),
		 .PIM_WrFIFO_Flush	(PIM_WrFIFO_Flush),
		 .rdsts_nr		(rdsts_nr[2:0]),
		 .rdsts_len		(rdsts_len[5:0]),
		 .rdsts_wren		(rdsts_wren),
		 .npi_ict_state		(npi_ict_state[31:0]),
		 // Inputs
		 .ReqRNW		(ReqRNW[C_NUM_PORTS-1:0]),
		 .ReqSize		(ReqSize[C_NUM_PORTS*4-1:0]),
		 .ReqId			(ReqId[C_NUM_PORTS*3-1:0]),
		 .ReqAddr		(ReqAddr[C_NUM_PORTS*C_PIX_ADDR_WIDTH_MAX-1:0]),
		 .ReqEmpty		(ReqEmpty[C_NUM_PORTS-1:0]),
		 .ReqWrEmpty		(ReqWrEmpty[C_NUM_PORTS-1:0]),
		 .ReqWrData		(ReqWrData[C_NUM_PORTS*C_MEM_DATA_WIDTH-1:0]),
		 .ReqWrBE		(ReqWrBE[C_NUM_PORTS*C_MEM_BE_WIDTH-1:0]),
		 .ReqGrant		(ReqGrant[C_NUM_PORTS-1:0]),
		 .ReqPending		(ReqPending[C_NUM_PORTS-1:0]),
		 .ReqGrant_nr		(ReqGrant_nr[2:0]),
		 .PIM_AddrAck		(PIM_AddrAck),
		 .PIM_WrFIFO_Empty	(PIM_WrFIFO_Empty),
		 .PIM_WrFIFO_AlmostFull	(PIM_WrFIFO_AlmostFull),
		 .PIM_InitDone		(PIM_InitDone),
		 .rdsts_afull		(rdsts_afull));

   npi_ict_rd #(/*AUTOINSTPARAM*/
		// Parameters
		.C_PIM_DATA_WIDTH	(C_PIM_DATA_WIDTH))
   npi_ict_rd (
	       .Clk			(MPMC_Clk),
	       .Rst			(MPMC_Rst),
	       /*AUTOINST*/
	       // Outputs
	       .PIM_RdFIFO_Pop		(PIM_RdFIFO_Pop),
	       .PIM_RdFIFO_Flush	(PIM_RdFIFO_Flush),
	       .PIM_RdFIFO_Push		(PIM_RdFIFO_Push),
	       .PIM_RdFIFO_Push_Data	(PIM_RdFIFO_Push_Data[C_PIM_DATA_WIDTH-1:0]),
	       .PIM_RdFIFO_Push_sel	(PIM_RdFIFO_Push_sel[2:0]),
	       .rdsts_afull		(rdsts_afull),
	       .npi_ict_dbg		(npi_ict_dbg[15:0]),
	       // Inputs
	       .PIM_RdFIFO_Data		(PIM_RdFIFO_Data[C_PIM_DATA_WIDTH-1:0]),
	       .PIM_RdFIFO_RdWdAddr	(PIM_RdFIFO_RdWdAddr[3:0]),
	       .PIM_RdFIFO_Empty	(PIM_RdFIFO_Empty),
	       .PIM_RdFIFO_Latency	(PIM_RdFIFO_Latency[1:0]),
	       .rdsts_wren		(rdsts_wren),
	       .rdsts_len		(rdsts_len[5:0]),
	       .rdsts_nr		(rdsts_nr[2:0]));
   
   assign PIM0_RdFIFO_Latency = 2'h2;
   assign PIM1_RdFIFO_Latency = 2'h2;
   assign PIM2_RdFIFO_Latency = 2'h2;
   assign PIM3_RdFIFO_Latency = 2'h2;
   assign PIM4_RdFIFO_Latency = 2'h2;

   wire [127:0] PIMrd_dbg;
   assign PIMrd_dbg[63:0] = PIM_RdFIFO_Push_Data;
   assign PIMrd_dbg[64]   = PIM_RdFIFO_Push;
   assign PIMrd_dbg[67:65]= PIM_RdFIFO_Push_sel;
   assign PIMrd_dbg[68]   = rdsts_afull;
   assign PIMrd_dbg[69]   = rdsts_wren;
   assign PIMrd_dbg[75:70]= rdsts_len;
   assign PIMrd_dbg[78:76]= rdsts_nr;
   assign PIMrd_dbg[94:79]= npi_ict_dbg;
   
   /* pim_dbg AUTO_TEMPLATE "\([0-9]+\)"
    (
    .PIM_\(.*\)     (PIM@_\1[]),
    )*/
   wire [127:0] PIM0_dbg;
   wire [127:0] PIM1_dbg;
   wire [127:0] PIM2_dbg;
   wire [127:0] PIM3_dbg;
   wire [127:0] PIM4_dbg;
   pim_dbg PIM0 (/*AUTOINST*/
		 // Outputs
		 .PIM_dbg		(PIM0_dbg[127:0]),	 // Templated
		 // Inputs
		 .PIM_Addr		(PIM0_Addr[31:0]),	 // Templated
		 .PIM_AddrAck		(PIM0_AddrAck),		 // Templated
		 .PIM_AddrReq		(PIM0_AddrReq),		 // Templated
		 .PIM_InitDone		(PIM0_InitDone),	 // Templated
		 .PIM_RNW		(PIM0_RNW),		 // Templated
		 .PIM_RdFIFO_Data	(PIM0_RdFIFO_Data[31:0]), // Templated
		 .PIM_RdFIFO_Empty	(PIM0_RdFIFO_Empty),	 // Templated
		 .PIM_RdFIFO_Flush	(PIM0_RdFIFO_Flush),	 // Templated
		 .PIM_RdFIFO_Latency	(PIM0_RdFIFO_Latency[1:0]), // Templated
		 .PIM_RdFIFO_Pop	(PIM0_RdFIFO_Pop),	 // Templated
		 .PIM_RdFIFO_RdWdAddr	(PIM0_RdFIFO_RdWdAddr[3:0]), // Templated
		 .PIM_RdModWr		(PIM0_RdModWr),		 // Templated
		 .PIM_Size		(PIM0_Size[3:0]),	 // Templated
		 .PIM_WrFIFO_AlmostFull	(PIM0_WrFIFO_AlmostFull), // Templated
		 .PIM_WrFIFO_BE		(PIM0_WrFIFO_BE[3:0]),	 // Templated
		 .PIM_WrFIFO_Data	(PIM0_WrFIFO_Data[31:0]), // Templated
		 .PIM_WrFIFO_Empty	(PIM0_WrFIFO_Empty),	 // Templated
		 .PIM_WrFIFO_Flush	(PIM0_WrFIFO_Flush),	 // Templated
		 .PIM_WrFIFO_Push	(PIM0_WrFIFO_Push));	 // Templated
   pim_dbg PIM1 (/*AUTOINST*/
		 // Outputs
		 .PIM_dbg		(PIM1_dbg[127:0]),	 // Templated
		 // Inputs
		 .PIM_Addr		(PIM1_Addr[31:0]),	 // Templated
		 .PIM_AddrAck		(PIM1_AddrAck),		 // Templated
		 .PIM_AddrReq		(PIM1_AddrReq),		 // Templated
		 .PIM_InitDone		(PIM1_InitDone),	 // Templated
		 .PIM_RNW		(PIM1_RNW),		 // Templated
		 .PIM_RdFIFO_Data	(PIM1_RdFIFO_Data[31:0]), // Templated
		 .PIM_RdFIFO_Empty	(PIM1_RdFIFO_Empty),	 // Templated
		 .PIM_RdFIFO_Flush	(PIM1_RdFIFO_Flush),	 // Templated
		 .PIM_RdFIFO_Latency	(PIM1_RdFIFO_Latency[1:0]), // Templated
		 .PIM_RdFIFO_Pop	(PIM1_RdFIFO_Pop),	 // Templated
		 .PIM_RdFIFO_RdWdAddr	(PIM1_RdFIFO_RdWdAddr[3:0]), // Templated
		 .PIM_RdModWr		(PIM1_RdModWr),		 // Templated
		 .PIM_Size		(PIM1_Size[3:0]),	 // Templated
		 .PIM_WrFIFO_AlmostFull	(PIM1_WrFIFO_AlmostFull), // Templated
		 .PIM_WrFIFO_BE		(PIM1_WrFIFO_BE[3:0]),	 // Templated
		 .PIM_WrFIFO_Data	(PIM1_WrFIFO_Data[31:0]), // Templated
		 .PIM_WrFIFO_Empty	(PIM1_WrFIFO_Empty),	 // Templated
		 .PIM_WrFIFO_Flush	(PIM1_WrFIFO_Flush),	 // Templated
		 .PIM_WrFIFO_Push	(PIM1_WrFIFO_Push));	 // Templated
   pim_dbg PIM2 (/*AUTOINST*/
		 // Outputs
		 .PIM_dbg		(PIM2_dbg[127:0]),	 // Templated
		 // Inputs
		 .PIM_Addr		(PIM2_Addr[31:0]),	 // Templated
		 .PIM_AddrAck		(PIM2_AddrAck),		 // Templated
		 .PIM_AddrReq		(PIM2_AddrReq),		 // Templated
		 .PIM_InitDone		(PIM2_InitDone),	 // Templated
		 .PIM_RNW		(PIM2_RNW),		 // Templated
		 .PIM_RdFIFO_Data	(PIM2_RdFIFO_Data[31:0]), // Templated
		 .PIM_RdFIFO_Empty	(PIM2_RdFIFO_Empty),	 // Templated
		 .PIM_RdFIFO_Flush	(PIM2_RdFIFO_Flush),	 // Templated
		 .PIM_RdFIFO_Latency	(PIM2_RdFIFO_Latency[1:0]), // Templated
		 .PIM_RdFIFO_Pop	(PIM2_RdFIFO_Pop),	 // Templated
		 .PIM_RdFIFO_RdWdAddr	(PIM2_RdFIFO_RdWdAddr[3:0]), // Templated
		 .PIM_RdModWr		(PIM2_RdModWr),		 // Templated
		 .PIM_Size		(PIM2_Size[3:0]),	 // Templated
		 .PIM_WrFIFO_AlmostFull	(PIM2_WrFIFO_AlmostFull), // Templated
		 .PIM_WrFIFO_BE		(PIM2_WrFIFO_BE[3:0]),	 // Templated
		 .PIM_WrFIFO_Data	(PIM2_WrFIFO_Data[31:0]), // Templated
		 .PIM_WrFIFO_Empty	(PIM2_WrFIFO_Empty),	 // Templated
		 .PIM_WrFIFO_Flush	(PIM2_WrFIFO_Flush),	 // Templated
		 .PIM_WrFIFO_Push	(PIM2_WrFIFO_Push));	 // Templated
   pim_dbg PIM3 (/*AUTOINST*/
		 // Outputs
		 .PIM_dbg		(PIM3_dbg[127:0]),	 // Templated
		 // Inputs
		 .PIM_Addr		(PIM3_Addr[31:0]),	 // Templated
		 .PIM_AddrAck		(PIM3_AddrAck),		 // Templated
		 .PIM_AddrReq		(PIM3_AddrReq),		 // Templated
		 .PIM_InitDone		(PIM3_InitDone),	 // Templated
		 .PIM_RNW		(PIM3_RNW),		 // Templated
		 .PIM_RdFIFO_Data	(PIM3_RdFIFO_Data[31:0]), // Templated
		 .PIM_RdFIFO_Empty	(PIM3_RdFIFO_Empty),	 // Templated
		 .PIM_RdFIFO_Flush	(PIM3_RdFIFO_Flush),	 // Templated
		 .PIM_RdFIFO_Latency	(PIM3_RdFIFO_Latency[1:0]), // Templated
		 .PIM_RdFIFO_Pop	(PIM3_RdFIFO_Pop),	 // Templated
		 .PIM_RdFIFO_RdWdAddr	(PIM3_RdFIFO_RdWdAddr[3:0]), // Templated
		 .PIM_RdModWr		(PIM3_RdModWr),		 // Templated
		 .PIM_Size		(PIM3_Size[3:0]),	 // Templated
		 .PIM_WrFIFO_AlmostFull	(PIM3_WrFIFO_AlmostFull), // Templated
		 .PIM_WrFIFO_BE		(PIM3_WrFIFO_BE[3:0]),	 // Templated
		 .PIM_WrFIFO_Data	(PIM3_WrFIFO_Data[31:0]), // Templated
		 .PIM_WrFIFO_Empty	(PIM3_WrFIFO_Empty),	 // Templated
		 .PIM_WrFIFO_Flush	(PIM3_WrFIFO_Flush),	 // Templated
		 .PIM_WrFIFO_Push	(PIM3_WrFIFO_Push));	 // Templated
   pim_dbg PIM4 (/*AUTOINST*/
		 // Outputs
		 .PIM_dbg		(PIM4_dbg[127:0]),	 // Templated
		 // Inputs
		 .PIM_Addr		(PIM4_Addr[31:0]),	 // Templated
		 .PIM_AddrAck		(PIM4_AddrAck),		 // Templated
		 .PIM_AddrReq		(PIM4_AddrReq),		 // Templated
		 .PIM_InitDone		(PIM4_InitDone),	 // Templated
		 .PIM_RNW		(PIM4_RNW),		 // Templated
		 .PIM_RdFIFO_Data	(PIM4_RdFIFO_Data[31:0]), // Templated
		 .PIM_RdFIFO_Empty	(PIM4_RdFIFO_Empty),	 // Templated
		 .PIM_RdFIFO_Flush	(PIM4_RdFIFO_Flush),	 // Templated
		 .PIM_RdFIFO_Latency	(PIM4_RdFIFO_Latency[1:0]), // Templated
		 .PIM_RdFIFO_Pop	(PIM4_RdFIFO_Pop),	 // Templated
		 .PIM_RdFIFO_RdWdAddr	(PIM4_RdFIFO_RdWdAddr[3:0]), // Templated
		 .PIM_RdModWr		(PIM4_RdModWr),		 // Templated
		 .PIM_Size		(PIM4_Size[3:0]),	 // Templated
		 .PIM_WrFIFO_AlmostFull	(PIM4_WrFIFO_AlmostFull), // Templated
		 .PIM_WrFIFO_BE		(PIM4_WrFIFO_BE[3:0]),	 // Templated
		 .PIM_WrFIFO_Data	(PIM4_WrFIFO_Data[31:0]), // Templated
		 .PIM_WrFIFO_Empty	(PIM4_WrFIFO_Empty),	 // Templated
		 .PIM_WrFIFO_Flush	(PIM4_WrFIFO_Flush),	 // Templated
		 .PIM_WrFIFO_Push	(PIM4_WrFIFO_Push));	 // Templated

   wire [191:0] PIM_dbg;
   pim_dbg64 PIM64 (/*AUTOINST*/
		    // Outputs
		    .PIM_dbg		(PIM_dbg[191:0]),
		    // Inputs
		    .PIM_Addr		(PIM_Addr[31:0]),
		    .PIM_AddrReq	(PIM_AddrReq),
		    .PIM_AddrAck	(PIM_AddrAck),
		    .PIM_InitDone	(PIM_InitDone),
		    .PIM_RNW		(PIM_RNW),
		    .PIM_RdFIFO_Data	(PIM_RdFIFO_Data[63:0]),
		    .PIM_RdFIFO_Empty	(PIM_RdFIFO_Empty),
		    .PIM_RdFIFO_Flush	(PIM_RdFIFO_Flush),
		    .PIM_RdFIFO_Latency	(PIM_RdFIFO_Latency[1:0]),
		    .PIM_RdFIFO_Pop	(PIM_RdFIFO_Pop),
		    .PIM_RdFIFO_RdWdAddr(PIM_RdFIFO_RdWdAddr[3:0]),
		    .PIM_RdModWr	(PIM_RdModWr),
		    .PIM_Size		(PIM_Size[3:0]),
		    .PIM_WrFIFO_AlmostFull(PIM_WrFIFO_AlmostFull),
		    .PIM_WrFIFO_BE	(PIM_WrFIFO_BE[7:0]),
		    .PIM_WrFIFO_Data	(PIM_WrFIFO_Data[63:0]),
		    .PIM_WrFIFO_Empty	(PIM_WrFIFO_Empty),
		    .PIM_WrFIFO_Flush	(PIM_WrFIFO_Flush),
		    .PIM_WrFIFO_Push	(PIM_WrFIFO_Push));
   
   reg [127:0] TRIG0;
   reg [127:0] TRIG1;
   reg [191:0] TRIG2;

   always @(posedge MPMC_Clk)
     begin
	TRIG0 <= #1 PIM0_dbg;
	//TRIG0 <= #1 PIMrd_dbg;
	TRIG1 <= #1 PIM4_dbg;
	TRIG2 <= #1 PIM_dbg;	
     end
   
   wire [35:0] 	CONTROL0;
   wire [35:0] 	CONTROL1;
   wire [35:0] 	CONTROL2;

   generate if (C_NPI_CHIPSCOPE == 1)
     begin
	chipscope_icon3
	  icon (/*AUTOINST*/
		// Inouts
		.CONTROL0		(CONTROL0[35:0]),
		.CONTROL1		(CONTROL1[35:0]),
		.CONTROL2		(CONTROL2[35:0]));
	chipscope_ila_128x1
	  ila0 (
		// Outputs
		.TRIG_OUT		(),
		// Inouts
		.CONTROL		(CONTROL0[35:0]),
		// Inputs
		.CLK			(MPMC_Clk),
		.TRIG0			(TRIG0[127:0]));
	chipscope_ila_128x1
	  ila1 (
		// Outputs
		.TRIG_OUT		(),
		// Inouts
		.CONTROL		(CONTROL1[35:0]),
		// Inputs
		.CLK			(MPMC_Clk),
		.TRIG0			(TRIG1[127:0]));
	chipscope_ila_192x1
	  ila2 (
		// Outputs
		.TRIG_OUT		(),
		// Inouts
		.CONTROL		(CONTROL2[35:0]),
		// Inputs
		.CLK			(MPMC_Clk),
		.TRIG0			(TRIG2[191:0]));	
     end
   endgenerate
endmodule // npi_ict
// Local Variables:
// verilog-library-directories:("." "/opt/ise12.3/ISE_DS/ISE/verilog/src/unisims/" "../")
// verilog-library-files:(".""sata_phy")
// verilog-library-extensions:(".v" ".h")
// End:
// 
// npi_ict.v ends here
