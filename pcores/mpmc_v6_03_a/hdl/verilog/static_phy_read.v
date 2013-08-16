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
//Device: Any
//Purpose: Read logic of Static Phy for MPMC
//Reference:
//Revision History:
//
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

//-----------------------------------------------------------------------------
// Module name:      static_phy_read
// Description:      Produces read related signals.
// Verilog-standard: Verilog 2001
//-----------------------------------------------------------------------------
module static_phy_read #
  (
   parameter integer DQS_WIDTH = 4
   )
  (
   input  wire                 clk0,
   input  wire                 ctrl_rden,
   input  wire [3:0]           phy_calib_rden_delay,
   output wire [DQS_WIDTH-1:0] phy_calib_rden
   );

   genvar i;
   generate
      for (i=0;i<DQS_WIDTH;i=i+1) begin : gen_phy_calib_rden
         static_phy_srl_delay
           srl_delay_phy_calib_rden
             (
              .Clk   (clk0),
              .Data  (ctrl_rden),
              .Delay (phy_calib_rden_delay),
              .Q     (phy_calib_rden[i])
              );
      end
   endgenerate
   
endmodule // static_phy_read

