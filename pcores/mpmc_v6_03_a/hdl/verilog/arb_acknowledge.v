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
// Description: Logic to create PI_AddrAck signal.
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

module arb_acknowledge
  (
   Clk,                       // I
   Rst,                       // I
   PI_AddrReq,                // I [C_NUM_PORTS-1:0]
   PI_AddrAck,                // O [C_NUM_PORTS-1:0]
   PI_RNW,                    // I [C_NUM_PORTS-1:0]
   PI_ReqPending,             // O [C_NUM_PORTS-1:0]
   DP_Ctrl_RdFIFO_AlmostFull, // I [C_NUM_PORTS-1:0]
   Ctrl_AP_Pipeline1_CE,      // I
   Arb_WhichPort_Decode,      // I [C_NUM_PORTS-1:0]
   Ctrl_InitializeMemory      // I
   );
   
   parameter C_NUM_PORTS = 8;              // Allowed Values: 1-8
   parameter C_PIPELINE_ADDRACK = 8'h00;   // Allowed Values: 8'h00-8'hFF, each
                                           // bit corresponds to an individual port.
   parameter C_MAX_REQ_ALLOWED_INT = 2;        // Allowed Values: Any integer
   parameter C_REQ_PENDING_CNTR_WIDTH = 2; // Allowed Values: Such that counter 
                                           // does not overflow when max pending 
                                           // instruction are acknowledged
   parameter C_ARB_PIPELINE = 1;         // Allowed values: 0 or 1
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
   input                                             Clk;
   input                                             Rst;
   input [C_NUM_PORTS-1:0]                           PI_AddrReq;
   input [C_NUM_PORTS-1:0]                           PI_RNW;
   output [C_NUM_PORTS-1:0]                          PI_AddrAck;
   output [C_NUM_PORTS-1:0]                          PI_ReqPending;
   input [C_NUM_PORTS-1:0]                           DP_Ctrl_RdFIFO_AlmostFull;
   input                                             Ctrl_AP_Pipeline1_CE;
   input [C_NUM_PORTS-1:0]                           Arb_WhichPort_Decode;
   input                                             Ctrl_InitializeMemory;

   reg [C_NUM_PORTS-1:0]                             PI_AddrAck = 0;
   reg [C_NUM_PORTS-1:0]                             PI_AddrAck_i = 0;
   wire [C_NUM_PORTS-1:0]                            pi_addrack_i1;
   reg [C_NUM_PORTS-1:0]                             pi_addrack_i2 = 0;
   reg [C_NUM_PORTS-1:0]                             PI_ReqPending = 0;
   wire [C_NUM_PORTS-1:0]                            pi_reqallowed;
   reg [C_NUM_PORTS*C_REQ_PENDING_CNTR_WIDTH-1:0]    pi_reqpending_cnt = 0;
   reg [C_NUM_PORTS-1:0]                             pi_reqpending_rst = 0;
   reg [C_NUM_PORTS-1:0]                             pi_reqpending_i = 0;
   wire [C_NUM_PORTS-1:0]                            pi_reqpending_p1;

   genvar i;
   
   // Implementation for PI_AddrAck
   assign pi_addrack_i1 = PI_AddrReq & pi_reqallowed & ~{C_NUM_PORTS{Ctrl_InitializeMemory}} & ((PI_RNW & ~DP_Ctrl_RdFIFO_AlmostFull) | ~PI_RNW);
   generate
      for (i=0;i<C_NUM_PORTS;i=i+1) begin : implement_addrack_optional_reg
         always @(posedge Clk)
           if (pi_addrack_i2[i])
             pi_addrack_i2[i] <= 1'b0;
           else
             pi_addrack_i2[i] <= pi_addrack_i1[i];
      end
   endgenerate

   generate
      for (i=0;i<C_NUM_PORTS;i=i+1) begin : implement_addrack
         always @(pi_addrack_i2 or pi_addrack_i1) begin
            if (|(C_PIPELINE_ADDRACK & (8'h01 << i)))
              PI_AddrAck_i[i] <= pi_addrack_i2[i];
            else
              PI_AddrAck_i[i] <= pi_addrack_i1[i];
         end
         always @(PI_AddrAck_i or PI_AddrReq)
           if (|(C_PIPELINE_ADDRACK & (8'h01 << i)))
             PI_AddrAck[i] <= PI_AddrAck_i[i] & PI_AddrReq[i];
           else
             PI_AddrAck[i] <= PI_AddrAck_i[i];
      end
   endgenerate

   // Implementation for PI_ReqPending

   generate
      for (i=0;i<C_NUM_PORTS;i=i+1) begin : implement_reqpending_cntr
         always @(posedge Clk) begin
            if (Rst)
              pi_reqpending_cnt[(i+1)*C_REQ_PENDING_CNTR_WIDTH-1:i*C_REQ_PENDING_CNTR_WIDTH] <= 0;
            else if (PI_AddrAck[i] & Ctrl_AP_Pipeline1_CE & Arb_WhichPort_Decode[i])
              pi_reqpending_cnt[(i+1)*C_REQ_PENDING_CNTR_WIDTH-1:i*C_REQ_PENDING_CNTR_WIDTH] <= pi_reqpending_cnt[(i+1)*C_REQ_PENDING_CNTR_WIDTH-1:i*C_REQ_PENDING_CNTR_WIDTH];
            else if (PI_AddrAck[i])
              pi_reqpending_cnt[(i+1)*C_REQ_PENDING_CNTR_WIDTH-1:i*C_REQ_PENDING_CNTR_WIDTH] <= pi_reqpending_cnt[(i+1)*C_REQ_PENDING_CNTR_WIDTH-1:i*C_REQ_PENDING_CNTR_WIDTH] + 1'b1;
            else if (Ctrl_AP_Pipeline1_CE & Arb_WhichPort_Decode[i])
              pi_reqpending_cnt[(i+1)*C_REQ_PENDING_CNTR_WIDTH-1:i*C_REQ_PENDING_CNTR_WIDTH] <= pi_reqpending_cnt[(i+1)*C_REQ_PENDING_CNTR_WIDTH-1:i*C_REQ_PENDING_CNTR_WIDTH] - 1'b1;
            else
              pi_reqpending_cnt[(i+1)*C_REQ_PENDING_CNTR_WIDTH-1:i*C_REQ_PENDING_CNTR_WIDTH] <= pi_reqpending_cnt[(i+1)*C_REQ_PENDING_CNTR_WIDTH-1:i*C_REQ_PENDING_CNTR_WIDTH];
         end
      end
   endgenerate

   generate
      for (i=0;i<C_NUM_PORTS;i=i+1) begin : implement_reqpending_comp
         always @(pi_reqpending_cnt) begin
           pi_reqpending_rst[i] <= (pi_reqpending_cnt[(i+1)*C_REQ_PENDING_CNTR_WIDTH-1:i*C_REQ_PENDING_CNTR_WIDTH] == 0);
         end
      end
   endgenerate
   
   generate
      for (i=0;i<C_NUM_PORTS;i=i+1) begin : implement_reqpending
         always @(posedge Clk) begin
           pi_reqpending_i[i] <= PI_AddrAck[i] | (~(Rst | pi_reqpending_rst[i]) & pi_reqpending_i[i]);
         end
      end
   endgenerate

   assign pi_reqpending_p1 = pi_reqpending_i | PI_AddrAck;

   // pipeline helps meet timing on the arbiter on this critical path
   generate
     if (C_ARB_PIPELINE == 0) begin : no_pi_reqpending_pipeline
        always @(pi_reqpending_p1) begin
            PI_ReqPending = pi_reqpending_p1;
        end
     end
     else begin : pi_reqpending_pipeline
        always @(posedge Clk) begin
            PI_ReqPending <= pi_reqpending_p1;
        end
     end
   endgenerate

   // Implementation for pi_reqallowed
   generate
      for (i=0;i<C_NUM_PORTS;i=i+1) begin : implement_reqallowed
         assign pi_reqallowed[i] = ((pi_reqpending_cnt[(i+1)*C_REQ_PENDING_CNTR_WIDTH-1:i*C_REQ_PENDING_CNTR_WIDTH] < C_MAX_REQ_ALLOWED_INT));
      end
   endgenerate
   
endmodule // arb_acknowledge

