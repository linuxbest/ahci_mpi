//*****************************************************************************
// (c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: %version
//  \   \         Application: MIG
//  /   /         Filename: v6_ddrx_ocb_mon.v
// \   \  /  \    Date Created: Aug 03 2009
//  \___\/\___\
//
//Device: Virtex-6
//Design Name: DDR3 SDRAM
//Purpose:
//   OCB Monitor logic for monitoring and controlling phase between BUFG
//   and performance path clocks going to OSERDES blocks
//Reference:
//Revision History:
//  1.1 Initial check-in                                          - JL 11/12/08
//*****************************************************************************

/******************************************************************************
******************************************************************************/

`timescale 1ps/1ps

module v6_ddrx_ocb_mon #
(
   parameter TCQ            = 100,   // clk->out delay (sim only)
   parameter MMCM_ADV_PS_WA = "OFF", // MMCM_ADV Phase Shift Work Around ("ON" or "OFF")
   parameter SIM_CAL_OPTION = "NONE" // "NONE", "FAST_CAL", "SKIP_CAL" (same as "NONE")
)
(
  output [255:0] dbg_ocb_mon,        // debug signals
  output reg     ocb_mon_PSEN,       // to MCMM_ADV
  output         ocb_mon_PSINCDEC,   // to MCMM_ADV
  output         ocb_mon_calib_done, // ocb clock calibration done
  output reg     ocb_wc,             // to OSERDESE1

  input          ocb_extend,         // from OSERDESE1
  input          ocb_mon_PSDONE,     // from MCMM_ADV
  input          ocb_mon_go,         // start the OCB monitor state machine
  input          clk,                // clkmem/2
  input          rst
);

  //***************************************************************************
  // Local parameters (other than state assignments)
  //***************************************************************************

  // merge two SIM_CAL_OPTION values into new localparam
  localparam FAST_SIM  = ((SIM_CAL_OPTION == "FAST_CAL") | (SIM_CAL_OPTION == "FAST_WIN_DETECT")) ? "YES" : "NO";

  // width of high counter (11 for synthesis, less for simulation)
  localparam hc_width  = (FAST_SIM == "YES") ? 3 : 11;

  // width of calibration done counter (6 for synthesis, less for simulation)
  localparam cdc_width = (FAST_SIM == "YES") ? 3 : 6;

  localparam c_width   = 4; // width of clk cycle counter

  //***************************************************************************
  // Internal signals
  //***************************************************************************

  reg                 reset;           // rst is synchronized to clk
  reg [2:0]           ocb_state_r;
  reg [2:0]           ocb_next_state;
  reg [hc_width-1:0]  high;            // high counter
  reg [hc_width:0]    samples;         // sample counter
  reg [c_width-1:0]   cycles;          // cycle counter (to wait after wc is pulsed)
  wire                samples_done = samples[hc_width];
  wire                cycles_done  = cycles[c_width-1];
  wire                inc_cntrs;
  wire                clr_high;
  wire                high_ce;
  wire                clr_samples;
  wire                samples_ce;
  wire                clr_cycles;
  wire                cycles_ce;
  wire                update_phase;
  reg [cdc_width-1:0] calib_done_cntr;
  wire                calib_done_cntr_inc;
  wire                calib_done_cntr_ce;
  wire                high_gt_low;

  // These 4 signals needed for Phase Shift Control workarounds only
  reg                 wait_psdone_ff;
  wire                ocb_mon_go_1;
  wire                en_count;
  reg                 cntr_msb;

  //***************************************************************************
  // Debug
  //***************************************************************************

  // Temporary debug assignments - remove for release code
  assign dbg_ocb_mon[0]     = ocb_mon_PSEN;
  assign dbg_ocb_mon[1]     = ocb_mon_PSINCDEC;
  assign dbg_ocb_mon[2]     = ocb_mon_calib_done;
  assign dbg_ocb_mon[3]     = ocb_wc;
  assign dbg_ocb_mon[4]     = ocb_extend;
  assign dbg_ocb_mon[5]     = ocb_mon_PSDONE;
  assign dbg_ocb_mon[6]     = ocb_mon_go;
  assign dbg_ocb_mon[7]     = samples_done;
  assign dbg_ocb_mon[8]     = cycles_done;
  assign dbg_ocb_mon[9]     = inc_cntrs;
  assign dbg_ocb_mon[10]    = clr_high;
  assign dbg_ocb_mon[11]    = high_ce;
  assign dbg_ocb_mon[12]    = clr_samples;
  assign dbg_ocb_mon[13]    = samples_ce;
  assign dbg_ocb_mon[14]    = clr_cycles;
  assign dbg_ocb_mon[15]    = cycles_ce;
  assign dbg_ocb_mon[16]    = update_phase;
  assign dbg_ocb_mon[17]    = calib_done_cntr_inc;
  assign dbg_ocb_mon[18]    = calib_done_cntr_ce;
  assign dbg_ocb_mon[19]    = high_gt_low;
  assign dbg_ocb_mon[29:20] = 'b0;                                    // spare scalor bits
  assign dbg_ocb_mon[33:30] = {1'b0, ocb_state_r};                    // 1 spare bit
  assign dbg_ocb_mon[37:34] = {1'b0, ocb_next_state};                 // 1 spare bit
  assign dbg_ocb_mon[53:38] = {{16-hc_width{1'b0}}, high};            // 16 bits max
  assign dbg_ocb_mon[69:54] = {{15-hc_width{1'b0}}, samples};         // 16 bits max
  assign dbg_ocb_mon[77:70] = {{8-c_width{1'b0}}, cycles};            //  8 bits max
  assign dbg_ocb_mon[85:78] = {{8-cdc_width{1'b0}}, calib_done_cntr}; //  8 bits max

  //***************************************************************************
  // MMCM phase shift interface
  //***************************************************************************

  // V6 Engineering Samples (ES) chips require the following Phase Shift Control
  // workarounds:

  // 1. Must wait for PSDONE to pulse active after the trailing edge of RST before
  //    using the PS interface.
  // 2. Must double pulse PSEN, with one inactive period between pulses.
  // 3. Must maintain PSINCDEC from the PSEN though PSDONE (this is already done,
  //    so no change to the design).

  generate
    if (MMCM_ADV_PS_WA == "ON") begin: gen_ps_wa
//      always @(posedge clk or posedge reset)
//      if(reset)                wait_psdone_ff <= #TCQ 1'b0;
//      else if (ocb_mon_PSDONE) wait_psdone_ff <= #TCQ 1'b1;
      // MODIFIED, 030309, RICHC
      // Appears that PSDONE is driven when RESET is still high -
      // perhaps we're still waiting for the second MMCM to lock?
      always @(posedge clk)
        wait_psdone_ff <= #TCQ 1'b1;

      assign ocb_mon_go_1 = ocb_mon_go & wait_psdone_ff;

      assign en_count = update_phase | cntr_msb | ocb_mon_PSEN;

      always @(posedge clk)
      begin
        if (reset)
        begin
          cntr_msb     <= #TCQ 1'b0;
          ocb_mon_PSEN <= #TCQ 1'b0;
        end
        else
        begin
          if(en_count)
          begin
          cntr_msb     <= #TCQ (cntr_msb ^ ocb_mon_PSEN); // msb of 2-bit counter
          ocb_mon_PSEN <= #TCQ ~ocb_mon_PSEN;             // lsb of 2-bit counter
          end
        end
      end
    end
    else
    begin
      assign ocb_mon_go_1 = ocb_mon_go;

      always @(posedge clk)
        if (reset) ocb_mon_PSEN <= #TCQ 1'b0;
        else       ocb_mon_PSEN <= #TCQ update_phase;
    end
  endgenerate

  assign ocb_mon_PSINCDEC = ~high_gt_low;

  //***************************************************************************
  // reset synchronization
  //***************************************************************************

  always @(posedge clk or posedge rst)
    if (rst) reset <= #TCQ 1'b1;
    else     reset <= #TCQ 1'b0;

  //***************************************************************************
  // ocb state assignments
  //***************************************************************************

  localparam OCB_IDLE         = 3'h0;
  localparam OCB_OUTSIDE_LOOP = 3'h1;
  localparam OCB_INSIDE_LOOP  = 3'h2;
  localparam OCB_WAIT1        = 3'h3;
  localparam OCB_INSIDE_JMP   = 3'h4;
  localparam OCB_UPDATE       = 3'h5;
  localparam OCB_WAIT2        = 3'h6;

  //***************************************************************************
  // State register
  //***************************************************************************

  always @(posedge clk)
    if (reset) ocb_state_r <= #TCQ 'b0;
    else       ocb_state_r <= #TCQ ocb_next_state;

  //***************************************************************************
  // Next ocb state
  //***************************************************************************

  always @(ocb_state_r or ocb_mon_go_1 or cycles_done or samples_done or ocb_mon_PSDONE)
  begin
    ocb_next_state = OCB_IDLE; // default state is idle

    case (ocb_state_r)
      OCB_IDLE         : begin // (0) wait for ocb_mon_go
                           if(ocb_mon_go_1) ocb_next_state = OCB_OUTSIDE_LOOP;
                         end
      OCB_OUTSIDE_LOOP : begin // (1) clr samples counter, clr high counter
                           ocb_next_state = OCB_INSIDE_LOOP;
                         end
      OCB_INSIDE_LOOP  : begin // (2) pulse ocb_wc, clr cycles counter
                           ocb_next_state = OCB_WAIT1;
                         end
      OCB_WAIT1        : begin // (3) inc cycles counter
                           if(!cycles_done) ocb_next_state = OCB_WAIT1;
                           else             ocb_next_state = OCB_INSIDE_JMP;
                         end
      OCB_INSIDE_JMP   : begin // (4) inc samples counter, conditionally inc high
                           if(samples_done) ocb_next_state = OCB_UPDATE;
                           else             ocb_next_state = OCB_INSIDE_LOOP;
                         end
      OCB_UPDATE       : begin // (5) pulse ocb_mon_PSEN
                           ocb_next_state = OCB_WAIT2;
                         end
      OCB_WAIT2        : begin // (6) wait for PSDONE from MMCD_ADV
                           if(ocb_mon_PSDONE) ocb_next_state = OCB_OUTSIDE_LOOP;
                           else               ocb_next_state = OCB_WAIT2;
                         end
    endcase
  end

  //***************************************************************************
  // ocb state translations
  //***************************************************************************

  assign inc_cntrs    = (ocb_state_r == OCB_INSIDE_JMP) & ~samples_done;
  assign clr_high     = (ocb_state_r == OCB_OUTSIDE_LOOP);
  assign high_ce      = clr_high | inc_cntrs;
  assign clr_samples  = clr_high;
  assign samples_ce   = clr_samples  | inc_cntrs;
  assign clr_cycles   = (ocb_state_r == OCB_INSIDE_LOOP);
  assign cycles_ce    = clr_cycles   | (ocb_state_r == OCB_WAIT1);
  assign update_phase = (ocb_state_r == OCB_UPDATE);

  //***************************************************************************
  // ocb_mon_calib_done generator
  //***************************************************************************

  assign calib_done_cntr_inc = high_gt_low ^ calib_done_cntr[0];
  assign calib_done_cntr_ce  = update_phase & ~calib_done_cntr[cdc_width-1];

  always @(posedge clk)
    if (reset)                  calib_done_cntr <= #TCQ 'b0;
    else if(calib_done_cntr_ce) calib_done_cntr <= #TCQ calib_done_cntr + calib_done_cntr_inc;

  assign ocb_mon_calib_done = calib_done_cntr[cdc_width-1];

  //***************************************************************************
  // ocb_wc generator
  //***************************************************************************

  always @(posedge clk)
    if (reset) ocb_wc <= #TCQ 'b0;
    else       ocb_wc <= #TCQ (ocb_state_r == OCB_INSIDE_LOOP);

  //***************************************************************************
  // high counter
  //***************************************************************************

  wire [hc_width-1:0] high_d = {hc_width{~clr_high}} & (high + {{hc_width-1{1'b0}}, ocb_extend});

  always @(posedge clk)
    if (reset)       high <= #TCQ 'b0;
    else if(high_ce) high <= #TCQ high_d;

  //***************************************************************************
  // sample counter
  //***************************************************************************

   wire [hc_width:0] samples_d = clr_samples ? 'b1 : samples + 1; // samples cntr starts at 1

  always @(posedge clk)
    if (reset)          samples <= #TCQ 'b0;
    else if(samples_ce) samples <= #TCQ samples_d;

  //***************************************************************************
  // cycle counter
  //***************************************************************************

  wire [c_width-1:0] cycles_d = {c_width{~clr_cycles}} & (cycles + {{c_width-1{1'b0}}, 1'b1});

  always @(posedge clk)
    if (reset)         cycles <= #TCQ 'b0;
    else if(cycles_ce) cycles <= #TCQ cycles_d;

  //***************************************************************************
  // compare
  //***************************************************************************

  assign high_gt_low = high[hc_width-1];

endmodule
