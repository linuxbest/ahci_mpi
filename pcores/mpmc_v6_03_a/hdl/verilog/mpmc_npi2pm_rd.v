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
`timescale 1ns / 1ns
`default_nettype none

module mpmc_npi2pm_rd
#(
  parameter  C_NPI2PM_BUF_AWIDTH = 2,
  parameter  C_NPI2PM_BUF_DEPTH = 4,
  parameter  C_DATA_WIDTH = 1'b1,
  parameter  C_PIM_BASETYPE = 0
)
(
  input  wire                           Clk,
  input  wire                           Rst,
  input  wire                           targeted,
  input  wire                           AddrReq,
  input  wire [3:0]                     Size,
  input  wire                           RNW,
  input  wire                           AddrAck,
  input  wire                           FIFO_Cmd,
  input  wire                           FIFO_Flush,

  output reg                            start,
  output reg                            stop,
  output reg                            flush,
  output reg   [3:0]                    qualifier,
  output reg                            dead_cycle
);

  localparam C_BEAT_CNT_WIDTH = (C_PIM_BASETYPE == 0) ? 2 : 
                                (C_PIM_BASETYPE == 1) ? 4 : // XCL Worst case is 16 words
                                (C_PIM_BASETYPE == 6) ? 5 : // VFBC hardcoded to 32 words
                                6;  // Worst case scenario is 64 words

  // pipelined inputs
  reg                               AddrReq_d1;
  reg                               AddrReq_d2;
  reg   [3:0]                       Size_d1;
  reg                               RNW_d1;
  reg                               AddrAck_d1;
  reg                               AddrAck_d2;
  reg                               FIFO_Cmd_d1;
  reg                               FIFO_Flush_d1;

  wire                              start_i;
  wire                              dead_cycle_i;
  wire                              done;
  wire                              pop;
  wire                              push;

  wire  [3:0]                       qualifier_out;
  wire                              FIFO_full;  // unused
  wire                              FIFO_empty;
  reg    [(C_BEAT_CNT_WIDTH-C_DATA_WIDTH)-1 :0]         beat_count;
  reg    [(C_BEAT_CNT_WIDTH-C_DATA_WIDTH)-1:0]         next_count;

  wire                              fifo_pop;
  wire  [3:0]                       qualifier_i;
  wire                              fifo_empty_i;

  // latch our inputs
  always @(posedge Clk)
    begin
      AddrReq_d1  <= AddrReq & targeted;
      AddrReq_d2  <= AddrReq_d1;
      Size_d1     <= Size;
      RNW_d1      <= RNW;
      AddrAck_d1  <= AddrAck & targeted;
      AddrAck_d2  <= AddrAck_d1;
      FIFO_Cmd_d1 <= FIFO_Cmd;
      FIFO_Flush_d1 <= FIFO_Flush;
    end

  assign start_i =  (AddrReq_d1 & ~AddrReq_d2) | (AddrReq_d1 & AddrAck_d2);
  assign dead_cycle_i = AddrReq_d1 & AddrReq_d2 & ~AddrAck_d1 & ~AddrAck_d2;
  assign done = ((beat_count == 0) && FIFO_Cmd_d1);

  // outputs
  always @(posedge Clk)
    if (Rst | FIFO_Flush_d1)
      begin
        start <= 1'b0;
        stop  <= 1'b0;
        qualifier <= 4'b0;
        dead_cycle <= 1'b0;
      end
    else
      begin
        start <= start_i;
        stop  <= done;
        qualifier <= qualifier_out;
        dead_cycle <= dead_cycle_i;
      end

  always @(posedge Clk)
    flush <= FIFO_Flush_d1;

  // fifo will be used to store incoming AddrReqs
  srl16e_fifo
   #(
      .c_width      (4),            // qualifier is 4 bits
      .c_awidth     (C_NPI2PM_BUF_AWIDTH),            // 
      .c_depth      (C_NPI2PM_BUF_DEPTH)
    ) 
    srl16e_fifo_inst 
    (
     .Clk           ( Clk  ),                   // I
     .Rst           ( Rst | FIFO_Flush_d1 ),    // I
     .WR_EN         ( start_i ),                // I
     .RD_EN         ( fifo_pop ),               // I
     .DIN           ( {Size_d1[2:0],RNW_d1} ),  // I
     .DOUT          ( qualifier_i ),              // O
     .FULL          ( FIFO_full ),              // O unused
     .EMPTY         ( fifo_empty_i )            // O
  );

  fifo_pipeline
  #(
    .C_DWIDTH       (4),
    .C_INV_EXISTS   (1)
  )
  srl16e_fifo_pipeine
  (
    .Clk            (Clk),
    .Rst            (Rst | FIFO_Flush_d1),
    .FIFO_Exists    (fifo_empty_i),
    .FIFO_Read      (fifo_pop),
    .FIFO_Data      (qualifier_i),
    .PIPE_Exists    (FIFO_empty),
    .PIPE_Read      (done),
    .PIPE_Data      (qualifier_out)
  );


  generate 
  begin
    if (C_PIM_BASETYPE == 1) begin : xcl_next_count
      always @(*)
      begin
        // Max is 16 words
        case (qualifier_i[2:1])
          2'd0: next_count = 0;
          2'd1: next_count = (4 >> C_DATA_WIDTH) - 1; 
          2'd2: next_count = (8 >> C_DATA_WIDTH) - 1;
          2'd3: next_count = (16 >> C_DATA_WIDTH) - 1;
          default: next_count = 0;
        endcase
      end
    end
    else if (C_PIM_BASETYPE == 6) begin : vfbc_next_count 
      always @(posedge Clk)
      begin 
        // Always 32 words
        next_count <= (32 >> C_DATA_WIDTH) -1;
      end
    end
    else begin : default_next_count
      // Number of beats to count next.  If we are 64 bit, then the number of
      // beats will be half.
      always @(*)
      begin
        case (qualifier_i[3:1])
          3'd0: next_count = 0;
          3'd1: next_count = (4 >> C_DATA_WIDTH) - 1; 
          3'd2: next_count = (8 >> C_DATA_WIDTH) - 1;
          3'd3: next_count = (16 >> C_DATA_WIDTH) - 1;
          3'd4: next_count = (32 >> C_DATA_WIDTH) - 1;
          3'd5: next_count = (64 >> C_DATA_WIDTH) - 1;
          default: next_count = 0;
        endcase
      end
    end
  end
  endgenerate

  always @(posedge Clk)
  begin
    if (Rst | FIFO_Flush_d1)
      beat_count <= 0;
    else if (fifo_pop)
      beat_count <= next_count;
    else if (~fifo_pop & FIFO_Cmd_d1)
      beat_count <= beat_count - 1'b1;
    else 
      beat_count <= beat_count;
  end

endmodule

`default_nettype wire
