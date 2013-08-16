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

`timescale 1ns/1ps

module phy_dq_iob_sdram (
   input  wire clk0,
   input  wire clk0_rddata,
   input  wire rddata_clk_sel,
   input  wire dq_oe_n,
   input  wire wr_data_rise,
   output reg  rd_data_rise,
   inout  wire sdram_dq
   );


  wire    dq_out;
  wire    dq_in;
  wire    dq_oe_n_r;
  wire    rd_data_rise_rdclk;
  reg     rd_data_rise_clk0;
  reg     rd_data_rise_clk180;

///////////////////////////////////////////////////////////////////////////
// make sure output is tri-state during reset (dq_oe_n_r = 1)
  FDRE u_tri_state_dq (
    .D    (dq_oe_n),
    .R    (1'b0),
    .C    (clk0),
    .Q    (dq_oe_n_r),
    .CE   (1'b1)
  );

// register the wite data
  (* IOB = "FORCE" *) 
  FDRE u_reg_dq (
    .Q    (dq_out),
    .C    (clk0),
    .CE   (1'b1),
    .D    (wr_data_rise),
    .R    (1'b0)
  );

  IOBUF u_iobuf_dq (
    .I  (dq_out),
    .T  (dq_oe_n_r),
    .IO (sdram_dq),
    .O  (dq_in)
  );
  
  FD fd_dq_0 (
    .Q   (rd_data_rise_rdclk), 
    .C   (clk0_rddata), 
    .D   (dq_in)
  );

  ///////////////////////////////////////////////////////////////////////////
  //Flop the data on clk0
  always @(posedge clk0) begin
    if (rddata_clk_sel) begin
      rd_data_rise <= rd_data_rise_clk0;
    end else begin
      rd_data_rise <= rd_data_rise_clk180;
    end
    rd_data_rise_clk0 <= rd_data_rise_rdclk;
  end

  always @(negedge clk0) begin
    rd_data_rise_clk180 <= rd_data_rise_rdclk;
  end
  
endmodule
