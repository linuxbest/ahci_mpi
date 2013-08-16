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
// Description: Top level arbiter.
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
module arbiter
  (
   Clk,                       // I
   Rst,                       // I
   PI_AddrReq,                // I [C_NUM_PORTS-1:0]
   PI_Size,                   // I [C_NUM_PORTS*4-1:0]
   PI_RNW,                    // I [C_NUM_PORTS-1:0]
   PI_RdModWr,                // I [C_NUM_PORTS-1:0]
   PI_AddrAck,                // O [C_NUM_PORTS-1:0]
   PI_ArbPatternType_Pop,     // I [C_NUM_PORTS-1:0]
   Ctrl_InitializeMemory,     // I
   Ctrl_Maint,              // I
   Ctrl_Maint_Enable,       // I
   Ctrl_Complete,             // I
   Ctrl_Idle,                 // I
   Ctrl_AlmostIdle,           // I
   PhyIF_Ctrl_InitDone,       // I
   Ctrl_AP_Pipeline1_CE,      // I
   DP_Ctrl_RdFIFO_AlmostFull, // I [C_NUM_PORTS-1:0]
   Arb_Sequence,              // I [C_ARB_SEQUENCE_ENCODING_WIDTH-1:0]
   Arb_LoadSequence,          // I
   Arb_PatternStart_i,        // O
   Arb_PatternStart,          // O
   Arb_WhichPort_Decode,      // O [C_NUM_PORTS-1:0]
   Arb_WhichPort,             // O [C_ARB_PORT_ENCODING_WIDTH-1:0]
   Arb_PatternType_Decode,    // O [C_ARB_PATTERN_TYPE_DECODE_WIDTH-1:0]
   Arb_PatternType,           // O [C_ARB_PATTERN_TYPE_WIDTH-1:0]
   Arb_RdModWr                // O
   );

   parameter C_FAMILY           = "virtex4";
   parameter C_USE_INIT_PUSH    = 0;
   
   parameter integer C_INCLUDE_ECC_SUPPORT = 0;

   parameter C_NUM_PORTS        = 8;       // Allowed Values: 1-8
   parameter C_PIPELINE_ADDRACK = 8'h00;   // Allowed Values: 8'h00-8'hFF, each
                                           // bit corresponds to an individual port.
   parameter C_PI_DATA_WIDTH = 8'hFF;
   parameter C_CP_PIPELINE = 0;            // Allowed Values: 0-1
   parameter C_MAX_REQ_ALLOWED_INT  = 2;       // Allowed Values: Any integer

   parameter C_ARB_PORT_ENCODING_WIDTH     = 3; // Allowed Values: 1-3
   parameter C_ARB_PATTERN_TYPE_WIDTH      = 4; // Allowed Values: 4
   parameter C_ARB_PATTERN_TYPE_DECODE_WIDTH = 16; // Allowed Values: 16
   parameter C_ARB_SEQUENCE_ENCODING_WIDTH = 4; // Allowed Values: 4
   parameter C_ARB_BRAM_ADDR_WIDTH         = 9; // Allowed Values: 9
   parameter C_ARB_PIPELINE                = 1; // Allowed Values: 0,1
   parameter C_REQ_PENDING_CNTR_WIDTH      = 2; // Allowed Values: Such that counter 
                                                // does not overflow when max pending 
                                                // instruction are acknowledged
   parameter C_PORT_FOR_WRITE_TRAINING_PATTERN = 3'b001;
   parameter C_ARB0_ALGO                   = "ROUND_ROBIN";
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

   parameter C_ARB_BRAM_SRVAL_A  = 36'h0;
   parameter C_ARB_BRAM_SRVAL_B  = 36'h0;
   parameter C_ARB_BRAM_INIT_00  = 256'h0;
   parameter C_ARB_BRAM_INIT_01  = 256'h0;
   parameter C_ARB_BRAM_INIT_02  = 256'h0;
   parameter C_ARB_BRAM_INIT_03  = 256'h0;
   parameter C_ARB_BRAM_INIT_04  = 256'h0;
   parameter C_ARB_BRAM_INIT_05  = 256'h0;
   parameter C_ARB_BRAM_INIT_06  = 256'h0;
   parameter C_ARB_BRAM_INIT_07  = 256'h0;
   parameter C_ARB_BRAM_INIT_08  = 256'h0;
   parameter C_ARB_BRAM_INIT_09  = 256'h0;
   parameter C_ARB_BRAM_INIT_0A  = 256'h0;
   parameter C_ARB_BRAM_INIT_0B  = 256'h0;
   parameter C_ARB_BRAM_INIT_0C  = 256'h0;
   parameter C_ARB_BRAM_INIT_0D  = 256'h0;
   parameter C_ARB_BRAM_INIT_0E  = 256'h0;
   parameter C_ARB_BRAM_INIT_0F  = 256'h0;
   parameter C_ARB_BRAM_INIT_10  = 256'h0;
   parameter C_ARB_BRAM_INIT_11  = 256'h0;
   parameter C_ARB_BRAM_INIT_12  = 256'h0;
   parameter C_ARB_BRAM_INIT_13  = 256'h0;
   parameter C_ARB_BRAM_INIT_14  = 256'h0;
   parameter C_ARB_BRAM_INIT_15  = 256'h0;
   parameter C_ARB_BRAM_INIT_16  = 256'h0;
   parameter C_ARB_BRAM_INIT_17  = 256'h0;
   parameter C_ARB_BRAM_INIT_18  = 256'h0;
   parameter C_ARB_BRAM_INIT_19  = 256'h0;
   parameter C_ARB_BRAM_INIT_1A  = 256'h0;
   parameter C_ARB_BRAM_INIT_1B  = 256'h0;
   parameter C_ARB_BRAM_INIT_1C  = 256'h0;
   parameter C_ARB_BRAM_INIT_1D  = 256'h0;
   parameter C_ARB_BRAM_INIT_1E  = 256'h0;
   parameter C_ARB_BRAM_INIT_1F  = 256'h0;
   parameter C_ARB_BRAM_INIT_20  = 256'h0;
   parameter C_ARB_BRAM_INIT_21  = 256'h0;
   parameter C_ARB_BRAM_INIT_22  = 256'h0;
   parameter C_ARB_BRAM_INIT_23  = 256'h0;
   parameter C_ARB_BRAM_INIT_24  = 256'h0;
   parameter C_ARB_BRAM_INIT_25  = 256'h0;
   parameter C_ARB_BRAM_INIT_26  = 256'h0;
   parameter C_ARB_BRAM_INIT_27  = 256'h0;
   parameter C_ARB_BRAM_INIT_28  = 256'h0;
   parameter C_ARB_BRAM_INIT_29  = 256'h0;
   parameter C_ARB_BRAM_INIT_2A  = 256'h0;
   parameter C_ARB_BRAM_INIT_2B  = 256'h0;
   parameter C_ARB_BRAM_INIT_2C  = 256'h0;
   parameter C_ARB_BRAM_INIT_2D  = 256'h0;
   parameter C_ARB_BRAM_INIT_2E  = 256'h0;
   parameter C_ARB_BRAM_INIT_2F  = 256'h0;
   parameter C_ARB_BRAM_INIT_30  = 256'h0;
   parameter C_ARB_BRAM_INIT_31  = 256'h0;
   parameter C_ARB_BRAM_INIT_32  = 256'h0;
   parameter C_ARB_BRAM_INIT_33  = 256'h0;
   parameter C_ARB_BRAM_INIT_34  = 256'h0;
   parameter C_ARB_BRAM_INIT_35  = 256'h0;
   parameter C_ARB_BRAM_INIT_36  = 256'h0;
   parameter C_ARB_BRAM_INIT_37  = 256'h0;
   parameter C_ARB_BRAM_INIT_38  = 256'h0;
   parameter C_ARB_BRAM_INIT_39  = 256'h0;
   parameter C_ARB_BRAM_INIT_3A  = 256'h0;
   parameter C_ARB_BRAM_INIT_3B  = 256'h0;
   parameter C_ARB_BRAM_INIT_3C  = 256'h0;
   parameter C_ARB_BRAM_INIT_3D  = 256'h0;
   parameter C_ARB_BRAM_INIT_3E  = 256'h0;
   parameter C_ARB_BRAM_INIT_3F  = 256'h0;
   parameter C_ARB_BRAM_INITP_00 = 256'h0;
   parameter C_ARB_BRAM_INITP_01 = 256'h0;
   parameter C_ARB_BRAM_INITP_02 = 256'h0;
   parameter C_ARB_BRAM_INITP_03 = 256'h0;
   parameter C_ARB_BRAM_INITP_04 = 256'h0;
   parameter C_ARB_BRAM_INITP_05 = 256'h0;
   parameter C_ARB_BRAM_INITP_06 = 256'h0;
   parameter C_ARB_BRAM_INITP_07 = 256'h0;
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
   localparam C_ARB_PORTNUM_ZERO  = 3'b000;
   localparam C_ARB_PORTNUM_ONE   = 3'b001;
   localparam C_ARB_PORTNUM_TWO   = 3'b010;
   localparam C_ARB_PORTNUM_THREE = 3'b011;
   localparam C_ARB_PORTNUM_FOUR  = 3'b100;
   localparam C_ARB_PORTNUM_FIVE  = 3'b101;
   localparam C_ARB_PORTNUM_SIX   = 3'b110;
   localparam C_ARB_PORTNUM_SEVEN = 3'b111;
   localparam C_ARB_PORTNUM_INIT  = { C_ARB_PORTNUM_SEVEN[C_ARB_PORT_ENCODING_WIDTH-1:0], 
                                      C_ARB_PORTNUM_SIX  [C_ARB_PORT_ENCODING_WIDTH-1:0],
                                      C_ARB_PORTNUM_FIVE [C_ARB_PORT_ENCODING_WIDTH-1:0],
                                      C_ARB_PORTNUM_FOUR [C_ARB_PORT_ENCODING_WIDTH-1:0],
                                      C_ARB_PORTNUM_THREE[C_ARB_PORT_ENCODING_WIDTH-1:0],
                                      C_ARB_PORTNUM_TWO  [C_ARB_PORT_ENCODING_WIDTH-1:0],
                                      C_ARB_PORTNUM_ONE  [C_ARB_PORT_ENCODING_WIDTH-1:0],
                                      C_ARB_PORTNUM_ZERO [C_ARB_PORT_ENCODING_WIDTH-1:0]};

   input                                     Clk;
   input                                     Rst;
   input [C_NUM_PORTS-1:0]                   PI_AddrReq;
   input [C_NUM_PORTS*4-1:0]                 PI_Size;
   input [C_NUM_PORTS-1:0]                   PI_RNW;
   input [C_NUM_PORTS-1:0]                   PI_RdModWr;
   output [C_NUM_PORTS-1:0]                  PI_AddrAck;
   input [C_NUM_PORTS-1:0]                   PI_ArbPatternType_Pop;
   input                                     Ctrl_InitializeMemory;
   input                                     Ctrl_Maint;
   input                                     Ctrl_Maint_Enable;
   input                                     Ctrl_Complete;
   input                                     Ctrl_Idle;
   input                                     Ctrl_AlmostIdle;
   input                                     Ctrl_AP_Pipeline1_CE;
   input                                     PhyIF_Ctrl_InitDone;
   input [C_NUM_PORTS-1:0]                   DP_Ctrl_RdFIFO_AlmostFull;
   input [C_ARB_SEQUENCE_ENCODING_WIDTH-1:0] Arb_Sequence;
   input                                     Arb_LoadSequence;
   output                                    Arb_PatternStart_i;
   output                                    Arb_PatternStart;
   output [C_NUM_PORTS-1:0]                  Arb_WhichPort_Decode;
   output [C_ARB_PORT_ENCODING_WIDTH-1:0]    Arb_WhichPort;
   output [C_ARB_PATTERN_TYPE_WIDTH-1:0]     Arb_PatternType;
   output [C_ARB_PATTERN_TYPE_DECODE_WIDTH-1:0] Arb_PatternType_Decode;
   output                                       Arb_RdModWr;
   
   
   wire [C_ARB_PORT_ENCODING_WIDTH-1:0]             Arb_WhichPort_i;
   wire [C_NUM_PORTS-1:0]                           Arb_WhichPort_Decode_i;
   wire [C_NUM_PORTS-1:0]                           arb_reqpending;
   reg [C_NUM_PORTS*C_ARB_PORT_ENCODING_WIDTH-1:0]  arb_portnum = 0;
   wire [C_ARB_BRAM_ADDR_WIDTH-1:0]                 arb_brama_addr;
   wire [35:0]                                      arb_brama_dataout;
   wire                                             arb_brama_ce;
   reg  [C_NUM_PORTS-1:0]                           rnw_i;
    
   
   generate 
     if (C_ARB_PIPELINE == 1) begin : rnw_pipeline
       always @(posedge Clk) begin
         rnw_i <= PI_RNW;
       end
     end
     else begin : no_rnw_pipeline
       always @(*) begin
         rnw_i <= PI_RNW;
       end
     end
   endgenerate

   // Instantiate Address Acknowledge logic
   arb_acknowledge
     #(.C_NUM_PORTS                  (C_NUM_PORTS),
       .C_PIPELINE_ADDRACK           (C_PIPELINE_ADDRACK),
       .C_MAX_REQ_ALLOWED_INT        (C_MAX_REQ_ALLOWED_INT),
       .C_REQ_PENDING_CNTR_WIDTH     (C_REQ_PENDING_CNTR_WIDTH),
       .C_ARB_PIPELINE               (C_ARB_PIPELINE),
       .C_WORD_WRITE_SEQ             (C_WORD_WRITE_SEQ),
       .C_WORD_READ_SEQ              (C_WORD_READ_SEQ),
       .C_DOUBLEWORD_WRITE_SEQ       (C_DOUBLEWORD_WRITE_SEQ),
       .C_DOUBLEWORD_READ_SEQ        (C_DOUBLEWORD_READ_SEQ),
       .C_CL4_WRITE_SEQ              (C_CL4_WRITE_SEQ),
       .C_CL4_READ_SEQ               (C_CL4_READ_SEQ),
       .C_CL8_WRITE_SEQ              (C_CL8_WRITE_SEQ),
       .C_CL8_READ_SEQ               (C_CL8_READ_SEQ),
       .C_B16_WRITE_SEQ              (C_B16_WRITE_SEQ),
       .C_B16_READ_SEQ               (C_B16_READ_SEQ),
       .C_B32_WRITE_SEQ              (C_B32_WRITE_SEQ),
       .C_B32_READ_SEQ               (C_B32_READ_SEQ),
       .C_B64_WRITE_SEQ              (C_B64_WRITE_SEQ),
       .C_B64_READ_SEQ               (C_B64_READ_SEQ)
       )
       arb_acknowledge_0
         (
          .Clk                       (Clk),                       // I
          .Rst                       (Rst),                       // I
          .PI_AddrReq                (PI_AddrReq),                // I [C_NUM_PORTS-1:0]
          .PI_RNW                    (PI_RNW),                    // I [C_NUM_PORTS-1:0]
          .PI_AddrAck                (PI_AddrAck),                // O [C_NUM_PORTS-1:0]
          .PI_ReqPending             (arb_reqpending),            // O [C_NUM_PORTS-1:0]
          .DP_Ctrl_RdFIFO_AlmostFull (DP_Ctrl_RdFIFO_AlmostFull), // I [C_NUM_PORTS-1:0]
          .Ctrl_AP_Pipeline1_CE      (Ctrl_AP_Pipeline1_CE),      // I
          .Arb_WhichPort_Decode      (Arb_WhichPort_Decode_i),    // I [C_NUM_PORTS-1:0]
          .Ctrl_InitializeMemory     (Ctrl_InitializeMemory)      // I
   );
   

   // Instantiate Pattern Start Logic   
   arb_pattern_start
     #(.C_FAMILY                  (C_FAMILY),
       .C_NUM_PORTS               (C_NUM_PORTS),
       .C_ARB_PIPELINE            (C_ARB_PIPELINE),
       .C_CP_PIPELINE             (C_CP_PIPELINE),
       .C_ARB_PORT_ENCODING_WIDTH (C_ARB_PORT_ENCODING_WIDTH),
       .C_ARB0_ALGO               (C_ARB0_ALGO)
       )
       arb_pattern_start_0
         (
          .Clk              (Clk),                    // I
          .Rst              (Rst),                    // I
          .PI_ReqPending    (arb_reqpending & ~(rnw_i & DP_Ctrl_RdFIFO_AlmostFull)),         // I [C_NUM_PORTS-1:0]
          .Ctrl_Idle        (Ctrl_Idle),              // I
          .Ctrl_Maint     (Ctrl_Maint),           // I
          .Ctrl_Complete    (Ctrl_Complete),          // I
          .Arb_PortNum      (arb_portnum),            // I [C_NUM_PORTS*C_ARB_PORT_ENCODING_WIDTH-1:0]
          .Arb_PatternStart_i (Arb_PatternStart_i),   // O 
          .Arb_PatternStart (Arb_PatternStart)        // O 
          );

   // Instantiate Logic to determine which port corresponds to the 
   // pattern start logic
   arb_which_port
     #(.C_FAMILY                  (C_FAMILY),
       .C_USE_INIT_PUSH           (C_USE_INIT_PUSH),
       .C_NUM_PORTS               (C_NUM_PORTS),
       .C_ARB_PIPELINE            (C_ARB_PIPELINE),
       .C_CP_PIPELINE             (C_CP_PIPELINE),
       .C_ARB_PORT_ENCODING_WIDTH (C_ARB_PORT_ENCODING_WIDTH),
       .C_PORT_FOR_WRITE_TRAINING_PATTERN(C_PORT_FOR_WRITE_TRAINING_PATTERN),
       .C_ARB0_ALGO               (C_ARB0_ALGO)
       )
       arb_which_port_0
         (
          .Clk                  (Clk),                    // I
          .Rst                  (Rst),                    // I
          .PhyIF_Ctrl_InitDone  (PhyIF_Ctrl_InitDone),    // I
          .PI_ReqPending        (arb_reqpending & ~(rnw_i & DP_Ctrl_RdFIFO_AlmostFull)),         // I [C_NUM_PORTS-1:0]
          .Ctrl_Idle            (Ctrl_Idle),             // I
          .Ctrl_Complete        (Ctrl_Complete),          // I
          .Arb_PortNum          (arb_portnum),            // I [C_NUM_PORTS*C_ARB_PORT_ENCODING_WIDTH-1:0]
          .Arb_WhichPort_i      (Arb_WhichPort_i),        // O [C_ARB_PORT_ENCODING_WIDTH-1:0]
          .Arb_WhichPort_Decode_i (Arb_WhichPort_Decode_i), // O [C_NUM_PORTS-1:0]
          .Arb_WhichPort        (Arb_WhichPort),          // O [C_ARB_PORT_ENCODING_WIDTH-1:0]
          .Arb_WhichPort_Decode (Arb_WhichPort_Decode)    // O [C_NUM_PORTS-1:0]
          );

   // Instantiate Logic to determine the pattern type that corresponds 
   // to the pattern start logic
   arb_pattern_type
     #(.C_FAMILY                  (C_FAMILY),
       .C_INCLUDE_ECC_SUPPORT     (C_INCLUDE_ECC_SUPPORT),
       .C_NUM_PORTS               (C_NUM_PORTS),
       .C_PI_DATA_WIDTH           (C_PI_DATA_WIDTH),
       .C_CP_PIPELINE             (C_CP_PIPELINE),
       .C_ARB_PORT_ENCODING_WIDTH (C_ARB_PORT_ENCODING_WIDTH),
       .C_ARB_PATTERN_TYPE_WIDTH  (C_ARB_PATTERN_TYPE_WIDTH),
       .C_ARB_PATTERN_TYPE_DECODE_WIDTH (C_ARB_PATTERN_TYPE_DECODE_WIDTH),
       .C_MAX_REQ_ALLOWED_INT     (C_MAX_REQ_ALLOWED_INT),
       .C_WORD_WRITE_SEQ          (C_WORD_WRITE_SEQ),
       .C_WORD_READ_SEQ           (C_WORD_READ_SEQ),
       .C_DOUBLEWORD_WRITE_SEQ    (C_DOUBLEWORD_WRITE_SEQ),
       .C_DOUBLEWORD_READ_SEQ     (C_DOUBLEWORD_READ_SEQ),
       .C_CL4_WRITE_SEQ           (C_CL4_WRITE_SEQ),
       .C_CL4_READ_SEQ            (C_CL4_READ_SEQ),
       .C_CL8_WRITE_SEQ           (C_CL8_WRITE_SEQ),
       .C_CL8_READ_SEQ            (C_CL8_READ_SEQ),
       .C_B16_WRITE_SEQ           (C_B16_WRITE_SEQ),
       .C_B16_READ_SEQ            (C_B16_READ_SEQ),
       .C_B32_WRITE_SEQ           (C_B32_WRITE_SEQ),
       .C_B32_READ_SEQ            (C_B32_READ_SEQ),
       .C_B64_WRITE_SEQ           (C_B64_WRITE_SEQ),
       .C_B64_READ_SEQ            (C_B64_READ_SEQ),
       .C_REFH_SEQ                (C_REFH_SEQ),
       .C_NOP_SEQ                 (C_NOP_SEQ)
       )
       arb_pattern_type_0
         (
          .Clk                   (Clk),                    // I
          .Rst                   (Rst),                    // I
          .PI_Size               (PI_Size),                // I [C_NUM_PORTS*4-1:0]
          .PI_RNW                (PI_RNW),                 // I [C_NUM_PORTS-1:0]
          .PI_RdModWr            (PI_RdModWr),             // I [C_NUM_PORTS-1:0]
          .PI_AddrAck            (PI_AddrAck),             // I [C_NUM_PORTS-1:0]
          .PI_ArbPatternType_Pop (PI_ArbPatternType_Pop),  // I [C_NUM_PORTS-1:0]
          .Ctrl_Idle             (Ctrl_Idle),              // I
          .Ctrl_AlmostIdle       (Ctrl_AlmostIdle),        // I
          .Ctrl_Complete         (Ctrl_Complete),          // I
          .Ctrl_InitializeMemory (Ctrl_InitializeMemory),  // I
          .Ctrl_Maint          (Ctrl_Maint),           // I
          .Ctrl_Maint_Enable   (Ctrl_Maint_Enable),    // I
          .PhyIF_Ctrl_InitDone   (PhyIF_Ctrl_InitDone),    // I
          .Arb_WhichPort         (Arb_WhichPort_i),        // I [C_ARB_PORT_ENCODING_WIDTH-1:0]
          .Arb_PatternStart      (Arb_PatternStart),       // I
          .Arb_PatternStart_i    (Arb_PatternStart_i),     // I
          .Arb_PatternType_Decode (Arb_PatternType_Decode), // O [C_ARB_PATTERN_TYPE_DECODE_WIDTH-1:0]
          .Arb_PatternType       (Arb_PatternType),        // O [C_ARB_PATTERN_TYPE_WIDTH-1:0]
          .Arb_RdModWr           (Arb_RdModWr)             // O
   );
   
   // Instantiate the Arbiter BRAM clock enable.
   assign arb_brama_ce = Ctrl_Idle | Ctrl_Complete;
   
  
   generate
      if (C_NUM_PORTS == 1) begin : inst_single_port_arb_algo
         always @(posedge Clk)
            arb_portnum <= {C_ARB_PORT_ENCODING_WIDTH{1'b0}};
      end
      else if (C_ARB0_ALGO == "FIXED") begin : inst_fixed_arb_algo
         always @(posedge Clk)
            arb_portnum <= C_ARB_PORTNUM_INIT[C_NUM_PORTS*C_ARB_PORT_ENCODING_WIDTH-1:0];
      end
      else if (C_ARB0_ALGO == "ROUND_ROBIN") begin : inst_round_robin_arb_algo
         always @(posedge Clk) 
            if (Rst) 
               arb_portnum <= C_ARB_PORTNUM_INIT[C_NUM_PORTS*C_ARB_PORT_ENCODING_WIDTH-1:0];
            else if (arb_brama_ce) 
               arb_portnum <= { arb_portnum[C_ARB_PORT_ENCODING_WIDTH-1:0], arb_portnum[C_NUM_PORTS*C_ARB_PORT_ENCODING_WIDTH-1:C_ARB_PORT_ENCODING_WIDTH]};
      end
      else if (C_ARB0_ALGO == "CUSTOM") begin : inst_custom_arb_bram_algo
         wire [8*C_ARB_PORT_ENCODING_WIDTH-1:0] arb_brama_dataout_compressed;
         // Instantiate Arbiter BRAM Address logic
         arb_bram_addr
           #(.C_ARB_SEQUENCE_ENCODING_WIDTH (C_ARB_SEQUENCE_ENCODING_WIDTH),
             .C_ARB_BRAM_ADDR_WIDTH        (C_ARB_BRAM_ADDR_WIDTH),
             .C_BASEADDR_ARB0              (C_BASEADDR_ARB0),
             .C_HIGHADDR_ARB0              (C_HIGHADDR_ARB0),
             .C_BASEADDR_ARB1              (C_BASEADDR_ARB1),
             .C_HIGHADDR_ARB1              (C_HIGHADDR_ARB1),
             .C_BASEADDR_ARB2              (C_BASEADDR_ARB2),
             .C_HIGHADDR_ARB2              (C_HIGHADDR_ARB2),
             .C_BASEADDR_ARB3              (C_BASEADDR_ARB3),
             .C_HIGHADDR_ARB3              (C_HIGHADDR_ARB3),
             .C_BASEADDR_ARB4              (C_BASEADDR_ARB4),
             .C_HIGHADDR_ARB4              (C_HIGHADDR_ARB4),
             .C_BASEADDR_ARB5              (C_BASEADDR_ARB5),
             .C_HIGHADDR_ARB5              (C_HIGHADDR_ARB5),
             .C_BASEADDR_ARB6              (C_BASEADDR_ARB6),
             .C_HIGHADDR_ARB6              (C_HIGHADDR_ARB6),
             .C_BASEADDR_ARB7              (C_BASEADDR_ARB7),
             .C_HIGHADDR_ARB7              (C_HIGHADDR_ARB7),
             .C_BASEADDR_ARB8              (C_BASEADDR_ARB8),
             .C_HIGHADDR_ARB8              (C_HIGHADDR_ARB8),
             .C_BASEADDR_ARB9              (C_BASEADDR_ARB9),
             .C_HIGHADDR_ARB9              (C_HIGHADDR_ARB9),
             .C_BASEADDR_ARB10             (C_BASEADDR_ARB10),
             .C_HIGHADDR_ARB10             (C_HIGHADDR_ARB10),
             .C_BASEADDR_ARB11             (C_BASEADDR_ARB11),
             .C_HIGHADDR_ARB11             (C_HIGHADDR_ARB11),
             .C_BASEADDR_ARB12             (C_BASEADDR_ARB12),
             .C_HIGHADDR_ARB12             (C_HIGHADDR_ARB12),
             .C_BASEADDR_ARB13             (C_BASEADDR_ARB13),
             .C_HIGHADDR_ARB13             (C_HIGHADDR_ARB13),
             .C_BASEADDR_ARB14             (C_BASEADDR_ARB14),
             .C_HIGHADDR_ARB14             (C_HIGHADDR_ARB14),
             .C_BASEADDR_ARB15             (C_BASEADDR_ARB15),
             .C_HIGHADDR_ARB15             (C_HIGHADDR_ARB15)
             )
             arb_bram_addr_0
               (
                .Clk              (Clk),              // I
                .Rst              (Rst),              // I
                .Arb_Sequence     (Arb_Sequence),     // I [C_ARB_SEQUENCE_ENCODING_WIDTH-1:0]
                .Arb_LoadSequence (Arb_LoadSequence), // I
                .Ctrl_Complete    (Ctrl_Complete),    // I
                .Ctrl_Idle        (Ctrl_Idle),        // I
                .Arb_BRAMAddr     (arb_brama_addr)    // O [C_ARB_BRAM_ADDR_WIDTH-1:0]
                );

         // Instantiate the Arbiter BRAM
         RAMB16_S36_S36
           #(
             .SRVAL_A  (C_ARB_BRAM_SRVAL_A),
             .SRVAL_B  (C_ARB_BRAM_SRVAL_B),
             .INIT_00  (C_ARB_BRAM_INIT_00),
             .INIT_01  (C_ARB_BRAM_INIT_01),
             .INIT_02  (C_ARB_BRAM_INIT_02),
             .INIT_03  (C_ARB_BRAM_INIT_03),
             .INIT_04  (C_ARB_BRAM_INIT_04),
             .INIT_05  (C_ARB_BRAM_INIT_05),
             .INIT_06  (C_ARB_BRAM_INIT_06),
             .INIT_07  (C_ARB_BRAM_INIT_07),
             .INIT_08  (C_ARB_BRAM_INIT_08),
             .INIT_09  (C_ARB_BRAM_INIT_09),
             .INIT_0A  (C_ARB_BRAM_INIT_0A),
             .INIT_0B  (C_ARB_BRAM_INIT_0B),
             .INIT_0C  (C_ARB_BRAM_INIT_0C),
             .INIT_0D  (C_ARB_BRAM_INIT_0D),
             .INIT_0E  (C_ARB_BRAM_INIT_0E),
             .INIT_0F  (C_ARB_BRAM_INIT_0F),
             .INIT_10  (C_ARB_BRAM_INIT_10),
             .INIT_11  (C_ARB_BRAM_INIT_11),
             .INIT_12  (C_ARB_BRAM_INIT_12),
             .INIT_13  (C_ARB_BRAM_INIT_13),
             .INIT_14  (C_ARB_BRAM_INIT_14),
             .INIT_15  (C_ARB_BRAM_INIT_15),
             .INIT_16  (C_ARB_BRAM_INIT_16),
             .INIT_17  (C_ARB_BRAM_INIT_17),
             .INIT_18  (C_ARB_BRAM_INIT_18),
             .INIT_19  (C_ARB_BRAM_INIT_19),
             .INIT_1A  (C_ARB_BRAM_INIT_1A),
             .INIT_1B  (C_ARB_BRAM_INIT_1B),
             .INIT_1C  (C_ARB_BRAM_INIT_1C),
             .INIT_1D  (C_ARB_BRAM_INIT_1D),
             .INIT_1E  (C_ARB_BRAM_INIT_1E),
             .INIT_1F  (C_ARB_BRAM_INIT_1F),
             .INIT_20  (C_ARB_BRAM_INIT_20),
             .INIT_21  (C_ARB_BRAM_INIT_21),
             .INIT_22  (C_ARB_BRAM_INIT_22),
             .INIT_23  (C_ARB_BRAM_INIT_23),
             .INIT_24  (C_ARB_BRAM_INIT_24),
             .INIT_25  (C_ARB_BRAM_INIT_25),
             .INIT_26  (C_ARB_BRAM_INIT_26),
             .INIT_27  (C_ARB_BRAM_INIT_27),
             .INIT_28  (C_ARB_BRAM_INIT_28),
             .INIT_29  (C_ARB_BRAM_INIT_29),
             .INIT_2A  (C_ARB_BRAM_INIT_2A),
             .INIT_2B  (C_ARB_BRAM_INIT_2B),
             .INIT_2C  (C_ARB_BRAM_INIT_2C),
             .INIT_2D  (C_ARB_BRAM_INIT_2D),
             .INIT_2E  (C_ARB_BRAM_INIT_2E),
             .INIT_2F  (C_ARB_BRAM_INIT_2F),
             .INIT_30  (C_ARB_BRAM_INIT_30),
             .INIT_31  (C_ARB_BRAM_INIT_31),
             .INIT_32  (C_ARB_BRAM_INIT_32),
             .INIT_33  (C_ARB_BRAM_INIT_33),
             .INIT_34  (C_ARB_BRAM_INIT_34),
             .INIT_35  (C_ARB_BRAM_INIT_35),
             .INIT_36  (C_ARB_BRAM_INIT_36),
             .INIT_37  (C_ARB_BRAM_INIT_37),
             .INIT_38  (C_ARB_BRAM_INIT_38),
             .INIT_39  (C_ARB_BRAM_INIT_39),
             .INIT_3A  (C_ARB_BRAM_INIT_3A),
             .INIT_3B  (C_ARB_BRAM_INIT_3B),
             .INIT_3C  (C_ARB_BRAM_INIT_3C),
             .INIT_3D  (C_ARB_BRAM_INIT_3D),
             .INIT_3E  (C_ARB_BRAM_INIT_3E),
             .INIT_3F  (C_ARB_BRAM_INIT_3F),
             .INITP_00 (C_ARB_BRAM_INITP_00),
             .INITP_01 (C_ARB_BRAM_INITP_01),
             .INITP_02 (C_ARB_BRAM_INITP_02),
             .INITP_03 (C_ARB_BRAM_INITP_03),
             .INITP_04 (C_ARB_BRAM_INITP_04),
             .INITP_05 (C_ARB_BRAM_INITP_05),
             .INITP_06 (C_ARB_BRAM_INITP_06),
             .INITP_07 (C_ARB_BRAM_INITP_07)
             )
             RAMB16_S36_S36_0
               (
                .CLKA        (Clk),                      // I
                .ADDRA       (arb_brama_addr),           // I
                .WEA         (1'b0),                     // I
                .ENA         (arb_brama_ce),             // I
                .SSRA        (1'b0),                     // I
                .DIA         (32'h0),                    // I
                .DIPA        (4'h0),                     // I
                .DOA         (arb_brama_dataout[31:0]),  // O
                .DOPA        (arb_brama_dataout[35:32]), // O
                .CLKB        (Clk),                      // I
                .ADDRB       (9'h0),                     // I
                .WEB         (1'b0),                     // I
                .ENB         (1'b1),                     // I
                .SSRB        (1'b0),                     // I
                .DIB         (32'h0),                    // I
                .DIPB        (4'h0),                     // I
                .DOB         (),                         // O
                .DOPB        ()                          // O
                );

        // Bram output is always encoded as 3 bits wide, here we compress it
        // down if the arb port encoding with is less than 3
          assign arb_brama_dataout_compressed = { arb_brama_dataout[3*7 +: C_ARB_PORT_ENCODING_WIDTH],
                                                  arb_brama_dataout[3*6 +: C_ARB_PORT_ENCODING_WIDTH],
                                                  arb_brama_dataout[3*5 +: C_ARB_PORT_ENCODING_WIDTH],
                                                  arb_brama_dataout[3*4 +: C_ARB_PORT_ENCODING_WIDTH],
                                                  arb_brama_dataout[3*3 +: C_ARB_PORT_ENCODING_WIDTH],
                                                  arb_brama_dataout[3*2 +: C_ARB_PORT_ENCODING_WIDTH],
                                                  arb_brama_dataout[3*1 +: C_ARB_PORT_ENCODING_WIDTH],
                                                  arb_brama_dataout[3*0 +: C_ARB_PORT_ENCODING_WIDTH] };

          always @(posedge Clk)
            begin
               if (arb_brama_ce)
                 arb_portnum <= arb_brama_dataout_compressed[C_NUM_PORTS*C_ARB_PORT_ENCODING_WIDTH-1:0];
               else
                 arb_portnum <= arb_portnum;
            end
      end

   endgenerate
   
endmodule // arbiter

