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

module phy_top_sdram #(
   parameter C_FAMILY                           = "virtex4",
   parameter         C_RDDATA_CLK_SEL           = 1'b1,
   parameter integer C_RDEN_DELAY               = 0,
   parameter         C_RDDATA_SWAP_RISE         = 0,
   parameter         C_NUM_REG                  = 0,
   parameter integer WDF_RDEN_EARLY             = 0,
   parameter integer WDF_RDEN_WIDTH             = 1,
   parameter BANK_WIDTH                         = 2,
   parameter CLK_WIDTH                          = 1,
   parameter CKE_WIDTH                          = 1,
   parameter COL_WIDTH                          = 10,
   parameter CS_NUM                             = 1,
   parameter CS_WIDTH                           = 1,
   parameter DM_WIDTH                           = 2,
   parameter DQ_WIDTH                           = 16,
   parameter ROW_WIDTH                          = 13,   
   parameter BURST_LEN                          = 4,   
   parameter BURST_TYPE                         = 0,
   parameter CAS_LAT                            = 5,
   parameter ECC_ENABLE                         = 0,   
   parameter REG_ENABLE                         = 0,
   parameter SIM_ONLY                           = 0
   )
  (
   input  wire                            clk0,
   input  wire                            rst0,
   input  wire                            clk0_rddata,

   ////////////////////////////////////////////////////////////////////////////
   //Static PHY interface
   output wire                            dcm_en,
   output wire                            dcm_incdec,
   input  wire                            dcm_done,
   input  wire [C_NUM_REG-1:0]            reg_ce,
   input  wire [31:0]                     reg_in,
   output wire [C_NUM_REG*32-1:0]         reg_out,

   input  wire                            ctrl_wren,
   input  wire [ROW_WIDTH-1:0]            ctrl_addr,
   input  wire [BANK_WIDTH-1:0]           ctrl_ba,
   input  wire                            ctrl_ras_n,
   input  wire                            ctrl_cas_n,
   input  wire                            ctrl_we_n,
   input  wire [CS_NUM-1:0]               ctrl_cs_n,
   input  wire                            ctrl_rden,
   input  wire                            ctrl_ref_flag,
   input  wire [DQ_WIDTH-1:0]             wdf_data,
   input  wire [(DM_WIDTH)-1:0]           wdf_mask_data,
   output wire [WDF_RDEN_WIDTH-1:0]       wdf_rden,
   output wire                            phy_init_done,
   output wire [0:0]                      phy_calib_rden,
   output wire [DQ_WIDTH-1:0]             rd_data_rise,
   output wire [CLK_WIDTH-1:0]            sdram_ck,
   output wire [ROW_WIDTH-1:0]            sdram_addr,
   output wire [BANK_WIDTH-1:0]           sdram_ba,
   output wire                            sdram_ras_n,
   output wire                            sdram_cas_n,
   output wire                            sdram_we_n,
   output wire [CS_WIDTH-1:0]             sdram_cs_n,
   output wire [CKE_WIDTH-1:0]            sdram_cke,
   output wire [DM_WIDTH-1:0]             sdram_dm,
   inout  wire [DQ_WIDTH-1:0]             sdram_dq
   );  

  wire                    phy_init_done_int;
  wire [3:0]              calib_done;
  wire [3:0]              calib_start;
  wire                    dq_oe_n;

  wire [DM_WIDTH-1:0]     mask_data_rise;
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

  
  static_phy_control # (
    .C_RDDATA_CLK_SEL           (C_RDDATA_CLK_SEL),
    .C_RDEN_DELAY               (C_RDEN_DELAY),
    .C_RDDATA_SWAP_RISE         (C_RDDATA_SWAP_RISE),
    .C_NUM_REG                  (C_NUM_REG)
   ) CTRL (
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
  
  
   
  assign phy_init_done = phy_init_done_int;
  
  phy_write_sdram #
    (
     .WDF_RDEN_EARLY (WDF_RDEN_EARLY),
     .WDF_RDEN_WIDTH (WDF_RDEN_WIDTH),
     .DQ_WIDTH     (DQ_WIDTH), 
     .DM_WIDTH     (DM_WIDTH), 
     .CAS_LAT      (CAS_LAT),
     .ECC_ENABLE   (ECC_ENABLE),
     .REG_ENABLE   (REG_ENABLE)
     )
    u_phy_write
      (
       .clk0               (clk0),
       .wdf_data           (wdf_data),
       .wdf_mask_data      (wdf_mask_data),
       .ctrl_wren          (ctrl_wren),
       .dq_oe_n            (dq_oe_n),
       .wdf_rden           (wdf_rden),
       .wr_data_rise       (wr_data_rise),
       .mask_data_rise     (mask_data_rise)
       );
  
  phy_io_sdram # (
    .DM_WIDTH       (DM_WIDTH),
    .DQ_WIDTH       (DQ_WIDTH),
    .CAS_LAT        (CAS_LAT),
    .ECC_ENABLE     (ECC_ENABLE),      
    .REG_ENABLE     (REG_ENABLE)
  ) u_phy_io (
    .clk0                 (clk0),
    .clk0_rddata          (clk0_rddata),
    .dq_oe_n              (dq_oe_n),
    .ctrl_rden            (ctrl_rden),
    .rddata_clk_sel       (rddata_clk_sel),
    .calib_rden           (),
    .wr_data_rise         (wr_data_rise),
    .mask_data_rise       (mask_data_rise),
    .rd_data_rise         (rd_data_rise),
    .sdram_dm             (sdram_dm),
    .sdram_dq             (sdram_dq)
  );

  static_phy_read #(
    .DQS_WIDTH (1)
  ) RD_DLY (
    .clk0                 (clk0),
    .ctrl_rden            (ctrl_rden),
    .phy_calib_rden_delay (rden_delay),
    .phy_calib_rden       (phy_calib_rden)
  );


  phy_ctl_io_sdram #
    (
     .C_FAMILY    (C_FAMILY),
     .CLK_WIDTH   (CLK_WIDTH),
     .BANK_WIDTH  (BANK_WIDTH),
     .CKE_WIDTH   (CKE_WIDTH),
     .COL_WIDTH   (COL_WIDTH),
     .CS_NUM      (CS_NUM),
     .CS_WIDTH    (CS_WIDTH),
     .ROW_WIDTH   (ROW_WIDTH)
     ) 
    u_phy_ctl_io
      (
       .clk0             (clk0),
       .rst0             (rst0),
       .ctrl_addr        (ctrl_addr),
       .ctrl_ba          (ctrl_ba),
       .ctrl_ras_n       (ctrl_ras_n),
       .ctrl_cas_n       (ctrl_cas_n),
       .ctrl_we_n        (ctrl_we_n),
       .ctrl_cs_n        (ctrl_cs_n),
       .phy_init_addr    (phy_init_addr),
       .phy_init_ba      (phy_init_ba),
       .phy_init_ras_n   (phy_init_ras_n),
       .phy_init_cas_n   (phy_init_cas_n),
       .phy_init_we_n    (phy_init_we_n),
       .phy_init_cs_n    (phy_init_cs_n),
       .phy_init_cke     (phy_init_cke),
       .phy_init_done    (phy_init_done_int),
       .sdram_ck         (sdram_ck),
       .sdram_addr       (sdram_addr),
       .sdram_ba         (sdram_ba),
       .sdram_ras_n      (sdram_ras_n),
       .sdram_cas_n      (sdram_cas_n),
       .sdram_we_n       (sdram_we_n),
       .sdram_cke        (sdram_cke),
       .sdram_cs_n       (sdram_cs_n)
       );
  
  phy_init_sdram #
    (
     .DQ_WIDTH     (DQ_WIDTH),
     .BANK_WIDTH   (BANK_WIDTH),
     .CKE_WIDTH    (CKE_WIDTH),
     .COL_WIDTH    (COL_WIDTH),
     .CS_NUM       (CS_NUM),
     .ROW_WIDTH    (ROW_WIDTH),
     .BURST_LEN    (BURST_LEN),
     .BURST_TYPE   (BURST_TYPE),
     .CAS_LAT      (CAS_LAT),
     .REG_ENABLE   (REG_ENABLE),
     .ECC_ENABLE   (ECC_ENABLE),
     .SIM_ONLY     (SIM_ONLY)
     )
    u_phy_init
      (
       .clk0                (clk0),
       .rst0                (rst0),
       .ctrl_ref_flag       (ctrl_ref_flag),
       .phy_init_addr       (phy_init_addr),
       .phy_init_ba         (phy_init_ba),
       .phy_init_ras_n      (phy_init_ras_n),
       .phy_init_cas_n      (phy_init_cas_n),
       .phy_init_we_n       (phy_init_we_n),
       .phy_init_cs_n       (phy_init_cs_n),
       .phy_init_cke        (phy_init_cke),
       .phy_init_done       (phy_init_done_int)
       );
  
endmodule
