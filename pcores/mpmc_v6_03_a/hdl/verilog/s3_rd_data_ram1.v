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
// MPMC Spartam3 MIG PHY Read Data RAMs
//-------------------------------------------------------------------------
//
// Description:
//   This module contains RAM16X1D instantiations 
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

module s3_rd_data_ram1 #
  (
   parameter integer DQS_WIDTH  = 2,        // # of DQS strobes
   parameter integer DQ_PER_DQS = 8,        // # of DQ data bits per strobe
   parameter         C_FAMILY = "spartan3a" // Allowed Values: spartan3, spartan3e, spartan3a
   )
  (
   output [(DQ_PER_DQS-1):0] DOUT,
   input [3:0]               WADDR,
   input [(DQ_PER_DQS-1):0]  DIN,
   input [3:0]               RADDR,
   input                     WCLK0,
   input                     WCLK1,
   input                     WE
   );

  // Use generate to instantiate read data path registers
  
  genvar data_i;
  generate
    for(data_i = 0; data_i < DQ_PER_DQS; data_i = data_i+1) begin: gen_data
      
      // Based on DQ bit I/O pad placement
      // determine which DQS delayed value is used to register the DQ bit
      
      // S3A Starter Kit assigns DQ bits 1, 2, 4, & 7 in COL0
      // S3500E Starter Kit assigns DQ bits 0, 3, 4, & 7 in COL0
      // S3 default assign DQ bits 0, 2, 4, & 6 to COL0
      if (((C_FAMILY == "spartan3a") && ((data_i == 0) || (data_i == 4) || (data_i == 6) || (data_i == 7))) ||
          ((C_FAMILY == "spartan3e") && ((data_i == 1) || (data_i == 3) || (data_i == 5) || (data_i == 7))) ||
          ((C_FAMILY == "spartan3") && ((data_i == 0) || (data_i == 2) || (data_i == 4) || (data_i == 6))))
        
        
        // Use dqs_delayed_col0 and place in Col 0
        RAM16X1D u_fifo_bit 
          (
           .DPO   (DOUT[data_i]), 
           .A0    (WADDR[0]), 
           .A1    (WADDR[1]),
           .A2    (WADDR[2]), 
           .A3    (WADDR[3]), 
           .D     (DIN[data_i]),
           .DPRA0 (RADDR[0]), 
           .DPRA1 (RADDR[1]),
           .DPRA2 (RADDR[2]), 
           .DPRA3 (RADDR[3]), 
           .SPO   (),
           .WCLK  (WCLK0), 
           .WE    (WE)
           );
      
      else              
        
        // Use dqs_delayed_col1 and place in Col 1
        RAM16X1D u_fifo_bit 
          (
           .DPO   (DOUT[data_i]), 
           .A0    (WADDR[0]), 
           .A1    (WADDR[1]),
           .A2    (WADDR[2]), 
           .A3    (WADDR[3]), 
           .D     (DIN[data_i]),
           .DPRA0 (RADDR[0]), 
           .DPRA1 (RADDR[1]),
           .DPRA2 (RADDR[2]), 
           .DPRA3 (RADDR[3]), 
           .SPO   (),
           .WCLK  (WCLK1), 
           .WE    (WE)
           );
      
    end
  endgenerate
  
endmodule
