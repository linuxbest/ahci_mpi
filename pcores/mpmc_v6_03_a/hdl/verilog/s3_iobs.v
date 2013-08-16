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
// MPMC Spartam3 MIG PHY IOBs
//-------------------------------------------------------------------------
//
// Description:
//   This module contains the instantiations for
//     -infrastructure_ios,
//     -data_path_iobs
//     -controller_iobs modules
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

module s3_iobs #
  (
   parameter         C_FAMILY    = "spartan3", // Allowed Values: spartan3, spartan3e, spartan3a
   parameter integer BANK_WIDTH  = 2,  // # of memory bank addr bits
   parameter integer ROW_WIDTH   = 14, // # of memory row & # of addr bits
   parameter integer CLK_WIDTH   = 3,  // # of clock outputs          
   parameter integer CKE_WIDTH   = 2,  // # of memory clock enable outputs
   parameter integer CS_WIDTH    = 2,  // # of memory chip selects
   parameter integer ODT_WIDTH   = 1,
   parameter integer DM_WIDTH    = 8,  // # of data mask bits
   parameter integer DQ_BITS     = 5,  // # of data bits 
   parameter integer DQS_WIDTH   = 8,  // # of DQS strobes
   parameter integer DQSN_ENABLE = 0,  // Enables differential DQS
   parameter integer SIM_ONLY    = 0,
   parameter integer DDR2_ENABLE = 1
   )
  (
   input                     clk0,               
   input                     clk90,
   input                     clk180,
   input                     clk270,   
   input                     rst0,
   input                     rst90,        
   input                     ddr_rasb_cntrl,    
   input                     ddr_casb_cntrl,    
   input                     ddr_web_cntrl,     
   input                     ddr_cke_cntrl,     
   input [(CS_WIDTH-1):0]    ddr_csb_cntrl,
   input [(ODT_WIDTH-1):0]   ddr_odt_cntrl,     
   input [(ROW_WIDTH-1):0]   ddr_address_cntrl, 
   input [(BANK_WIDTH-1):0]  ddr_ba_cntrl,      
   input [(DQS_WIDTH)-1:0]   dqs_reset,         
   input [(DQS_WIDTH)-1:0]   dqs_enable,        
   inout [(DQS_WIDTH-1):0]   ddr_dqs,
   inout [(DQS_WIDTH-1):0]   ddr_dqs_n,
   inout [(DQ_BITS-1):0]     ddr_dq,      
   input [(DQ_BITS-1):0]     write_data_falling,
   input [(DQ_BITS-1):0]     write_data_rising,
   input                     write_en_val,   
   input [(DM_WIDTH-1):0]    data_mask_f,
   input [(DM_WIDTH-1):0]    data_mask_r, 
   output [(CLK_WIDTH-1):0]  ddr2_ck,
   output [(CLK_WIDTH-1):0]  ddr2_ck_n,
   output                    ddr_rasb,          
   output                    ddr_casb,         
   output                    ddr_web,          
   output [(BANK_WIDTH-1):0] ddr_ba,      
   output [(ROW_WIDTH-1):0]  ddr_address,
   output [(CKE_WIDTH-1):0]  ddr_cke,          
   output [(CS_WIDTH-1):0]   ddr_csb, 
   output [(ODT_WIDTH-1):0]  ddr_odt,         
   input                     rst_dqs_div_int,   // Input from phy FPGA logic to IOB  
  output                     rst_dqs_div_out,    // External output (loopback to rst_dqs_div_in...signal next in list)
  input                      rst_dqs_div_in,     // External input 
  output                     rst_dqs_div,        // Output to read_data module   
  output [(DQS_WIDTH-1):0]   dqs_int_delay_in,
  output [(DQ_BITS-1):0]     dq,
  output [(DM_WIDTH-1):0]    ddr_dm
   );

  s3_infrastructure_iobs #
    (
     .C_FAMILY  (C_FAMILY),
     .CLK_WIDTH (CLK_WIDTH),
     .DDR2_ENABLE (DDR2_ENABLE)
     )
    infrastructure_iobs   
      (
       .ddr2_ck   (ddr2_ck),        
       .ddr2_ck_n (ddr2_ck_n), 
       .clk0      (clk0),
       .clk180    (clk180)      
       );

  s3_controller_iobs #
    (
     .BANK_WIDTH (BANK_WIDTH),
     .ROW_WIDTH  (ROW_WIDTH),
     .CS_WIDTH   (CS_WIDTH),
     .CKE_WIDTH  (CKE_WIDTH),
     .ODT_WIDTH  (ODT_WIDTH)
     )
    controller_iobs 
      (
       .clk0              (clk0),
       .clk180            (clk180),
       .ddr_rasb_cntrl    (ddr_rasb_cntrl),
       .ddr_casb_cntrl    (ddr_casb_cntrl),
       .ddr_web_cntrl     (ddr_web_cntrl), 
       .ddr_cke_cntrl     (ddr_cke_cntrl),
       .ddr_csb_cntrl     (ddr_csb_cntrl),
       .ddr_odt_cntrl     (ddr_odt_cntrl),
       .ddr_address_cntrl (ddr_address_cntrl),
       .ddr_ba_cntrl      (ddr_ba_cntrl),
       .ddr_rasb          (ddr_rasb),
       .ddr_casb          (ddr_casb),
       .ddr_web           (ddr_web),
       .ddr_ba            (ddr_ba),
       .ddr_address       (ddr_address),
       .ddr_cke           (ddr_cke),
       .ddr_csb           (ddr_csb), 
       .ddr_odt           (ddr_odt),
       .rst_dqs_div_int   (rst_dqs_div_int),
       .rst_dqs_div       (rst_dqs_div),
       .rst_dqs_div_in    (rst_dqs_div_in),
       .rst_dqs_div_out   (rst_dqs_div_out)
       );               
  
  s3_data_path_iobs #
    (
     .DM_WIDTH    (DM_WIDTH),
     .DQ_BITS     (DQ_BITS),
     .DQS_WIDTH   (DQS_WIDTH),  
     .DQSN_ENABLE (DQSN_ENABLE),
     .SIM_ONLY    (SIM_ONLY)
     ) 
    datapath_iobs  
      (
       .clk0               (clk0),
       .clk90              (clk90),
       .clk180             (clk180),
       .clk270             (clk270),    
       .rst0               (rst0),
       .rst90              (rst90),
       .dqs_reset          (dqs_reset),
       .dqs_enable         (dqs_enable),
       .ddr_dqs            (ddr_dqs),                      
       .ddr_dqs_n          (ddr_dqs_n),                    
       .ddr_dq             (ddr_dq),
       .write_data_falling (write_data_falling),
       .write_data_rising  (write_data_rising),
       .write_en_val       (write_en_val),
       .data_mask_f        (data_mask_f),
       .data_mask_r        (data_mask_r),                   
       .dqs_int_delay_in   (dqs_int_delay_in),
       .ddr_dm             (ddr_dm),
       .ddr_dq_val         (dq)
       );
  
endmodule

