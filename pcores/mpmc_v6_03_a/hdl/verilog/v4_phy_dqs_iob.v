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

`timescale 1ns/1ps

module v4_phy_dqs_iob#
  (
   parameter integer DQSN_ENABLE       = 1,
   parameter integer DDR2_ENABLE       = 1,
   parameter READ_WIRE_DELAY           = 0
   )
  (
   input  CLK,
   input  RESET,
   input  CTRL_DQS_RST,
   input  CTRL_DQS_EN,
   inout  DDR_DQS_L,
   inout  DDR_DQS
   );
  
  wire    dqs_in;
  wire    dqs_out;
  wire    ctrl_dqs_en_r1;
  wire    vcc;
  wire    gnd;
  wire    clk180;
  reg     data1;
  reg     RESET_r1;

  assign vcc    = 1'b1;
  assign gnd    = 1'b0;
  assign clk180 = ~CLK;
  
  always @( posedge CLK )
    RESET_r1 <= RESET;
  
  always @ (posedge clk180) begin
    if (CTRL_DQS_RST == 1'b1)
      data1 <= 1'b0;
    else
      data1 <= 1'b1;
  end
  
  ODDR #
    (
     .SRTYPE       ("SYNC"),
     .DDR_CLK_EDGE ("OPPOSITE_EDGE")
     )
    oddr_dqs
      (
       .Q  (dqs_out),
       .C  (clk180),
       .CE (vcc),
       .D1 (data1),
       .D2 (gnd),
       .R  (gnd),
       .S  (gnd)
       );
  
  (* IOB = "FORCE" *) FDS tri_state_dqs
    (
     .Q   (ctrl_dqs_en_r1),
     .C   (clk180),
     .D   (CTRL_DQS_EN),
     .S   (RESET_r1)
     )/* synthesis syn_useioff = 1 */;
  
  
  generate
    if (DDR2_ENABLE) begin: gen_dqs_iob_ddr2
      if (DQSN_ENABLE == 1) begin : gen_dqsn_diff
        IOBUFDS iobuf_dqs
          (
           .O   (dqs_in),
           .IO  (DDR_DQS),
           .IOB (DDR_DQS_L),
           .I   (dqs_out),
           .T   (ctrl_dqs_en_r1)
           );
      end
      else
        begin : gen_dqsn_nodiff
          IOBUF iobuf_dqs
            (
             
             .IO (DDR_DQS),
             .I  (dqs_out),
             .T  (ctrl_dqs_en_r1),
             .O  (dqs_in)
             );
          assign DDR_DQS_L = 1'b1;
        end
    end else begin: gen_dqs_iob_ddr1
      IOBUF u_iobuf_dqs
        (
         .O  (dqs_in),
         .IO (DDR_DQS),
         .I  (dqs_out),
         .T  (ctrl_dqs_en_r1)
         );
    end
  endgenerate
  
endmodule
