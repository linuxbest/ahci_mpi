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
//
// mpmc_pm - MPMC Performance Monitor - Module
//-------------------------------------------------------------------------
// Filename:     mpmc_pm.v
// Description:  This module is a MPMC Performance Monitor
//
//-------------------------------------------------------------------------
// Author:      CJC
// History:
//  CJC       05/15/2006      - Initial Release
//  CJC       05/25/2006      - Fixed the timers so they don't wrap > 255
//  CJC       06/09/2006      - Implemented C_SHIFT_BY
//-------------------------------------------------------------------------

// Design Notes:
//    The start/stop signals support independent read/write signals as well as the allowal of 
//    overlapping transactions.  You can have as many overlapping transactions as defined by 
//    the C_WR_TIMER and C_RD_TIMER parameters for write transactions and read transactions,
//    respectively.
`timescale 1ns / 1ns
`default_nettype none


/* This module times the start and stop signals that arrive from the port interfaces.  It contains
   an array of counters defined by C_FIFO_AWIDTH/DEPTH to allow overlapping transactions to be 
   measured.   When a start signal arrives a set of shift registers is rotated to create a pulse
   which will reset one of the counters so that it will start counting.  When a stop signal is 
   received, the first counter is read, and the pointer is then incremented to the next counter. */
module mpmc_pm_timer 
(
  Clk,
  Rst,
  start,
  stop,
  qualifier,
  bram_address,
  wr_en
);
  parameter         C_FIFO_AWIDTH = 1;
  parameter         C_FIFO_DEPTH = 2;
  parameter         C_CNT_AWIDTH  = 8;
  parameter         C_CNT_DEPTH  = 256;
  parameter         C_SHIFT_BY  = 1;

  input             Clk;
  input             Rst;
  input             start;
  input             stop;
  input     [3:0]   qualifier;
  output    [8:0]   bram_address;
  output            wr_en;

  wire              Clk;
  wire              Rst;
  wire              start;
  wire              stop;
  wire      [3:0]   qualifier;
  reg       [8:0]   bram_address;
  reg               wr_en;

  reg       [C_FIFO_DEPTH-1:0]  timer_res_ff;
  reg       [C_FIFO_DEPTH-1:0]  timer_res_ff_d1;
  wire      [C_FIFO_DEPTH-1:0]  timer_res;
  reg       [(C_CNT_AWIDTH*C_FIFO_DEPTH)-1:0]  timer_count_out;
  wire      [C_CNT_AWIDTH-1:0]   timer_count_value; 
  reg       [C_FIFO_AWIDTH-1:0]  timer_read_ptr;

  genvar    i;

  // shift register is rotated to create a pulse which resets a counter
  always @ (posedge Clk)
    if (Rst)
      begin
        timer_res_ff[C_FIFO_DEPTH-1] <= 1'b1; 
        timer_res_ff[C_FIFO_DEPTH-2:0] <= 0; 
      end
    else if (start)
      begin
        timer_res_ff <= {timer_res_ff[C_FIFO_DEPTH-2:0], timer_res_ff[C_FIFO_DEPTH-1]};
      end
    else
      begin
        timer_res_ff <= timer_res_ff;
      end

  // these flops are used in the edge detector for creating the pulse
  always @ (posedge Clk)
    if (Rst)
      begin
        timer_res_ff_d1[C_FIFO_DEPTH-1] <= 1'b1; 
        timer_res_ff_d1[C_FIFO_DEPTH-2:0] <= 0; 
      end
    else 
      begin
          timer_res_ff_d1 <= timer_res_ff;
      end

  // logic to create a pulse necessary to reset the counter
  assign timer_res = (timer_res_ff & (~timer_res_ff_d1));

  // generate our counters
  generate
    for (i=0; i < C_FIFO_DEPTH; i=i+1)
      begin : timer_inst 
        always @(posedge Clk)
            if (Rst||timer_res[i])
                timer_count_out[((i+1)*C_CNT_AWIDTH)-1:i*C_CNT_AWIDTH] = {C_CNT_AWIDTH{1'b0}}+3;
            else if (timer_count_out[((i+1)*C_CNT_AWIDTH)-1:i*C_CNT_AWIDTH] < {(C_SHIFT_BY+5){1'b1}})
                timer_count_out[((i+1)*C_CNT_AWIDTH)-1:i*C_CNT_AWIDTH] = timer_count_out[((i+1)*C_CNT_AWIDTH)-1:i*C_CNT_AWIDTH] + 1;
            else  // no change
                timer_count_out[((i+1)*C_CNT_AWIDTH)-1:i*C_CNT_AWIDTH] = timer_count_out[((i+1)*C_CNT_AWIDTH)-1:i*C_CNT_AWIDTH];
                
      end
  endgenerate

  // This counter controls which timer output we pick from the mux, it increments after the
  // last data item has finished and the transaction has been designated as finished.
  always @ (posedge Clk)
    if (Rst)
        timer_read_ptr <= 0;
    else if (stop)
        timer_read_ptr <= timer_read_ptr + 1;
    else
        timer_read_ptr <= timer_read_ptr;
        

  // This mux selects the output counter we want to capture
    assign timer_count_value = (timer_count_out >> timer_read_ptr*C_CNT_AWIDTH);

  // create wr_en from the stop
  always @(posedge Clk)
      if (Rst) wr_en <= 0;
      else     wr_en <= stop;
   

  // create the bram address from the wr_en
  always @(posedge Clk)
    begin
      if (Rst)
        bram_address <= 0;
      else if ( stop )
        bram_address <= {qualifier, timer_count_value[C_SHIFT_BY+4:C_SHIFT_BY]};
      else
        bram_address <= bram_address;
    end

endmodule

`default_nettype wire
