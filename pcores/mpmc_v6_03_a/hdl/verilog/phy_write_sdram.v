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
//Device: Virtex-5
//Purpose:
//Reference:
//   Handles delaying various write control signals appropriately depending 
//   on CAS latency, pipe delay etc. 
//Revision History:
//   Rev 1.0 - 4/10/07
//*****************************************************************************

`timescale 1ns/1ps

module phy_write_sdram #

  (
   parameter integer WDF_RDEN_EARLY = 0,
   parameter integer WDF_RDEN_WIDTH = 1,
   parameter DQ_WIDTH      = 16,
   parameter DM_WIDTH      = 4,
   parameter CAS_LAT       = 5,
   parameter ECC_ENABLE    = 0,
   parameter REG_ENABLE    = 0

   )
  (
   input                                   clk0,
   input [(DQ_WIDTH)-1:0]                  wdf_data,
   input [(DM_WIDTH)-1:0]                  wdf_mask_data,
   input                                   ctrl_wren,
   output                                  dq_oe_n,
   output [WDF_RDEN_WIDTH-1:0]             wdf_rden,
   output [DQ_WIDTH-1:0]                   wr_data_rise,
   output [DM_WIDTH-1:0]                   mask_data_rise
   );


// Local paramemter declaration
  
  localparam WR_LATENCY = (2 +  ECC_ENABLE + ECC_ENABLE);
  
// Local signal declaration
  wire       dq_oe_0          /* synthesis syn_maxfan = 1 */;
  wire       dqs_rst_0;
  wire       wdf_rden_0;
  reg        dq_oe_n_int;
  reg [5:0]  wr_stages        /* synthesis syn_maxfan = 1 */;

  always @(*)
    wr_stages[0] <=  ctrl_wren;
 
 // synthesis attribute max_fanout of wr_stages is 1
  always @(posedge clk0) begin
    wr_stages[1] <= wr_stages[0];
    wr_stages[2] <= wr_stages[1];
    wr_stages[3] <= wr_stages[2];
    wr_stages[4] <= wr_stages[3];
    wr_stages[5] <= wr_stages[4];
  end

  generate 
    if (WDF_RDEN_EARLY==1) begin: gen_wdf_rden_early
      
      assign wdf_rden_0 = wr_stages[WR_LATENCY-2-ECC_ENABLE-ECC_ENABLE];
    end
    else begin: gen_wdf_rden_normal
      
      assign wdf_rden_0 = wr_stages[WR_LATENCY-1-ECC_ENABLE-ECC_ENABLE];
    end
  endgenerate
  
  
  assign dq_oe_0        = wr_stages[WR_LATENCY + REG_ENABLE];
  
  always @(posedge clk0) begin
    dq_oe_n_int         <= ~dq_oe_0; 
  end
  
  assign dq_oe_n        = dq_oe_n_int;
  assign wdf_rden       = {WDF_RDEN_WIDTH{wdf_rden_0}};
  assign wr_data_rise   = wdf_data;
  assign mask_data_rise = wdf_mask_data;
  
endmodule
