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
// Description: Logic to create FIFO to store sequence of pattern type
// signal.  Used to pipeline address requests.
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
module arb_pattern_type_fifo
  (
   Clk,                    // I
   Rst,                    // I
   PI_Size,                // I [3:0]
   PI_RNW,                 // I
   PI_RdModWr,             // I
   PI_AddrAck,             // I 
   PI_ArbPatternType_Pop,  // I 
   PI_ArbPatternType,      // O [C_ARB_PATTERN_TYPE_WIDTH-1:0]
   PI_ArbRdModWr           // O
   );

  parameter C_PI_DATA_WIDTH = 1'b1;
  parameter integer C_INCLUDE_ECC_SUPPORT = 0;
  parameter C_ARB_PATTERN_TYPE_WIDTH = 4; // Allowed Values: 4
  parameter C_MAX_REQ_ALLOWED_INT = 2;        // Allowed Values: Any integer
  parameter C_WORD_WRITE_SEQ       =  0;
  parameter C_WORD_READ_SEQ        =  1;
  parameter C_DOUBLEWORD_WRITE_SEQ =  2;
  parameter C_DOUBLEWORD_READ_SEQ  =  3;
  parameter C_CL4_WRITE_SEQ        =  4;
  parameter C_CL4_READ_SEQ         =  5;
  parameter C_CL8_WRITE_SEQ        =  6;
  parameter C_CL8_READ_SEQ         =  7;
  parameter C_B16_WRITE_SEQ        =  8;
  parameter C_B16_READ_SEQ         =  9;
  parameter C_B32_WRITE_SEQ        = 10;
  parameter C_B32_READ_SEQ         = 11;
  parameter C_B64_WRITE_SEQ        = 12;
  parameter C_B64_READ_SEQ         = 13;
  parameter C_REFH_SEQ             = 14;
  parameter C_NOP_SEQ              = 15;
  
  input     Clk;
  input     Rst;
  input [3:0] PI_Size;
  input       PI_RNW;
  input       PI_RdModWr;
  input       PI_AddrAck;
  input       PI_ArbPatternType_Pop;
  output [C_ARB_PATTERN_TYPE_WIDTH-1:0] PI_ArbPatternType;
  output                                PI_ArbRdModWr;
  
  localparam P_FIFO_DEPTH =      (C_MAX_REQ_ALLOWED_INT <=  1) ?  2 :
                                 (C_MAX_REQ_ALLOWED_INT <=  3) ?  4 :
                                 (C_MAX_REQ_ALLOWED_INT <=  7) ?  8 :
                                 (C_MAX_REQ_ALLOWED_INT <= 15) ? 16 : 0;
  localparam P_FIFO_ADDR_DEPTH = (C_MAX_REQ_ALLOWED_INT <=  1) ? 1 :
                                 (C_MAX_REQ_ALLOWED_INT <=  3) ? 2 :
                                 (C_MAX_REQ_ALLOWED_INT <=  7) ? 3 :
                                 (C_MAX_REQ_ALLOWED_INT <= 15) ? 4 : 0;
  reg [C_ARB_PATTERN_TYPE_WIDTH-1:0]    pi_arbpatterntype_i;
  reg [C_ARB_PATTERN_TYPE_WIDTH-1:0]    pi_arbpatterntype_i2a = 0;
  wire [C_ARB_PATTERN_TYPE_WIDTH-1:0]   pi_arbpatterntype_i2b;
  reg [C_ARB_PATTERN_TYPE_WIDTH-1:0]    pi_arbpatterntype_i3 = 0;
  reg [1:0]                             arb_patterntype_cnt = 0;
  reg                                   pi_arbrdmodwr_i1a = 0;
  wire                                  pi_arbrdmodwr_i1b;
  reg                                   pi_arbrdmodwr_i2 = 0;
  
  // Encode request type
  always @(*) begin
    case ({PI_Size[2:0],PI_RNW})
      4'h0: pi_arbpatterntype_i <= (C_PI_DATA_WIDTH == 1'b0) ?
                                   C_WORD_WRITE_SEQ :
                                   C_DOUBLEWORD_WRITE_SEQ;
      4'h1: pi_arbpatterntype_i <= (C_PI_DATA_WIDTH == 1'b0) ?
                                   C_WORD_READ_SEQ :
                                   C_DOUBLEWORD_READ_SEQ;
      4'h2: pi_arbpatterntype_i <= C_CL4_WRITE_SEQ;
      4'h3: pi_arbpatterntype_i <= C_CL4_READ_SEQ;
      4'h4: pi_arbpatterntype_i <= C_CL8_WRITE_SEQ;
      4'h5: pi_arbpatterntype_i <= C_CL8_READ_SEQ;
      4'h6: pi_arbpatterntype_i <= C_B16_WRITE_SEQ;
      4'h7: pi_arbpatterntype_i <= C_B16_READ_SEQ;
      4'h8: pi_arbpatterntype_i <= C_B32_WRITE_SEQ;
      4'h9: pi_arbpatterntype_i <= C_B32_READ_SEQ;
      4'hA: pi_arbpatterntype_i <= C_B64_WRITE_SEQ;
      4'hB: pi_arbpatterntype_i <= C_B64_READ_SEQ;
      default: pi_arbpatterntype_i <= C_DOUBLEWORD_WRITE_SEQ;
    endcase
  end

  // Instantiate 4-bit SRL16 FIFOs
  /*
  generate
    if (C_MAX_REQ_ALLOWED_INT == 1) begin : instantiate_pattern_type_fifo_1deep
      always @(posedge Clk) begin
        if (Rst)
          arb_patterntype_cnt <= 0;
        else if (PI_AddrAck & PI_ArbPatternType_Pop)
          arb_patterntype_cnt <= arb_patterntype_cnt;
        else if (PI_AddrAck)
          arb_patterntype_cnt <= arb_patterntype_cnt + 1;
        else if (PI_ArbPatternType_Pop)
          arb_patterntype_cnt <= arb_patterntype_cnt - 1;
        else
          arb_patterntype_cnt <= arb_patterntype_cnt;
      end
      always @(posedge Clk) begin
        if (PI_AddrAck)
          pi_arbpatterntype_i2a <= pi_arbpatterntype_i;
        else
          pi_arbpatterntype_i2a <= pi_arbpatterntype_i2a;
      end
      assign pi_arbpatterntype_i2b = (arb_patterntype_cnt==0) | (PI_AddrAck & PI_ArbPatternType_Pop) ? pi_arbpatterntype_i : pi_arbpatterntype_i2a;
      always @(posedge Clk) begin
        if (arb_patterntype_cnt==0 | PI_ArbPatternType_Pop)
          pi_arbpatterntype_i3 <= pi_arbpatterntype_i2b;
        else
          pi_arbpatterntype_i3 <= pi_arbpatterntype_i3;
      end
      assign PI_ArbPatternType = pi_arbpatterntype_i3;
    end
    else begin : instantiate_pattern_type_fifo_ndeep
      fifo_4 P0_rdFIFO_pos 
        (
         .rst   (Rst),
         .wclk  (Clk),
         .wdin  (pi_arbpatterntype_i),
         .push  (PI_AddrAck),
         .rclk  (Clk),
         .rdout (PI_ArbPatternType),
         .pop   (PI_ArbPatternType_Pop)
         );
    end
  endgenerate
   */
   
  // Provide PI_ArbRdModWr signal with PI_ArbPatternType
  generate
    if (C_INCLUDE_ECC_SUPPORT == 0)
      begin : gen_pi_arbrdmodwr_noecc
        assign PI_ArbRdModWr = 0;
        mpmc_ctrl_path_fifo #
          (
           .C_FIFO_DEPTH      (P_FIFO_DEPTH),
           .C_FIFO_ADDR_WIDTH (P_FIFO_ADDR_DEPTH),
           .C_DATA_WIDTH      (C_ARB_PATTERN_TYPE_WIDTH)
           )
          pi_arbpatterntype_fifo
            (
             .Rst  (Rst),
             .Clk  (Clk),
             .Push (PI_AddrAck),
             .DIn  (pi_arbpatterntype_i),
             .Pop  (PI_ArbPatternType_Pop),
             .DOut (PI_ArbPatternType)
             );
      end
    else
      begin : gen_pi_arbrdmodwr_ecc
        mpmc_ctrl_path_fifo #
          (
           .C_FIFO_DEPTH      (P_FIFO_DEPTH),
           .C_FIFO_ADDR_WIDTH (P_FIFO_ADDR_DEPTH),
           .C_DATA_WIDTH      (C_ARB_PATTERN_TYPE_WIDTH+1)
           )
          pi_arbpatterntype_fifo
            (
             .Rst  (Rst),
             .Clk  (Clk),
             .Push (PI_AddrAck),
             .DIn  ({PI_RdModWr,pi_arbpatterntype_i}),
             .Pop  (PI_ArbPatternType_Pop),
             .DOut ({PI_ArbRdModWr,PI_ArbPatternType})
             );
        /*
        if (C_MAX_REQ_ALLOWED_INT == 1)
          begin : gen_small_fifo
            always @(posedge Clk) begin
              if (PI_AddrAck)
                pi_arbrdmodwr_i1a <= PI_RdModWr;
            end
            assign pi_arbrdmodwr_i1b = (arb_patterntype_cnt==0) | (PI_AddrAck & PI_ArbPatternType_Pop) ? PI_RdModWr : pi_arbrdmodwr_i1a;
            always @(posedge Clk) begin
              if (arb_patterntype_cnt==0 | PI_ArbPatternType_Pop)
                pi_arbrdmodwr_i2 <= pi_arbrdmodwr_i1b;
            end
            assign PI_ArbRdModWr = pi_arbrdmodwr_i2;
          end
        else
          begin : gen_large_fifo
            fifo_1 rdmodwrfifo 
              (
               .rst   (Rst),
               .wclk  (Clk),
               .wdin  (PI_RdModWr),
               .push  (PI_AddrAck),
               .rclk  (Clk),
               .rdout (PI_ArbRdModWr),
               .pop   (PI_ArbPatternType_Pop)
               );
          end
         */
      end
  endgenerate
   
endmodule // arb_pattern_type_fifo

