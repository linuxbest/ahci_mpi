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
// MPMC Spartam3 MIG PHY Data Path IOBs
//-------------------------------------------------------------------------
//
// Description:
//   This module contains the instantiations for
//     -s3_ddr_iob,
//     -s3_dqs_iob and
//     -ddr_dm modules
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

module s3_data_path_iobs #
  (
   parameter integer DM_WIDTH      = 8,      // # of data mask bits
   parameter integer DQ_BITS       = 5,      // # of data bits 
   parameter integer DQS_WIDTH     = 8,      // # of DQS strobes
   parameter integer DQSN_ENABLE   = 0,          // Enables differential DQS
   parameter integer SIM_ONLY      = 0
   )
  (
   input                    clk0,             
   input                    clk90, 
   input                    clk180,             
   input                    clk270,  
   input                    rst0,
   input                    rst90,       
   input [(DQS_WIDTH-1):0]  dqs_reset,         
   input [(DQS_WIDTH-1):0]  dqs_enable,        
   input                    write_en_val,  
   inout [(DQS_WIDTH-1):0]  ddr_dqs,
   inout [(DQS_WIDTH-1):0]  ddr_dqs_n,       
   inout [(DQ_BITS-1):0]    ddr_dq,          
   input [(DQ_BITS-1):0]    write_data_falling,
   input [(DQ_BITS-1):0]    write_data_rising, 
   input [(DM_WIDTH-1):0]   data_mask_f,   
   input [(DM_WIDTH-1):0]   data_mask_r,   
   output [(DQS_WIDTH-1):0] dqs_int_delay_in,
   output [(DQ_BITS-1):0]   ddr_dq_val,
   output [(DM_WIDTH-1):0]  ddr_dm
   );

  wire [(DQ_BITS-1):0]      ddr_dq_in;
  
  assign ddr_dq_val = ddr_dq_in;
  
  // Instantiate module that generates all DDR DM IOB modules
  s3_dm_iobs #
    (
     .DM_WIDTH (DM_WIDTH)
     )
    dm_iobs
      (
       .ddr_dm       (ddr_dm),
       .mask_falling (data_mask_f),
       .mask_rising  (data_mask_r),
       .clk90        (clk90),
       .clk270       (clk270)
       );
  
  //***********************************************************************
  // DDR DQS instantiations 
  // Based on parameter settings for # of DQS bits
  //***********************************************************************  
  
  genvar dqs_i;
  generate
    for(dqs_i = 0; dqs_i < DQS_WIDTH; dqs_i = dqs_i+1) begin: gen_dqs
      
      s3_dqs_iob #
        (
         .DQSN_ENABLE   (DQSN_ENABLE),
         .SIM_ONLY      (SIM_ONLY)
         )
        dqs_iob
          (
           .clk0           (clk0),
           .rst0           (rst0),
           .ddr_dqs_reset  (dqs_reset[dqs_i]),
           .ddr_dqs_enable (dqs_enable[dqs_i]),
           .ddr_dqs        (ddr_dqs[dqs_i]),
           .ddr_dqs_n      (ddr_dqs_n[dqs_i]),
           .dqs            (dqs_int_delay_in[dqs_i])
           );
      
    end
  endgenerate


  //***************************************************************************
  // DDR DQ instantiations 
  // Based on parameter settings for # of DQ bits
  //***************************************************************************
  
  genvar dq_i;
  generate
    for(dq_i = 0; dq_i < DQ_BITS; dq_i = dq_i+1) begin: gen_dq
      
      s3_dq_iob 
        dq_iob 
          (
           .clk90              (clk90),
           .clk270             (clk270),
           .rst90              (rst90),
           .ddr_dq_inout       (ddr_dq[dq_i]), 
           .write_data_falling (write_data_falling[dq_i]), 
           .write_data_rising  (write_data_rising[dq_i]),
           .read_data_in       (ddr_dq_in[dq_i]),
           .write_en_val       (write_en_val)
           );
      
    end
  endgenerate
  
endmodule
