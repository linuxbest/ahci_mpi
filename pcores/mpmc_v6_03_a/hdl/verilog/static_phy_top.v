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
//Device: Any
//Purpose: Top Level Static Phy for MPMC
//Reference:
//Revision History:
//
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

//-----------------------------------------------------------------------------
// Module name:      static_phy_top
// Description:      Top Level Static Phy.
//                     bits [0:3]   sets rden_delay
//                     bit  [4]     sets rddata_clk_sel
//                     bit  [5]     sets rddata_swap_rise
//                     bit  [6]     is unused
//                     bit  [7]     is 0 during first reset and 1 afterwards.
//                                  It prevents control reg from being 
//                                  overwritten after initial reset.
//                     bit  [8]     is DCM En (Self Clearing)
//                     bit  [9]     is DCM IncDec
//                     bit  [10]    is DCM Done (Needs to be cleared by sw)
//                     bits [11:23] are unused
//                     bits [24:31] are the dcm tap value (Read Only)
// Verilog-standard: Verilog 2001
//-----------------------------------------------------------------------------
module static_phy_top #
  (
   // System Parameters
   parameter         FAMILY                     = "virtex2p",
   // Static Phy Specific parameters
   parameter         C_RDDATA_CLK_SEL           = 1'b1,
   parameter integer C_RDEN_DELAY               = 0,
   parameter         C_RDDATA_SWAP_RISE         = 0,
   parameter         C_NUM_REG                  = 0,
   // MPMC FIFO related parameters
   parameter integer WDF_RDEN_EARLY             = 0,
   parameter integer ECC_ENABLE                 = 0,  
   // Memory Configuration Parameters
   parameter integer ADDITIVE_LAT               = 0,
   parameter integer BURST_LEN                  = 4,   
   parameter integer BURST_TYPE                 = 0,
   parameter integer CAS_LAT                    = 5,
   parameter integer DQSN_ENABLE                = 1, 
   parameter integer ODT_TYPE                   = 1,
   parameter integer REDUCE_DRV                 = 0,
   parameter integer REG_ENABLE                 = 0,
   parameter integer DDR2_ENABLE                = 1,
   // Width Parameters
   parameter integer WDF_RDEN_WIDTH             = 1,
   parameter integer BANK_WIDTH                 = 2,
   parameter integer CLK_WIDTH                  = 1,
   parameter integer CKE_WIDTH                  = 1,
   parameter integer COL_WIDTH                  = 10,
   parameter integer CS_WIDTH                   = 1,
   parameter integer DM_WIDTH                   = 2,
   parameter integer DQ_WIDTH                   = 16,
   parameter integer DQ_PER_DQS                 = 8,
   parameter integer DQS_WIDTH                  = 2,
   parameter integer ODT_WIDTH                  = 1,
   parameter integer ROW_WIDTH                  = 13,   
   // Chip Select Parameters
   parameter integer CS_NUM                     = 1,
   // Clock Parameters
   parameter integer CLK_PERIOD                 = 3000,   
   // Simulation Parmaters
   parameter integer SIM_ONLY                   = 0
   )
  (
   input  wire                          clk0,
   input  wire                          clk90,
   input  wire                          clk0_rddata,
   input  wire                          rst0,
   input  wire                          rst90,
   output wire                          dcm_en,
   output wire                          dcm_incdec,
   input  wire                          dcm_done,
   input  wire [C_NUM_REG-1:0]          reg_ce,
   input  wire [31:0]                   reg_in,
   output wire [C_NUM_REG*32-1:0]       reg_out,

   input  wire                          ctrl_wren,     // When write data is
                                                       // ready.  (DQS)
   input  wire [ROW_WIDTH-1:0]          ctrl_addr,
   input  wire [BANK_WIDTH-1:0]         ctrl_ba,
   input  wire                          ctrl_ras_n,
   input  wire                          ctrl_cas_n,
   input  wire                          ctrl_we_n,
   input  wire [CS_NUM-1:0]             ctrl_cs_n,
   input  wire                          ctrl_rden,     // Set high for number
                                                       // of read data beats.
                                                       // Needs to be high
                                                       // one cycle before 
                                                       // ctrl_cas/ras/we 
                                                       // specify read cmd.
   input  wire                          ctrl_ref_flag, // Refresh flag.  One
                                                       // cycle pulse.  Used
                                                       // for init counters for
                                                       // 200 us delay.  Assert
                                                       // every 7.8 us.  Write 
                                                       // training and write 
                                                       // data.  Look at phy 
                                                       // init module.
   input  wire [(2*DM_WIDTH)-1:0]       wdf_mask_data,
   input  wire [(2*DQS_WIDTH*DQ_PER_DQS)-1:0] wdf_data,// Write data.
   output wire [WDF_RDEN_WIDTH-1:0]     wdf_rden,      // Pop signal to FIFO.
   output wire                          phy_init_done, // High once init is
                                                       // done.
   output wire [DQS_WIDTH-1:0]          phy_calib_rden,      // Read data push.
   output wire [(DQS_WIDTH*DQ_PER_DQS)-1:0] rd_data_rise,    // LSB's
   output wire [(DQS_WIDTH*DQ_PER_DQS)-1:0] rd_data_fall,    // MSB's
   output wire [CLK_WIDTH-1:0]          ddr_ck,
   output wire [CLK_WIDTH-1:0]          ddr_ck_n,
   output wire [ROW_WIDTH-1:0]          ddr_addr,
   output wire [BANK_WIDTH-1:0]         ddr_ba,
   output wire                          ddr_ras_n,
   output wire                          ddr_cas_n,
   output wire                          ddr_we_n,
   output wire [CS_WIDTH-1:0]           ddr_cs_n,
   output wire [CKE_WIDTH-1:0]          ddr_cke,
   output wire [ODT_WIDTH-1:0]          ddr_odt,
   output wire [DM_WIDTH-1:0]           ddr_dm,
   inout  wire [DQS_WIDTH-1:0]          ddr_dqs,
   inout  wire [DQS_WIDTH-1:0]          ddr_dqs_n,
   inout  wire [DQ_WIDTH-1:0]           ddr_dq
   );  

   wire [ROW_WIDTH-1:0]                 phy_init_addr;
   wire [BANK_WIDTH-1:0]                phy_init_ba;
   wire                                 phy_init_cas_n;
   wire [CKE_WIDTH-1:0]                 phy_init_cke;
   wire [CS_NUM-1:0]                    phy_init_cs_n;
   wire                                 phy_init_ras_n;
   wire                                 phy_init_we_n;
   
   wire                                 odt;
   wire [DQ_WIDTH-1:0]                  wr_data_rise;
   wire [DQ_WIDTH-1:0]                  wr_data_fall;
   wire [DM_WIDTH-1:0]                  mask_data_rise;
   wire [DM_WIDTH-1:0]                  mask_data_fall;
   wire                                 dq_oe_n;
   wire                                 dqs_oe_n;
   wire                                 dqs_rst_n;
   
   wire                                 rddata_clk_sel;// 0 -> pipeline rddata
                                                       //      on clk180
                                                       // 1 -> pipeline rddata
                                                       //      on clk0
   wire                                 rddata_swap_rise; // 0 -> first data in
                                                          //      rise position
                                                          // 1 -> first data in
                                                          //      fall position
   wire [3:0]                           rden_delay;    // Delay value for 
                                                       // phy_calib_rden.

   static_phy_control #
     (
      .C_RDDATA_CLK_SEL           (C_RDDATA_CLK_SEL),
      .C_RDEN_DELAY               (C_RDEN_DELAY),
      .C_RDDATA_SWAP_RISE         (C_RDDATA_SWAP_RISE),
      .C_NUM_REG                  (C_NUM_REG)
     )
     static_phy_control_0
       (
        .Clk              (clk0),
        .Rst              (rst0),
        .Reg_CE           (reg_ce),
        .Reg_In           (reg_in),
        .Reg_Out          (reg_out),
        .phy_init_done    (phy_init_done),
        .rden_delay       (rden_delay),
        .rddata_clk_sel   (rddata_clk_sel),
        .rddata_swap_rise (rddata_swap_rise),
        .dcm_en           (dcm_en),
        .dcm_incdec       (dcm_incdec),
        .dcm_done         (dcm_done)
        );
   
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
      .DDR2_ENABLE  (DDR2_ENABLE),
      .DQSN_ENABLE  (DQSN_ENABLE),
      .STATIC_PHY   (1),
      .SIM_ONLY     (SIM_ONLY)
      )
     static_phy_init_0
       (
        .clk0           (clk0),
        .clk180         (~clk0), // ***Clock for control registers***
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

   static_phy_iobs #
     (
      .FAMILY      (FAMILY),
      .BANK_WIDTH  (BANK_WIDTH),
      .CKE_WIDTH   (CKE_WIDTH),
      .COL_WIDTH   (COL_WIDTH),
      .CS_NUM      (CS_NUM),
      .CS_WIDTH    (CS_WIDTH),
      .ODT_WIDTH   (ODT_WIDTH),
      .ROW_WIDTH   (ROW_WIDTH),
      .CLK_WIDTH   (CLK_WIDTH),
      .DM_WIDTH    (DM_WIDTH),
      .DQS_WIDTH   (DQS_WIDTH),
      .DQ_WIDTH    (DQ_WIDTH),
      .DQSN_ENABLE (DQSN_ENABLE),
      .DDR2_ENABLE (DDR2_ENABLE)
      )
     static_phy_iobs_0
       (
        .clk0             (clk0),
        .clk90            (clk90),
        .clk0_rddata      (clk0_rddata),
        .rst0             (rst0),
        .rst90            (rst90),
        .rddata_clk_sel   (rddata_clk_sel),
        .rddata_swap_rise (rddata_swap_rise),
        .ctrl_addr        (ctrl_addr),
        .ctrl_ba          (ctrl_ba),
        .ctrl_ras_n       (ctrl_ras_n),
        .ctrl_cas_n       (ctrl_cas_n),
        .ctrl_we_n        (ctrl_we_n),
        .ctrl_cs_n        (ctrl_cs_n),
        .odt              (odt),
        .phy_init_addr    (phy_init_addr),
        .phy_init_ba      (phy_init_ba),
        .phy_init_ras_n   (phy_init_ras_n),
        .phy_init_cas_n   (phy_init_cas_n),
        .phy_init_we_n    (phy_init_we_n),
        .phy_init_cs_n    (phy_init_cs_n),
        .phy_init_cke     (phy_init_cke),
        .phy_init_done    (phy_init_done),
        .wr_data_rise     (wr_data_rise),
        .wr_data_fall     (wr_data_fall),
        .mask_data_rise   (mask_data_rise),
        .mask_data_fall   (mask_data_fall),
        .rd_data_rise     (rd_data_rise[DQ_WIDTH-1:0]),
        .rd_data_fall     (rd_data_fall[DQ_WIDTH-1:0]),
        .dq_oe_n          ({DQ_WIDTH{dq_oe_n}}),
        .dqs_oe_n         ({DQS_WIDTH{dqs_oe_n}}),
        .dqs_rst_n        ({DQS_WIDTH{dqs_rst_n}}),
        .ddr_addr         (ddr_addr),
        .ddr_ba           (ddr_ba),
        .ddr_ras_n        (ddr_ras_n),
        .ddr_cas_n        (ddr_cas_n),
        .ddr_we_n         (ddr_we_n),
        .ddr_cke          (ddr_cke),
        .ddr_cs_n         (ddr_cs_n),
        .ddr_odt          (ddr_odt),
        .ddr_ck           (ddr_ck),
        .ddr_ck_n         (ddr_ck_n),
        .ddr_dm           (ddr_dm),
        .ddr_dqs          (ddr_dqs),
        .ddr_dqs_n        (ddr_dqs_n),
        .ddr_dq           (ddr_dq)
        );
   
   static_phy_write #
     (
      .WDF_RDEN_EARLY (WDF_RDEN_EARLY),
      .WDF_RDEN_WIDTH (WDF_RDEN_WIDTH),
      .DQ_WIDTH       (DQ_WIDTH),
      .DM_WIDTH       (DM_WIDTH),
      .ADDITIVE_LAT   (ADDITIVE_LAT),
      .CAS_LAT        (CAS_LAT),
      .ECC_ENABLE     (ECC_ENABLE),
      .REG_ENABLE     (REG_ENABLE),
      .DDR2_ENABLE    (DDR2_ENABLE),
      .ODT_TYPE       (ODT_TYPE)
      )
     static_phy_write_0
       (
        .clk0           (clk0),
        .clk90          (clk90),
        .wdf_data       ({wdf_data[DQ_WIDTH+(DQS_WIDTH*DQ_PER_DQS)-1:DQS_WIDTH*DQ_PER_DQS],wdf_data[DQ_WIDTH-1:0]}),
        .wdf_mask_data  (wdf_mask_data),
        .ctrl_wren      (ctrl_wren),
        .phy_init_done  (phy_init_done),
        .dq_oe_n        (dq_oe_n),
        .dqs_oe_n       (dqs_oe_n),
        .dqs_rst_n      (dqs_rst_n),
        .wdf_rden       (wdf_rden),
        .odt            (odt),
        .wr_data_rise   (wr_data_rise),
        .wr_data_fall   (wr_data_fall),
        .mask_data_rise (mask_data_rise),
        .mask_data_fall (mask_data_fall)
        );

   static_phy_read #
     (
      .DQS_WIDTH (DQS_WIDTH)
      )
     static_phy_read_0
       (
        .clk0                 (clk0),
        .ctrl_rden            (ctrl_rden),
        .phy_calib_rden_delay (rden_delay),
        .phy_calib_rden       (phy_calib_rden)
        );
   
endmodule // static_phy_top

