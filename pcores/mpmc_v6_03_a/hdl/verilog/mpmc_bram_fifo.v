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
// MPMC Data Path
//-------------------------------------------------------------------------

// Description:    
//   Data Path for MPMC
//
// Structure:
//   mpmc_data_path
//     mpmc_write_fifo
//       mpmc_bram_fifo
//         mpmc_ramb16_sx_sx
//       mpmc_srl_fifo
//     mpmc_read_fifo
//       mpmc_bram_fifo
//         mpmc_ramb16_sx_sx
//       mpmc_srl_fifo
//     
//--------------------------------------------------------------------------
//
// History:
//   06/15/2007 Initial Version
//
//--------------------------------------------------------------------------
`timescale 1ns/1ns

module mpmc_bram_fifo #
  (
   parameter         C_FAMILY            = "virtex4",
   parameter         C_USE_INIT_PUSH     = 1'b1,
   parameter         C_INPUT_PIPELINE    = 1'b1,
   parameter         C_OUTPUT_PIPELINE   = 1'b1,
   parameter integer C_ADDR_WIDTH        =   15,
   parameter integer C_INPUT_DATA_WIDTH  =  128,
   parameter integer C_OUTPUT_DATA_WIDTH =   64,
   parameter         C_DIRECTION         = "write"
   )
  (
   // Write Side
   input  wire                             PushClk,
   input  wire [C_ADDR_WIDTH-1:0]          PushAddr,
   input  wire                             Push,
   input  wire [C_INPUT_DATA_WIDTH-1:0]    PushData,
   input  wire [C_INPUT_DATA_WIDTH/8-1:0]  PushParity,
   // Write Training Pattern Signals
   // Assumes that InitPush and related Pop do not happen on the same cycle.
   // Assumes that InitPush and Push do not happen on the same cycle.
   input                                   InitPush,
   input [C_OUTPUT_DATA_WIDTH-1:0]         InitData,
   // Read Side
   input  wire                             PopClk,
   input  wire [C_ADDR_WIDTH-1:0]          PopAddr,
   input  wire                             Pop,
   input                                   ParityRst,
   output reg  [C_OUTPUT_DATA_WIDTH-1:0]   PopData,
   output reg  [C_OUTPUT_DATA_WIDTH/8-1:0] PopParity
   );
   
   localparam P_INPUT_PARITY_WIDTH  = C_INPUT_DATA_WIDTH/8;
   localparam P_OUTPUT_PARITY_WIDTH = C_OUTPUT_DATA_WIDTH/8;
   localparam P_BRAM_TYPE_NOT_SUPPORTED = 
           ((C_INPUT_DATA_WIDTH ==   8) && (C_OUTPUT_DATA_WIDTH ==   8)) ? 1 :
           ((C_INPUT_DATA_WIDTH ==   8) && (C_OUTPUT_DATA_WIDTH ==  16)) ? 1 :
           ((C_INPUT_DATA_WIDTH ==   8) && (C_OUTPUT_DATA_WIDTH == 128)) ? 1 :
           ((C_INPUT_DATA_WIDTH ==  16) && (C_OUTPUT_DATA_WIDTH ==   8)) ? 1 :
           ((C_INPUT_DATA_WIDTH ==  16) && (C_OUTPUT_DATA_WIDTH ==  16)) ? 1 :
           ((C_INPUT_DATA_WIDTH ==  16) && (C_OUTPUT_DATA_WIDTH == 128)) ? 1 :
           ((C_INPUT_DATA_WIDTH == 128) && (C_OUTPUT_DATA_WIDTH ==   8)) ? 1 :
           ((C_INPUT_DATA_WIDTH == 128) && (C_OUTPUT_DATA_WIDTH ==  16)) ? 1 :
           ((C_INPUT_DATA_WIDTH == 128) && (C_OUTPUT_DATA_WIDTH == 128)) ? 1 :
                                                                           0;
   // Note that special case is for read or write only.  If supporting PIM
   // widths other than 32 or 64, will need to revisit these special cases.
   localparam P_BRAM_TYPE_SPECIAL_CASE = 
           ((C_INPUT_DATA_WIDTH ==   8) && (C_OUTPUT_DATA_WIDTH ==  64)) ? 1 :
           ((C_INPUT_DATA_WIDTH ==   8) && (C_OUTPUT_DATA_WIDTH == 128)) ? 1 :
           ((C_INPUT_DATA_WIDTH ==  16) && (C_OUTPUT_DATA_WIDTH == 128)) ? 1 :
           ((C_INPUT_DATA_WIDTH ==  64) && (C_OUTPUT_DATA_WIDTH ==   8)) ? 1 :
           ((C_INPUT_DATA_WIDTH == 128) && (C_OUTPUT_DATA_WIDTH ==   8)) ? 1 :
           ((C_INPUT_DATA_WIDTH == 128) && (C_OUTPUT_DATA_WIDTH ==  16)) ? 1 :
                                                                           0;
   localparam P_NUM_BRAMS =
           ((C_INPUT_DATA_WIDTH ==   8) && (C_OUTPUT_DATA_WIDTH ==   8)) ? 1 :
           ((C_INPUT_DATA_WIDTH ==   8) && (C_OUTPUT_DATA_WIDTH ==  16)) ? 1 :
           ((C_INPUT_DATA_WIDTH ==   8) && (C_OUTPUT_DATA_WIDTH ==  32)) ? 1 :
           ((C_INPUT_DATA_WIDTH ==   8) && (C_OUTPUT_DATA_WIDTH ==  64)) ? 2 :
           ((C_INPUT_DATA_WIDTH ==   8) && (C_OUTPUT_DATA_WIDTH == 128)) ? 4 :
           ((C_INPUT_DATA_WIDTH ==  16) && (C_OUTPUT_DATA_WIDTH ==   8)) ? 1 :
           ((C_INPUT_DATA_WIDTH ==  16) && (C_OUTPUT_DATA_WIDTH ==  16)) ? 1 :
           ((C_INPUT_DATA_WIDTH ==  16) && (C_OUTPUT_DATA_WIDTH ==  32)) ? 1 :
           ((C_INPUT_DATA_WIDTH ==  16) && (C_OUTPUT_DATA_WIDTH ==  64)) ? 2 :
           ((C_INPUT_DATA_WIDTH ==  16) && (C_OUTPUT_DATA_WIDTH == 128)) ? 4 :
           ((C_INPUT_DATA_WIDTH ==  32) && (C_OUTPUT_DATA_WIDTH ==   8)) ? 1 :
           ((C_INPUT_DATA_WIDTH ==  32) && (C_OUTPUT_DATA_WIDTH ==  16)) ? 1 :
           ((C_INPUT_DATA_WIDTH ==  32) && (C_OUTPUT_DATA_WIDTH ==  32)) ? 1 :
           ((C_INPUT_DATA_WIDTH ==  32) && (C_OUTPUT_DATA_WIDTH ==  64)) ? 2 :
           ((C_INPUT_DATA_WIDTH ==  32) && (C_OUTPUT_DATA_WIDTH == 128)) ? 4 :
           ((C_INPUT_DATA_WIDTH ==  64) && (C_OUTPUT_DATA_WIDTH ==   8)) ? 3 :
           ((C_INPUT_DATA_WIDTH ==  64) && (C_OUTPUT_DATA_WIDTH ==  16)) ? 2 :
           ((C_INPUT_DATA_WIDTH ==  64) && (C_OUTPUT_DATA_WIDTH ==  32)) ? 2 :
           ((C_INPUT_DATA_WIDTH ==  64) && (C_OUTPUT_DATA_WIDTH ==  64)) ? 2 :
           ((C_INPUT_DATA_WIDTH ==  64) && (C_OUTPUT_DATA_WIDTH == 128)) ? 4 :
           ((C_INPUT_DATA_WIDTH == 128) && (C_OUTPUT_DATA_WIDTH ==   8)) ? 5 :
           ((C_INPUT_DATA_WIDTH == 128) && (C_OUTPUT_DATA_WIDTH ==  16)) ? 5 :
           ((C_INPUT_DATA_WIDTH == 128) && (C_OUTPUT_DATA_WIDTH ==  32)) ? 4 :
           ((C_INPUT_DATA_WIDTH == 128) && (C_OUTPUT_DATA_WIDTH ==  64)) ? 4 :
           ((C_INPUT_DATA_WIDTH == 128) && (C_OUTPUT_DATA_WIDTH == 128)) ? 4 :
                                                                           0;
   
   reg [C_ADDR_WIDTH-1:0]           PushAddr_r;
   reg                              Push_r;
   reg [C_INPUT_DATA_WIDTH-1:0]     PushData_r;
   reg [C_INPUT_DATA_WIDTH/8-1:0]   PushParity_r;
   reg                              InitPush_r;
   reg [C_OUTPUT_DATA_WIDTH-1:0]    InitData_r;
   wire [C_OUTPUT_DATA_WIDTH-1:0]   PopData_r /* synthesis syn_keep=1 */;
   wire [C_OUTPUT_DATA_WIDTH/8-1:0] PopParity_r /* synthesis syn_keep=1 */;

   wire [10:0]                      PushAddr_tmp;
   wire [10:0]                      PopAddr_tmp;
   
   wire [C_INPUT_DATA_WIDTH-1:0]    PushData_reorder;
   wire [C_INPUT_DATA_WIDTH/8-1:0]  PushParity_reorder;
   wire [C_OUTPUT_DATA_WIDTH-1:0]   InitData_reorder;
   wire [C_OUTPUT_DATA_WIDTH-1:0]   PopData_reorder;
   wire [C_OUTPUT_DATA_WIDTH/8-1:0] PopParity_reorder;
   
   genvar i;
   
   // synthesis translate_off
   initial begin
      if (P_BRAM_TYPE_NOT_SUPPORTED == 1) begin
         $display ("ERROR: Selected BRAM Type Not Supported!");
         $finish;
      end
   end
   // synthesis translate_on

   generate
      if (C_INPUT_PIPELINE == 1) begin : gen_input_pipeline
         always @(posedge PushClk) begin
            PushAddr_r   <= PushAddr;
            Push_r       <= Push;
            PushData_r   <= PushData;
            PushParity_r <= PushParity;
         end
         if (C_USE_INIT_PUSH) begin : gen_initpush
           always @(posedge PushClk) begin
             InitPush_r   <= InitPush;
             InitData_r   <= InitData;
           end
         end
      end
      else begin : gen_no_input_pipeline
         always @(*) begin
            PushAddr_r   <= PushAddr;
            Push_r       <= Push;
            PushData_r   <= PushData;
            PushParity_r <= PushParity;
         end
         if (C_USE_INIT_PUSH) begin : gen_initpush
           always @(*) begin
             InitPush_r   <= InitPush;
             InitData_r   <= InitData;
           end
         end
      end
   endgenerate

   generate
      if (C_OUTPUT_PIPELINE == 1) begin : gen_output_pipeline
        if (C_DIRECTION == "read") begin : gen_read
          always @(posedge PopClk) begin
            PopData   <= PopData_r;
            PopParity <= PopParity_r;
          end
        end
        else begin : gen_write
          reg Pop_d1;
          always @(posedge PopClk) begin
            Pop_d1 <= Pop;
            if (~Pop_d1) begin
              PopData   <= {C_OUTPUT_DATA_WIDTH{1'b0}};
              PopParity <= {C_OUTPUT_DATA_WIDTH/8{1'b0}};
            end
            else begin
              PopData   <= PopData_r;
              PopParity <= PopParity_r;
            end
          end
        end
      end
      else begin : gen_no_output_pipeline
         always @(*) begin
            PopData   <= PopData_r;
            PopParity <= PopParity_r;
         end
      end
   endgenerate
   
   generate
      if (P_BRAM_TYPE_NOT_SUPPORTED == 1) begin : gen_addr_not_supported
      end
      else if (P_BRAM_TYPE_SPECIAL_CASE == 1) begin : gen_addr_special_case
         if      ((C_INPUT_DATA_WIDTH ==   8) && (C_OUTPUT_DATA_WIDTH ==  64))
           begin : gen_addr_8_64
              assign PushAddr_tmp = PushAddr_r[C_ADDR_WIDTH-1:0];
              assign PopAddr_tmp  = {ParityRst,PopAddr[C_ADDR_WIDTH-1:1]};
           end
         else if ((C_INPUT_DATA_WIDTH ==   8) && (C_OUTPUT_DATA_WIDTH == 128))
           begin : gen_addr_8_128
              assign PushAddr_tmp = PushAddr_r[C_ADDR_WIDTH-1:0];
              assign PopAddr_tmp  = {ParityRst,PopAddr[C_ADDR_WIDTH-1:2]};
           end
         else if ((C_INPUT_DATA_WIDTH ==  16) && (C_OUTPUT_DATA_WIDTH == 128))
           begin : gen_addr_16_128
              assign PushAddr_tmp = PushAddr_r[C_ADDR_WIDTH-1:2];
              assign PopAddr_tmp  = {ParityRst,PopAddr[C_ADDR_WIDTH-1:2]};
           end
         else if ((C_INPUT_DATA_WIDTH ==  64) && (C_OUTPUT_DATA_WIDTH ==   8))
           begin : gen_addr_64_8
              assign PushAddr_tmp = PushAddr_r[C_ADDR_WIDTH-1:1];
              assign PopAddr_tmp  = {ParityRst,PopAddr[C_ADDR_WIDTH-1:0]};
           end
         else if ((C_INPUT_DATA_WIDTH == 128) && (C_OUTPUT_DATA_WIDTH ==   8))
           begin : gen_addr_128_8
              assign PushAddr_tmp = PushAddr_r[C_ADDR_WIDTH-1:2];
              assign PopAddr_tmp  = {ParityRst,PopAddr[C_ADDR_WIDTH-1:1]};
           end
         else if ((C_INPUT_DATA_WIDTH == 128) && (C_OUTPUT_DATA_WIDTH ==   16))
           begin : gen_addr_128_16
              assign PushAddr_tmp = PushAddr_r[C_ADDR_WIDTH-1:2];
              assign PopAddr_tmp  = {ParityRst,PopAddr[C_ADDR_WIDTH-1:2]};
           end
         else
           begin : gen_addr_not_supported
           end
      end
      else if (P_NUM_BRAMS == 1) begin : gen_addr_1bram
         assign PushAddr_tmp = PushAddr_r[C_ADDR_WIDTH-1:0];
         if (((C_FAMILY == "virtex6" || C_FAMILY == "virtex5")) && 
             (C_INPUT_DATA_WIDTH == C_OUTPUT_DATA_WIDTH)) begin : gen_v5
            assign PopAddr_tmp  = PopAddr[C_ADDR_WIDTH-1:0];
         end
         else begin : gen_normal
            assign PopAddr_tmp  = {ParityRst,PopAddr[C_ADDR_WIDTH-1:0]};
         end
      end
      else if (P_NUM_BRAMS == 2) begin : gen_addr_2bram
         assign PushAddr_tmp = PushAddr_r[C_ADDR_WIDTH-1:1];
         if (((C_FAMILY == "virtex6" || C_FAMILY == "virtex5")) && 
             (C_INPUT_DATA_WIDTH == C_OUTPUT_DATA_WIDTH)) begin : gen_v5
            assign PopAddr_tmp  = PopAddr[C_ADDR_WIDTH-1:1];
         end
         else begin : gen_normal
            assign PopAddr_tmp  = {ParityRst,PopAddr[C_ADDR_WIDTH-1:1]};
         end
      end
      else if (P_NUM_BRAMS == 4) begin : gen_addr_4bram
         assign PushAddr_tmp = PushAddr_r[C_ADDR_WIDTH-1:2];
         if (((C_FAMILY == "virtex6" || C_FAMILY == "virtex5")) && 
             (C_INPUT_DATA_WIDTH == C_OUTPUT_DATA_WIDTH)) begin : gen_v5
            assign PopAddr_tmp  = PopAddr[C_ADDR_WIDTH-1:2];
         end
         else begin : gen_normal
            assign PopAddr_tmp  = {ParityRst,PopAddr[C_ADDR_WIDTH-1:2]};
         end
      end
   endgenerate
     
   generate
      if (P_BRAM_TYPE_NOT_SUPPORTED == 1) 
        begin : gen_reorder_not_supported
        end
      else if (P_BRAM_TYPE_SPECIAL_CASE == 1) 
        begin : gen_reorder_special_case
          // This special case will only work for reads.
          if      ((C_INPUT_DATA_WIDTH == 8) && (C_OUTPUT_DATA_WIDTH == 64))
            begin : gen_reorder_8_64
              assign PushData_reorder        = PushData_r;
              assign PushParity_reorder      = PushParity_r;
              if (C_USE_INIT_PUSH) begin : gen_initpush
                assign InitData_reorder [3:0]  = InitData_r [3:0];
                assign InitData_reorder [7:4]  = InitData_r[11:8];
                assign InitData_reorder[11:8]  = InitData_r[19:16];
                assign InitData_reorder[15:12] = InitData_r[27:24];
                assign InitData_reorder[19:16] = InitData_r[35:32];
                assign InitData_reorder[23:20] = InitData_r[43:40];
                assign InitData_reorder[27:24] = InitData_r[51:48];
                assign InitData_reorder[31:28] = InitData_r[59:56];
                assign InitData_reorder[35:32] = InitData_r[7:4];
                assign InitData_reorder[39:36] = InitData_r[15:12];
                assign InitData_reorder[43:40] = InitData_r[23:20];
                assign InitData_reorder[47:44] = InitData_r[31:28];
                assign InitData_reorder[51:48] = InitData_r[39:36];
                assign InitData_reorder[55:52] = InitData_r[47:44];
                assign InitData_reorder[59:56] = InitData_r[55:52];
                assign InitData_reorder[63:60] = InitData_r[63:60];
              end
              assign PopData_r [3:0]         = PopData_reorder [3:0];
              assign PopData_r [7:4]         = PopData_reorder[35:32];
              assign PopData_r[11:8]         = PopData_reorder [7:4];
              assign PopData_r[15:12]        = PopData_reorder[39:36];
              assign PopData_r[19:16]        = PopData_reorder[11:8];
              assign PopData_r[23:20]        = PopData_reorder[43:40];
              assign PopData_r[27:24]        = PopData_reorder[15:12];
              assign PopData_r[31:28]        = PopData_reorder[47:44];
              assign PopData_r[35:32]        = PopData_reorder[19:16];
              assign PopData_r[39:36]        = PopData_reorder[51:48];
              assign PopData_r[43:40]        = PopData_reorder[23:20];
              assign PopData_r[47:44]        = PopData_reorder[55:52];
              assign PopData_r[51:48]        = PopData_reorder[27:24];
              assign PopData_r[55:52]        = PopData_reorder[59:56];
              assign PopData_r[59:56]        = PopData_reorder[31:28];
              assign PopData_r[63:60]        = PopData_reorder[63:60];
              assign PopParity_r             = {P_OUTPUT_PARITY_WIDTH{1'b0}};
            end
          // This special case is optimized for writes
          else if ((C_INPUT_DATA_WIDTH == 64) && (C_OUTPUT_DATA_WIDTH == 8))
            begin : gen_reorder_64_8
              assign PushData_reorder [3:0]  = PushData_r [3:0];
              assign PushData_reorder [7:4]  = PushData_r[11:8];
              assign PushData_reorder[11:8]  = PushData_r[19:16];
              assign PushData_reorder[15:12] = PushData_r[27:24];
              assign PushData_reorder[19:16] = PushData_r[35:32];
              assign PushData_reorder[23:20] = PushData_r[43:40];
              assign PushData_reorder[27:24] = PushData_r[51:48];
              assign PushData_reorder[31:28] = PushData_r[59:56];
              assign PushData_reorder[35:32] = PushData_r [7:4];
              assign PushData_reorder[39:36] = PushData_r[15:12];
              assign PushData_reorder[43:40] = PushData_r[23:20];
              assign PushData_reorder[47:44] = PushData_r[31:28];
              assign PushData_reorder[51:48] = PushData_r[39:36];
              assign PushData_reorder[55:52] = PushData_r[47:44];
              assign PushData_reorder[59:56] = PushData_r[55:52];
              assign PushData_reorder[63:60] = PushData_r[63:60];
              assign PushParity_reorder      = PushParity_r;
              if (C_USE_INIT_PUSH) begin : gen_initpush
                assign InitData_reorder        = InitData_r;
              end
              assign PopData_r               = PopData_reorder;
              assign PopParity_r             = PopParity_reorder;
            end
          else
            begin :gen_reorder_not_supported
            end
        end
      else if (((C_INPUT_DATA_WIDTH ==   8) && (C_OUTPUT_DATA_WIDTH ==   8)) ||
               ((C_INPUT_DATA_WIDTH ==   8) && (C_OUTPUT_DATA_WIDTH ==  32)) ||
               ((C_INPUT_DATA_WIDTH ==  16) && (C_OUTPUT_DATA_WIDTH ==  16)) ||
               ((C_INPUT_DATA_WIDTH ==  16) && (C_OUTPUT_DATA_WIDTH ==  32)) ||
               ((C_INPUT_DATA_WIDTH ==  32) && (C_OUTPUT_DATA_WIDTH ==   8)) ||
               ((C_INPUT_DATA_WIDTH ==  32) && (C_OUTPUT_DATA_WIDTH ==  16)) ||
               ((C_INPUT_DATA_WIDTH ==  32) && (C_OUTPUT_DATA_WIDTH ==  32)) ||
               ((C_INPUT_DATA_WIDTH ==  64) && (C_OUTPUT_DATA_WIDTH ==  64)) ||
               ((C_INPUT_DATA_WIDTH == 128) && (C_OUTPUT_DATA_WIDTH == 128)))
        begin : gen_reorder_general
          assign PushData_reorder   = PushData_r;
          assign PushParity_reorder = PushParity_r;
          if (C_USE_INIT_PUSH) begin : gen_initpush
            assign InitData_reorder   = InitData_r;
          end
          assign PopData_r          = PopData_reorder;
          assign PopParity_r        = PopParity_reorder;
        end
      else if ((C_INPUT_DATA_WIDTH ==  16) && (C_OUTPUT_DATA_WIDTH ==  64))
        begin : gen_reorder_16_64
          assign PushData_reorder        = PushData_r;
          assign PushParity_reorder      = PushParity_r;
          if (C_USE_INIT_PUSH) begin : gen_initpush
            assign InitData_reorder [7:0]  = InitData_r [7:0];
            assign InitData_reorder[15:8]  = InitData_r[23:16];
            assign InitData_reorder[23:16] = InitData_r[39:32];
            assign InitData_reorder[31:24] = InitData_r[55:48];
            assign InitData_reorder[39:32] = InitData_r[15:8];
            assign InitData_reorder[47:40] = InitData_r[31:24];
            assign InitData_reorder[55:48] = InitData_r[47:40];
            assign InitData_reorder[63:56] = InitData_r[63:56];
          end
          assign PopData_r [7:0]         = PopData_reorder [7:0];
          assign PopData_r[15:8]         = PopData_reorder[39:32];
          assign PopData_r[23:16]        = PopData_reorder[15:8];
          assign PopData_r[31:24]        = PopData_reorder[47:40];
          assign PopData_r[39:32]        = PopData_reorder[23:16];
          assign PopData_r[47:40]        = PopData_reorder[55:48];
          assign PopData_r[55:48]        = PopData_reorder[31:24];
          assign PopData_r[63:56]        = PopData_reorder[63:56];
          assign PopParity_r[0]          = PopParity_reorder[0];
          assign PopParity_r[1]          = PopParity_reorder[4];
          assign PopParity_r[2]          = PopParity_reorder[1];
          assign PopParity_r[3]          = PopParity_reorder[5];
          assign PopParity_r[4]          = PopParity_reorder[2];
          assign PopParity_r[5]          = PopParity_reorder[6];
          assign PopParity_r[6]          = PopParity_reorder[3];
          assign PopParity_r[7]          = PopParity_reorder[7];
        end
      else if ((C_INPUT_DATA_WIDTH ==  32) && (C_OUTPUT_DATA_WIDTH ==  64))
        begin : gen_reorder_32_64
          assign PushData_reorder        = PushData_r;
          assign PushParity_reorder      = PushParity_r;
          if (C_USE_INIT_PUSH) begin : gen_initpush
            assign InitData_reorder[15:0]  = InitData_r[15:0];
            assign InitData_reorder[31:16] = InitData_r[47:32];
            assign InitData_reorder[47:32] = InitData_r[31:16];
            assign InitData_reorder[63:48] = InitData_r[63:48];
          end
          assign PopData_r[15:0]         = PopData_reorder[15:0];
          assign PopData_r[31:16]        = PopData_reorder[47:32];
          assign PopData_r[47:32]        = PopData_reorder[31:16];
          assign PopData_r[63:48]        = PopData_reorder[63:48];
          assign PopParity_r[1:0]        = PopParity_reorder[1:0];
          assign PopParity_r[3:2]        = PopParity_reorder[5:4];
          assign PopParity_r[5:4]        = PopParity_reorder[3:2];
          assign PopParity_r[7:6]        = PopParity_reorder[7:6];
        end
      else if ((C_INPUT_DATA_WIDTH ==  32) && (C_OUTPUT_DATA_WIDTH == 128))
        begin : gen_reorder_32_128
          assign PushData_reorder          = PushData_r;
          assign PushParity_reorder        = PushParity_r;
          if (C_USE_INIT_PUSH) begin : gen_initpush
            assign InitData_reorder  [7:0]   = InitData_r  [7:0];
            assign InitData_reorder [15:8]   = InitData_r [39:32];
            assign InitData_reorder [23:16]  = InitData_r [71:64];
            assign InitData_reorder [31:24]  = InitData_r[103:96];
            assign InitData_reorder [39:32]  = InitData_r [15:8];
            assign InitData_reorder [47:40]  = InitData_r [47:40];
            assign InitData_reorder [55:48]  = InitData_r [79:72];
            assign InitData_reorder [63:56]  = InitData_r[111:104];
            assign InitData_reorder [71:64]  = InitData_r [23:16];
            assign InitData_reorder [79:72]  = InitData_r [55:48];
            assign InitData_reorder [87:80]  = InitData_r [87:80];
            assign InitData_reorder [95:88]  = InitData_r[119:112];
            assign InitData_reorder[103:96]  = InitData_r [31:24];
            assign InitData_reorder[111:104] = InitData_r [63:56];
            assign InitData_reorder[119:112] = InitData_r [95:88];
            assign InitData_reorder[127:120] = InitData_r[127:120];
          end
          assign PopData_r  [7:0]          = PopData_reorder  [7:0];
          assign PopData_r [15:8]          = PopData_reorder [39:32];
          assign PopData_r [23:16]         = PopData_reorder [71:64];
          assign PopData_r [31:24]         = PopData_reorder[103:96];
          assign PopData_r [39:32]         = PopData_reorder [15:8];
          assign PopData_r [47:40]         = PopData_reorder [47:40];
          assign PopData_r [55:48]         = PopData_reorder [79:72];
          assign PopData_r [63:56]         = PopData_reorder[111:104];
          assign PopData_r [71:64]         = PopData_reorder [23:16];
          assign PopData_r [79:72]         = PopData_reorder [55:48];
          assign PopData_r [87:80]         = PopData_reorder [87:80];
          assign PopData_r [95:88]         = PopData_reorder[119:112];
          assign PopData_r[103:96]         = PopData_reorder [31:24];
          assign PopData_r[111:104]        = PopData_reorder [63:56];
          assign PopData_r[119:112]        = PopData_reorder [95:88];
          assign PopData_r[127:120]        = PopData_reorder[127:120];
          assign PopParity_r[0]            = PopParity_reorder[0];
          assign PopParity_r[1]            = PopParity_reorder[4];
          assign PopParity_r[2]            = PopParity_reorder[8];
          assign PopParity_r[3]            = PopParity_reorder[12];
          assign PopParity_r[4]            = PopParity_reorder[1];
          assign PopParity_r[5]            = PopParity_reorder[5];
          assign PopParity_r[6]            = PopParity_reorder[9];
          assign PopParity_r[7]            = PopParity_reorder[13];
          assign PopParity_r[8]            = PopParity_reorder[2];
          assign PopParity_r[9]            = PopParity_reorder[6];
          assign PopParity_r[10]           = PopParity_reorder[10];
          assign PopParity_r[11]           = PopParity_reorder[14];
          assign PopParity_r[12]           = PopParity_reorder[3];
          assign PopParity_r[13]           = PopParity_reorder[7];
          assign PopParity_r[14]           = PopParity_reorder[11];
          assign PopParity_r[15]           = PopParity_reorder[15];
        end
      else if ((C_INPUT_DATA_WIDTH ==  64) && (C_OUTPUT_DATA_WIDTH ==  16))
        begin : gen_reorder_64_16
          assign PushData_reorder [7:0]  = PushData_r [7:0];
          assign PushData_reorder[15:8]  = PushData_r[23:16];
          assign PushData_reorder[23:16] = PushData_r[39:32];
          assign PushData_reorder[31:24] = PushData_r[55:48];
          assign PushData_reorder[39:32] = PushData_r[15:8];
          assign PushData_reorder[47:40] = PushData_r[31:24];
          assign PushData_reorder[55:48] = PushData_r[47:40];
          assign PushData_reorder[63:56] = PushData_r[63:56];
          assign PushParity_reorder[0]   = PushParity_r[0];
          assign PushParity_reorder[1]   = PushParity_r[2];
          assign PushParity_reorder[2]   = PushParity_r[4];
          assign PushParity_reorder[3]   = PushParity_r[6];
          assign PushParity_reorder[4]   = PushParity_r[1];
          assign PushParity_reorder[5]   = PushParity_r[3];
          assign PushParity_reorder[6]   = PushParity_r[5];
          assign PushParity_reorder[7]   = PushParity_r[7];
          if (C_USE_INIT_PUSH) begin : gen_initpush
            assign InitData_reorder        = InitData_r;
          end
          assign PopData_r               = PopData_reorder;
          assign PopParity_r             = PopParity_reorder;
        end
      else if ((C_INPUT_DATA_WIDTH ==  64) && (C_OUTPUT_DATA_WIDTH ==  32))
        begin : gen_reorder_64_32
          assign PushData_reorder[15:0]  = PushData_r[15:0];
          assign PushData_reorder[31:16] = PushData_r[47:32];
          assign PushData_reorder[47:32] = PushData_r[31:16];
          assign PushData_reorder[63:48] = PushData_r[63:48];
          assign PushParity_reorder[1:0] = PushParity_r[1:0];
          assign PushParity_reorder[3:2] = PushParity_r[5:4];
          assign PushParity_reorder[5:4] = PushParity_r[3:2];
          assign PushParity_reorder[7:6] = PushParity_r[7:6];
          if (C_USE_INIT_PUSH) begin : gen_initpush
            assign InitData_reorder        = InitData_r;
          end
          assign PopData_r               = PopData_reorder;
          assign PopParity_r             = PopParity_reorder;
        end
      else if ((C_INPUT_DATA_WIDTH ==  64) && (C_OUTPUT_DATA_WIDTH == 128))
        begin : gen_reorder_64_128
          assign PushData_reorder          = PushData_r;
          assign PushParity_reorder        = PushParity_r;
          if (C_USE_INIT_PUSH) begin : gen_initpush
            assign InitData_reorder [15:0]   = InitData_r [15:0];
            assign InitData_reorder [31:16]  = InitData_r [79:64];
            assign InitData_reorder [47:32]  = InitData_r [31:16];
            assign InitData_reorder [63:48]  = InitData_r [95:80];
            assign InitData_reorder [79:64]  = InitData_r [47:32];
            assign InitData_reorder [95:80]  = InitData_r[111:96];
            assign InitData_reorder[111:96]  = InitData_r [63:48];
            assign InitData_reorder[127:112] = InitData_r[127:112];
          end
          assign PopData_r [15:0]          = PopData_reorder [15:0];
          assign PopData_r [31:16]         = PopData_reorder [47:32];
          assign PopData_r [47:32]         = PopData_reorder [79:64];
          assign PopData_r [63:48]         = PopData_reorder[111:96];
          assign PopData_r [79:64]         = PopData_reorder [31:16];
          assign PopData_r [95:80]         = PopData_reorder [63:48];
          assign PopData_r[111:96]         = PopData_reorder [95:80];
          assign PopData_r[127:112]        = PopData_reorder[127:112];
          assign PopParity_r [1:0]         = PopParity_reorder [1:0];
          assign PopParity_r [3:2]         = PopParity_reorder [5:4];
          assign PopParity_r [5:4]         = PopParity_reorder [9:8];
          assign PopParity_r [7:6]         = PopParity_reorder[13:12];
          assign PopParity_r [9:8]         = PopParity_reorder [3:2];
          assign PopParity_r[11:10]        = PopParity_reorder [7:6];
          assign PopParity_r[13:12]        = PopParity_reorder[11:10];
          assign PopParity_r[15:14]        = PopParity_reorder[15:14];
        end
      else if ((C_INPUT_DATA_WIDTH == 128) && (C_OUTPUT_DATA_WIDTH ==  32))
        begin : gen_reorder_128_32
          assign PushData_reorder  [7:0]   = PushData_r  [7:0];
          assign PushData_reorder [15:8]   = PushData_r [39:32];
          assign PushData_reorder [23:16]  = PushData_r [71:64];
          assign PushData_reorder [31:24]  = PushData_r[103:96];
          assign PushData_reorder [39:32]  = PushData_r [15:8];
          assign PushData_reorder [47:40]  = PushData_r [47:40];
          assign PushData_reorder [55:48]  = PushData_r [79:72];
          assign PushData_reorder [63:56]  = PushData_r[111:104];
          assign PushData_reorder [71:64]  = PushData_r [23:16];
          assign PushData_reorder [79:72]  = PushData_r [55:48];
          assign PushData_reorder [87:80]  = PushData_r [87:80];
          assign PushData_reorder [95:88]  = PushData_r[119:112];
          assign PushData_reorder[103:96]  = PushData_r [31:24];
          assign PushData_reorder[111:104] = PushData_r [63:56];
          assign PushData_reorder[119:112] = PushData_r [95:88];
          assign PushData_reorder[127:120] = PushData_r[127:120];
          assign PushParity_reorder[0]     = PushParity_r[0];
          assign PushParity_reorder[1]     = PushParity_r[4];
          assign PushParity_reorder[2]     = PushParity_r[8];
          assign PushParity_reorder[3]     = PushParity_r[12];
          assign PushParity_reorder[4]     = PushParity_r[1];
          assign PushParity_reorder[5]     = PushParity_r[5];
          assign PushParity_reorder[6]     = PushParity_r[9];
          assign PushParity_reorder[7]     = PushParity_r[13];
          assign PushParity_reorder[8]     = PushParity_r[2];
          assign PushParity_reorder[9]     = PushParity_r[6];
          assign PushParity_reorder[10]    = PushParity_r[10];
          assign PushParity_reorder[11]    = PushParity_r[14];
          assign PushParity_reorder[12]    = PushParity_r[3];
          assign PushParity_reorder[13]    = PushParity_r[7];
          assign PushParity_reorder[14]    = PushParity_r[11];
          assign PushParity_reorder[15]    = PushParity_r[15];
          if (C_USE_INIT_PUSH) begin : gen_initpush
            assign InitData_reorder          = InitData_r;
          end
          assign PopData_r                 = PopData_reorder;
          assign PopParity_r               = PopParity_reorder;
        end
      else if ((C_INPUT_DATA_WIDTH == 128) && (C_OUTPUT_DATA_WIDTH ==  64))
        begin : gen_reorder_128_64
          assign PushData_reorder [15:0]   = PushData_r [15:0];
          assign PushData_reorder [31:16]  = PushData_r [79:64];
          assign PushData_reorder [47:32]  = PushData_r [31:16];
          assign PushData_reorder [63:48]  = PushData_r [95:80];
          assign PushData_reorder [79:64]  = PushData_r [47:32];
          assign PushData_reorder [95:80]  = PushData_r[111:96];
          assign PushData_reorder[111:96]  = PushData_r [63:48];
          assign PushData_reorder[127:112] = PushData_r[127:112];
          assign PushParity_reorder [1:0]  = PushParity_r [1:0];
          assign PushParity_reorder [3:2]  = PushParity_r [9:8];
          assign PushParity_reorder [5:4]  = PushParity_r [3:2];
          assign PushParity_reorder [7:6]  = PushParity_r[11:10];
          assign PushParity_reorder [9:8]  = PushParity_r [5:4];
          assign PushParity_reorder[11:10] = PushParity_r[13:12];
          assign PushParity_reorder[13:12] = PushParity_r [7:6];
          assign PushParity_reorder[15:14] = PushParity_r[15:14];
          if (C_USE_INIT_PUSH) begin : gen_initpush
            assign InitData_reorder          = InitData_r;
          end
          assign PopData_r                 = PopData_reorder;
          assign PopParity_r               = PopParity_reorder;
        end
      else
        begin :gen_reorder_not_supported
        end
   endgenerate
   
   generate
      if (P_BRAM_TYPE_NOT_SUPPORTED == 1) begin : gen_brams_not_supported
      end
      else if (P_BRAM_TYPE_SPECIAL_CASE == 1) begin : gen_brams_special_case
         // This case will only work for reads.  
         // Needs extra BRAM for Write Byte Enables.
         if (((C_INPUT_DATA_WIDTH ==   8) && (C_OUTPUT_DATA_WIDTH ==  64)) ||
             ((C_INPUT_DATA_WIDTH ==   8) && (C_OUTPUT_DATA_WIDTH == 128)) ||
             ((C_INPUT_DATA_WIDTH ==  16) && (C_OUTPUT_DATA_WIDTH == 128)))
           begin : gen_brams_read
              assign PopParity_reorder = {P_OUTPUT_PARITY_WIDTH{1'b0}};
              for (i=0;i<P_NUM_BRAMS;i=i+1) begin : gen_brams
                 if ((C_FAMILY == "virtex4") || (C_FAMILY == "virtex6" || C_FAMILY == "virtex5")) 
                   begin : gen_v4
                    wire [31:0] dia;
                    wire [31:0] dib;
                    wire [31:0] dob;
                    assign dia = PushData_reorder
                                 [(i+1)*C_INPUT_DATA_WIDTH/P_NUM_BRAMS-1:
                                  i*C_INPUT_DATA_WIDTH/P_NUM_BRAMS];
                    assign dib = {C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS{1'b0}};
                    assign PopData_reorder
                                 [(i+1)*C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS-1:
                                  i*C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS] =
                           dob[C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS-1:0];
                      
                    RAMB16 #
                      (
                       .DOA_REG             (0),
                       .DOB_REG             (0),
                       .WRITE_WIDTH_A       (C_INPUT_DATA_WIDTH/P_NUM_BRAMS),
                       .WRITE_WIDTH_B       (C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS +
                                            P_OUTPUT_PARITY_WIDTH/P_NUM_BRAMS),
                       .READ_WIDTH_A        (C_INPUT_DATA_WIDTH/P_NUM_BRAMS),
                       .READ_WIDTH_B        (C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS +
                                            P_OUTPUT_PARITY_WIDTH/P_NUM_BRAMS),
                       .WRITE_MODE_A        ("READ_FIRST"),
                       .WRITE_MODE_B        ("READ_FIRST"),
                       .SIM_COLLISION_CHECK ("NONE")
                       ) 
                      bram 
                        (.CLKA  (PushClk),
                         .WEA   ({4{Push_r}}),
                         .ADDRA ({2'b0,PushAddr_tmp,2'b0}),
                         .DIA   (dia),
                         .DIPA  (4'b0),
                         .DOA   (),
                         .DOPA  (), 
                         .ENA   (1'b1),
                         .SSRA  (1'b0),
                         // Don't add logic for write training pattern since
                         // this is a read special case.
                         .CLKB  (PopClk),
                         .WEB   ({4{Pop}}),
                         .ADDRB ({1'b0,PopAddr_tmp,3'b0}),
                         .DIB   (dib),
                         .DIPB  (4'b0),
                         .DOB   (dob),
                         .DOPB  (),
                         .ENB   (1'b1),
                         .SSRB  (1'b0),
                         .REGCEA      (1'b0),
                         .REGCEB      (1'b1),
                         .CASCADEINA  (1'b0),
                         .CASCADEINB  (1'b0),
                         .CASCADEOUTA (),
                         .CASCADEOUTB ()
                         );
                 end
                 else begin : gen_normal
                    mpmc_ramb16_sx_sx #
                      (
                       .C_DATA_WIDTH_A   (C_INPUT_DATA_WIDTH/P_NUM_BRAMS),
                       .C_DATA_WIDTH_B   (C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS),
                       .C_PARITY_WIDTH_A (1),
                       .C_PARITY_WIDTH_B (1)
                       ) 
                      bram 
                        (.CLKA  (PushClk),
                         .WEA   (Push_r),
                         .ADDRA ({1'b0,PushAddr_tmp,2'b0}),
                         .DIA   (PushData_reorder
                                 [(i+1)*C_INPUT_DATA_WIDTH/P_NUM_BRAMS-1:
                                  i*C_INPUT_DATA_WIDTH/P_NUM_BRAMS]),
                         .DIPA  (1'b0),
                         .DOA   (),
                         .DOPA  (), 
                         .ENA   (1'b1),
                         .SSRA  (1'b0),
                         .CLKB  (PopClk),
                         .WEB   (Pop),
                         .ADDRB ({PopAddr_tmp,3'b0}),
                         .DIB   ({C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS{1'b0}}),
                         .DIPB  (1'b0),
                         .DOB   (PopData_reorder
                                 [(i+1)*C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS-1:
                                  i*C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS]),
                         .DOPB  (),
                         .ENB   (1'b1),
                         .SSRB  (1'b0)
                         );
                 end
              end
           end
         // This case is optimized for writes
         else if ((C_INPUT_DATA_WIDTH ==  64) && (C_OUTPUT_DATA_WIDTH ==  8))
           begin : gen_brams_64_8
              wire [31:0] PushParity_reorder_tmp;
              wire [3:0]  PopParity_reorder_tmp;
              assign PushParity_reorder_tmp[0]  = PushParity_reorder[0];
              assign PushParity_reorder_tmp[4]  = PushParity_reorder[1];
              assign PushParity_reorder_tmp[8]  = PushParity_reorder[2];
              assign PushParity_reorder_tmp[12] = PushParity_reorder[3];
              assign PushParity_reorder_tmp[16] = PushParity_reorder[4];
              assign PushParity_reorder_tmp[20] = PushParity_reorder[5];
              assign PushParity_reorder_tmp[24] = PushParity_reorder[6];
              assign PushParity_reorder_tmp[28] = PushParity_reorder[7];
              assign PushParity_reorder_tmp[3:1]   = 3'b0;
              assign PushParity_reorder_tmp[7:5]   = 3'b0;
              assign PushParity_reorder_tmp[11:9]  = 3'b0;
              assign PushParity_reorder_tmp[15:13] = 3'b0;
              assign PushParity_reorder_tmp[19:17] = 3'b0;
              assign PushParity_reorder_tmp[23:21] = 3'b0;
              assign PushParity_reorder_tmp[27:25] = 3'b0;
              assign PushParity_reorder_tmp[31:29] = 3'b0;
              assign PopParity_reorder = PopParity_reorder_tmp[0];
              if ((C_FAMILY == "virtex4") || (C_FAMILY == "virtex6" || C_FAMILY == "virtex5")) 
                begin : gen_v4
                  wire [31:0] dia;
                  wire [31:0] dib;
                  wire [31:0] dob;
                  wire [3:0]  web;
                  wire [14:0] addrb;
                  assign      dia = PushParity_reorder_tmp;
                  if (C_USE_INIT_PUSH) begin : gen_initpush
                    assign dib   = {4{InitPush_r}};
                    assign web   = {4{InitPush_r | Pop}};
                    assign addrb = InitPush_r ? {2'b0,PushAddr_tmp,2'b0} : 
                                                {2'b0,PopAddr_tmp,2'b0};
                  end else begin : gen_normal
                    assign dib   = {4{1'b0}};
                    assign web   = {4{Pop}};
                    assign addrb = {2'b0,PopAddr_tmp,2'b0};
                  end
                  assign PopParity_reorder_tmp = dob;
                  RAMB16 #
                    (
                     .DOA_REG             (0),
                     .DOB_REG             (0),
                     .WRITE_WIDTH_A       (36),
                     .WRITE_WIDTH_B       (4),
                     .READ_WIDTH_A        (36),
                     .READ_WIDTH_B        (4),
                     .WRITE_MODE_A        ("READ_FIRST"),
                     .WRITE_MODE_B        ("READ_FIRST"),
                     .SIM_COLLISION_CHECK ("NONE")
                     ) 
                    bram 
                      (.CLKA  (PushClk),
                       .WEA   ({4{Push_r}}),
                       .ADDRA ({1'b0,PushAddr_tmp,3'b0}),
                       .DIA   (dia),
                       .DIPA  (4'b0),
                       .DOA   (),
                       .DOPA  (), 
                       .ENA   (1'b1),
                       .SSRA  (1'b0),
                       .CLKB  (PopClk),
                       .WEB   (web),
                       .ADDRB (addrb),
                       .DIB   (dib),
                       .DIPB  (4'b0),
                       .DOB   (dob),
                       .DOPB  (),
                       .ENB   (1'b1),
                       .SSRB  (1'b0),
                       .REGCEA      (1'b0),
                       .REGCEB      (1'b1),
                       .CASCADEINA  (1'b0),
                       .CASCADEINB  (1'b0),
                       .CASCADEOUTA (),
                       .CASCADEOUTB ()
                       );
                end
              else begin : gen_normal
                wire [3:0]  dib;
                wire        web;
                wire [13:0] addrb;
                if (C_USE_INIT_PUSH) begin : gen_initpush
                  assign dib = {4{InitPush_r}};
                  assign web = InitPush_r | Pop;
                  assign addrb = {1'b0,InitPush_r ? PushAddr_tmp : PopAddr_tmp,
                                  2'b0};
                end else begin : gen_normal
                  assign dib = {4{1'b0}};
                  assign web = Pop;
                  assign addrb = {1'b0,PopAddr_tmp,2'b0};
                end
                mpmc_ramb16_sx_sx #
                  (
                   .C_DATA_WIDTH_A   (32),
                   .C_DATA_WIDTH_B   (4),
                   .C_PARITY_WIDTH_A (1),
                   .C_PARITY_WIDTH_B (1)
                   ) 
                  bram 
                    (.CLKA  (PushClk),
                     .WEA   (Push_r),
                     .ADDRA ({PushAddr_tmp,3'b0}),
                     .DIA   (PushParity_reorder_tmp),
                     .DIPA  (1'b0),
                     .DOA   (),
                     .DOPA  (), 
                     .ENA   (1'b1),
                     .SSRA  (1'b0),
                     .CLKB  (PopClk),
                     .WEB   (web),
                     .ADDRB (addrb),
                     .DIB   (dib),
                     .DIPB  (1'b0),
                     .DOB   (PopParity_reorder_tmp),
                     .DOPB  (),
                     .ENB   (1'b1),
                     .SSRB  (1'b0)
                     );
              end
              for (i=0;i<2;i=i+1) begin : gen_brams
                 if (((C_FAMILY == "virtex6" || C_FAMILY == "virtex5")) || (C_FAMILY == "virtex4")) 
                   begin : gen_v4
                     wire [31:0] dia;
                     wire [31:0] dib;
                     wire [31:0] dob;
                     wire [3:0]  web;
                     wire [14:0] addrb;
                     assign dia = PushData_reorder[(i+1)*32-1:i*32];
                     if (C_USE_INIT_PUSH) begin : gen_initpush
                       assign dib = InitPush_r ? 
                                    InitData_reorder[(i+1)*4-1:i*4] : 
                                    4'b0;
                       assign web = {4{InitPush_r | Pop}};
                       assign addrb = InitPush_r ? {2'b0,PushAddr_tmp,2'b0} : 
                                                   {2'b0,PopAddr_tmp,2'b0};
                     end else begin : gen_normal
                       assign dib = 4'b0;
                       assign web = {4{Pop}};
                       assign addrb = {2'b0,PopAddr_tmp,2'b0};
                     end
                     assign PopData_reorder[(i+1)*4-1:i*4] = dob[3:0];
                     RAMB16 #
                       (
                        .DOA_REG             (0),
                        .DOB_REG             (0),
                        .WRITE_WIDTH_A       (36),
                        .WRITE_WIDTH_B       (4),
                        .READ_WIDTH_A        (36),
                        .READ_WIDTH_B        (4),
                        .WRITE_MODE_A        ("READ_FIRST"),
                        .WRITE_MODE_B        ("READ_FIRST"),
                        .SIM_COLLISION_CHECK ("NONE")
                        ) 
                       bram 
                         (.CLKA  (PushClk),
                          .WEA   ({4{Push_r}}),
                          .ADDRA ({1'b0,PushAddr_tmp,3'b0}),
                          .DIA   (dia),
                          .DIPA  (4'b0),
                          .DOA   (),
                          .DOPA  (), 
                          .ENA   (1'b1),
                          .SSRA  (1'b0),
                          .CLKB  (PopClk),
                          .WEB   (web),
                          .ADDRB (addrb),
                          .DIB   (dib),
                          .DIPB  (4'b0),
                          .DOB   (dob),
                          .DOPB  (),
                          .ENB   (1'b1),
                          .SSRB  (1'b0),
                          .REGCEA      (1'b0),
                          .REGCEB      (1'b1),
                          .CASCADEINA  (1'b0),
                          .CASCADEINB  (1'b0),
                          .CASCADEOUTA (),
                          .CASCADEOUTB ()
                          );
                   end
                 else begin : gen_normal
                   wire [3:0]  dib;
                   wire        web;
                   wire [13:0] addrb;
                   if (C_USE_INIT_PUSH) begin : gen_initpush
                     assign dib   = InitPush_r ? 
                                    InitData_reorder[(i+1)*4-1:i*4] : 
                                    4'b0;
                     assign web   = InitPush_r | Pop;
                     assign addrb = {1'b0, InitPush_r ? PushAddr_tmp : 
                                                        PopAddr_tmp,2'b0};
                   end else begin : gen_normal
                     assign dib   = 4'b0;
                     assign web   =Pop;
                     assign addrb = {1'b0,PopAddr_tmp,2'b0};
                   end
                   mpmc_ramb16_sx_sx #
                     (
                      .C_DATA_WIDTH_A   (32),
                      .C_DATA_WIDTH_B   (4),
                      .C_PARITY_WIDTH_A (1),
                      .C_PARITY_WIDTH_B (1)
                      ) 
                     bram 
                       (.CLKA  (PushClk),
                        .WEA   (Push_r),
                        .ADDRA ({PushAddr_tmp,3'b0}),
                        .DIA   (PushData_reorder[(i+1)*32-1:i*32]),
                        .DIPA  (1'b0),
                        .DOA   (),
                        .DOPA  (), 
                        .ENA   (1'b1),
                        .SSRA  (1'b0),
                        .CLKB  (PopClk),
                        .WEB   (web),
                        .ADDRB (addrb),
                        .DIB   (dib),
                        .DIPB  (1'b0),
                        .DOB   (PopData_reorder[(i+1)*4-1:i*4]),
                        .DOPB  (),
                        .ENB   (1'b1),
                        .SSRB  (1'b0)
                        );
                 end
              end
           end
         // This case is optimized for writes
         //else if ((C_INPUT_DATA_WIDTH == 128) && (C_OUTPUT_DATA_WIDTH ==  8))
         //  begin : gen_brams_128_8
         //  end
         // This case is optimized for writes
         //else if ((C_INPUT_DATA_WIDTH == 128) && (C_OUTPUT_DATA_WIDTH == 16))
         //  begin : gen_brams_128_16
         //  end
         else
           begin : gen_brams_not_supported
           end
      end
      else begin : gen_brams_normal
         if (((C_FAMILY == "virtex5") || (C_FAMILY == "virtex6")) && 
             (C_INPUT_DATA_WIDTH == C_OUTPUT_DATA_WIDTH) &&
             (C_INPUT_DATA_WIDTH == 32)) begin : gen_v5_RAMB18SDP
           wire [3:0]  we;
           wire [31:0] di;
           wire [3:0]  dip;
           if (C_USE_INIT_PUSH) begin : gen_initpush
             assign we = {4{InitPush_r | Push_r}};
             assign di = InitPush_r ? InitData_reorder : PushData_reorder;
             assign dip = InitPush_r ? {4{InitPush_r}} : PushParity_reorder;
           end else begin : gen_normal
             assign we = {4{Push_r}};
             assign di = PushData_reorder;
             assign dip = PushParity_reorder;
           end
            RAMB18SDP #
              (
               .DO_REG              (0),
               .SIM_COLLISION_CHECK ("NONE")
               ) 
              bram 
                (.WRCLK  (PushClk),
                 .WE     (we),
                 .WRADDR (PushAddr_tmp[9:1]),
                 .DI     (di),
                 .DIP    (dip),
                 .WREN   (1'b1),
                 .RDCLK  (PopClk),
                 .RDADDR (PopAddr_tmp[9:1]),
                 .DO     (PopData_reorder),
                 .DOP    (PopParity_reorder),
                 .RDEN   (1'b1),
                 .SSR    (ParityRst),
                 .REGCE  (1'b1)
                 );
         end
         else if (((C_FAMILY == "virtex5") || (C_FAMILY == "virtex6")) && 
             (C_INPUT_DATA_WIDTH == C_OUTPUT_DATA_WIDTH) &&
             (C_INPUT_DATA_WIDTH == 64)) begin : gen_v5_RAMB36SDP
           wire [7:0]  we;
           wire [63:0] di;
           wire [7:0]  dip;
           if (C_USE_INIT_PUSH) begin : gen_initpush
             assign we  = {8{InitPush_r | Push_r}};
             assign di  = InitPush_r ? InitData_reorder : PushData_reorder;
             assign dip = InitPush_r ? {8{InitPush_r}} : PushParity_reorder;
           end else begin : gen_normal
             assign we  = {8{Push_r}};
             assign di  = PushData_reorder;
             assign dip = PushParity_reorder;
           end
           RAMB36SDP #
             (
              .DO_REG              (0),
              .SIM_COLLISION_CHECK ("NONE")
              ) 
             bram 
               (.WRCLK     (PushClk),
                .WE        (we),
                .WRADDR    (PushAddr_tmp[9:1]),
                .DI        (di),
                .DIP       (dip),
                .WREN      (1'b1),
                .RDCLK     (PopClk),
                .RDADDR    (PopAddr_tmp[9:1]),
                .DO        (PopData_reorder),
                .DOP       (PopParity_reorder),
                .RDEN      (1'b1),
                .SSR       (ParityRst),
                .REGCE     (1'b1),
                .SBITERR   (),
                .DBITERR   (),
                .ECCPARITY ()
                );
         end
         else if ((C_FAMILY == "virtex6" || C_FAMILY == "virtex5") || (C_FAMILY == "virtex4")) 
           begin : gen_v4
             for (i=0;i<P_NUM_BRAMS;i=i+1) begin : gen_brams
               wire [31:0] dia;
               wire [3:0]  dipa;
               wire [31:0] dib;
               wire [3:0]  dipb;
               wire [31:0] dob;
               wire [3:0]  dopb;
               wire [3:0]  web;
               wire [14:0] addrb;
               assign dia = PushData_reorder
                            [(i+1)*C_INPUT_DATA_WIDTH/P_NUM_BRAMS-1:
                             i*C_INPUT_DATA_WIDTH/P_NUM_BRAMS];
               assign dipa = PushParity_reorder
                             [(i+1)*P_INPUT_PARITY_WIDTH/P_NUM_BRAMS-1:
                              i*P_INPUT_PARITY_WIDTH/P_NUM_BRAMS];
               if (C_USE_INIT_PUSH) begin : gen_initpush
                 assign dib = InitPush_r ? 
                              InitData_reorder
                              [(i+1)*C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS-1:
                               i*C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS] :
                              {C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS{1'b0}};
                 assign dipb = {P_OUTPUT_PARITY_WIDTH/P_NUM_BRAMS{InitPush_r}};
                 assign web  = {4{InitPush_r | Pop}};
                 assign addrb = InitPush_r ? {1'b0,PushAddr_tmp,3'b0} :
                                             {1'b0,PopAddr_tmp,3'b0};
               end else begin : gen_normal
                 assign dib = {C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS{1'b0}};
                 assign dipb = {P_OUTPUT_PARITY_WIDTH/P_NUM_BRAMS{1'b0}};
                 assign web  = {4{Pop}};
                 assign addrb = {1'b0,PopAddr_tmp,3'b0};
               end
               assign PopData_reorder
                      [(i+1)*C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS-1:
                       i*C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS] = 
                      dob[C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS-1:0];
               assign PopParity_reorder
                      [(i+1)*P_OUTPUT_PARITY_WIDTH/P_NUM_BRAMS-1:
                       i*P_OUTPUT_PARITY_WIDTH/P_NUM_BRAMS] = 
                      dopb[P_OUTPUT_PARITY_WIDTH/P_NUM_BRAMS-1:0];
               RAMB16 #
                 (
                  .DOA_REG             (0),
                  .DOB_REG             (0),
                  .WRITE_WIDTH_A       (C_INPUT_DATA_WIDTH/P_NUM_BRAMS +
                                        P_INPUT_PARITY_WIDTH/P_NUM_BRAMS),
                  .WRITE_WIDTH_B       (C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS +
                                        P_OUTPUT_PARITY_WIDTH/P_NUM_BRAMS),
                  .READ_WIDTH_A        (C_INPUT_DATA_WIDTH/P_NUM_BRAMS +
                                        P_INPUT_PARITY_WIDTH/P_NUM_BRAMS),
                  .READ_WIDTH_B        (C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS +
                                        P_OUTPUT_PARITY_WIDTH/P_NUM_BRAMS),
                  .WRITE_MODE_A        ("READ_FIRST"),
                  .WRITE_MODE_B        ("READ_FIRST"),
                  .SIM_COLLISION_CHECK ("NONE")
                  ) 
                 bram 
                   (.CLKA  (PushClk),
                    .WEA   ({4{Push_r}}),
                    .ADDRA ({1'b0,PushAddr_tmp,3'b0}),
                    .DIA   (dia),
                    .DIPA  (dipa),
                    .DOA   (),
                    .DOPA  (), 
                    .ENA   (1'b1),
                    .SSRA  (1'b0),
                    .CLKB  (PopClk),
                    .WEB   (web),
                    .ADDRB (addrb),
                    .DIB   (dib),
                    .DIPB  (dipb),
                    .DOB   (dob),
                    .DOPB  (dopb),
                    .ENB   (1'b1),
                    .SSRB  (1'b0),
                    .REGCEA      (1'b0),
                    .REGCEB      (1'b1),
                    .CASCADEINA  (1'b0),
                    .CASCADEINB  (1'b0),
                    .CASCADEOUTA (),
                    .CASCADEOUTB ()
                    );
             end
           end
         else begin : gen_normal
           for (i=0;i<P_NUM_BRAMS;i=i+1) begin : gen_brams
             wire [C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS-1:0]   dib;
             wire [P_OUTPUT_PARITY_WIDTH/P_NUM_BRAMS-1:0] dipb;
             wire        web;
             wire [13:0] addrb;
             if (C_USE_INIT_PUSH) begin : gen_initpush
               assign dib   = InitPush_r ? 
                              InitData_reorder
                              [(i+1)*C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS-1:
                               i*C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS] :
                              {C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS{1'b0}};
               assign dipb  = {P_OUTPUT_PARITY_WIDTH/P_NUM_BRAMS{InitPush_r}};
               assign web   = InitPush_r | Pop;
               assign addrb = {InitPush_r ? PushAddr_tmp : PopAddr_tmp,3'b0};
             end else begin : gen_normal
               assign dib   = {C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS{1'b0}};
               assign dipb  = {P_OUTPUT_PARITY_WIDTH/P_NUM_BRAMS{1'b0}};
               assign web   = Pop;
               assign addrb = {PopAddr_tmp,3'b0};
             end
             mpmc_ramb16_sx_sx #
               (
                .C_DATA_WIDTH_A   (C_INPUT_DATA_WIDTH/P_NUM_BRAMS),
                .C_DATA_WIDTH_B   (C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS),
                .C_PARITY_WIDTH_A (P_INPUT_PARITY_WIDTH/P_NUM_BRAMS),
                .C_PARITY_WIDTH_B (P_OUTPUT_PARITY_WIDTH/P_NUM_BRAMS)
                ) 
               bram 
                 (.CLKA  (PushClk),
                  .WEA   (Push_r),
                  .ADDRA ({PushAddr_tmp,3'b0}),
                  .DIA   (PushData_reorder
                          [(i+1)*C_INPUT_DATA_WIDTH/P_NUM_BRAMS-1:
                           i*C_INPUT_DATA_WIDTH/P_NUM_BRAMS]),
                  .DIPA  (PushParity_reorder
                          [(i+1)*P_INPUT_PARITY_WIDTH/P_NUM_BRAMS-1:
                           i*P_INPUT_PARITY_WIDTH/P_NUM_BRAMS]),
                  .DOA   (),
                  .DOPA  (), 
                  .ENA   (1'b1),
                  .SSRA  (1'b0),
                  .CLKB  (PopClk),
                  .WEB   (web),
                  .ADDRB (addrb),
                  .DIB   (dib),
                  .DIPB  (dipb),
                  .DOB   (PopData_reorder
                          [(i+1)*C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS-1:
                           i*C_OUTPUT_DATA_WIDTH/P_NUM_BRAMS]),
                  .DOPB  (PopParity_reorder
                          [(i+1)*P_OUTPUT_PARITY_WIDTH/P_NUM_BRAMS-1:
                           i*P_OUTPUT_PARITY_WIDTH/P_NUM_BRAMS]),
                  .ENB   (1'b1),
                  .SSRB  (1'b0)
                  );
           end
         end
      end
   endgenerate

endmodule // mpmc_bram_fifo

