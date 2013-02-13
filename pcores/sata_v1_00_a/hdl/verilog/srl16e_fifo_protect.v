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
//-----------------------------------------------
//
// MODULE:  srl16e_fifo_protect
//
// This is the simplest form of inferring the
// SRL16E/SRL16CE in a Xilinx FPGA.
//
// This version checks the status of FULL/EMPTY
// in order to prevent OVERRUN status.
//
//-----------------------------------------------
`timescale 1ns / 100ps
module srl16e_fifo_protect
 #(parameter
    c_width  = 8,
    c_awidth = 4,
    c_depth  = 16
  )
  (
    input                Clk,       // Main System Clock  (Sync FIFO)
    input                Rst,     // FIFO Counter Reset (Clk
    input                WR_EN,     // FIFO Write Enable  (Clk)
    input                RD_EN,     // FIFO Read Enable   (Clk)
    input  [c_width-1:0] DIN,       // FIFO Data Input    (Clk)
    output [c_width-1:0] DOUT,      // FIFO Data Output   (Clk)
    output               ALMOST_FULL,
    output               FULL,      // FIFO FULL Status   (Clk)
    output               ALMOST_EMPTY,
    output               EMPTY      // FIFO EMPTY Status  (Clk)
  );

///////////////////////////////////////
// FIFO Local Parameters
///////////////////////////////////////
localparam [c_awidth-1:0] c_empty     = ~(0);
localparam [c_awidth-1:0] c_empty_pre =  (0);
localparam [c_awidth-1:0] c_empty_pre1=  (1);
localparam [c_awidth-1:0] c_full      = c_empty-1;
localparam [c_awidth-1:0] c_full_pre  = c_full-1;
localparam [c_awidth-1:0] c_full_pre1 = c_full-2;

///////////////////////////////////////
// FIFO Internal Signals
///////////////////////////////////////
reg  [c_width-1:0] memory [c_depth-1:0];
reg [c_awidth-1:0] cnt_read;

///////////////////////////////////////
// Main SRL16E FIFO Array
///////////////////////////////////////
always @(posedge Clk) begin : blkSRL
integer i;
  if (WR_EN) begin
    for (i = 0; i < c_depth-1; i = i + 1) begin
      memory[i+1] <= memory[i];
    end
    memory[0] <= DIN;
  end
end

///////////////////////////////////////
// Read Index Counter
// Up/Down Counter
///////////////////////////////////////
always @(posedge Clk) begin
  if (Rst) cnt_read <= c_empty;
  else if ( WR_EN & !RD_EN & !FULL)  cnt_read <= cnt_read + 1;
  else if (!WR_EN &  RD_EN & !EMPTY) cnt_read <= cnt_read - 1;
end

///////////////////////////////////////
// Status Flags / Outputs
// These could be registered, but would
// increase logic in order to pre-decode
// FULL/EMPTY status.
///////////////////////////////////////
assign FULL  = (cnt_read == c_full);
assign EMPTY = (cnt_read == c_empty);
assign ALMOST_FULL  = (cnt_read == c_full_pre  || c_full_pre1  == cnt_read);
assign ALMOST_EMPTY = (cnt_read == c_empty_pre || c_empty_pre1 == cnt_read);
assign DOUT  = (c_depth == 1) ? memory[0] : memory[cnt_read];

endmodule // srl16e_fifo_protect


