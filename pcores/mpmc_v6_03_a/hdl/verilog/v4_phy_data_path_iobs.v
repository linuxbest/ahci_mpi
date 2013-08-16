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

module v4_phy_data_path_iobs#
  (
   parameter integer DQSN_ENABLE       = 1,
   parameter integer DDR2_ENABLE       = 1,
   parameter integer data_width        = 64,
   parameter integer data_strobe_width = 8,
   parameter integer data_mask_width   = 8
   )
  (
   input                           CLK,
   input                           CLK90,
   input                           RESET0,
   input [data_width-1:0]          data_idelay_inc,
   input [data_width-1:0]          data_idelay_ce,
   input [data_width-1:0]          data_idelay_rst,
   input [data_width-1:0]          delay_enable,   
   input                           dqs_rst,
   input                           dqs_en,
   input [data_width-1:0]          wr_data_rise,
   input [data_width-1:0]          wr_data_fall,
   input [1:0]                     wr_en,
   output [data_width-1:0]         rd_data_rise,
   output [data_width-1:0]         rd_data_fall,
   input [data_mask_width-1:0]     mask_data_rise,
   input [data_mask_width-1:0]     mask_data_fall,
   
   inout [data_width-1:0]          DDR_DQ,
   inout [data_strobe_width-1:0]   DDR_DQS,
   inout [data_strobe_width-1:0]   DDR_DQS_L,
   output [data_mask_width-1:0]    DDR_DM
   )/* synthesis syn_preserve=1 */;
  
  genvar i;

  /////////////////////////////////////////////////////////////////////////////
  // DQS instances
  /////////////////////////////////////////////////////////////////////////////

  generate
    for (i=0;i<data_strobe_width;i=i+1)
      begin : gen_v4_phy_dqs_iob
        v4_phy_dqs_iob  
          #(
            .DQSN_ENABLE       (DQSN_ENABLE),
            .DDR2_ENABLE       (DDR2_ENABLE)
            )
            v4_dqs_iob
              (
               .CLK              (CLK),
               .RESET            (RESET0),
               .CTRL_DQS_RST     (dqs_rst),
               .CTRL_DQS_EN      (dqs_en),
               .DDR_DQS          (DDR_DQS[i]),
               .DDR_DQS_L        (DDR_DQS_L[i])
               );
      end
  endgenerate
  
  /////////////////////////////////////////////////////////////////////////////
  // DM instances
  /////////////////////////////////////////////////////////////////////////////

  generate
    for (i=0;i<data_mask_width;i=i+1)
      begin : gen_v4_phy_dm_iob
        v4_phy_dm_iob v4_dm_iob
          (
           .CLK90            (CLK90),
           .MASK_DATA_RISE   (mask_data_rise[i]),
           .MASK_DATA_FALL   (mask_data_fall[i]),
           .DDR_DM           (DDR_DM[i])
           );
      end
  endgenerate

  /////////////////////////////////////////////////////////////////////////////
  // DQ_IOB4 instances
  /////////////////////////////////////////////////////////////////////////////

  generate
    for (i=0;i<data_width;i=i+1)
      begin : gen_v4_phy_dq_iob
        v4_phy_dq_iob v4_dq_iob
          (
           .CLK              (CLK),
           .CLK90            (CLK90),
	   .RESET0           (RESET0),
           .DATA_DLYINC      (data_idelay_inc[i]),
           .DATA_DLYCE       (data_idelay_ce[i]),
           .DATA_DLYRST      (data_idelay_rst[i]),
           .WRITE_DATA_RISE  (wr_data_rise[i]),
           .WRITE_DATA_FALL  (wr_data_fall[i]),
           .CTRL_WREN        (wr_en),
           .DELAY_ENABLE     (delay_enable[i]),
           .DDR_DQ           (DDR_DQ[i]),
           .RD_DATA_RISE     (rd_data_rise[i]),
           .RD_DATA_FALL     (rd_data_fall[i])
           );
      end
  endgenerate
  
endmodule
