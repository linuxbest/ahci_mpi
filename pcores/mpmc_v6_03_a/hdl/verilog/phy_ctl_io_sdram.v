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

module phy_ctl_io_sdram #
  (
   parameter C_FAMILY      = "virtex4",
   parameter CLK_WIDTH     = 1,
   parameter BANK_WIDTH    = 2,
   parameter CKE_WIDTH     = 1,
   parameter COL_WIDTH     = 10,
   parameter CS_NUM        = 1,
   parameter CS_WIDTH      = 1,
   parameter ROW_WIDTH     = 13
   )   
  (
   input                   clk0,
   input                   rst0,
   input [ROW_WIDTH-1:0]   ctrl_addr,
   input [BANK_WIDTH-1:0]  ctrl_ba,
   input                   ctrl_ras_n,
   input                   ctrl_cas_n,
   input                   ctrl_we_n,
   input [CS_NUM-1:0]      ctrl_cs_n,
   input [ROW_WIDTH-1:0]   phy_init_addr,
   input [BANK_WIDTH-1:0]  phy_init_ba,
   input                   phy_init_ras_n,
   input                   phy_init_cas_n,
   input                   phy_init_we_n,
   input [CS_NUM-1:0]      phy_init_cs_n,
   input [CKE_WIDTH-1:0]   phy_init_cke,
   input                   phy_init_done,
   output [CLK_WIDTH-1:0]  sdram_ck,
   output [ROW_WIDTH-1:0]  sdram_addr,
   output [BANK_WIDTH-1:0] sdram_ba,
   output                  sdram_ras_n,
   output                  sdram_cas_n,
   output                  sdram_we_n,
   output [CKE_WIDTH-1:0]  sdram_cke,
   output [CS_WIDTH-1:0]   sdram_cs_n
  );
  
  wire [ROW_WIDTH-1:0]     addr_mux;
  wire [BANK_WIDTH-1:0]    ba_mux;
  wire                     cas_n_mux;
  wire [CS_NUM-1:0]        cs_n_mux;
  wire                     ras_n_mux;
  wire                     we_n_mux;

  //***************************************************************************

  // MUX to choose from either PHY or controller for SDRAM control
  assign addr_mux  = (phy_init_done) ? ctrl_addr  : phy_init_addr;
  assign ba_mux    = (phy_init_done) ? ctrl_ba    : phy_init_ba;
  assign cas_n_mux = (phy_init_done) ? ctrl_cas_n : phy_init_cas_n;
  assign cs_n_mux  = (phy_init_done) ? ctrl_cs_n  : phy_init_cs_n;
  assign ras_n_mux = (phy_init_done) ? ctrl_ras_n : phy_init_ras_n;
  assign we_n_mux  = (phy_init_done) ? ctrl_we_n  : phy_init_we_n;

  //***************************************************************************
  // Memory clock generation
  //***************************************************************************
  wire    vcc;
  wire    gnd;
  assign  vcc = 1'b1;
  assign  gnd = 1'b0;
  wire [CLK_WIDTH-1:0]     sdram_ck_q;

  genvar ck_i;
  generate 
    for (ck_i=0;ck_i<CLK_WIDTH;ck_i=ck_i+1)begin : gen_ck
      if ((C_FAMILY == "spartan3") || 
          (C_FAMILY == "spartan3a") || 
          (C_FAMILY == "spartan3e")) begin : gen_s3
        FDDRRSE ODDR_CLK (
          .Q  (sdram_ck_q[ck_i]), 
          .C0 (clk0), 
          .C1 (~clk0), 
          .CE (vcc), 
          .D0 (gnd), 
          .D1 (vcc), 
          .R  (gnd), 
          .S  (gnd)
        );
      end else begin : gen_virtex
        ODDR #(
          .SRTYPE ("SYNC"),
          .DDR_CLK_EDGE ("OPPOSITE_EDGE")
        ) ODDR_CLK (
          .Q   (sdram_ck_q[ck_i]),
          .C   (clk0),
          .CE  (vcc),
          .D1  (gnd),
          .D2  (vcc),
          .R   (gnd),
          .S   (gnd)
        );
      end
      OBUF OBUF (
        .I   (sdram_ck_q[ck_i]),
        .O   (sdram_ck[ck_i])
      );
    end
  endgenerate



  //***************************************************************************
  // Output flop instantiation
  // NOTE: Make sure all control/address flops are placed in IOBs
  //***************************************************************************
    
  // RAS: = 1 at reset
  (* IOB = "FORCE" *) FDS
  
  # (.INIT(1'b1))
  
  u_ff_ras_n 
    (
     .Q   (sdram_ras_n),
     .C   (clk0),
     .D   (ras_n_mux),
     .S   (rst0)
     );
     
  // CAS: = 1 at reset
  (* IOB = "FORCE" *) FDS
  
  # (.INIT(1'b1))
  
  u_ff_cas_n
    (
     .Q   (sdram_cas_n),
     .C   (clk0),
     .D   (cas_n_mux),
     .S   (rst0)
     );

  // WE: = 1 at reset
  (* IOB = "FORCE" *) FDS
    
  # (.INIT(1'b1))
  
  u_ff_we_n
    (
     .Q   (sdram_we_n),
     .C   (clk0),
     .D   (we_n_mux),
     .S   (rst0)
     );
  
  // CKE: = 0 at reset
  genvar cke_i;
  generate 
    for (cke_i = 0; cke_i < CKE_WIDTH; cke_i = cke_i + 1) begin: gen_cke
      (* IOB = "FORCE" *) FDR   u_ff_cke
        (
         .Q   (sdram_cke[cke_i]),
         .C   (clk0),
         .R   (rst0),
         .D   (phy_init_cke[cke_i])
         );
    end
  endgenerate

  // chip select: = 1 at reset
  genvar cs_i;
  generate 
    for(cs_i = 0; cs_i < CS_WIDTH; cs_i = cs_i + 1) begin: gen_cs_n
      (* IOB = "FORCE" *) FDS   
        
      # (.INIT(1'b1))      

      u_ff_cs_n
        (
         .Q   (sdram_cs_n[cs_i]),
         .C   (clk0),
         .D   (cs_n_mux[(cs_i*CS_NUM)/CS_WIDTH]),
         .S   (rst0)
         );
    end
  endgenerate
      
  // address: = X at reset 
  genvar addr_i;
  generate 
    for (addr_i = 0; addr_i < ROW_WIDTH; addr_i = addr_i + 1) begin: gen_addr
      (* IOB = "FORCE" *) FD    u_ff_addr
        (
         .Q   (sdram_addr[addr_i]),
         .C   (clk0),
         .D   (addr_mux[addr_i])
         );
    end
  endgenerate

  // bank address = X at reset
  genvar ba_i;
  generate 
    for (ba_i = 0; ba_i < BANK_WIDTH; ba_i = ba_i + 1) begin: gen_ba
      (* IOB = "FORCE" *) FD    u_ff_ba
        (
         .Q   (sdram_ba[ba_i]),
         .C   (clk0),
         .D   (ba_mux[ba_i])
         );
    end
  endgenerate

endmodule
