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

module v4_phy_tap_ctrl #
  (
   parameter integer tby4tapvalue = 17
   )
  (
   input         clk,
   input         reset,
   input         dq_data,
   input         ctrl_dummyread_start,
   output        dlyinc,
   output        dlyce,
   output        chan_done
   );

   // IDEL_SET_VAL = (# of cycles - 1) to wait after changing IDELAY value
   // we only have to wait enough for input with new IDELAY value to
   // propagate through pipeline stages
   localparam IDEL_SET_VAL = 3'b111;

   // Number of taps to be incremented or decremented after finding an edge.
   // i.e., min(32, T/4)
   localparam MAX_TAP_COUNT = (tby4tapvalue < 32) ? tby4tapvalue : 32;

   localparam    IDLE                = 4'h0;
   localparam    BIT_CALIBRATION     = 4'h1;
   localparam    INC                 = 4'h2;
   localparam    IDEL_WAIT           = 4'h3;
   localparam    EDGE                = 4'h4;
   localparam    EDGE_WAIT           = 4'h5;
   localparam    DEC                 = 4'h6;
   localparam    INC_TAPS            = 4'h7;
   localparam    DONE                = 4'h8;
   localparam    PIPE_WAIT           = 4'h9;

   reg           cal_detect_edge;
   reg           calib_start;
   reg [5:0]     curr_tap_cnt;
   reg [3:0]     current_state
                 /* synthesis syn_maxfan = 5 */;
   reg [5:0]     dec_tap_count;
   reg           dlyce_int;
   reg           dlyinc_int;
   reg           done_int;
   reg [5:0]     inc_tap_count;
   reg [2:0]     idel_set_cnt;
   wire          idel_set_wait;
   reg [3:0]     next_state
                 /* synthesis syn_maxfan = 5 */;
   reg           prev_dq;
   reg           reset_r1
                 /* synthesis syn_preserve=1 */;
   reg           tap_count_flag;
   reg           tap_count_rst;
   reg           tap_max_count_flag;

   //*******************************************************************

   // synthesis attribute equivalent_register_removal of reset_r1 is "no";
   always @( posedge clk )
     reset_r1 <= reset;

   assign dlyce = dlyce_int;
   assign dlyinc = dlyinc_int;

   // Asserted when per bit calibration complete
   assign chan_done = done_int;

   // Asserted when controller is issuing a dummy read
   always @(posedge clk)
     if (reset_r1)
       calib_start <= 1'b0;
     else
       calib_start <= ctrl_dummyread_start;

   //*******************************************************************
   // Per Bit calibration: DQ-FPGA Clock
   // Definitions:
   //  edge: detected when varying IDELAY, and current capture data != prev
   //    capture data
   // Algorithm Description:
   //  1. Starts at IDELAY tap 0 for each bit
   //  2. Increment DQ IDELAY until we find an edge.
   //  3. Once it finds an edge, decide whether its more accurate to
   //     increment or decrement by min(32, T/4).
   //  4. If no edge is found by tap 63, decrement to tap MAX_TAP_COUNT.
   //  5. Repeat for each DQ in current DQS set.
   //*******************************************************************

   // current state logic
   // synthesis attribute max_fanout of current_state is 5
   always @ (posedge clk)
     // If calibration finished, then halt state machine
     if (reset_r1 || !ctrl_dummyread_start)
       current_state <= IDLE;
     else
       current_state <= next_state;

   //*******************************************************************
   // signal to tell calibration state machines to wait and give IDELAY time to
   // settle after it's value is changed (both time for IDELAY chain to settle,
   // and for settled output to propagate through IDDR). For general use: use
   // for any calibration state machines that modify any IDELAY.
   // Should give at least enough time for IDELAY output to settle for new data
   // to propagate through IDDR.
   // For now, give very "generous" delay - doesn't really matter since only
   // needed during calibration
   //*******************************************************************

   assign idel_set_wait = (idel_set_cnt != IDEL_SET_VAL);

   always @(posedge clk)
     if (reset_r1)
       idel_set_cnt <= 3'b000;
     else if (dlyce_int)
       idel_set_cnt <= 3'b000;
     else if (idel_set_cnt != IDEL_SET_VAL)
       idel_set_cnt <= idel_set_cnt + 1;

   // Everytime the IDELAY is incremented when searching for edge of
   // data valid window, wait for some time for IDELAY output to settle
   // (IDELAY output can glitch), then sample the output. Then:
   //   1. Compare current value of DQ to PREV_DQ, if they are different
   //      then an edge has been found
   //   2. Set PREV_DQ = current value of DQ
   always @(posedge clk)
     // When first calibrating each individual bit, store the initial value
     // of data as PREV_DQ (i.e. initialize PREV_DQ - since it's possible to
     // find an edge immediately after the first incrementation of IDELAY)
     // NOTE: Make sure that during state BIT_CALIBRATION, that DQ_DATA
     //  reflects the current DQ being calibrated (i.e. does not reflect the
     //  previous DQ bit)
     if (current_state == BIT_CALIBRATION) begin
       prev_dq <= dq_data;
       cal_detect_edge <= 1'b0;
     end else if (!idel_set_wait && (current_state == IDEL_WAIT)) begin
       // Only update PREV_DQ once each time after IDELAY inc'ed - update
       // as we're done waiting for IDELAY to settle
       prev_dq         <= dq_data;
       cal_detect_edge <= (dq_data != prev_dq);
     end

   //*****************************************************************
   // keep track of edge tap counts found, and whether we've
   // incremented to the maximum number of taps allowed
   // curr_tap_cnt is reset for each bit
   //*****************************************************************

   always @(posedge clk)
      if(reset_r1 || tap_count_rst)
        curr_tap_cnt[5:0] <= 6'd0;
      else if((dlyce_int == 1'b1) && (dlyinc_int == 1'b1))
        curr_tap_cnt[5:0] <= curr_tap_cnt + 1;

   //*******************************************************************
   // Keeps track of tap counts to increment or decrement
   // by min(32, T/4) once it finds an edge.
   //*******************************************************************

   always @ (posedge clk)
     if (reset_r1 || tap_count_rst)
       dec_tap_count <= MAX_TAP_COUNT;
     else if ((dlyce_int == 1'b1) && (dlyinc_int == 1'b0))
       dec_tap_count <= dec_tap_count - 1;

   always @(posedge clk)
      if(reset_r1 || tap_count_rst)
        inc_tap_count[5:0] <= MAX_TAP_COUNT;
      else if((dlyce_int == 1'b1) && (dlyinc_int == 1'b1))
        inc_tap_count[5:0] <= inc_tap_count - 1;

   // Flag to decide whether its more accurate
   // to increment or decrement by min(32, T/4) after finding an edge.
   always @( posedge clk )
     if ( reset_r1 )
       tap_count_flag <= 1'b0;
     else if ( curr_tap_cnt > MAX_TAP_COUNT )
       tap_count_flag <= 1'b1;
     else
       tap_count_flag <= 1'b0;

   // Flag asserted, if edge not found and tap count reached maximum value
   always @( posedge clk )
     if ( reset_r1 )
       tap_max_count_flag <= 1'b0;
     else if ( curr_tap_cnt == 63 )
       tap_max_count_flag <= 1'b1;
     else
       tap_max_count_flag <= 1'b0;

   //*******************************************************************
   // Flags for taps to increment or decrement.
   // Flags for counters deassertion.
   //*******************************************************************

   always @ *  begin
      // default values, all these flags gets pulsed in different states
      dlyce_int = 1'b0;
      dlyinc_int = 1'b0;
      done_int = 1'b0;
      tap_count_rst = 1'b0;

      case (current_state)

        BIT_CALIBRATION: begin
           // Reset all tap counters before per bit calibration of each bit
           tap_count_rst = 1'b1;
        end

        INC: begin
           // Increment taps by one tap
           dlyce_int  = 1'b1;
           dlyinc_int = 1'b1;
        end

        EDGE_WAIT: begin
          // Reset all tap counters before per bit calibration of each bit
           tap_count_rst = 1'b1;
        end

        DEC: begin
           // Decrement taps by one tap
           dlyce_int  = 1'b1;
           dlyinc_int = 1'b0;
        end

        INC_TAPS: begin
           // Increment taps by one tap
           dlyce_int = 1'b1;
           dlyinc_int = 1'b1;
        end

        DONE: begin
          // Per bit calibration completed.
          done_int = 1'b1;
        end

      endcase
   end

   //*******************************************************************
   // Next State Logic
   //*******************************************************************

   // synthesis attribute max_fanout of next_state is 5
   always @ *
     case (current_state) // synthesis full_case parallel_case

       // Start per bit calibration after controller issues dummy read
       IDLE: begin
         if (calib_start)
           next_state = BIT_CALIBRATION;
         else
           next_state = IDLE;
       end

       // starts per bit calibration for each bit
       BIT_CALIBRATION: begin
         next_state = INC;
       end

       // increment by one tap value
       INC: begin
         next_state = IDEL_WAIT;
       end

       IDEL_WAIT: begin
         if (!idel_set_wait)
           // wait few clock cycles for IDELAY output to settle and
           // IDDR pipe to clear
           next_state = EDGE;
         else
           next_state = IDEL_WAIT;
       end

       EDGE: begin
         if (cal_detect_edge)
           // if edge found, increment or decrement by MAX_TAP_COUNT
           next_state = EDGE_WAIT;
         else if (tap_max_count_flag)
           // if edge not found, decrement by MAX_TAP_COUNT taps
           next_state = DEC;
         else
           next_state = INC;
       end

       EDGE_WAIT: begin
         if (tap_count_flag)
           // if edge found and taps incremented (curr_tap_cnt) to find
           // an edge are more than MAX_TAP_COUNT, decrement by MAX_TAP_COUNT.
           next_state = DEC;
         else
           // if edge found and taps incremented (curr_tap_cnt) to find
           // an edge are less than MAX_TAP_COUNT, increment by MAX_TAP_COUNT.
           next_state = INC_TAPS;
       end

       // Decrement by MAX_TAP_COUNT i.e., T/4 or 32
       DEC: begin
         if (dec_tap_count == 1)
           next_state = DONE;
         else
           next_state = DEC;
       end

       // Increment by MAX_TAP_COUNT i.e., T/4 or 32
       INC_TAPS: begin
         if (inc_tap_count == 1)
           next_state = DONE;
         else
           next_state = INC_TAPS;
       end

       // per bit calibration completed for one bit and continue for other bits
       DONE: begin
         next_state = PIPE_WAIT;
       end

       // wait extra clock cycle to allow MUX selector for which bit to
       // calibrate to take effect. Not needed in current design because all
       // MUX logic is combination, but include just in case later need to
       // add register stage for MUX logic for timing purposes
       PIPE_WAIT: begin
         next_state = BIT_CALIBRATION;
       end

     endcase

endmodule
