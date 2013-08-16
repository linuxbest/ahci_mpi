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
// Description: Logic to specify which arbitration priority levels have a 
// request pending.
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
module arb_req_pending_muxes
  (
   Arb_ReqPending,      // I [C_NUM_PORTS-1:0]
   Arb_PortNum,         // I [C_ARB_PORT_ENCODING_WIDTH-1:0]
   Arb_PatternEnable    // O 
   );
   
   parameter C_NUM_PORTS = 8;               // Allowed Values: 1-8
   parameter C_ARB_PORT_ENCODING_WIDTH = 3; // Allowed Values: 1-3

   input [C_NUM_PORTS-1:0]                          Arb_ReqPending;
   input [C_ARB_PORT_ENCODING_WIDTH-1:0]            Arb_PortNum;
   output                                           Arb_PatternEnable;

   reg                                              Arb_PatternEnable = 0;

   wire [2:0]                                       arb_portnum_i;

   wire [7:0]                                       arb_reqpending_i;
   
   
   // Instantiate Enable Mux
   assign arb_portnum_i = Arb_PortNum;

   assign arb_reqpending_i = Arb_ReqPending;
   
   always @(arb_portnum_i or arb_reqpending_i)
     case (arb_portnum_i)
       0: Arb_PatternEnable <= arb_reqpending_i[0];
       1: Arb_PatternEnable <= arb_reqpending_i[1];
       2: Arb_PatternEnable <= arb_reqpending_i[2];
       3: Arb_PatternEnable <= arb_reqpending_i[3];
       4: Arb_PatternEnable <= arb_reqpending_i[4];
       5: Arb_PatternEnable <= arb_reqpending_i[5];
       6: Arb_PatternEnable <= arb_reqpending_i[6];
       7: Arb_PatternEnable <= arb_reqpending_i[7];
     endcase // case(arb_portnum_i)

endmodule // arb_req_pending_muxes

