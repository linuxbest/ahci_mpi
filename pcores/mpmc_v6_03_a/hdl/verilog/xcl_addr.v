//-----------------------------------------------------------------------------
//-- (c) Copyright 2006 - 2009 Xilinx, Inc. All rights reserved.
//--
//-- This file contains confidential and proprietary information
//-- of Xilinx, Inc. and is protected under U.S. and
//-- international copyright and other intellectual property
//-- laws.
//--
//-- DISCLAIMER
//-- This disclaimer is not a license and does not grant any
//-- rights to the materials distributed herewith. Except as
//-- otherwise provided in a valid license issued to you by
//-- Xilinx, and to the maximum extent permitted by applicable
//-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
//-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
//-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
//-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
//-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
//-- (2) Xilinx shall not be liable (whether in contract or tort,
//-- including negligence, or under any other theory of
//-- liability) for any loss or damage of any kind or nature
//-- related to, arising under or in connection with these
//-- materials, including for any direct, or any indirect,
//-- special, incidental, or consequential loss or damage
//-- (including loss of data, profits, goodwill, or any type of
//-- loss or damage suffered as a result of any action brought
//-- by a third party) even if such damage or loss was
//-- reasonably foreseeable or Xilinx had been advised of the
//-- possibility of the same.
//--
//-- CRITICAL APPLICATIONS
//-- Xilinx products are not designed or intended to be fail-
//-- safe, or for use in any application requiring fail-safe
//-- performance, such as life-support or safety devices or
//-- systems, Class III medical devices, nuclear facilities,
//-- applications related to the deployment of airbags, or any
//-- other applications that could lead to death, personal
//-- injury, or severe property or environmental damage
//-- (individually and collectively, "Critical
//-- Applications"). Customer assumes the sole risk and
//-- liability of any use of Xilinx products in Critical
//-- Applications, subject only to applicable laws and
//-- regulations governing limitations on product liability.
//--
//-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
//-- PART OF THIS FILE AT ALL TIMES.
//-----------------------------------------------------------------------------
//
// Description:       XCL Address Module
//   Contains the NPI Logic and control logic for the XCL PIM.  If doing 
//   cacheline writes, the write module will activate first and push the data 
//   into the WrFIFO, then issue an AddrReq.  In all other cases, the AddrReq 
//   will be asserted first, and upon AddrAck, the addr module will start either
//   the Write Module or the Read Module so they are ready to handle the Data.  
//   The transaction will complete when all data has been read, or all data has 
//   been written and an the addrack has been received.
// Verilog-standard:  Verilog 2001
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps
`default_nettype none


module xcl_addr 
#(
///////////////////////////////////////////////////////////////////////////
// Parameter Definitions
///////////////////////////////////////////////////////////////////////////
  parameter C_PI_OFFSET         = 0, // valid address, must be aligned to 
                                     // C_LINESIZE 
  parameter C_WRITEXFER         = 1, // 0,1,2
  parameter C_LINESIZE          = 4 // 1,4,8,16
)
(
///////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////
  input wire         Clk,
  input wire         Clk_MPMC,
  input wire         Rst,
  input wire         Clk_PI_Enable,
  output wire [31:0] PI_Addr,
  output reg         PI_AddrReq,
  input wire         PI_AddrAck,
  output wire        PI_RNW,
  output wire        PI_RdModWr,
  output wire [3:0]  PI_Size,
  input wire         PI_InitDone,
  input wire  [0:31] Access_Data,
  input wire         Access_Exists,
  input wire         Access_Control,
  output wire        Access_REN_Addr,
  output reg         Write_Start,
  output reg         Read_Start,
  input wire         Write_Done,
  input wire         Read_Done
);

  wire          start;
  wire          complete;
  wire          addr_request;
  reg           busy;
  reg           addrack_hold;
  wire          write_start_i;
  reg           addr_done;
  reg  [31:0]   pi_addr_hold;
  reg           pi_rnw_hold;
   
  //////////////////////////////////////////////////////////////////////////
  // MPMC NPI Interface Address Request logic
  //////////////////////////////////////////////////////////////////////////

  // Latch Addr/RNW for WRITEXFER == 2
  always @(posedge Clk)
    if (Rst)
      begin
        pi_addr_hold <= 32'b0;
        pi_rnw_hold <= 32'b0;
      end
    else if (start)
      begin
        pi_addr_hold <= Access_Data + C_PI_OFFSET;
        pi_rnw_hold <= ~Access_Control;
      end

  // set PI_RNW, PI_ADDR
  generate                 
    if (C_WRITEXFER == 0) begin : READONLY_ADDR
      assign PI_RNW = 1; 
      assign PI_Addr = Access_Data + C_PI_OFFSET;
    end
    else if (C_WRITEXFER == 1 || C_LINESIZE == 1) begin : WRITE_WORD_ADDR
      assign PI_RNW = ~Access_Control;
      assign PI_Addr = Access_Data + C_PI_OFFSET;
    end
    else begin : WRITE_FIRST_ADDR
      assign PI_RNW = pi_rnw_hold;
      assign PI_Addr = pi_addr_hold;
    end
  endgenerate

  // Size will be determined by the linesize if a read or writexfer of 2, 
  // otherwise size is 0 (word write)
  generate                 
    if (C_LINESIZE == 1) begin : LINESIZE_1
      assign PI_Size = 4'd0;
    end
    else if (C_LINESIZE == 4) begin : LINESIZE_4
      assign PI_Size = (PI_RNW | (C_WRITEXFER == 2)) ? 4'd1 : 4'd0;
    end
    else if (C_LINESIZE == 8) begin : LINESIZE_8
      assign PI_Size = (PI_RNW | (C_WRITEXFER == 2)) ? 4'd2 : 4'd0;
    end
    else begin : LINESIZE_16
      assign PI_Size = (PI_RNW | (C_WRITEXFER == 2)) ? 4'd3 : 4'd0;
    end
  endgenerate

  // This value tied to zero
  assign PI_RdModWr = 1'b1;

  // Register Request on Port Interface
  // AddrAck clears this bit last, to ensure back 2 back operation
  always @(posedge Clk_MPMC)
    if (Rst) 
      PI_AddrReq <= 0;
    else if (addr_request & Clk_PI_Enable)
      PI_AddrReq <= 1;
    else if (PI_AddrAck)
      PI_AddrReq <= 0;
 
  // Hold PI_AddrAck for slower clock frequencies
  always @(posedge Clk_MPMC)
    if (Rst) 
      addrack_hold <= 1'b0;
    else
      addrack_hold <= ~Clk_PI_Enable & (PI_AddrAck | addrack_hold);

  always @(posedge Clk)
    addr_done <= PI_AddrAck | addrack_hold;

  //////////////////////////////////////////////////////////////////////////
  // XCL Control Logic
  //////////////////////////////////////////////////////////////////////////

  // Start transaction when Request Exists on FSL, if C_WRITEXFER == 2, we
  // will will not start unless InitDone is high
  assign start = Access_Exists & ~busy & (PI_InitDone || C_WRITEXFER != 2);

  // Hold off other XCL transfers while busy
  always @(posedge Clk)
    if (Rst | complete) 
      busy <= 0;
    else if (start)
      busy <= 1;

  // When writing more than 1 data beat, to ensure a valid write push data
  // into the WrFIFO before the Address request.  For single data beat writes
  // we will push the data in after the Address Request.
  generate 
    if (C_WRITEXFER == 2 && C_LINESIZE > 1) begin : WRITE_FIRST

      // If it is a read, then start the address request first, 
      // if it is a write, then start the address request after writes are done
      assign addr_request = (~Access_Control & start) | Write_Done;

      // always start writes first
      assign write_start_i = start & Access_Control; 

      assign complete =  Read_Done | (addr_done & ~pi_rnw_hold);
                            
    end
    else begin : ADDRREQ_FIRST

      // Always addrreq first
      assign addr_request = start;
     
      // Start wrtes when AddrReq is done
      assign write_start_i = addr_done & ~PI_RNW;

      assign complete = Read_Done | Write_Done;

    end
  endgenerate
    

  // Output signals to the data modules/access_fifo
  always @(posedge Clk)
    Write_Start <= write_start_i;
   
  // Tell the read module to expect data
  always @(posedge Clk)
    Read_Start <= addr_done & PI_RNW;

  // Pop values out of the FIFO when we start a write or read 
  assign Access_REN_Addr = Read_Start | write_start_i;


endmodule // xcl_addr

`default_nettype wire
