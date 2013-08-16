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

`timescale 1ns/1ps

//-----------------------------------------------------------------------------
// Module name:      static_phy_control
// Description:      Status/Control registers for the Static PHY
//                   1 Control Register set by mpmc_ctrl_if module
//                        B.E     L.E.
//                   bits [0:3]   [31:28] sets rden_delay
//                   bit  [4]     [27]    sets rddata_clk_sel
//                   bit  [5]     [26]    sets rddata_swap_rise
//                   bit  [6]     [25]    is unused
//                   bit  [7]     [24]    is 0 during first reset and 1 afterwards.
//                                        It prevents control reg from being set to
//                                        default vals after initial reset. (Read Only)
//                   bit  [8]     [23]    is DCM En (Self Clearing)
//                   bit  [9]     [22]    is DCM IncDec
//                   bit  [10]    [21]    is DCM Done (Needs to be cleared by software)
//                   bit  [11]    [20]    is the Initialization Done signal (Read Only)
//                   bits [12:15] [19:16] are unused
//                   bits [16:31] [15:0]  are the dcm tap value (Read Only)
// Verilog-standard: Verilog 2001
//-----------------------------------------------------------------------------
module static_phy_control #
  (
   parameter         C_RDDATA_CLK_SEL           = 1'b1,
   parameter         C_RDEN_DELAY               = 4'b0,
   parameter         C_RDDATA_SWAP_RISE         = 1'b0,
   parameter         C_NUM_REG                  = 1'b0
   )
  (
   ////////////////////
   // Global Signals //
   ////////////////////
   input  wire                     Clk,
   input  wire                     Rst,

   //////////////////////
   // mpmc_ctrl_if I/O //
   //////////////////////
   input  wire [C_NUM_REG-1:0]     Reg_CE,
   input  wire [31:0]              Reg_In,
   output wire [C_NUM_REG*32-1:0]  Reg_Out,

   //////////////////////////////////////////////////
   // Static Phy Control Interface related signals //
   //////////////////////////////////////////////////
   input  wire                     phy_init_done,
   output reg  [3:0]               rden_delay,
   output reg                      rddata_clk_sel,
   output reg                      rddata_swap_rise,
   output reg                      dcm_en,
   output reg                      dcm_incdec,
   input  wire                     dcm_done
   );

   reg [10:0] dcm_tap_value = 0;
   reg        dcm_done_o = 0;
   reg        phy_init_done_o = 0;

   reg        rst_found = 0;
   reg        rst_found_set = 0;
   reg        rst_d1 = 0;
   reg        rst_ctrl_reg = 0;


   // Reset Logic and status
   always @(posedge Clk)
      rst_d1 <= Rst;

   always @(posedge Clk)
      rst_ctrl_reg <= Rst & ~rst_found;

   always @(posedge Clk)
      rst_found_set <= rst_d1 & ~Rst;

   always @(posedge Clk)
     rst_found <= ~rst_ctrl_reg & (rst_found_set | rst_found);

   // rden_delay register
   always @(posedge Clk)
      if (rst_ctrl_reg)
         rden_delay <= C_RDEN_DELAY;
      else if (Reg_CE[0])
         rden_delay <= Reg_In[31:28];

   // rddata_clk_sel register
   always @(posedge Clk)
      if (rst_ctrl_reg)
         rddata_clk_sel <= C_RDDATA_CLK_SEL;
      else if (Reg_CE[0])
         rddata_clk_sel <= Reg_In[27];

   // rddata_clk_sel register
   always @(posedge Clk)
      if (rst_ctrl_reg)
         rddata_swap_rise <= C_RDDATA_SWAP_RISE;
      else if (Reg_CE[0])
         rddata_swap_rise <= Reg_In[26];

   // DCM En Register
   always @(posedge Clk)
      if (Rst)
         dcm_en <= 1'b0;
      else if (Reg_CE[0])
         dcm_en <= Reg_In[23];
      else
         dcm_en <= 1'b0;

   // DCM Inc Dec Register
   always @(posedge Clk)
      if (Rst)
         dcm_incdec <= 1'b0;
      else if (Reg_CE[0])
         dcm_incdec <= Reg_In[22];

   // DCM Done register
   always @(posedge Clk)
      if (Rst)
         dcm_done_o <= 1'b0;
      else if (dcm_done)
         dcm_done_o <= 1'b1;
      else if (Reg_CE[0])
         dcm_done_o <= Reg_In[21];

   // Phy Init Done Status Reg
   always @(posedge Clk)
      phy_init_done_o <= phy_init_done;

   // Calcualte DCM tap value
   always @(posedge Clk) begin
      if (rst_ctrl_reg) begin
         dcm_tap_value <= 11'h000;
      end else if (dcm_en & dcm_incdec) begin
         dcm_tap_value <= dcm_tap_value + 1'b1;
      end else if (dcm_en & ~dcm_incdec) begin
         dcm_tap_value <= dcm_tap_value - 1'b1;
      end
    end

   wire [15:0] dcm_tap_value_extended = {{6{dcm_tap_value[10]}}, dcm_tap_value[9:0]};

   assign Reg_Out = {rden_delay, rddata_clk_sel, rddata_swap_rise ,1'b0,
                     rst_found,dcm_en,dcm_incdec,dcm_done_o,phy_init_done_o,
                     4'b0,dcm_tap_value_extended};

endmodule // static_phy_control
