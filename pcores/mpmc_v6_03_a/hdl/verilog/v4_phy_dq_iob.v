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

module v4_phy_dq_iob #
  (
   parameter READ_WIRE_DELAY = 0
   )
  (
   input       CLK,
   input       CLK90,
   input       RESET0,
   input       DATA_DLYINC,
   input       DATA_DLYCE,
   input       DATA_DLYRST,
   input       WRITE_DATA_RISE,
   input       WRITE_DATA_FALL,
   input [1:0] CTRL_WREN,
   input       DELAY_ENABLE,
   output      RD_DATA_RISE,
   output      RD_DATA_FALL,
   inout       DDR_DQ
   );

   wire        dq_in;
   wire        dq_out;
   wire        dq_delayed;
   wire [1:0]  write_en_L;
   wire        write_en_L_r1;
   wire        dq_q1;
   wire        dq_q1_r;
   wire        dq_q2;
   wire        vcc;
   wire        gnd;
   reg         reset0_r1
            /* synthesis syn_preserve=1 */;

  //*******************************************************************

  assign vcc = 1'b1;
  assign gnd = 1'b0;
  assign write_en_L = ~CTRL_WREN;

   always @( posedge CLK )
     reset0_r1 <= RESET0;

  ODDR #
    (
     .DDR_CLK_EDGE ("SAME_EDGE"),
     .SRTYPE       ("SYNC")
     )
    oddr_dq
      (
       .Q  (dq_out),
       .C  (CLK90),
       .CE (vcc),
       .D1 (WRITE_DATA_RISE),
       .D2 (WRITE_DATA_FALL),
       .R  (gnd),
       .S  (gnd)
       );

   // 3-state enable for the data I/O generated such that to enable
   // write data output one-half clock cycle before
   // the first data word, and disable the write data
   // one-half clock cycle after the last data word
   ODDR #
     (
      .DDR_CLK_EDGE ("SAME_EDGE"),
      .SRTYPE       ("ASYNC")
      )
     tri_state_dq
       (
        .Q    (write_en_L_r1),
        .C    (CLK90),
        .CE   (vcc),
        .D1   (write_en_L[0]),
        .D2   (write_en_L[1]),
        .R    (gnd),
        .S    (gnd)
        );

  IOBUF  iobuf_dq
    (
     .I  (dq_out),
     .T  (write_en_L_r1),
     .IO (DDR_DQ),
     .O  (dq_in)
     );

  IDELAY #
    (
     .IOBDELAY_TYPE  ("VARIABLE"),
     .IOBDELAY_VALUE (0)
     )   
    idelay_dq
      (
       .O   (dq_delayed),
       .I   (dq_in),
       .C   (CLK),
       .CE  (DATA_DLYCE),
       .INC (DATA_DLYINC),
       .RST (DATA_DLYRST)
       );

  IDDR #
    (
     .DDR_CLK_EDGE ("SAME_EDGE"),
     .SRTYPE       ("SYNC")
     )
    iddr_dq
      (
       .Q1 (dq_q1),
       .Q2 (dq_q2),
       .C  (CLK),
       .CE (vcc),
       .D  (dq_delayed),
       .R  (gnd),
       .S  (gnd)
       );
  
  //*******************************************************************
  // RC: Optional circuit to delay the bit by one bit time - may be
  // necessary if there is bit-misalignment (e.g. rising edge of FPGA
  // clock may be capturing bit[n] for DQ[0] but bit[n+1] for DQ[1])
  // within a DQS group. The operation for delaying by one bit time
  // involves delaying the Q1 (rise) output of the IDDR, and "flipping"
  // the Q bits
  //*******************************************************************
  
  FDRSE u_fd_dly_q1
    (
     .Q    (dq_q1_r),
     .C    (CLK),
     .CE   (vcc),
     .D    (dq_q1),
     .R    (gnd),
     .S    (gnd)
     );
  
  assign RD_DATA_RISE = DELAY_ENABLE ? dq_q2   : dq_q1;
  assign RD_DATA_FALL = DELAY_ENABLE ? dq_q1_r : dq_q2;  

endmodule
