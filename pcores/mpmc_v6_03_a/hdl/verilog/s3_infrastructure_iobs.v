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
// MPMC Spartam3 MIG PHY Infrastructure IOBs
//-------------------------------------------------------------------------
//
// Description:
//   This module contains the FDDRRSE instantiations for the clocks.
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
//-----------------------------------------------------------------------------

`timescale 1ns/100ps

module s3_infrastructure_iobs #
  (
   parameter         C_FAMILY  = "spartan3", // Allowed Values: spartan3, spartan3e, spartan3a
   parameter integer CLK_WIDTH = 3, // # of clock outputs          
   parameter integer DDR2_ENABLE = 1
   )
  (
   input                     clk0,
   input                     clk180,
   output [(CLK_WIDTH-1):0]  ddr2_ck,
   output [(CLK_WIDTH-1):0]  ddr2_ck_n
   );
  
  wire [(CLK_WIDTH-1):0]     ddr2_clk_q;
  wire [(CLK_WIDTH-1):0]     ddr2_clk_n_q;
  
  wire                       vcc;   
  wire                       gnd;   

  assign gnd = 1'b0;
  assign vcc = 1'b1;   
  
  // ***********************************************************
  // Output DDR generation & output buffers
  // This includes instantiation of the output DDR flip flop
  // for ddr clk's and dimm clk's
  // ***********************************************************
  
  genvar clk_i;
  generate
    for (clk_i = 0; clk_i < CLK_WIDTH; clk_i = clk_i+1) begin: gen_clk
      
      FDDRRSE u_ddr_clk
        (
         .Q  (ddr2_clk_q[clk_i]), 
         .C0 (clk0), 
         .C1 (clk180), 
         .CE (vcc), 
         .D0 (vcc), 
         .D1 (gnd), 
         .R  (gnd), 
         .S  (gnd)
         );
      
      // Use FPGA differential output buffer            
      if (C_FAMILY == "spartan3" && DDR2_ENABLE) begin : gen_spartan3
        OBUF u_ddr_clk_buf
          (
           .I  (ddr2_clk_q[clk_i]),  
           .O  (ddr2_ck[clk_i])
           );
        FDDRRSE u_ddr_clk_n
          (
           .Q  (ddr2_clk_n_q[clk_i]), 
           .C0 (clk0), 
           .C1 (clk180), 
           .CE (vcc), 
           .D0 (gnd), 
           .D1 (vcc), 
           .R  (gnd), 
           .S  (gnd)
           );
      
        OBUF u_ddr_clk_n_buf
          (
           .I (ddr2_clk_n_q[clk_i]),  
           .O (ddr2_ck_n[clk_i])
           );
      end else begin : gen_spartan3x
        OBUFDS u_ddr_clk_buf
          (
           .I  (ddr2_clk_q[clk_i]),  
           .O  (ddr2_ck[clk_i]),
           .OB (ddr2_ck_n[clk_i])
           );
      end      
    end
  endgenerate
  
endmodule
