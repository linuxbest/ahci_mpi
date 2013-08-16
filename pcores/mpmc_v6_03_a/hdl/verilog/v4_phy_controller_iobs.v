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

`timescale 1ns/1ps

module v4_phy_controller_iobs #
  (
   parameter integer row_address  = 14,
   parameter integer bank_address = 3,
   parameter integer cs_width     = 1,
   parameter integer cke_width    = 1,
   parameter integer odt_width    = 1  
   )
  (
   input                     CLK,
   input [row_address-1:0]   ctrl_ddr2_address,
   input [bank_address-1:0]  ctrl_ddr2_ba,
   input                     ctrl_ddr2_ras_L,
   input                     ctrl_ddr2_cas_L,
   input                     ctrl_ddr2_we_L,
   input [cs_width-1:0]      ctrl_ddr2_cs_L,
   input [cke_width-1:0]     ctrl_ddr2_cke,
   input [odt_width-1:0]     ctrl_ddr2_odt,

   output [row_address-1:0]  DDR_ADDRESS,
   output [bank_address-1:0] DDR_BA,
   output                    DDR_RAS_L,
   output                    DDR_CAS_L,
   output                    DDR_WE_L,
   output [cke_width-1:0]    DDR_CKE,
   output [odt_width-1:0]    DDR_ODT,
   output [cs_width-1:0]     ddr_cs_L
   );
  
  (* IOB = "FORCE" *)
  reg [row_address-1:0]      ctrl_ddr2_address_d1;
  (* IOB = "FORCE" *)
  reg [bank_address-1:0]     ctrl_ddr2_ba_d1;
  (* IOB = "FORCE" *)
  reg                        ctrl_ddr2_ras_L_d1;
  (* IOB = "FORCE" *)
  reg                        ctrl_ddr2_cas_L_d1;
  (* IOB = "FORCE" *)
  reg                        ctrl_ddr2_we_L_d1;
  (* IOB = "FORCE" *)
  reg [cs_width-1:0]         ctrl_ddr2_cs_L_d1;
  (* IOB = "FORCE" *)
  reg [cke_width-1:0]        ctrl_ddr2_cke_d1;
  (* IOB = "FORCE" *)
  reg [odt_width-1:0]        ctrl_ddr2_odt_d1;
  wire [odt_width-1:0]       ctrl_ddr2_odt_tmp;
  
  genvar i;
  
  generate
    if (odt_width>cs_width) begin : gen_odt_rep
      for (i=0;i<odt_width/cs_width;i=i+1) begin : gen_odt
        assign ctrl_ddr2_odt_tmp[(i+1)*cs_width-1:i*cs_width] = 
                 ctrl_ddr2_odt[(i+1)*cs_width-1:i*cs_width] & ~ctrl_ddr2_cs_L;
      end
    end else begin : gen_odt_norep
      assign ctrl_ddr2_odt_tmp = ctrl_ddr2_odt & ~ctrl_ddr2_cs_L[odt_width-1:0];
    end
  endgenerate
    
  always @(posedge CLK)
    begin
      ctrl_ddr2_address_d1 <= ctrl_ddr2_address;
      ctrl_ddr2_ba_d1 <= ctrl_ddr2_ba;
      ctrl_ddr2_ras_L_d1 <= ctrl_ddr2_ras_L;
      ctrl_ddr2_cas_L_d1 <= ctrl_ddr2_cas_L;
      ctrl_ddr2_we_L_d1 <= ctrl_ddr2_we_L;
      ctrl_ddr2_cs_L_d1 <= ctrl_ddr2_cs_L;
      ctrl_ddr2_cke_d1 <= ctrl_ddr2_cke;
      ctrl_ddr2_odt_d1 <= ctrl_ddr2_odt_tmp;
    end
  
  OBUF r0
    (
     .I  (ctrl_ddr2_ras_L_d1),
     .O  (DDR_RAS_L)
     );
  
  OBUF r1
    (
     .I  (ctrl_ddr2_cas_L_d1),
     .O  (DDR_CAS_L)
     );
  
  OBUF r2
    (
     .I  (ctrl_ddr2_we_L_d1),
     .O  (DDR_WE_L)
     );
  
  
  generate
    for (i=0;i<cs_width;i=i+1)
      begin : gen_obuf_cs
        OBUF OBUF_cs
          (
           .I  (ctrl_ddr2_cs_L_d1[i]),
           .O  (ddr_cs_L[i])
           );
      end
  endgenerate
  
  generate
    for (i=0;i<cke_width;i=i+1)
      begin : gen_obuf_cke
        OBUF OBUF_cke
          (
           .I  (ctrl_ddr2_cke_d1[i]),
           .O  (DDR_CKE[i])
           );
      end
  endgenerate
  
  generate
    for (i=0;i<odt_width;i=i+1)
      begin : gen_obuf_odt
        OBUF OBUF_odt
          (
           .I  (ctrl_ddr2_odt_d1[i]),
           .O  (DDR_ODT[i])
           );
      end
  endgenerate
  
  generate
    for (i=0;i<row_address;i=i+1)
      begin : gen_obuf_r
        OBUF OBUF_r
          (
           .I  (ctrl_ddr2_address_d1[i]),
           .O  (DDR_ADDRESS[i])
           );
      end
  endgenerate
  
  generate
    for (i=0;i<bank_address;i=i+1)
      begin : gen_obuf_b
        OBUF OBUF_b
          (
           .I  (ctrl_ddr2_ba_d1[i]),
           .O  (DDR_BA[i])
           );
      end
  endgenerate
  
endmodule
