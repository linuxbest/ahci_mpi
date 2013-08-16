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
// Description: Pop signal generator based on the Empty signal that is
// friendly to timing.  This module takes the Empty signal from the NPI
// RdFIFO_Empty and creates the necessary RdFIFO_Pop signal to retrieve the
// data as soon as possible.  The Empty signal is registered and the Pop
// signal is generator based on the size of thre transaction and the memory
// width by predicting the Empty flag toggling.  This results in the least
// amount of loading on the Empty signal to ensure higher attainable
// frequencies.
// Verilog-standard:  Verilog 2001
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps
`default_nettype none

module pop_generator
#(
  parameter C_PI_DATA_WIDTH             = 32,
  parameter C_LINESIZE                  = 4,
  parameter C_MEM_SDR_DATA_WIDTH        = 8,
  parameter C_CNT_WIDTH                 = 1
)
(
  input  wire                           Clk_MPMC,
  input  wire                           Rst,
  input  wire                           Empty,
  input  wire                           Clk_PI_Enable,
  output wire                           Pop
);

  localparam integer P_PI2MEM_DATA_RATIO = (C_PI_DATA_WIDTH > C_MEM_SDR_DATA_WIDTH)
                                          ? C_PI_DATA_WIDTH/C_MEM_SDR_DATA_WIDTH
                                          : 1;

  localparam integer P_POP_COUNT    = (C_LINESIZE == 1)       ? 1 : 
                                     (C_PI_DATA_WIDTH == 64) ? C_LINESIZE/2 :
                                                               C_LINESIZE;
                                            

  reg                           empty_d1;
  reg                           empty_d2;
  reg                           pop_d1;
  reg                           clk_pi_enable_d1;
  wire                          pop_start;
  wire                          pop_stop;
  reg  [C_CNT_WIDTH-1:0]        count;
  reg  [2:0]                    empty_cntr;
  reg                           pop_ready;
  reg                           pop_start_mask;
  wire                          pop_i;

  always @(posedge Clk_MPMC)
    begin
      empty_d1 <= Empty;
      empty_d2 <= empty_d1;
      pop_d1   <= Pop;
      clk_pi_enable_d1 <= Clk_PI_Enable;
    end

  // start popping if we detect an edge on empty and we have not just popped
  assign pop_start = ~empty_d1 & empty_d2 & ~pop_d1 & ~pop_start_mask;

  always @(posedge Clk_MPMC)
    if (Rst)
      pop_start_mask <= 1'b0;
    else 
      pop_start_mask <= pop_start | pop_start_mask;

  // stop popping when count == our linesize -1 and we issue a pop 
  assign pop_stop = (count[0 +: C_CNT_WIDTH] == C_LINESIZE - 1) & Pop;

  // In cacheline transfers, wr_adr is controlled by RdWdAddr, in bursts 
  // we use a counter
  always @(posedge Clk_MPMC)
    if (Rst)
      count <= {C_CNT_WIDTH{1'b0}};
    else if (Pop)
      count <= count + 1'b1;

  // This counter is used to emulate the empty flag for small memories, we
  // start at an offset of 2 to compensate for the empty pipeline.  We start
  // at an offset of one to align with the Clk_PI_Enable signal if necessary.
  always @(posedge Clk_MPMC)
    if (pop_start)
      empty_cntr <= clk_pi_enable_d1 ? 3'd2 : 3'd1;
    else
      empty_cntr <= empty_cntr + 1'b1;

  // indicates we are to start popping data out of the fifo 
  always @(posedge Clk_MPMC) 
    if (Rst)
      pop_ready <= 1'b0;
    else
      pop_ready <= ~pop_stop & (pop_start | pop_ready);

  // these generates evaluate the counter and issue pop signals
  // accordingly, this models what the empty flags would look like w/ the
  // timing implications of evaluating the empty signal directly
  generate
    if (P_PI2MEM_DATA_RATIO == 8) 
      begin : gen_pop_eighth_rate
        assign pop_i =  pop_start | (pop_ready & (empty_cntr[2:0] == 0));
      end
    else if (P_PI2MEM_DATA_RATIO == 4) 
      begin : gen_pop_quarter_rate
        assign pop_i =  pop_start | (pop_ready & (empty_cntr[1:0] == 0));
      end
    else if (P_PI2MEM_DATA_RATIO == 2) 
      begin : gen_pop_half_rate
        assign pop_i =  pop_start | (pop_ready & ~empty_cntr[0]);
    end
    else begin : gen_pop_full_rate // Half rate if we are in a 2:1 clk ratio
      assign pop_i = (pop_start | pop_ready);
    end
  endgenerate

  assign Pop = pop_i & Clk_PI_Enable;
  
endmodule // pop_generator

`default_nettype wire
