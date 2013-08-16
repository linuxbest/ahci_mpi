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

`timescale 1ns/100ps
`default_nettype none
`define ARBITRATE_TO_A ~Addr_Exists_A || Addr_Sel_FIFO_Full & Addr_RNW_A || Addr_Read_A ? IDLE : \
                        (Addr_RNW_A || C_XCL_A_WRITEXFER == 0) ? READ_A : \
                        Data_Exists_A & Data_Wr_Burst_A ? WR_CL_DATA_A : \
                        Data_Exists_A & ~Data_Wr_Burst_A ? WR_WD_ADDR_A : \
                        ~Data_Exists_Early_A ? IDLE : \
                        Data_Wr_Burst_Early_A ? WR_CL_DATA_A : WR_WD_ADDR_A

`define ARBITRATE_TO_B  (C_PI_B_SUBTYPE == "INACTIVE") ? IDLE : \
                        ~Addr_Exists_B || Addr_Sel_FIFO_Full & Addr_RNW_B || Addr_Read_B ? IDLE : \
                        (Addr_RNW_B || C_XCL_B_WRITEXFER == 0) ? READ_B : \
                        Data_Exists_B & Data_Wr_Burst_B ? WR_CL_DATA_B : \
                        Data_Exists_B & ~Data_Wr_Burst_B ? WR_WD_ADDR_B : \
                        ~Data_Exists_Early_B ? IDLE : \
                        Data_Wr_Burst_Early_B ? WR_CL_DATA_B : WR_WD_ADDR_B

module dualxcl_fsm
#(
  parameter C_PI_A_SUBTYPE              = "XCL",
  parameter C_PI_B_SUBTYPE              = "XCL",
  parameter C_XCL_A_WRITEXFER           = 1,
  parameter C_XCL_B_WRITEXFER           = 1,
  parameter C_XCL_A_LINESIZE            = 4,
  parameter C_XCL_B_LINESIZE            = 4,
  parameter C_MAX_CNTR_WIDTH            = 4

)
(
  input  wire                           Clk,
  input  wire                           Rst,

  output wire                           Addr_Sel_Push,
  output wire                           Addr_Sel_B,
  input  wire                           Addr_Sel_FIFO_Full,
  output wire                           Data_Sel_B,

  output wire                           Addr_Read_A,
  input  wire                           Addr_RNW_A,
  input  wire                           Addr_Exists_A,
  output wire                           Data_Read_A,
  input  wire                           Data_Wr_Burst_A,
  input  wire                           Data_Wr_Burst_Early_A,
  input  wire                           Data_Exists_A,
  input  wire                           Data_Exists_Early_A,

  output wire                           Addr_Read_B,
  input  wire                           Addr_RNW_B,
  input  wire                           Addr_Exists_B,
  output wire                           Data_Read_B,
  input  wire                           Data_Wr_Burst_B,
  input  wire                           Data_Wr_Burst_Early_B,
  input  wire                           Data_Exists_B,
  input  wire                           Data_Exists_Early_B,

  input  wire                           PI_InitDone,
  input  wire                           PI_AddrAck,
  output wire                           PI_AddrReq,
  input  wire                           PI_WrFIFO_AlmostFull,
  output wire                           PI_WrFIFO_Push

);

  // state machine states
  localparam   WAIT_FOR_INIT_DONE   = 5'h0F;
  localparam   IDLE                 = 5'h0E;
  localparam   FAIL                 = 5'h0D;

  localparam   READ_A               = 5'h00;
  localparam   WR_WD_ADDR_A         = 5'h01;
  localparam   WR_WD_DATA_A         = 5'h02;
  localparam   WR_CL_DATA_A         = 5'h03;
  localparam   WR_CL_ADDR_A         = 5'h05;

  localparam   READ_B               = 5'h10;
  localparam   WR_WD_ADDR_B         = 5'h11;
  localparam   WR_WD_DATA_B         = 5'h12;
  localparam   WR_CL_DATA_B         = 5'h13;
  localparam   WR_CL_ADDR_B         = 5'h15;

  reg                               wrfifo_full;
  (* fsm_encoding = "auto" *)
  reg  [4:0]                        state;
  reg  [4:0]                        next_state;
  reg  [C_MAX_CNTR_WIDTH-1:0]       push_count;
  reg                               addr_read_i_a;
  reg                               addr_read_i_b;
  wire                              pi_addrreq_a;
  reg                               pi_wrfifo_push_a;
  wire                              pi_addrreq_b;
  reg                               pi_wrfifo_push_b;

  always @(posedge Clk)
    wrfifo_full <= PI_WrFIFO_AlmostFull;

  always @(posedge Clk)
    if (Rst)
      state <= WAIT_FOR_INIT_DONE;
    else
      state <= next_state;

  always @(*)
  begin
    next_state = state;
    case (state)
      WAIT_FOR_INIT_DONE:
        if (PI_InitDone)
          next_state = IDLE;

      IDLE:
        begin
          if (C_PI_B_SUBTYPE != "INACTIVE")
            next_state = `ARBITRATE_TO_B;

          // If A is idle, then try to arbitrate to B
          if (next_state == IDLE)
            next_state = `ARBITRATE_TO_A;
        end

      READ_A:
        if (PI_AddrAck)
          next_state = `ARBITRATE_TO_B;

      WR_WD_ADDR_A:
        if (PI_AddrAck)
          next_state = WR_WD_DATA_A;

      WR_WD_DATA_A:
        next_state = `ARBITRATE_TO_B;

      WR_CL_DATA_A:
        if ((push_count == (C_XCL_A_LINESIZE-1)) && !wrfifo_full && Data_Exists_A)
          next_state = WR_CL_ADDR_A;

      WR_CL_ADDR_A:
        if (PI_AddrAck)
            next_state = `ARBITRATE_TO_B;

      READ_B:
        if (PI_AddrAck)
          next_state = `ARBITRATE_TO_A;

      WR_WD_ADDR_B:
        if (PI_AddrAck)
          next_state = WR_WD_DATA_B;

      WR_WD_DATA_B:
        next_state = `ARBITRATE_TO_A;

      WR_CL_DATA_B:
        if ((push_count == (C_XCL_B_LINESIZE-1)) && !wrfifo_full && Data_Exists_B)
          next_state = WR_CL_ADDR_B;

      WR_CL_ADDR_B:
        if (PI_AddrAck)
          next_state = `ARBITRATE_TO_A;

      FAIL:
        next_state = FAIL;

        default:
          next_state = FAIL;


    endcase
  end

  always @(posedge Clk)
  begin
    pi_wrfifo_push_a <= ((next_state == WR_CL_DATA_A)) || (next_state == WR_WD_DATA_A);
    pi_wrfifo_push_b <= ((next_state == WR_CL_DATA_B)) || (next_state == WR_WD_DATA_B);
  end

  assign pi_addrreq_a = (state == READ_A)
                      || (state == WR_WD_ADDR_A)
                      || (state == WR_CL_ADDR_A);

  always @(posedge Clk)
    addr_read_i_a <= PI_AddrAck && ~Addr_Sel_B;

  assign Addr_Read_A = addr_read_i_a;

  assign Data_Read_A = PI_WrFIFO_Push & ~Addr_Sel_B;


  generate
    if (C_PI_B_SUBTYPE != "INACTIVE")
    begin : XCL_B
      assign Addr_Sel_B         = (state == READ_B)
                                  || (state == WR_WD_ADDR_B)
                                  || (state == WR_WD_DATA_B)
                                  || (state == WR_CL_ADDR_B)
                                  || (state == WR_CL_DATA_B);

      assign Data_Sel_B         = (C_XCL_A_WRITEXFER == 0) ? 1 : 
                                  (C_PI_A_SUBTYPE == "IXCL") ? 1 :
                                  (C_PI_A_SUBTYPE == "IXCL2") ? 1 :
                                  (C_XCL_B_WRITEXFER == 0) ? 0 : 
                                  (C_PI_B_SUBTYPE == "IXCL") ? 0 :
                                  (C_PI_B_SUBTYPE == "IXCL2") ? 0 :
                                     (state == WR_WD_DATA_B)
                                  || (state == WR_CL_DATA_B)
                                  || (state == WR_CL_ADDR_B);

      assign pi_addrreq_b = (state == READ_B)
                          || (state == WR_WD_ADDR_B)
                          || (state == WR_CL_ADDR_B);

      always @(posedge Clk)
        addr_read_i_b <= PI_AddrAck && Addr_Sel_B;

      assign Addr_Read_B = addr_read_i_b;



      assign Data_Read_B = (PI_WrFIFO_Push & Addr_Sel_B);

    end
    else
    begin : NO_XCL_B
      assign Addr_Sel_B         = 1'b0;
      assign Data_Sel_B         = 1'b0;
      assign pi_addrreq_b       = 1'b0;
      assign Addr_Read_B        = 1'b0;
      assign Data_Read_B        = 1'b0;
    end
  endgenerate



  assign Addr_Sel_Push = (state == READ_A && PI_AddrAck)
                         || (state == READ_B && PI_AddrAck);
  always @(posedge Clk)
    if (state == IDLE || state == WR_WD_DATA_A || state == WR_WD_DATA_B
        || state == WR_CL_ADDR_A || state == WR_CL_ADDR_B 
        || state == WAIT_FOR_INIT_DONE)
      push_count <= 4'b0;
    else if (PI_WrFIFO_Push)
      push_count <= push_count + 1'b1;

  assign PI_WrFIFO_Push = ((pi_wrfifo_push_a & Data_Exists_A) | (pi_wrfifo_push_b & Data_Exists_B)) & ~wrfifo_full;
  assign PI_AddrReq = pi_addrreq_a | pi_addrreq_b;

endmodule // dualxcl_fsm

`default_nettype wire
