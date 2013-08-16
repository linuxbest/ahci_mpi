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

module v4_phy_iobs #
  (
   parameter integer DQSN_ENABLE       = 1,
   parameter integer DDR2_ENABLE       = 1,
   parameter integer clk_width         = 1,
   parameter integer data_strobe_width = 8,
   parameter integer data_width        = 64,
   parameter integer data_mask_width   = 8,
   parameter integer row_address       = 14,
   parameter integer bank_address      = 3,
   parameter integer cs_width          = 1,
   parameter integer cke_width         = 1,
   parameter integer odt_width         = 1
   )   
  (
   input                           CLK,
   input                           CLK90,
   input                           RESET0,
   output [clk_width-1:0]          DDR_CK,
   output [clk_width-1:0]          DDR_CK_N,

   input [data_width-1:0]          data_idelay_inc,
   input [data_width-1:0]          data_idelay_ce,
   input [data_width-1:0]          data_idelay_rst,
   input [data_width-1:0]          delay_enable,

   input                           dqs_rst,
   input                           dqs_en,
   input [1:0]                     wr_en,
   input [data_width-1:0]          wr_data_rise,
   input [data_width-1:0]          wr_data_fall,
   input [data_mask_width-1:0]     mask_data_rise,
   input [data_mask_width-1:0]     mask_data_fall,
   inout [data_width-1:0]          DDR_DQ,
   inout [data_strobe_width-1:0]   DDR_DQS,
   inout [data_strobe_width-1:0]   DDR_DQS_L,
   output [data_mask_width-1:0]    DDR_DM,
   output [data_width-1:0]         rd_data_rise,
   output [data_width-1:0]         rd_data_fall,
   output [data_strobe_width-1:0]  dqs_delayed,

   input [row_address-1  :0]       ctrl_ddr2_address,
   input [bank_address-1 :0]       ctrl_ddr2_ba,
   input                           ctrl_ddr2_ras_L,
   input                           ctrl_ddr2_cas_L,
   input                           ctrl_ddr2_we_L,
   input [cs_width-1:0]            ctrl_ddr2_cs_L,
   input [cke_width-1:0]           ctrl_ddr2_cke,
   input [odt_width-1:0]           ctrl_ddr2_odt,

   output [row_address-1  :0]      DDR_ADDRESS,
   output [bank_address-1 :0]      DDR_BA,
   output                          DDR_RAS_L,
   output                          DDR_CAS_L,
   output                          DDR_WE_L,
   output [cke_width-1:0]          DDR_CKE,
   output [odt_width-1:0]          DDR_ODT,
   output [cs_width-1:0]           ddr_cs_L
   );

  //***************************************************************************

  v4_phy_infrastructure_iobs #
    (
     .clk_width (clk_width)
     )
    infrastructure_iobs_00
      (
       .CLK                  (CLK),
       .DDR_CK               (DDR_CK),
       .DDR_CK_N             (DDR_CK_N)
       );
  
  v4_phy_data_path_iobs #
    (
     .DQSN_ENABLE       (DQSN_ENABLE),
     .DDR2_ENABLE       (DDR2_ENABLE),
     .data_width        (data_width),
     .data_strobe_width (data_strobe_width),
     .data_mask_width   (data_mask_width)
     )
    data_path_iobs_00
      (
       .CLK                  (CLK),
       .CLK90                (CLK90),
       .RESET0               (RESET0),
       .dqs_rst              (dqs_rst),
       .dqs_en               (dqs_en),
       .delay_enable         (delay_enable),
       .data_idelay_inc      (data_idelay_inc),
       .data_idelay_ce       (data_idelay_ce),
       .data_idelay_rst      (data_idelay_rst),
       .wr_data_rise         (wr_data_rise),
       .wr_data_fall         (wr_data_fall),
       .wr_en                (wr_en),
       .rd_data_rise         (rd_data_rise),
       .rd_data_fall         (rd_data_fall),
       .mask_data_rise       (mask_data_rise),
       .mask_data_fall       (mask_data_fall),
       .DDR_DQ               (DDR_DQ),
       .DDR_DQS              (DDR_DQS),
       .DDR_DQS_L            (DDR_DQS_L),
       .DDR_DM               (DDR_DM)
       );
  
  v4_phy_controller_iobs #
    (
     .row_address  (row_address),
     .bank_address (bank_address),
     .cs_width     (cs_width),
     .cke_width    (cke_width),
     .odt_width    (odt_width)
     )
    controller_iobs_00
      (
       .CLK                  (CLK),
       .ctrl_ddr2_address    (ctrl_ddr2_address),
       .ctrl_ddr2_ba         (ctrl_ddr2_ba),
       .ctrl_ddr2_ras_L      (ctrl_ddr2_ras_L),
       .ctrl_ddr2_cas_L      (ctrl_ddr2_cas_L),
       .ctrl_ddr2_we_L       (ctrl_ddr2_we_L),
       .ctrl_ddr2_cs_L       (ctrl_ddr2_cs_L),
       .ctrl_ddr2_cke        (ctrl_ddr2_cke),
       .ctrl_ddr2_odt        (ctrl_ddr2_odt),
       
       .DDR_ADDRESS          (DDR_ADDRESS),
       .DDR_BA               (DDR_BA),
       .DDR_RAS_L            (DDR_RAS_L),
       .DDR_CAS_L            (DDR_CAS_L),
       .DDR_WE_L             (DDR_WE_L),
       .DDR_CKE              (DDR_CKE),
       .DDR_ODT              (DDR_ODT),
       .ddr_cs_L             (ddr_cs_L)
       );
  
endmodule
