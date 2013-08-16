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
// MPMC Spartam3 MIG PHY Gray Counter
//-------------------------------------------------------------------------
//
// Description:
//
// Structure:
//   -- s3_phy.v
//     -- s3_phy_init.v
//     -- s3_infrastructure.v
//       -- s3_cal_top.v
//         -- s3_cal_ctl.v
//         -- s3_tap_dly.v
//     -- s3_phy_write.v
//     -- s3_data_path.v
//       -- s3_data_read_controller.v
//         -- s3_dqs_delay.v
//         -- s3_fifo_0_wr_en.v
//         -- s3_fifo_1_wr_en.v
//       -- s3_data_read.v
//         -- s3_rd_data_ram0.v
//         -- s3_rd_data_ram1.v
//         -- s3_gray_cntr.v
//     -- s3_iobs.v
//       -- s3_infrastructure_iobs.v
//       -- s3_controller_iobs.v
//       -- s3_data_path_iobs.v
//         -- s3_dqs_iob.v
//         -- s3_dq_iob.v
//         -- s3_dm_iobs.v
//     
//--------------------------------------------------------------------------
//
// History:
//
//--------------------------------------------------------------------------

`timescale 1ns/100ps

module s3_gray_cntr
  (
   input        clk,
   input        reset,
   input        cnt_en,
   output [3:0] gcnt_out
   );

  reg [3:0]  d_in;
  wire [3:0] gc_int;

  
  assign gcnt_out = gc_int;

  always @(gc_int) begin
    case (gc_int)
      4'b0000 : d_in <= 4'b0001;  //1
      4'b0001 : d_in <= 4'b0011;  //3
      4'b0010 : d_in <= 4'b0110;  //6
      4'b0011 : d_in <= 4'b0010;  //2
      4'b0100 : d_in <= 4'b1100;  //c
      4'b0101 : d_in <= 4'b0100;  //4
      4'b0110 : d_in <= 4'b0111;  //7
      4'b0111 : d_in <= 4'b0101;  //5
      4'b1000 : d_in <= 4'b0000;  //0
      4'b1001 : d_in <= 4'b1000;  //8
      4'b1010 : d_in <= 4'b1011;  //b
      4'b1011 : d_in <= 4'b1001;  //9
      4'b1100 : d_in <= 4'b1101;  //d
      4'b1101 : d_in <= 4'b1111;  //f
      4'b1110 : d_in <= 4'b1010;  //a
      4'b1111 : d_in <= 4'b1110;  //e
      default : d_in <= 4'b0001;  //1
    endcase
  end

  genvar i;
  generate
    for (i = 0; i <= 3; i = i+1) begin: gen_addr
      
      FDCE u_addr_bit  
        (
         .Q(gc_int[i]),
         .C(clk),
         .CE(cnt_en),
         .CLR(reset),
         .D(d_in[i])
         );
      
    end
  endgenerate

endmodule



