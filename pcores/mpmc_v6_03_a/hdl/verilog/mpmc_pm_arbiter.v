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
// Filename:     mpmc_pm_arbiter.v
// Description:  This module is a MPMC Performance Monitor Arbiter
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


/* A very simple arbiter to handle when we have reads and writes coming in simultaneously,
   counts coming from the write timer will always have priority over the read timer */ 
module mpmc_pm_arbiter
(
  Clk,
  Rst,
  wr_address,
  wr_we,
  rd_address,
  rd_we,
  pm_address,
  pm_we
);
  
  input         Clk;
  input         Rst;
  input [8:0]   wr_address;
  input         wr_we; 
  input [8:0]   rd_address;
  input         rd_we; 

  output [8:0]  pm_address;
  output        pm_we; 

  wire          Clk;
  wire          Rst;
  wire  [8:0]   wr_address;
  wire          wr_we; 
  wire  [8:0]   rd_address;
  wire          rd_we; 

  reg    [8:0]  pm_address;
  reg           pm_we; 


  reg           reads;
  reg           writes;

  reg    [8:0]  wr_addr_d1;
  reg    [8:0]  rd_addr_d1;
  wire   [8:0]  new_addr;

  // latch the data 
  always @ (posedge Clk)
      if (Rst)
          rd_addr_d1 <= 0;
      else if (rd_we)
          rd_addr_d1 <= rd_address;
      else
          rd_addr_d1 <= rd_addr_d1;

  // latch the data 
  always @ (posedge Clk)
      if (Rst)
          wr_addr_d1 <= 0;
      else if (wr_we)
          wr_addr_d1 <= wr_address;
      else
          wr_addr_d1 <= wr_addr_d1;


  // sr latch reads side, when the latch is set, it indicates data has arrived
  always @ (posedge Clk)
    begin
      if (Rst)
        reads <= 1'b0;
      else
        reads <= rd_we | (reads & ~(!writes && reads));
    end

  // sr latch writes side
  always @ (posedge Clk)
    begin
      if (Rst)
        writes <= 1'b0;
      else
        writes <= wr_we;
    end

  // mux to select which data we will send to the PM, priority given to writes
  assign new_addr = writes ? wr_addr_d1 : rd_addr_d1;
        
  // latch for data out
  always @ (posedge Clk)
      if (Rst)
          pm_address <= 0;
      else 
          pm_address <= new_addr;

  // generate the output write enable signal
  always @ (posedge Clk)
      if (Rst)
          pm_we  <= 1'b0;
      else 
          pm_we  <= (reads | writes);

endmodule
`default_nettype wire
