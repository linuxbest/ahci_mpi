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
// MPMC Spartam3 MIG PHY Data Read Controller
//-------------------------------------------------------------------------
//
// Description:
//   This module has instantiation for fifo_0_wr_en, fifo_1_wr_en, 
//   dqs_delay and wr_gray_cntr.
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
//   Dec 20 2007: Merged MIG 2.1 modifications into this file.
//   Jul 18 2008: Merged MIG 2.3 modifications into this file.
//
//--------------------------------------------------------------------------

`timescale 1ns/100ps

module s3_data_read_controller #
  (
   parameter integer SIM_ONLY        = 0,
   parameter integer DQS_WIDTH       = 8,          // # of DQS strobes
   parameter         C_FAMILY        = "spartan3", // Allowed Values: spartan3, spartan3e, spartan3a
   parameter integer C_SPECIAL_BOARD = 0,          // Allowed Values: 0 = use default settings, 
                                                   //                 1 = special placement
   parameter integer C_DEBUG_EN      = 0
   )
  (
   input                    rst,
   input                    rst_dqs_div_in,
   input [4:0]              delay_sel,   
   input [(DQS_WIDTH-1):0]  dqs_int_delay_in,
   output [(DQS_WIDTH-1):0] fifo_0_wr_en_val,    
   output [(DQS_WIDTH-1):0] fifo_1_wr_en_val,    
   output [(DQS_WIDTH-1):0] dqs_delayed_col0_val,
   output [(DQS_WIDTH-1):0] dqs_delayed_col1_val,
   //debug_signals
   input [4:0]              vio_out_dqs,
   input                    vio_out_dqs_en,
   input [4:0]              vio_out_rst_dqs_div,
   input                    vio_out_rst_dqs_div_en
   );
  
  (* BUFFER_TYPE = "none" *) wire [(DQS_WIDTH-1):0]    dqs_delayed_col0; 
  (* BUFFER_TYPE = "none" *) wire [(DQS_WIDTH-1):0]    dqs_delayed_col1; 
  
  wire [(DQS_WIDTH-1):0]    fifo_0_wr_en/* synthesis syn_keep=1 */;        
  wire [(DQS_WIDTH-1):0]    fifo_1_wr_en/* synthesis syn_keep=1 */;        
  wire [4:0]                delay_sel_rst_dqs_div;
  wire [4:0]                delay_sel_dqs;

  
  // For simulation purposes
  // Need to model delay
  wire [(DQS_WIDTH-1):0]    #(0.6) fifo_0_wr_en_sim;     
  wire [(DQS_WIDTH-1):0]    #(0.6) fifo_1_wr_en_sim;     
  
  wire                      rst_dqs_div;
  
  wire [(DQS_WIDTH-1):0]    rst_dqs_delay_n;
  
  wire [(DQS_WIDTH-1):0]    dqs_delayed_col0_n;
  wire [(DQS_WIDTH-1):0]    dqs_delayed_col1_n;
  
  assign dqs_delayed_col0_val = dqs_delayed_col0;
  assign dqs_delayed_col1_val = dqs_delayed_col1;
  
  assign dqs_delayed_col0_n = ~dqs_delayed_col0;
  assign dqs_delayed_col1_n = ~dqs_delayed_col1;
  
  generate      
    if (SIM_ONLY == 0) begin: gen_no_sim
      assign fifo_0_wr_en_val = fifo_0_wr_en;
      assign fifo_1_wr_en_val = fifo_1_wr_en;           
    end
    else begin: gen_sim
      assign fifo_0_wr_en_sim = fifo_0_wr_en;
      assign fifo_1_wr_en_sim = fifo_1_wr_en;
      
      assign fifo_0_wr_en_val = fifo_0_wr_en_sim;
      assign fifo_1_wr_en_val = fifo_1_wr_en_sim;
      
    end
  endgenerate
  
  generate
    if(C_DEBUG_EN)  begin
      assign delay_sel_rst_dqs_div = (vio_out_rst_dqs_div_en) ? 
                                     vio_out_rst_dqs_div[4:0] : 
                                     delay_sel;
      assign delay_sel_dqs = vio_out_dqs_en ? vio_out_dqs[4:0] : delay_sel;
    end else begin
      assign delay_sel_rst_dqs_div = delay_sel;
      assign delay_sel_dqs = delay_sel;
    end
  endgenerate

  // Rst DQS Div instantation
  // If S3E Starter Kit, hard code loopback delay value
  generate
    if ((C_FAMILY == "spartan3e") && (C_SPECIAL_BOARD == 1)) begin
      
      s3_dqs_delay #
        (
         .SIM_ONLY      (SIM_ONLY)
         )
        rst_dqs_div_delayed
          (
           .clk_in(rst_dqs_div_in), 
           .sel_in(5'b10111),
           .clk_out(rst_dqs_div)
           )/* synthesis syn_preserve=1 */;
      
    end
    else if ((C_FAMILY == "spartan3e") && (C_SPECIAL_BOARD == 2)) begin
      
      s3_dqs_delay #
        (
         .SIM_ONLY      (SIM_ONLY)
         )
        rst_dqs_div_delayed
          (
           .clk_in(rst_dqs_div_in), 
           .sel_in(5'b10111),
           .clk_out(rst_dqs_div)
           )/* synthesis syn_preserve=1 */;
      
    end
    else
      begin
        
        s3_dqs_delay #
          (
           .SIM_ONLY    (SIM_ONLY)
           )
          rst_dqs_div_delayed
            (
             .clk_in(rst_dqs_div_in), 
             .sel_in(delay_sel_rst_dqs_div), 
             .clk_out(rst_dqs_div)
             )/* synthesis syn_preserve=1 */;
        
      end
  endgenerate
  
  // DQS Internal Delay Circuit implemented in LUTs
  // Use generate statement based on number of DQS bits
  
  genvar dqs_i;
  generate
    for(dqs_i = 0; dqs_i < DQS_WIDTH; dqs_i = dqs_i+1) begin: gen_dqs
      if ((dqs_i == 1) && (C_SPECIAL_BOARD == 2)) begin
        // Instantiate COL0 DQS_DELAY           
        s3_dqs_delay #
          (
           .SIM_ONLY    (SIM_ONLY)
           )
          u_dqs_delay_col1
            (
             .clk_in(dqs_int_delay_in[dqs_i]), 
             .sel_in(5'b11101),
             .clk_out(dqs_delayed_col0[dqs_i])
             )/* synthesis syn_preserve=1 */;
        
        // Instantiate COL1 DQS_DELAY
        s3_dqs_delay #
          (
           .SIM_ONLY    (SIM_ONLY)
           )
          u_dqs_delay_col0
            (
             .clk_in(dqs_int_delay_in[dqs_i]), 
             .sel_in(5'b11101),
             .clk_out(dqs_delayed_col1[dqs_i])
             )/* synthesis syn_preserve=1 */;
      end
      else begin
        // Instantiate COL0 DQS_DELAY           
        // UCF help: dqs_delay0_col0 replaced with u_dqs_delay_col0
        s3_dqs_delay #
          (
           .SIM_ONLY    (SIM_ONLY)
           )
          u_dqs_delay_col1
            (
             .clk_in(dqs_int_delay_in[dqs_i]), 
             .sel_in(delay_sel_dqs),
             .clk_out(dqs_delayed_col0[dqs_i])
             )/* synthesis syn_preserve=1 */;
   
        // Instantiate COL1 DQS_DELAY
        s3_dqs_delay #
          (
           .SIM_ONLY    (SIM_ONLY)
           )
          u_dqs_delay_col0
            (
             .clk_in(dqs_int_delay_in[dqs_i]), 
             .sel_in(delay_sel_dqs),
             .clk_out(dqs_delayed_col1[dqs_i])                                  
             )/* synthesis syn_preserve=1 */;
      end
    end
  endgenerate
  
  // FIFO write enable generation logic   
  genvar wr_i;
  generate
    for(wr_i = 0; wr_i < DQS_WIDTH; wr_i = wr_i+1) begin: gen_wr
      
      s3_fifo_0_wr_en 
        u_fifo_0_wr_en
          (
           .clk(dqs_delayed_col0_n[wr_i]), 
           .reset(rst), 
           .din(rst_dqs_div),
           .rst_dqs_delay_n(rst_dqs_delay_n[wr_i]), 
           .dout(fifo_0_wr_en[wr_i])
           )/* synthesis syn_preserve=1 */;
      
      s3_fifo_1_wr_en 
        u_fifo_1_wr_en 
          (
           .clk(dqs_delayed_col1[wr_i]), 
           .rst_dqs_delay_n(rst_dqs_delay_n[wr_i]),
           .reset(rst), 
           .din(rst_dqs_div), 
           .dout(fifo_1_wr_en[wr_i])
           )/* synthesis syn_preserve=1 */;
      
    end
  endgenerate
  
endmodule 

