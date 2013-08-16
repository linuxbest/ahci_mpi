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
// MPMC V5 MIG PHY DDR1 Calibration
//-------------------------------------------------------------------------
//
// Description:
//   This module handles calibration after memory initialization.
//
// Structure:
//     
//--------------------------------------------------------------------------
//
// History:
//   Dec 20 2007: Merged MIG 2.1 modifications into this file.
//   Jul 18 2008: Merged MIG 2.3 modifications into this file.
//
//--------------------------------------------------------------------------

`timescale 1ns/1ps

//*****************************************************************************
// Port descriptions:
//   Inputs:
//     clk: CLK0 (some initialization logic interfacing to this module is
//       clocked off CLK0, so require CLK0 <-> CLK90 synchronization)
//     clk90, rst90: 90 degrees shift from CLK0, and reset sync'ed to CLK90
//     calib_start: Assert to begin each stage of calibration. [0] = stg1,
//       [3] = stg4. [0] should be asserted only once memory initialization
//       complete, calibration training patterns have been written to memory,
//       and continuous read to generate training pattern for stage 1 begun.
//       The others should only be asserted once the previous stage is
//       complete, and training pattern continuous read for that stage has
//       begun.
//     din_capture: Raw capture data from ISERDES. rising data = lower half
//       of din_capture (i.e. [WIDTH-1:0]), falling data = upper half
//     bit_time_taps: Number of taps that a bit time spans (e.g. clk = 333MHz,
//       then bit time = 1.5ns, or 20 taps; for 100MHz, taps = 63 (max))
//   Outputs:
//     calib_done[3:0]: Asserted when the corresponding stage of calibration
//     dlyrst_dq[]: Tap reset for DQ IDELAYs
//     dlyce_dq[]: Control enable for DQ IDELAYs
//     dlyinc_dq[]: Increment/decrement for DQ IDELAYs
//     dlyrst_dqs[]: Tap reset for DQS IDELAYs
//     dlyce_dqs[]: Control enable for DQS IDELAYs
//     dlyinc_dqs[]: Increment/decrement for DQS IDELAYs
//*****************************************************************************

module v5_phy_calib_ddr1 #
  (
   parameter DQ_WIDTH      = 72, 
   parameter DQ_BITS       = 7,
   parameter DQ_PER_DQS    = 8,          
   parameter DQS_BITS      = 4,
   parameter DQS_WIDTH     = 9,          
   parameter ADDITIVE_LAT  = 0,
   parameter CAS_LAT       = 2,
   parameter ECC_ENABLE    = 0,
   parameter REG_ENABLE    = 0,
   parameter CLK_PERIOD    = 5000,
   parameter DEBUG_EN      = 0
   )
  (
   input                                   clk0,
   input                                   clk90,
   input                                   rst90,
   input [3:0]                             calib_start_0,
   input                                   ctrl_rden_0,
   input                                   phy_init_rden_0,
   input                                   phy_init_done_0,
   input [DQ_WIDTH-1:0]                    rd_data_rise,
   input [DQ_WIDTH-1:0]                    rd_data_fall,
   input                                   calib_ref_done_0,
   output reg [3:0]                        calib_done_0,   
   output reg                              calib_ref_req_0,
   output reg [3:0]                        calib_err_0,
   output reg [DQS_WIDTH-1:0]              calib_rden,
   output reg                              dlyrst_dq,
   output reg [DQ_WIDTH-1:0]               dlyce_dq,
   output reg [DQ_WIDTH-1:0]               dlyinc_dq,
   output reg                              dlyrst_dqs,
   output reg [DQS_WIDTH-1:0]              dlyce_dqs,
   output reg [DQS_WIDTH-1:0]              dlyinc_dqs,
   output reg [DQS_WIDTH-1:0]              dlyrst_gate,
   output reg [DQS_WIDTH-1:0]              dlyce_gate,
   output reg [DQS_WIDTH-1:0]              dlyinc_gate,
   output reg [DQS_WIDTH-1:0]              en_dqs,
   //Debug signals
   input                                   dbg_idel_up_all,
   input                                   dbg_idel_down_all,
   input                                   dbg_idel_up_dq,
   input                                   dbg_idel_down_dq,
   input                                   dbg_idel_up_dqs,
   input                                   dbg_idel_down_dqs,
   input                                   dbg_idel_up_gate,
   input                                   dbg_idel_down_gate,
   input [DQ_BITS-1:0]                     dbg_sel_idel_dq,
   input                                   dbg_sel_all_idel_dq,
   input [DQS_BITS:0]                      dbg_sel_idel_dqs,
   input                                   dbg_sel_all_idel_dqs,
   input [DQS_BITS:0]                      dbg_sel_idel_gate,
   input                                   dbg_sel_all_idel_gate,
   output [3:0]                            dbg_calib_done,
   output [3:0]                            dbg_calib_err,
   output [(6*DQ_WIDTH)-1:0]               dbg_calib_dq_tap_cnt,
   output [(6*DQS_WIDTH)-1:0]              dbg_calib_dqs_tap_cnt,
   output [(6*DQS_WIDTH)-1:0]              dbg_calib_gate_tap_cnt,
   output [(2*DQS_WIDTH)-1:0]              dbg_calib_rden_dly,
   output [(2*DQS_WIDTH)-1:0]              dbg_calib_gate_dly,
   input  [(2*DQS_WIDTH)-1:0]              dbg_calib_rden_dly_value,
   input  [(DQS_WIDTH)-1:0]                dbg_calib_rden_dly_en,
   input  [(2*DQS_WIDTH)-1:0]              dbg_calib_gate_dly_value,
   input  [(DQS_WIDTH)-1:0]                dbg_calib_gate_dly_en
   );

  
  // minimum time (in IDELAY taps) for which capture data must be stable for 
  // algorithm to consider
  localparam MIN_WIN_SIZE = 5;
  // minimum # of cycles to wait after changing IDELAY value
  localparam IDEL_SET_VAL = 4'b1111;
  // # of clock cycles to delay read enable to determine if read data pattern
  // is correct for stage 4 (DQS gate) calibration
  localparam CAL4_RDEN_PIPE_LEN = 7;
  // translate CAS latency into number of clock cycles for read valid delay
  // determination. Really only needed for CL = 2.5 (set to 2)
  localparam CAS_LAT_RDEN = (CAS_LAT == 25) ? 2 : CAS_LAT;
  // delay used to determine READ_VALID, DQS gate delays
  localparam RDEN_BASE_DELAY = CAS_LAT_RDEN + ADDITIVE_LAT + REG_ENABLE + 
             ECC_ENABLE + 8;
  // fix minimum value of DQS to be 1 to handle the case where's there's only
  // one DQS group. We could also enforce that user always inputs minimum
  // value of 1 for DQS_BITS (even when DQS_WIDTH=1). Leave this as safeguard
  // Assume we don't have to do this for DQ, DQ_WIDTH always > 1
  localparam DQS_BITS_FIX = (DQS_BITS == 0) ? 1 : DQS_BITS;
  // how many taps to "pre-delay" DQ before stg 1 calibration - not needed for
  // current calibration, but leave for debug
  localparam DQ_IDEL_INIT = 6'b000000;
  // # IDELAY taps per bit time (i.e. half cycle). Limit to 63. 
  localparam integer BIT_TIME_TAPS = (CLK_PERIOD/150 < 64) ? 
             CLK_PERIOD/150 : 63;

  // used in various places during stage 4 cal: (1) determines maximum taps
  // to increment when finding right edge, (2) amount to decrement after
  // finding left edge, (3) amount to increment after finding right edge
  localparam CAL4_IDEL_BIT_VAL = (BIT_TIME_TAPS >= 6'b100000) ?
             6'b100000 : BIT_TIME_TAPS;  
  
  localparam CAL1_IDLE                   = 4'h0;
  localparam CAL1_INIT                   = 4'h1;
  localparam CAL1_INC_IDEL               = 4'h2;
  localparam CAL1_FIND_FIRST_EDGE        = 4'h3;
  localparam CAL1_FIRST_EDGE_IDEL_WAIT   = 4'h4;
  localparam CAL1_FOUND_FIRST_EDGE_WAIT  = 4'h5;
  localparam CAL1_FIND_SECOND_EDGE       = 4'h6;
  localparam CAL1_SECOND_EDGE_IDEL_WAIT  = 4'h7;
  localparam CAL1_CALC_IDEL              = 4'h8;
  localparam CAL1_DEC_IDEL               = 4'h9;
  localparam CAL1_DONE                   = 4'hA;

  localparam CAL2_IDLE                   = 3'h0;
  localparam CAL2_INIT                   = 3'h1;
  localparam CAL2_FIND_EDGE              = 3'h2;
  localparam CAL2_FIND_EDGE_IDEL_WAIT    = 3'h3;
  localparam CAL2_CALC_IDEL_STALL        = 3'h4;
  localparam CAL2_CALC_IDEL              = 3'h5;
  localparam CAL2_ADJ_IDEL               = 3'h6;
  localparam CAL2_DONE                   = 3'h7;
  
  localparam CAL4_IDLE                   = 3'h0;
  localparam CAL4_INIT                   = 3'h1;
  localparam CAL4_FIND_WINDOW            = 3'h2;
  localparam CAL4_FIND_EDGE              = 3'h3;
  localparam CAL4_IDEL_WAIT              = 3'h4;
  localparam CAL4_RDEN_PIPE_CLR_WAIT     = 3'h5;
  localparam CAL4_ADJ_IDEL               = 3'h6;
  localparam CAL4_DONE                   = 3'h7;

  integer                                i;
 
  reg [5:0]                      cal1_bit_time_tap_cnt;
  wire [1:0]                     cal1_data_chk;                          
  reg [1:0]                      cal1_data_chk_last;
  reg                            cal1_data_chk_last_valid;
  reg [1:0]                      cal1_data_chk_r;
  reg                            cal1_dlyce_dq;
  reg                            cal1_dlyinc_dq;
  reg                            cal1_dqs_dq_init_phase;
  wire                           cal1_detect_edge;
  wire                           cal1_detect_stable;
  reg                            cal1_found_second_edge;
  reg                            cal1_found_rising;
  reg                            cal1_found_window;
  reg                            cal1_first_edge_done;                   
  reg [5:0]                      cal1_first_edge_tap_cnt;
  reg [6:0]                      cal1_idel_dec_cnt;
  reg [5:0]                      cal1_idel_inc_cnt;
  reg [5:0]                      cal1_idel_max_tap;
  reg                            cal1_idel_max_tap_we;
  reg [5:0]                      cal1_idel_tap_cnt;
  reg                            cal1_idel_tap_limit_hit;
  reg [6:0]                      cal1_low_freq_idel_dec;
  wire [6:0]                     cal1_low_freq_idel_dec_raw;
  reg                            cal1_ref_req;
  wire                           cal1_refresh;  
  reg [3:0]                      cal1_state;
  reg [3:0]                      cal1_window_cnt;           
  reg                            cal2_dec_bit_time;
  reg                            cal2_dec_zero;
  wire                           cal2_detect_edge;
  reg                            cal2_dlyce_dqs;
  reg                            cal2_dlyinc_dqs;
  reg [5:0]                      cal2_edge_tap_cnt;
  reg                            cal2_found_edge;
  reg [5:0]                      cal2_idel_adj_cnt;  
  reg                            cal2_idel_adj_inc;
  reg [5:0]                      cal2_idel_tap_cnt;
  reg [5:0]                      cal2_idel_tap_limit;
  reg                            cal2_idel_tap_limit_hit;
  reg                            cal2_inc_bit_time;
  reg                            cal2_rd_data_fall_last;
  reg                            cal2_rd_data_fall_r;
  reg                            cal2_rd_data_last_valid;
  reg                            cal2_rd_data_rise_last;
  reg                            cal2_rd_data_rise_r;
  reg                            cal2_ref_req;
  reg [2:0]                      cal2_state;
  reg [5:0]                      cal2_tap_limit_delta;
  reg                            cal2_toggle;
  reg                            cal3_data_match;
  reg                            cal3_en;
  reg                            cal4_data_match;
  reg                            cal4_dlyce_gate;
  reg                            cal4_dlyinc_gate;
  reg                            cal4_dlyrst_gate;
  reg [5:0]                      cal4_idel_adj_cnt;
  reg                            cal4_idel_adj_inc;
  reg                            cal4_idel_bit_tap;
  reg [5:0]                      cal4_idel_tap_cnt;
  reg                            cal4_idel_max_tap;
  reg                            cal4_new_window;
  reg [3:0]                      cal4_rden_pipe_cnt;
  reg                            cal4_rd_match;
  reg                            cal4_rd_match_valid;
  reg                            cal4_ref_req;  
  reg                            cal4_seek_left;
  reg                            cal4_stable_window;
  reg [2:0]                      cal4_state;
  reg [3:0]                      cal4_window_cnt;                        
  reg [3:0]                      calib_done;
  reg [3:0]                      calib_done_tmp;         // only for stg1/2/4
  reg [3:0]                      calib_err;
  reg [CAL4_RDEN_PIPE_LEN-1:0]   calib_rden_mux_r;
  reg                            calib_ref_done;
  reg                            calib_ref_done_270;
  reg                            calib_ref_req;
  reg [3:0]                      calib_start;                         
  reg [3:0]                      calib_start_270;                        
  reg                            ctrl_rden_270;
  reg [DQ_BITS-1:0]              count_dq;         
  reg [DQS_BITS_FIX-1:0]         count_dqs;
  reg [DQS_BITS_FIX-1:0]         count_gate;
  wire                           dlyce_or;
  reg [(2*DQS_WIDTH)-1:0]        gate_dly;
  wire [(2*DQS_WIDTH)-1:0]       gate_dly_i;
  reg [DQS_WIDTH-1:0]            i_calib_rden;
  reg [3:0]                      idel_set_cnt;
  wire                           idel_set_wait;
  reg [DQ_BITS-1:0]              next_count_dq;         
  reg [DQS_BITS_FIX-1:0]         next_count_dqs;
  reg [DQS_BITS_FIX-1:0]         next_count_gate;
  reg                            phy_init_done;
  reg                            phy_init_done_270;
  reg                            phy_init_rden_270;
  reg [(2*DQS_WIDTH)-1:0]        rd_data_fall_chk_r2;
  reg [(2*DQS_WIDTH)-1:0]        rd_data_fall_chk_r1;
  reg [DQ_WIDTH-1:0]             rd_data_fall_r;   
  reg [(2*DQS_WIDTH)-1:0]        rd_data_rise_chk_r2;
  reg [(2*DQS_WIDTH)-1:0]        rd_data_rise_chk_r1;
  reg [DQ_WIDTH-1:0]             rd_data_rise_r;
  reg [4:0]                      rden_r;
  reg [DQS_BITS_FIX-1:0]         rden_cnt;               
  wire [3:0]                     rden_edge;
  reg [RDEN_BASE_DELAY:0]        rden_stages_r;
  reg [(2*DQS_WIDTH)-1:0]        rden_dly;
  wire [(2*DQS_WIDTH)-1:0]       rden_dly_i;
  
  // Debug
  integer                        x;
  reg [5:0]                      dbg_dq_tap_cnt [DQ_WIDTH-1:0];
  reg [5:0]                      dbg_dqs_tap_cnt [DQS_WIDTH-1:0];
  reg [5:0]                      dbg_gate_tap_cnt [DQS_WIDTH-1:0];

  //***************************************************************************
  // Debug output ("dbg_phy_calib_*")
  // NOTES:
  //  1. All debug outputs coming out of PHY_CALIB are clocked off CLK90,
  //     although they are also static after calibration is complete. This
  //     means the user can either connect them to a Chipscope ILA.
  //  2. The widths of most of these debug buses are dependent on the # of
  //     DQS/DQ bits (e.g. dq_tap_cnt width = 6 * (# of DQ bits)
  // SIGNAL DESCRIPTION:
  //  1. calib_done:   4 bits - each one asserted as each phase of calibration
  //                   is completed.
  //  2. calib_err:    4 bits - each one asserted when a calibration error
  //                   encountered for that stage. Some of these bits may not
  //                   be used (not all cal stages report an error).
  //  3. dq_tap_cnt:   final IDELAY tap counts for all DQ IDELAYs
  //  4. dqs_tap_cnt:  final IDELAY tap counts for all DQS IDELAYs
  //  5. gate_tap_cnt: final IDELAY tap counts for all DQS gate
  //                   synchronization IDELAYs
  //  6. rden_dly:     related to # of cycles after issuing a read until when
  //                   read data is valid - for all DQS groups
  //  7. gate_dly:     related to # of cycles after issuing a read until when
  //                   clock enable for all DQ's is deasserted to prevent
  //                   effect of DQS postamble glitch - for all DQS groups
  //***************************************************************************

  //*****************************************************************
  // Record IDELAY tap values by "snooping" IDELAY control signals
  //*****************************************************************

  // record DQ IDELAY tap values
  genvar dbg_dq_tc_i;
  generate
    for (dbg_dq_tc_i = 0; dbg_dq_tc_i < DQ_WIDTH;
         dbg_dq_tc_i = dbg_dq_tc_i + 1) begin: gen_dbg_dq_tap_cnt
      assign dbg_calib_dq_tap_cnt[(6*dbg_dq_tc_i)+5:(6*dbg_dq_tc_i)]
               = dbg_dq_tap_cnt[dbg_dq_tc_i];
      always @(posedge clk90)
        if (rst90 | dlyrst_dq)
          dbg_dq_tap_cnt[dbg_dq_tc_i] <= 6'b000000;
        else
          if (dlyce_dq[dbg_dq_tc_i])
            if (dlyinc_dq[dbg_dq_tc_i])
              dbg_dq_tap_cnt[dbg_dq_tc_i]
                <= dbg_dq_tap_cnt[dbg_dq_tc_i] + 1;
            else
              dbg_dq_tap_cnt[dbg_dq_tc_i]
                <= dbg_dq_tap_cnt[dbg_dq_tc_i] - 1;
    end
  endgenerate

  // record DQS IDELAY tap values
  genvar dbg_dqs_tc_i;
  generate
    for (dbg_dqs_tc_i = 0; dbg_dqs_tc_i < DQS_WIDTH;
         dbg_dqs_tc_i = dbg_dqs_tc_i + 1) begin: gen_dbg_dqs_tap_cnt
      assign dbg_calib_dqs_tap_cnt[(6*dbg_dqs_tc_i)+5:(6*dbg_dqs_tc_i)]
               = dbg_dqs_tap_cnt[dbg_dqs_tc_i];
      always @(posedge clk90)
        if (rst90 | dlyrst_dqs)
          dbg_dqs_tap_cnt[dbg_dqs_tc_i] <= 6'b000000;
        else
          if (dlyce_dqs[dbg_dqs_tc_i])
            if (dlyinc_dqs[dbg_dqs_tc_i])
              dbg_dqs_tap_cnt[dbg_dqs_tc_i]
                <= dbg_dqs_tap_cnt[dbg_dqs_tc_i] + 1;
            else
              dbg_dqs_tap_cnt[dbg_dqs_tc_i]
                <= dbg_dqs_tap_cnt[dbg_dqs_tc_i] - 1;
    end
  endgenerate

  // record DQS gate IDELAY tap values
  genvar dbg_gate_tc_i;
  generate
    for (dbg_gate_tc_i = 0; dbg_gate_tc_i < DQS_WIDTH;
         dbg_gate_tc_i = dbg_gate_tc_i + 1) begin: gen_dbg_gate_tap_cnt
      assign dbg_calib_gate_tap_cnt[(6*dbg_gate_tc_i)+5:(6*dbg_gate_tc_i)]
               = dbg_gate_tap_cnt[dbg_gate_tc_i];
      always @(posedge clk90)
        if (rst90 | dlyrst_gate[dbg_gate_tc_i])
          dbg_gate_tap_cnt[dbg_gate_tc_i] <= 6'b000000;
        else
          if (dlyce_gate[dbg_gate_tc_i])
            if (dlyinc_gate[dbg_gate_tc_i])
              dbg_gate_tap_cnt[dbg_gate_tc_i]
                <= dbg_gate_tap_cnt[dbg_gate_tc_i] + 1;
            else
              dbg_gate_tap_cnt[dbg_gate_tc_i]
                <= dbg_gate_tap_cnt[dbg_gate_tc_i] - 1;
    end
  endgenerate

  assign dbg_calib_done        = calib_done;
  assign dbg_calib_err         = calib_err;
  assign dbg_calib_rden_dly    = rden_dly_i;
  assign dbg_calib_gate_dly    = gate_dly_i;

  genvar rden_dly_var;
  generate
    if (DEBUG_EN == 0) begin : gen_rden_dly_nodebug
      assign rden_dly_i = rden_dly;
    end else begin : gen_rden_dly_debug
      reg [DQS_WIDTH-1:0] rden_dly_en_l;
      reg [2*DQS_WIDTH-1:0] rden_dly_l;
      for (rden_dly_var=0;rden_dly_var<DQS_WIDTH;rden_dly_var=rden_dly_var+1) begin : gen_reg_rden_dly_ovr
	always @(posedge clk90)
	  if (rst90) begin
	    rden_dly_en_l[rden_dly_var] <= 1'b0;
	    rden_dly_l[rden_dly_var*2+:2] <= 6'b0;
	  end else if (dbg_calib_rden_dly_en[rden_dly_var]) begin
	    rden_dly_en_l[rden_dly_var] <= 1'b1;
	    rden_dly_l[rden_dly_var*2+:2] <= dbg_calib_rden_dly_value[rden_dly_var*2+:2];
	  end
        assign rden_dly_i[rden_dly_var*2+:2] = rden_dly_en_l[rden_dly_var] ? 
	  				       rden_dly_l[rden_dly_var*2+:2]: 
					       rden_dly[rden_dly_var*2+:2];
      end
    end
  endgenerate

  genvar gate_dly_var;
  generate
    if (DEBUG_EN == 0) begin : gen_gate_dly_nodebug
      assign gate_dly_i = gate_dly;
    end else begin : gen_gate_dly_debug
      reg [DQS_WIDTH-1:0] gate_dly_en_l;
      reg [2*DQS_WIDTH-1:0] gate_dly_l;
      for (gate_dly_var=0;gate_dly_var<DQS_WIDTH;gate_dly_var=gate_dly_var+1) begin : gen_reg_gate_dly_ovr
	always @(posedge clk90)
	  if (rst90) begin
	    gate_dly_en_l[gate_dly_var] <= 1'b0;
	    gate_dly_l[gate_dly_var*2+:2] <= 2'b0;
	  end else if (dbg_calib_gate_dly_en[gate_dly_var]) begin
	    gate_dly_en_l[gate_dly_var] <= 1'b1;
	    gate_dly_l[gate_dly_var*2+:2] <= dbg_calib_gate_dly_value[gate_dly_var*2+:2];
	  end
        assign gate_dly_i[gate_dly_var*2+:2] = gate_dly_en_l[gate_dly_var] ? 
	  				       gate_dly_l[gate_dly_var*2+:2]: 
					       gate_dly[gate_dly_var*2+:2];
      end
    end
  endgenerate

  //***************************************************************************
  // Translation from CLK0 -> CLK90 and vice versa (control signals)
  //***************************************************************************

  // synchronize incrementally to improve timing. Note that going from
  // CLK0 -> CLK90 is a 2-step process (0->270, 270->90) to avoid 1/4 cyc path
  always @(negedge clk90) begin
    calib_start_270   <= calib_start_0;
    phy_init_done_270 <= phy_init_done_0;
    ctrl_rden_270     <= ctrl_rden_0;       // sync'ed to CLK90 in RDEN pipe
    phy_init_rden_270 <= phy_init_rden_0;   // sync'ed to CLK90 in RDEN pipe
    calib_ref_done_270 <= calib_ref_done_0;
  end
    
  always @(posedge clk90) begin
    calib_start   <= calib_start_270;
    phy_init_done <= phy_init_done_270;
    calib_ref_done <= calib_ref_done_270;
  end
    
  always @(posedge clk0) begin
    calib_done_0 <= calib_done;
    calib_err_0  <= calib_err;
    calib_ref_req_0 <= calib_ref_req;
  end

  //***************************************************************************
  
  // register incoming capture data to improve timing. Adding single pipeline
  // stage does not affect functionality (as long as we make sure to wait
  // extra clock cycle after changing DQ IDELAY)
  always @(posedge clk90) begin
    rd_data_rise_r  <= rd_data_rise;
    rd_data_fall_r  <= rd_data_fall;
  end

  // furthur register a subset of the incoming captured data to use in 
  // stage 3 and 4 calibration to check incoming data pattern. 
  // NOTE: Can combine this with MUXing from stages 3 and 4 to save resources
  genvar rdd_i;
  generate
    for (rdd_i = 0; rdd_i < DQS_WIDTH; rdd_i = rdd_i + 1) begin: gen_rdd
      always @(posedge clk90) begin
        rd_data_rise_chk_r1[(2*rdd_i)] <= 
          rd_data_rise_r[(rdd_i*DQ_PER_DQS)];
        rd_data_rise_chk_r1[(2*rdd_i)+1] <= 
          rd_data_rise_r[(rdd_i*DQ_PER_DQS)+1];
        rd_data_fall_chk_r1[(2*rdd_i)] <= 
          rd_data_fall_r[(rdd_i*DQ_PER_DQS)];
        rd_data_fall_chk_r1[(2*rdd_i)+1] <= 
          rd_data_fall_r[(rdd_i*DQ_PER_DQS)+1];

        rd_data_rise_chk_r2[(2*rdd_i)] <= 
          rd_data_rise_chk_r1[(2*rdd_i)];
        rd_data_rise_chk_r2[(2*rdd_i)+1] <= 
          rd_data_rise_chk_r1[(2*rdd_i)+1];
        rd_data_fall_chk_r2[(2*rdd_i)] <= 
          rd_data_fall_chk_r1[(2*rdd_i)];
        rd_data_fall_chk_r2[(2*rdd_i)+1] <= 
          rd_data_fall_chk_r1[(2*rdd_i)+1];
      end
    end
  endgenerate 

  
  //***************************************************************************
  // Demultiplexor to control (reset, increment, decrement) IDELAY tap values
  //   For DQ:
  //     STG1: for per-bit-deskew, only inc/dec the current DQ. For non-per 
  //       deskew, increment all bits in the current DQS set
  //     STG2: inc/dec all DQ's in the current DQS set.  
  // NOTE: Nice to add some error checking logic here (or elsewhere in the
  //       code) to check if logic attempts to overflow tap value
  //***************************************************************************

  // don't use DLYRST to reset value of IDELAY after reset. Need to change this
  // if we want to allow user to recalibrate after initial reset
  always @(posedge clk90)
    if (rst90) begin
      dlyrst_dq <= 1'b1;
      dlyrst_dqs <= 1'b1;
    end else begin
      dlyrst_dq <= 1'b0;
      dlyrst_dqs <= 1'b0;
    end
  
  always @(posedge clk90) begin
    if (rst90) begin
      dlyce_dq   <= {DQ_WIDTH{1'b0}};
      dlyinc_dq  <= {DQ_WIDTH{1'b0}};
      dlyce_dqs  <= {DQS_WIDTH{1'b0}};
      dlyinc_dqs <= {DQS_WIDTH{1'b0}};
    end 
    else begin
      dlyce_dq   <= {DQ_WIDTH{1'b0}};
      dlyinc_dq  <= {DQ_WIDTH{1'b0}};
      dlyce_dqs  <= {DQS_WIDTH{1'b0}};
      dlyinc_dqs <= {DQS_WIDTH{1'b0}};

      // stage 1 cal: change only specified DQ
      if (cal1_dlyce_dq) begin
        dlyce_dq[count_dq] <= 1'b1;
        dlyinc_dq[count_dq] <= cal1_dlyinc_dq;
      end else if (cal2_dlyce_dqs) begin
        // stage 2 cal: change DQS and all corresponding DQ's
        dlyce_dqs[count_dqs] <= 1'b1;
        dlyinc_dqs[count_dqs] <= cal2_dlyinc_dqs;
        for (i = 0; i < DQ_PER_DQS; i = i + 1) begin: loop_dly
          dlyce_dq[(DQ_PER_DQS*count_dqs)+i] <= 1'b1;
          dlyinc_dq[(DQ_PER_DQS*count_dqs)+i] <= cal2_dlyinc_dqs;
        end
      end else if (DEBUG_EN != 0) begin
        // DEBUG: allow user to vary IDELAY tap settings
        // For DQ IDELAY taps
        if (dbg_idel_up_all || dbg_idel_down_all ||
            dbg_sel_all_idel_dq) begin
          for (x = 0; x < DQ_WIDTH; x = x + 1) begin: loop_dly_inc_dq
            dlyce_dq[x] <= dbg_idel_up_all | dbg_idel_down_all |
                           dbg_idel_up_dq  | dbg_idel_down_dq;
            dlyinc_dq[x] <= dbg_idel_up_all | dbg_idel_up_dq;
          end
        end else begin
          dlyce_dq <= 'b0;
          dlyce_dq[dbg_sel_idel_dq] <= dbg_idel_up_dq |
                                       dbg_idel_down_dq;
          dlyinc_dq[dbg_sel_idel_dq] <= dbg_idel_up_dq;
        end
        // For DQS IDELAY taps
        if (dbg_idel_up_all || dbg_idel_down_all ||
            dbg_sel_all_idel_dqs) begin
          for (x = 0; x < DQS_WIDTH; x = x + 1) begin: loop_dly_inc_dqs
            dlyce_dqs[x] <= dbg_idel_up_all | dbg_idel_down_all |
                            dbg_idel_up_dqs | dbg_idel_down_dqs;
            dlyinc_dqs[x] <= dbg_idel_up_all | dbg_idel_up_dqs;
          end
        end else begin
          dlyce_dqs <= 'b0;
          dlyce_dqs[dbg_sel_idel_dqs] <= dbg_idel_up_dqs |
                                         dbg_idel_down_dqs;
          dlyinc_dqs[dbg_sel_idel_dqs] <= dbg_idel_up_dqs;
        end
      end
    end
  end

  // GATE synchronization is handled directly by Stage 4 calibration FSM
  always @(posedge clk90)
    if (rst90) begin
      dlyrst_gate <= {DQS_WIDTH{1'b1}};
      dlyce_gate  <= {DQS_WIDTH{1'b0}};
      dlyinc_gate <= {DQS_WIDTH{1'b0}};
    end else begin
      dlyrst_gate <= {DQS_WIDTH{1'b0}};
      dlyce_gate  <= {DQS_WIDTH{1'b0}};
      dlyinc_gate <= {DQS_WIDTH{1'b0}};

      dlyrst_gate[count_gate] <= cal4_dlyrst_gate;
      if (cal4_dlyce_gate) begin
        dlyce_gate[count_gate]  <= 1'b1;
        dlyinc_gate[count_gate] <= cal4_dlyinc_gate;
      end else if (DEBUG_EN != 0) begin
        // DEBUG: allow user to vary IDELAY tap settings
        if (dbg_idel_up_all || dbg_idel_down_all ||
            dbg_sel_all_idel_gate) begin
          for (x = 0; x < DQS_WIDTH; x = x + 1) begin: loop_dly_inc_gate
            dlyce_gate[x] <= dbg_idel_up_all | dbg_idel_down_all |
                             dbg_idel_up_gate | dbg_idel_down_gate;
            dlyinc_gate[x] <= dbg_idel_up_all | dbg_idel_up_gate;
          end
        end else begin
          dlyce_gate <= {DQS_WIDTH{1'b0}};
          dlyce_gate[dbg_sel_idel_gate] <= dbg_idel_up_gate |
                                           dbg_idel_down_gate;
          dlyinc_gate[dbg_sel_idel_gate] <= dbg_idel_up_gate;
        end
      end
    end

  //***************************************************************************
  // signal to tell calibration state machines to wait and give IDELAY time to
  // settle after it's value is changed (both time for IDELAY chain to settle,
  // and for settled output to propagate through ISERDES). For general use: use
  // for any calibration state machines that modify any IDELAY. Should give at
  // least 2*5ns (worst case "guess", based on IDELAY being 5ns max) + 2 clock 
  // cycles = 10ns + 2 clock cycles
  //***************************************************************************

  // combine requests to modify any of the IDELAYs into one. Also add when
  // DQS is inverted (this also requires settling time)
  assign dlyce_or = cal1_dlyce_dq | 
                    cal2_dlyce_dqs |
                    cal4_dlyce_gate |
                    cal4_dlyrst_gate;
  
  // SYN_NOTE: Can later recode to avoid combinational path
  assign idel_set_wait = dlyce_or || (idel_set_cnt != IDEL_SET_VAL);  

  always @(posedge clk90)
    if (rst90)
      idel_set_cnt <= 4'b0000;
    else if (dlyce_or)
      idel_set_cnt <= 4'b0000;
    else if (idel_set_cnt != IDEL_SET_VAL)
      idel_set_cnt <= idel_set_cnt + 1;
        
  // generate request to PHY_INIT logic to issue auto-refresh
  // used by certain states to force prech/auto-refresh part way through
  // calibration to avoid a tRAS violation (which will happen if that
  // stage of calibration lasts long enough). This signal must meet the
  // following requirements: (1) only transition from 0->1 when the refresh
  // request is needed, (2) stay at 1 and only transition 1->0 when
  // CALIB_REF_DONE is asserted 
  always @(posedge clk90)
    if (rst90)
      calib_ref_req <= 1'b0;
    else
      calib_ref_req <= cal1_ref_req | cal2_ref_req | cal4_ref_req;

  // stage 1 calibration requests auto-refresh every 4 bits
  generate
    if (DQ_BITS < 2) begin: gen_cal1_refresh_dq_lte4
      assign cal1_refresh = 1'b0;
    end else begin: gen_cal1_refresh_dq_gt4
      assign cal1_refresh = (next_count_dq[1:0] == 2'b00);
    end
  endgenerate
        
  //***************************************************************************
  // First stage calibration: DQ-DQS
  // Definitions:
  //  edge: detected when varying IDELAY, and current capture data != prev 
  //    capture data
  //  valid bit window: detected when current capture data == prev capture 
  //    data for more than half the bit time 
  //  starting conditions for DQS-DQ phase:
  //    case 1: when DQS starts somewhere in rising edge bit window, or
  //      on the right edge of the rising bit window. 
  //    case 2: when DQS starts somewhere in falling edge bit window, or
  //      on the right edge of the falling bit window.    
  // Algorithm Description:
  //  1. Increment DQ IDELAY until we find an edge. 
  //  2. While we're finding the first edge, note whether a valid bit window
  //     has been detected before we found an edge. If so, then figure out if
  //     this is the rising or falling bit window. If rising, then our starting
  //     DQS-DQ phase is case 1. If falling, then it's case 2. If don't detect
  //     a valid bit window, then we must have started on the edge of a window.
  //     Need to wait until later on to decide which case we are.
  //       - Store FIRST_EDGE IDELAY value
  //  3. Now look for second edge. 
  //  4. While we're finding the second edge, note whether valid bit window 
  //     is detected. If so, then use to, along with results from (2) to figure
  //     out what the starting case is. If in rising bit window, then we're in
  //     case 2. If falling, then case 1.
  //       - Store SECOND_EDGE IDELAY value
  //     NOTES: 
  //       a. Finding two edges allows us to calculate the bit time (although
  //          not the "same" bit time polarity - need to investigate this 
  //          more).
  //       b. If we run out of taps looking for the second edge, then the bit 
  //       time must be too long (>= 2.5ns, and DQS-DQ starting phase must be
  //       case 1).
  //  5. Calculate absolute amount to delay DQ as:
  //       If second edge found, and case 1:
  //         - DQ_IDELAY = FIRST_EDGE - 0.5*(SECOND_EDGE - FIRST_EDGE)
  //       If second edge found, and case 2:
  //         - DQ_IDELAY = SECOND_EDGE - 0.5*(SECOND_EDGE - FIRST_EDGE)
  //       If second edge not found, then need to make an approximation on
  //       how much to shift by (should be okay, because we have more timing
  //       margin):
  //         - DQ_IDELAY = FIRST_EDGE - 0.5 * (bit_time)
  //     NOTE: Does this account for either case 1 or case 2?????  
  //     NOTE: It's also possible even when we find the second edge, that
  //           to instead just use half the bit time to subtract from either
  //           FIRST or SECOND_EDGE. Finding the actual bit time (which is
  //           what (SECOND_EDGE - FIRST_EDGE) is, is slightly more accurate,
  //           since it takes into account duty cycle distortion.
  //  6. Repeat for each DQ in current DQS set.
  //***************************************************************************

  //*****************************************************************
  // for first stage calibration - used for checking if DQS is aligned to the
  // particular DQ, such that we're in the data valid window. Basically, this
  // is one giant MUX. 
  //  = [falling data, rising data]
  //  = [0, 1] = rising DQS aligned in proper (rising edge) bit window
  //  = [1, 0] = rising DQS aligned in wrong (falling edge) bit window
  //  = [0, 0], or [1,1] = in uncertain region between windows
  //*****************************************************************

  // SYN_NOTE: May have to split this up into multiple levels - MUX can get
  //  very wide - as wide as the data bus width 
  assign cal1_data_chk = 
    {rd_data_fall_r[next_count_dq],
     rd_data_rise_r[next_count_dq]};

  // register for timing purposes
  always @(posedge clk90)
    cal1_data_chk_r <= cal1_data_chk;  

  //*****************************************************************
  // determine when an edge has occurred - when either the current value
  // is different from the previous latched value or when the DATA_CHK
  // outputs are the same (rare, but indicates that we're at an edge) 
  // This is only valid when the IDELAY output has had a chance to
  // settle out first.
  //*****************************************************************

  assign cal1_detect_edge = ((cal1_data_chk_r != cal1_data_chk_last) &&
                             cal1_data_chk_last_valid) ||
                            (cal1_data_chk_r == 2'b11) ||
                            (cal1_data_chk_r == 2'b00);

  assign cal1_detect_stable = ((cal1_data_chk_r == cal1_data_chk_last) &&
                               cal1_data_chk_last_valid) &&
                              ((cal1_data_chk_r == 2'b01) ||
                               (cal1_data_chk_r == 2'b10));
  
  //*****************************************************************
  // Find valid window: keep track of how long we've been in the same data 
  // window. If it's been long enough, then declare that we've found a valid 
  // window. Also returns whether we found a rising or falling window (only
  // valid when found_window is asserted)
  //*****************************************************************

  always @(posedge clk90) begin
    if (cal1_state == CAL1_INIT) begin
      cal1_window_cnt   <= 4'b0000;
      cal1_found_window <= 1'b0;
      cal1_found_rising <= 1'bx;
    end else if (!cal1_data_chk_last_valid) begin
      // if we haven't stored a previous value of CAL1_DATA_CHK (or it got
      // invalidated because we detected an edge, and are now looking for the
      // second edge), then make sure FOUND_WINDOW deasserted on following
      // clock edge (to avoid finding a false window immediately after finding
      // an edge). Note that because of jitter, it's possible to not find an
      // edge at the end of the IDELAY increment settling time, but to find an
      // edge on the next clock cycle (e.g. during CAL1_FIND_FIRST_EDGE)
      cal1_window_cnt   <= 4'b0000;
      cal1_found_window <= 1'b0;
      cal1_found_rising <= 1'bx;            
    end else if (((cal1_state == CAL1_FIRST_EDGE_IDEL_WAIT) ||
                  (cal1_state == CAL1_SECOND_EDGE_IDEL_WAIT)) && 
                 !idel_set_wait) begin      
      // while finding the first and second edges, see if we can detect a
      // stable bit window (occurs over MIN_WIN_SIZE number of taps). If
      // so, then we're away from an edge, and can conclusively determine the 
      // starting DQS-DQ phase. 
      if (cal1_detect_stable) begin
        cal1_window_cnt <= cal1_window_cnt + 1;
        if (cal1_window_cnt == MIN_WIN_SIZE-1) begin
          cal1_found_window <= 1'b1;
          if (cal1_data_chk_r == 2'b01)
            cal1_found_rising <= 1'b1;
          else
            cal1_found_rising <= 1'b0;
        end 
      end else begin
        // otherwise, we're not in a data valid window, reset the window 
        // counter, and indicate we're not currently in window. This should
        // happen by design at least once after finding the first edge. 
        cal1_window_cnt <= 4'b0000;
        cal1_found_window <= 1'b0;
        cal1_found_rising <= 1'bx;
      end
    end
  end

  //*****************************************************************
  // keep track of edge tap counts found, and whether we've 
  // incremented to the maximum number of taps allowed
  //*****************************************************************

  always @(posedge clk90)
    if (cal1_state == CAL1_INIT) begin
      cal1_idel_tap_limit_hit   <= 1'b0;
      cal1_idel_tap_cnt   <= 6'b000000;
    end else if (cal1_dlyce_dq) begin
      if (cal1_dlyinc_dq) begin
        cal1_idel_tap_cnt <= cal1_idel_tap_cnt + 1;
        cal1_idel_tap_limit_hit <= (cal1_idel_tap_cnt == 6'b111110);
      end else begin
        cal1_idel_tap_cnt <= cal1_idel_tap_cnt - 1;
        cal1_idel_tap_limit_hit <= 1'b0;
      end
    end
 
  //*****************************************************************    
  // Pipeline for better timing - amount to decrement by if second
  // edge not found
  //*****************************************************************    
  // if only one edge found (possible for low frequencies), then:
  //  1. Assume starting DQS-DQ phase has DQS in DQ window (aka "case 1")
  //  2. We have to decrement by (63 - first_edge_tap_cnt) + (BIT_TIME_TAPS/2)
  //     (i.e. decrement by 63-first_edge_tap_cnt to get to right edge of
  //     DQ window. Then decrement again by (BIT_TIME_TAPS/2) to get to center
  //     of DQ window. 
  //  3. Clamp the above value at 63 to ensure we don't underflow IDELAY 
  assign cal1_low_freq_idel_dec_raw = 7'b0111111 - 
                                      {1'b0, cal1_first_edge_tap_cnt} +
                                      {2'b0, BIT_TIME_TAPS[5:1]};
  
  always @(posedge clk90)
    if (cal1_low_freq_idel_dec_raw <= 7'b0111111)
      cal1_low_freq_idel_dec <= cal1_low_freq_idel_dec_raw;
    else
      cal1_low_freq_idel_dec <= 7'b0111111;

  //*****************************************************************
  // Keep track of max taps used during stage 1, use this to limit
  // the number of taps that can be used in stage 2
  //*****************************************************************

  always @(posedge clk90)
    if (rst90) begin
      cal1_idel_max_tap    <= 6'b000000;
      cal1_idel_max_tap_we <= 1'b0;
    end else begin      
      // pipeline latch enable for CAL1_IDEL_MAX_TAP - we have plenty
      // of time, tap count gets updated, then dead cycles waiting for
      // IDELAY output to settle
      cal1_idel_max_tap_we <= (cal1_idel_max_tap < cal1_idel_tap_cnt);
      // record maximum # of taps used for stg 1 cal
      if ((cal1_state == CAL1_DONE) && cal1_idel_max_tap_we)
        cal1_idel_max_tap <= cal1_idel_tap_cnt;
    end
  
  //*****************************************************************    
  
  always @(posedge clk90)    
    if (rst90) begin
      calib_done[0]            <= 1'b0;
      calib_done_tmp[0]        <= 1'bx;
      calib_err[0]             <= 1'b0;
      count_dq                 <= {DQ_BITS{1'b0}};
      next_count_dq            <= {DQ_BITS{1'b0}};
      cal1_bit_time_tap_cnt    <= 6'bxxxxxx;
      cal1_data_chk_last       <= 2'bxx;
      cal1_data_chk_last_valid <= 1'bx;
      cal1_dlyce_dq            <= 1'b0;
      cal1_dlyinc_dq           <= 1'b0;
      cal1_dqs_dq_init_phase   <= 1'bx;
      cal1_first_edge_done     <= 1'bx;
      cal1_found_second_edge   <= 1'bx;
      cal1_first_edge_tap_cnt  <= 6'bxxxxxx;
      // MIG 2.1: Bug fix for low freq case when two edges found 
      // during stg1 cal - cal1_idel_dec_cnt can overflow if 6 bits
      cal1_idel_dec_cnt        <= 7'bxxxxxxx;
      cal1_idel_inc_cnt        <= 6'bxxxxxx;
      cal1_ref_req             <= 1'b0;      
      cal1_state               <= CAL1_IDLE;
    end else begin
      // default values for all "pulse" outputs
      cal1_ref_req        <= 1'b0;
      cal1_dlyce_dq       <= 1'b0;
      cal1_dlyinc_dq      <= 1'b0;
      
      case (cal1_state)
        CAL1_IDLE:
          if (calib_start[0]) begin
            calib_done[0] <= 1'b0;
            calib_done_tmp[0] <= 1'b0;
            cal1_state    <= CAL1_INIT;
          end

        CAL1_INIT: begin
          cal1_data_chk_last_valid <= 1'b0;
          cal1_found_second_edge <= 1'b0;
          cal1_dqs_dq_init_phase <= 1'b0;
          cal1_idel_inc_cnt      <= 6'b000000;
          cal1_state <= CAL1_INC_IDEL;
        end

        // increment DQ IDELAY so that either: (1) DQS starts somewhere in
        // first rising DQ window, or (2) DQS starts in first falling DQ
        // window. The amount to shift is frequency dependent (and is either
        // precalculated by MIG or possibly adjusted by the user)
        CAL1_INC_IDEL:
          if ((cal1_idel_inc_cnt == DQ_IDEL_INIT) && !idel_set_wait) begin
            cal1_state <= CAL1_FIND_FIRST_EDGE;
          end else if (cal1_idel_inc_cnt != DQ_IDEL_INIT) begin
            cal1_idel_inc_cnt <= cal1_idel_inc_cnt + 1;
            cal1_dlyce_dq <= 1'b1;
            cal1_dlyinc_dq <= 1'b1;
          end   
        
        // look for first edge
        CAL1_FIND_FIRST_EDGE: begin
          // Determine DQS-DQ phase if we can detect enough of a valid window
          if (cal1_found_window)
            cal1_dqs_dq_init_phase <= ~cal1_found_rising;
          // find first edge - if found then record position
          if (cal1_detect_edge) begin
            cal1_state <= CAL1_FOUND_FIRST_EDGE_WAIT;
            cal1_first_edge_done   <= 1'b0;
            cal1_first_edge_tap_cnt <= cal1_idel_tap_cnt;
            cal1_data_chk_last_valid <= 1'b0;
          end else begin
            // otherwise, store the current value of DATA_CHK, increment 
            // DQ IDELAY, and compare again  
            cal1_state <= CAL1_FIRST_EDGE_IDEL_WAIT;
            cal1_data_chk_last <= cal1_data_chk_r;
            // avoid comparing against DATA_CHK_LAST for previous iteration
            cal1_data_chk_last_valid <= 1'b1;
            cal1_dlyce_dq <= 1'b1;
            cal1_dlyinc_dq <= 1'b1;         
          end          
        end

        // wait for DQ IDELAY to settle
        CAL1_FIRST_EDGE_IDEL_WAIT:          
          if (!idel_set_wait)
            cal1_state <= CAL1_FIND_FIRST_EDGE;

        // delay state between finding first edge and looking for second
        // edge. Necessary in order to invalidate CAL1_FOUND_WINDOW before
        // starting to look for second edge
        CAL1_FOUND_FIRST_EDGE_WAIT:
          cal1_state <= CAL1_FIND_SECOND_EDGE;          

        // Try and find second edge
        CAL1_FIND_SECOND_EDGE: begin
          // When looking for 2nd edge, first make sure data stabilized (by
          // detecting valid data window) - needed to avoid false edges
          if (cal1_found_window) begin
            cal1_first_edge_done <= 1'b1;
            cal1_dqs_dq_init_phase <= cal1_found_rising;
          end
          // exit if run out of taps to increment
          if (cal1_idel_tap_limit_hit)
            cal1_state <= CAL1_CALC_IDEL;      
          else begin
            // found second edge, record the current edge count
            if (cal1_first_edge_done && cal1_detect_edge) begin
              cal1_state <= CAL1_CALC_IDEL;
              cal1_found_second_edge <= 1'b1;
              cal1_bit_time_tap_cnt <= cal1_idel_tap_cnt - 
                                       cal1_first_edge_tap_cnt;
            end else begin
              cal1_state <= CAL1_SECOND_EDGE_IDEL_WAIT;
              cal1_data_chk_last <= cal1_data_chk_r;
              cal1_data_chk_last_valid <= 1'b1;
              cal1_dlyce_dq <= 1'b1;
              cal1_dlyinc_dq <= 1'b1;
            end
          end
        end

        // wait for DQ IDELAY to settle, then store ISERDES output
        CAL1_SECOND_EDGE_IDEL_WAIT:
          if (!idel_set_wait)
            cal1_state <= CAL1_FIND_SECOND_EDGE;
 
        // pipeline delay state to calculate amount to decrement DQ IDELAY
        // NOTE: We're calculating the amount to decrement by, not the
        //  absolute setting for DQ IDELAY
        CAL1_CALC_IDEL: begin
          // if two edges found
          if (cal1_found_second_edge)
            // case 1: DQS was in DQ window to start with. First edge found 
            // corresponds to left edge of DQ rising window. Backup by 1.5*BT
            // NOTE: In this particular case, it is possible to decrement 
            //  "below 0" in the case where DQS delay is less than 0.5*BT, 
            //  need to limit decrement to prevent IDELAY tap underflow
            if (!cal1_dqs_dq_init_phase)
              // MIG 2.1: Bug fix for low freq case when two edges found 
              // during stg1 cal - cal1_idel_dec_cnt can overflow if 6 bits
              cal1_idel_dec_cnt <= {1'b0, cal1_bit_time_tap_cnt} +
                                   {1'b0, (cal1_bit_time_tap_cnt >> 1)};
            // case 2: DQS was in wrong DQ window (in DQ falling window). 
            // First edge found is right edge of DQ rising window. Second 
            // edge is left edge of DQ rising window. Backup by 0.5*BT
            else
              cal1_idel_dec_cnt <= {1'b0, (cal1_bit_time_tap_cnt >> 1)};
          // if only one edge found - assume will always be case 1 - DQS in
          // DQS window. Case 2 only possible if path delay on DQS > 5ns 
          else
            cal1_idel_dec_cnt <= cal1_low_freq_idel_dec;
          cal1_state <= CAL1_DEC_IDEL;
        end
        
        // decrement DQ IDELAY for final adjustment
        CAL1_DEC_IDEL:
          // once adjustment is complete, we're done with calibration for
          // this DQ, now return to IDLE state and repeat for next DQ
          // Add underflow protection for case of 2 edges found and DQS
          // starting in DQ window (see comments for above state) - note we 
          // have to take into account delayed value of CAL1_IDEL_TAP_CNT -
          // gets updated one clock cycle after CAL1_DLYCE/INC_DQ
          if ((cal1_idel_dec_cnt == 7'b0000000) ||
              (cal1_dlyce_dq && (cal1_idel_tap_cnt == 6'b000001))) begin
            cal1_state <= CAL1_DONE;
            if (count_dq == DQ_WIDTH-1)
              calib_done_tmp[0] <= 1'b1;
            else
              // need for VHDL simulation to prevent out-of-index error
              next_count_dq <= count_dq + 1;
          end else begin
            // keep decrementing until final tap count reached
            cal1_idel_dec_cnt <= cal1_idel_dec_cnt - 1;
            cal1_dlyce_dq <= 1'b1;
            cal1_dlyinc_dq <= 1'b0;
          end

        // delay state to allow count_dq and DATA_CHK to point to the next
        // DQ bit (allows us to potentially begin checking for an edge on 
        // next DQ right away).
        CAL1_DONE:
          if (!idel_set_wait) begin
            count_dq <= next_count_dq;
            if (calib_done_tmp[0]) begin
              calib_done[0] <= 1'b1;
              cal1_state <= CAL1_IDLE;
            end else begin
              // request auto-refresh after every 8-bits calibrated to
              // avoid tRAS violation
              if (cal1_refresh) begin  
                cal1_ref_req <= 1'b1;
                if (calib_ref_done) 
                  cal1_state <= CAL1_INIT;
              end else
                // if no need this time for refresh, proceed to next bit
                cal1_state <= CAL1_INIT;
            end
          end
      endcase
    end

  //***************************************************************************
  // Second stage calibration: DQS-FPGA Clock
  // Algorithm Description:
  //  1. Increment DQS IDELAY until we find an edge - look at bit[0] of
  //     DQS group. DQ IDELAY is incremented in lock step with DQS. An edge is
  //     defined as either: as either: (1) a change in capture value or (2) an
  //     invalid capture value (e.g. rising data == falling data for that same
  //     clock cycle). It's possible we don't find an edge (at low frequencies)
  //     in this case, we stop if we run out of taps. Also note that we can't
  //     increment up to 63 taps when looking for an edge, instead, we only
  //     have (63 - max # taps used for Stage 1 calibration)
  //  2. Now calculate how much to either increment or decrement the tap delay
  //     depending on when and if we found an edge. Not that we only find one
  //     edge, then determine how much to back off based on the BIT_TIME_TAPS
  //     parameter (rather than finding two edges, dividing the delta by 2, and
  //     backing off by that amount).
  //       - If an edge found, then:
  //         * If we can back off by BIT_TIME_TAPS, then do so (i.e. if edge
  //           found at BIT_TIME_TAPS taps or greater)
  //         * If we can't, but we can increment by BIT_TIME_TAPS, then do so
  //         * If we can't do either (happens at lower frequencies), then
  //           figure out whether we can get closer to the midpoint by either
  //           decrementing down to 0, or incrementing up to the maximum # of
  //           taps (this is not 63 - since we have to reserve taps for the
  //           first stage)
  //       - If an edge not found, then:
  //         * Decrement by half the number of taps transfered. This
  //           guarantees we have at least (0.5 * max taps) of leading and
  //           trailing edge margin. It's not optimal, but then again, we
  //           "don't know exactly where we are" in terms of DQS-FPGA clock
  //           phase when we're unable to find an edge.
  //  3. Adjust DQS IDELAY based on results of step (2).
  //  4. Repeat for each DQS group.
  //***************************************************************************

  //*****************************************************************
  // Max number of taps used for stg2 cal dependent on number of taps
  // used for stg1 (give priority to stg1 cal - let it use as many
  // taps as it needs - the remainder of the IDELAY taps can be used
  // by stg2)
  //*****************************************************************

  always @(posedge clk90)
    cal2_idel_tap_limit <= 6'b111111 - cal1_idel_max_tap;
  
  //*****************************************************************
  // second stage calibration uses readback pattern of "1100" (i.e.
  // 1st rising = 1, 1st falling = 1, 2nd rising = 0, 2nd falling = 0)
  // only look at the first bit of each DQS group
  //*****************************************************************

  // register for timing purposes
  always @(posedge clk90) begin
    cal2_rd_data_fall_r <= rd_data_fall_r[next_count_dqs*DQ_PER_DQS];
    cal2_rd_data_rise_r <= rd_data_rise_r[next_count_dqs*DQ_PER_DQS];
  end

  // deasserted when captured data has changed since IDELAY was
  // incremented, or when we're right on the edge (i.e. rise data =
  // fall data). NOTE: Only valid when CAL2_TOGGLE = 1
  assign cal2_detect_edge =
    ((((cal2_rd_data_fall_r != cal2_rd_data_fall_last) ||
       (cal2_rd_data_rise_r != cal2_rd_data_rise_last)) &&
      cal2_rd_data_last_valid) ||
     (cal2_rd_data_rise_r != cal2_rd_data_fall_r));
                           
  //*****************************************************************
  // keep track of edge tap counts found, and whether we've 
  // incremented to the maximum number of taps allowed (NOTE: Unlike
  // for stage 1, we do need to check both for inc and dec). Don't
  // have underflow check, only overflow. 
  //*****************************************************************

  always @(posedge clk90)
    if (cal2_state == CAL2_INIT) begin
      cal2_idel_tap_limit_hit <= 1'b0;
      cal2_idel_tap_cnt <= 6'b000000;
    end else if (cal2_dlyce_dqs) begin
      if (cal2_dlyinc_dqs) begin
        cal2_idel_tap_cnt <= cal2_idel_tap_cnt + 1;
        cal2_idel_tap_limit_hit <= (cal2_idel_tap_cnt == 
                                    cal2_idel_tap_limit - 1); 
      end else begin
        cal2_idel_tap_cnt <= cal2_idel_tap_cnt - 1;
        cal2_idel_tap_limit_hit <= 1'b0;
      end
    end

  //*****************************************************************
  // Once we find the first edge, need to make a decision on whether
  // to decrement or increment the DQ/DQS IDELAY tap counts, and how
  // much to increment them by
  // NOTE: These values are pipelined, and it's assumed by design
  //  that these values will be used at a minimum one clock cycle
  //  after the sub-terms change value - this means one clock cycle
  //  for calculating cal2_tap_limit_delta before cal2_dec_zero and
  //  cal2_inc_bit_time can be calculated - hence the requirement
  //  for state CAL2_CALC_STALL
  //*****************************************************************

  always @(posedge clk90) begin
    // difference between edge tap and max tap count - use if we can't
    // dec/inc by BIT TIME
    cal2_tap_limit_delta <= cal2_idel_tap_limit - cal2_idel_tap_cnt;
    // asserted if best to decrement by BIT TIME
    cal2_dec_bit_time    <= (cal2_idel_tap_cnt > BIT_TIME_TAPS);
    // asserted if best to increment by BIT TIME
    cal2_inc_bit_time    <= (cal2_tap_limit_delta > BIT_TIME_TAPS);
    // asserted if best to decrement tap count to 0
    cal2_dec_zero        <= (cal2_tap_limit_delta < cal2_idel_tap_cnt);
  end
  
  //*****************************************************************
  
  always @(posedge clk90)    
    if (rst90) begin
      calib_done[1]           <= 1'b0;
      calib_done_tmp[1]       <= 1'bx;
      calib_err[1]            <= 1'b0;
      count_dqs               <= {DQS_BITS_FIX{1'b0}};
      next_count_dqs          <= {DQS_BITS_FIX{1'b0}};
      cal2_dlyce_dqs          <= 1'b0;
      cal2_dlyinc_dqs         <= 1'b0;                            
      cal2_found_edge         <= 1'bx;
      cal2_idel_adj_inc       <= 1'bx;
      cal2_idel_adj_cnt       <= 6'bxxxxxx;
      cal2_rd_data_last_valid <= 1'bx;
      cal2_ref_req             <= 1'b0; 
      cal2_state              <= CAL2_IDLE;
      cal2_toggle             <= 1'bx;
    end else begin
      cal2_ref_req        <= 1'b0;
      cal2_dlyce_dqs    <= 1'b0;
      cal2_dlyinc_dqs   <= 1'b0;
      cal2_toggle       <= ~cal2_toggle;
      
      case (cal2_state)
        CAL2_IDLE:
          if (calib_start[1]) begin
            calib_done[1]     <= 1'b0;
            calib_done_tmp[1] <= 1'b0;
            cal2_state        <= CAL2_INIT;
          end

        CAL2_INIT: begin
          cal2_rd_data_last_valid <= 1'b0;
          cal2_toggle             <= 1'b1;
          cal2_found_edge         <= 1'b0;
          cal2_state              <= CAL2_FIND_EDGE;
        end
          
        CAL2_FIND_EDGE: begin
          // if we find an edge (or run out of taps looking for an edge) -
          // need to start calculating how much to either increment or
          // decrement IDELAY
          if (cal2_detect_edge || cal2_idel_tap_limit_hit) begin
            cal2_state <= CAL2_CALC_IDEL_STALL;
            // record if we found an edge
            cal2_found_edge <= cal2_detect_edge;
            // DEBUG_ONLY: record first edge tap count
            cal2_edge_tap_cnt <= cal2_idel_tap_cnt;
          end else begin
            // if haven't yet found an edge, and haven't yet reached max # of
            // taps, increment IDELAY, and keep looking for an edge
            cal2_state <= CAL2_FIND_EDGE_IDEL_WAIT;
            cal2_rd_data_rise_last <= cal2_rd_data_rise_r;
            cal2_rd_data_fall_last <= cal2_rd_data_fall_r;
            cal2_rd_data_last_valid <= 1'b1;
            cal2_dlyce_dqs  <= 1'b1;
            cal2_dlyinc_dqs <= 1'b1;
          end
        end
           
        // wait for DQS/DQ IDELAY to settle
        CAL2_FIND_EDGE_IDEL_WAIT:
          // wait until both IDELAY/ISERDES has settled, and for the correct
          // toggle bit value (depends on whether we're calibrating with
          // inverted or noninverted DQS) - needed to remove restriction of
          // user having always to pick an even or odd value for settling time
          if (!idel_set_wait && !cal2_toggle)
            cal2_state <= CAL2_FIND_EDGE;

        // stall state - needed because of one cycle delay in calculating
        // certain terms that are needed in state CAL2_CALC_IDEL
        CAL2_CALC_IDEL_STALL:
          cal2_state <= CAL2_CALC_IDEL;
        // pipeline delay state to calculate amount to adjust DQ IDELAY
        CAL2_CALC_IDEL: begin
          cal2_state <= CAL2_ADJ_IDEL;    
          // if edge found:
          if (cal2_found_edge) begin
            if (cal2_dec_bit_time) begin
              // if we can decrement by bit time
              cal2_idel_adj_cnt <= BIT_TIME_TAPS;
              cal2_idel_adj_inc <= 1'b0;
            end else if (cal2_inc_bit_time) begin
              // if we can increment by bit time (into the next clock cycle)
              cal2_idel_adj_cnt <= BIT_TIME_TAPS;
              cal2_idel_adj_inc <= 1'b1;
            end else if (cal2_dec_zero) begin
              // if we don't have enough taps to either increment or decrement
              // by bit time (i.e. incrementing would take DQ/DQS taps above 
              // 63, decrementing would take us below 0), then:
              // if we can decrement more than we can increment, then do so
              cal2_idel_adj_cnt <= cal2_idel_tap_cnt;
              cal2_idel_adj_inc <= 1'b0;
            end else begin
              // otherwise, if incrementing to the max brings us closer to the
              // midpoint, then do so 
              cal2_idel_adj_cnt <= cal2_tap_limit_delta;
              cal2_idel_adj_inc <= 1'b1;
            end
          end else begin
            // if no edges found - back off (decrement) by half the tap
            // counts
            cal2_idel_adj_cnt <= {1'b0, cal2_idel_tap_cnt[5:1]};
            cal2_idel_adj_inc <= 1'b0;
          end
        end
          
        // increment/decrement DQS/DQ IDELAY for final adjustment
        CAL2_ADJ_IDEL:
          if (cal2_idel_adj_cnt == 6'b000000) begin
            cal2_state <= CAL2_DONE;
            if (count_dqs == DQS_WIDTH-1)
              calib_done_tmp[1] <= 1'b1;
            else
              // need for VHDL simulation to prevent out-of-index error
              next_count_dqs <= count_dqs + 1;        
          end else begin
            // keep decrementing/incrementing until final tap count reached
            cal2_idel_adj_cnt <= cal2_idel_adj_cnt - 1;
            cal2_dlyce_dqs    <= 1'b1;
            cal2_dlyinc_dqs   <= cal2_idel_adj_inc;
          end       

        // delay state to allow count_dqs and ISERDES data to point to next
        // DQ bit before going to idle
        CAL2_DONE:
          if (!idel_set_wait) begin
            count_dqs <= next_count_dqs;
            if (calib_done_tmp[1]) begin
              calib_done[1] <= 1'b1;
              cal2_state <= CAL2_IDLE;        
            end else begin
              // request auto-refresh after every DQS group calibrated to
              // avoid tRAS violation 
              cal2_ref_req <= 1'b1;
              if (calib_ref_done) 
                cal2_state <= CAL2_INIT;
            end
          end
      endcase
    end

  //***************************************************************************
  // Stage 3 calibration: Read Enable
  //***************************************************************************
  
  // don't start calibrating until told to do so, need this if initialization
  // logic will assert RDEN at times prior to start of Stage 2 calibration
  always @(posedge clk90)
    if (rst90)
      cal3_en <= 1'b0;
    else if (calib_start[2])
      cal3_en <= 1'b1;
    else if (calib_done[2])
      cal3_en <= 1'b0;
  
  // long delay chain to delay read enable signal from controller/
  // initialization logic (i.e. this is used for both initialization and
  // during normal controller operation). Stage 3 calibration logic decides 
  // which delayed version is appropriate to use (which is affected by the 
  // round trip delay of DQ/DQS) as a "valid" signal to tell rest of logic 
  // when the captured data output from ISERDES is valid. NOTE: Note all of 
  // these taps will be used - depends also on ADDITIVE_CAS_LATENCY, and 
  // whether various optional features (which result in extra pipeline 
  // delay) are enabled

  // first stage isn't registered; should only be used for DDR1
  always @(*)
    rden_stages_r[0] = ctrl_rden_270 | phy_init_rden_270;

  genvar rden_r_i;
  generate 
    for (rden_r_i = 1; rden_r_i <= RDEN_BASE_DELAY; 
         rden_r_i = rden_r_i + 1) begin: gen_rden_stages
      always @(posedge clk90)
        rden_stages_r[rden_r_i] <= rden_stages_r[rden_r_i-1];
    end
  endgenerate
    
  // read_en_r is the range of possible taps - one of which will ultimately
  // be used to generate the read valid for each DQS. READ_EN_R[0] is the
  // MINIMUM possible delay from issuance of read command until when
  // captured data at ISERDES output is valid
  // Analysis of what the minimum possible time is for read data to be
  // synchronized into CLK90 domain (i.e. don't consider any board delays)
  //   1. From rising edge of RDEN, 2 for CASn to be asserted at FPGA output
  //   2. Another half cycle for it to be latched into SDRAM (since falling
  //      edge of CLK0 corresponds to rising edge of SDRAM clock) or at the
  //      control/address register of a registered DIMM module
  //   3. Another 1 c/c if REG_ENABLE = 1
  //   4. CAS_LAT + ADDITIVE_CAS_LAT cycles for first data to appear
  //   5. Assume that data gets synchronized to CLK90 on the next CLK90 rising 
  //      edge - have 1 c/c through rank 1 of ISERDES, and 2 c/c through
  //      rank2/rank3 of ISERDES
  //   6. Add 1 c/c since during calibration, we start with the second word
  //      of the burst
  //   7. Add 3 c/c for determining CAL3_DATA_MATCH
  //   8. Add 1 c/c for if ECC enabled (ECC_ENABLE = 1)
  //   9. Subtract 1.25 c/c for synchronization between CLK0 and CLK90
  //   10. Total = 3 + 0.5 + REG_ENABLE + CAS_LAT + 
  //               ADDITIVE_CAS_LAT + 3 + 1 + 3 + ECC_ENABLE - 1.25
  //             = 8.25 + REG_ENABLE + CAS_LAT + ADDITIVE_CAS_LAT + ECC_ENABLE
  //             =~ 8 + REG_ENABLE + CAS_LAT + ADDITIVE_CAS_LAT + ECC_ENABLE
  //             = 8 + RDEN_DELAY = RDEN_BASE_DELAY
  //   Worst case minimum delay (for DDR2) is:
  //     REG_ENABLE = 1, CAS_LAT = 5, ADDITIVE_CAS_LAT = 4, ECC_ENABLE = 1
  //     total = 8 + 1 + 5 + 4 + 1 = 19
  // Pad with extra 3 clock cycles to account for propagation related delay
  // (PCB, package delay, output-clock skew) - up to 9ns at 333MHz  
  always @(*)
    rden_r[0] = rden_stages_r[RDEN_BASE_DELAY];

  always @(posedge clk90) begin
    rden_r[1] <= rden_r[0];
    rden_r[2] <= rden_r[1];
    rden_r[3] <= rden_r[2];
    rden_r[4] <= rden_r[3]; 
  end

  // used to determine one which clock cycle valid data is returned
  assign rden_edge = {rden_r[3] & ~rden_r[4],
                      rden_r[2] & ~rden_r[3],
                      rden_r[1] & ~rden_r[2],
                      rden_r[0] & ~rden_r[1]};
  
  //*****************************************************************
  // indicates that current received data is the correct pattern. Check both
  // rising and falling data for first 2 DQ's in each DQS group. Note that
  // we're checking using registered, and twice-registered version of ISERDES
  // output, so need to take this delay into account in determining final
  // read valid delay.
  // Expect data in sequence (in binary): 11, 10, 01, 00
  // We check for the presence of the two middle words (10, 01), and
  // compensate read valid delay accordingly
  // NOTE: Original read enable calibration data checking compared using more
  //       bits. Check if this is required. 
  //*****************************************************************

  always @(posedge clk90) begin
    cal3_data_match 
      <= ((rd_data_rise_r[(rden_cnt*DQ_PER_DQS+1)] == 0)  &&
          (rd_data_rise_r[(rden_cnt*DQ_PER_DQS)]   == 1)  &&
          (rd_data_rise_chk_r1[(2*rden_cnt)+1] == 1) &&
          (rd_data_rise_chk_r1[(2*rden_cnt)]   == 0) &&
          (rd_data_fall_r[(rden_cnt*DQ_PER_DQS)+1] == 0)  &&       
          (rd_data_fall_r[(rden_cnt*DQ_PER_DQS)]   == 1)  &&
          (rd_data_fall_chk_r1[(2*rden_cnt)+1] == 1) &&
          (rd_data_fall_chk_r1[(2*rden_cnt)]   == 0));
  end

  // when calibrating, check to see which clock cycle (after the read is
  // issued) does the expected data pattern arrive. Record this result
  // NOTE: Can add error checking here in case valid data not found on any
  //  of the available pipeline stages
  always @(posedge clk90) begin
    if (rst90) begin
      calib_done[2] <= 1'b0;
      calib_err[2]  <= 1'b0;
      rden_cnt      <= {DQS_WIDTH{1'b0}};
    end else
      if (!calib_done[2] && cal3_en) begin
        // NOTE: Need to add error checking later in case match not found
        case ({cal3_data_match, rden_edge})
          5'b10001: begin
            rden_dly[(rden_cnt*2)]   <= 1'b0;
            rden_dly[(rden_cnt*2)+1] <= 1'b0;
            if (rden_cnt == DQS_WIDTH-1)
              calib_done[2] <= 1'b1;
            else
              // need for VHDL simulation to prevent out-of-index error
              rden_cnt <= rden_cnt + 1;       
          end
          5'b10010: begin
            rden_dly[(rden_cnt*2)]   <= 1'b1;
            rden_dly[(rden_cnt*2)+1] <= 1'b0;
            if (rden_cnt == DQS_WIDTH-1)
              calib_done[2] <= 1'b1;
            else
              rden_cnt <= rden_cnt + 1;       
          end
          5'b10100: begin
            rden_dly[(rden_cnt*2)]   <= 1'b0;
            rden_dly[(rden_cnt*2)+1] <= 1'b1;
            rden_cnt <= rden_cnt + 1;
            if (rden_cnt == DQS_WIDTH-1)
              calib_done[2] <= 1'b1;
            else
              rden_cnt <= rden_cnt + 1;       
          end
          5'b11000: begin
            rden_dly[(rden_cnt*2)]   <= 1'b1;
            rden_dly[(rden_cnt*2)+1] <= 1'b1;
            rden_cnt <= rden_cnt + 1;
            if (rden_cnt == DQS_WIDTH-1)
              calib_done[2] <= 1'b1;
            else
              rden_cnt <= rden_cnt + 1;       
          end
        endcase
      end
  end
  
  // generate read valid signal for each DQS group. Subtract 5 from the
  // delay output of stg 3 cal (1 c/c because stg3 cal starts at 2nd word of
  // burst + 3 c/c because it takes 3 c/c to determine if a match was found +
  // 1 c/c because we still have to register I_CALIB_RDEN to produce the 
  // actual read valid signal that gets routed to User I/F)
  genvar rden_i;
  generate 
    for(rden_i = 0; rden_i < DQS_WIDTH; rden_i = rden_i + 1) begin: gen_rden
      always @(*) begin
        case ({rden_dly[(rden_i*2)+1], rden_dly[(rden_i*2)]})
          2'b00: 
            i_calib_rden[rden_i] = rden_stages_r[RDEN_BASE_DELAY-5];
          2'b01: 
            i_calib_rden[rden_i] = rden_stages_r[RDEN_BASE_DELAY-4];
          2'b10: 
            i_calib_rden[rden_i] = rden_stages_r[RDEN_BASE_DELAY-3];
          2'b11: 
            i_calib_rden[rden_i] = rden_stages_r[RDEN_BASE_DELAY-2];
        endcase
      end
  
      // keep CALIB_RDEN deasserted until calibration complete (i.e. stage 3 
      // finished), and initialization logic stops sending training reads;
      // else user will get rogue (i.e. unwanted) RDEN pulses during cal 
      always @(posedge clk90)
        calib_rden[rden_i] <= phy_init_done & i_calib_rden[rden_i];
    end
  endgenerate

  //***************************************************************************
  // Stage 4 calibration: DQS gate
  //***************************************************************************

  // delay RDEN so it matches CAL4_DATA_MATCH delay (2 cycles) + delay by
  // another 4 cycles since we indicate for data match after 4th cycle + 1
  // more cycle because we're using unregistered version of RDEN
  always @(posedge clk90)
    calib_rden_mux_r <= {calib_rden_mux_r[CAL4_RDEN_PIPE_LEN-2:0], 
                         i_calib_rden[next_count_gate]};

  always @(posedge clk90)
    if (calib_rden_mux_r[CAL4_RDEN_PIPE_LEN-2] && 
        !calib_rden_mux_r[CAL4_RDEN_PIPE_LEN-1]) begin
      cal4_rd_match       <= cal4_data_match;
      cal4_rd_match_valid <= 1'b1;
    end else begin
      cal4_rd_match       <= 1'b0;
      cal4_rd_match_valid <= 1'b0;
    end

  //*****************************************************************
  // generate DQS enable signal for each DQS group  
  // There are differences between DQS gate signal for calibration vs. during
  // normal operation:
  //  * calibration gates the second to last clock cycle of the burst, 
  //    rather than after the last word (e.g. for a 8-word, 4-cycle burst,
  //    cycle 4 is gated for calibration; during normal operation, cycle
  //    5 (i.e. cycle after the last word) is gated)  
  // enable for DQS is deasserted for two clock cycles, except when
  // we have the preamble for the next read immediately following
  // the postamble of the current read - assume DQS does not glitch
  // during this time, that it stays low. Also if we did have to gate
  // the DQS for this case, then we don't have enough time to deassert
  // the gate in time for the first rising edge of DQS for the second
  // read
  //*****************************************************************

  genvar gate_i;
  generate 
    for(gate_i = 0; gate_i < DQS_WIDTH; gate_i = gate_i + 1) begin: gen_gate
      always @(posedge clk90)
        // don't assert gate enable until stage 3 calibration finished -
        // we don't need it before then
        if (!calib_done[2])
          en_dqs[gate_i] <= 1'b1;
        else
          case ({gate_dly[(gate_i*2)+1], gate_dly[(gate_i*2)]})    
            2'b00:
              if (!calib_done[3])
                // gate during calibration (1 c/c ahead of normal operation)
                // don't worry about the case when we have read-idle-read, it
                // doesn't happen during calibration. Also
                en_dqs[gate_i] 
                  <= ~((~rden_stages_r[RDEN_BASE_DELAY-10] & 
                        rden_stages_r[RDEN_BASE_DELAY-9]) |
                       (~rden_stages_r[RDEN_BASE_DELAY-9] & 
                        rden_stages_r[RDEN_BASE_DELAY-8]) |
                       (~rden_stages_r[RDEN_BASE_DELAY-8] & 
                        rden_stages_r[RDEN_BASE_DELAY-7]));
              else
                // gate during normal operation
                en_dqs[gate_i]
                  <= ~((~rden_stages_r[RDEN_BASE_DELAY-10] &
                        ~rden_stages_r[RDEN_BASE_DELAY-9] &
                        rden_stages_r[RDEN_BASE_DELAY-8]) |
                       (~rden_stages_r[RDEN_BASE_DELAY-9] &
                        ~rden_stages_r[RDEN_BASE_DELAY-8] &
                        rden_stages_r[RDEN_BASE_DELAY-7]));
            2'b01:
              if (!calib_done[3])
                en_dqs[gate_i] 
                  <= ~((~rden_stages_r[RDEN_BASE_DELAY-9] & 
                        rden_stages_r[RDEN_BASE_DELAY-8]) |
                       (~rden_stages_r[RDEN_BASE_DELAY-8] & 
                        rden_stages_r[RDEN_BASE_DELAY-7]) |
                       (~rden_stages_r[RDEN_BASE_DELAY-7] & 
                        rden_stages_r[RDEN_BASE_DELAY-6]));
              else
                en_dqs[gate_i]
                  <= ~((~rden_stages_r[RDEN_BASE_DELAY-9] &
                        ~rden_stages_r[RDEN_BASE_DELAY-8] &
                        rden_stages_r[RDEN_BASE_DELAY-7]) |
                       (~rden_stages_r[RDEN_BASE_DELAY-8] &
                        ~rden_stages_r[RDEN_BASE_DELAY-7] &
                        rden_stages_r[RDEN_BASE_DELAY-6]));
            2'b10:
              if (!calib_done[3])
                en_dqs[gate_i] 
                  <= ~((~rden_stages_r[RDEN_BASE_DELAY-8] & 
                        rden_stages_r[RDEN_BASE_DELAY-7]) |
                       (~rden_stages_r[RDEN_BASE_DELAY-7] & 
                        rden_stages_r[RDEN_BASE_DELAY-6]) |
                       (~rden_stages_r[RDEN_BASE_DELAY-6] & 
                        rden_stages_r[RDEN_BASE_DELAY-5]));    
              else
                en_dqs[gate_i]
                  <= ~((~rden_stages_r[RDEN_BASE_DELAY-8] &
                        ~rden_stages_r[RDEN_BASE_DELAY-7] &
                        rden_stages_r[RDEN_BASE_DELAY-6]) |
                       (~rden_stages_r[RDEN_BASE_DELAY-7] &
                        ~rden_stages_r[RDEN_BASE_DELAY-6] &
                        rden_stages_r[RDEN_BASE_DELAY-5]));
            2'b11:
              if (!calib_done[3])
                en_dqs[gate_i]
                  <= ~((~rden_stages_r[RDEN_BASE_DELAY-7] & 
                        rden_stages_r[RDEN_BASE_DELAY-6]) |
                       (~rden_stages_r[RDEN_BASE_DELAY-6] & 
                        rden_stages_r[RDEN_BASE_DELAY-5]) |
                       (~rden_stages_r[RDEN_BASE_DELAY-5] & 
                        rden_stages_r[RDEN_BASE_DELAY-4]));
              else
                en_dqs[gate_i]
                  <= ~((~rden_stages_r[RDEN_BASE_DELAY-7] &
                        ~rden_stages_r[RDEN_BASE_DELAY-6] &
                        rden_stages_r[RDEN_BASE_DELAY-5]) |
                       (~rden_stages_r[RDEN_BASE_DELAY-6] &
                        ~rden_stages_r[RDEN_BASE_DELAY-5] &
                        rden_stages_r[RDEN_BASE_DELAY-4]));
          endcase
    end
  endgenerate

  //*****************************************************************
  // indicates that current received data is the correct pattern. Same as 
  // for READ VALID calibration, except that the expected data sequence is
  // different since DQS gate is asserted after the 3rd word.
  // Data sequence:
  //  Arrives from memory (at FPGA input) (bit[1:0]: 11 10 01 00
  //  After gating the sequence looks like: 11 10 01 01 (4th word = 3rd word)
  // NOTE: Need to check last 3 cycles of burst
  //   1. If gate is too early, sequence will be: 11 11 11 11 or 11 10 10 10 
  //   2. If gate timing is correct, sequence will be: 11 10 01 01
  //   3. If gate is too late, sequence will be: 11 10 01 00
  //*****************************************************************
 
  always @(posedge clk90) begin
    cal4_data_match 
      <= ((rd_data_rise_chk_r2[(2*next_count_gate)+1] == 1) &&
          (rd_data_rise_chk_r2[(2*next_count_gate)]   == 0) &&
          (rd_data_rise_chk_r1[(2*next_count_gate)+1] == 0) &&
          (rd_data_rise_chk_r1[(2*next_count_gate)]   == 1) &&
          (rd_data_rise_r[(next_count_gate*DQ_PER_DQS+1)] == 0) &&
          (rd_data_rise_r[(next_count_gate*DQ_PER_DQS)]   == 1) &&
          (rd_data_fall_chk_r2[(2*next_count_gate)+1] == 1) &&
          (rd_data_fall_chk_r2[(2*next_count_gate)]   == 0) &&
          (rd_data_fall_chk_r1[(2*next_count_gate)+1] == 0) &&
          (rd_data_fall_chk_r1[(2*next_count_gate)]   == 1) &&
          (rd_data_fall_r[(next_count_gate*DQ_PER_DQS+1)] == 0) &&
          (rd_data_fall_r[(next_count_gate*DQ_PER_DQS)]   == 1));
  end

  //*****************************************************************
  // Find valid window: keep track of how long we've been in the same data 
  // window. If it's been long enough, then declare that we've found a stable
  // valid window - in particular, that we're past any region of instability
  // associated with the edge of the window. Use only when finding left edge
  //*****************************************************************

  always @(posedge clk90)
    // reset before we start to look for window
    if (cal4_state == CAL4_INIT) begin
      cal4_window_cnt    <= 4'b0000;
      cal4_stable_window <= 1'b0;
    end else if ((cal4_state == CAL4_FIND_EDGE) && cal4_seek_left) begin
      // if we're looking for left edge, and incrementing IDELAY, count
      // consecutive taps over which we're in the window
      if (cal4_rd_match_valid) begin
        if (cal4_rd_match)
          cal4_window_cnt <= cal4_window_cnt + 1;
        else
          cal4_window_cnt <= 4'b0000;
      end

      if (cal4_window_cnt == MIN_WIN_SIZE-1)
        cal4_stable_window <= 1'b1;
    end 

  //*****************************************************************
  // keep track of edge tap counts found, and whether we've
  // incremented to the maximum number of taps allowed
  //*****************************************************************

  always @(posedge clk90)
    if ((cal4_state == CAL4_INIT) || cal4_dlyrst_gate) begin
      cal4_idel_max_tap <= 1'b0;
      cal4_idel_bit_tap <= 1'b0;
      cal4_idel_tap_cnt <= 6'b000000;
    end else if (cal4_dlyce_gate) begin
      if (cal4_dlyinc_gate) begin
        cal4_idel_tap_cnt <= cal4_idel_tap_cnt + 1;
        cal4_idel_bit_tap <= (cal4_idel_tap_cnt == CAL4_IDEL_BIT_VAL-2);
        cal4_idel_max_tap <= (cal4_idel_tap_cnt == 6'b111110);
      end else begin
        cal4_idel_tap_cnt <= cal4_idel_tap_cnt - 1;
        cal4_idel_bit_tap <= 1'b0;
        cal4_idel_max_tap <= 1'b0;
      end
    end

  always @(posedge clk90)
    if (cal4_state != CAL4_RDEN_PIPE_CLR_WAIT)
      cal4_rden_pipe_cnt <= CAL4_RDEN_PIPE_LEN-1;
    else
      cal4_rden_pipe_cnt <= cal4_rden_pipe_cnt - 1;

  //*****************************************************************
  // Stage 4 cal state machine
  //*****************************************************************
  
  always @(posedge clk90)    
    if (rst90) begin
      calib_done[3]     <= 1'b0;
      calib_done_tmp[3] <= 1'b0;
      calib_err[3]      <= 1'b0;
      count_gate        <= {DQS_BITS_FIX{1'b0}};
      gate_dly          <= {(2*DQS_BITS_FIX){1'b0}};
      next_count_gate   <= {DQS_BITS_FIX{1'b0}};
      cal4_idel_adj_cnt <= 6'bxxxxxx;
      cal4_dlyce_gate   <= 1'b0;
      cal4_dlyinc_gate  <= 1'b0;
      cal4_dlyrst_gate  <= 1'b0;    // reset handled elsewhere in code
      cal4_new_window   <= 1'bx;
      cal4_ref_req      <= 1'b0;
      cal4_seek_left    <= 1'bx;
      cal4_state        <= CAL4_IDLE;
    end else begin
      cal4_ref_req     <= 1'b0;
      cal4_dlyce_gate  <= 1'b0;
      cal4_dlyinc_gate <= 1'b0;
      cal4_dlyrst_gate <= 1'b0;

      case (cal4_state)
        CAL4_IDLE:
          if (calib_start[3]) begin
            calib_done[3] <= 1'b0;      
            cal4_state    <= CAL4_INIT;
          end

        // use by support logic as reset state, probably can get rid of this
        CAL4_INIT:
          cal4_state <= CAL4_FIND_WINDOW;
        
        // sort of an initial state - start checking to see whether we're
        // already in the window or not
        CAL4_FIND_WINDOW:
          // decide right away if we start in the proper window - this
          // determines if we are then looking for the left (trailing) or
          // right (leading) edge of the data valid window
          if (cal4_rd_match_valid) begin
            cal4_new_window <= 1'b0;
            // if we find a match - then we're already in window, now look
            // for left edge. Otherwise, look for right edge of window
            cal4_seek_left  <= cal4_rd_match;
            cal4_state      <= CAL4_FIND_EDGE;
          end
        
        CAL4_FIND_EDGE:
          // don't do anything until the exact clock cycle when to check that
          // readback data is valid or not
          if (cal4_rd_match_valid) begin
            // we're currently in the window, look for left edge of window
            if (cal4_seek_left) begin
              // make sure we've passed the right edge before trying to detect
              // the left edge (i.e. avoid any edge "instability") - else, we
              // may detect an "false" edge too soon. By design, if we start in
              // the data valid window, always expect at least
              // MIN(BIT_TIME_TAPS,32) (-/+ jitter, see below) taps of valid
              // window before we hit the left edge (this is because when stage
              // 4 calibration first begins (i.e., gate_dly = 00, and IDELAY =
              // 00), we're guaranteed to NOT be in the window, and we always
              // start searching for MIN(BIT_TIME_TAPS,32) for the right edge
              // of window. If we don't find it, increment gate_dly, and if we
              // now start in the window, we have at least approximately
              // CLK_PERIOD-MIN(BIT_TIME_TAPS,32) = MIN(BIT_TIME_TAPS,32) taps.
              // It's approximately because jitter, noise, etc. can bring this
              // value down slightly. Because of this (although VERY UNLIKELY),
              // we have to protect against not decrementing IDELAY below 0
              // during adjustment phase).
              if (cal4_stable_window && !cal4_rd_match) begin
                // found left edge of window, dec by MIN(BIT_TIME_TAPS,32)
                cal4_idel_adj_cnt <= CAL4_IDEL_BIT_VAL;
                cal4_idel_adj_inc <= 1'b0;
                cal4_state        <= CAL4_ADJ_IDEL;
              end else begin
                // Otherwise, keep looking for left edge:
                if (cal4_idel_max_tap) begin
                  // ran out of taps looking for left edge (max=63) - happens
                  // for low frequency case, decrement by 32
                  cal4_idel_adj_cnt <= 6'b100000;
                  cal4_idel_adj_inc <= 1'b0;
                  cal4_state        <= CAL4_ADJ_IDEL;
                end else begin
                  cal4_dlyce_gate  <= 1'b1;
                  cal4_dlyinc_gate <= 1'b1;
                  cal4_state       <= CAL4_IDEL_WAIT;
                end
              end
            end else begin
              // looking for right edge of window:
              // look for the first match - this means we've found the right
              // (leading) edge of the data valid window, increment by
              // MIN(BIT_TIME_TAPS,32)
              if (cal4_rd_match) begin
                cal4_idel_adj_cnt <= CAL4_IDEL_BIT_VAL;
                cal4_idel_adj_inc <= 1'b1;
                cal4_state        <= CAL4_ADJ_IDEL;
              end else begin
              // Otherwise, keep looking:
                // only look for MIN(BIT_TIME_TAPS,32) taps for right edge,
                // if we haven't found it, then inc gate delay, try again
                if (cal4_idel_bit_tap) begin
                  // if we're already maxed out on gate delay, then error out
                  // (simulation only - calib_err isn't currently connected)
                  if (gate_dly[(count_gate*2)+1] &&
                      gate_dly[(count_gate*2)]) begin
                    calib_err[3] <= 1'b1;
                    cal4_state   <= CAL4_IDLE;
                  end else begin
                    // this is an clamping adder - can't instantiate directly
                    // in HDL, at least not in verilog-can't have non-constant
                    // bit ranges. Whatever.
                    gate_dly[(count_gate*2)+1]
                      <= gate_dly[(count_gate*2)+1] | gate_dly[count_gate*2];
                    gate_dly[count_gate*2] <= ~gate_dly[count_gate*2];
                    cal4_dlyrst_gate <= 1'b1;
                    cal4_new_window  <= 1'b1;
                    cal4_state <= CAL4_IDEL_WAIT;
                  end
                end else begin
                  // keep looking for right edge
                  cal4_dlyce_gate  <= 1'b1;
                  cal4_dlyinc_gate <= 1'b1;
                  cal4_state       <= CAL4_IDEL_WAIT;
                end
              end
            end
          end

        // wait for GATE IDELAY to settle, after reset or increment
        CAL4_IDEL_WAIT:          
          if (!idel_set_wait)
            cal4_state <= CAL4_RDEN_PIPE_CLR_WAIT;                  
  
        // give additional time for RDEN_R pipe to clear from effects of 
        // previous pipeline or IDELAY tap change
        CAL4_RDEN_PIPE_CLR_WAIT: 
          if (cal4_rden_pipe_cnt == 4'b0000) begin
            // return to looking for either left or right edge, or if gate
            // delay was just incremented, look for new window
            if (cal4_new_window)
              cal4_state <= CAL4_FIND_WINDOW;
            else
              cal4_state <= CAL4_FIND_EDGE;
          end
        // increment/decrement DQS/DQ IDELAY for final adjustment
        CAL4_ADJ_IDEL:
          // add underflow protection for corner case when left edge found
          // using fewer than MIN(BIT_TIME_TAPS,32) taps
          if ((cal4_idel_adj_cnt == 6'b000000) ||
              (cal4_dlyce_gate && !cal4_dlyinc_gate &&
               (cal4_idel_tap_cnt == 6'b000001))) begin
            cal4_state <= CAL4_DONE;
            if (count_gate == DQS_WIDTH-1)
              calib_done_tmp[3] <= 1'b1;
            else
              // need for VHDL simulation to prevent out-of-index error
              next_count_gate <= count_gate + 1;
          end else begin
            cal4_idel_adj_cnt <= cal4_idel_adj_cnt - 1;
            cal4_dlyce_gate  <= 1'b1;
            // whether inc or dec depends on whether left or right edge found
            cal4_dlyinc_gate <= cal4_idel_adj_inc;
          end

        // wait for IDELAY output to settle after decrement. Check current 
        // COUNT_GATE value and decide if we're done
        CAL4_DONE:
          if (!idel_set_wait) begin
            count_gate <= next_count_gate;
            if (calib_done_tmp[3]) begin 
              calib_done[3] <= 1'b1;
              cal4_state <= CAL4_IDLE;
            end else begin
              // request auto-refresh after every DQS group calibrated to
              // avoid tRAS violation 
              cal4_ref_req <= 1'b1;
              if (calib_ref_done) 
                cal4_state <= CAL4_INIT;
            end
          end
      endcase
    end            
  
endmodule
