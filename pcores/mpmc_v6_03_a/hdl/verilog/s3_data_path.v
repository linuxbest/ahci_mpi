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
// MPMC Spartam3 MIG PHY Data Path
//-------------------------------------------------------------------------
//
// Description:
//   This module comprises the write and read data paths for the
//   DDR1 memory interface. The write data along with write enable 
//   signals are forwarded to the DDR IOB FFs. The read data is 
//   captured in CLB FFs and finally input to FIFOs.
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

module s3_data_path #
  (
   parameter integer DQS_WIDTH     = 8,         // # of DQS strobes
   parameter integer DQ_BITS       = 5,         // # of data bits 
   parameter integer DQ_PER_DQS    = 8,         // # of DQ data bits per strobe
   parameter integer SIM_ONLY      = 0,
   parameter         C_FAMILY      = "spartan3",// Allowed Values: spartan3, spartan3e, spartan3a
   parameter integer C_SPECIAL_BOARD = 0,       // Allowed Values: 0 = use default settings, 
                                                //                 1 = special placement
   parameter integer C_DEBUG_EN      = 0
   )
  (
   input                      clk0,
   input                      clk90,
   input                      clk180,
   input                      rst,
   input                      rst90,
   input                      rst_dqs_div_in,
   input [4:0]                delay_sel,  
   input                      rst_rd_fifo,
   input [(DQS_WIDTH-1):0]    dqs_int_delay_in,
   input                      read_fifo_rden,
   input [(DQ_BITS-1):0]      dq,   
   output                     user_data_valid,
   output [((DQ_BITS*2)-1):0] user_output_data,
   //debug_signals
   input [4:0]                vio_out_dqs,
   input                      vio_out_dqs_en,
   input [4:0]                vio_out_rst_dqs_div,
   input                      vio_out_rst_dqs_div_en
   );  
  
  wire [(DQS_WIDTH-1):0]      fifo_0_wr_en/* synthesis syn_keep=1 */;
  wire [(DQS_WIDTH-1):0]      fifo_1_wr_en/* synthesis syn_keep=1 */;
  
  wire [(DQS_WIDTH-1):0]      dqs_delayed_col0;
  wire [(DQS_WIDTH-1):0]      dqs_delayed_col1;
  
  s3_data_read #
    (
     .DQS_WIDTH       (DQS_WIDTH),
     .DQ_BITS         (DQ_BITS),
     .DQ_PER_DQS      (DQ_PER_DQS),
     .SIM_ONLY        (SIM_ONLY),
     .C_FAMILY        (C_FAMILY),
     .C_SPECIAL_BOARD (C_SPECIAL_BOARD)
     )
    data_read
      (
       .clk0             (clk0),
       .clk90            (clk90),
       .clk180           (clk180),
       .rst              (rst),
       .rst90            (rst90),
       .ddr_dq_in        (dq),
       .fifo_0_wr_en     (fifo_0_wr_en),
       .fifo_1_wr_en     (fifo_1_wr_en),
       .rst_dqs_div_in   (rst_dqs_div_in), 
       .rst_rd_fifo      (rst_rd_fifo),
       .dqs_delayed_col0 (dqs_delayed_col0),
       .dqs_delayed_col1 (dqs_delayed_col1), 
       .read_fifo_rden   (read_fifo_rden), 
       .user_output_data (user_output_data),
       .user_data_valid  (user_data_valid)          
       );
  
  s3_data_read_controller #
    (
     .DQS_WIDTH       (DQS_WIDTH),
     .SIM_ONLY        (SIM_ONLY),
     .C_FAMILY        (C_FAMILY),
     .C_SPECIAL_BOARD (C_SPECIAL_BOARD),
     .C_DEBUG_EN      (C_DEBUG_EN)
     )
    data_read_controller
      (
       .rst                    (rst),
       .rst_dqs_div_in         (rst_dqs_div_in), 
       .delay_sel              (delay_sel),            
       .dqs_int_delay_in       (dqs_int_delay_in),                            
       .fifo_0_wr_en_val       (fifo_0_wr_en),
       .fifo_1_wr_en_val       (fifo_1_wr_en),    
       .dqs_delayed_col0_val   (dqs_delayed_col0),
       .dqs_delayed_col1_val   (dqs_delayed_col1),
       //debug_signals
       .vio_out_dqs            (vio_out_dqs),   
       .vio_out_dqs_en         (vio_out_dqs_en),   
       .vio_out_rst_dqs_div    (vio_out_rst_dqs_div),
       .vio_out_rst_dqs_div_en (vio_out_rst_dqs_div_en)
       );
  
endmodule 

