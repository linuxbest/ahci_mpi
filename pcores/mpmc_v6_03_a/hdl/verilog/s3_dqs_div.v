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
// MPMC Spartam3 MIG PHY DQS div
//-------------------------------------------------------------------------
//
// Description:
//   Generates the rst_dqs_div signal necessary for DQS
//   calibration on read cycles.  Previously generated
//   in S3A controller, but needs to be part of phy logic.
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
//   Jul 18 2008: Merged MIG 2.3 modifications into this file.
//
//--------------------------------------------------------------------------

`timescale 1ns/100ps

module s3_dqs_div #
  (
   parameter integer BURST_LEN     = 4, // Burst length = 4 (or 8)   
   parameter integer CAS_LAT       = 3, // Memory read CAS latency
   parameter integer REG_ENABLE    = 0,
   parameter integer ADDITIVE_LAT  = 0,
   parameter integer DDR2_ENABLE   = 1  // 1 = DDR2, 0 = DDR memory type
   )
  (
   input clk0,
   input rst0,
   input phy_init_done,
   input ctrl_rden,
   output rst_dqs_div_int,
   output reg read_fifo_rden
   );

  // Max read stages = (if registered DIMM) + (max CAS latency)
  // Add 2 to account for control signals registered out in IOB 
  // plus DQS preamble during a read operation
  
  // coverage off
  localparam MAX_RD_STAGES = (DDR2_ENABLE == 1) ? (REG_ENABLE + CAS_LAT + ADDITIVE_LAT) : (REG_ENABLE + CAS_LAT);
  localparam MAX_RD_STAGES_RDEN = (DDR2_ENABLE == 1) ? (1 + CAS_LAT + ADDITIVE_LAT) : (1 + CAS_LAT);
  // coverage on
  
  reg [MAX_RD_STAGES:0] rd_stages;
  reg 			read_fifo_rden_i;
  
  // Don't register first stage of read cycle indicator
  always @(*)
    rd_stages[0] <= (phy_init_done) ? (ctrl_rden) : 1'b0;
  
  genvar rd_i;
  generate
    for(rd_i = 0; rd_i < MAX_RD_STAGES; rd_i = rd_i+1) begin: gen_rd_stages
      
      always @(posedge clk0) begin
        rd_stages[rd_i + 1] <= rd_stages[rd_i];
      end
    end
  endgenerate
  
  // LOC register that feeds IOB to a close slice
  FDR  dqs_rst_ff
    (
     .Q (rst_dqs_div_iob),     
     .D (rd_stages[MAX_RD_STAGES-1]),   
     .C (clk0),
     .R (rst0)
     ); 
  
  // Use MAX_RD_STAGES + 2 to account for control signals
  // registered out in IOB AND
  // DQS preamble during a read operation
  
  // LOC down component to IOB
  (* IOB = "FORCE" *) FDR  dqs_rst_iob
    (
     .Q (rst_dqs_div_int),     
     .D (rst_dqs_div_iob),   
     .C (clk0),
     .R (rst0)
     );

  // read_fifo_rden logic
   always @(posedge clk0)   begin
     if (rst0) begin
       read_fifo_rden_i <= 1'b0;
       read_fifo_rden <= 1'b0;
     end else begin
       read_fifo_rden_i <= rd_stages[MAX_RD_STAGES_RDEN-1];
       read_fifo_rden <= read_fifo_rden_i;
     end
   end
  
endmodule 

