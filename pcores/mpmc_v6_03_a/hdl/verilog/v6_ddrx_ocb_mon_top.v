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
//  /   /         Filename: v6_ddrx_ocb_mon_top.v
// \   \  /  \    Date Created: Aug 03 2009
//  \___\/\___\
//
//Device: Virtex-6
//Design Name: DDR3 SDRAM
//Purpose:
//  Top-level for OCB Monitor logic
//Reference:
//Revision History:
//*****************************************************************************

/******************************************************************************
******************************************************************************/

`timescale 1ps/1ps


module v6_ddrx_ocb_mon_top #
  (
   parameter TCQ = 100,
   parameter MMCM_ADV_PS_WA = "OFF", // MMCM_ADV Phase Shift Work Around ("ON" or "OFF"),
   parameter DRAM_TYPE        = "DDR3", // Memory I/F type: "DDR3", "DDR2"   
   parameter CLKPERF_DLY_USED = "OFF",  // Workaround for write path
   parameter SIM_CAL_OPTION = "NONE"  // "NONE",
                                      // "FAST_CAL",
                                      // "SKIP_CAL" (same as "NONE")
   )
  (
   // Debug
   input          dbg_ocb_mon_off,
   output         dbg_ocb_mon_clk,
   output [255:0] dbg_ocb_mon,

   output         ocb_mon_PSEN,       // to MCMM_ADV
   output         ocb_mon_PSINCDEC,   // to MCMM_ADV
   output         ocb_mon_calib_done, // to calib control (level)
   input          ocb_mon_PSDONE,     // from MCMM_ADV
   input          ocb_mon_go,         // start the OCB monitor state machine
   input          clk_mem,
   input          clk,
   input          clk_wr,
   input          rst
   );

  // Set DDR3_DATA to 1 only when CLKPERFDELAYED path of all OSERDESE1
  // blocks in design are being used - basically this value must match
  // the values of all other OSERDESE1 blocks in interface. 
  localparam OCB_DDR3_DATA 
             = ((DRAM_TYPE == "DDR3") && 
                (CLKPERF_DLY_USED == "ON")) ? 1 : 0;
  
  reg ocb_extend; // combinatorial

  wire    clk_wr_n;
  wire    clk_mem_n;
  `ifdef TEST_BLH_OSERDESE1
  wire    clk_n;
  `endif

  wire   ocb_mon_go_1;
  wire   ocb_mon_calib_done_1;

  assign ocb_mon_go_1       = ocb_mon_go & ~dbg_ocb_mon_off;
  assign ocb_mon_calib_done = ocb_mon_calib_done_1 | dbg_ocb_mon_off;

  //***************************************************************************
  // Debug
  //***************************************************************************

  // Temporary debug assignments - remove for release code
  assign dbg_ocb_mon_clk = clk;

  assign clk_wr_n  = ~clk_wr;
  assign clk_mem_n = ~clk_mem;

`ifdef TEST_BLH_OSERDESE1
  assign clk_n = ~clk;
`endif

  v6_ddrx_ocb_mon #
    (
     .TCQ(TCQ),
     .MMCM_ADV_PS_WA(MMCM_ADV_PS_WA),
     .SIM_CAL_OPTION(SIM_CAL_OPTION)
     )
    u_phy_ocb_mon
      (
       .dbg_ocb_mon(dbg_ocb_mon),
       .ocb_mon_PSEN(ocb_mon_PSEN),               // to MCMM_ADV
       .ocb_mon_PSINCDEC(ocb_mon_PSINCDEC),       // to MCMM_ADV
       .ocb_mon_calib_done(ocb_mon_calib_done_1),
       .ocb_wc(ocb_wc),                           // to OSERDESE1
       .ocb_extend(ocb_extend),                   // from OSERDESE1
       .ocb_mon_PSDONE(ocb_mon_PSDONE),           // from MCMM_ADV
       .ocb_mon_go(ocb_mon_go_1),                 // start the OCB monitor
                                                  // state machine
       .clk(clk),
       .rst(rst)
       );

`ifdef TEST_BLH_OSERDESE1
  B_OSERDESE1_TEST #
`else
        OSERDESE1 #
`endif
    (
     .DATA_RATE_OQ   ("DDR"),         // parameter
     .DATA_RATE_TQ   ("DDR"),         // parameter
     .DATA_WIDTH     (4),             // parameter integer
     // MIG 3.3: Modified - set to 0 to match setting for all other
     //  OSERDESE1 blocks in design
//     .DDR3_DATA      (1),             // parameter integer
     .DDR3_DATA      (OCB_DDR3_DATA), // parameter integer
     .INIT_OQ        (1'b0),          // parameter
     .INIT_TQ        (1'b0),          // parameter
     .INTERFACE_TYPE ("MEMORY_DDR3"), // parameter
     .ODELAY_USED    (0),             // parameter integer
     .SERDES_MODE    ("MASTER"),      // parameter
     .SRVAL_OQ       (1'b0),          // parameter
     .SRVAL_TQ       (1'b0),          // parameter
     .TRISTATE_WIDTH (4)              // parameter integer
     )
    u_oserdes_ocb_mon
      (
       .OCBEXTEND    (ocbextend_raw),
       .OFB          (),
       .OQ           (),
       .SHIFTOUT1    (),
       .SHIFTOUT2    (),
       .TQ           (),
       .CLK          (clk_mem),
       .CLKDIV       (clk),
`ifdef TEST_BLH_OSERDESE1
       .CLKDIVB      (clk_n),
`endif
       .CLKPERF      (clk_wr_n),
       .CLKPERFDELAY (),
       .D1           (1'b1),
       .D2           (1'b1),
       .D3           (1'b0),
       .D4           (1'b0),
       .D5           (1'b0),
       .D6           (1'b0),
       .OCE          (1'b1),
       .ODV          (1'b0),
       .SHIFTIN1     (),
       .SHIFTIN2     (),
`ifdef TEST_BLH_OSERDESE1
       .SR           (rst),
`else
       .RST          (rst),
`endif
       .T1           (1'b0),
       .T2           (1'b0),
       .T3           (1'b0),
       .T4           (1'b0),
       .TFB          (),
       .TCE          (1'b1),
       .WC           (ocb_wc)
       );

`ifdef TEST_BLH_OSERDESE1
  always @(ocbextend_raw)
    // removes 15 ps unknowns when BLH is selected
    if (ocbextend_raw !== 1'bx) ocb_extend <= ocbextend_raw;
`else
  always @(ocbextend_raw) ocb_extend = ocbextend_raw;
`endif

endmodule
