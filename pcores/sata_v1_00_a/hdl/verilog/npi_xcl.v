// npi_xcl.v --- 
// 
// Filename: npi_xcl.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Mon Aug 13 10:04:24 2012 (+0800)
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
module npi_xcl (/*AUTOARG*/
   // Outputs
   DCACHE_FSL_IN_CONTROL, DCACHE_FSL_IN_DATA, DCACHE_FSL_IN_EXISTS,
   DCACHE_FSL_OUT_FULL, ICACHE_FSL_IN_CONTROL, ICACHE_FSL_IN_DATA,
   ICACHE_FSL_IN_EXISTS, ICACHE_FSL_OUT_FULL, PI_Addr, PI_AddrReq,
   PI_RNW, PI_RdModWr, PI_Size, PI_WrFIFO_Data, PI_WrFIFO_BE,
   PI_WrFIFO_Push, PI_RdFIFO_Pop, PI_WrFIFO_Flush, PI_RdFIFO_Flush,
   // Inputs
   DCACHE_FSL_IN_CLK, DCACHE_FSL_IN_READ, DCACHE_FSL_OUT_CLK,
   DCACHE_FSL_OUT_CONTROL, DCACHE_FSL_OUT_DATA, DCACHE_FSL_OUT_WRITE,
   ICACHE_FSL_IN_CLK, ICACHE_FSL_IN_READ, ICACHE_FSL_OUT_CLK,
   ICACHE_FSL_OUT_CONTROL, ICACHE_FSL_OUT_DATA, ICACHE_FSL_OUT_WRITE,
   MPMC_Clk, MPMC_Rst, sys_clk, sys_rst, PI_AddrAck, PI_InitDone,
   PI_RdFIFO_Data, PI_RdFIFO_RdWdAddr, PI_WrFIFO_AlmostFull,
   PI_WrFIFO_Empty, PI_RdFIFO_Empty, PI_RdFIFO_Latency
   );
   parameter C_FAMILY = "virtex5";
   parameter C_XCL_CHIPSCOPE = 0;
   
   input MPMC_Clk;
   input MPMC_Rst;

   input sys_clk;
   input sys_rst;

   /*AUTOINOUTCOMP("mb_top", "^ICACHE_")*/
   // Beginning of automatic in/out/inouts (from specific module)
   output		ICACHE_FSL_IN_CONTROL;
   output [0:31]	ICACHE_FSL_IN_DATA;
   output		ICACHE_FSL_IN_EXISTS;
   output		ICACHE_FSL_OUT_FULL;
   input		ICACHE_FSL_IN_CLK;
   input		ICACHE_FSL_IN_READ;
   input		ICACHE_FSL_OUT_CLK;
   input		ICACHE_FSL_OUT_CONTROL;
   input [0:31]		ICACHE_FSL_OUT_DATA;
   input		ICACHE_FSL_OUT_WRITE;
   // End of automatics
   /*AUTOINOUTCOMP("mb_top", "^DCACHE_")*/
   // Beginning of automatic in/out/inouts (from specific module)
   output		DCACHE_FSL_IN_CONTROL;
   output [0:31]	DCACHE_FSL_IN_DATA;
   output		DCACHE_FSL_IN_EXISTS;
   output		DCACHE_FSL_OUT_FULL;
   input		DCACHE_FSL_IN_CLK;
   input		DCACHE_FSL_IN_READ;
   input		DCACHE_FSL_OUT_CLK;
   input		DCACHE_FSL_OUT_CONTROL;
   input [0:31]		DCACHE_FSL_OUT_DATA;
   input		DCACHE_FSL_OUT_WRITE;
   // End of automatics

   output [31:0] 	PI_Addr;
   output 		PI_AddrReq;
   input 		PI_AddrAck;
   output 		PI_RNW;
   output 		PI_RdModWr;
   output [3:0] 	PI_Size;
   input 		PI_InitDone;
   output [31:0] 	PI_WrFIFO_Data;
   output [3:0] 	PI_WrFIFO_BE;
   output 		PI_WrFIFO_Push;
   input [31:0] 	PI_RdFIFO_Data;
   output 		PI_RdFIFO_Pop;
   input [3:0] 		PI_RdFIFO_RdWdAddr;
   input 		PI_WrFIFO_AlmostFull;
   input 		PI_WrFIFO_Empty;
   output 		PI_WrFIFO_Flush;
   input 		PI_RdFIFO_Empty;
   output 		PI_RdFIFO_Flush;
   input [1:0] 		PI_RdFIFO_Latency;
   
  localparam C_PI_A_SUBTYPE              = "DXCL2";
  localparam C_PI_B_SUBTYPE              = "INACTIVE";
  localparam C_PI_BASEADDR               = 32'hc0000000;
  localparam C_PI_HIGHADDR               = 32'hffffffff;
  localparam C_PI_OFFSET                 = 0;
  localparam C_PI_ADDR_WIDTH             = 32;
  localparam C_PI_DATA_WIDTH             = 32;
  localparam C_PI_BE_WIDTH               = 4;
  localparam C_PI_RDWDADDR_WIDTH         = 4;
  localparam C_PI_RDDATA_DELAY           = 2;
  localparam C_XCL_A_WRITEXFER           = 1;
  localparam C_XCL_A_LINESIZE            = 8;
  localparam C_XCL_B_WRITEXFER           = 1;
  localparam C_XCL_B_LINESIZE            = 4;
  localparam C_XCL_PIPE_STAGES           = 2;
  localparam C_MEM_DATA_WIDTH            = 32; // unused (for RdModWr) 
  localparam C_MEM_SDR_DATA_WIDTH        = 32; // unused

   dualxcl #(/*AUTOINSTPARAM*/
	     // Parameters
	     .C_FAMILY			(C_FAMILY),
	     .C_PI_A_SUBTYPE		(C_PI_A_SUBTYPE),
	     .C_PI_B_SUBTYPE		(C_PI_B_SUBTYPE),
	     .C_PI_BASEADDR		(C_PI_BASEADDR),
	     .C_PI_HIGHADDR		(C_PI_HIGHADDR),
	     .C_PI_OFFSET		(C_PI_OFFSET),
	     .C_PI_ADDR_WIDTH		(C_PI_ADDR_WIDTH),
	     .C_PI_DATA_WIDTH		(C_PI_DATA_WIDTH),
	     .C_PI_BE_WIDTH		(C_PI_BE_WIDTH),
	     .C_PI_RDWDADDR_WIDTH	(C_PI_RDWDADDR_WIDTH),
	     .C_PI_RDDATA_DELAY		(C_PI_RDDATA_DELAY),
	     .C_XCL_A_WRITEXFER		(C_XCL_A_WRITEXFER),
	     .C_XCL_A_LINESIZE		(C_XCL_A_LINESIZE),
	     .C_XCL_B_WRITEXFER		(C_XCL_B_WRITEXFER),
	     .C_XCL_B_LINESIZE		(C_XCL_B_LINESIZE),
	     .C_XCL_PIPE_STAGES		(C_XCL_PIPE_STAGES),
	     .C_MEM_DATA_WIDTH		(C_MEM_DATA_WIDTH),
	     .C_MEM_SDR_DATA_WIDTH	(C_MEM_SDR_DATA_WIDTH))
   dualxcl  (
	     // Outputs
	     .FSL_A_M_Full		(DCACHE_FSL_OUT_FULL),
	     .FSL_A_S_Data		(DCACHE_FSL_IN_DATA[0:31]),
	     .FSL_A_S_Control		(DCACHE_FSL_IN_CONTROL),
	     .FSL_A_S_Exists		(DCACHE_FSL_IN_EXISTS),
	     .FSL_B_M_Full		(ICACHE_FSL_OUT_FULL),
	     .FSL_B_S_Data		(ICACHE_FSL_IN_DATA[0:31]),
	     .FSL_B_S_Control		(ICACHE_FSL_IN_CONTROL),
	     .FSL_B_S_Exists		(ICACHE_FSL_IN_EXISTS),
	     .PI_Addr			(PI_Addr[C_PI_ADDR_WIDTH-1:0]),
	     .PI_AddrReq		(PI_AddrReq),
	     .PI_RNW			(PI_RNW),
	     .PI_RdModWr		(PI_RdModWr),
	     .PI_Size			(PI_Size[3:0]),
	     .PI_WrFIFO_Data		(PI_WrFIFO_Data[C_PI_DATA_WIDTH-1:0]),
	     .PI_WrFIFO_BE		(PI_WrFIFO_BE[C_PI_BE_WIDTH-1:0]),
	     .PI_WrFIFO_Push		(PI_WrFIFO_Push),
	     .PI_RdFIFO_Pop		(PI_RdFIFO_Pop),
	     .PI_WrFIFO_Flush		(PI_WrFIFO_Flush),
	     .PI_RdFIFO_Flush		(PI_RdFIFO_Flush),
	     // Inputs
	     .Clk			(sys_clk),
	     .Clk_MPMC			(MPMC_Clk),
	     .Rst			(sys_rst),
	     .FSL_A_M_Clk		(DCACHE_FSL_IN_CLK),
	     .FSL_A_M_Write		(DCACHE_FSL_OUT_WRITE),
	     .FSL_A_M_Data		(DCACHE_FSL_OUT_DATA[0:31]),
	     .FSL_A_M_Control		(DCACHE_FSL_OUT_CONTROL),
	     .FSL_A_S_Clk		(DCACHE_FSL_OUT_CLK),
	     .FSL_A_S_Read		(DCACHE_FSL_IN_READ),
	     .FSL_B_M_Clk		(ICACHE_FSL_IN_CLK),
	     .FSL_B_M_Write		(ICACHE_FSL_OUT_WRITE),
	     .FSL_B_M_Data		(ICACHE_FSL_OUT_DATA[0:31]),
	     .FSL_B_M_Control		(ICACHE_FSL_OUT_CONTROL),
	     .FSL_B_S_Clk		(ICACHE_FSL_OUT_CLK),
	     .FSL_B_S_Read		(ICACHE_FSL_IN_READ),
	     .PI_AddrAck		(PI_AddrAck),
	     .PI_InitDone		(PI_InitDone),
	     .PI_RdFIFO_Data		(PI_RdFIFO_Data[C_PI_DATA_WIDTH-1:0]),
	     .PI_RdFIFO_RdWdAddr	(PI_RdFIFO_RdWdAddr[C_PI_RDWDADDR_WIDTH-1:0]),
	     .PI_WrFIFO_AlmostFull	(PI_WrFIFO_AlmostFull),
	     .PI_RdFIFO_Empty		(PI_RdFIFO_Empty));

   wire [127:0] 	TRIG0;
   wire [127:0] 	TRIG1;
   wire [127:0] 	TRIG2;

   assign TRIG0[31:0]  = DCACHE_FSL_IN_DATA;
   assign TRIG0[63:32] = DCACHE_FSL_OUT_DATA;
   assign TRIG0[64]    = DCACHE_FSL_IN_CONTROL;
   assign TRIG0[65]    = DCACHE_FSL_IN_EXISTS;
   assign TRIG0[66]    = DCACHE_FSL_OUT_FULL;
   assign TRIG0[67]    = DCACHE_FSL_IN_READ;
   assign TRIG0[68]    = DCACHE_FSL_OUT_CONTROL;
   assign TRIG0[69]    = DCACHE_FSL_OUT_WRITE;

   assign TRIG1[31:0]    = PI_Addr;
   assign TRIG1[63:32]   = PI_WrFIFO_Data;
   assign TRIG1[95:64]   = PI_RdFIFO_Data;
   assign TRIG1[96]      = PI_AddrReq;
   assign TRIG1[97]      = PI_AddrAck;   
   assign TRIG1[98]      = PI_RNW;
   assign TRIG1[99]      = PI_RdModWr;
   assign TRIG1[103:100] = PI_Size;
   assign TRIG1[104]     = PI_InitDone;
   assign TRIG1[108:105] = PI_WrFIFO_BE;
   assign TRIG1[109]     = PI_WrFIFO_Push;
   assign TRIG1[110]     = PI_WrFIFO_AlmostFull;
   assign TRIG1[111]     = PI_WrFIFO_Empty;
   assign TRIG1[112]     = PI_WrFIFO_Flush;   
   assign TRIG1[113]     = PI_RdFIFO_Empty;   
   assign TRIG1[117:114] = PI_RdFIFO_RdWdAddr;   
   assign TRIG1[118]     = PI_RdFIFO_Pop;   
   assign TRIG1[119]     = PI_RdFIFO_Flush;
   assign TRIG1[121:120] = PI_RdFIFO_Latency;      
   
   wire [35:0] 		CONTROL0;
   wire [35:0] 		CONTROL1;
   wire [35:0] 		CONTROL2;
   generate if (C_XCL_CHIPSCOPE == 1)
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
	chipscope_ila_128x1
	  ila2 (
		// Outputs
		.TRIG_OUT		(),
		// Inouts
		.CONTROL		(CONTROL2[35:0]),
		// Inputs
		.CLK			(MPMC_Clk),
		.TRIG0			(TRIG2[127:0]));	
     end
   endgenerate
endmodule // npi_xcl
// Local Variables:
// verilog-library-directories:("." "/opt/ise12.3/ISE_DS/ISE/verilog/src/unisims/" "npi")
// verilog-library-files:(".""sata_phy")
// verilog-library-extensions:(".v" ".h")
// End:
// 
// npi_xcl.v ends here
