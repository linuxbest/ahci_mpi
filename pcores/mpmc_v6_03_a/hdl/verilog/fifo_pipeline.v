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
//Purpose:
//    Synchronous, shallow FIFO that uses SRL16E as a DP Memory.
//    This requires about 1/2 the resources as a Distributed RAM DPRAM 
//    implementation.
//
//    This FIFO will have the current data on the output when data is contained
//    in the FIFO.  When the FIFO is empty, the output data is invalid.
//
//Reference:
//Revision History:
//
///////////////////////////////////////////////////////////////////////////
// Module: fifo_pipeline --
// This is a "smart" pipeline register output to the FIFO it will load 
// register whenever data exists in the fifo the data is popped.  The 
// result is that this register will look like the output of the SRL
// FIFO but without the associated timing delays while maintaining the
// same signal relationship between "exist", "ren", and "data/control".
///////////////////////////////////////////////////////////////////////////
`timescale 1ns / 100ps
module fifo_pipeline
  #(
    parameter C_DWIDTH = 1,       //  Allowed values: 1+
    parameter C_INV_EXISTS = 0    //  Allowed values: 0,1
  )
  (
    // system signals
    input  wire                 Clk,
    input  wire                 Rst,
    // FIFO side signals
    input  wire                 FIFO_Exists, // Exists or Empty
    output wire                 FIFO_Read,   // Read is Pop
    input  wire [C_DWIDTH-1:0]  FIFO_Data,
    // Pipelined signals
    output wire                 PIPE_Exists,
    input  wire                 PIPE_Read,
    output reg  [C_DWIDTH-1:0]  PIPE_Data = {C_DWIDTH{1'b0}}
  );
  
  wire                          fifo_exists_i;
  reg                           fifo_exists_d1;
  wire                          fifo_exists_rising_edge;
  wire                          fifo_read_cond_1;
  wire                          fifo_read_cond_2;
  reg                           pipe_exists_i;

  // Exists is really an empty signal in this case
  generate
    if (C_INV_EXISTS) begin : FIFO_EMPTY
      assign fifo_exists_i = ~FIFO_Exists;
      assign PIPE_Exists   = ~pipe_exists_i;
    end
    else begin : FIFO_EXISTS
      assign fifo_exists_i = FIFO_Exists;
      assign PIPE_Exists   = pipe_exists_i;
    end
  endgenerate

  // Exists signal is a S/R latch w/ rst
  always @(posedge Clk)
    if (Rst)
      pipe_exists_i <= 1'b0;
    else
      pipe_exists_i <= fifo_exists_i | (~PIPE_Read & pipe_exists_i);

  // Rising edge detector for FIFO_Exists
  always @(posedge Clk)
    fifo_exists_d1 <= fifo_exists_i;

  assign fifo_exists_rising_edge = fifo_exists_i & ~fifo_exists_d1;

  // Condition 1 to Read the FIFO our pipe is empty and the fifo is not
  assign fifo_read_cond_1 = ~pipe_exists_i & fifo_exists_rising_edge;

  // condition 2 to read the FIFO is if a READ is issued and we have more data
  // in the fifo
  assign fifo_read_cond_2 = PIPE_Read & fifo_exists_i;

  // Or the two conditions
  assign FIFO_Read = fifo_read_cond_1 | fifo_read_cond_2;

  // Data pipeline register, we advance every time a read is performed
  always @(posedge Clk)
    if (FIFO_Read)
      PIPE_Data <= FIFO_Data;

    

endmodule // fifo_pipeline
