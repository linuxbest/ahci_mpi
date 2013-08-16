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
// MPMC Spartam3 MIG PHY DQS IOBs
//-------------------------------------------------------------------------
//
// Description:
//   This module instantiates DDR IOB output flip-flops, an 
//   output buffer with registered tri-state, and an input buffer  
//   for a single strobe/dqs bit. The DDR IOB output flip-flops 
//   are used to forward strobe to memory during a write. During
//   a read, the output of the IBUF is routed to the internal 
//   delay module, dqs_delay. 
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

module s3_dqs_iob #
  (
   parameter integer DQSN_ENABLE   = 0, // Enables differential DQS
   parameter integer SIM_ONLY      = 0
   )
  (
   input  clk0,
   input  rst0,
   input  ddr_dqs_reset, 
   input  ddr_dqs_enable,   
   inout  ddr_dqs,
   inout  ddr_dqs_n,
   output dqs
   );
  
  localparam VCC = 1'b1;
  localparam GND = 1'b0; 
  
  wire dqs_q;
  wire ddr_dqs_enable_reg;
  wire dqs_data;
  
  assign dqs_data = ~ddr_dqs_reset;
  
  (* IOB = "FORCE" *) FD dqs_en_reg 
    (
     .D (ddr_dqs_enable),
     .Q (ddr_dqs_enable_reg),
     .C (clk0)
     );

  FDDRRSE dqs_reg 
    (
     .Q (dqs_q),
     .C0        (clk0),
     .C1        (~clk0),
     .CE        (VCC),
     .D0        (dqs_data),
     .D1        (GND),
     .R (GND),
     .S (GND)
     );
  
  //***********************************************************************
  // IO buffer for dqs signal. Allows for distribution of dqs
  // to the data (DQ) loads.
  //***********************************************************************  
  
  
  generate
    if (SIM_ONLY == 0) begin: dqs_no_sim
      // Need to instantiate differential DQS IO buffer
      // when selected through the DQSN_ENABLE parameter
      if (DQSN_ENABLE == 1) begin: diff_dqs
        IOBUFDS iobuf_dqs
          (
           .O   (dqs),
           .IO  (ddr_dqs),
           .IOB (ddr_dqs_n),
           .I   (dqs_q),
           .T   (ddr_dqs_enable_reg)
           );
      end
      else begin: no_diff_dqs
        // No differential DQS enabled
        // Drive default logic high on DQSn                     
        // Replace original PHY with IOBUF module
        IOBUF iobuf_dqs
          (
           .IO  (ddr_dqs),
           .I   (dqs_q),
           .T   (ddr_dqs_enable_reg),
           .O   (dqs)
           );
        assign ddr_dqs_n = VCC;
      end
    end
    else begin: dqs_sim
      PULLUP dqs_pullup 
        (
         .O (ddr_dqs)
         ); 
      PULLUP dqsn_pullup 
        (
         .O (ddr_dqs_n)
         ); 

      // Need to create simulatable tri-state buffers
      // Can't get board DQS termination to propogate properly on internal logic
      assign ddr_dqs = (~ddr_dqs_enable_reg) ? dqs_q : 1'bZ;    
      assign dqs = ddr_dqs;

      // Need to instantiate differential DQS signal
      // when selected through the DQSN_ENABLE parameter
      if (DQSN_ENABLE == 1)
        assign ddr_dqs_n = ~ddr_dqs;
      else 
        assign ddr_dqs_n = VCC;
    end
  endgenerate    // End SIM_ONLY generate
  
endmodule 
