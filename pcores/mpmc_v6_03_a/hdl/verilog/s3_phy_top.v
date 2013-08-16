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
// MPMC Spartam3 MIG PHY Top Level
//-------------------------------------------------------------------------
//
// Description:
//
// Structure:
//   -- s3_phy.v
//     -- s3_phy_init.v
//     -- s3_infrastructure.v
//       -- s3_cal_top.v
//         -- s3_cal_ctl.v
//         -- s3_tap_dly.v
//     -- s3_phy_write.v
//     -- s3_data_path.v
//       -- s3_data_read_controller.v
//         -- s3_dqs_delay.v
//         -- s3_fifo_0_wr_en.v
//         -- s3_fifo_1_wr_en.v
//       -- s3_data_read.v
//         -- s3_rd_data_ram0.v
//         -- s3_rd_data_ram1.v
//         -- s3_gray_cntr.v
//     -- s3_iobs.v
//       -- s3_infrastructure_iobs.v
//       -- s3_controller_iobs.v
//       -- s3_data_path_iobs.v
//         -- s3_dqs_iob.v
//         -- s3_dq_iob.v
//         -- s3_dm_iobs.v
//     
//--------------------------------------------------------------------------
//
// History:
//   Dec 20 2007: Merged MIG 2.1 modifications into this file.
//   Jul 18 2008: Merged MIG 2.3 modifications into this file.
//
//--------------------------------------------------------------------------

`timescale 1ns/1ps

// ---------------------------------------------------------------------------
// 
//  Definition of Generics:
//
//      BANK_WIDTH     -- DDR/DDR2 bank address bus width
//      ROW_WIDTH      -- DDR/DDR2 row address bus width
//      COL_WIDTH      -- DDR/DDR2 column address bus width
//      CLK_WIDTH      -- DDR/DDR2 number of output clock pairs
//      CS_NUM         -- Number of external chip selectable memory components
//      CS_WIDTH       -- Number of CS signals to duplicate
//      DM_WIDTH       -- Width of DDR/DDR2 data mask signals
//      DQ_BITS        -- Width of DDR/DDR2 data signals
//      DQ_PER_DQS     -- Ratio of data signals per data strobe signal
//                     -- (design only supports a ratio of 8)
//      DQS_BITS       -- Unused: Can be internally generated using log2 (DQS_WIDTH)
//      DQS_WIDTH      -- Width of DDR/DDR2 data strobe signals
//      DQSN_ENABLE    -- 0 = Disables differential DQS
//                     -- 1 = Enables differential DQS
//      ODT_WIDTH      -- Width of DDR/DDR2 ODT signals to duplicate
//      ADDITIVE_LAT   -- Value for additive latency
//                     -- (only supported for DDR2 memory)
//      BURST_LEN      -- Burst length = 4 (or 8)   
//      BURST_TYPE     -- Sequential (= 0) or Interleaved (= 1) burst type
//      CAS_LAT        -- Memory read CAS latency
//      ECC_ENABLE     -- 0 = Disable ECC (default)   (not supported)
//      ODT_TYPE       -- Specified ODT output type
//                     -- 0 = off (default)
//                              
//      REDUCE_DRV     -- 0 = typical drive strength
//                     -- 1 = reduced drive strength
//      REG_ENABLE     -- Set to 1 for registered DIMM memory components
//      CLK_PERIOD     -- Specifies clock period (unused in S3A PHY)
//      DDR2_ENABLE    -- 0 = DDR memory interface
//                     -- 1 = DDR2 memory interface
//      DQS_GATE_EN    -- Note: Unused in S3A PHY
//      IDEL_HIGH_PERF -- Note: Unused in S3A PHY
//      WDF_RDEN_EARLY -- Used to specify if WDF RdEn needs to be set early
//                     -- 1 = assert WDF RdEn early, 
//                     -- 0 = no early assertion needed
//      SIM_ONLY       -- Set to 0 for implementation
//                     -- Set to 1 during simulation to reduce init time
//
// -----------------------------------------------------------------------------
module s3_phy_top #
  (
   parameter integer BANK_WIDTH      = 2,
   parameter integer ROW_WIDTH       = 13,   
   parameter integer COL_WIDTH       = 10,
   parameter integer CLK_WIDTH       = 1,
   parameter integer CKE_WIDTH       = 1,
   parameter integer CS_NUM          = 1,
   parameter integer CS_WIDTH        = 1,
   parameter integer DM_WIDTH        = 2,
   parameter integer DQ_BITS         = 16,
   parameter integer DQ_PER_DQS      = 8,
   parameter integer DQS_BITS        = 1, // Unused: Can be internally generated using log2 (DQS_WIDTH)
   parameter integer DQS_WIDTH       = 2,
   parameter integer DQSN_ENABLE     = 0, // Enables differential DQS
   parameter integer ODT_WIDTH       = 1,
   parameter integer ADDITIVE_LAT    = 0,
   parameter integer BURST_LEN       = 4, // Burst length = 4 (or 8)   
   parameter integer BURST_TYPE      = 0, // Sequential burst type
   parameter integer CAS_LAT         = 3, // Memory read CAS latency
   parameter integer ECC_ENABLE      = 0, // Disable ECC (default)   
   parameter integer ODT_TYPE        = 0,
   parameter integer REDUCE_DRV      = 0,
   parameter integer REG_ENABLE      = 0,
   parameter integer TWR             = 15000,
   parameter integer CLK_PERIOD      = 7500,       // Note: Unused in S3A PHY
   parameter integer DDR2_ENABLE     = 1,          // 1 = DDR2, 
                                                   // 0 = DDR memory type
   parameter integer DQS_GATE_EN     = 0,          // Note: Unused in S3A PHY
   parameter         IDEL_HIGH_PERF  = "TRUE",     // Note: Unused in S3A PHY
   parameter         WDF_RDEN_EARLY  = 1,          // By default, PHY should use early RdEn on WDF
   parameter integer WDF_RDEN_WIDTH  = 1,
   parameter integer SIM_ONLY        = 0,
   parameter         C_FAMILY        = "spartan3", // Allowed Values: spartan3, spartan3e, spartan3a
   parameter integer C_SPECIAL_BOARD = 0,          // Allowed Values: 0 = use default settings, 
                                                   //                 1 = special placement
   parameter integer C_DEBUG_EN      = 0
   )
  (
   input                                 clk0,
   input                                 clk90,
   input                                 rst0,
   input                                 rst90,
   input                                 ctrl_wren,
   input [ROW_WIDTH-1:0]                 ctrl_addr,
   input [BANK_WIDTH-1:0]                ctrl_ba,
   input                                 ctrl_ras_n,
   input                                 ctrl_cas_n,
   input                                 ctrl_we_n,
   input [CS_NUM-1:0]                    ctrl_cs_n,
   input                                 ctrl_rden,
   input                                 ctrl_ref_flag,
   input [(2*DQS_WIDTH*DQ_PER_DQS)-1:0]  wdf_data,
   input [(2*DM_WIDTH)-1:0]              wdf_mask_data,
   
   output [WDF_RDEN_WIDTH-1:0]           wdf_rden,
   output                                phy_init_done,
   output [DQS_WIDTH-1:0]                phy_calib_rden,
   output [(DQS_WIDTH*DQ_PER_DQS)-1:0]   rd_data_rise,
   output [(DQS_WIDTH*DQ_PER_DQS)-1:0]   rd_data_fall,  
   
   output [CLK_WIDTH-1:0]                ddr_ck,
   output [CLK_WIDTH-1:0]                ddr_ck_n,
   output [ROW_WIDTH-1:0]                ddr_addr,
   output [BANK_WIDTH-1:0]               ddr_ba,
   output                                ddr_ras_n,
   output                                ddr_cas_n,
   output                                ddr_we_n,
   output [CS_WIDTH-1:0]                 ddr_cs_n,
   output [CKE_WIDTH-1:0]                ddr_cke,
   output [ODT_WIDTH-1:0]                ddr_odt,
   output [DM_WIDTH-1:0]                 ddr_dm,
   
   inout [DQS_WIDTH-1:0]                 ddr_dqs,
   inout [DQS_WIDTH-1:0]                 ddr_dqs_n,
   inout [(DQS_WIDTH*DQ_PER_DQS)-1:0]    ddr_dq,
   
   output                                rst_dqs_div_out,
   input                                 rst_dqs_div_in,
   //debug_signals
   output [4:0]                          dbg_delay_sel, 
   output                                dbg_rst_calib,
   output [4:0]                          dbg_phase_cnt,
   output [5:0]                          dbg_cnt,
   output                                dbg_trans_onedtct,
   output                                dbg_trans_twodtct,
   output                                dbg_enb_trans_two_dtct,
   input [4:0]                           vio_out_dqs,
   input                                 vio_out_dqs_en,
   input [4:0]                           vio_out_rst_dqs_div,
   input                                 vio_out_rst_dqs_div_en
   );  

  localparam DQ_WIDTH = DQS_WIDTH * DQ_PER_DQS;
  
  wire [2:0]                             calib_done;
  wire [2:0]                             calib_start;
  wire [DQS_WIDTH-1:0]                   dqs_oe;
  wire [DQS_WIDTH-1:0]                   dqs_rst;
  wire [ROW_WIDTH-1:0]                   phy_init_addr;
  wire [BANK_WIDTH-1:0]                  phy_init_ba;
  wire                                   phy_init_cas_n;
  wire [CKE_WIDTH-1:0]                   phy_init_cke;
  wire [CS_NUM-1:0]                      phy_init_cs_n;
  wire                                   phy_init_ras_n;
  wire                                   phy_init_we_n;
  wire [ODT_WIDTH-1:0]                   phy_odt;
  wire                                   mux_ddr_rasb; 
  wire                                   mux_ddr_casb;
  wire                                   mux_ddr_web;
  wire                                   mux_ddr_cke;
  wire [CS_NUM-1:0]                      mux_ddr_csb;
  wire [ODT_WIDTH-1:0]                   mux_ddr_odt;
  wire [ROW_WIDTH-1:0]                   mux_ddr_address;
  wire [BANK_WIDTH-1:0]                  mux_ddr_ba;
  
  wire [DQ_WIDTH-1:0]                    wr_data_fall;
  wire [DQ_WIDTH-1:0]                    wr_data_rise;
  wire [DM_WIDTH-1:0]                    mask_data_fall;
  wire [DM_WIDTH-1:0]                    mask_data_rise;
  
  wire [4:0]                             delay_sel;
  wire [(DQS_WIDTH-1):0]                 dqs_int_delay_in;
  wire [(DQS_WIDTH*DQ_PER_DQS)-1:0]      dq;
  wire                                   dqs_div_rst;
  wire                                   read_fifo_rden;
  wire [((DQ_BITS*2)-1):0]               user_output_data;
  
  wire                                   clk180;
  wire                                   clk270;
  wire                                   rst_calib;
  wire                                   rst_rd_fifo;
  wire                                   start_rd;
  wire                                   init_done_re;
  reg                                    start_rd_reg;
  reg                                    phy_init_done_reg;
  reg                                    phy_init_done_reg180;
  
  wire                                   dq_oe;
  wire                                   user_data_valid;
  wire                                   rst_dqs_div_int;       
  
  // Seeing issue when wren follows rden, read address counters are reset before all data
  // is read out of FIFOs
  // Only use ctrl_rden to reset the read address counters
  assign start_rd = ctrl_rden;
  
  always @(posedge clk0) begin
    start_rd_reg <= start_rd;   
    phy_init_done_reg <= phy_init_done;
  end
  
  // Use RE detect to reset read FIFOs
  assign rst_rd_fifo = (start_rd & ~start_rd_reg);
  assign init_done_re = (phy_init_done & ~phy_init_done_reg);
  
  assign clk180 = ~clk0;
  assign clk270 = ~clk90;
  
  // Read logic re-calibrates itself during write operations
  // Reset to calibration logic is active low (ie. new delay_val is assigned)
  assign rst_calib = ~(ctrl_wren | rst0 | init_done_re);        
  
  // ----------------------------------------------------------------------
  // Module Name: phy_write
  // Purpose:           Write path logic on data.
  // ----------------------------------------------------------------------
  s3_phy_write #
    (
     .DQ_BITS        (DQ_BITS), 
     .DM_WIDTH       (DM_WIDTH),
     .DQ_PER_DQS     (DQ_PER_DQS),
     .DQS_WIDTH      (DQS_WIDTH),
     .CS_NUM         (CS_NUM),
     .ODT_WIDTH      (ODT_WIDTH),
     .ADDITIVE_LAT   (ADDITIVE_LAT),
     .CAS_LAT        (CAS_LAT),
     .ECC_ENABLE     (ECC_ENABLE),
     .ODT_TYPE       (ODT_TYPE),
     .REG_ENABLE     (REG_ENABLE),
     .DDR2_ENABLE    (DDR2_ENABLE),
     .WDF_RDEN_EARLY (WDF_RDEN_EARLY),
     .WDF_RDEN_WIDTH (WDF_RDEN_WIDTH)
     )
    phy_write
      (
       .clk0           (clk0),
       .clk90          (clk90),
       .rst0           (rst0),
       .rst90          (rst90),
       .wdf_data       (wdf_data),
       .wdf_mask_data  (wdf_mask_data),
       .wdf_rden       (wdf_rden),
       .ctrl_wren      (ctrl_wren),
       .ctrl_cs_n      (ctrl_cs_n),
       .phy_init_done  (phy_init_done),
       .dq_oe          (dq_oe),
       .dqs_oe         (dqs_oe),
       .dqs_rst        (dqs_rst),
       .odt            (phy_odt),
       .wr_data_rise   (wr_data_rise),
       .wr_data_fall   (wr_data_fall),
       .mask_data_rise (mask_data_rise),
       .mask_data_fall (mask_data_fall)
       );
  
  // ----------------------------------------------------------------------
  // Module Name: phy_init
  // Purpose:     Initialization logic.  Derived from V5 MIG design. 
  //              All outputs from this block need to be muxed with signals
  //              from the controller before being presented to the IOBs.
  // ----------------------------------------------------------------------
  s3_phy_init #
    (
     .DQS_WIDTH    (DQS_WIDTH),
     .DQ_PER_DQS   (DQ_PER_DQS),
     .BANK_WIDTH   (BANK_WIDTH),
     .CKE_WIDTH    (CKE_WIDTH),
     .COL_WIDTH    (COL_WIDTH),
     .CS_WIDTH     (CS_WIDTH),
     .ODT_WIDTH    (ODT_WIDTH),
     .ROW_WIDTH    (ROW_WIDTH),
     .ADDITIVE_LAT (ADDITIVE_LAT),
     .BURST_LEN    (BURST_LEN),
     .BURST_TYPE   (BURST_TYPE),
     .CAS_LAT      (CAS_LAT),
     .ODT_TYPE     (ODT_TYPE),
     .REDUCE_DRV   (REDUCE_DRV),
     .REG_ENABLE   (REG_ENABLE),
     .TWR          (TWR),
     .CLK_PERIOD   (CLK_PERIOD),
     .DDR2_ENABLE  (DDR2_ENABLE),
     .DQSN_ENABLE  (DQSN_ENABLE),
     .STATIC_PHY   (0),
     .SIM_ONLY     (SIM_ONLY)
     )
    phy_init
      (
       .clk0           (clk0),
       .clk180         (clk180),
       .rst0           (rst0),
       .ctrl_ref_flag  (ctrl_ref_flag),
       .phy_init_addr  (phy_init_addr),
       .phy_init_ba    (phy_init_ba),
       .phy_init_ras_n (phy_init_ras_n),
       .phy_init_cas_n (phy_init_cas_n),
       .phy_init_we_n  (phy_init_we_n),
       .phy_init_cs_n  (phy_init_cs_n),
       .phy_init_cke   (phy_init_cke),
       .phy_init_done  (phy_init_done)
       );
  
  // Loop back start to done signal       
  assign calib_done = calib_start;
  
  // ----------------------------------------------------------------------
  // Module Name: infrastructure
  // Purpose:     Instantiate infrastruture block
  //              Creates delay_sel used by DQ and DQS IOB modules
  // ----------------------------------------------------------------------
  s3_infrastructure #
    (
     .SIM_ONLY        (SIM_ONLY),
     .C_FAMILY        (C_FAMILY),
     .C_SPECIAL_BOARD (C_SPECIAL_BOARD)
     )
    infrastructure
      (
       .sys_rst                (rst0),
       .clk_int                (clk0),
       .rst_calib              (rst_calib),
       .delay_sel_val_out      (delay_sel),
       .dbg_delay_sel          (dbg_delay_sel),
       .dbg_rst_calib          (dbg_rst_calib),
       .dbg_phase_cnt          (dbg_phase_cnt),
       .dbg_cnt                (dbg_cnt),
       .dbg_trans_onedtct      (dbg_trans_onedtct),
       .dbg_trans_twodtct      (dbg_trans_twodtct),
       .dbg_enb_trans_two_dtct (dbg_enb_trans_two_dtct)
       );
  
  // ----------------------------------------------------------------------
  // Module Name:       data_path
  // Purpose:           Keep data_path module which instantiates
  //                    data_read_controller & data_read modules
  //                    Added parameterization
  // ----------------------------------------------------------------------
  s3_data_path #
    (
     .DQS_WIDTH       (DQS_WIDTH),      
     .DQ_BITS         (DQ_BITS),        
     .DQ_PER_DQS      (DQ_PER_DQS),
     .SIM_ONLY        (SIM_ONLY),
     .C_FAMILY        (C_FAMILY),
     .C_SPECIAL_BOARD (C_SPECIAL_BOARD),
     .C_DEBUG_EN      (C_DEBUG_EN)
     )  
    data_path
      ( 
        .clk0                   (clk0), 
        .clk90                  (clk90), 
        .clk180                 (clk180), 
        .rst                    (rst0),
        .rst90                  (rst90),
        .rst_dqs_div_in         (dqs_div_rst),
        .delay_sel              (delay_sel),
        .dqs_int_delay_in       (dqs_int_delay_in),
        .rst_rd_fifo            (rst_rd_fifo),
        .dq                     (dq),      
        .user_data_valid        (user_data_valid),
        .user_output_data       (user_output_data),
        .read_fifo_rden         (read_fifo_rden),
        .vio_out_dqs            (vio_out_dqs),   
        .vio_out_dqs_en         (vio_out_dqs_en),   
        .vio_out_rst_dqs_div    (vio_out_rst_dqs_div),
        .vio_out_rst_dqs_div_en (vio_out_rst_dqs_div_en)
        );                           
  
  assign phy_calib_rden = user_data_valid;
  
  assign rd_data_fall = user_output_data[(2*DQS_WIDTH*DQ_PER_DQS)-1:(DQS_WIDTH*DQ_PER_DQS)];
  assign rd_data_rise = user_output_data[(DQS_WIDTH*DQ_PER_DQS)-1:0];
  
  // ----------------------------------------------------------------------
  // Module Name:       iobs
  // Purpose:           Instantiate all IOB components   
  // ----------------------------------------------------------------------
  s3_iobs #
    (
     .C_FAMILY      (C_FAMILY),
     .BANK_WIDTH    (BANK_WIDTH),
     .ROW_WIDTH     (ROW_WIDTH),
     .CLK_WIDTH     (CLK_WIDTH),
     .CKE_WIDTH     (CKE_WIDTH),
     .CS_WIDTH      (CS_WIDTH),
     .ODT_WIDTH     (ODT_WIDTH),
     .DM_WIDTH      (DM_WIDTH),
     .DQ_BITS       (DQ_BITS),
     .DQS_WIDTH     (DQS_WIDTH),
     .DQSN_ENABLE   (DQSN_ENABLE),
     .SIM_ONLY      (SIM_ONLY),
     .DDR2_ENABLE   (DDR2_ENABLE)
     )
    iobs 
      (
       .clk0               (clk0), 
       .clk90              (clk90), 
       .clk180             (clk180),
       .clk270             (clk270),
       .rst0               (rst0),
       .rst90              (rst90),
       .ddr_rasb_cntrl     (mux_ddr_rasb), 
       .ddr_casb_cntrl     (mux_ddr_casb),
       .ddr_web_cntrl      (mux_ddr_web),
       .ddr_cke_cntrl      (mux_ddr_cke),
       .ddr_csb_cntrl      ({CS_WIDTH/CS_NUM{mux_ddr_csb}}),
       .ddr_odt_cntrl      (mux_ddr_odt),
       .ddr_address_cntrl  (mux_ddr_address),
       .ddr_ba_cntrl       (mux_ddr_ba),
       .dqs_reset          (dqs_rst),
       .dqs_enable         (dqs_oe),
       .ddr_dqs            (ddr_dqs),
       .ddr_dqs_n          (ddr_dqs_n),
       .ddr_dq             (ddr_dq),
       .write_data_rising  (wr_data_rise), 
       .write_data_falling (wr_data_fall),
       .write_en_val       (dq_oe),
       .data_mask_r        (mask_data_rise), 
       .data_mask_f        (mask_data_fall),
       .ddr2_ck            (ddr_ck),        
       .ddr2_ck_n          (ddr_ck_n), 
       .ddr_rasb           (ddr_ras_n), 
       .ddr_casb           (ddr_cas_n),
       .ddr_web            (ddr_we_n),
       .ddr_ba             (ddr_ba),
       .ddr_address        (ddr_addr),
       .ddr_cke            (ddr_cke),
       .ddr_csb            (ddr_cs_n),
       .ddr_odt            (ddr_odt), 
       
       .rst_dqs_div_int    (rst_dqs_div_int),
       .rst_dqs_div_out    (rst_dqs_div_out),
       .rst_dqs_div_in     (rst_dqs_div_in),
       .rst_dqs_div        (dqs_div_rst),     // IOB output to data path module
       
       .dqs_int_delay_in   (dqs_int_delay_in),
       .ddr_dm             (ddr_dm),
       .dq                 (dq)
       );                                                       
       
  // Instantiate necessary muxing logic on signals
  // that are actively driven from the phy_init block during
  // initialization and those that are driven from the controller
  // during normal operation
  
  always @(posedge clk180)
    phy_init_done_reg180 <= phy_init_done;
  
  assign mux_ddr_address = (phy_init_done_reg180) ? ctrl_addr : phy_init_addr;
  assign mux_ddr_ba = (phy_init_done_reg180) ? ctrl_ba : phy_init_ba;
  assign mux_ddr_rasb = (phy_init_done_reg180) ? ctrl_ras_n : phy_init_ras_n;
  assign mux_ddr_casb = (phy_init_done_reg180) ? ctrl_cas_n : phy_init_cas_n;
  assign mux_ddr_web = (phy_init_done_reg180) ? ctrl_we_n : phy_init_we_n;
  assign mux_ddr_csb = (phy_init_done_reg180) ? ctrl_cs_n : phy_init_cs_n;
  
  
  // No mux instantiated needed as the controller doesn't drive CKE or ODT signals
  assign mux_ddr_cke = phy_init_cke;
  assign mux_ddr_odt = phy_odt;
  
  // ----------------------------------------------------------------------
  // Module Name: dqs_div
  // Purpose:     Need a unique module to create, rst_dqs_div_int signal
  //              Was previously generated in S3 controller, but needs to be
  //              generated in phy block here.   
  // ----------------------------------------------------------------------
  s3_dqs_div #
    (
     .BURST_LEN    (BURST_LEN),
     .CAS_LAT      (CAS_LAT),
     .REG_ENABLE   (REG_ENABLE),
     .DDR2_ENABLE  (DDR2_ENABLE)
     )
    dqs_div
      (
       .clk0            (clk0),
       .rst0            (rst0),
       .phy_init_done   (phy_init_done),
       .ctrl_rden       (ctrl_rden),
       .rst_dqs_div_int (rst_dqs_div_int),
       .read_fifo_rden  (read_fifo_rden)
       );
  
endmodule
