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
// mpmc_sample_cycle.v - Clock Ratio and Phase detection Logic
//-------------------------------------------------------------------------
// Filename:          mpmc_sample_cycle.v
// Description:
//       This sample cycle generator counts the number of clock edges
//       of the fast_clk in two slow_clk cycles and uses half of that as
//       the slow_clk/fast_clk ratio to generate the slow_clk sample cycle
//       signal in the next two slow_clk cycles. This scheme is used mainly to
//       provide a robust mechanism to accomocate for a 1:1 ratio between
//       slow_clk and fast_clks. The sample cycle signal is aligned to the
//       rising edge of the fast clock and is asserted for 1 fast_clk in the
//       cycle prior to the rising edge of slow_clk.            
//
// Verilog-standard:  Verilog 2001
//-------------------------------------------------------------------------
// Author:      KD
// History:
//  KD        01/10/2007      - Initial Version
//  JL        02/23/2007      - Added option to replicate output.
//
//-------------------------------------------------------------------------

`timescale 1ns/1ns

module mpmc_sample_cycle (
  sample_cycle,
  fast_clk, 
  slow_clk
  );

  parameter C_OUTPUT_WIDTH = 1;
   
  output [C_OUTPUT_WIDTH-1:0] sample_cycle;
  input                       fast_clk;
  input                       slow_clk;

  wire                      clear_count;
  wire                      clear_count_p1;
  reg  [0:4]                new_count;
  reg  [0:4]                count;
  reg  [0:4]                ratio;
  reg  [0:4]                ratio_minus1;
  reg                       slow_clk_div2 = 0; // slow_clk_div2 = half freq. of slow_clk Clock
  reg                       slow_clk_div2_del;
  reg  [C_OUTPUT_WIDTH-1:0] sample_cycle;
  // synthesis attribute equivalent_register_removal of sample_cycle is "no"
  reg                       clk_1_to_1;
   
  always @(posedge slow_clk )
    #1 slow_clk_div2 <= ~slow_clk_div2; // #1 is for simulation, build a toggle FF in
                                        // slow_clk. This creates a half frequency signal.

  always @(posedge fast_clk)
    slow_clk_div2_del <= slow_clk_div2; // align slow clocked toggle signal into fast clk.

  // Detect the rising edge of the slow_clk_div2 to clear the slow_clk sample counter.
  assign clear_count = slow_clk_div2 & ~slow_clk_div2_del;

  always @(posedge fast_clk)
    if (clear_count) count <= 5'b00000;
    else count <= count + 1;
 
  always @(posedge fast_clk)
    if (clear_count) ratio <= count;

  // Create a new counter that runs earlier than above counter.
  // This counter runs ahead to find the cycle just before
  // the slow clock's rising edge transitions

  always @(posedge fast_clk)
    ratio_minus1 <= (ratio - 1);

  assign clear_count_p1 = (count[0:4] == ratio_minus1);

  always @(posedge fast_clk)
    if (clear_count_p1)
      new_count <= 5'b00001;
    else       
      new_count <= new_count + 1'b1 ;

  always @(posedge fast_clk)
    clk_1_to_1 <= (ratio[0:3] == 4'b0000);

  // Generate sample_cycle signal and drive from the output of a FF for better timing.
  // implement sample_cycle as a Flip Flop with Set input

  genvar i;
  generate
     for (i=0;i<C_OUTPUT_WIDTH;i=i+1)
       begin : gen_sample_cycle
          always @(posedge fast_clk)
            if (clk_1_to_1) sample_cycle[i] <= 1'b1;                       // 1:1 slow_clk/fast_clk ratios
            else sample_cycle[i] <= ((new_count == {ratio[0:3], 1'b1}) ||  // Second slow_clk cycle in the pair
                                  (new_count == {1'b0, ratio[0:3]}));   // First slow_clk cycle in the pair
       end
  endgenerate
endmodule
