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
// Description: Creates address for SRL FIFO.
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
module fifo_32_rdcntr (
  rclk,
  rst,
  ren,
  wen,
  raddr
  );

  input        rclk;
  input        rst;
  input        ren;
  input        wen;
  output [3:0] raddr;

  reg [3:0]    raddr = 0;

  wire         raddr_ce0;
  wire         raddr_ce1;
  wire    [3:0] raddr_i;
  wire         raddr_i3_0;
  wire         raddr_i3_1;

  assign       raddr_ce0 = ren^wen;
  assign       raddr_ce1 = ren^wen;

// The structural logic has the same functionality as the same functionality
// as the following RTL block    

     always @(posedge rclk) begin
        if (rst) raddr[0] <= 1'b1; else if (raddr_ce0) raddr[0] <= raddr_i[0];
        if (rst) raddr[1] <= 1'b1; else if (raddr_ce0) raddr[1] <= raddr_i[1];
        if (rst) raddr[2] <= 1'b1; else if (raddr_ce1) raddr[2] <= raddr_i[2];
        if (rst) raddr[3] <= 1'b1; else if (raddr_ce1) raddr[3] <= raddr_i[3];
     end
//FDSE raddr0ff (.Q(raddr[0]), .C(rclk), .CE(raddr_ce0), .S(rst), .D(raddr_i[0]));//, .CLR(rst));
//FDSE raddr1ff (.Q(raddr[1]), .C(rclk), .CE(raddr_ce0), .S(rst), .D(raddr_i[1]));//, .CLR(rst));
//FDSE raddr2ff (.Q(raddr[2]), .C(rclk), .CE(raddr_ce1), .S(rst), .D(raddr_i[2]));//, .CLR(rst));
//FDSE raddr3ff (.Q(raddr[3]), .C(rclk), .CE(raddr_ce1), .S(rst), .D(raddr_i[3]));//, .CLR(rst));

// the structural logic that generates raddr_i has the same functionality
// as the following RTL block    

//assign raddr_i = wen ? (raddr + 1) : (raddr - 1);

// or

//always @ (wen or raddr)
//begin
//    if (wen) raddr_i = raddr + 1;
//      else raddr_i = raddr - 1;
//end
// Note that raddr will not change unless raddr_ce is also high. The
// LUTs were instantiated because arithmetic RTL creates unnecessary
// carry logic in some synthesis tools. 

// compute raddr_i[0]:
assign raddr_i[0] = ~raddr[0];

// compute raddr_i[1]: -------------------------------------------------

   LUT3
     #(
       .INIT (8'h69)
       )
     raddr_i1_rom (.O(raddr_i[1]), .I0(raddr[0]), .I1(raddr[1]),
                   .I2(wen));
  
       
   // compute raddr_i[2]: -------------------------------------------------
   
   LUT4
     #(
       .INIT (16'h78E1)
       )
     raddr_i2_rom (.O(raddr_i[2]), .I0(raddr[0]), .I1(raddr[1]),
                   .I2(raddr[2]),  .I3(wen));
   
   // compute raddr_i[3]: -------------------------------------------------
   
   LUT4
     #(
       .INIT (16'h7F80)
       )
     raddr_i3_rom1 (.O(raddr_i3_1), .I0(raddr[0]), .I1(raddr[1]),
                    .I2(raddr[2]),   .I3(raddr[3]));
   
   LUT4
     #(
       .INIT (16'hFE01)
       )
     raddr_i3_rom0 (.O(raddr_i3_0), .I0(raddr[0]), .I1(raddr[1]),
                    .I2(raddr[2]),   .I3(raddr[3]));
       
   MUXF5   raddr_i3_mux  (.O(raddr_i[3]),  .S(wen),
                          .I0(raddr_i3_0), .I1(raddr_i3_1));
   
endmodule

