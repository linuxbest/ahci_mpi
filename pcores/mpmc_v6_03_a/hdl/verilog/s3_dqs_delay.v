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
// MPMC Spartan3 MIG PHY DQS Delay
//-------------------------------------------------------------------------

// Description: 
//   This module generates the delay in the dqs signal.
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

`timescale 1ns/100ps

module s3_dqs_delay #
  (
   parameter integer SIM_ONLY = 0
   )
  (
   input       clk_in,
   input [4:0] sel_in,
   output      clk_out
   );
  
  wire #(1.875) sim_delay;
  
  wire          delay1;
  wire          delay2;     
  wire          delay3;
  wire          delay4;
  wire          delay5;
  
  localparam HIGH = 1'b1; 

  assign sim_delay = clk_in;
  
  generate
    // For simulation purposes => model delay_sel of 1.875 ns
    if (SIM_ONLY == 1)
      begin : gen_sim_delay
        assign clk_out = sim_delay;
      end
    else
      begin : gen_delay
        LUT4 #
          (
           .INIT (16'hf3c0)
           )
          one 
            (
             .I0 (HIGH),
             .I1 (sel_in[4]),
             .I2 (delay5),
             .I3 (clk_in),
             .O  (clk_out)
             )/* synthesis syn_noprune=1 */;
        
        LUT4 #
          (
           .INIT (16'hee22)
           )
          two 
            (
             .I0 (clk_in),
             .I1 (sel_in[2]),
             .I2 (HIGH),
             .I3 (delay3),
             .O  (delay4)
             )/* synthesis syn_noprune=1 */;
        
        LUT4 #
          (
           .INIT (16'he2e2)
           )
          three 
            (
             .I0 (clk_in),
             .I1 (sel_in[0]),
             .I2 (delay1),
             .I3 (HIGH),
             .O  (delay2)
             )/* synthesis syn_noprune=1 */;
        
        LUT4 #
          (
           .INIT (16'hff00)
           )
          four 
            (
             .I0 (HIGH),
             .I1 (HIGH),
             .I2 (HIGH),
             .I3 (clk_in),
             .O  (delay1)
             )/* synthesis syn_noprune=1 */;
        
        LUT4 #
          (
           .INIT (16'hf3c0)
           )
          five 
            (
             .I0 (HIGH),
             .I1 (sel_in[3]),
             .I2 (delay4),
             .I3 (clk_in),
             .O  (delay5)
             )/* synthesis syn_noprune=1 */;
        
        LUT4 #
          (
           .INIT (16'he2e2)
           )
          six 
            (
             .I0 (clk_in),
             .I1 (sel_in[1]),
             .I2 (delay2),
             .I3 (HIGH),
             .O  (delay3)
             )/* synthesis syn_noprune=1 */;
      end
  endgenerate

endmodule 

