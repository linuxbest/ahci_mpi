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

module v4_phy_tap_logic #
  (
   parameter integer data_width        = 64,
   parameter integer data_bits         = 6,
   parameter integer data_strobe_width = 8,
   parameter integer tby4tapvalue      = 17,
   parameter integer DatabitsPerStrobe = 8,
   parameter integer DEBUG_EN          = 0
   )
  (
   input                            CLK,
   input                            RESET0,
   input                            CTRL_DUMMYREAD_START,
   input [data_width-1:0]           calibration_dq,
   output                           SEL_DONE,
   output [data_width-1:0]          data_idelay_inc,
   output [data_width-1:0]          data_idelay_ce,
   output [data_width-1:0]          data_idelay_rst,
   output [data_width-1:0]          per_bit_skew,

   // Debug Signals
   input                             dbg_idel_up_all,
   input                             dbg_idel_down_all,
   input                             dbg_idel_up_dq,
   input                             dbg_idel_down_dq,
   input [data_bits-1:0]             dbg_sel_idel_dq,
   input                             dbg_sel_all_idel_dq,
   output [(6*data_width)-1:0]       dbg_calib_dq_tap_cnt,
   output [data_strobe_width-1:0]    dbg_data_tap_inc_done,
   output                            dbg_sel_done
   );

  wire [data_strobe_width-1:0]      dlyinc_dqs;
  wire [data_strobe_width-1:0]      dlyce_dqs;
  wire [data_width-1:0]             data_dlyinc;
  wire [data_width-1:0]             data_dlyce;
  reg [data_width-1:0]              data_dlyinc_r;
  reg [data_width-1:0]              data_dlyce_r;
  wire [data_strobe_width-1:0]      chan_done_dqs;
  wire [data_strobe_width-1:0]      dq_data_dqs;
  wire [data_strobe_width-1:0]      calib_done_dqs;

  reg                               data_tap_inc_done;
  reg                               tap_sel_done;

  reg                               RESET0_r1 /* synthesis syn_preserve=1 */;

  // Debug
  integer                           x;
  reg [5:0]                         dbg_dq_tap_cnt [data_width-1:0];

  genvar i;
   
  // For controller to stop dummy reads
  assign SEL_DONE = tap_sel_done;

  // synthesis attribute equivalent_register_removal of RESET0_r1 is "no";
  always @( posedge CLK )
    RESET0_r1 <= RESET0;
  
  // All DQS set groups calibrated for each bit of correspoding DQS set
  // After all DQS sets calibrated, per bit calibration completed flag
  // tap_sel_done asserted
  always @ (posedge CLK) begin
    if (RESET0_r1 == 1'b1) begin
      data_tap_inc_done   <= 1'b0;
      tap_sel_done        <= 1'b0;
    end
    else begin
      data_tap_inc_done   <= (&calib_done_dqs[data_strobe_width-1:0]);
      tap_sel_done        <= (data_tap_inc_done);
    end
  end

  ////////////////////////////////////////////////////////////////////////////
  // Debug output ("dbg_*")
  // NOTES:
  //  1. All debug outputs coming out of TAP_LOGIC are clocked off CLK0,
  //     although they are also static after calibration is complete. This
  //     means the user can either connect them to a Chipscope ILA, or to
  //     either a sync/async VIO input block. Using an async VIO has the
  //     advantage of not requiring these paths to meet cycle-to-cycle timing.
  //  2. The widths of most of these debug buses are dependent on the # of
  //     DQS/DQ bits (e.g. dq_tap_cnt width = 6 * (# of DQ bits)
  // SIGNAL DESCRIPTION:
  //  1. tap_sel_done:      1 bit - asserted as per bit calibration 
  //                        (first stage) is completed.
  //  2. data_tap_inc_done: # of DQS bits - each one asserted when 
  //                        per bit calibration is completed for 
  //                        corresponding byte.
  //  3. calib_dq_tap_cnt:  final IDELAY tap counts for all DQ IDELAYs
  ////////////////////////////////////////////////////////////////////////////

   assign dbg_sel_done = tap_sel_done;
   assign dbg_data_tap_inc_done = calib_done_dqs;

   assign data_idelay_ce  = DEBUG_EN ? data_dlyce_r : data_dlyce;
   assign data_idelay_inc = DEBUG_EN ? data_dlyinc_r : data_dlyinc;

  always @ (posedge CLK) begin
    if (RESET0_r1) begin
      data_dlyce_r  <= 'b0;
      data_dlyinc_r <= 'b0;
    end else begin
      data_dlyce_r  <= 'b0;
      data_dlyinc_r <= 'b0;

      if (!data_tap_inc_done) begin
        data_dlyce_r  <= data_dlyce;
        data_dlyinc_r <= data_dlyinc;
      end else if ( DEBUG_EN == 1 ) begin
        // DEBUG: allow user to vary IDELAY tap settings
        // For DQ IDELAY taps
        if (dbg_idel_up_all || dbg_idel_down_all ||
            dbg_sel_all_idel_dq) begin
          for (x = 0; x < data_width; x = x + 1) begin: loop_dly_inc_dq
            data_dlyce_r[x]  <= dbg_idel_up_all | dbg_idel_down_all |
                                  dbg_idel_up_dq  | dbg_idel_down_dq;
            data_dlyinc_r[x] <= dbg_idel_up_all | dbg_idel_up_dq;
          end
        end else begin
          data_dlyce_r <= 'b0;
          data_dlyce_r[dbg_sel_idel_dq]  <= dbg_idel_up_dq | dbg_idel_down_dq;
          data_dlyinc_r[dbg_sel_idel_dq] <= dbg_idel_up_dq;
        end
      end
    end
  end

  //*****************************************************************
  // Record IDELAY tap values by "snooping" IDELAY control signals
  //*****************************************************************

  // record DQ IDELAY tap values
  genvar dbg_dq_tc_i;
  generate
    for (dbg_dq_tc_i = 0; dbg_dq_tc_i < data_width;
         dbg_dq_tc_i = dbg_dq_tc_i + 1) begin: gen_dbg_dq_tap_cnt
      assign dbg_calib_dq_tap_cnt[(6*dbg_dq_tc_i)+5:(6*dbg_dq_tc_i)]
               = dbg_dq_tap_cnt[dbg_dq_tc_i];
    always @(posedge CLK)
      if (RESET0_r1)
        dbg_dq_tap_cnt[dbg_dq_tc_i] <= 6'b000000;
      else
        if (data_idelay_ce[dbg_dq_tc_i])
          if (data_idelay_inc[dbg_dq_tc_i])
            dbg_dq_tap_cnt[dbg_dq_tc_i]
              <= dbg_dq_tap_cnt[dbg_dq_tc_i] + 1;
          else
            dbg_dq_tap_cnt[dbg_dq_tc_i]
              <= dbg_dq_tap_cnt[dbg_dq_tc_i] - 1;
      end
  endgenerate

  ////////////////////////////////////////////////////////////////////////////
  //  tap_ctrl instances for  DDR_DQS strobes
  ////////////////////////////////////////////////////////////////////////////

  generate
    for (i=0;i<data_strobe_width;i=i+1)
      begin : gen_phy_tap_ctrl
        v4_phy_tap_ctrl #
          (
           .tby4tapvalue (tby4tapvalue)
           )
          tap_ctrl_0
            (
             .clk                   (CLK),
             .reset                 (RESET0),
             .dq_data               (dq_data_dqs[i]),
             .ctrl_dummyread_start  (CTRL_DUMMYREAD_START),
             .dlyinc                (dlyinc_dqs[i]),
             .dlyce                 (dlyce_dqs[i]),
             .chan_done             (chan_done_dqs[i])
             );
      end
  endgenerate

  ////////////////////////////////////////////////////////////////////////////
  //  instances of data_tap_inc for each dqs and associated tap_ctrl
  ////////////////////////////////////////////////////////////////////////////
   
  generate
    for (i=0;i<data_strobe_width;i=i+1)
      begin : gen_phy_data_tap_inc
        if ((i+1)*8 > data_width)
          begin : gen_fill
            v4_phy_data_tap_inc #
              (
               .DatabitsPerStrobe (DatabitsPerStrobe-((i+1)*8-data_width))
               )
              data_tap_inc_0
                (
                 .CLK              (CLK),
                 .RESET            (RESET0),
                 .CALIBRATION_DQ   (calibration_dq[(i+1)*DatabitsPerStrobe-
                                                   ((i+1)*8-data_width)-1:
                                                   i*DatabitsPerStrobe]),
                 .CTRL_CALIB_START (CTRL_DUMMYREAD_START),
                 .DLYINC           (dlyinc_dqs[i]),
                 .DLYCE            (dlyce_dqs[i]),
                 .CHAN_DONE        (chan_done_dqs[i]),
                 .DQ_DATA          (dq_data_dqs[i]),
                 .DATA_DLYINC      (data_dlyinc[(i+1)*DatabitsPerStrobe-
                                                ((i+1)*8-data_width)-1:
                                                i*DatabitsPerStrobe]),
                 .DATA_DLYCE       (data_dlyce[(i+1)*DatabitsPerStrobe-
                                               ((i+1)*8-data_width)-1:
                                               i*DatabitsPerStrobe]),
                 .DATA_DLYRST      (data_idelay_rst[(i+1)*DatabitsPerStrobe-
                                                    ((i+1)*8-data_width)-1:
                                                    i*DatabitsPerStrobe]),
                 .CALIB_DONE       (calib_done_dqs[i]),
                 .PER_BIT_SKEW     (per_bit_skew[((i+1)*DatabitsPerStrobe)-1:
                                                   i*DatabitsPerStrobe])
                 );
          end
        else
          begin : gen_normal
            v4_phy_data_tap_inc #
              (
               .DatabitsPerStrobe (DatabitsPerStrobe)
               )
              data_tap_inc_0
                (
                 .CLK              (CLK),
                 .RESET            (RESET0),
                 .CALIBRATION_DQ   (calibration_dq[(i+1)*DatabitsPerStrobe-1:
                                                   i*DatabitsPerStrobe]),
                 .CTRL_CALIB_START (CTRL_DUMMYREAD_START),
                 .DLYINC           (dlyinc_dqs[i]),
                 .DLYCE            (dlyce_dqs[i]),
                 .CHAN_DONE        (chan_done_dqs[i]),
                 .DQ_DATA          (dq_data_dqs[i]),
                 .DATA_DLYINC      (data_dlyinc[(i+1)*DatabitsPerStrobe-1:
                                                i*DatabitsPerStrobe]),
                 .DATA_DLYCE       (data_dlyce[(i+1)*DatabitsPerStrobe-1:
                                               i*DatabitsPerStrobe]),
                 .DATA_DLYRST      (data_idelay_rst[(i+1)*DatabitsPerStrobe-1:
                                                    i*DatabitsPerStrobe]),
                 .CALIB_DONE       (calib_done_dqs[i]),
                 .PER_BIT_SKEW     (per_bit_skew[((i+1)*DatabitsPerStrobe)-1:
                                                 i*DatabitsPerStrobe])
                 );
          end
      end
  endgenerate

endmodule
