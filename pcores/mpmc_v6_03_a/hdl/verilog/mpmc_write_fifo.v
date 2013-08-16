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

`timescale 1ns/1ps

module mpmc_write_fifo #
  (
   parameter         C_FAMILY         = "virtex4",
   parameter         C_USE_INIT_PUSH  = 1'b1,
   parameter         C_FIFO_TYPE      = 2'b11,  // BRAM (2'b11) or SRL (2'b10)
   parameter         C_PI_PIPELINE    = 1'b1,
   parameter         C_MEM_PIPELINE   = 1'b1,
   parameter integer C_PI_ADDR_WIDTH  =   32,
   parameter integer C_PI_DATA_WIDTH  =   64,
   parameter integer C_MEM_DATA_WIDTH =  128
   )
  (
   // Clocks and Resets
   input                           Clk,
   input                           Rst,
   // Port Interface Control Signal Inputs
   input                           AddrAck,
   input                           RNW,
   input  [3:0]                    Size,
   input  [C_PI_ADDR_WIDTH-1:0]    Addr,
   // Write Training Pattern Signals
   // Assumes that InitPush and related Pop do not happen on the same cycle.
   // Assumes that InitPush and Push do not happen on the same cycle.
   input                           InitPush,
   input [C_MEM_DATA_WIDTH-1:0]    InitData,
   input                           InitDone,
   // Write FIFO Control Signal Inputs
   input                           Flush,
   input                           Push,
   input                           Pop,
   input                           BE_Rst, // Valid with Pop
   // Write FIFO Control Signal Outputs
   output                          Empty,
   output                          AlmostFull,
   // Write FIFO Data Signals
   input  [C_PI_DATA_WIDTH-1:0]    PushData,
   input  [C_PI_DATA_WIDTH/8-1:0]  PushBE,
   output [C_MEM_DATA_WIDTH-1:0]   PopData,
   output [C_MEM_DATA_WIDTH/8-1:0] PopBE
   );

   localparam P_INPUT_DATA_WIDTH  = C_PI_DATA_WIDTH;
   localparam P_OUTPUT_DATA_WIDTH = C_MEM_DATA_WIDTH;
   localparam P_INPUT_PIPELINE    = C_PI_PIPELINE;
   localparam P_OUTPUT_PIPELINE   = C_MEM_PIPELINE;
   
   localparam P_WORD_XFER_SPECIAL_CASE = 
            ((P_INPUT_DATA_WIDTH ==   8) && (P_OUTPUT_DATA_WIDTH ==  64)) ? 1 :
            ((P_INPUT_DATA_WIDTH ==   8) && (P_OUTPUT_DATA_WIDTH == 128)) ? 1 :
            ((P_INPUT_DATA_WIDTH ==  16) && (P_OUTPUT_DATA_WIDTH ==  64)) ? 1 :
            ((P_INPUT_DATA_WIDTH ==  16) && (P_OUTPUT_DATA_WIDTH == 128)) ? 1 :
            ((P_INPUT_DATA_WIDTH ==  32) && (P_OUTPUT_DATA_WIDTH ==  64)) ? 1 :
            ((P_INPUT_DATA_WIDTH ==  32) && (P_OUTPUT_DATA_WIDTH == 128)) ? 1 :
            ((P_INPUT_DATA_WIDTH ==  64) && (P_OUTPUT_DATA_WIDTH ==   8)) ? 1 :
            ((P_INPUT_DATA_WIDTH ==  64) && (P_OUTPUT_DATA_WIDTH ==  16)) ? 1 :
            ((P_INPUT_DATA_WIDTH ==  64) && (P_OUTPUT_DATA_WIDTH ==  32)) ? 1 :
            ((P_INPUT_DATA_WIDTH ==  64) && (P_OUTPUT_DATA_WIDTH == 128)) ? 1 :
            ((P_INPUT_DATA_WIDTH == 128) && (P_OUTPUT_DATA_WIDTH ==   8)) ? 1 :
            ((P_INPUT_DATA_WIDTH == 128) && (P_OUTPUT_DATA_WIDTH ==  16)) ? 1 :
            ((P_INPUT_DATA_WIDTH == 128) && (P_OUTPUT_DATA_WIDTH ==  32)) ? 1 :
            ((P_INPUT_DATA_WIDTH == 128) && (P_OUTPUT_DATA_WIDTH ==  64)) ? 1 :
                                                                            0;

   localparam P_DOUBLEWORD_XFER_SPECIAL_CASE = 
            ((P_INPUT_DATA_WIDTH ==   8) && (P_OUTPUT_DATA_WIDTH == 128)) ? 1 :
            ((P_INPUT_DATA_WIDTH ==  16) && (P_OUTPUT_DATA_WIDTH == 128)) ? 1 :
            ((P_INPUT_DATA_WIDTH ==  32) && (P_OUTPUT_DATA_WIDTH == 128)) ? 1 :
            ((P_INPUT_DATA_WIDTH ==  64) && (P_OUTPUT_DATA_WIDTH == 128)) ? 1 :
            ((P_INPUT_DATA_WIDTH == 128) && (P_OUTPUT_DATA_WIDTH ==   8)) ? 1 :
            ((P_INPUT_DATA_WIDTH == 128) && (P_OUTPUT_DATA_WIDTH ==  16)) ? 1 :
            ((P_INPUT_DATA_WIDTH == 128) && (P_OUTPUT_DATA_WIDTH ==  32)) ? 1 :
            ((P_INPUT_DATA_WIDTH == 128) && (P_OUTPUT_DATA_WIDTH ==  64)) ? 1 :
                                                                            0;

   localparam P_FIFO_ADDR_WIDTH =
        (C_FIFO_TYPE == 2'b11) ?
        (((P_INPUT_DATA_WIDTH  == 128) || (P_OUTPUT_DATA_WIDTH == 128)) ? 10 :
         ((P_INPUT_DATA_WIDTH  ==  64) || (P_OUTPUT_DATA_WIDTH ==  64)) ? 10 :
         ((P_INPUT_DATA_WIDTH  ==  32) || (P_OUTPUT_DATA_WIDTH ==  32)) ? 10 :
                                                                           0) :
        (((P_INPUT_DATA_WIDTH  >=  64) || (P_OUTPUT_DATA_WIDTH >=  64)) ?  8 :
         ((P_INPUT_DATA_WIDTH  ==  32) || (P_OUTPUT_DATA_WIDTH ==  32)) ?  7 :
                                                                           0);
   /*
   localparam P_FIFO_ADDR_WIDTH =
        (C_FIFO_TYPE == 2'b11) ?
        (((P_INPUT_DATA_WIDTH  == 128) || (P_OUTPUT_DATA_WIDTH == 128)) ? 13 :
         ((P_INPUT_DATA_WIDTH  ==  64) || (P_OUTPUT_DATA_WIDTH ==  64)) ? 12 :
         ((P_INPUT_DATA_WIDTH  ==  32) || (P_OUTPUT_DATA_WIDTH ==  32)) ? 11 :
                                                                           0) :
        (((P_INPUT_DATA_WIDTH  >=  64) || (P_OUTPUT_DATA_WIDTH >=  64)) ?  8 :
         ((P_INPUT_DATA_WIDTH  ==  32) || (P_OUTPUT_DATA_WIDTH ==  32)) ?  7 :
                                                                           0);
   
   */
   localparam P_PUSH_INC_VALUE = (P_INPUT_DATA_WIDTH ==   8) ?  1'd1 :
                                 (P_INPUT_DATA_WIDTH ==  16) ?  2'd2 :
                                 (P_INPUT_DATA_WIDTH ==  32) ?  3'd4 :
                                 (P_INPUT_DATA_WIDTH ==  64) ?  4'd8 :
                                 (P_INPUT_DATA_WIDTH == 128) ? 5'd16 :
                                                                1'd0;
   localparam P_POP_INC_VALUE = (P_OUTPUT_DATA_WIDTH ==   8) ?  1'd1 :
                                (P_OUTPUT_DATA_WIDTH ==  16) ?  2'd2 :
                                (P_OUTPUT_DATA_WIDTH ==  32) ?  3'd4 :
                                (P_OUTPUT_DATA_WIDTH ==  64) ?  4'd8 :
                                (P_OUTPUT_DATA_WIDTH == 128) ? 5'd16 :
                                                                1'd0;
   localparam P_PUSH_LSBS_MAX_BIT = (P_OUTPUT_DATA_WIDTH == 128) ? 3 :
                                    (P_OUTPUT_DATA_WIDTH ==  64) ? 2 :
                                                                   0;
   localparam P_PUSH_LSBS_MIN_BIT = (P_INPUT_DATA_WIDTH == 64) ? 3 :
                                    (P_INPUT_DATA_WIDTH == 32) ? 2 :
                                                                 0;
   localparam P_PUSH_LSBS_NUM_BITS = P_PUSH_LSBS_MAX_BIT-P_PUSH_LSBS_MIN_BIT+1;
   localparam P_FIFOADDR_MIN_BIT = 
            ((P_INPUT_DATA_WIDTH == 128) || (P_OUTPUT_DATA_WIDTH == 128)) ? 4 :
            ((P_INPUT_DATA_WIDTH ==  64) || (P_OUTPUT_DATA_WIDTH ==  64)) ? 3 :
            ((P_INPUT_DATA_WIDTH ==  32) || (P_OUTPUT_DATA_WIDTH ==  32)) ? 2 :
            ((P_INPUT_DATA_WIDTH ==  16) || (P_OUTPUT_DATA_WIDTH ==  16)) ? 1 :
                                                                            0;
   
   reg [P_FIFO_ADDR_WIDTH:0]  pushaddr;
   reg [P_FIFO_ADDR_WIDTH:0]  popaddr;
   reg [P_FIFO_ADDR_WIDTH:0]  pushaddr_r;
   reg                        next_push_is_word;
   
   // Calculate address for push counter
   generate
      if (((P_INPUT_DATA_WIDTH == 64) && 
           (P_DOUBLEWORD_XFER_SPECIAL_CASE == 1)) ||
          ((P_INPUT_DATA_WIDTH == 32) && 
           (P_WORD_XFER_SPECIAL_CASE == 1)))
        begin : gen_pushaddr_special_case
           reg [P_PUSH_LSBS_NUM_BITS-1:0] next_push_lsbs;
           wire [P_PUSH_LSBS_MAX_BIT+1:0] next_push_incvalue_tmp;
           reg [P_PUSH_LSBS_MAX_BIT+1:0]  next_push_incvalue;
           reg [P_FIFO_ADDR_WIDTH:0]      pushaddr_tmp;
           // Logic to skip addresses in data FIFO during word xfers
           // Special rules require word Push to occur after AddrAck for the
           // corresponding transfer.  Additionally  all push's for prior 
           // AddrAcks's must complete before the AddrReq corresponding to a
           // word transfer can be asserted.
           always @(posedge Clk) begin
             if (Rst)
               next_push_is_word <= 1'b0;
             else
               next_push_is_word <= (AddrAck & ~RNW & (Size == 4'h0)) | (next_push_is_word & ~(Flush | Push));
           end
           always @(posedge Clk) begin
              if (Rst)
                next_push_lsbs <= 0;
              else if (AddrAck & ~RNW)
                next_push_lsbs <= Addr[P_PUSH_LSBS_MAX_BIT:
                                       P_PUSH_LSBS_MIN_BIT];
           end
           assign next_push_incvalue_tmp = 
                    {1'b1,{P_PUSH_LSBS_MAX_BIT+1{1'b0}}} - 
                    {1'b0,Addr[P_PUSH_LSBS_MAX_BIT:P_PUSH_LSBS_MIN_BIT],
                     {P_PUSH_LSBS_MIN_BIT{1'b0}}};
           always @(posedge Clk) begin
              if (Rst)
                next_push_incvalue <= 0;
              else if (AddrAck & ~RNW)
                next_push_incvalue <= 
                             next_push_incvalue_tmp;
           end
           if (C_USE_INIT_PUSH) begin : gen_initpush
             always @(posedge Clk) begin
               if (Rst | Flush)
                 pushaddr_tmp <= 0;
               else if (Push & next_push_is_word)
                 pushaddr_tmp <= pushaddr + next_push_incvalue;
               else if (Push)
                 pushaddr_tmp <= pushaddr_tmp + P_PUSH_INC_VALUE;
               else if (InitPush)
                 pushaddr_tmp <= pushaddr_tmp + P_POP_INC_VALUE;
             end
           end else begin : gen_normal
             always @(posedge Clk) begin
               if (Rst | Flush)
                 pushaddr_tmp <= 0;
               else if (Push & next_push_is_word)
                 pushaddr_tmp <= pushaddr + next_push_incvalue;
               else if (Push)
                 pushaddr_tmp <= pushaddr_tmp + P_PUSH_INC_VALUE;
             end
           end
           always @(*) begin
              if (next_push_is_word)
                pushaddr <= 
                  {pushaddr_tmp[P_FIFO_ADDR_WIDTH:P_PUSH_LSBS_MAX_BIT+1],
                   next_push_lsbs,
                   pushaddr_tmp[P_PUSH_LSBS_MIN_BIT-1:0]};
              else
                pushaddr <= pushaddr_tmp;
              
           end
        end
      else
        begin : gen_pushaddr_normal
           always @(posedge Clk) begin
              next_push_is_word <= 1'b0;
           end
           if (C_USE_INIT_PUSH) begin : gen_initpush
             always @(posedge Clk) begin
               if (Rst | Flush)
                 pushaddr <= 0;
               else if (Push)
                 pushaddr <= pushaddr + P_PUSH_INC_VALUE;
               else if (InitPush)
                 pushaddr <= pushaddr + P_POP_INC_VALUE;
             end
           end else begin : gen_normal
             always @(posedge Clk) begin
               if (Rst | Flush)
                 pushaddr <= 0;
               else if (Push)
                 pushaddr <= pushaddr + P_PUSH_INC_VALUE;
             end
           end
        end
   endgenerate
   generate
      if (P_INPUT_PIPELINE == 1) begin : gen_pushaddr_pipeline
         always @(posedge Clk) begin
            pushaddr_r <= pushaddr;
         end
      end
      else begin : gen_pushaddr_nopipeline
         always @(*) begin
            pushaddr_r <= pushaddr;
         end
      end
   endgenerate
   // Calculate address for pop counter
   always @(posedge Clk) begin
      if (Rst | Flush)
        popaddr <= 0;
      else if (Pop && ~Empty)
        popaddr <= popaddr + P_POP_INC_VALUE;
   end
   
   // Calculate empty flag
   assign Empty = (pushaddr_r[P_FIFO_ADDR_WIDTH:P_FIFOADDR_MIN_BIT] == 
                   popaddr[P_FIFO_ADDR_WIDTH:P_FIFOADDR_MIN_BIT]) ? 
                  1'b1 : 
                  1'b0;

   // Calculate almost full flag
   generate
      if (C_FIFO_TYPE == 2'b10) begin : gen_almostfull_srl
         wire [P_FIFO_ADDR_WIDTH:0] fifoaddr;
         assign fifoaddr = pushaddr - popaddr;
         assign AlmostFull = 
                        ((fifoaddr > 
                          (2**P_FIFO_ADDR_WIDTH - P_PUSH_INC_VALUE)) ||
                         (Push && 
                          (fifoaddr > 
                           (2**P_FIFO_ADDR_WIDTH - 2*P_PUSH_INC_VALUE)))) ?
                             1'b1 : 1'b0;
      end
      else begin : gen_almostfull_bram
         // NPI cannot request more data than is possible for BRAM to hold.
         assign AlmostFull = 1'b0;
      end
   endgenerate

   // Instantiate FIFO
   generate
      if (C_FIFO_TYPE == 2'b11) begin : gen_fifo_bram
         mpmc_bram_fifo #
           (
            .C_FAMILY            (C_FAMILY),
            .C_INPUT_PIPELINE    (P_INPUT_PIPELINE),
            .C_OUTPUT_PIPELINE   (P_OUTPUT_PIPELINE),
            .C_ADDR_WIDTH        (P_FIFO_ADDR_WIDTH),
            .C_INPUT_DATA_WIDTH  (P_INPUT_DATA_WIDTH),
            .C_OUTPUT_DATA_WIDTH (P_OUTPUT_DATA_WIDTH),
            .C_DIRECTION         ("write"),
            .C_USE_INIT_PUSH     (C_USE_INIT_PUSH)
            )
           mpmc_bram_fifo_0
             (
              .PushClk    (Clk),
              .PushAddr   (pushaddr[P_FIFO_ADDR_WIDTH-1:0]),
              .Push       (Push),
              .PushData   (PushData),
              .PushParity (PushBE),
              .InitPush   (InitPush),
              .InitData   (InitData),
              .PopClk     (Clk),
              .PopAddr    (popaddr[P_FIFO_ADDR_WIDTH-1:0]),
              .Pop        (Pop && ~Empty),
              .ParityRst  (BE_Rst),
              .PopData    (PopData),
              .PopParity  (PopBE)
              );
      end
      else begin : gen_fifo_srl
         mpmc_srl_fifo #
           (
            .C_FAMILY            (C_FAMILY),
            .C_INPUT_PIPELINE    (P_INPUT_PIPELINE),
            .C_OUTPUT_PIPELINE   (P_OUTPUT_PIPELINE),
            .C_ADDR_WIDTH        (P_FIFO_ADDR_WIDTH),
            .C_INPUT_DATA_WIDTH  (P_INPUT_DATA_WIDTH),
            .C_OUTPUT_DATA_WIDTH (P_OUTPUT_DATA_WIDTH),
            .C_DIRECTION         ("write"),
            .C_USE_INIT_PUSH     (C_USE_INIT_PUSH)
            )
           mpmc_srl_fifo_0
             (
              .Clk             (Clk),
              .Rst             (Rst | Flush),
              .SpecialCaseXfer (next_push_is_word),
              .PushAddr        (pushaddr[P_FIFO_ADDR_WIDTH-1:0]),
              .Push            (Push),
              .PushData        (PushData),
              .PushParity      (PushBE),
              .InitDone        (InitDone),
              .InitPush        (InitPush),
              .InitData        (InitData),
              .PopAddr         (popaddr[P_FIFO_ADDR_WIDTH-1:0]),
              .Pop             (Pop && ~Empty),
              .ParityRst       (BE_Rst),
              .PopData         (PopData),
              .PopParity       (PopBE)
              );
      end
   endgenerate
   
endmodule // mpmc_write_fifo

