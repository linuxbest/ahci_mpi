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
// MPMC V5 MIG PHY DDR1 IO's
//-------------------------------------------------------------------------
//
// Description:
//
// Structure:
//     
//--------------------------------------------------------------------------
//
// History:
//   Dec 20 2007: Merged MIG 2.1 modifications into this file.
//   Jul 18 2008: Merged MIG 2.3 modifications into this file.
//
//--------------------------------------------------------------------------

`timescale 1ns/1ps

module v5_phy_top_ddr1 #
  (
   parameter integer WDF_RDEN_EARLY = 0,
   parameter integer WDF_RDEN_WIDTH = 1,
   parameter BANK_WIDTH            = 2,
   parameter CLK_WIDTH             = 2,
   parameter CKE_WIDTH             = 1,
   parameter COL_WIDTH             = 10,
   parameter CS_NUM                = 1,
   parameter CS_WIDTH              = 2,
   parameter USE_DM_PORT           = 1,
   parameter DM_WIDTH              = 4,
   parameter DQ_WIDTH              = 32,
   parameter DQ_BITS               = 5,
   parameter DQ_PER_DQS            = 8,
   parameter DQS_BITS              = 2,
   parameter DQS_WIDTH             = 4,
   parameter HIGH_PERFORMANCE_MODE = "TRUE",
   parameter IODELAY_GRP           = "IODELAY_MIG",
   parameter ODT_WIDTH             = 0,
   parameter ROW_WIDTH             = 13,
   parameter ADDITIVE_LAT          = 0,
   parameter BURST_LEN             = 4,
   parameter BURST_TYPE            = 0,
   parameter CAS_LAT               = 3,
   parameter ECC_ENABLE            = 0,
   parameter ODT_TYPE              = 0,
   parameter REDUCE_DRV            = 0,
   parameter REG_ENABLE            = 0,
   parameter CLK_PERIOD            = 5000,
   parameter DDR2_ENABLE           = 0,
   parameter DQS_GATE_EN           = 1,
   parameter SIM_ONLY              = 0,
   parameter DEBUG_EN              = 0
   )
  (
   input                                  clk0,
   input                                  clk90,
   input                                  rst0,
   input                                  rst90,
   input                                  ctrl_wren,
   input [ROW_WIDTH-1:0]                  ctrl_addr,
   input [BANK_WIDTH-1:0]                 ctrl_ba,
   input                                  ctrl_ras_n,
   input                                  ctrl_cas_n,
   input                                  ctrl_we_n,
   input [CS_NUM-1:0]                     ctrl_cs_n,
   input                                  ctrl_rden,
   input                                  ctrl_ref_flag,
   input [(2*DQS_WIDTH*DQ_PER_DQS)-1:0]   wdf_data,
   input [(2*DM_WIDTH)-1:0]               wdf_mask_data,
   output [WDF_RDEN_WIDTH-1:0]            wdf_rden,
   output reg                             phy_init_done
                                          /* synthesis syn_maxfan = 1 */,
   output [DQS_WIDTH-1:0]                 phy_calib_rden,
   output                                 phy_init_wdf_wren,
   output [63:0]                          phy_init_wdf_data,
   output [(DQS_WIDTH*DQ_PER_DQS)-1:0]    rd_data_rise,
   output [(DQS_WIDTH*DQ_PER_DQS)-1:0]    rd_data_fall,   
   output [CLK_WIDTH-1:0]                 ddr_ck,
   output [CLK_WIDTH-1:0]                 ddr_ck_n,
   output [ROW_WIDTH-1:0]                 ddr_addr,
   output [BANK_WIDTH-1:0]                ddr_ba,
   output                                 ddr_ras_n,
   output                                 ddr_cas_n,
   output                                 ddr_we_n,
   output [CS_WIDTH-1:0]                  ddr_cs_n,
   output [CKE_WIDTH-1:0]                 ddr_cke,
   output [ODT_WIDTH-1:0]                 ddr_odt,
   output [DM_WIDTH-1:0]                  ddr_dm,
   inout [DQS_WIDTH-1:0]                  ddr_dqs,
   inout [DQS_WIDTH-1:0]                  ddr_dqs_n,
   inout [DQ_WIDTH-1:0]                   ddr_dq,
   //Debug signals
   input                                  dbg_idel_up_all,
   input                                  dbg_idel_down_all,
   input                                  dbg_idel_up_dq,
   input                                  dbg_idel_down_dq,
   input                                  dbg_idel_up_dqs,
   input                                  dbg_idel_down_dqs,
   input                                  dbg_idel_up_gate,
   input                                  dbg_idel_down_gate,
   input [DQ_BITS-1:0]                    dbg_sel_idel_dq,
   input                                  dbg_sel_all_idel_dq,
   input [DQS_BITS:0]                     dbg_sel_idel_dqs,
   input                                  dbg_sel_all_idel_dqs,
   input [DQS_BITS:0]                     dbg_sel_idel_gate,
   input                                  dbg_sel_all_idel_gate,
   output [3:0]                           dbg_calib_done,
   output [3:0]                           dbg_calib_err,
   output [(6*DQ_WIDTH)-1:0]              dbg_calib_dq_tap_cnt,
   output [(6*DQS_WIDTH)-1:0]             dbg_calib_dqs_tap_cnt,
   output [(6*DQS_WIDTH)-1:0]             dbg_calib_gate_tap_cnt,
   output [(2*DQS_WIDTH)-1:0]             dbg_calib_rden_dly,
   output [(2*DQS_WIDTH)-1:0]             dbg_calib_gate_dly,
   input  [(2*DQS_WIDTH)-1:0]             dbg_calib_rden_dly_value,
   input  [(DQS_WIDTH)-1:0]               dbg_calib_rden_dly_en,
   input  [(2*DQS_WIDTH)-1:0]             dbg_calib_gate_dly_value,
   input  [(DQS_WIDTH)-1:0]               dbg_calib_gate_dly_en
   );  

  
  wire [3:0]              calib_done;
  wire                    calib_ref_done;
  wire                    calib_ref_req;
  wire [3:0]              calib_start;
  wire                    dq_oe_n;
  wire                    dqs_oe_n;
  wire                    dqs_rst_n;
  wire [DM_WIDTH-1:0]     mask_data_fall;
  wire [DM_WIDTH-1:0]     mask_data_rise;
  wire                    odt;
  wire [ROW_WIDTH-1:0]    phy_init_addr;
  wire [BANK_WIDTH-1:0]   phy_init_ba;
  wire                    phy_init_cas_n;
  wire [CKE_WIDTH-1:0]    phy_init_cke;
  wire [CS_NUM-1:0]       phy_init_cs_n;
  wire                    phy_init_ras_n;
  wire                    phy_init_rden;
  wire                    phy_init_we_n;
  wire                    phy_init_wren;
  wire [DQ_WIDTH-1:0]     wr_data_fall;
  wire [DQ_WIDTH-1:0]     wr_data_rise;
  wire                    i_phy_init_done;
  
  v5_phy_write_ddr1 #
    (
     .WDF_RDEN_EARLY (WDF_RDEN_EARLY),
     .WDF_RDEN_WIDTH (WDF_RDEN_WIDTH),
     .DQ_WIDTH     (DQ_WIDTH), 
     .DM_WIDTH     (DM_WIDTH), 
     .DQS_WIDTH    (DQS_WIDTH),
     .ADDITIVE_LAT (ADDITIVE_LAT),
     .CAS_LAT      (CAS_LAT),
     .ECC_ENABLE   (ECC_ENABLE),
     .ODT_TYPE     (ODT_TYPE),
     .REG_ENABLE   (REG_ENABLE),
     .DDR2_ENABLE  (DDR2_ENABLE)
     )
    u_phy_write
      (
       .clk0               (clk0),
       .clk90              (clk90),
       .wdf_data           ({wdf_data[DQ_WIDTH+(DQS_WIDTH*DQ_PER_DQS)-1:DQS_WIDTH*DQ_PER_DQS],wdf_data[DQ_WIDTH-1:0]}),
       .wdf_mask_data      (wdf_mask_data),
       .ctrl_wren          (ctrl_wren),
       .phy_init_wren      (phy_init_wren),
       .phy_init_done      (i_phy_init_done),
       .dq_oe_n            (dq_oe_n),
       .dqs_oe_n           (dqs_oe_n),
       .dqs_rst_n          (dqs_rst_n),
       .wdf_rden           (wdf_rden),
       .odt                (odt),
       .wr_data_rise       (wr_data_rise),
       .wr_data_fall       (wr_data_fall),
       .mask_data_rise     (mask_data_rise),
       .mask_data_fall     (mask_data_fall)
       );
  
  v5_phy_io_ddr1 #
    (
     .CLK_WIDTH             (CLK_WIDTH),
     .USE_DM_PORT           (USE_DM_PORT),
     .DM_WIDTH              (DM_WIDTH),
     .DQ_WIDTH              (DQ_WIDTH),
     .DQ_BITS               (DQ_BITS),
     .DQ_PER_DQS            (DQ_PER_DQS),
     .DQS_BITS              (DQS_BITS),
     .DQS_WIDTH             (DQS_WIDTH),
     .HIGH_PERFORMANCE_MODE (HIGH_PERFORMANCE_MODE),
     .IODELAY_GRP           (IODELAY_GRP),
     .ODT_WIDTH             (ODT_WIDTH),
     .ADDITIVE_LAT          (ADDITIVE_LAT),
     .CAS_LAT               (CAS_LAT),
     .ECC_ENABLE            (ECC_ENABLE),
     .REG_ENABLE            (REG_ENABLE),
     .CLK_PERIOD            (CLK_PERIOD),
     .DDR2_ENABLE           (DDR2_ENABLE),
     .DQS_GATE_EN           (DQS_GATE_EN),
     .DEBUG_EN              (DEBUG_EN)
     )
    u_phy_io
      (
       .clk0                   (clk0),
       .clk90                  (clk90),
       .rst0                   (rst0),
       .rst90                  (rst90),
       .dq_oe_n                (dq_oe_n),
       .dqs_oe_n               (dqs_oe_n),
       .dqs_rst_n              (dqs_rst_n),
       .calib_start            (calib_start),
       .ctrl_rden              (ctrl_rden),
       .phy_init_rden          (phy_init_rden),
       .phy_init_done          (i_phy_init_done),
       .calib_ref_done         (calib_ref_done),
       .calib_done             (calib_done),
       .calib_ref_req          (calib_ref_req),
       .calib_rden             (phy_calib_rden),
       .wr_data_rise           (wr_data_rise),
       .wr_data_fall           (wr_data_fall),
       .mask_data_rise         (mask_data_rise),
       .mask_data_fall         (mask_data_fall),
       .rd_data_rise           (rd_data_rise[DQ_WIDTH-1:0]),
       .rd_data_fall           (rd_data_fall[DQ_WIDTH-1:0]),
       .ddr_ck                 (ddr_ck),
       .ddr_ck_n               (ddr_ck_n),
       .ddr_dm                 (ddr_dm),
       .ddr_dqs                (ddr_dqs),
       .ddr_dqs_n              (ddr_dqs_n),
       .ddr_dq                 (ddr_dq),
       //Debug signals
       .dbg_idel_up_all        (dbg_idel_up_all),
       .dbg_idel_down_all      (dbg_idel_down_all),
       .dbg_idel_up_dq         (dbg_idel_up_dq),
       .dbg_idel_down_dq       (dbg_idel_down_dq),
       .dbg_idel_up_dqs        (dbg_idel_up_dqs),
       .dbg_idel_down_dqs      (dbg_idel_down_dqs),
       .dbg_idel_up_gate       (dbg_idel_up_gate),
       .dbg_idel_down_gate     (dbg_idel_down_gate),
       .dbg_sel_idel_dq        (dbg_sel_idel_dq),
       .dbg_sel_all_idel_dq    (dbg_sel_all_idel_dq),
       .dbg_sel_idel_dqs       (dbg_sel_idel_dqs),
       .dbg_sel_all_idel_dqs   (dbg_sel_all_idel_dqs),
       .dbg_sel_idel_gate      (dbg_sel_idel_gate),
       .dbg_sel_all_idel_gate  (dbg_sel_all_idel_gate),
       .dbg_calib_done         (dbg_calib_done),
       .dbg_calib_err          (dbg_calib_err),
       .dbg_calib_dq_tap_cnt   (dbg_calib_dq_tap_cnt),
       .dbg_calib_dqs_tap_cnt  (dbg_calib_dqs_tap_cnt),
       .dbg_calib_gate_tap_cnt (dbg_calib_gate_tap_cnt),
       .dbg_calib_rden_dly_value (dbg_calib_rden_dly_value),
       .dbg_calib_rden_dly_en  (dbg_calib_rden_dly_en),
       .dbg_calib_rden_dly     (dbg_calib_rden_dly),
       .dbg_calib_gate_dly_value (dbg_calib_gate_dly_value),
       .dbg_calib_gate_dly_en  (dbg_calib_gate_dly_en),
       .dbg_calib_gate_dly     (dbg_calib_gate_dly)
       );

  v5_phy_ctl_io_ddr1 #
    (
     .BANK_WIDTH (BANK_WIDTH),
     .CKE_WIDTH  (CKE_WIDTH),
     .COL_WIDTH  (COL_WIDTH),
     .CS_NUM     (CS_NUM),
     .CS_WIDTH   (CS_WIDTH),
     .ODT_WIDTH  (ODT_WIDTH),
     .ROW_WIDTH  (ROW_WIDTH),
     .DDR2_ENABLE (DDR2_ENABLE)
     )
    u_phy_ctl_io
      (
       .clk0           (clk0),
       .rst0           (rst0),
       .ctrl_addr      (ctrl_addr),
       .ctrl_ba        (ctrl_ba),
       .ctrl_ras_n     (ctrl_ras_n),
       .ctrl_cas_n     (ctrl_cas_n),
       .ctrl_we_n      (ctrl_we_n),
       .ctrl_cs_n      (ctrl_cs_n),
       .phy_init_addr  (phy_init_addr),
       .phy_init_ba    (phy_init_ba),
       .phy_init_ras_n (phy_init_ras_n),
       .phy_init_cas_n (phy_init_cas_n),
       .phy_init_we_n  (phy_init_we_n),
       .phy_init_cs_n  (phy_init_cs_n),
       .phy_init_cke   (phy_init_cke),
       .phy_init_done  (i_phy_init_done),
       .odt            (odt),
       .ddr_addr       (ddr_addr),
       .ddr_ba         (ddr_ba),
       .ddr_ras_n      (ddr_ras_n),
       .ddr_cas_n      (ddr_cas_n),
       .ddr_we_n       (ddr_we_n),
       .ddr_cke        (ddr_cke),
       .ddr_cs_n       (ddr_cs_n),
       .ddr_odt        (ddr_odt)
       );

  v5_phy_init_ddr1 #
    (
     .DQ_WIDTH     (DQ_WIDTH),
     .DQS_WIDTH    (DQS_WIDTH),
     .BANK_WIDTH   (BANK_WIDTH),
     .CKE_WIDTH    (CKE_WIDTH),
     .COL_WIDTH    (COL_WIDTH),
     .CS_NUM       (CS_NUM),
     .ODT_WIDTH    (ODT_WIDTH),
     .ROW_WIDTH    (ROW_WIDTH),
     .ADDITIVE_LAT (ADDITIVE_LAT),
     .BURST_LEN    (BURST_LEN),
     .BURST_TYPE   (BURST_TYPE),
     .CAS_LAT      (CAS_LAT),
     .ODT_TYPE     (ODT_TYPE),
     .REDUCE_DRV   (REDUCE_DRV),
     .REG_ENABLE   (REG_ENABLE),
     .ECC_ENABLE   (ECC_ENABLE),
     .DDR2_ENABLE  (DDR2_ENABLE),
     .DQS_GATE_EN  (DQS_GATE_EN),
     .SIM_ONLY     (SIM_ONLY)
     )
    u_phy_init
      (
       .clk0                (clk0),
       .rst0                (rst0),
       .calib_done          (calib_done),
       .ctrl_ref_flag       (ctrl_ref_flag),
       .calib_ref_done      (calib_ref_done),
       .calib_start         (calib_start),
       .calib_ref_req       (calib_ref_req),
       .phy_init_wren       (phy_init_wren),
       .phy_init_rden       (phy_init_rden),
       .phy_init_wdf_wren   (phy_init_wdf_wren),
       .phy_init_wdf_data   (phy_init_wdf_data),
       .phy_init_addr       (phy_init_addr),
       .phy_init_ba         (phy_init_ba),
       .phy_init_ras_n      (phy_init_ras_n),
       .phy_init_cas_n      (phy_init_cas_n),
       .phy_init_we_n       (phy_init_we_n),
       .phy_init_cs_n       (phy_init_cs_n),
       .phy_init_cke        (phy_init_cke),
       .phy_init_done       (i_phy_init_done)
       );

  // synthesis attribute max_fanout of phy_init_done is 1
  always @( posedge clk0 )
    phy_init_done <= i_phy_init_done;

endmodule
