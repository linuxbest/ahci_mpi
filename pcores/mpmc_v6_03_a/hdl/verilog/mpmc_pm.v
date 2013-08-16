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
//
// mpmc_pm - MPMC Performance Monitor - Module
//-------------------------------------------------------------------------
// Filename:     mpmc_pm.v
// Description:  This module is a MPMC Performance Monitor
//
//-------------------------------------------------------------------------
// Author:      CJC
// History:
//  CJC       05/15/2006      - Initial Release
//  CJC       05/25/2006      - Fixed the timers so they don't wrap > 255
//  CJC       06/09/2006      - Implemented C_SHIFT_BY
//-------------------------------------------------------------------------

// Design Notes:
//    The start/stop signals support independent read/write signals as well as the allowal of 
//    overlapping transactions.  You can have as many overlapping transactions as defined by 
//    the C_WR_TIMER and C_RD_TIMER parameters for write transactions and read transactions,
//    respectively.
`timescale 1ns / 1ns
`default_nettype none


/* This module is broken down into 4 separate modules: Timer, Arbiter, Buffer, BRAM.  Two 
   timers are instantiated, one for write transactions, one for read transactions.  These 
   values are passed to the arbiter, which then inserts them into a small buffer.  The buffer
   is necessary because while we can have new counts coming every cycle (or even two per cycle),
   the BRAM needs 2 cycles to read the address and write back the increment value.  */ 
module mpmc_pm (
  PM_Clk,
  Host_Clk,
  Rst,
  wr_start,
  wr_stop,
  wr_flush,
  wr_qualifier,
  rd_start,
  rd_stop,
  rd_flush,
  rd_qualifier,
  dead_cycle,
  PM_BRAM_enable,

  Dead_Cycle_Cnt_Clr,
  Dead_Cycle_Cnt_Out,
  Host_BRAM_address,
  Host_BRAM_Clr,
  Host_BRAM_data_out,
  Host_BRAM_status,
  Host_BRAM_status_tog
  );


// parameters 

  parameter         C_PM_WR_TIMER_AWIDTH = 1;                       // default is to allow max of two transactions at once
  parameter         C_PM_WR_TIMER_DEPTH  = 1 << C_PM_WR_TIMER_AWIDTH;
  parameter         C_PM_RD_TIMER_AWIDTH = C_PM_WR_TIMER_AWIDTH;        // set to the same as write timer
  parameter         C_PM_RD_TIMER_DEPTH  = 1 << C_PM_RD_TIMER_AWIDTH;
  parameter         C_PM_BUF_AWIDTH      = 3*C_PM_WR_TIMER_AWIDTH;      // This is the buffer before we write to the BRAM on the pm side
  parameter         C_PM_BUF_DEPTH       = 1 << C_PM_BUF_AWIDTH;
  parameter         C_PM_SHIFT_CNT_BY    = 1;
  parameter         C_PM_DC_CNTR = 1;               // valid values: 0,1
  parameter         C_PM_DC_WIDTH = 48;               // valid values: 32-64
  parameter         C_PI_RD_FIFO_TYPE    = 2'b00;
  parameter         C_PI_WR_FIFO_TYPE    = 2'b00;


// port declarations
  input             PM_Clk;
  input             Host_Clk;
  input             Rst;
  input             wr_start;
  input             wr_stop;
  input             wr_flush;
  input   [3:0]     wr_qualifier;
  input             rd_start;
  input             rd_stop;
  input             rd_flush;
  input   [3:0]     rd_qualifier;
  input             dead_cycle;
  input             PM_BRAM_enable;

  input             Dead_Cycle_Cnt_Clr;
  output [63:0]     Dead_Cycle_Cnt_Out;
  input   [8:0]     Host_BRAM_address;
  input             Host_BRAM_Clr;
  output [35:0]     Host_BRAM_data_out;
  output            Host_BRAM_status;
  input             Host_BRAM_status_tog;

// wires and regs 
  wire              PM_Clk;
  wire              Host_Clk;
  wire              Rst;
  wire              wr_start;
  wire              wr_stop;
  wire              wr_flush;
  wire    [3:0]     wr_qualifier;
  wire              rd_start;
  wire              rd_stop;
  wire              rd_flush;
  wire    [3:0]     rd_qualifier;
  wire              dead_cycle;
  wire              PM_BRAM_enable;

  wire              Dead_Cycle_Cnt_Clr;
  wire   [63:0]     Dead_Cycle_Cnt_Out;
  wire    [8:0]     Host_BRAM_address;
  wire              Host_BRAM_Clr;
  wire   [35:0]     Host_BRAM_data_out;
  reg               Host_BRAM_status;
  wire              Host_BRAM_status_tog;

  wire  [8:0]              wr_address;
  wire                     wr_we;
  wire  [8:0]              rd_address;
  wire                     rd_we;
  wire  [8:0]              pm_address;
  wire                     pm_we;
  wire                     pm_bram_wr;      
  reg                      pm_bram_wr_d1;     
  reg                      pm_bram_wr_d2;     
  wire  [8:0]              pm_bram_address;
  wire [35:0]              pm_bram_data_in;      // values back to BRAM
  wire [35:0]              pm_bram_data_out;     // values from BRAM
  reg  [35:0]              pm_bram_data_out_i;     // values from BRAM
  reg                      pm_bram_en_p1;  
  reg                      pm_bram_en;      // Determines which of the pms brams are enabled
  reg  [C_PM_DC_WIDTH-1:0] pm_dead_cycle_cntr;

  wire  [8:0]              Host_BRAM_address_i;
  reg   [8:0]              Host_BRAM_addr_cnt;
  reg                      Host_BRAM_clr_set;

  wire                     FIFO_full;
  wire                     FIFO_almost_full;
  wire                     FIFO_empty;
  wire                     FIFO_almost_empty;

  

  // this will count the write transactions
  generate
    if (C_PI_WR_FIFO_TYPE > 2'b0) begin : enable_wr_timer
      mpmc_pm_timer 
       #(
          .C_FIFO_AWIDTH (C_PM_WR_TIMER_AWIDTH),
          .C_FIFO_DEPTH (C_PM_WR_TIMER_DEPTH),
          .C_SHIFT_BY     (C_PM_SHIFT_CNT_BY)
        ) 
        pm_wr_timer
        (
          .Clk            (PM_Clk),       // I
          .Rst            (Rst|wr_flush),    // I
          .start          (wr_start),     // I
          .stop           (wr_stop),      // I
          .qualifier      (wr_qualifier), // I
          .bram_address   (wr_address),   // O
          .wr_en          (wr_we)         // O
        );
    end
    else begin : disable_wr_timer
      assign wr_address = 9'h00;
      assign wr_we      = 1'b0;
    end
  endgenerate

  
  // this will count the read transactions
  generate
    if (C_PI_RD_FIFO_TYPE > 2'b0) begin : enable_rd_timer
      mpmc_pm_timer 
       #(
          .C_FIFO_AWIDTH  (C_PM_RD_TIMER_AWIDTH),
          .C_FIFO_DEPTH   (C_PM_RD_TIMER_DEPTH),
          .C_SHIFT_BY     (C_PM_SHIFT_CNT_BY)
        ) 
        pm_rd_timer
        (
          .Clk            (PM_Clk),       // I
          .Rst            (Rst|rd_flush),    // I
          .start          (rd_start),     // I
          .stop           (rd_stop),      // I
          .qualifier      (rd_qualifier), // I
          .bram_address   (rd_address),   // O
          .wr_en          (rd_we)         // O
        );
    end
    else begin : disable_rd_timer
      assign rd_address = 9'h00;
      assign rd_we      = 1'b0;
    end
  endgenerate
  
  // this will arbitrate when we have reads/writes finishing simultaneously
  generate 
    if (C_PI_RD_FIFO_TYPE > 2'b0 && C_PI_WR_FIFO_TYPE > 2'b0) begin : timer_arb
      mpmc_pm_arbiter
        rd_wr_arbiter
        (
          .Clk             (PM_Clk),      // I
          .Rst             (Rst),         // I
          .wr_address      (wr_address),  // I
          .wr_we           (wr_we),       // I
          .rd_address      (rd_address),  // I
          .rd_we           (rd_we),       // I
          .pm_address      (pm_address),  // O
          .pm_we           (pm_we)        // O
        );
      end
    else begin : no_timer_arb
      assign pm_address = (C_PI_RD_FIFO_TYPE > 2'b0) ? rd_address : wr_address;
      assign pm_we      = (C_PI_RD_FIFO_TYPE > 2'b0) ? rd_we      : wr_we;
    end
  endgenerate

  // fifo is used to buffer the bram writes, since it will take 3 cycles to 
  // increment the bram
  srl16e_fifo_protect 
   #(
      .c_width      (9),
      .c_awidth     (C_PM_BUF_AWIDTH),
      .c_depth      (C_PM_BUF_DEPTH)
    ) 
    srl16e_fifo_inst 
    (
     .Clk      ( PM_Clk  ),           // I
     .Rst      ( Rst     ),           // I
     .WR_EN    ( pm_we), // I
     .RD_EN    ( pm_bram_wr_d2 ),     // I
     .DIN      ( pm_address ),        // I
     .DOUT     ( pm_bram_address ),   // O
     .FULL     ( FIFO_full ),         // O
     .ALMOST_FULL  ( FIFO_almost_full ),   // O
     .ALMOST_EMPTY ( FIFO_almost_empty ),  // O
     .EMPTY    ( FIFO_empty )         // O
  );
  // generate our signal to write to bram.  We want to do this when the buffer is not empty and we aren't currently writing to the bram
  assign pm_bram_wr = ~(FIFO_empty |pm_bram_wr_d1|pm_bram_wr_d2);        
  
  // latch write signal to delay it one cycle, so that we can read the bram value, incremement it, then write it.
  always @(posedge PM_Clk)
    if (Rst)
      begin
        pm_bram_wr_d1 <= 0;
        pm_bram_wr_d2 <= 0;
      end
    else
      begin
        pm_bram_wr_d1 <= pm_bram_wr;
        pm_bram_wr_d2 <= pm_bram_wr_d1;
      end
  
  // Accumulate the data 
  assign  pm_bram_data_in = pm_bram_data_out_i + 1;
  
  always @(posedge PM_Clk)
    pm_bram_data_out_i <= pm_bram_data_out;
  // PM_BRAM_enable is asynchronous, we used two flip flops to ensure stability
  always @(posedge PM_Clk)
    if (Rst)
      begin
        pm_bram_en_p1 <= 0;
        pm_bram_en <= 0;
      end
    else
      begin
        pm_bram_en_p1 <= PM_BRAM_enable;
        pm_bram_en <= pm_bram_en_p1; 
      end

  // this is the dead cycle counter
  generate
    if (C_PM_DC_CNTR == 1)
      begin : dead_cycle_cntr_instantiate
        always @(posedge PM_Clk)
          if (Rst || Dead_Cycle_Cnt_Clr)
             pm_dead_cycle_cntr <= 0;
          else if (pm_bram_en && dead_cycle)
             pm_dead_cycle_cntr <= pm_dead_cycle_cntr + 1;
          else
             pm_dead_cycle_cntr <= pm_dead_cycle_cntr;
      end
    else
      begin : no_dead_cycle_cntr
        always @ (posedge PM_Clk)
            pm_dead_cycle_cntr <= 0;
      end
  endgenerate

  assign Dead_Cycle_Cnt_Out = {{(64-C_PM_DC_WIDTH){1'b0}}, pm_dead_cycle_cntr};

  always @(posedge Host_Clk)
    if (Rst || Host_BRAM_Clr)
      Host_BRAM_clr_set <= 1;
    else if (Host_BRAM_addr_cnt == 0)
      Host_BRAM_clr_set <= 0;

  always @(posedge Host_Clk)
    if (Rst || Host_BRAM_Clr)
      Host_BRAM_addr_cnt <= {9{1'b1}};
    else if (Host_BRAM_clr_set)
      Host_BRAM_addr_cnt <= Host_BRAM_addr_cnt - 1'b1;

  always @(posedge Host_Clk)
    if (Rst || Host_BRAM_Clr)
      Host_BRAM_status <= 0;
    else if (Host_BRAM_addr_cnt == 0 && Host_BRAM_clr_set == 1)
      Host_BRAM_status <= 1;
    else if (Host_BRAM_status_tog)
      Host_BRAM_status <= Host_BRAM_status ^ Host_BRAM_status_tog;
    
    
  assign Host_BRAM_address_i = Host_BRAM_clr_set ? Host_BRAM_addr_cnt : Host_BRAM_address;
   
 // Instantiate the BRAM
 RAMB16_S36_S36
  #(
    .SRVAL_A  (36'b0),
    .SRVAL_B  (36'b0),
    .WRITE_MODE_A  ("WRITE_FIRST"), // host port 
    .WRITE_MODE_B  ("WRITE_FIRST"), // PM port
    .SIM_COLLISION_CHECK ("NONE")   // Ignore errors.  We won't be reading data 
                                    // and writing at the same time.
   )
     BRAM
   (
   .CLKA        (Host_Clk),             // I
   .ADDRA       (Host_BRAM_address_i),  // I
   .WEA         (Host_BRAM_clr_set),    // I
   .ENA         (1'b1),                 // I
   .SSRA        (Rst),                  // I
   .DIA         (32'b0),                // I
   .DIPA        (4'b0),                 // I
   .DOA         (Host_BRAM_data_out[31:0]),  // O
   .DOPA        (Host_BRAM_data_out[35:32]), // O

   .CLKB        (PM_Clk),               // I
   .ADDRB       (pm_bram_address),      // I address will be 256 64 bit words
   .WEB         (pm_bram_wr_d2),        // I
   .ENB         (pm_bram_en),           // I
   .SSRB        (Rst),                  // I
   .DIB         (pm_bram_data_in[31:0]), // I
   .DIPB        (pm_bram_data_in[35:32]), // I
   .DOB         (pm_bram_data_out[31:0]), // O
   .DOPB        (pm_bram_data_out[35:32]) // O
   );

endmodule

`default_nettype wire
