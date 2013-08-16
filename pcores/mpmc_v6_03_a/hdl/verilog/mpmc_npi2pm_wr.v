//-----------------------------------------------------------------------------
//-- (c) Copyright 2006 - 2010 Xilinx, Inc. All rights reserved.
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

module mpmc_npi2pm_wr #
(
///////////////////////////////////////////////////////////////////////////
// Parameter Definitions
///////////////////////////////////////////////////////////////////////////
  parameter  C_DATA_WIDTH = 1'b1,
  parameter  C_PIM_BASETYPE = 0
) 
(
///////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////
  input  wire       Clk,
  input  wire       Rst,
  input  wire       AddrReq,
  input  wire       AddrAck,
  input  wire [3:0] Size,
  input  wire       WrFIFO_Push,

  output wire       start,
  output wire       stop,
  output wire       flush,
  output wire [3:0] qualifier,
  output wire       dead_cycle

);

///////////////////////////////////////////////////////////////////////////
// Local Params and Wires
///////////////////////////////////////////////////////////////////////////
localparam C_BEAT_CNT_WIDTH = (C_PIM_BASETYPE == 0) ? 1 : 
                              (C_PIM_BASETYPE == 1) ? 4 :
                              (C_PIM_BASETYPE == 2) ? 6 :
                              (C_PIM_BASETYPE == 3) ? 6 :
                              (C_PIM_BASETYPE == 4) ? 8 :
                              (C_PIM_BASETYPE == 5) ? 6 :
                              (C_PIM_BASETYPE == 6) ? 6 :
                              8;
localparam NPI_SINGLE         = 4'b0000;
localparam NPI_CACHELN_4WRD   = 4'b0001;
localparam NPI_CACHELN_8WRD   = 4'b0010;
localparam NPI_BURST_16WRD    = 4'b0011;
localparam NPI_BURST_32WRD    = 4'b0100;
localparam NPI_BURST_64WRD    = 4'b0101;
// State machine states
localparam SM_IDLE                    = 4'd0;
localparam SM_SINGLE_CYCLE_TRANS      = 4'd1;
localparam SM_DONE                    = 4'd2;
localparam SM_DATA_FIRST_START        = 4'd3;
localparam SM_DATA_FIRST_MIDDLE       = 4'd4;
localparam SM_ADDR_FIRST_START        = 4'd5;
localparam SM_ADDRACK_FIRST_START     = 4'd6;
localparam SM_ADDR_FIRST_ADDRACK_WAIT = 4'd7;
localparam SM_ADDR_FIRST_DATA_WAIT    = 4'd8;
localparam SM_FAIL                    = 4'd9;


wire [2:0]                  size_i; 
reg  [6:0]                  size_cnt;
reg  [C_BEAT_CNT_WIDTH-1:0] beat_cnt;
reg  [C_BEAT_CNT_WIDTH-1:0] trans_cnt;
reg                         addrreq_d1;
reg                         addrack_d1;
reg  [2:0]                  size_d1;
reg                         wrfifo_push_d1;
reg                         eq_d1;
reg                         gt_d1;
wire                        done;
reg  [3:0]                  state;
reg  [3:0]                  next_state;

wire                        stop_i;
wire                        start_i;
reg                         stop_d2;
reg                         start_d2;
reg  [3:0]                  qualifier_d2;
reg                         dead_cycle_d2;

///////////////////////////////////////////////////////////////////////////
// Begin RTL
///////////////////////////////////////////////////////////////////////////

// Ignore upper bit on Size 
assign size_i = Size[2:0]; 

// Table to convert sizes to beat counts, if data width is 64, then we
// transfer 2 words per beat
always @(*) begin
  case ({1'b0,size_i}) 
    NPI_SINGLE: 
      size_cnt = 7'd1;
    NPI_CACHELN_4WRD:
      size_cnt = 7'd4 >> C_DATA_WIDTH;
    NPI_CACHELN_8WRD:
      size_cnt = 7'd8 >> C_DATA_WIDTH;
    NPI_BURST_16WRD:
      size_cnt = 7'd16 >> C_DATA_WIDTH;
    NPI_BURST_32WRD:
      size_cnt = 7'd32 >> C_DATA_WIDTH;
    NPI_BURST_64WRD:
      size_cnt = 7'd64 >> C_DATA_WIDTH;
    default:
      size_cnt = 7'd1;
  endcase
end

// Transaction Counter with independent overflow bit count
always @(posedge Clk) begin
  if (Rst) begin
    trans_cnt <= { C_BEAT_CNT_WIDTH {1'b0}};
  end
  else if (AddrAck) begin
    trans_cnt <= trans_cnt + size_cnt;
  end
  else if (beat_cnt[C_BEAT_CNT_WIDTH-1] & ~AddrAck) begin
    trans_cnt <= {1'b0,trans_cnt[C_BEAT_CNT_WIDTH-2 : 0]};
  end
end

// Beat Counter with independent overflow bit count
always @(posedge Clk) begin
  if ( Rst ) begin
    beat_cnt[0 +: C_BEAT_CNT_WIDTH-1] <= {C_BEAT_CNT_WIDTH-1{1'b0}};
  end
  else if (WrFIFO_Push) begin
    beat_cnt[0 +: C_BEAT_CNT_WIDTH-1] <= beat_cnt[0 +: C_BEAT_CNT_WIDTH-1] + 1'b1;
  end
end

// De-assert MSB when trans_cnt is has msb asserted.  Wait for ~AddrAck such
// that trans_cnt can deassrt MSB simultaneously and keep the counts in sync
always @(posedge Clk) begin
  if ( Rst ) begin
    beat_cnt[C_BEAT_CNT_WIDTH-1] <= 1'b0;  
  end
  else if ((& beat_cnt[0 +: C_BEAT_CNT_WIDTH-1]) & WrFIFO_Push) begin
    beat_cnt[C_BEAT_CNT_WIDTH-1] <= 1'b1; 
  end
  else if (trans_cnt[C_BEAT_CNT_WIDTH-1] & ~AddrAck) begin
    beat_cnt[C_BEAT_CNT_WIDTH-1] <= 1'b0;
  end
end

// Register signals for second stage
always @(posedge Clk) begin
  addrreq_d1     <= AddrReq;
  addrack_d1     <= AddrAck;
  size_d1        <= size_i;
  wrfifo_push_d1 <= WrFIFO_Push;
  // Compare the beats counted to beats in a transaction
  eq_d1          <= (beat_cnt == trans_cnt);
  gt_d1          <= (beat_cnt >  trans_cnt);
end

//always @(*) begin
//  // Compare the beats counted to beats in a transaction
//  eq_d1          = (beat_cnt == trans_cnt);
//  gt_d1          = (beat_cnt >  trans_cnt);
//end
// An addrack with the the count equal to or greather than the number
// expecteed for the transaction indicates that this transaction has
// completed.
assign done = addrack_d1 & (eq_d1 | gt_d1);

always @(posedge Clk) begin
  if (Rst) begin
    state <= SM_IDLE;
  end 
  else begin
    state <= next_state;
  end
end

always @(*)
begin
  next_state = state;
  case (state)
    SM_IDLE, 
    SM_SINGLE_CYCLE_TRANS,
    SM_DONE:
    begin
      if (done)
        next_state = SM_SINGLE_CYCLE_TRANS;
      else if (addrack_d1)
        next_state = SM_ADDRACK_FIRST_START;
      else if (~addrack_d1 & gt_d1)
        next_state = SM_DATA_FIRST_START;
      else if (~addrack_d1 & ~gt_d1 & addrreq_d1)
        next_state = SM_ADDR_FIRST_START;
      else
        next_state = SM_IDLE;
    end

    SM_DATA_FIRST_START,
    SM_DATA_FIRST_MIDDLE:
    begin
      // In this state if the counters are equal then an addrack has occured and
      // the the number of beats expected for the current transactions are
      // accounted for.
      if (eq_d1 | done)
        next_state = SM_DONE;
      else
        next_state = SM_DATA_FIRST_MIDDLE;
    end

    SM_ADDR_FIRST_START,
    SM_ADDR_FIRST_ADDRACK_WAIT:
    begin
      if (done) 
        next_state = SM_DONE;
      else if (addrack_d1)
        next_state = SM_ADDR_FIRST_DATA_WAIT;
      else
        next_state = SM_ADDR_FIRST_ADDRACK_WAIT;
    end

    SM_ADDRACK_FIRST_START,
    SM_ADDR_FIRST_DATA_WAIT:
    begin
      if (eq_d1)
        next_state = SM_DONE;
      else
        next_state = SM_ADDR_FIRST_DATA_WAIT;
    end

    SM_FAIL:
    begin
      next_state = SM_FAIL;
    end

    default:
    begin
      next_state = SM_FAIL;
    end


  endcase
end

assign start_i = (state == SM_SINGLE_CYCLE_TRANS) || (state == SM_DATA_FIRST_START)
                 || (state == SM_ADDR_FIRST_START)|| (state == SM_ADDRACK_FIRST_START);
assign stop_i  = (state == SM_SINGLE_CYCLE_TRANS) || (state == SM_DONE);

always @(posedge Clk) begin
  start_d2      <= start_i;
  stop_d2       <= stop_i;
  dead_cycle_d2 <= AddrReq & addrreq_d1 & ~AddrAck & ~addrack_d1;
end

// Latch qualifer on valid addrack
always @(posedge Clk) begin  
  if (Rst) begin
    qualifier_d2 <= 4'b0;
  end else if (addrack_d1) begin
    qualifier_d2  <= {size_d1, 1'b0};
  end
end
// Assign outputs
assign start                  = start_d2;
assign stop                   = stop_d2;
assign qualifier              = qualifier_d2;
// Flushes reserved in writes
assign flush                  = 1'b0;
assign dead_cycle             = dead_cycle_d2;

endmodule

`default_nettype wire
