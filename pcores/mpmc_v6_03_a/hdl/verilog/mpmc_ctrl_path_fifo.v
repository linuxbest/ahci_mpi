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
// Description: Generic FIFO.  Note that there must be at least 2 cycles 
// between the push and the corresponding pop.
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

module mpmc_ctrl_path_fifo #
  (
   parameter C_FIFO_DEPTH      = 4,
   parameter C_FIFO_ADDR_WIDTH = 2, // 2**C_FIFO_ADDR_WIDTH = C_FIFO_DEPTH
   parameter C_DATA_WIDTH      = 4
   )
  (
   input                     Rst,
   input                     Clk,
   input                     Push,
   input [C_DATA_WIDTH-1:0]  DIn,
   input                     Pop,
   output [C_DATA_WIDTH-1:0] DOut
   );

  reg [C_FIFO_ADDR_WIDTH-1:0]         pushaddr = 0;
  reg [C_FIFO_ADDR_WIDTH-1:0]         popaddr = 0;
  wire [C_FIFO_DEPTH-1:0]             ce;
  reg [C_DATA_WIDTH*C_FIFO_DEPTH-1:0] fifo_reg = 0;

  genvar i;

  // Calculate FIFO address
  always @(posedge Clk)
    if (Rst)
      pushaddr <= {C_FIFO_ADDR_WIDTH{1'b0}};
    else if (Push)
      pushaddr <= pushaddr + 1'b1;

  always @(posedge Clk)
    if (Rst)
      popaddr <= {C_FIFO_ADDR_WIDTH{1'b0}};
    else if (Pop)
      popaddr <= popaddr + 1'b1;

  // Calculate clock enables and instantiate FIFO registers
  generate 
    for (i=0;i<C_FIFO_DEPTH;i=i+1) begin : gen_ctrl
      assign ce[i] = ((pushaddr == i) && Push) ? 1'b1 : 1'b0;
      always @(posedge Clk)
        if (ce[i])
          fifo_reg[(i+1)*C_DATA_WIDTH-1:i*C_DATA_WIDTH] = DIn;
    end
  endgenerate

  // Instantiate FIFO output mux
  mpmc_srl_fifo_nto1_mux #
    (
     .C_RATIO         (C_FIFO_DEPTH),
     .C_SEL_WIDTH     (C_FIFO_ADDR_WIDTH),
     .C_DATAOUT_WIDTH (C_DATA_WIDTH)
     )
    mpmc_ctrl_path_fifo_mux
    (
     .Sel (popaddr),
     .In  (fifo_reg),
     .Out (DOut)
     );

endmodule                           

