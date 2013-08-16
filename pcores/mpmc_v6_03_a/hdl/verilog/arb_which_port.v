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
// Description: Logic to select which port is currently active in the
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
module arb_which_port #
  (                  
   parameter C_FAMILY                          = "virtex4",
   parameter C_USE_INIT_PUSH                   = 0,
   parameter C_NUM_PORTS                       = 8,
   parameter C_ARB_PORT_ENCODING_WIDTH         = 3,
   parameter C_ARB_PIPELINE                    = 1,
   parameter C_CP_PIPELINE                     = 0,
   parameter C_PORT_FOR_WRITE_TRAINING_PATTERN = 3'b001,
   parameter C_ARB0_ALGO                       = "ROUND_ROBIN"
   )
  (
   input                                            Clk,
   input                                            Rst,
   input [C_NUM_PORTS-1:0]                          PI_ReqPending,
   input                                            PhyIF_Ctrl_InitDone,
   input                                            Ctrl_Idle,
   input                                            Ctrl_Complete,
   input [C_NUM_PORTS*C_ARB_PORT_ENCODING_WIDTH-1:0]Arb_PortNum,
   output wire [C_ARB_PORT_ENCODING_WIDTH-1:0]      Arb_WhichPort_i,
   output wire [C_NUM_PORTS-1:0]                    Arb_WhichPort_Decode_i,
   output reg [C_ARB_PORT_ENCODING_WIDTH-1:0]       Arb_WhichPort = 0,
   output reg [C_NUM_PORTS-1:0]                     Arb_WhichPort_Decode = 0
   );

   reg                                               arb_whichport_ce = 0;
   reg [C_NUM_PORTS-1:0]                             arb_whichport_rst = 0;
   wire [C_NUM_PORTS-1:0]                            arb_patternenable;
   wire [C_NUM_PORTS*C_ARB_PORT_ENCODING_WIDTH-1:0]  arb_whichport_i1;
   
   genvar i;
   
   localparam P_WHICHPORT_RESET = 
             (C_PORT_FOR_WRITE_TRAINING_PATTERN == 0) ? 1  :
             (C_PORT_FOR_WRITE_TRAINING_PATTERN == 1) ? 2  :
             (C_PORT_FOR_WRITE_TRAINING_PATTERN == 2) ? 4  :
             (C_PORT_FOR_WRITE_TRAINING_PATTERN == 3) ? 8  :
             (C_PORT_FOR_WRITE_TRAINING_PATTERN == 4) ? 16 :
             (C_PORT_FOR_WRITE_TRAINING_PATTERN == 5) ? 32 :
             (C_PORT_FOR_WRITE_TRAINING_PATTERN == 6) ? 64 :
                                                        128;

  // Instantiate Muxes
  generate
    for (i=0;i<C_NUM_PORTS;i=i+1) begin : instantiate_arb_req_pending_muxes
      if (C_ARB0_ALGO == "FIXED") begin : inst_fixed_arb_algo
        assign arb_patternenable[i] = PI_ReqPending[i];
      end
      else begin : inst_custom_arb_algo
        arb_req_pending_muxes 
          #(
            .C_NUM_PORTS (C_NUM_PORTS),
            .C_ARB_PORT_ENCODING_WIDTH (C_ARB_PORT_ENCODING_WIDTH)
            )
            arb_req_pending_muxes_
              (
               .Arb_ReqPending (PI_ReqPending),
               .Arb_PortNum (Arb_PortNum[i*C_ARB_PORT_ENCODING_WIDTH+C_ARB_PORT_ENCODING_WIDTH-1:i*C_ARB_PORT_ENCODING_WIDTH]),
               .Arb_PatternEnable (arb_patternenable[i])
               );
      end
      assign arb_whichport_i1[(i+1)*C_ARB_PORT_ENCODING_WIDTH-1:
                              i*C_ARB_PORT_ENCODING_WIDTH] = 
                  Arb_PortNum[(i+1)*C_ARB_PORT_ENCODING_WIDTH-1:
                              i*C_ARB_PORT_ENCODING_WIDTH] & 
                  {C_ARB_PORT_ENCODING_WIDTH{arb_patternenable[i]}};
    end
  endgenerate

  // Instantiate FFs to select the highest priority port
  reg ctrl_complete_d1 = 0;
  always @(posedge Clk) begin
    ctrl_complete_d1 <= Ctrl_Complete;
  end
  
  always @(Ctrl_Idle or ctrl_complete_d1) begin
    arb_whichport_ce = Ctrl_Idle | ctrl_complete_d1;
  end

  always @(arb_patternenable) begin
    arb_whichport_rst <= (arb_patternenable << 1);
  end

  generate
    if (C_NUM_PORTS == 1) begin : instantiate_Arb_WhichPort_i_1port
      assign Arb_WhichPort_i = 1'b0;
    end
    else begin : instantiate_Arb_WhichPort_i_2to8ports
      high_priority_select
        #(
          .C_FAMILY(C_FAMILY),
          .C_NUM_PORTS(C_NUM_PORTS),
          .C_PI_D_WIDTH(C_ARB_PORT_ENCODING_WIDTH)
          )
          high_priority_select_0
            (
             .Clk    (Clk),
             .Rst    (Rst),
             .PI_D   (arb_whichport_i1),
             .PI_CE  (arb_whichport_ce),
             .PI_Rst (arb_whichport_rst),
             .Q      (Arb_WhichPort_i)
             );
    end
  endgenerate
  
  // Create One-Hot encoded version of Arb_Which_Port_i
  port_encoder #(
    .C_NUM_PORTS        (C_NUM_PORTS),
    .C_PORT_WIDTH       (C_ARB_PORT_ENCODING_WIDTH)
  ) 
  arb_whichport_encoder (
    .Port               (Arb_WhichPort_i),
    .Port_Encode        (Arb_WhichPort_Decode_i)
  );

  generate
    if (C_CP_PIPELINE==0) begin : whichport_nopipeline
      if (C_USE_INIT_PUSH) begin : gen_arb_whichport_wtp
        always @(Arb_WhichPort_i) begin
          if (~PhyIF_Ctrl_InitDone)
            Arb_WhichPort <= C_PORT_FOR_WRITE_TRAINING_PATTERN;
          else    
            Arb_WhichPort <= Arb_WhichPort_i;
        end
        always @(Arb_WhichPort_Decode_i) begin
          if (~PhyIF_Ctrl_InitDone)
            Arb_WhichPort_Decode <= P_WHICHPORT_RESET;
          else
            Arb_WhichPort_Decode <= Arb_WhichPort_Decode_i;
        end
      end
      else begin : gen_arb_whichport
        always @(Arb_WhichPort_i) begin
          Arb_WhichPort <= Arb_WhichPort_i;
        end
        always @(Arb_WhichPort_Decode_i) begin
          Arb_WhichPort_Decode <= Arb_WhichPort_Decode_i;
        end
      end
    end
    else begin : whichport_pipeline
      if (C_USE_INIT_PUSH) begin : gen_arb_whichport_wtp
        always @(posedge Clk) begin
          if (~PhyIF_Ctrl_InitDone)
            Arb_WhichPort <= C_PORT_FOR_WRITE_TRAINING_PATTERN;
          else    
                 Arb_WhichPort <= Arb_WhichPort_i;
        end
        always @(posedge Clk) begin
          if (~PhyIF_Ctrl_InitDone)
            Arb_WhichPort_Decode <= P_WHICHPORT_RESET;
          else            
            Arb_WhichPort_Decode <= Arb_WhichPort_Decode_i;
        end
      end
      else begin : gen_pi_wrfifo_data
        always @(posedge Clk) begin
          Arb_WhichPort <= Arb_WhichPort_i;
        end
        always @(posedge Clk) begin
          Arb_WhichPort_Decode <= Arb_WhichPort_Decode_i;
        end
      end
    end
  endgenerate
   
endmodule // arb_which_port

