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

module v4_phy_data_tap_inc #
  (
   parameter integer DatabitsPerStrobe = 8
   )
  (
   input                              CLK,
   input                              RESET,
   input [DatabitsPerStrobe-1:0]      CALIBRATION_DQ,
   input                              CTRL_CALIB_START,
   input                              DLYINC,
   input                              DLYCE,
   input                              CHAN_DONE,

   output                             DQ_DATA,
   output [DatabitsPerStrobe-1:0]     DATA_DLYINC,
   output [DatabitsPerStrobe-1:0]     DATA_DLYCE,
   output [DatabitsPerStrobe-1:0]     DATA_DLYRST,
   output                             CALIB_DONE,
   output reg [DatabitsPerStrobe-1:0] PER_BIT_SKEW
   );

  wire                            muxout_d0d1;
  wire                            muxout_d2d3;
  wire                            muxout_d4d5;
  wire                            muxout_d6d7;
  
  wire                            muxout_d0_to_d3;
  wire                            muxout_d4_to_d7;
  
  wire [DatabitsPerStrobe-1:0]    data_dlyinc_int;
  wire [DatabitsPerStrobe-1:0]    data_dlyce_int;
  reg                             calib_done_int;
  reg                             calib_done_int_r1;
  reg [7:0]                       calibration_dq_r
				  /* synthesis syn_maxfan = 5 */
                                  /* synthesis syn_preserve=1 */;

  reg [7:0]                       chan_sel_int
                                  /* synthesis syn_maxfan = 5 */;
  wire [7:0]                      chan_sel;
  
  reg                             RESET_r1
                                  /* synthesis syn_preserve=1 */;

  //***************************************************************************

  assign DATA_DLYRST = {DatabitsPerStrobe{RESET_r1}};
  assign DATA_DLYINC = data_dlyinc_int;
  assign DATA_DLYCE  = data_dlyce_int;
  assign CALIB_DONE  = calib_done_int;
  
  always @( posedge CLK )
    RESET_r1 <= RESET;
  
  always @( posedge CLK )
    calib_done_int_r1 <= calib_done_int;

   // synthesis attribute max_fanout of calibration_dq_r is 5
   // synthesis attribute equivalent_register_removal of calibration_dq_r is "no";
  generate
    genvar      k;
    for (k=0; k<=7; k=k+1)
      begin : gen_calibration_dq_r
        if (k<DatabitsPerStrobe)
          begin : gen_normal
            always @(posedge CLK) begin
              calibration_dq_r[k] <=  CALIBRATION_DQ[k];
            end
          end
        else
          begin : gen_fill
            always @(posedge CLK) begin
              calibration_dq_r[k] <=  1'b0;
            end
          end
      end
  endgenerate
  
  // DQ Data Select Mux
  //Stage 1 Muxes
  assign muxout_d0d1 = chan_sel[1] ? calibration_dq_r[1] : calibration_dq_r[0];
  assign muxout_d2d3 = chan_sel[3] ? calibration_dq_r[3] : calibration_dq_r[2];
  assign muxout_d4d5 = chan_sel[5] ? calibration_dq_r[5] : calibration_dq_r[4];
  assign muxout_d6d7 = chan_sel[7] ? calibration_dq_r[7] : calibration_dq_r[6];
  
  //Stage 2 Muxes
  assign muxout_d0_to_d3 = (chan_sel[2] | chan_sel[3]) ?  muxout_d2d3:
                                                          muxout_d0d1;
  assign muxout_d4_to_d7 = (chan_sel[6] | chan_sel[7]) ?  muxout_d6d7:
                                                          muxout_d4d5;
  
  //Stage 3 Muxes
  assign DQ_DATA = (chan_sel[4] | chan_sel[5] | chan_sel[6] | chan_sel[7]) ?
                   muxout_d4_to_d7: muxout_d0_to_d3;
  
   // RC: After calibration is complete, the Q1 output of each IDDR in the DQS
   // group is recorded. It should either be a static 1 or 0, depending on
   // which bit time is aligned to the rising edge of the FPGA CLK. If some
   // of the bits are 0, and some are 1 - this indicates there is "bit-
   // misalignment" within that DQS group. This will be handled later during
   // pattern calibration and by enabling the delay/swap circuit to delay
   // certain IDDR outputs by one bit time. For now, just record this "offset
   // pattern" and provide this to the pattern calibration logic.
   always @(posedge CLK) begin
     if (RESET_r1 || (!calib_done_int))
       PER_BIT_SKEW = {DatabitsPerStrobe{1'b0}};
     else if (calib_done_int && (!calib_done_int_r1))
       // Store offset pattern immediately after per-bit calib finished
       PER_BIT_SKEW = CALIBRATION_DQ;
   end
  
  generate
    genvar i;
    for (i=0; i<=DatabitsPerStrobe-1; i=i+1)
      begin :  dlyce_dlyinc
        assign data_dlyce_int[i] = chan_sel[i] ? DLYCE : 1'b0;
        assign data_dlyinc_int[i] = chan_sel[i] ? DLYINC : 1'b0;
      end
  endgenerate
  
  // Module that controls the calib_done.
  always @(posedge CLK)
    if (RESET_r1)
      calib_done_int <= 1'b0;
    else if (CTRL_CALIB_START)
      if (~|chan_sel)
        calib_done_int <= 1'b1;
  
  // Module that controls the chan_sel.
  always @(posedge CLK)
    if (RESET_r1)
      chan_sel_int <= 1;
    else if (CTRL_CALIB_START)
      if (CHAN_DONE)
        chan_sel_int <= chan_sel_int << 1;
  
  generate
    genvar      j;
    for (j=0; j<=7; j=j+1)
      begin :  chan_sel_gen
        assign chan_sel[j] = chan_sel_int[j];
      end
  endgenerate
  
endmodule
