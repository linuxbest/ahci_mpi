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
// MPMC Spartam3 MIG PHY DQ IOBs
//-------------------------------------------------------------------------
//
// Description:
//   This module instantiates DDR IOB output flip-flops, and an 
//   output buffer for the data bits.
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

module s3_dq_iob
  (
   input  clk90,    
   input  clk270,         
   input  rst90,
   inout  ddr_dq_inout, 
   input  write_data_falling,    
   input  write_data_rising,    
   input  write_en_val,    
   output read_data_in
   ); 
  
  localparam GND = 1'b0;
  localparam CLOCK_EN = 1'b1; 
  
  wire ddr_en;    //Tri-state enable signal
  wire ddr_dq_q;  //Data output intermediate signal
  wire ddr_dq_o;  //Data output intermediate signal
  wire enable_b;
  
  wire write_data_rising1;
  wire write_data_falling1;
        
  // Using dq_oe from phy_write is already active low
  assign enable_b = write_en_val;
  
  assign #1 write_data_rising1  = write_data_rising;
  assign #1 write_data_falling1 = write_data_falling;
  
  // Transmission data path
  FDDRRSE DDR_OUT
    (
     .Q  (ddr_dq_q), 
     .C0 (clk270), 
     .C1 (clk90), 
     .CE (CLOCK_EN),
     .D0 (write_data_rising1), 
     .D1 (write_data_falling1), 
     .R  (GND), 
     .S  (GND)
     );
  
  (* IOB = "FORCE" *) FD DQ_T
    (
     .D   (enable_b), 
     .C   (clk270), 
     .Q   (ddr_en)
     )/* synthesis syn_useioff = 1 */; 
  
  OBUFT DQ_OBUFT
    (
     .I (ddr_dq_q),
     .T (ddr_en),
     .O (ddr_dq_inout)
     );
  
  IBUF DQ_IBUF
    (
     .I (ddr_dq_inout),
     .O (read_data_in)
     );
  
endmodule 

