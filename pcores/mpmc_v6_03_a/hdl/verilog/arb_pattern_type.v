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
// Description: Logic to create pattern type signal from arbiter to the
// control path.
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
module arb_pattern_type
  (
   Clk,                    // I
   Rst,                    // I
   PI_Size,                // I [C_NUM_PORTS*4-1:0]
   PI_RNW,                 // I [C_NUM_PORTS-1:0]
   PI_RdModWr,             // I [C_NUM_PORTS-1:0]
   PI_AddrAck,             // I [C_NUM_PORTS-1:0]
   PI_ArbPatternType_Pop,  // I [C_NUM_PORTS-1:0]
   Ctrl_Idle,              // I
   Ctrl_AlmostIdle,              // I
   Ctrl_Complete,              // I
   Ctrl_InitializeMemory,  // I
   Ctrl_Maint,           // I
   Ctrl_Maint_Enable,    // I
   PhyIF_Ctrl_InitDone,    // I
   Arb_WhichPort,          // I [C_ARB_PORT_ENCODING_WIDTH-1:0]
   Arb_PatternStart,       // I
   Arb_PatternStart_i,     // I
   Arb_PatternType_Decode, // O [C_ARB_PATTERN_TYPE_DECODE_WIDTH-1:0]
   Arb_PatternType,        // O [C_ARB_PATTERN_TYPE_WIDTH-1:0]
   Arb_RdModWr             // O
   );
   
   parameter C_FAMILY = "virtex4";
   parameter integer C_INCLUDE_ECC_SUPPORT = 0;
   parameter C_NUM_PORTS = 8;               // Allowed Values: 1-8
   parameter C_PI_DATA_WIDTH = 8'hFF;
   parameter C_ARB_PORT_ENCODING_WIDTH = 3; // Allowed Values: 1-3
   parameter C_ARB_PATTERN_TYPE_WIDTH = 4;  // Allowed Values: 4
   parameter C_ARB_PATTERN_TYPE_DECODE_WIDTH = 16; // Allowed Values: 16
   parameter C_CP_PIPELINE = 0;            // Allowed Values: 0-1
   parameter C_MAX_REQ_ALLOWED_INT = 2;        // Allowed Values: Any integer
   parameter C_WORD_WRITE_SEQ       = 4'd0;
   parameter C_WORD_READ_SEQ        = 4'd1;
   parameter C_DOUBLEWORD_WRITE_SEQ = 4'd2;
   parameter C_DOUBLEWORD_READ_SEQ  = 4'd3;
   parameter C_CL4_WRITE_SEQ        = 4'd4;
   parameter C_CL4_READ_SEQ         = 4'd5;
   parameter C_CL8_WRITE_SEQ        = 4'd6;
   parameter C_CL8_READ_SEQ         = 4'd7;
   parameter C_B16_WRITE_SEQ        = 4'd8;
   parameter C_B16_READ_SEQ         = 4'd9;
   parameter C_B32_WRITE_SEQ        = 4'd10;
   parameter C_B32_READ_SEQ         = 4'd11;
   parameter C_B64_WRITE_SEQ        = 4'd12;
   parameter C_B64_READ_SEQ         = 4'd13;
   parameter C_REFH_SEQ             = 4'd14;
   parameter C_NOP_SEQ              = 4'd15;
 
   input                                             Clk;
   input                                             Rst;
   input [C_NUM_PORTS*4-1:0]                         PI_Size;
   input [C_NUM_PORTS-1:0]                           PI_RNW;
   input [C_NUM_PORTS-1:0]                           PI_RdModWr;
   input [C_NUM_PORTS-1:0]                           PI_AddrAck;
   input [C_NUM_PORTS-1:0]                           PI_ArbPatternType_Pop;
   input                                             Ctrl_Idle;
   input                                             Ctrl_AlmostIdle;
   input                                             Ctrl_Complete;
   input                                             Ctrl_InitializeMemory;
   input                                             Ctrl_Maint;
   input                                             Ctrl_Maint_Enable;
   input                                             PhyIF_Ctrl_InitDone;
   input [C_ARB_PORT_ENCODING_WIDTH-1:0]             Arb_WhichPort;
   input                                             Arb_PatternStart;
   input                                             Arb_PatternStart_i;
   output [C_ARB_PATTERN_TYPE_WIDTH-1:0]             Arb_PatternType;
   output [C_ARB_PATTERN_TYPE_DECODE_WIDTH-1:0]      Arb_PatternType_Decode;
   output                                            Arb_RdModWr;
   
   reg [C_NUM_PORTS-1:0]                             PI_ArbPatternType_Pop_d1 = 0;
   reg                                               Arb_RdModWr = 0;
   reg                                               Ctrl_Maint_d1 = 0;
   reg                                               Ctrl_Maint_Enable_d1 = 0;
   reg [C_ARB_PATTERN_TYPE_WIDTH-1:0]                Arb_PatternType = 0;
   reg [C_ARB_PATTERN_TYPE_DECODE_WIDTH-1:0]         Arb_PatternType_Decode = 0;
   wire [C_NUM_PORTS*C_ARB_PATTERN_TYPE_WIDTH-1:0]   pi_arbpatterntype_i1;
   reg  [C_NUM_PORTS*C_ARB_PATTERN_TYPE_WIDTH-1:0]   pi_arbpatterntype_i1a = 0;
   wire [C_ARB_PATTERN_TYPE_WIDTH-1:0]               pi_arbpatterntype_i2;
   wire [7:0]                                        pi_arbrdmodwr_i1;
   reg                                               pi_arbrdmodwr_i2 = 0;
   
   genvar i;
   
   // Instantiate per port FIFOs for the sequence pattern type
   always @(posedge Clk)
     PI_ArbPatternType_Pop_d1 <= PI_ArbPatternType_Pop;
   generate
      for (i=0;i<C_NUM_PORTS;i=i+1) begin : instantiate_arb_pattern_type_fifos
         arb_pattern_type_fifo 
           #(
             .C_PI_DATA_WIDTH          (C_PI_DATA_WIDTH[i]),
             .C_INCLUDE_ECC_SUPPORT    (C_INCLUDE_ECC_SUPPORT),
             .C_ARB_PATTERN_TYPE_WIDTH (C_ARB_PATTERN_TYPE_WIDTH),
             .C_MAX_REQ_ALLOWED_INT    (C_MAX_REQ_ALLOWED_INT),
             .C_WORD_WRITE_SEQ         (C_WORD_WRITE_SEQ),
             .C_WORD_READ_SEQ          (C_WORD_READ_SEQ),
             .C_DOUBLEWORD_WRITE_SEQ   (C_DOUBLEWORD_WRITE_SEQ),
             .C_DOUBLEWORD_READ_SEQ    (C_DOUBLEWORD_READ_SEQ),
             .C_CL4_WRITE_SEQ          (C_CL4_WRITE_SEQ),
             .C_CL4_READ_SEQ           (C_CL4_READ_SEQ),
             .C_CL8_WRITE_SEQ          (C_CL8_WRITE_SEQ),
             .C_CL8_READ_SEQ           (C_CL8_READ_SEQ),
             .C_B16_WRITE_SEQ          (C_B16_WRITE_SEQ),
             .C_B16_READ_SEQ           (C_B16_READ_SEQ),
             .C_B32_WRITE_SEQ          (C_B32_WRITE_SEQ),
             .C_B32_READ_SEQ           (C_B32_READ_SEQ),
             .C_B64_WRITE_SEQ          (C_B64_WRITE_SEQ),
             .C_B64_READ_SEQ           (C_B64_READ_SEQ),
             .C_REFH_SEQ               (C_REFH_SEQ),
             .C_NOP_SEQ                (C_NOP_SEQ)
             )
             arb_pattern_type_fifo_
               (
                .Clk                   (Clk),
                .Rst                   (Rst),
                .PI_Size               (PI_Size[(i+1)*4-1:i*4]),
                .PI_RNW                (PI_RNW[i]),
                .PI_RdModWr            (PI_RdModWr[i]),
                .PI_AddrAck            (PI_AddrAck[i]),
                .PI_ArbPatternType_Pop (PI_ArbPatternType_Pop_d1[i]),
                .PI_ArbPatternType     (pi_arbpatterntype_i1[C_ARB_PATTERN_TYPE_WIDTH*i +: C_ARB_PATTERN_TYPE_WIDTH]),
                .PI_ArbRdModWr         (pi_arbrdmodwr_i1[i])
                );
      end

      // Tie off outputs for unused ports
      for (i = C_NUM_PORTS; i < 8; i = i + 1) begin : instantiate_arb_pattern_type_fifos_tie_offs
        assign pi_arbrdmodwr_i1[i] = 1'b0;
        // assign pi_arbpatterntype_i1[C_ARB_PATTERN_TYPE_WIDTH*i +: C_ARB_PATTERN_TYPE_WIDTH] = {C_ARB_PATTERN_TYPE_WIDTH{1'b0}};
      end
   endgenerate

   // Instantiate per port muxes for the sequence pattern type

   arb_pattern_type_muxes
     #(
       .C_NUM_PORTS               (C_NUM_PORTS),
       .C_ARB_PORT_ENCODING_WIDTH (C_ARB_PORT_ENCODING_WIDTH),
       .C_ARB_PATTERN_TYPE_WIDTH  (C_ARB_PATTERN_TYPE_WIDTH)
       )
       arb_pattern_type_muxes_
         (
          .Arb_WhichPort       (Arb_WhichPort),
          .PI_ArbPatternType_I (pi_arbpatterntype_i1),
          .PI_ArbPatternType_O (pi_arbpatterntype_i2)
          );
   always @(*)
     begin
        case (Arb_WhichPort)
          0: pi_arbrdmodwr_i2 <= pi_arbrdmodwr_i1[0];
          1: pi_arbrdmodwr_i2 <= pi_arbrdmodwr_i1[1];
          2: pi_arbrdmodwr_i2 <= pi_arbrdmodwr_i1[2];
          3: pi_arbrdmodwr_i2 <= pi_arbrdmodwr_i1[3];
          4: pi_arbrdmodwr_i2 <= pi_arbrdmodwr_i1[4];
          5: pi_arbrdmodwr_i2 <= pi_arbrdmodwr_i1[5];
          6: pi_arbrdmodwr_i2 <= pi_arbrdmodwr_i1[6];
          7: pi_arbrdmodwr_i2 <= pi_arbrdmodwr_i1[7];
          default: pi_arbrdmodwr_i2 <= pi_arbrdmodwr_i1[0];
        endcase
     end

   // Instantiate FFs to select the highest priority port
   always @(posedge Clk) begin
      Ctrl_Maint_d1 <= Ctrl_Maint;
      Ctrl_Maint_Enable_d1 <= Ctrl_Maint_Enable;
   end
   generate
      if (C_CP_PIPELINE==0) begin : patterntype_nopipeline
         always @(*) begin
            Arb_PatternType <= (PhyIF_Ctrl_InitDone & Ctrl_Maint_d1 & Ctrl_Maint_Enable_d1) ? C_REFH_SEQ : 
                               Ctrl_Idle ? C_NOP_SEQ : pi_arbpatterntype_i2;
         end
         always @(*) begin
            Arb_RdModWr <= pi_arbrdmodwr_i2;
         end
      end
      else begin : patterntype_pipeline
         always @(posedge Clk) begin
            Arb_PatternType <= Ctrl_AlmostIdle ? C_NOP_SEQ : 
                               (PhyIF_Ctrl_InitDone & Ctrl_Maint_d1 
                                & Ctrl_Maint_Enable_d1 
                                & (Arb_PatternStart_i 
                                   | Arb_PatternType_Decode[C_REFH_SEQ]))  ? C_REFH_SEQ :
                               pi_arbpatterntype_i2;
            Arb_RdModWr <= pi_arbrdmodwr_i2;
         end
      end
   endgenerate
   
   always @(Arb_PatternType) begin
      case (Arb_PatternType)
        0: Arb_PatternType_Decode <= 1;
        1: Arb_PatternType_Decode <= 2;
        2: Arb_PatternType_Decode <= 4;
        3: Arb_PatternType_Decode <= 8;
        4: Arb_PatternType_Decode <= 16;
        5: Arb_PatternType_Decode <= 32;
        6: Arb_PatternType_Decode <= 64;
        7: Arb_PatternType_Decode <= 128;
        8: Arb_PatternType_Decode <= 256;
        9: Arb_PatternType_Decode <= 512;
        10: Arb_PatternType_Decode <= 1024;
        11: Arb_PatternType_Decode <= 2048;
        12: Arb_PatternType_Decode <= 4096;
        13: Arb_PatternType_Decode <= 8192;
        14: Arb_PatternType_Decode <= 16384;
        15: Arb_PatternType_Decode <= 32768;
      endcase   
   end
endmodule // arb_pattern_type

