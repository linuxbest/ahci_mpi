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
//Purpose: Write logic of Static Phy for MPMC
//Reference:
//Revision History:
//
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

//-----------------------------------------------------------------------------
// Module name:      static_phy_write
// Description:      Produces write related signals.
// Verilog-standard: Verilog 2001
//-----------------------------------------------------------------------------
module static_phy_write #
  (
   parameter integer WDF_RDEN_EARLY = 0,
   parameter integer WDF_RDEN_WIDTH = 1,
   parameter integer DQ_WIDTH       = 32,
   parameter integer DM_WIDTH       = 4,
   parameter integer ADDITIVE_LAT   = 0,
   parameter integer CAS_LAT        = 5,
   parameter integer ECC_ENABLE     = 0,
   parameter integer REG_ENABLE     = 0,
   parameter integer DDR2_ENABLE    = 1,
   parameter integer ODT_TYPE       = 1
   )
  (
   input  wire                             clk0,
   input  wire                             clk90,
   input  wire [(2*DQ_WIDTH)-1:0]          wdf_data,
   input  wire [(2*DM_WIDTH)-1:0]          wdf_mask_data,
   input  wire                             ctrl_wren,
   input  wire                             phy_init_done,
   output wire                             dq_oe_n,
   output wire                             dqs_oe_n,
   output wire                             dqs_rst_n,
   output wire [WDF_RDEN_WIDTH-1:0]        wdf_rden,
   output wire                             odt,
   output wire [DQ_WIDTH-1:0]              wr_data_rise,
   output wire [DQ_WIDTH-1:0]              wr_data_fall,
   output wire [DM_WIDTH-1:0]              mask_data_rise,
   output wire [DM_WIDTH-1:0]              mask_data_fall   
   );
   
  // (MIN,MAX) value of WR_LATENCY for DDR1:
  //   REG_ENABLE   = (0,1)
  //   ECC_ENABLE   = (0,1)
  //   Write latency = 1
  //   Total: (1,3)
  // (MIN,MAX) value of WR_LATENCY for DDR2:
  //   REG_ENABLE   = (0,1)
  //   ECC_ENABLE   = (0,1)
  //   Write latency = ADDITIVE_CAS + CAS_LAT - 1 = (0,4) + (3,5) - 1 = (2,8)
  //     ADDITIVE_LAT = (0,4) (JEDEC79-2B)
  //     CAS_LAT      = (3,5) (JEDEC79-2B)
  //   Total: (2,10) 
  localparam WR_LATENCY = (DDR2_ENABLE) ? 
             (1 + ADDITIVE_LAT + (CAS_LAT-1) + REG_ENABLE + ECC_ENABLE + ECC_ENABLE) : 
             (2 + REG_ENABLE + ECC_ENABLE + ECC_ENABLE);
   
   wire                     dq_oe_0;
   reg                      dq_oe_n_90_r1 = 0;
   reg                      dq_oe_n_90_r2 = 0;
   reg                      dq_oe_n_270 = 0;
   wire                     dqs_oe_0;
   reg                      dqs_oe_n_180_r1 = 0;
   reg                      dqs_oe_n_180_r2 = 0;
   reg                      dqs_oe_270 = 0;
   wire                     dqs_rst_0;
   reg                      dqs_rst_n_180_r1 = 0;
   reg                      dqs_rst_n_180_r2 = 0;
   reg                      dqs_rst_270 = 0;
   wire                     odt_0;
   reg                      phy_init_done_r = 0;
   wire                     wdf_rden_0;
   reg [WDF_RDEN_WIDTH-1:0] wdf_rden_0_r1 = 0;
   reg [10:0]               wr_stages = 0;

  //***************************************************************************
  // Analysis of additional pipeline delays:
  //   1. dq_oe (DQ 3-state): 1 CLK90 cyc in IOB 3-state FF
  //   2. dqs_oe (DQS 3-state): 1 CLK180 cyc in IOB 3-state FF
  //   3. dqs_rst (DQS output value reset): 1 CLK180 cyc in FF + 1 CLK180 cyc
  //      in IOB DDR
  //   4. odt (ODT control): 1 CLK0 cyc in IOB FF
  //   5. write data (output two cyc after wdf_rden - output of RAMB_FIFO w/
  //      output register enabled): 2 CLK90 cyc in OSERDES
  //***************************************************************************

  // DQS 3-state must be asserted one extra clock cycle due b/c of write
  // pre- and post-amble (extra half clock cycle for each)
  assign dqs_oe_0      = wr_stages[WR_LATENCY-1] | wr_stages[WR_LATENCY];

  // same goes for ODT, need to handle both pre- and post-amble (generate
  // ODT only for DDR2)
  generate
    if (DDR2_ENABLE) begin: gen_odt_ddr2
      assign odt_0 = (ODT_TYPE == 0) ? 1'b0 : 
                     (REG_ENABLE == 0) ?  (wr_stages[WR_LATENCY-1] | wr_stages[WR_LATENCY]) : 
                     (wr_stages[WR_LATENCY-2] | wr_stages[WR_LATENCY-1]);
    end else begin: gen_odt_ddr1
       assign odt_0 = 1'b0;
    end
  endgenerate
    
  assign dq_oe_0       = wr_stages[WR_LATENCY];
  assign dqs_rst_0     = ~wr_stages[WR_LATENCY-1];
  generate 
    if (WDF_RDEN_EARLY==1) begin: gen_wdf_rden_early
      assign wdf_rden_0    = wr_stages[WR_LATENCY-2-ECC_ENABLE-ECC_ENABLE];
    end
    else begin: gen_wdf_rden_normal
      assign wdf_rden_0    = wr_stages[WR_LATENCY-1-ECC_ENABLE-ECC_ENABLE];
    end
  endgenerate

  always@(posedge clk0)
    phy_init_done_r <= phy_init_done;
  
  // first stage isn't registered
  always @(*)
    wr_stages[0] <= ctrl_wren;
  // synthesis attribute max_fanout of wr_stages is 1
  always @(posedge clk0) begin
    wr_stages[1] <= wr_stages[0];
    wr_stages[2] <= wr_stages[1];
    wr_stages[3] <= wr_stages[2];
    wr_stages[4] <= wr_stages[3];
    wr_stages[5] <= wr_stages[4];
    wr_stages[6] <= wr_stages[5];
    wr_stages[7] <= wr_stages[6];
    wr_stages[8] <= wr_stages[7];
    wr_stages[9] <= wr_stages[8];
    wr_stages[10] <= wr_stages[9];
  end

  // intermediate synchronization to CLK270
  // synthesis attribute max_fanout of  dq_oe_n_270 is 1
  // synthesis attribute max_fanout of  dqs_oe_270 is 1
  always @(negedge clk90) begin
    dq_oe_n_270       <= ~dq_oe_0;
    dqs_oe_270        <= dqs_oe_0;
    dqs_rst_270       <= dqs_rst_0;
  end

  // synchronize DQS signals to CLK180
  // synthesis attribute max_fanout of dqs_oe_n_180_r1 is 1
  // synthesis attribute max_fanout of dqs_rst_n_180_r1 is 1
  always @(negedge clk0) begin
    dqs_oe_n_180_r1  <= ~dqs_oe_270;
    dqs_oe_n_180_r2  <= dqs_oe_n_180_r1;
    dqs_rst_n_180_r1 <= ~dqs_rst_270;
    dqs_rst_n_180_r2 <= dqs_rst_n_180_r1;
  end

  // All write data-related signals synced to CLK90
  // synthesis attribute max_fanout of dq_oe_n_90_r1 is 1  
  always @(posedge clk90) begin
    dq_oe_n_90_r1  <= dq_oe_n_270;
    dq_oe_n_90_r2  <= dq_oe_n_90_r1;
  end

  always @(posedge clk0) begin
    wdf_rden_0_r1  <= {WDF_RDEN_WIDTH{wdf_rden_0}};
  end
   
  //***************************************************************************

  // synthesis attribute max_fanout of dq_oe_n is 1
  assign dq_oe_n   = dq_oe_n_90_r2;
 // synthesis attribute max_fanout of dqs_oe_n is 1  
  assign dqs_oe_n  = dqs_oe_n_180_r2;
  assign dqs_rst_n = dqs_rst_n_180_r2;
  assign odt       = odt_0;
  assign wdf_rden  = wdf_rden_0_r1;

  //***************************************************************************
  // Format write data/mask: Data is in format: {fall, rise}
  //***************************************************************************
  
  assign wr_data_rise = wdf_data[DQ_WIDTH-1:0];
  assign wr_data_fall = wdf_data[(2*DQ_WIDTH)-1:DQ_WIDTH];  
  assign mask_data_rise = wdf_mask_data[DM_WIDTH-1:0];
  assign mask_data_fall = wdf_mask_data[(2*DM_WIDTH)-1:DM_WIDTH];
     
endmodule // static_phy_write



