// gen_npi.v --- 
// 
// Filename: gen_npi.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Mon Aug  6 16:58:13 2012 (+0800)
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
module gen_npi (/*AUTOARG*/
   // Outputs
   PI_Addr, PI_AddrReq, PI_RNW, PI_Size, PI_RdModWr, PI_RdFIFO_Flush,
   PI_RdFIFO_Pop, PI_WrFIFO_Data, PI_WrFIFO_BE, PI_WrFIFO_Push,
   PI_WrFIFO_Flush,
   // Inputs
   Clk, Rst, PI_AddrAck, PI_RdFIFO_RdWdAddr, PI_RdFIFO_Data,
   PI_RdFIFO_Empty, PI_RdFIFO_Latency, PI_WrFIFO_Empty,
   PI_WrFIFO_AlmostFull, PI_InitDone
   );
   parameter C_PORT_ID             = 0;
   parameter C_PORT_DATA_WIDTH     = 64;
   parameter C_PORT_RDWDADDR_WIDTH = 4;
   parameter C_PORT_BE_WIDTH       = 8;
   parameter C_PORT_ENABLE         = 0;
   
   input Clk;
   input Rst;
   
   output [31:0] PI_Addr;
   output 	 PI_AddrReq;
   output 	 PI_RNW;
   output [3:0]  PI_Size;
   output 	 PI_RdModWr;   
   input 	 PI_AddrAck;

   input [C_PORT_RDWDADDR_WIDTH-1:0] PI_RdFIFO_RdWdAddr;
   input [C_PORT_DATA_WIDTH-1:0]     PI_RdFIFO_Data;
   output 			     PI_RdFIFO_Flush;
   output 			     PI_RdFIFO_Pop;
   input 			     PI_RdFIFO_Empty;
   input [1:0] 			     PI_RdFIFO_Latency;
   
   output [C_PORT_DATA_WIDTH-1:0]    PI_WrFIFO_Data;
   output [C_PORT_BE_WIDTH-1:0]      PI_WrFIFO_BE;
   output 			     PI_WrFIFO_Push;
   output 			     PI_WrFIFO_Flush;
   input 			     PI_WrFIFO_Empty;
   input 			     PI_WrFIFO_AlmostFull;

   input 			     PI_InitDone;

   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [31:0]		PI_Addr;
   reg			PI_AddrReq;
   reg			PI_RNW;
   reg			PI_RdFIFO_Flush;
   reg			PI_RdModWr;
   reg [3:0]		PI_Size;
   reg [C_PORT_BE_WIDTH-1:0] PI_WrFIFO_BE;
   reg [C_PORT_DATA_WIDTH-1:0] PI_WrFIFO_Data;
   reg			PI_WrFIFO_Flush;
   reg			PI_WrFIFO_Push;
   // End of automatics

   task npi_write_single;
      input [31:0] address;
      input [31:0] data;
      begin
	 PI_AddrReq = 1;
	 PI_Addr    = address + C_PORT_ID;
	 PI_RNW     = 0;
	 PI_Size    = 0;
         PI_RdModWr = 1;
	 @(posedge Clk);
	 while (PI_AddrAck == 0)
	   @(posedge Clk);
	 PI_AddrReq = 0;
	 PI_Addr    = 0;
	 PI_RNW     = 0;
         PI_RdModWr = 0;

	 PI_WrFIFO_Push = 1;
	 PI_WrFIFO_Data = data;
	 PI_WrFIFO_BE   = ~0;
	 @(posedge Clk);
	 PI_WrFIFO_Push = 0;
	 PI_WrFIFO_Data = 0;
	 PI_WrFIFO_BE   = 0;
	 
	 @(posedge Clk);
	 @(posedge Clk);
	 //while (PI_WrFIFO_Empty == 0)
	 //  @(posedge Clk);
      end
   endtask // npi_write_single

   integer j, k ;
   task npi_write;
      input [31:0] address;
      input [3:0]  size;
      input [31:0] data;
      begin
	 k = (1<<(size + 1))/(C_PORT_DATA_WIDTH/32);
	 for (j = 0; j < k; j = j + 1) begin
	    PI_WrFIFO_Push = 1;
	    PI_WrFIFO_Data = data + j;
	    PI_WrFIFO_BE   = ~0;
	    @(posedge Clk);
	 end
	 PI_WrFIFO_Push = 0;
	 PI_WrFIFO_Data = 0;
	 PI_WrFIFO_BE   = 0;

	 PI_AddrReq = 1;
	 PI_Addr    = address + C_PORT_ID;
	 PI_RNW     = 0;
	 PI_Size    = size;
         PI_RdModWr = 1;
	 @(posedge Clk);
	 while (PI_AddrAck == 0)
	   @(posedge Clk);
	 PI_AddrReq = 0;
	 PI_Addr    = 0;
	 PI_RNW     = 0;
         PI_RdModWr = 0;
	 
	 @(posedge Clk);
	 //@(posedge Clk);
	 //while (PI_WrFIFO_Empty == 0)
	 //  @(posedge Clk);
      end
   endtask // npi_write
	 
   task npi_write_err;
      input [31:0] address;
      input [3:0]  size;
      input [31:0] data;
      begin
	 k = (1<<(size + 1))/(C_PORT_DATA_WIDTH/32);
	 k = k - 4;
	 for (j = 0; j < k; j = j + 1) begin
	    PI_WrFIFO_Push = 1;
	    PI_WrFIFO_Data = data + j;
	    PI_WrFIFO_BE   = ~0;
	    @(posedge Clk);
	 end
	 PI_WrFIFO_Push = 0;
	 PI_WrFIFO_Data = 0;
	 PI_WrFIFO_BE   = 0;

	 PI_AddrReq = 1;
	 PI_Addr    = address + C_PORT_ID;
	 PI_RNW     = 0;
	 PI_Size    = size;
         PI_RdModWr = 1;
	 @(posedge Clk);
	 while (PI_AddrAck == 0)
	   @(posedge Clk);
	 PI_AddrReq = 0;
	 PI_Addr    = 0;
	 PI_RNW     = 0;
         PI_RdModWr = 0;
	 
	 @(posedge Clk);
	 //@(posedge Clk);
	 //while (PI_WrFIFO_Empty == 0)
	 //  @(posedge Clk);
      end
   endtask // npi_write
   task npi_read;
      input [31:0] address;
      input [3:0]  size;
      begin
	 PI_AddrReq = 1;
	 PI_Addr    = address + C_PORT_ID;
	 PI_RNW     = 1;
	 PI_Size    = size;
	 @(posedge Clk);
	 while (PI_AddrAck == 0)
	   @(posedge Clk);
	 PI_AddrReq = 0;
	 PI_Addr    = 0;
	 PI_RNW     = 0;
      end
   endtask // npi_rw_single
   
   integer 			     i;
   initial begin
      PI_AddrReq      = 0;
      PI_Addr         = 0;
      PI_RNW          = 0;
      PI_Size         = 0;
      PI_RdModWr      = 0;
      
      PI_WrFIFO_Flush = 0;
      PI_WrFIFO_Push  = 0;
      PI_WrFIFO_Data  = 0;
      PI_WrFIFO_BE    = 0;
      
      PI_RdFIFO_Flush = 0;
      
      @(posedge ~Rst);
      
      @(posedge PI_InitDone);
      
      for (i = 0; i < 100; i = i + 1)
	@(posedge Clk);
      
      while (C_PORT_ENABLE == 0)
	@(posedge Clk);

      npi_write_single(32'h200, 1);
      npi_write(32'h300, 1, 1);
      npi_write(32'h400, 2, 2);
      npi_write(32'h500, 3, 3);
      npi_write(32'h600, 4, 4);
      npi_write(32'h700, 5, 5);      
      
      npi_read(32'h200, 0);
      npi_read(32'h300, 1);
      npi_read(32'h400, 2);
      npi_read(32'h500, 3);
      npi_read(32'h600, 4);
      npi_read(32'h700, 5);
      
      npi_write_err(32'h700, 5, 5);      
   end

   assign PI_RdFIFO_Pop = ~PI_RdFIFO_Empty;
endmodule
// 
// gen_npi.v ends here
