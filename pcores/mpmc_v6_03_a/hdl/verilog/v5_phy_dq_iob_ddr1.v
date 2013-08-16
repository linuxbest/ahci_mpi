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
//Purpose:
//   This module places the data in the IOBs.
//Reference:
//Revision History:
//   Jul 18 2008: Merged MIG 2.3 modifications into this file.
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

module v5_phy_dq_iob_ddr1 #
  (
   parameter HIGH_PERFORMANCE_MODE = "TRUE",
   parameter IODELAY_GRP           = "IODELAY_MIG"
   )
  (
   input  clk90,
   input  rst90,
   input  dlyinc,
   input  dlyce,
   input  dlyrst,
   input  dq_oe_n,
   input  dqs,
   input  wr_data_rise,
   input  wr_data_fall,
   output rd_data_rise,
   output rd_data_fall,
   inout  ddr_dq
   );

  wire    dq_in;
  wire    dq_oe_n_r;
  wire    dq_out;
  wire    iserdes_clk;
  wire    iserdes_clkb;

  // on a write, rising edge of DQS corresponds to rising edge of CLK180
  // (aka falling edge of CLK0 -> rising edge DQS). We also know:
  //  1. data must be driven 1/4 clk cycle before corresponding DQS edge
  //  2. first rising DQS edge driven on falling edge of CLK0
  //  3. rising data must be driven 1/4 cycle before falling edge of CLK0
  //  4. therefore, rising data driven on rising edge of CLK90
  ODDR #
    (
     .SRTYPE("SYNC"),
     .DDR_CLK_EDGE("SAME_EDGE")
     )
    u_oddr_dq
      (
       .Q  (dq_out),
       .C  (clk90),
       .CE (1'b1),
       .D1 (wr_data_rise),
       .D2 (wr_data_fall),
       .R  (1'b0),
       .S  (1'b0)
       );

  // make sure output is tri-state during reset (DQ_OE_N_R = 1)
  (* IOB = "FORCE" *) FDPE u_tri_state_dq
    (
     .D    (dq_oe_n),
     .PRE  (rst90),
     .C    (clk90),
     .Q    (dq_oe_n_r),
     .CE   (1'b1)
     ) /* synthesis syn_useioff = 1 */;

  IOBUF u_iobuf_dq
    (
     .I  (dq_out),
     .T  (dq_oe_n_r),
     .IO (ddr_dq),
     .O  (dq_in)
     );

 // (* IODELAY_GROUP = IODELAY_GRP *) IODELAY #
    IODELAY #
    (
     .DELAY_SRC("I"),
     .IDELAY_TYPE("VARIABLE"),
     .HIGH_PERFORMANCE_MODE(HIGH_PERFORMANCE_MODE),
     .IDELAY_VALUE(0),
     .ODELAY_VALUE(0)
     )
    u_idelay_dq
      (
       .DATAOUT(dq_idelay),
       .C(clk90),
       .CE(dlyce),
       .DATAIN(),
       .IDATAIN(dq_in),
       .INC(dlyinc),
       .ODATAIN(),
       .RST(dlyrst),
       .T()
       );

  // equalize delays to avoid delta-delay issues
  assign  iserdes_clk  = dqs;
  assign  iserdes_clkb = ~dqs;

  ISERDES_NODELAY #
    (
     .BITSLIP_ENABLE("FALSE"),
     .DATA_RATE("DDR"),
     .DATA_WIDTH(4),
     .INTERFACE_TYPE("MEMORY"),
     .NUM_CE(2),
     .SERDES_MODE("MASTER")
     )
    u_iserdes_dq
      (
       .Q1           (rd_data_fall),
       .Q2           (rd_data_rise),
       .Q3           (),
       .Q4           (),
       .Q5           (),
       .Q6           (),
       .SHIFTOUT1    (),
       .SHIFTOUT2    (),
       .BITSLIP      (),
       .CE1          (1'd1),
       .CE2          (1'd1),
       .CLK          (iserdes_clk),
       .CLKB         (iserdes_clkb),
       .CLKDIV       (clk90),
       .D            (dq_idelay),
       .OCLK         (clk90),
       .RST          (rst90),
       .SHIFTIN1     (),
       .SHIFTIN2     ()
       );

endmodule
