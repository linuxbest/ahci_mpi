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
// MPMC Spartam3 MIG PHY Infrastructure
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
//   Dec 20 2007:
//     Merged MIG 2.1 modifications into this file.
//
//--------------------------------------------------------------------------

`timescale 1ns/100ps

module s3_infrastructure #
  (
   parameter integer SIM_ONLY = 0,
   parameter         C_FAMILY = "spartan3", // Allowed Values: spartan3, spartan3e, spartan3a
   parameter integer C_SPECIAL_BOARD = 0    // Allowed Values: 0 = use default settings, 
                                            //                 1 = special placement
   )
  (
   input        sys_rst,
   input        clk_int,
   input        rst_calib,
   output [4:0] delay_sel_val_out,
   // debug_signals
   output [4:0] dbg_delay_sel, 
   output       dbg_rst_calib,
   output [4:0] dbg_phase_cnt,
   output [5:0] dbg_cnt,
   output       dbg_trans_onedtct,
   output       dbg_trans_twodtct,
   output       dbg_enb_trans_two_dtct
   );
  
  wire [4:0]    delay_sel_val;    
  reg [4:0]     delay_sel_val1;   
  reg           rst_calib_r1;
  reg           rst_calib_r2;
  reg           sys_rst_reg;

  assign dbg_delay_sel = delay_sel_val1;
  assign dbg_rst_calib = rst_calib_r2;

  // New MIG v1.7 derived
  assign delay_sel_val_out = delay_sel_val1;
  
  always @(posedge clk_int) begin
    sys_rst_reg <= sys_rst;
    if (sys_rst == 1'b1) begin
      rst_calib_r1 <= 1'b0;
      rst_calib_r2 <= 1'b0;
    end
    else begin
      rst_calib_r1 <= rst_calib;
      rst_calib_r2 <= rst_calib_r1;
    end
  end
  
  always @(posedge clk_int) begin
    if (rst_calib_r2 == 1'b0 )
      delay_sel_val1 <= delay_sel_val;
    else
      delay_sel_val1 <= delay_sel_val1;
  end
  
  // Instantiate cal_top module here to generate delay_sel vector
  // that is used by all dqs delay modules
  s3_cal_top #
    (
     .SIM_ONLY        (SIM_ONLY),
     .C_FAMILY        (C_FAMILY),
     .C_SPECIAL_BOARD (C_SPECIAL_BOARD)
     )
    cal_top 
      (
       .clk0                   (clk_int),          
       .reset                  (sys_rst_reg),      
       .tapForDqs              (delay_sel_val),
       .dbg_phase_cnt          (dbg_phase_cnt),
       .dbg_cnt                (dbg_cnt),
       .dbg_trans_onedtct      (dbg_trans_onedtct),
       .dbg_trans_twodtct      (dbg_trans_twodtct),
       .dbg_enb_trans_two_dtct (dbg_enb_trans_two_dtct)
       );       
  
endmodule



