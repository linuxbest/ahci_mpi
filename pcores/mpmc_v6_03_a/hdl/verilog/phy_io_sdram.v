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

module phy_io_sdram #(
  parameter DM_WIDTH       = 2,
  parameter DQ_WIDTH       = 16,
  parameter CAS_LAT        = 5,
  parameter ECC_ENABLE     = 0,
  parameter REG_ENABLE     = 0
  )(
    input  wire                          clk0,
    input  wire                          clk0_rddata,
    input  wire                          dq_oe_n,
    input  wire                          ctrl_rden,
    input  wire                          rddata_clk_sel,
    output wire                          calib_rden,
    input  wire [DQ_WIDTH-1:0]           wr_data_rise,
    input  wire [DM_WIDTH-1:0]           mask_data_rise,
    output wire [DQ_WIDTH-1:0]           rd_data_rise,
    output wire [DM_WIDTH-1:0]           sdram_dm,
    inout  wire [DQ_WIDTH-1:0]           sdram_dq
  );

  // ratio of # of physical DM outputs to bytes in data bus
  // may be different - e.g. if using x4 components
  localparam DM_TO_BYTE_RATIO = DM_WIDTH / (DQ_WIDTH/8);
  // translate CAS latency into number of clock cycles for read valid delay
  // determination. Really only needed for CL = 2.5 (set to 2)
  localparam CAS_LAT_RDEN = (CAS_LAT == 25) ? 2 : CAS_LAT;
  // delay used to determine READ_VALID, DQS gate delays
  localparam RDEN_BASE_DELAY = CAS_LAT_RDEN + (ECC_ENABLE == 1) + (REG_ENABLE == 1) + 2  ;

// keep CALIB_ERR internal for now
  reg  [RDEN_BASE_DELAY-1:0]           rden_stages_r;
  reg  [0:0]                           calib_rden_int;
  wire [DM_WIDTH-1:0]                  rd_mask_data;
  wire [DM_WIDTH-1:0]                  mask_data_tmp;

  reg  [DQ_WIDTH-1:0]                  wr_data_rise_reg;
  wire [DQ_WIDTH-1:0]                  wr_data_rise_out;

  //***************************************************************************

  assign calib_rden = calib_rden_int[0];

  //***************************************************************************
  // keep CALIB_RDEN deasserted until calibration complete (i.e. stage 3
  // finished), and initialization logic stops sending training reads;
  // else user will get rogue (i.e. unwanted) RDEN pulses during cal
  always @(posedge clk0) begin
    rden_stages_r <= {rden_stages_r[RDEN_BASE_DELAY-2:0],ctrl_rden};
    calib_rden_int[0] <= rden_stages_r[RDEN_BASE_DELAY-1];
    wr_data_rise_reg <= wr_data_rise;
  end


  //***************************************************************************
  // DM instances
  //***************************************************************************

  genvar rd_dm_i;
  generate
    for(rd_dm_i = 0; rd_dm_i < DM_WIDTH; rd_dm_i = rd_dm_i+1) begin: gen_rd_dm
      assign rd_mask_data[rd_dm_i] = ((CAS_LAT_RDEN == 2) ? (~(rden_stages_r[0])) : (~(rden_stages_r[1])));
    end
  endgenerate

  assign mask_data_tmp = mask_data_rise & rd_mask_data;

  genvar dm_i;
  generate
    for(dm_i = 0; dm_i < DM_WIDTH; dm_i = dm_i+1) begin: gen_dm
      phy_dm_iob_sdram u_iob_dm (
         .clk0            (clk0),
         .mask_data_rise  (mask_data_tmp[dm_i/DM_TO_BYTE_RATIO]),
         .sdram_dm        (sdram_dm[dm_i])
       );
    end
  endgenerate


//****************************************************************************
// Register write Data, for REG DIMM the registered data needs to be sent
//****************************************************************************

  assign wr_data_rise_out = (REG_ENABLE == 1) ? wr_data_rise_reg : wr_data_rise;

//****************************************************************************
// Register Data read back from memory
//****************************************************************************

 genvar dq_i;
  generate
    for(dq_i = 0; dq_i < DQ_WIDTH; dq_i = dq_i+1) begin: gen_dq
      phy_dq_iob_sdram u_iob_dq (
        .clk0           (clk0),
        .clk0_rddata    (clk0_rddata),
        .dq_oe_n        (dq_oe_n),
        .rddata_clk_sel (rddata_clk_sel),
        .wr_data_rise   (wr_data_rise_out[dq_i]),
        .rd_data_rise   (rd_data_rise[dq_i]),
        .sdram_dq       (sdram_dq[dq_i])
      );
    end
  endgenerate

endmodule
