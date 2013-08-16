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
// Description: Logic to create pattern start signal from arbiter to 
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
module arb_pattern_start #
  (
   parameter C_FAMILY                  = "virtex4",
   parameter C_NUM_PORTS               = 8,
   parameter C_ARB_PORT_ENCODING_WIDTH = 3,
   parameter C_CP_PIPELINE             = 0,
   parameter C_ARB_PIPELINE            = 1,
   parameter C_ARB0_ALGO               = "ROUND_ROBIN"
   )
  (
   input                                             Clk,
   input                                             Rst,
   input [C_NUM_PORTS-1:0]                           PI_ReqPending,
   input                                             Ctrl_Idle,
   input                                             Ctrl_Maint,
   input                                             Ctrl_Complete,
   input [C_NUM_PORTS*C_ARB_PORT_ENCODING_WIDTH-1:0] Arb_PortNum,
   output                                            Arb_PatternStart_i,
   output reg                                        Arb_PatternStart = 0
   );
   
  reg                    ctrl_complete_d1 = 0;
  wire                   pi_arbpatternstart_i1;
  wire                   pi_arbpatternstart_i1a;
  reg                    pi_arbpatternstart_i2 = 0;
  reg                    arb_patternstart_ce = 0;
  reg                    ctrl_maint_i1 = 0;
  reg                    ctrl_maint_i2 = 0;
  wire                   ctrl_maint_p;
  wire                   arb_patternstart_i1;
  
  genvar i;

  always @(posedge Clk) begin
    ctrl_complete_d1 <= Ctrl_Complete;
  end
  
  always @(Ctrl_Idle or ctrl_complete_d1) begin
    arb_patternstart_ce = Ctrl_Idle | ctrl_complete_d1;
  end

  generate
    if ((C_ARB0_ALGO == "ROUND_ROBIN") || (C_ARB0_ALGO == "FIXED")) begin : inst_fixed_arb_algo
      reg pi_arbpatternstart_i1_tmp;
      always @(posedge Clk) begin
        if (Rst)
          pi_arbpatternstart_i1_tmp <= 1'b0;
        else if (arb_patternstart_ce)
          pi_arbpatternstart_i1_tmp <= | PI_ReqPending;
      end
      assign pi_arbpatternstart_i1 = pi_arbpatternstart_i1_tmp;
    end
    else if (C_ARB0_ALGO == "CUSTOM") begin : inst_custom_arb_algo
      wire [C_NUM_PORTS-1:0] arb_patternenable;

      // Instantiate per port muxes for the sequence pattern start
      for (i=0;i<C_NUM_PORTS;i=i+1) begin : instantiate_arb_req_pending_muxes
        arb_req_pending_muxes 
          #(
            .C_NUM_PORTS (C_NUM_PORTS),
            .C_ARB_PORT_ENCODING_WIDTH (C_ARB_PORT_ENCODING_WIDTH)
            )
            arb_req_pending_muxes_
              (
               .Arb_ReqPending (PI_ReqPending),
               .Arb_PortNum (Arb_PortNum[i*C_ARB_PORT_ENCODING_WIDTH+
                                         C_ARB_PORT_ENCODING_WIDTH-1:
                                         i*C_ARB_PORT_ENCODING_WIDTH]),
               .Arb_PatternEnable (arb_patternenable[i])
               );
      end
      
      // Instantiate FFs to select the highest priority port
      high_priority_select
        #(
          .C_FAMILY(C_FAMILY),
          .C_NUM_PORTS(C_NUM_PORTS),
          .C_PI_D_WIDTH(1)
          )
          high_priority_select_0
            (
             .Clk    (Clk),
             .Rst    (Rst),
             .PI_D   (arb_patternenable),
             .PI_CE  (arb_patternstart_ce),
             .PI_Rst ({C_NUM_PORTS{1'b0}}),
             .Q      (pi_arbpatternstart_i1)
             );
  
    end
  endgenerate

  always @(posedge Clk) ctrl_maint_i1 <= Ctrl_Idle & Ctrl_Maint;
  always @(posedge Clk) ctrl_maint_i2 <= ctrl_maint_i1;
  assign ctrl_maint_p = ctrl_maint_i1 & ~ctrl_maint_i2;
  
  assign pi_arbpatternstart_i1a = pi_arbpatternstart_i1 & ~ctrl_complete_d1;
 
  always @(posedge Clk)
    pi_arbpatternstart_i2 <= pi_arbpatternstart_i1a;

  assign arb_patternstart_i1 = (pi_arbpatternstart_i1 & ~pi_arbpatternstart_i2)
                               | (ctrl_maint_p);
  assign Arb_PatternStart_i = arb_patternstart_i1; 

  generate
    if (C_CP_PIPELINE==0) begin : patternstart_nopipeline
      always @(Arb_PatternStart_i) begin
        Arb_PatternStart <= Arb_PatternStart_i;
      end
    end
    else begin : patternstart_pipeline
      always @(posedge Clk) begin
        Arb_PatternStart <= Arb_PatternStart_i;
      end
    end
  endgenerate

endmodule // arb_pattern_start

