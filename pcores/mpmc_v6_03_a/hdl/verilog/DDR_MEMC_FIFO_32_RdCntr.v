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
// Description: This Module implements a helper function to generate
//              the read address pointer for the SRL based FIFO
//              used in the Memory Controller FIFO. It supports a 16
//              deep FIFO. Used to help break apart logic into smaller
//              pieces. Computes the SRL read address based on the
//              read/write strobes
//
// Rev History:
//
//   0.0   (7/27/00)  Begin Coding 
//   0.1   (10/30/00) Initial Commented Version for Release
//   0.2   (8/15/03)  Modified for DDR Memory Controller
//
/////////////////////////////////////////////////////////////////////

`timescale 1ns/1ns

module DDR_MEMC_FIFO_32_RdCntr (
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

  wire         raddr_ce0;
  wire         raddr_ce1;
  wire    [3:0] raddr_i;
  wire         raddr_i3_0;
  wire         raddr_i3_1;

  assign       raddr_ce0 = ren^wen;
  assign       raddr_ce1 = ren^wen;

// The structural logic has the same functionality as the same functionality
// as the following RTL block    
//     always @(posedge rclk)
//       if (raddr_ce0) raddr <= raddr_i;

FDSE raddr0ff (.Q(raddr[0]), .C(rclk), .CE(raddr_ce0), .S(rst), .D(raddr_i[0]));//, .CLR(rst));
FDSE raddr1ff (.Q(raddr[1]), .C(rclk), .CE(raddr_ce0), .S(rst), .D(raddr_i[1]));//, .CLR(rst));
FDSE raddr2ff (.Q(raddr[2]), .C(rclk), .CE(raddr_ce1), .S(rst), .D(raddr_i[2]));//, .CLR(rst));
FDSE raddr3ff (.Q(raddr[3]), .C(rclk), .CE(raddr_ce1), .S(rst), .D(raddr_i[3]));//, .CLR(rst));

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

/* synthesis translate_off */
defparam raddr_i1_rom.INIT = 8'h69;
/* synthesis translate_on */

LUT3 raddr_i1_rom (.O(raddr_i[1]), .I0(raddr[0]), .I1(raddr[1]),
                   .I2(wen))
                   /*synthesis xc_props = "INIT=69"*/;
// synthesis attribute INIT of raddr_i1_rom is "69"

// compute raddr_i[2]: -------------------------------------------------

/* synthesis translate_off */
defparam raddr_i2_rom.INIT = 16'h78E1;
/* synthesis translate_on */

LUT4 raddr_i2_rom (.O(raddr_i[2]), .I0(raddr[0]), .I1(raddr[1]),
                   .I2(raddr[2]),  .I3(wen))
                   /*synthesis xc_props = "INIT=78E1"*/;
// synthesis attribute INIT of raddr_i2_rom is "78E1"

// compute raddr_i[3]: -------------------------------------------------

/* synthesis translate_off */
defparam raddr_i3_rom1.INIT = 16'h7F80;
/* synthesis translate_on */

LUT4 raddr_i3_rom1 (.O(raddr_i3_1), .I0(raddr[0]), .I1(raddr[1]),
                    .I2(raddr[2]),   .I3(raddr[3]))
                    /*synthesis xc_props = "INIT=7F80"*/;
// synthesis attribute INIT of raddr_i3_rom1 is "7F80"

/* synthesis translate_off */
defparam raddr_i3_rom0.INIT = 16'hFE01;
/* synthesis translate_on */

LUT4 raddr_i3_rom0 (.O(raddr_i3_0), .I0(raddr[0]), .I1(raddr[1]),
                    .I2(raddr[2]),   .I3(raddr[3]))
                    /*synthesis xc_props = "INIT=FE01"*/;
// synthesis attribute INIT of raddr_i3_rom0 is "FE01"

MUXF5   raddr_i3_mux  (.O(raddr_i[3]),  .S(wen),
                       .I0(raddr_i3_0), .I1(raddr_i3_1));


endmodule






