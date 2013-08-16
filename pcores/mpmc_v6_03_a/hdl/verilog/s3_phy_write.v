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
// MPMC Spartam3 MIG PHY Data Write
//-------------------------------------------------------------------------
//
// Description:
//   Handles delaying various write control signals appropriately depending 
//   on CAS latency, additive latency, etc. Also splits the data and mask in
//   rise and fall buses. 
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
//
//--------------------------------------------------------------------------

`timescale 1ns/1ps

module s3_phy_write #
  (   
   parameter integer DQ_BITS            = 16,
   parameter integer DM_WIDTH           = 4,
   parameter integer DQ_PER_DQS         = 8,
   parameter integer DQS_WIDTH          = 4,
   parameter integer ODT_WIDTH          = 1,
   parameter integer CS_NUM             = 1,
   parameter integer ADDITIVE_LAT       = 0,
   parameter integer CAS_LAT            = 3,
   parameter integer ECC_ENABLE         = 0,
   parameter integer ODT_TYPE           = 0,
   parameter integer REG_ENABLE         = 0,
   parameter integer DDR2_ENABLE        = 1,                    // 1 = DDR2, 0 = DDR memory type
   parameter             WDF_RDEN_EARLY = 1,                    // By default, PHY should use early RdEn on WDF
   parameter integer WDF_RDEN_WIDTH = 1
   )
  (
   input                                   clk0,
   input                                   clk90,
   input                                   rst0,
   input                                   rst90,
   input [(2*DQS_WIDTH*DQ_PER_DQS)-1:0]    wdf_data,
   input [(2*DM_WIDTH)-1:0]                wdf_mask_data,
   input                                   ctrl_wren,
   input [CS_NUM-1:0]                      ctrl_cs_n,
   input                                   phy_init_done,
   output                                  dq_oe,
   output [(DQ_BITS/DQ_PER_DQS)-1:0]       dqs_oe,
   output [(DQ_BITS/DQ_PER_DQS)-1:0]       dqs_rst,
   output reg [WDF_RDEN_WIDTH-1:0]         wdf_rden,
   output     [ODT_WIDTH-1:0]              odt,
   output reg [(DQS_WIDTH*DQ_PER_DQS)-1:0] wr_data_rise,
   output reg [(DQS_WIDTH*DQ_PER_DQS)-1:0] wr_data_fall,
   output reg [DM_WIDTH-1:0]               mask_data_rise,
   output reg [DM_WIDTH-1:0]               mask_data_fall
   );

  localparam DQ_WIDTH = DQS_WIDTH * DQ_PER_DQS;

  // (MIN,MAX) value of WR_LATENCY for DDR2:
  //   ADDITIVE_LAT = (0,4) (JEDEC79-2B)
  //   CAS_LAT      = (3,5) (JEDEC79-2B)
  //   REG_ENABLE   = (0,1)
  //   ECC_ENABLE   = (0,1)
  //   Total: (3,11)   
  
  //coverage off
  //localparam WR_LATENCY = (DDR2_ENABLE == 1) ? (ADDITIVE_LAT + CAS_LAT + REG_ENABLE + ECC_ENABLE + 1) : (REG_ENABLE + 3);
  localparam WR_LATENCY = (DDR2_ENABLE == 1) ? (ADDITIVE_LAT + CAS_LAT + REG_ENABLE + 1) : (REG_ENABLE + 3);
  //coverage on
  
  wire                           dq_oe_0;
  reg                            dq_oe_90_r1;
  reg                            dq_oe_90_r2/* synthesis syn_maxfan = 6 */;
  reg                            dq_oe_270/* synthesis syn_maxfan = 9 */;
  
  wire                           dqs_oe_0;
  reg                            dqs_oe_180_r1;
  reg [(DQ_BITS/DQ_PER_DQS)-1:0] dqs_oe_180_r2;
  // synthesis attribute equivalent_register_removal of dqs_oe_180_r2 is "no";
  reg                            dqs_oe_270;
  
  wire                           dqs_rst_0;
  reg                            dqs_rst_180_r1;
  reg [(DQ_BITS/DQ_PER_DQS)-1:0] dqs_rst_180_r2;
  // synthesis attribute equivalent_register_removal of dqs_rst_180_r2 is "no";
  reg                            dqs_rst_270;
  
  reg [CS_NUM-1:0]               ctrl_cs_270;
  reg                            odt_270;
  reg [ODT_WIDTH-1:0]            odt_180;
  wire                           wdf_rden_0;
  
  reg [(WR_LATENCY+1):0]         wr_stages;
  reg                            phy_init_done_r;
  reg                            phy_init_done_r_270;
  
  reg                            rst270;
  reg                            rst180;
       
  //generate rst270 to improve timing on reset paths to FFs clocked on clk270
  always @(negedge clk90)
    rst270 <= rst0;
  
  //generate rst180 to improve timing on reset paths to FFs clocked on clk180
  always @(negedge clk0)
    rst180 <= rst0;
  
  
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
  generate
    if (ECC_ENABLE==1) begin : gen_ecc_dqs_oe
      assign dqs_oe_0 = wr_stages[WR_LATENCY-0] | wr_stages[WR_LATENCY+1];
    end else begin : gen_noecc_dqs_oe
      assign dqs_oe_0 = wr_stages[WR_LATENCY-2] | wr_stages[WR_LATENCY-1];
    end
  endgenerate
  
  // Add generate to only create ODT logic for DDR2 memories
  generate
    genvar odt_i_rep;
    genvar odt_i;
    if (DDR2_ENABLE == 1) begin: gen_odt
      if (ECC_ENABLE==1) begin : gen_ecc_odt
        always @(negedge clk90)
          odt_270 <= (ODT_TYPE == 0) ? 1'b0 :
                     (REG_ENABLE == 0) ? (wr_stages[WR_LATENCY-1] | wr_stages[WR_LATENCY-0]) : 
                     (wr_stages[WR_LATENCY-2] | wr_stages[WR_LATENCY-1]) ; 
      end else begin : gen_noecc_odt
        always @(negedge clk90)
          odt_270 <= (ODT_TYPE == 0) ? 1'b0 : 
                     (REG_ENABLE == 0) ? (wr_stages[WR_LATENCY-3] | wr_stages[WR_LATENCY-2]) : 
                     (wr_stages[WR_LATENCY-4] | wr_stages[WR_LATENCY-3]) ;  
      end
      always @(negedge clk90)
        phy_init_done_r_270 <= phy_init_done_r;
      always @(negedge clk90)
        ctrl_cs_270 <= ~ctrl_cs_n;
      // Need to assign a initialization value for ODT
      for (odt_i_rep=0;odt_i_rep<ODT_WIDTH/CS_NUM;odt_i_rep=odt_i_rep+1) begin : gen_odt_rep
        for (odt_i=0;odt_i<CS_NUM;odt_i=odt_i+1) begin : gen_odt
          always @(negedge clk0)
            odt_180[odt_i_rep*CS_NUM+odt_i] <= (phy_init_done_r_270) ? odt_270 & ctrl_cs_270[odt_i] : 1'b0;
        end
      end
      assign odt = odt_180;
    end
    else begin: gen_no_odt
      assign odt = 1'b0; 
    end
  endgenerate
  
  
  // NOTE: Need to drive DQ one half cycle earlier (only if removal of 3-state
  // takes longer than output switching time)
  generate
    if (ECC_ENABLE==1) begin : gen_ecc_dq_oe
      assign dq_oe_0 = wr_stages[WR_LATENCY+1];
    end else begin : gen_noecc_dq_oe
      assign dq_oe_0 = wr_stages[WR_LATENCY-1];
    end
  endgenerate
  
  // Only need to generate a clock cycle pulse on DQS reset
  generate
    if (ECC_ENABLE==1) begin : gen_ecc_dqs_rst
      assign dqs_rst_0 = (wr_stages[WR_LATENCY-0] && ~wr_stages[WR_LATENCY+1]) ? 1'b0 : 1'b1;
    end else begin : gen_noecc_dqs_rst
      assign dqs_rst_0 = (wr_stages[WR_LATENCY-2] && ~wr_stages[WR_LATENCY-1]) ? 1'b0 : 1'b1;
    end
  endgenerate
  
  generate
    
    // If memory is DDR2 & 16-bits wide or 
    // If memory is DDR & 8-bits or 16-bits or 32-bits wide
    if ((DQ_BITS == 16) || (DDR2_ENABLE == 0)) begin: gen_rden
      
      // Remove TML data path register stage
      // To improve data_path to PHY timing paths
      // Need to assert the wdf_rden a clock earlier
      if (WDF_RDEN_EARLY == 1) begin: gen_rden_early
        
        // If WR_LATENCY = 3 (smallest allowable value for DDR memory)
        // Avoid the -1 array index here
        if (WR_LATENCY == 3) begin: gen_non_early_reg
          assign wdf_rden_0 = wr_stages[WR_LATENCY-3];  // to minimize output register stages
                        end
        else begin: gen_early_reg
          assign wdf_rden_0 = wr_stages[WR_LATENCY-4];  // to minimize output register stages
        end
        
      end
      else begin: gen_rden_later
        // Changes made with additional 2nd reg stage
        assign wdf_rden_0 = wr_stages[WR_LATENCY-3];    // to minimize output register stages
        
      end
      
    end
    else begin: gen_rden_ddr2
      
      if (WDF_RDEN_EARLY == 1) begin: gen_rden_early
        
        // Note: Incur extra latency here due to Force_DM changes in Cntrl
        // when DDR data width = 32
        assign wdf_rden_0 = wr_stages[WR_LATENCY-4];    // to minimize output register stages
      end
      else begin: gen_rden_later
        assign wdf_rden_0 = wr_stages[WR_LATENCY-3];    // to minimize output register stages
      end
    end  
  endgenerate    
  
  always @(posedge clk0) begin
    if (rst0) phy_init_done_r <= 1'b0;
    else phy_init_done_r <= phy_init_done;   
  end 
  
  // first stage isn't registered
  always @(*)
    
    // Need default state for wr_stages[0] to allow odt_0 output
    // to drive a default value
    wr_stages[0] <= (phy_init_done_r) ? ctrl_wren : 1'b0;
  
  // Change this to a generate to reduce logic that is created
  generate
    genvar wr_i;
    for (wr_i = 0; wr_i <= WR_LATENCY; wr_i = wr_i + 1)
      begin: gen_wr_stages
        
        always @(posedge clk0) begin
          if (rst0) wr_stages[wr_i+1] <= 1'b0;
          else wr_stages[wr_i+1] <= wr_stages[wr_i];
        end
    end
  endgenerate
  
  // intermediate synchronization to CLK270
  always @(negedge clk90) begin
    if (rst270) begin
      dq_oe_270 <= 1'b0;
      dqs_oe_270 <= 1'b0;
      dqs_rst_270 <= 1'b0;
    end
    else begin
      dq_oe_270 <= dq_oe_0;
      dqs_oe_270 <= dqs_oe_0;
      dqs_rst_270 <= dqs_rst_0;
    end
  end

  // synthesis attribute max_fanout of dqs_rst_180_r1 is 1
  // synthesis attribute max_fanout of dqs_oe_180_r1 is 1
  // synchronize DQS signals to CLK180
  always @(negedge clk0) begin
    if (rst180) begin
      dqs_oe_180_r1 <= 1'b1;
      dqs_rst_180_r1 <= 1'b1;
    end
    else begin  
      dqs_oe_180_r1 <= ~dqs_oe_270;
      dqs_rst_180_r1 <= ~dqs_rst_270;
    end
    dqs_oe_180_r2 <= {DQ_BITS/DQ_PER_DQS{dqs_oe_180_r1}};
    dqs_rst_180_r2 <= {DQ_BITS/DQ_PER_DQS{dqs_rst_180_r1}};
  end
  
  // All write data-related signals synced to CLK90
  // synthesis attribute max_fanout of dq_oe_90_r1 is 1
  always @(posedge clk90) begin
    if (rst90) dq_oe_90_r1<= 1'b1;
    else dq_oe_90_r1<= ~dq_oe_270;
    dq_oe_90_r2 <= dq_oe_90_r1;
  end
  
  assign dq_oe = dq_oe_90_r2;
  assign dqs_oe = dqs_oe_180_r2;
  assign dqs_rst = dqs_rst_180_r2;
  
  // Create registered vectorized signal
  // If WR_LATENCY = 3 then don't register wdf_rden signal here
  generate
    genvar wdf_rden_i;
    for (wdf_rden_i = 0; wdf_rden_i <= (WDF_RDEN_WIDTH-1); wdf_rden_i = wdf_rden_i + 1)
      begin: gen_wdf_rden
        
        // Added this since had to make wdf_rden_0 index 0 instead of -1
        if (((DQ_BITS == 16) || (DDR2_ENABLE == 0)) && (WDF_RDEN_EARLY == 1) && (WR_LATENCY == 3))
          always @(*) begin
            wdf_rden[wdf_rden_i] <= wdf_rden_0;
          end
        else begin
          always @(posedge clk0) begin
            if (rst0) wdf_rden[wdf_rden_i] <= 1'b0;
            else wdf_rden[wdf_rden_i] <= wdf_rden_0;    
          end
        end
      end
  endgenerate
  
  // Data is registered out of BRAM or SRL FIFOs on Clk270, so
  // reregister here on Clk90 to align for IOB
  always @(posedge clk90) begin
    if (rst90) begin    
      wr_data_rise = 32'd0;
      wr_data_fall = 32'd0;
      mask_data_rise = 4'd0;
      mask_data_fall = 4'd0;
    end
    else begin  
      wr_data_fall = wdf_data [(2*DQS_WIDTH*DQ_PER_DQS)-1:(DQS_WIDTH*DQ_PER_DQS)];
      wr_data_rise = wdf_data [(DQS_WIDTH*DQ_PER_DQS)-1:0];
      mask_data_fall = wdf_mask_data [(2*DM_WIDTH)-1:DM_WIDTH];
      mask_data_rise = wdf_mask_data [DM_WIDTH-1:0];
    end
  end
  
endmodule
