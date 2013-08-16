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

module v4_phy_pattern_compare8 #
  (
   parameter DEBUG_EN       = 0
   )
  (
   input       clk,
   input       rst,
   input       ctrl_rden,
   input       calib_done,
   input [7:0] rd_data_rise,
   input [7:0] rd_data_fall,
   input [7:0] per_bit_skew,      // indicates possible capture skew over DQ's
   output      comp_done,
   output      comp_error,        // asserted if unable to find correct pattern
   output reg  first_rising,
   output reg  rd_en_rise,
   output reg  rd_en_fall,
   output reg  cal_first_loop,
   output reg [7:0] delay_enable, // control delay/swap MUX for each DQ
   input  [4:0] dbg_calib_rden_dly_value,
   input        dbg_calib_rden_dly_en,
   output [4:0] dbg_calib_rden_dly,
   input  [7:0] dbg_calib_dq_in_byte_align_value,
   input        dbg_calib_dq_in_byte_align_en,
   input        dbg_calib_rd_data_sel_value,
   input        dbg_calib_rd_data_sel_en
   );

  localparam   CAL_IDLE             = 3'b000;
  localparam   CAL_CHECK_DATA       = 3'b001;
  localparam   CAL_INV_DELAY_ENABLE = 3'b010;
  localparam   CAL_DONE             = 3'b011;
  localparam   CAL_ERROR            = 3'b100;

  reg          cal_first_loop_i;
  reg [2:0]    cal_next_state;
  reg [2:0]    cal_state;
  reg [3:0]    clk_count;
  reg          cntrl_rden_r;
  reg          comp_done_r;
  reg          comp_error_r;
  wire         data_match_first_clk_fall;
  wire         data_match_first_clk_rise;
  reg          found_first_clk_rise;
  reg          found_first_clk_rise_r;
  reg          lock_first_rising;
  reg [7:0]    rd_data_fall_r;
  reg [7:0]    rd_data_fall_r2;
  reg [7:0]    rd_data_rise_r;
  reg [7:0]    rd_data_rise_r2;
  reg [7:0]    rd_data_rise_r3;
  reg          rd_en_out;
  reg          rd_en_out_r;
  reg          rd_en_r1 /* synthesis syn_preserve=1 */;
  reg          rd_en_r2;
  reg          rd_en_r3;
  reg          rd_en_r4;
  reg          rd_en_r5;
  reg          rd_en_r6;
  reg          rd_en_r7;
  reg          rd_en_r8;
  reg          rd_en_r9;
  reg          rd_en_r10;
  reg          rd_en_r11;
  reg          rst_r1 /* synthesis syn_preserve=1 */;

  //*******************************************************************

  assign comp_done  = comp_done_r;
  assign comp_error = comp_error_r;

  // synthesis attribute equivalent_register_removal of rst_r1 is "no";
  always @( posedge clk )
    rst_r1 <= rst;

  // synthesis attribute equivalent_register_removal of rd_en_r1 is "no";
  always @ (posedge clk) begin
    if (rst_r1) begin
      rd_en_r1 <= 1'b0;
      rd_en_r2 <= 1'b0;
      rd_en_r3 <= 1'b0;
      rd_en_r4 <= 1'b0;
      rd_en_r5 <= 1'b0;
      rd_en_r6 <= 1'b0;
      rd_en_r7 <= 1'b0;
      rd_en_r8 <= 1'b0;
      rd_en_r9 <= 1'b0;
      rd_en_r10 <= 1'b0;
      rd_en_r11 <= 1'b0;
    end else begin
      rd_en_r1 <= ctrl_rden;
      rd_en_r2 <= rd_en_r1;
      rd_en_r3 <= rd_en_r2;
      rd_en_r4 <= rd_en_r3;
      rd_en_r5 <= rd_en_r4;
      rd_en_r6 <= rd_en_r5;
      rd_en_r7 <= rd_en_r6;
      rd_en_r8 <= rd_en_r7;
      rd_en_r9 <= rd_en_r8;
      rd_en_r10 <= rd_en_r9;
      rd_en_r11 <= rd_en_r10;
    end
  end

  //*******************************************************************
  // Indicates when received data is equal to the expected data pattern
  // There are two possible scenarios: (1) rise and fall data are arrive
  // at the same clock cycle (FIRST_RISING = 0), (2) rise and fall data
  // arrive "staggered" w/r to each other (FIRST_RISING = 1). Which
  // sequence occurs depends on the results of the per-bit calibration
  // (and whether first data from memory is captured using rising or
  // falling edge data). Expected data pattern = [rise/fall] = 0110 for
  // even bits, and 1001 for odd bits = "A55A"
  // For FIRST_CLK_RISE = 0 (non-staggered case):
  //   - IDDR.Q1 = fall data, IDDR.Q2 = rise data, and rise and fall
  //     read data FIFO enables are asserted at same time
  // For FIRST_CLK_FALL = 1 (staggered case):
  //   - IDDR.Q1 = rise data, IDDR.Q2 = fall data, and rise and fall
  //     read data FIFO enables must be offset by 1 clk (rise enable
  //     leads fall enable)
  //*******************************************************************

  always @(posedge clk) begin
    rd_data_rise_r  <= rd_data_rise;
    rd_data_fall_r  <= rd_data_fall;
    rd_data_rise_r2 <= rd_data_rise_r;
    rd_data_fall_r2 <= rd_data_fall_r;
    rd_data_rise_r3 <= rd_data_rise_r2;
  end

  assign data_match_first_clk_fall
    = (rd_data_fall_r2 == 8'hAA) &&
      (rd_data_rise_r2 == 8'h55) &&
      (rd_data_fall_r  == 8'h55) &&
      (rd_data_rise_r  == 8'hAA);

  assign data_match_first_clk_rise
    = (rd_data_rise_r3 == 8'hAA) &&
      (rd_data_fall_r2 == 8'h55) &&
      (rd_data_rise_r2 == 8'h55) &&
      (rd_data_fall_r  == 8'hAA);

  //*******************************************************************
  // State machine to determine:
  //  1. What round trip delay is for read data (i.e. from when
  //     CTRL_RDEN is asserted until when synchronized data is
  //     available at input to read data FIFO
  //  2. Whether data is arriving staggered or simulataneous (depends
  //     on whether first data from memory is latched in on rising or
  //     falling edge
  //  3. Whether there is bit-alignment from the per-bit calibration
  //     step - i.e. whether the same FPGA clock edge is being used to
  //     clock in bits from two different bit times on different DQ's
  //     in this DQS group
  //*******************************************************************

  always @(posedge clk) begin
    if (rst_r1)
      cal_state <= CAL_IDLE;
    else
      cal_state <= cal_next_state;
  end

  always @(*) begin
    // default values, this value only gets pulsed when we find a
    // FIRST_RISING data pattern
    found_first_clk_rise  = 1'b0;
    cal_next_state = cal_state;
    case (cal_state)  // synthesis full_case parallel_case
      CAL_IDLE:
        // Don't start pattern calibration until controller issues read
        if (cntrl_rden_r)
          cal_next_state = CAL_CHECK_DATA;

      CAL_CHECK_DATA:
        // Stay in this state until we've waited maximum number of clock
        // cycles for a valid pattern to appear on the bus
        if (clk_count == 4'b1111) begin
          if (cal_first_loop_i)
            cal_next_state = CAL_INV_DELAY_ENABLE;
          else
            // Otherwise, we haven't found the right pattern
            cal_next_state = CAL_ERROR;
        end else begin
          if (data_match_first_clk_rise || data_match_first_clk_fall) begin
            cal_next_state = CAL_DONE;
            // Indicate to logic which data pattern was found
            found_first_clk_rise = data_match_first_clk_rise;
          end
        end

      // Inverting the control pattern for the delay/swap circuit for the
      // DQ's in this DQS group - we would have to do this if we got the
      // directionality incorrect on the first go-around. Note that we have
      // to wait several clock cycles to: (1) reflect new CLK_COUNT value,
      // (2) allow rd_data_rise/fall pipe chain to clear
      CAL_INV_DELAY_ENABLE:
        cal_next_state = CAL_IDLE;

      // Found a first rising or first falling pattern. We're done here.
      CAL_DONE:
        cal_next_state = CAL_DONE;

      // Error - we incremented CLK_COUNT to the highest possible value
      // and still didn't find a valid pattern - could be an issue with
      // per-bit calibration, or a board-level (e.g. stuck at bit) issue
      CAL_ERROR:
        cal_next_state = CAL_ERROR;

    endcase
  end

  //*******************************************************************

  // Asserted when controller is issuing a read
  always @(posedge clk) begin
    if (rst_r1)
      cntrl_rden_r <= 1'b0;
    else
      cntrl_rden_r <= ctrl_rden;
  end

  // Asserted when pattern calibration complete
  always @(posedge clk) begin
    if (rst_r1)
      comp_done_r <= 1'b0;
    else
      comp_done_r <= (cal_state == CAL_DONE);
  end

  // Asserted when pattern calibration hangs due to error
  always @(posedge clk) begin
    if (rst_r1)
      comp_error_r <= 1'b0;
    else
      comp_error_r <= (cal_state == CAL_ERROR);
  end

  always @(posedge clk)
    found_first_clk_rise_r <= found_first_clk_rise;

  generate 
    if (DEBUG_EN) begin : gen_dbg_fr
      always @(posedge clk)
	if (rst_r1) begin
	  first_rising     <= 1'b0;
	  lock_first_rising <= 1'b0;
	end else if (cal_state == CAL_DONE) begin
	  // If we enter CAL_DONE and found_first_clk_rise_r is pulsed (meaning
	  // we found a FIRST_RISING=1 pattern), then set FIRST_RISING=0
	  // This will be used statically to control MUXes to determine which
	  // output (Q1 or Q2) of the IDDR is "rising" and which is "falling"
	  // data
	  // NOTE: Once first rising is set, it stays set
	  // NOTE: FIRST_RISING as it is used in the rest of the design does not
	  // mean the same thing as FOUND_FIRST_CLK_RISE in this design!! It
	  // is actually named for something else (=1 means rising data forms
	  // the LSB of the full data word). Hence the inversion here.
	  if (dbg_calib_rd_data_sel_en)
	    first_rising <= dbg_calib_rd_data_sel_value;
	  else if (!lock_first_rising) begin
            lock_first_rising <= 1'b1;
            first_rising <= ~found_first_clk_rise_r;
	  end
	end
    end else begin : gen_nodbg_fr
      always @(posedge clk)
	if (rst_r1) begin
	  first_rising     <= 1'b0;
	  lock_first_rising <= 1'b0;
	end else if (cal_state == CAL_DONE) begin
	  // If we enter CAL_DONE and found_first_clk_rise_r is pulsed (meaning
	  // we found a FIRST_RISING=1 pattern), then set FIRST_RISING=0
	  // This will be used statically to control MUXes to determine which
	  // output (Q1 or Q2) of the IDDR is "rising" and which is "falling"
	  // data
	  // NOTE: Once first rising is set, it stays set
	  // NOTE: FIRST_RISING as it is used in the rest of the design does not
	  // mean the same thing as FOUND_FIRST_CLK_RISE in this design!! It
	  // is actually named for something else (=1 means rising data forms
	  // the LSB of the full data word). Hence the inversion here.
	  if (!lock_first_rising) begin
            lock_first_rising <= 1'b1;
            first_rising <= ~found_first_clk_rise_r;
	  end
	end
    end
  endgenerate

  //*******************************************************************

  // Count # of clock cycles from when read is issued, until when
  // correct data is detected
  assign dbg_calib_rden_dly = clk_count;
  generate
    if (DEBUG_EN) begin : gen_dbg
      always @(posedge clk)
	if (cal_state == CAL_IDLE)
	  clk_count <= 4'b0000;
	else if (cal_state == CAL_CHECK_DATA)
	  clk_count <= clk_count + 1;
	else if (dbg_calib_rden_dly_en)
	  clk_count <= dbg_calib_rden_dly_value;
    end else begin : gen_nodbg
      always @(posedge clk)
	if (cal_state == CAL_IDLE)
	  clk_count <= 4'b0000;
	else if (cal_state == CAL_CHECK_DATA)
	  clk_count <= clk_count + 1;
    end
  endgenerate

  // NOTE: Probably don't need all these cases! Need to check on this!
  always @(posedge clk) begin
    if (rst_r1)
      rd_en_out <= 1'b0;
    else begin
      case (clk_count) // synthesis full_case parallel_case
        4'b0101  : rd_en_out <= rd_en_r1;
        4'b0110  : rd_en_out <= rd_en_r2;
        4'b0111  : rd_en_out <= rd_en_r3;
        4'b1000  : rd_en_out <= rd_en_r4;
        4'b1001  : rd_en_out <= rd_en_r5;
        4'b1010  : rd_en_out <= rd_en_r6;
        4'b1011  : rd_en_out <= rd_en_r7;
        4'b1100  : rd_en_out <= rd_en_r8;
        4'b1101  : rd_en_out <= rd_en_r9;
        4'b1110  : rd_en_out <= rd_en_r10;
        4'b1111  : rd_en_out <= rd_en_r11;
	default  : rd_en_out <= rd_en_r1;
      endcase
    end
  end

  always @(posedge clk)
    if (rst_r1)
      rd_en_out_r <= 1'b0;
    else
      rd_en_out_r <= rd_en_out;

  // Generate read enables for Rising and Falling read data FIFOs
  // The timing of these will be dependent on whether a first rising or
  // first falling pattern was detected.
  always @(posedge clk)
    if (rst_r1) begin
      rd_en_rise <= 1'b0;
      rd_en_fall <= 1'b0;
    end else begin
      if (!calib_done) begin
        rd_en_rise <= 1'b0;
        rd_en_fall <= 1'b0;
      end else if (!first_rising) begin
        rd_en_rise <= rd_en_out;
        rd_en_fall <= rd_en_out_r;
      end else begin
        rd_en_rise <= rd_en_out_r;
        rd_en_fall <= rd_en_out_r;
      end
    end

  //*******************************************************************

  generate 
    if (DEBUG_EN) begin : gen_dbg_align
      reg dbg_ovr;
      always @(posedge clk)
	if (rst_r1)
	  dbg_ovr <= 1'b0;
	else if (dbg_calib_dq_in_byte_align_en)
	  dbg_ovr <= 1'b1;

      // MUX control for delay/swap circuit for each DQ (used to compensate
      // for possible bit-misalignment from per-bit calibration)
      always @(posedge clk)
	if (rst_r1)
	  delay_enable <= 8'b00000000;
	else if (dbg_calib_dq_in_byte_align_en)
	  delay_enable <= dbg_calib_dq_in_byte_align_value;
	else if (dbg_ovr==1'b0)
	  if (cal_first_loop_i)
            // Special case if per_bit_skew = 0xFF. Set delay_enable = 0x00
            // to bypass the delay/swap circuit (we should be able to find
            // a match with either delay_enable = 0xFF or 0x00, but finding
            // a match w/ = 0x00 saves one cycle of latency)
            if (&per_bit_skew)
              delay_enable <= 8'b00000000;
            else
              delay_enable <= per_bit_skew;
	  else
            delay_enable <= ~per_bit_skew;
    end else begin : gen_nodbg_align
      // MUX control for delay/swap circuit for each DQ (used to compensate
      // for possible bit-misalignment from per-bit calibration)
      always @(posedge clk)
	if (rst_r1)
	  delay_enable <= 8'b00000000;
        else 
	  if (cal_first_loop_i)
            // Special case if per_bit_skew = 0xFF. Set delay_enable = 0x00
            // to bypass the delay/swap circuit (we should be able to find
            // a match with either delay_enable = 0xFF or 0x00, but finding
            // a match w/ = 0x00 saves one cycle of latency)
            if (&per_bit_skew)
              delay_enable <= 8'b00000000;
            else
              delay_enable <= per_bit_skew;
	  else
            delay_enable <= ~per_bit_skew;
    end
  endgenerate

  // Keep track of which iteration of calibration loop we're in
  always @(posedge clk)
    if (rst_r1)
      cal_first_loop_i <= 1'b1;
    else if (cal_state == CAL_INV_DELAY_ENABLE)
      cal_first_loop_i <= 1'b0;
  always @(posedge clk)
    cal_first_loop <= cal_first_loop_i;



endmodule
