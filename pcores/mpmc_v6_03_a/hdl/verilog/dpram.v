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
// Description: 
//      This will infer a variable width/depth asynchronous dual port ram out of
//      RAM16X1D.  This is the simplest form of inferring the RAM16X1D in a 
//      Xilinx FPGA.
//
// Verilog-standard:  Verilog 2001
//-----------------------------------------------
`timescale 1ns / 100ps
`default_nettype none
module dpram
#(
  parameter                     C_WIDTH  = 8,
  parameter                     C_AWIDTH = 4,
  parameter                     C_DEPTH  = 1 << C_AWIDTH 
)
(
  input  wire                   Clk,        // Main System Clock  (Sync FIFO)
  input  wire                   WE,         // Write Enable  (Clk)
  input  wire [C_AWIDTH-1:0]    A,          // SPO/DI Address (Clk)
  input  wire [C_AWIDTH-1:0]    DPRA,       // DPO Address (aysnc)
  input  wire [C_WIDTH-1:0]     DI,         // Data In
  output wire [C_WIDTH-1:0]     SPO,        // Single Port Out (Clk)
  output wire [C_WIDTH-1:0]     DPO         // Dual Port Out (async)
  );

///////////////////////////////////////
// Internal Memory
///////////////////////////////////////
  reg  [C_WIDTH-1:0] memory [C_DEPTH-1:0];

  always @(posedge Clk)
    if (WE)
      memory[A] <= DI;      

  assign SPO = memory[A];     // Synchronous Read Output
  assign DPO = memory[DPRA];  // Asynchronous Read Output


endmodule // srl16e_fifo

`default_nettype wire
