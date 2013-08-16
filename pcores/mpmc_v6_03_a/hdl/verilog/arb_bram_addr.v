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
// Description: Logic to create arbitration BRAM address.
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

module arb_bram_addr
  (
   Clk,              // I
   Rst,              // I
   Arb_Sequence,     // I [C_ARB_SEQUENCE_ENCODING_WIDTH-1:0]
   Arb_LoadSequence, // I
   Ctrl_Complete,    // I
   Ctrl_Idle,        // I
   Arb_BRAMAddr      // O [C_ARB_BRAM_ADDR_WIDTH-1:0]
   );

   parameter C_ARB_SEQUENCE_ENCODING_WIDTH = 4;  // Allowed Values: 4
   parameter C_ARB_BRAM_ADDR_WIDTH = 9;          // Allowed Values: 9
   parameter C_BASEADDR_ARB0 = 9'b0_0000_0000;
   parameter C_HIGHADDR_ARB0 = 9'b0_0001_1111;
   parameter C_BASEADDR_ARB1 = 9'b0_0010_0000;
   parameter C_HIGHADDR_ARB1 = 9'b0_0011_1111;
   parameter C_BASEADDR_ARB2 = 9'b0_0100_0000;
   parameter C_HIGHADDR_ARB2 = 9'b0_0101_1111;
   parameter C_BASEADDR_ARB3 = 9'b0_0110_0000;
   parameter C_HIGHADDR_ARB3 = 9'b0_0111_1111;
   parameter C_BASEADDR_ARB4 = 9'b0_1000_0000;
   parameter C_HIGHADDR_ARB4 = 9'b0_1001_1111;
   parameter C_BASEADDR_ARB5 = 9'b0_1010_0000;
   parameter C_HIGHADDR_ARB5 = 9'b0_1011_1111;
   parameter C_BASEADDR_ARB6 = 9'b0_1100_0000;
   parameter C_HIGHADDR_ARB6 = 9'b0_1101_1111;
   parameter C_BASEADDR_ARB7 = 9'b0_1110_0000;
   parameter C_HIGHADDR_ARB7 = 9'b0_1111_1111;
   parameter C_BASEADDR_ARB8 = 9'b1_0000_0000;
   parameter C_HIGHADDR_ARB8 = 9'b1_0001_1111;
   parameter C_BASEADDR_ARB9 = 9'b1_0010_0000;
   parameter C_HIGHADDR_ARB9 = 9'b1_0011_1111;
   parameter C_BASEADDR_ARB10 = 9'b1_0100_0000;
   parameter C_HIGHADDR_ARB10 = 9'b1_0101_1111;
   parameter C_BASEADDR_ARB11 = 9'b1_0110_0000;
   parameter C_HIGHADDR_ARB11 = 9'b1_0111_1111;
   parameter C_BASEADDR_ARB12 = 9'b1_1000_0000;
   parameter C_HIGHADDR_ARB12 = 9'b1_1001_1111;
   parameter C_BASEADDR_ARB13 = 9'b1_1010_0000;
   parameter C_HIGHADDR_ARB13 = 9'b1_1011_1111;
   parameter C_BASEADDR_ARB14 = 9'b1_1100_0000;
   parameter C_HIGHADDR_ARB14 = 9'b1_1101_1111;
   parameter C_BASEADDR_ARB15 = 9'b1_1110_0000;
   parameter C_HIGHADDR_ARB15 = 9'b1_1111_1111;
   
   
   input                                     Clk;
   input                                     Rst;
   input [C_ARB_SEQUENCE_ENCODING_WIDTH-1:0] Arb_Sequence;
   input                                     Arb_LoadSequence;
   input                                     Ctrl_Complete;
   input                                     Ctrl_Idle;
   output [C_ARB_BRAM_ADDR_WIDTH-1:0]        Arb_BRAMAddr;

   reg [C_ARB_BRAM_ADDR_WIDTH-1:0]           Arb_BRAMAddr = 0;
   reg [C_ARB_BRAM_ADDR_WIDTH-1:0]           arb_baseaddr = 0;
   reg [C_ARB_BRAM_ADDR_WIDTH-1:0]           arb_highaddr = 0;
   
   // Instantiate Base Address Mux
   always @(Arb_Sequence) begin
      case (Arb_Sequence)
        0: arb_baseaddr <= C_BASEADDR_ARB0;
        1: arb_baseaddr <= C_BASEADDR_ARB1;
        2: arb_baseaddr <= C_BASEADDR_ARB2;
        3: arb_baseaddr <= C_BASEADDR_ARB3;
        4: arb_baseaddr <= C_BASEADDR_ARB4;
        5: arb_baseaddr <= C_BASEADDR_ARB5;
        6: arb_baseaddr <= C_BASEADDR_ARB6;
        7: arb_baseaddr <= C_BASEADDR_ARB7;
        8: arb_baseaddr <= C_BASEADDR_ARB8;
        9: arb_baseaddr <= C_BASEADDR_ARB9;
        10: arb_baseaddr <= C_BASEADDR_ARB10;
        11: arb_baseaddr <= C_BASEADDR_ARB11;
        12: arb_baseaddr <= C_BASEADDR_ARB12;
        13: arb_baseaddr <= C_BASEADDR_ARB13;
        14: arb_baseaddr <= C_BASEADDR_ARB14;
        15: arb_baseaddr <= C_BASEADDR_ARB15;
      endcase
   end
   
   // Instantiate High Address Mux
   always @(Arb_Sequence) begin
      case (Arb_Sequence)
        0: arb_highaddr <= C_HIGHADDR_ARB0;
        1: arb_highaddr <= C_HIGHADDR_ARB1;
        2: arb_highaddr <= C_HIGHADDR_ARB2;
        3: arb_highaddr <= C_HIGHADDR_ARB3;
        4: arb_highaddr <= C_HIGHADDR_ARB4;
        5: arb_highaddr <= C_HIGHADDR_ARB5;
        6: arb_highaddr <= C_HIGHADDR_ARB6;
        7: arb_highaddr <= C_HIGHADDR_ARB7;
        8: arb_highaddr <= C_HIGHADDR_ARB8;
        9: arb_highaddr <= C_HIGHADDR_ARB9;
        10: arb_highaddr <= C_HIGHADDR_ARB10;
        11: arb_highaddr <= C_HIGHADDR_ARB11;
        12: arb_highaddr <= C_HIGHADDR_ARB12;
        13: arb_highaddr <= C_HIGHADDR_ARB13;
        14: arb_highaddr <= C_HIGHADDR_ARB14;
        15: arb_highaddr <= C_HIGHADDR_ARB15;
      endcase
   end

   // Instantiate Counter
   always @(posedge Clk) begin
      if (Rst | Arb_LoadSequence | ((arb_highaddr == Arb_BRAMAddr) & (Ctrl_Complete | Ctrl_Idle)))
        Arb_BRAMAddr <= arb_baseaddr;
      else if (Ctrl_Complete | Ctrl_Idle)
        Arb_BRAMAddr <= Arb_BRAMAddr + 1;
   end
   
endmodule // arb_bram_addr


