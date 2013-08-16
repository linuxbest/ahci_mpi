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
//
// Description: 4-bit SRL FIFO.
//   
//--------------------------------------------------------------------------
//
// Structure:
//   mpmc_ctrl_path
//     ctrl_path
//     arbiter
//       arb_acknowledge
//       arb_bram_addr
//       arb_pattern_start
//         arb_req_pending_muxes
//         high_priority_select
//       arb_which_port
//         arb_req_pending_muxes
//         high_priority_select
//       arb_pattern_type
//         arb_pattern_type_muxes
//         arb_pattern_type_fifo
//         high_priority_select
//           mpmc_ctrl_path_fifo (currently used, better for output timing)
//           fifo_4 (not used, better for area)
//             fifo_32_rdcntr
//
//--------------------------------------------------------------------------
// History:
//
//--------------------------------------------------------------------------
`timescale 1ns/1ns

module fifo_4 (
  rst,   // Global Async Reset
  // Write Port Signals
  wclk,  // Write clock
  wdin,  // Write Data In
  push,   // Write Enable
  //push_early,
  // Read Port Signals
  rclk,  // Read clock
  rdout, // Read Data Out
  pop    // Read Enable
  );
   
// Port Declarations ************************************************

  input         rst;
  // Write Port Signals
  input         wclk;
  input  [3:0]  wdin;
  input         push;
  // Read Port Signals
  input         rclk;
  output [3:0]  rdout;
  input         pop;
   
// Signal Declarations ***********************************************
  wire   [3:0]  raddr;
  
  wire  [3:0]  #1 wdin;
  wire         #1 push;
  wire         #1 pop;
   
// Module Declarations ***********************************************

SRL16E fifo0 (.CLK(wclk), .CE(push), .D(wdin[0]), 
               .A0(raddr[0]), .A1(raddr[1]), .A2(raddr[2]),
               .A3(raddr[3]), .Q(rdout[0]));

SRL16E fifo1 (.CLK(wclk), .CE(push), .D(wdin[1]), 
               .A0(raddr[0]), .A1(raddr[1]), .A2(raddr[2]),
               .A3(raddr[3]), .Q(rdout[1]));

SRL16E fifo2 (.CLK(wclk), .CE(push), .D(wdin[2]), 
               .A0(raddr[0]), .A1(raddr[1]), .A2(raddr[2]),
               .A3(raddr[3]), .Q(rdout[2]));

SRL16E fifo3 (.CLK(wclk), .CE(push), .D(wdin[3]), 
               .A0(raddr[0]), .A1(raddr[1]), .A2(raddr[2]),
               .A3(raddr[3]), .Q(rdout[3]));

// Main body of code *************************************************

  
// Call all the helper logic that generates the read address pointers
fifo_32_rdcntr raddr_cntr0
  (.rclk(rclk), .rst(rst), .ren(pop), .wen(push), .raddr(raddr));


endmodule

