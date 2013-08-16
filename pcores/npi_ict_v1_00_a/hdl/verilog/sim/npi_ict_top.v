// npi_ict_top.v --- 
// 
// Filename: npi_ict_top.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Sat Aug 11 19:33:27 2012 (+0800)
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
module npi_ict_top (/*AUTOARG*/
   // Outputs
   PIM_WrFIFO_Push, PIM_WrFIFO_Flush, PIM_WrFIFO_Data, PIM_WrFIFO_BE,
   PIM_Size, PIM_RdModWr, PIM_RdFIFO_Pop, PIM_RdFIFO_Flush, PIM_RNW,
   PIM_AddrReq, PIM_Addr,
   // Inputs
   Rst, PIM_WrFIFO_Empty, PIM_WrFIFO_AlmostFull, PIM_RdFIFO_RdWdAddr,
   PIM_RdFIFO_Latency, PIM_RdFIFO_Empty, PIM_RdFIFO_Data,
   PIM_InitDone, PIM_AddrAck, Clk
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

   /*AUTOINPUT*/
   // Beginning of automatic inputs (from unused autoinst inputs)
   input		Clk;			// To gnpi_0 of gen_npi.v, ...
   input		PIM_AddrAck;		// To npi_ict of npi_ict.v
   input		PIM_InitDone;		// To npi_ict of npi_ict.v
   input [C_PIM_DATA_WIDTH-1:0] PIM_RdFIFO_Data;// To npi_ict of npi_ict.v
   input		PIM_RdFIFO_Empty;	// To npi_ict of npi_ict.v
   input [1:0]		PIM_RdFIFO_Latency;	// To npi_ict of npi_ict.v
   input [3:0]		PIM_RdFIFO_RdWdAddr;	// To npi_ict of npi_ict.v
   input		PIM_WrFIFO_AlmostFull;	// To npi_ict of npi_ict.v
   input		PIM_WrFIFO_Empty;	// To npi_ict of npi_ict.v
   input		Rst;			// To gnpi_0 of gen_npi.v, ...
   // End of automatics
   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output [31:0]	PIM_Addr;		// From npi_ict of npi_ict.v
   output		PIM_AddrReq;		// From npi_ict of npi_ict.v
   output		PIM_RNW;		// From npi_ict of npi_ict.v
   output		PIM_RdFIFO_Flush;	// From npi_ict of npi_ict.v
   output		PIM_RdFIFO_Pop;		// From npi_ict of npi_ict.v
   output		PIM_RdModWr;		// From npi_ict of npi_ict.v
   output [3:0]		PIM_Size;		// From npi_ict of npi_ict.v
   output [(C_PIM_DATA_WIDTH/8)-1:0] PIM_WrFIFO_BE;// From npi_ict of npi_ict.v
   output [C_PIM_DATA_WIDTH-1:0] PIM_WrFIFO_Data;// From npi_ict of npi_ict.v
   output		PIM_WrFIFO_Flush;	// From npi_ict of npi_ict.v
   output		PIM_WrFIFO_Push;	// From npi_ict of npi_ict.v
   // End of automatics

   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [31:0]		PIM0_Addr;		// From gnpi_0 of gen_npi.v
   wire			PIM0_AddrAck;		// From npi_ict of npi_ict.v
   wire			PIM0_AddrReq;		// From gnpi_0 of gen_npi.v
   wire			PIM0_InitDone;		// From npi_ict of npi_ict.v
   wire			PIM0_RNW;		// From gnpi_0 of gen_npi.v
   wire [C_PIM0_DATA_WIDTH-1:0] PIM0_RdFIFO_Data;// From npi_ict of npi_ict.v
   wire			PIM0_RdFIFO_Empty;	// From npi_ict of npi_ict.v
   wire			PIM0_RdFIFO_Flush;	// From gnpi_0 of gen_npi.v
   wire [1:0]		PIM0_RdFIFO_Latency;	// From npi_ict of npi_ict.v
   wire			PIM0_RdFIFO_Pop;	// From gnpi_0 of gen_npi.v
   wire [3:0]		PIM0_RdFIFO_RdWdAddr;	// From npi_ict of npi_ict.v
   wire			PIM0_RdModWr;		// From gnpi_0 of gen_npi.v
   wire [3:0]		PIM0_Size;		// From gnpi_0 of gen_npi.v
   wire			PIM0_WrFIFO_AlmostFull;	// From npi_ict of npi_ict.v
   wire [(C_PIM0_DATA_WIDTH/8)-1:0] PIM0_WrFIFO_BE;// From gnpi_0 of gen_npi.v
   wire [C_PIM0_DATA_WIDTH-1:0] PIM0_WrFIFO_Data;// From gnpi_0 of gen_npi.v
   wire			PIM0_WrFIFO_Empty;	// From npi_ict of npi_ict.v
   wire			PIM0_WrFIFO_Flush;	// From gnpi_0 of gen_npi.v
   wire			PIM0_WrFIFO_Push;	// From gnpi_0 of gen_npi.v
   wire [31:0]		PIM1_Addr;		// From gnpi_1 of gen_npi.v
   wire			PIM1_AddrAck;		// From npi_ict of npi_ict.v
   wire			PIM1_AddrReq;		// From gnpi_1 of gen_npi.v
   wire			PIM1_InitDone;		// From npi_ict of npi_ict.v
   wire			PIM1_RNW;		// From gnpi_1 of gen_npi.v
   wire [C_PIM1_DATA_WIDTH-1:0] PIM1_RdFIFO_Data;// From npi_ict of npi_ict.v
   wire			PIM1_RdFIFO_Empty;	// From npi_ict of npi_ict.v
   wire			PIM1_RdFIFO_Flush;	// From gnpi_1 of gen_npi.v
   wire [1:0]		PIM1_RdFIFO_Latency;	// From npi_ict of npi_ict.v
   wire			PIM1_RdFIFO_Pop;	// From gnpi_1 of gen_npi.v
   wire [3:0]		PIM1_RdFIFO_RdWdAddr;	// From npi_ict of npi_ict.v
   wire			PIM1_RdModWr;		// From gnpi_1 of gen_npi.v
   wire [3:0]		PIM1_Size;		// From gnpi_1 of gen_npi.v
   wire			PIM1_WrFIFO_AlmostFull;	// From npi_ict of npi_ict.v
   wire [(C_PIM1_DATA_WIDTH/8)-1:0] PIM1_WrFIFO_BE;// From gnpi_1 of gen_npi.v
   wire [C_PIM1_DATA_WIDTH-1:0] PIM1_WrFIFO_Data;// From gnpi_1 of gen_npi.v
   wire			PIM1_WrFIFO_Empty;	// From npi_ict of npi_ict.v
   wire			PIM1_WrFIFO_Flush;	// From gnpi_1 of gen_npi.v
   wire			PIM1_WrFIFO_Push;	// From gnpi_1 of gen_npi.v
   wire [31:0]		PIM2_Addr;		// From gnpi_2 of gen_npi.v
   wire			PIM2_AddrAck;		// From npi_ict of npi_ict.v
   wire			PIM2_AddrReq;		// From gnpi_2 of gen_npi.v
   wire			PIM2_InitDone;		// From npi_ict of npi_ict.v
   wire			PIM2_RNW;		// From gnpi_2 of gen_npi.v
   wire [C_PIM2_DATA_WIDTH-1:0] PIM2_RdFIFO_Data;// From npi_ict of npi_ict.v
   wire			PIM2_RdFIFO_Empty;	// From npi_ict of npi_ict.v
   wire			PIM2_RdFIFO_Flush;	// From gnpi_2 of gen_npi.v
   wire [1:0]		PIM2_RdFIFO_Latency;	// From npi_ict of npi_ict.v
   wire			PIM2_RdFIFO_Pop;	// From gnpi_2 of gen_npi.v
   wire [3:0]		PIM2_RdFIFO_RdWdAddr;	// From npi_ict of npi_ict.v
   wire			PIM2_RdModWr;		// From gnpi_2 of gen_npi.v
   wire [3:0]		PIM2_Size;		// From gnpi_2 of gen_npi.v
   wire			PIM2_WrFIFO_AlmostFull;	// From npi_ict of npi_ict.v
   wire [(C_PIM2_DATA_WIDTH/8)-1:0] PIM2_WrFIFO_BE;// From gnpi_2 of gen_npi.v
   wire [C_PIM2_DATA_WIDTH-1:0] PIM2_WrFIFO_Data;// From gnpi_2 of gen_npi.v
   wire			PIM2_WrFIFO_Empty;	// From npi_ict of npi_ict.v
   wire			PIM2_WrFIFO_Flush;	// From gnpi_2 of gen_npi.v
   wire			PIM2_WrFIFO_Push;	// From gnpi_2 of gen_npi.v
   wire [31:0]		PIM3_Addr;		// From gnpi_3 of gen_npi.v
   wire			PIM3_AddrAck;		// From npi_ict of npi_ict.v
   wire			PIM3_AddrReq;		// From gnpi_3 of gen_npi.v
   wire			PIM3_InitDone;		// From npi_ict of npi_ict.v
   wire			PIM3_RNW;		// From gnpi_3 of gen_npi.v
   wire [C_PIM3_DATA_WIDTH-1:0] PIM3_RdFIFO_Data;// From npi_ict of npi_ict.v
   wire			PIM3_RdFIFO_Empty;	// From npi_ict of npi_ict.v
   wire			PIM3_RdFIFO_Flush;	// From gnpi_3 of gen_npi.v
   wire [1:0]		PIM3_RdFIFO_Latency;	// From npi_ict of npi_ict.v
   wire			PIM3_RdFIFO_Pop;	// From gnpi_3 of gen_npi.v
   wire [3:0]		PIM3_RdFIFO_RdWdAddr;	// From npi_ict of npi_ict.v
   wire			PIM3_RdModWr;		// From gnpi_3 of gen_npi.v
   wire [3:0]		PIM3_Size;		// From gnpi_3 of gen_npi.v
   wire			PIM3_WrFIFO_AlmostFull;	// From npi_ict of npi_ict.v
   wire [(C_PIM3_DATA_WIDTH/8)-1:0] PIM3_WrFIFO_BE;// From gnpi_3 of gen_npi.v
   wire [C_PIM3_DATA_WIDTH-1:0] PIM3_WrFIFO_Data;// From gnpi_3 of gen_npi.v
   wire			PIM3_WrFIFO_Empty;	// From npi_ict of npi_ict.v
   wire			PIM3_WrFIFO_Flush;	// From gnpi_3 of gen_npi.v
   wire			PIM3_WrFIFO_Push;	// From gnpi_3 of gen_npi.v
   wire [31:0]		PIM4_Addr;		// From gnpi_4 of gen_npi.v
   wire			PIM4_AddrAck;		// From npi_ict of npi_ict.v
   wire			PIM4_AddrReq;		// From gnpi_4 of gen_npi.v
   wire			PIM4_InitDone;		// From npi_ict of npi_ict.v
   wire			PIM4_RNW;		// From gnpi_4 of gen_npi.v
   wire [C_PIM4_DATA_WIDTH-1:0] PIM4_RdFIFO_Data;// From npi_ict of npi_ict.v
   wire			PIM4_RdFIFO_Empty;	// From npi_ict of npi_ict.v
   wire			PIM4_RdFIFO_Flush;	// From gnpi_4 of gen_npi.v
   wire [1:0]		PIM4_RdFIFO_Latency;	// From npi_ict of npi_ict.v
   wire			PIM4_RdFIFO_Pop;	// From gnpi_4 of gen_npi.v
   wire [3:0]		PIM4_RdFIFO_RdWdAddr;	// From npi_ict of npi_ict.v
   wire			PIM4_RdModWr;		// From gnpi_4 of gen_npi.v
   wire [3:0]		PIM4_Size;		// From gnpi_4 of gen_npi.v
   wire			PIM4_WrFIFO_AlmostFull;	// From npi_ict of npi_ict.v
   wire [(C_PIM4_DATA_WIDTH/8)-1:0] PIM4_WrFIFO_BE;// From gnpi_4 of gen_npi.v
   wire [C_PIM4_DATA_WIDTH-1:0] PIM4_WrFIFO_Data;// From gnpi_4 of gen_npi.v
   wire			PIM4_WrFIFO_Empty;	// From npi_ict of npi_ict.v
   wire			PIM4_WrFIFO_Flush;	// From gnpi_4 of gen_npi.v
   wire			PIM4_WrFIFO_Push;	// From gnpi_4 of gen_npi.v
   // End of automatics

   wire 		MPMC_Clk;
   wire 		MPMC_Rst;
   assign MPMC_Clk = Clk;
   assign MPMC_Rst = Rst;
   
   npi_ict #(/*AUTOINSTPARAM*/
	     // Parameters
	     .C_FAMILY			(C_FAMILY),
	     .C_NUM_PORTS		(C_NUM_PORTS),
	     .C_PIM0_DATA_WIDTH		(C_PIM0_DATA_WIDTH),
	     .C_PIM0_RD_FIFO_TYPE	(C_PIM0_RD_FIFO_TYPE),
	     .C_PIM0_WR_FIFO_TYPE	(C_PIM0_WR_FIFO_TYPE),
	     .C_PIM0_RD_FIFO_APP_PIPELINE(C_PIM0_RD_FIFO_APP_PIPELINE),
	     .C_PIM0_RD_FIFO_MEM_PIPELINE(C_PIM0_RD_FIFO_MEM_PIPELINE),
	     .C_PIM0_WR_FIFO_APP_PIPELINE(C_PIM0_WR_FIFO_APP_PIPELINE),
	     .C_PIM0_WR_FIFO_MEM_PIPELINE(C_PIM0_WR_FIFO_MEM_PIPELINE),
	     .C_PIM1_DATA_WIDTH		(C_PIM1_DATA_WIDTH),
	     .C_PIM1_RD_FIFO_TYPE	(C_PIM1_RD_FIFO_TYPE),
	     .C_PIM1_WR_FIFO_TYPE	(C_PIM1_WR_FIFO_TYPE),
	     .C_PIM1_RD_FIFO_APP_PIPELINE(C_PIM1_RD_FIFO_APP_PIPELINE),
	     .C_PIM1_RD_FIFO_MEM_PIPELINE(C_PIM1_RD_FIFO_MEM_PIPELINE),
	     .C_PIM1_WR_FIFO_APP_PIPELINE(C_PIM1_WR_FIFO_APP_PIPELINE),
	     .C_PIM1_WR_FIFO_MEM_PIPELINE(C_PIM1_WR_FIFO_MEM_PIPELINE),
	     .C_PIM2_DATA_WIDTH		(C_PIM2_DATA_WIDTH),
	     .C_PIM2_RD_FIFO_TYPE	(C_PIM2_RD_FIFO_TYPE),
	     .C_PIM2_WR_FIFO_TYPE	(C_PIM2_WR_FIFO_TYPE),
	     .C_PIM2_RD_FIFO_APP_PIPELINE(C_PIM2_RD_FIFO_APP_PIPELINE),
	     .C_PIM2_RD_FIFO_MEM_PIPELINE(C_PIM2_RD_FIFO_MEM_PIPELINE),
	     .C_PIM2_WR_FIFO_APP_PIPELINE(C_PIM2_WR_FIFO_APP_PIPELINE),
	     .C_PIM2_WR_FIFO_MEM_PIPELINE(C_PIM2_WR_FIFO_MEM_PIPELINE),
	     .C_PIM3_DATA_WIDTH		(C_PIM3_DATA_WIDTH),
	     .C_PIM3_RD_FIFO_TYPE	(C_PIM3_RD_FIFO_TYPE),
	     .C_PIM3_WR_FIFO_TYPE	(C_PIM3_WR_FIFO_TYPE),
	     .C_PIM3_RD_FIFO_APP_PIPELINE(C_PIM3_RD_FIFO_APP_PIPELINE),
	     .C_PIM3_RD_FIFO_MEM_PIPELINE(C_PIM3_RD_FIFO_MEM_PIPELINE),
	     .C_PIM3_WR_FIFO_APP_PIPELINE(C_PIM3_WR_FIFO_APP_PIPELINE),
	     .C_PIM3_WR_FIFO_MEM_PIPELINE(C_PIM3_WR_FIFO_MEM_PIPELINE),
	     .C_PIM4_DATA_WIDTH		(C_PIM4_DATA_WIDTH),
	     .C_PIM4_RD_FIFO_TYPE	(C_PIM4_RD_FIFO_TYPE),
	     .C_PIM4_WR_FIFO_TYPE	(C_PIM4_WR_FIFO_TYPE),
	     .C_PIM4_RD_FIFO_APP_PIPELINE(C_PIM4_RD_FIFO_APP_PIPELINE),
	     .C_PIM4_RD_FIFO_MEM_PIPELINE(C_PIM4_RD_FIFO_MEM_PIPELINE),
	     .C_PIM4_WR_FIFO_APP_PIPELINE(C_PIM4_WR_FIFO_APP_PIPELINE),
	     .C_PIM4_WR_FIFO_MEM_PIPELINE(C_PIM4_WR_FIFO_MEM_PIPELINE),
	     .C_PIM_DATA_WIDTH		(C_PIM_DATA_WIDTH))
   npi_ict  (/*AUTOINST*/
	     // Outputs
	     .PIM0_AddrAck		(PIM0_AddrAck),
	     .PIM0_RdFIFO_Data		(PIM0_RdFIFO_Data[C_PIM0_DATA_WIDTH-1:0]),
	     .PIM0_RdFIFO_RdWdAddr	(PIM0_RdFIFO_RdWdAddr[3:0]),
	     .PIM0_WrFIFO_Empty		(PIM0_WrFIFO_Empty),
	     .PIM0_WrFIFO_AlmostFull	(PIM0_WrFIFO_AlmostFull),
	     .PIM0_RdFIFO_Empty		(PIM0_RdFIFO_Empty),
	     .PIM0_RdFIFO_Latency	(PIM0_RdFIFO_Latency[1:0]),
	     .PIM0_InitDone		(PIM0_InitDone),
	     .PIM1_AddrAck		(PIM1_AddrAck),
	     .PIM1_RdFIFO_Data		(PIM1_RdFIFO_Data[C_PIM1_DATA_WIDTH-1:0]),
	     .PIM1_RdFIFO_RdWdAddr	(PIM1_RdFIFO_RdWdAddr[3:0]),
	     .PIM1_WrFIFO_Empty		(PIM1_WrFIFO_Empty),
	     .PIM1_WrFIFO_AlmostFull	(PIM1_WrFIFO_AlmostFull),
	     .PIM1_RdFIFO_Empty		(PIM1_RdFIFO_Empty),
	     .PIM1_RdFIFO_Latency	(PIM1_RdFIFO_Latency[1:0]),
	     .PIM1_InitDone		(PIM1_InitDone),
	     .PIM2_AddrAck		(PIM2_AddrAck),
	     .PIM2_RdFIFO_Data		(PIM2_RdFIFO_Data[C_PIM2_DATA_WIDTH-1:0]),
	     .PIM2_RdFIFO_RdWdAddr	(PIM2_RdFIFO_RdWdAddr[3:0]),
	     .PIM2_WrFIFO_Empty		(PIM2_WrFIFO_Empty),
	     .PIM2_WrFIFO_AlmostFull	(PIM2_WrFIFO_AlmostFull),
	     .PIM2_RdFIFO_Empty		(PIM2_RdFIFO_Empty),
	     .PIM2_RdFIFO_Latency	(PIM2_RdFIFO_Latency[1:0]),
	     .PIM2_InitDone		(PIM2_InitDone),
	     .PIM3_AddrAck		(PIM3_AddrAck),
	     .PIM3_RdFIFO_Data		(PIM3_RdFIFO_Data[C_PIM3_DATA_WIDTH-1:0]),
	     .PIM3_RdFIFO_RdWdAddr	(PIM3_RdFIFO_RdWdAddr[3:0]),
	     .PIM3_WrFIFO_Empty		(PIM3_WrFIFO_Empty),
	     .PIM3_WrFIFO_AlmostFull	(PIM3_WrFIFO_AlmostFull),
	     .PIM3_RdFIFO_Empty		(PIM3_RdFIFO_Empty),
	     .PIM3_RdFIFO_Latency	(PIM3_RdFIFO_Latency[1:0]),
	     .PIM3_InitDone		(PIM3_InitDone),
	     .PIM4_AddrAck		(PIM4_AddrAck),
	     .PIM4_RdFIFO_Data		(PIM4_RdFIFO_Data[C_PIM4_DATA_WIDTH-1:0]),
	     .PIM4_RdFIFO_RdWdAddr	(PIM4_RdFIFO_RdWdAddr[3:0]),
	     .PIM4_WrFIFO_Empty		(PIM4_WrFIFO_Empty),
	     .PIM4_WrFIFO_AlmostFull	(PIM4_WrFIFO_AlmostFull),
	     .PIM4_RdFIFO_Empty		(PIM4_RdFIFO_Empty),
	     .PIM4_RdFIFO_Latency	(PIM4_RdFIFO_Latency[1:0]),
	     .PIM4_InitDone		(PIM4_InitDone),
	     .PIM_Addr			(PIM_Addr[31:0]),
	     .PIM_AddrReq		(PIM_AddrReq),
	     .PIM_RNW			(PIM_RNW),
	     .PIM_Size			(PIM_Size[3:0]),
	     .PIM_RdModWr		(PIM_RdModWr),
	     .PIM_WrFIFO_Data		(PIM_WrFIFO_Data[C_PIM_DATA_WIDTH-1:0]),
	     .PIM_WrFIFO_BE		(PIM_WrFIFO_BE[(C_PIM_DATA_WIDTH/8)-1:0]),
	     .PIM_WrFIFO_Push		(PIM_WrFIFO_Push),
	     .PIM_WrFIFO_Flush		(PIM_WrFIFO_Flush),
	     .PIM_RdFIFO_Pop		(PIM_RdFIFO_Pop),
	     .PIM_RdFIFO_Flush		(PIM_RdFIFO_Flush),
	     // Inputs
	     .MPMC_Clk			(MPMC_Clk),
	     .MPMC_Rst			(MPMC_Rst),
	     .PIM0_Addr			(PIM0_Addr[31:0]),
	     .PIM0_AddrReq		(PIM0_AddrReq),
	     .PIM0_RNW			(PIM0_RNW),
	     .PIM0_Size			(PIM0_Size[3:0]),
	     .PIM0_RdModWr		(PIM0_RdModWr),
	     .PIM0_WrFIFO_Data		(PIM0_WrFIFO_Data[C_PIM0_DATA_WIDTH-1:0]),
	     .PIM0_WrFIFO_BE		(PIM0_WrFIFO_BE[(C_PIM0_DATA_WIDTH/8)-1:0]),
	     .PIM0_WrFIFO_Push		(PIM0_WrFIFO_Push),
	     .PIM0_RdFIFO_Pop		(PIM0_RdFIFO_Pop),
	     .PIM0_WrFIFO_Flush		(PIM0_WrFIFO_Flush),
	     .PIM0_RdFIFO_Flush		(PIM0_RdFIFO_Flush),
	     .PIM1_Addr			(PIM1_Addr[31:0]),
	     .PIM1_AddrReq		(PIM1_AddrReq),
	     .PIM1_RNW			(PIM1_RNW),
	     .PIM1_Size			(PIM1_Size[3:0]),
	     .PIM1_RdModWr		(PIM1_RdModWr),
	     .PIM1_WrFIFO_Data		(PIM1_WrFIFO_Data[C_PIM1_DATA_WIDTH-1:0]),
	     .PIM1_WrFIFO_BE		(PIM1_WrFIFO_BE[(C_PIM1_DATA_WIDTH/8)-1:0]),
	     .PIM1_WrFIFO_Push		(PIM1_WrFIFO_Push),
	     .PIM1_RdFIFO_Pop		(PIM1_RdFIFO_Pop),
	     .PIM1_WrFIFO_Flush		(PIM1_WrFIFO_Flush),
	     .PIM1_RdFIFO_Flush		(PIM1_RdFIFO_Flush),
	     .PIM2_Addr			(PIM2_Addr[31:0]),
	     .PIM2_AddrReq		(PIM2_AddrReq),
	     .PIM2_RNW			(PIM2_RNW),
	     .PIM2_Size			(PIM2_Size[3:0]),
	     .PIM2_RdModWr		(PIM2_RdModWr),
	     .PIM2_WrFIFO_Data		(PIM2_WrFIFO_Data[C_PIM2_DATA_WIDTH-1:0]),
	     .PIM2_WrFIFO_BE		(PIM2_WrFIFO_BE[(C_PIM2_DATA_WIDTH/8)-1:0]),
	     .PIM2_WrFIFO_Push		(PIM2_WrFIFO_Push),
	     .PIM2_RdFIFO_Pop		(PIM2_RdFIFO_Pop),
	     .PIM2_WrFIFO_Flush		(PIM2_WrFIFO_Flush),
	     .PIM2_RdFIFO_Flush		(PIM2_RdFIFO_Flush),
	     .PIM3_Addr			(PIM3_Addr[31:0]),
	     .PIM3_AddrReq		(PIM3_AddrReq),
	     .PIM3_RNW			(PIM3_RNW),
	     .PIM3_Size			(PIM3_Size[3:0]),
	     .PIM3_RdModWr		(PIM3_RdModWr),
	     .PIM3_WrFIFO_Data		(PIM3_WrFIFO_Data[C_PIM3_DATA_WIDTH-1:0]),
	     .PIM3_WrFIFO_BE		(PIM3_WrFIFO_BE[(C_PIM3_DATA_WIDTH/8)-1:0]),
	     .PIM3_WrFIFO_Push		(PIM3_WrFIFO_Push),
	     .PIM3_RdFIFO_Pop		(PIM3_RdFIFO_Pop),
	     .PIM3_WrFIFO_Flush		(PIM3_WrFIFO_Flush),
	     .PIM3_RdFIFO_Flush		(PIM3_RdFIFO_Flush),
	     .PIM4_Addr			(PIM4_Addr[31:0]),
	     .PIM4_AddrReq		(PIM4_AddrReq),
	     .PIM4_RNW			(PIM4_RNW),
	     .PIM4_Size			(PIM4_Size[3:0]),
	     .PIM4_RdModWr		(PIM4_RdModWr),
	     .PIM4_WrFIFO_Data		(PIM4_WrFIFO_Data[C_PIM4_DATA_WIDTH-1:0]),
	     .PIM4_WrFIFO_BE		(PIM4_WrFIFO_BE[(C_PIM4_DATA_WIDTH/8)-1:0]),
	     .PIM4_WrFIFO_Push		(PIM4_WrFIFO_Push),
	     .PIM4_RdFIFO_Pop		(PIM4_RdFIFO_Pop),
	     .PIM4_WrFIFO_Flush		(PIM4_WrFIFO_Flush),
	     .PIM4_RdFIFO_Flush		(PIM4_RdFIFO_Flush),
	     .PIM_AddrAck		(PIM_AddrAck),
	     .PIM_WrFIFO_Empty		(PIM_WrFIFO_Empty),
	     .PIM_WrFIFO_AlmostFull	(PIM_WrFIFO_AlmostFull),
	     .PIM_RdFIFO_Data		(PIM_RdFIFO_Data[C_PIM_DATA_WIDTH-1:0]),
	     .PIM_RdFIFO_RdWdAddr	(PIM_RdFIFO_RdWdAddr[3:0]),
	     .PIM_RdFIFO_Empty		(PIM_RdFIFO_Empty),
	     .PIM_RdFIFO_Latency	(PIM_RdFIFO_Latency[1:0]),
	     .PIM_InitDone		(PIM_InitDone));

   parameter C_GNPI0_ENABLE     = 1;
   parameter C_GNPI1_ENABLE     = 1;
   parameter C_GNPI2_ENABLE     = 1;
   parameter C_GNPI3_ENABLE     = 1;
   parameter C_GNPI4_ENABLE     = 1;   
   
   /* gen_npi AUTO_TEMPLATE "_\([0-9]\)" (
    .C_PORT_ID             (@ * 32'h1000_0000),
    .C_PORT_DATA_WIDTH     (C_PIM@_DATA_WIDTH),
    .C_PORT_RDWDADDR_WIDTH (4),
    .C_PORT_BE_WIDTH       (C_PIM@_DATA_WIDTH/8),
    .C_PORT_ENABLE         (C_GNPI@_ENABLE),

    .PI_Addr		 (PIM@_Addr[]),
    .PI_AddrReq		 (PIM@_AddrReq),
    .PI_RNW		 (PIM@_RNW),
    .PI_Size		 (PIM@_Size[]),
    .PI_RdModWr		 (PIM@_RdModWr),
    .PI_RdFIFO_Flush	 (PIM@_RdFIFO_Flush),
    .PI_RdFIFO_Pop	 (PIM@_RdFIFO_Pop),
    .PI_WrFIFO_Data	 (PIM@_WrFIFO_Data[C_PIM@_DATA_WIDTH-1:0]),
    .PI_WrFIFO_BE	 (PIM@_WrFIFO_BE[(C_PIM@_DATA_WIDTH/8)-1:0]),
    .PI_WrFIFO_Push	 (PIM@_WrFIFO_Push),
    .PI_WrFIFO_Flush	 (PIM@_WrFIFO_Flush),
    .PI_AddrAck	         (PIM@_AddrAck),
    .PI_RdFIFO_RdWdAddr	 (PIM@_RdFIFO_RdWdAddr[3:0]),
    .PI_RdFIFO_Data	 (PIM@_RdFIFO_Data[C_PIM@_DATA_WIDTH-1:0]),
    .PI_RdFIFO_Empty	 (PIM@_RdFIFO_Empty),
    .PI_WrFIFO_Empty	 (PIM@_WrFIFO_Empty),
    .PI_WrFIFO_AlmostFull(PIM@_WrFIFO_AlmostFull),
    .PI_InitDone         (PIM@_InitDone),
    .PI_RdFIFO_Latency   (PIM@_RdFIFO_Latency[]),
    .PI_RdFIFO_PushEarly (PIM@_RdFIFO_PushEarly),    
    )*/

   gen_npi #(/*AUTOINSTPARAM*/
	     // Parameters
	     .C_PORT_ID			(0 * 32'h1000_0000),	 // Templated
	     .C_PORT_DATA_WIDTH		(C_PIM0_DATA_WIDTH),	 // Templated
	     .C_PORT_RDWDADDR_WIDTH	(4),			 // Templated
	     .C_PORT_BE_WIDTH		(C_PIM0_DATA_WIDTH/8),	 // Templated
	     .C_PORT_ENABLE		(C_GNPI0_ENABLE))	 // Templated
   gnpi_0 (/*AUTOINST*/
	   // Outputs
	   .PI_Addr			(PIM0_Addr[31:0]),	 // Templated
	   .PI_AddrReq			(PIM0_AddrReq),		 // Templated
	   .PI_RNW			(PIM0_RNW),		 // Templated
	   .PI_Size			(PIM0_Size[3:0]),	 // Templated
	   .PI_RdModWr			(PIM0_RdModWr),		 // Templated
	   .PI_RdFIFO_Flush		(PIM0_RdFIFO_Flush),	 // Templated
	   .PI_RdFIFO_Pop		(PIM0_RdFIFO_Pop),	 // Templated
	   .PI_WrFIFO_Data		(PIM0_WrFIFO_Data[C_PIM0_DATA_WIDTH-1:0]), // Templated
	   .PI_WrFIFO_BE		(PIM0_WrFIFO_BE[(C_PIM0_DATA_WIDTH/8)-1:0]), // Templated
	   .PI_WrFIFO_Push		(PIM0_WrFIFO_Push),	 // Templated
	   .PI_WrFIFO_Flush		(PIM0_WrFIFO_Flush),	 // Templated
	   // Inputs
	   .Clk				(Clk),
	   .Rst				(Rst),
	   .PI_AddrAck			(PIM0_AddrAck),		 // Templated
	   .PI_RdFIFO_RdWdAddr		(PIM0_RdFIFO_RdWdAddr[3:0]), // Templated
	   .PI_RdFIFO_Data		(PIM0_RdFIFO_Data[C_PIM0_DATA_WIDTH-1:0]), // Templated
	   .PI_RdFIFO_Empty		(PIM0_RdFIFO_Empty),	 // Templated
	   .PI_RdFIFO_Latency		(PIM0_RdFIFO_Latency[1:0]), // Templated
	   .PI_WrFIFO_Empty		(PIM0_WrFIFO_Empty),	 // Templated
	   .PI_WrFIFO_AlmostFull	(PIM0_WrFIFO_AlmostFull), // Templated
	   .PI_InitDone			(PIM0_InitDone));	 // Templated

   gen_npi #(/*AUTOINSTPARAM*/
	     // Parameters
	     .C_PORT_ID			(1 * 32'h1000_0000),	 // Templated
	     .C_PORT_DATA_WIDTH		(C_PIM1_DATA_WIDTH),	 // Templated
	     .C_PORT_RDWDADDR_WIDTH	(4),			 // Templated
	     .C_PORT_BE_WIDTH		(C_PIM1_DATA_WIDTH/8),	 // Templated
	     .C_PORT_ENABLE		(C_GNPI1_ENABLE))	 // Templated
   gnpi_1 (/*AUTOINST*/
	   // Outputs
	   .PI_Addr			(PIM1_Addr[31:0]),	 // Templated
	   .PI_AddrReq			(PIM1_AddrReq),		 // Templated
	   .PI_RNW			(PIM1_RNW),		 // Templated
	   .PI_Size			(PIM1_Size[3:0]),	 // Templated
	   .PI_RdModWr			(PIM1_RdModWr),		 // Templated
	   .PI_RdFIFO_Flush		(PIM1_RdFIFO_Flush),	 // Templated
	   .PI_RdFIFO_Pop		(PIM1_RdFIFO_Pop),	 // Templated
	   .PI_WrFIFO_Data		(PIM1_WrFIFO_Data[C_PIM1_DATA_WIDTH-1:0]), // Templated
	   .PI_WrFIFO_BE		(PIM1_WrFIFO_BE[(C_PIM1_DATA_WIDTH/8)-1:0]), // Templated
	   .PI_WrFIFO_Push		(PIM1_WrFIFO_Push),	 // Templated
	   .PI_WrFIFO_Flush		(PIM1_WrFIFO_Flush),	 // Templated
	   // Inputs
	   .Clk				(Clk),
	   .Rst				(Rst),
	   .PI_AddrAck			(PIM1_AddrAck),		 // Templated
	   .PI_RdFIFO_RdWdAddr		(PIM1_RdFIFO_RdWdAddr[3:0]), // Templated
	   .PI_RdFIFO_Data		(PIM1_RdFIFO_Data[C_PIM1_DATA_WIDTH-1:0]), // Templated
	   .PI_RdFIFO_Empty		(PIM1_RdFIFO_Empty),	 // Templated
	   .PI_RdFIFO_Latency		(PIM1_RdFIFO_Latency[1:0]), // Templated
	   .PI_WrFIFO_Empty		(PIM1_WrFIFO_Empty),	 // Templated
	   .PI_WrFIFO_AlmostFull	(PIM1_WrFIFO_AlmostFull), // Templated
	   .PI_InitDone			(PIM1_InitDone));	 // Templated

   gen_npi #(/*AUTOINSTPARAM*/
	     // Parameters
	     .C_PORT_ID			(2 * 32'h1000_0000),	 // Templated
	     .C_PORT_DATA_WIDTH		(C_PIM2_DATA_WIDTH),	 // Templated
	     .C_PORT_RDWDADDR_WIDTH	(4),			 // Templated
	     .C_PORT_BE_WIDTH		(C_PIM2_DATA_WIDTH/8),	 // Templated
	     .C_PORT_ENABLE		(C_GNPI2_ENABLE))	 // Templated
   gnpi_2 (/*AUTOINST*/
	   // Outputs
	   .PI_Addr			(PIM2_Addr[31:0]),	 // Templated
	   .PI_AddrReq			(PIM2_AddrReq),		 // Templated
	   .PI_RNW			(PIM2_RNW),		 // Templated
	   .PI_Size			(PIM2_Size[3:0]),	 // Templated
	   .PI_RdModWr			(PIM2_RdModWr),		 // Templated
	   .PI_RdFIFO_Flush		(PIM2_RdFIFO_Flush),	 // Templated
	   .PI_RdFIFO_Pop		(PIM2_RdFIFO_Pop),	 // Templated
	   .PI_WrFIFO_Data		(PIM2_WrFIFO_Data[C_PIM2_DATA_WIDTH-1:0]), // Templated
	   .PI_WrFIFO_BE		(PIM2_WrFIFO_BE[(C_PIM2_DATA_WIDTH/8)-1:0]), // Templated
	   .PI_WrFIFO_Push		(PIM2_WrFIFO_Push),	 // Templated
	   .PI_WrFIFO_Flush		(PIM2_WrFIFO_Flush),	 // Templated
	   // Inputs
	   .Clk				(Clk),
	   .Rst				(Rst),
	   .PI_AddrAck			(PIM2_AddrAck),		 // Templated
	   .PI_RdFIFO_RdWdAddr		(PIM2_RdFIFO_RdWdAddr[3:0]), // Templated
	   .PI_RdFIFO_Data		(PIM2_RdFIFO_Data[C_PIM2_DATA_WIDTH-1:0]), // Templated
	   .PI_RdFIFO_Empty		(PIM2_RdFIFO_Empty),	 // Templated
	   .PI_RdFIFO_Latency		(PIM2_RdFIFO_Latency[1:0]), // Templated
	   .PI_WrFIFO_Empty		(PIM2_WrFIFO_Empty),	 // Templated
	   .PI_WrFIFO_AlmostFull	(PIM2_WrFIFO_AlmostFull), // Templated
	   .PI_InitDone			(PIM2_InitDone));	 // Templated

   gen_npi #(/*AUTOINSTPARAM*/
	     // Parameters
	     .C_PORT_ID			(3 * 32'h1000_0000),	 // Templated
	     .C_PORT_DATA_WIDTH		(C_PIM3_DATA_WIDTH),	 // Templated
	     .C_PORT_RDWDADDR_WIDTH	(4),			 // Templated
	     .C_PORT_BE_WIDTH		(C_PIM3_DATA_WIDTH/8),	 // Templated
	     .C_PORT_ENABLE		(C_GNPI3_ENABLE))	 // Templated
   gnpi_3 (/*AUTOINST*/
	   // Outputs
	   .PI_Addr			(PIM3_Addr[31:0]),	 // Templated
	   .PI_AddrReq			(PIM3_AddrReq),		 // Templated
	   .PI_RNW			(PIM3_RNW),		 // Templated
	   .PI_Size			(PIM3_Size[3:0]),	 // Templated
	   .PI_RdModWr			(PIM3_RdModWr),		 // Templated
	   .PI_RdFIFO_Flush		(PIM3_RdFIFO_Flush),	 // Templated
	   .PI_RdFIFO_Pop		(PIM3_RdFIFO_Pop),	 // Templated
	   .PI_WrFIFO_Data		(PIM3_WrFIFO_Data[C_PIM3_DATA_WIDTH-1:0]), // Templated
	   .PI_WrFIFO_BE		(PIM3_WrFIFO_BE[(C_PIM3_DATA_WIDTH/8)-1:0]), // Templated
	   .PI_WrFIFO_Push		(PIM3_WrFIFO_Push),	 // Templated
	   .PI_WrFIFO_Flush		(PIM3_WrFIFO_Flush),	 // Templated
	   // Inputs
	   .Clk				(Clk),
	   .Rst				(Rst),
	   .PI_AddrAck			(PIM3_AddrAck),		 // Templated
	   .PI_RdFIFO_RdWdAddr		(PIM3_RdFIFO_RdWdAddr[3:0]), // Templated
	   .PI_RdFIFO_Data		(PIM3_RdFIFO_Data[C_PIM3_DATA_WIDTH-1:0]), // Templated
	   .PI_RdFIFO_Empty		(PIM3_RdFIFO_Empty),	 // Templated
	   .PI_RdFIFO_Latency		(PIM3_RdFIFO_Latency[1:0]), // Templated
	   .PI_WrFIFO_Empty		(PIM3_WrFIFO_Empty),	 // Templated
	   .PI_WrFIFO_AlmostFull	(PIM3_WrFIFO_AlmostFull), // Templated
	   .PI_InitDone			(PIM3_InitDone));	 // Templated

   gen_npi #(/*AUTOINSTPARAM*/
	     // Parameters
	     .C_PORT_ID			(4 * 32'h1000_0000),	 // Templated
	     .C_PORT_DATA_WIDTH		(C_PIM4_DATA_WIDTH),	 // Templated
	     .C_PORT_RDWDADDR_WIDTH	(4),			 // Templated
	     .C_PORT_BE_WIDTH		(C_PIM4_DATA_WIDTH/8),	 // Templated
	     .C_PORT_ENABLE		(C_GNPI4_ENABLE))	 // Templated
   gnpi_4 (/*AUTOINST*/
	   // Outputs
	   .PI_Addr			(PIM4_Addr[31:0]),	 // Templated
	   .PI_AddrReq			(PIM4_AddrReq),		 // Templated
	   .PI_RNW			(PIM4_RNW),		 // Templated
	   .PI_Size			(PIM4_Size[3:0]),	 // Templated
	   .PI_RdModWr			(PIM4_RdModWr),		 // Templated
	   .PI_RdFIFO_Flush		(PIM4_RdFIFO_Flush),	 // Templated
	   .PI_RdFIFO_Pop		(PIM4_RdFIFO_Pop),	 // Templated
	   .PI_WrFIFO_Data		(PIM4_WrFIFO_Data[C_PIM4_DATA_WIDTH-1:0]), // Templated
	   .PI_WrFIFO_BE		(PIM4_WrFIFO_BE[(C_PIM4_DATA_WIDTH/8)-1:0]), // Templated
	   .PI_WrFIFO_Push		(PIM4_WrFIFO_Push),	 // Templated
	   .PI_WrFIFO_Flush		(PIM4_WrFIFO_Flush),	 // Templated
	   // Inputs
	   .Clk				(Clk),
	   .Rst				(Rst),
	   .PI_AddrAck			(PIM4_AddrAck),		 // Templated
	   .PI_RdFIFO_RdWdAddr		(PIM4_RdFIFO_RdWdAddr[3:0]), // Templated
	   .PI_RdFIFO_Data		(PIM4_RdFIFO_Data[C_PIM4_DATA_WIDTH-1:0]), // Templated
	   .PI_RdFIFO_Empty		(PIM4_RdFIFO_Empty),	 // Templated
	   .PI_RdFIFO_Latency		(PIM4_RdFIFO_Latency[1:0]), // Templated
	   .PI_WrFIFO_Empty		(PIM4_WrFIFO_Empty),	 // Templated
	   .PI_WrFIFO_AlmostFull	(PIM4_WrFIFO_AlmostFull), // Templated
	   .PI_InitDone			(PIM4_InitDone));	 // Templated
   
endmodule
// Local Variables:
// verilog-library-directories:("." "/opt/ise12.3/ISE_DS/ISE/verilog/src/unisims/" "../" "../../" "../../sim/")
// verilog-library-files:(".""sata_phy")
// verilog-library-extensions:(".v" ".h")
// End:
// 
// npi_ict_top.v ends here

