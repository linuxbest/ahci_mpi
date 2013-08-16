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

module v4_phy_write #
  (
   parameter integer WDF_RDEN_EARLY  = 0,
   parameter integer WDF_RDEN_WIDTH  = 1,
   parameter integer DDR2_ENABLE     = 1,
   parameter integer ODT_WIDTH       = 1,
   parameter integer ODT_TYPE        = 1,
   parameter integer dq_width        = 64,
   parameter integer dm_width        = 8
   )
  (
   input                           CLK,
   input                           CLK90,
   input                           RESET90,
   input [dq_width-1:0]            WDF_DATA_RISE,
   input [dq_width-1:0]            WDF_DATA_FALL,
   input [dm_width-1:0]            MASK_DATA_RISE,
   input [dm_width-1:0]            MASK_DATA_FALL,
   input                           CTRL_ODT,
   input                           CTRL_WREN,
   input                           CTRL_DQS_RST,
   input                           CTRL_DQS_EN,
   output [ODT_WIDTH-1:0]          odt,
   output                          dqs_rst,
   output                          dqs_en,
   output reg [WDF_RDEN_WIDTH-1:0] wr_en,
   output [dq_width-1:0]           wr_data_rise,
   output [dq_width-1:0]           wr_data_fall,
   output [dm_width-1:0]           wr_mask_data_rise,
   output [dm_width-1:0]           wr_mask_data_fall
   ) /* synthesis syn_preserve=1 */;
  
  // synthesis attribute equivalent_register_removal of wr_en is "no"
  reg                              dqs_rst_r1;
  reg                              dqs_rst_r2;
  reg                              dqs_rst_r3;
  
  reg                              dqs_en_r1;
  reg                              dqs_en_r2;
  reg                              dqs_en_r3 /* synthesis syn_maxfan = 5 */;
  reg                              dqs_en_r4;
  
  reg                              odt_d1;
  reg                              odt_d2;
  reg                              odt_d3;
  
  reg                              RESET90_r1;

  generate
    if (DDR2_ENABLE) begin: gen_odt_ddr2
      assign dqs_rst = dqs_rst_r3;
      assign dqs_en  = dqs_en_r4;
      if (WDF_RDEN_EARLY) begin: gen_wr_en_noreg
        always @(*) begin
          wr_en <= {WDF_RDEN_WIDTH{CTRL_WREN}};
        end
      end
      else begin: gen_wr_en_reg          
        always @(posedge CLK) begin
          wr_en <= {WDF_RDEN_WIDTH{CTRL_WREN}};
        end
      end
      assign odt = {ODT_WIDTH{ (ODT_TYPE != 0) ? 
                               (odt_d1 | odt_d2) : 
                               1'b0}};
    end else begin: gen_odt_ddr1
      assign dqs_rst = dqs_rst_r3;
      assign dqs_en  = dqs_en_r3;
      if (WDF_RDEN_EARLY) begin: gen_wr_en_noreg
        always @(*) begin
          wr_en <= {WDF_RDEN_WIDTH{CTRL_WREN}};
        end
      end
      else begin: gen_wr_en_reg          
        always @(posedge CLK) begin
          wr_en <= {WDF_RDEN_WIDTH{CTRL_WREN}};
        end
      end
      assign odt = {ODT_WIDTH{1'b0}};
    end
  endgenerate

  always @( posedge CLK90 )
    RESET90_r1 <= RESET90;
  
  always @( posedge CLK ) begin
    odt_d1 <= CTRL_ODT;
    odt_d2 <= odt_d1;
    odt_d3 <= odt_d2;
  end
  
  always @ (negedge CLK90) begin
    dqs_rst_r1             <= CTRL_DQS_RST;
    dqs_en_r1              <= ~CTRL_DQS_EN;
  end
  
  // synthesis attribute max_fanout of dqs_en_r3 is 5
  always @ (negedge CLK) begin
    dqs_rst_r2  <= DDR2_ENABLE ? dqs_rst_r1 : CTRL_DQS_RST;
    dqs_rst_r3  <= dqs_rst_r2;
    dqs_en_r2   <= dqs_en_r1;
    dqs_en_r3   <= dqs_en_r2;
    dqs_en_r4   <= dqs_en_r3;
  end

  assign wr_data_fall =  WDF_DATA_FALL;
  assign wr_data_rise =  WDF_DATA_RISE;
  
  assign wr_mask_data_fall = MASK_DATA_FALL;
  assign wr_mask_data_rise = MASK_DATA_RISE;

endmodule
