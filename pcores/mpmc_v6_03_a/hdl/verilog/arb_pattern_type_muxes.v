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
// Description: Logic to select the patten type depending on which port is
// active.
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
module arb_pattern_type_muxes
  (
   Arb_WhichPort,       // I [C_ARB_PORT_ENCODING_WIDTH-1:0]
   PI_ArbPatternType_I, // I [C_NUM_PORTS*C_ARB_PATTERN_TYPE_WIDTH-1:0]
   PI_ArbPatternType_O  // O [C_ARB_PATTERN_TYPE_WIDTH-1:0]
   );
   
   parameter C_NUM_PORTS = 8;               // Allowed Values: 1-8
   parameter C_ARB_PORT_ENCODING_WIDTH = 3; // Allowed Values: 1-3
   parameter C_ARB_PATTERN_TYPE_WIDTH = 4;  // Allowed Values: 4

   input [C_ARB_PORT_ENCODING_WIDTH-1:0]            Arb_WhichPort;
   input [C_NUM_PORTS*C_ARB_PATTERN_TYPE_WIDTH-1:0] PI_ArbPatternType_I;
   output [C_ARB_PATTERN_TYPE_WIDTH-1:0]            PI_ArbPatternType_O;

   reg [C_ARB_PATTERN_TYPE_WIDTH-1:0]               PI_ArbPatternType_O = 0;
   wire [8*C_ARB_PATTERN_TYPE_WIDTH-1:0]            PI_ArbPatternType_I_i;
   
   
   assign PI_ArbPatternType_I_i = PI_ArbPatternType_I;
   
   generate
      if (C_NUM_PORTS == 1) begin : instantiate_Arb_PatternType_O_1port
         always @(PI_ArbPatternType_I_i) begin
            PI_ArbPatternType_O = PI_ArbPatternType_I_i[1*C_ARB_PATTERN_TYPE_WIDTH-1:0*C_ARB_PATTERN_TYPE_WIDTH];
         end
      end
      else begin : instantiate_Arb_PatternType_O_2to8ports
         always @(Arb_WhichPort or PI_ArbPatternType_I_i)
           case (Arb_WhichPort)
             0: PI_ArbPatternType_O = PI_ArbPatternType_I_i[1*C_ARB_PATTERN_TYPE_WIDTH-1:0*C_ARB_PATTERN_TYPE_WIDTH];
             1: if (C_NUM_PORTS > 1)
               PI_ArbPatternType_O = PI_ArbPatternType_I_i[2*C_ARB_PATTERN_TYPE_WIDTH-1:1*C_ARB_PATTERN_TYPE_WIDTH];
             else
           PI_ArbPatternType_O = 0;
             2: if (C_NUM_PORTS > 2)
               PI_ArbPatternType_O = PI_ArbPatternType_I_i[3*C_ARB_PATTERN_TYPE_WIDTH-1:2*C_ARB_PATTERN_TYPE_WIDTH];
             else
               PI_ArbPatternType_O = 0;
             3: if (C_NUM_PORTS > 3)
               PI_ArbPatternType_O = PI_ArbPatternType_I_i[4*C_ARB_PATTERN_TYPE_WIDTH-1:3*C_ARB_PATTERN_TYPE_WIDTH];
             else
               PI_ArbPatternType_O = 0;
             4: if (C_NUM_PORTS > 4)
         PI_ArbPatternType_O = PI_ArbPatternType_I_i[5*C_ARB_PATTERN_TYPE_WIDTH-1:4*C_ARB_PATTERN_TYPE_WIDTH];
             else
               PI_ArbPatternType_O = 0;
             5: if (C_NUM_PORTS > 5)
               PI_ArbPatternType_O = PI_ArbPatternType_I_i[6*C_ARB_PATTERN_TYPE_WIDTH-1:5*C_ARB_PATTERN_TYPE_WIDTH];
             else
               PI_ArbPatternType_O = 0;
             6: if (C_NUM_PORTS > 6)
               PI_ArbPatternType_O = PI_ArbPatternType_I_i[7*C_ARB_PATTERN_TYPE_WIDTH-1:6*C_ARB_PATTERN_TYPE_WIDTH];
             else
               PI_ArbPatternType_O = 0;
             7: if (C_NUM_PORTS > 7)
               PI_ArbPatternType_O = PI_ArbPatternType_I_i[8*C_ARB_PATTERN_TYPE_WIDTH-1:7*C_ARB_PATTERN_TYPE_WIDTH];
             else
               PI_ArbPatternType_O = 0;
           endcase
         end
      endgenerate
endmodule // arb_pattern_type_muxes


