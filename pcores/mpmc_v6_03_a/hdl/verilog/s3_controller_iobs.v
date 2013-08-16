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
// MPMC Spartam3 MIG PHY Control IOBs (Direct Clocking)
//-------------------------------------------------------------------------
//
// Description:
//   This module contains the IOB instantiations for the controller module
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

module s3_controller_iobs #
  (
   parameter integer BANK_WIDTH    = 2,  // # of memory bank addr bits
   parameter integer ROW_WIDTH     = 14, // # of memory row & # of addr bits
   parameter integer CS_WIDTH      = 1,
   parameter integer CKE_WIDTH     = 1,
   parameter integer ODT_WIDTH     = 1
   )
  (
   input                   clk0, 
   input                   clk180,          
   input                   ddr_rasb_cntrl, 
   input                   ddr_casb_cntrl, 
   input                   ddr_web_cntrl,  
   input                   ddr_cke_cntrl,  
   input [CS_WIDTH-1:0]    ddr_csb_cntrl,  
   input [ODT_WIDTH-1:0]   ddr_odt_cntrl,
   input [ROW_WIDTH-1:0]   ddr_address_cntrl,
   input [BANK_WIDTH-1:0]  ddr_ba_cntrl,    
   input                   rst_dqs_div_int,  
   input                   rst_dqs_div_in, 
   output                  ddr_rasb,        
   output                  ddr_casb,        
   output                  ddr_web,         
   output [BANK_WIDTH-1:0] ddr_ba,     
   output [ROW_WIDTH-1:0]  ddr_address, 
   output [CKE_WIDTH-1:0]  ddr_cke,         
   output [CS_WIDTH-1:0]   ddr_csb,
   output [ODT_WIDTH-1:0]  ddr_odt,         
   output                  rst_dqs_div,     
   output                  rst_dqs_div_out
   );
  
  wire [ROW_WIDTH-1:0]     ddr_address_iob_reg;
  wire [BANK_WIDTH-1:0]    ddr_ba_reg;
  
  wire                     ddr_web_q;
  wire                     ddr_rasb_q;
  wire                     ddr_casb_q;
  wire [CKE_WIDTH-1:0]     ddr_cke_q;
  wire [CS_WIDTH-1:0]      ddr_csb_q;
           
  (* IOB = "FORCE" *) FD we_iob  
    (
     .Q( ddr_web_q),
     .D( ddr_web_cntrl),
     .C( clk180)
     )/* synthesis syn_useioff = 1 */;
  
  (* IOB = "FORCE" *) FD ras_iob  
    (
     .Q( ddr_rasb_q),
     .D( ddr_rasb_cntrl),
     .C( clk180)
     )/* synthesis syn_useioff = 1 */;              
  
  (* IOB = "FORCE" *) FD cas_iob  
    (
     .Q( ddr_casb_q),
     .D( ddr_casb_cntrl),
     .C( clk180)
     )/* synthesis syn_useioff = 1 */;

  // ************************************* 
  //  Output buffers for control signals   
  // ************************************* 
  
  OBUF we_obuf  
    (
     .I( ddr_web_q),
     .O( ddr_web)
     );
  
  OBUF ras_obuf  
    (
     .I( ddr_rasb_q),
     .O( ddr_rasb)
     );
  
  OBUF cas_obuf
    (
     .I( ddr_casb_q),
     .O( ddr_casb)
     );
  
  // -----------------------------------------------------------------------
  // Addr Generate
  // Purpose: Generate vectorized DDR address signals based on 
  //          ROW_WIDTH parameter.
  // -----------------------------------------------------------------------
  
  genvar addr_i;
  generate
    for(addr_i = 0; addr_i < ROW_WIDTH; addr_i = addr_i+1) begin: gen_addr
      
      (* IOB = "FORCE" *) FD addr_iob 
        (
         .Q (ddr_address_iob_reg[addr_i]),
         .D (ddr_address_cntrl[addr_i]),
         .C (clk180)
         )/* synthesis syn_useioff = 1 */;
      
      OBUF addr_obuf   
        (
         .I (ddr_address_iob_reg[addr_i]),
         .O (ddr_address[addr_i])
         );
      
    end
  endgenerate
  
  // -----------------------------------------------------------------------
  // BA Generate
  // Purpose: Generate vectorized bank address signals based on 
  //            BANK_WIDTH parameter.
  // -----------------------------------------------------------------------
  
  genvar ba_i;
  generate
    for(ba_i = 0; ba_i < BANK_WIDTH; ba_i = ba_i+1) begin: gen_ba
      
      (* IOB = "FORCE" *) FD ba_iob 
        (
         .Q (ddr_ba_reg[ba_i]),
         .D (ddr_ba_cntrl[ba_i]),
         .C (clk180)
         )/* synthesis syn_useioff = 1 */;
      
      OBUF addr_obuf   
        (
         .I (ddr_ba_reg[ba_i]),
         .O (ddr_ba[ba_i])
         );
        
    end
  endgenerate
  
  // -----------------------------------------------------------------------
  // CS Generate
  // Purpose: Generate vectorized CS signal based on CS_WIDTH parameter.
  // -----------------------------------------------------------------------
  
  genvar cs_i;
  generate
    for(cs_i = 0; cs_i < CS_WIDTH; cs_i = cs_i+1) begin: gen_cs
      
      (* IOB = "FORCE" *) FD csb_iob 
         (
          .Q(ddr_csb_q[cs_i]),
          .D(ddr_csb_cntrl[cs_i]),
          .C(clk180)
          )/* synthesis syn_useioff = 1 */;
      OBUF cs_obuf
        (
         .I(ddr_csb_q[cs_i]),
         .O(ddr_csb[cs_i])
         );
      
    end
  endgenerate

  // -----------------------------------------------------------------------
  // CKE Generate
  // Purpose: Generate vectorized CKE signal based on CKE_WIDTH parameter.
  // -----------------------------------------------------------------------

  genvar cke_i;
  generate
    for(cke_i = 0; cke_i < CKE_WIDTH; cke_i = cke_i+1) begin: gen_cke
      
      (* IOB = "FORCE" *) FD cke_iob 
         (
          .Q(ddr_cke_q[cke_i]),
          .D(ddr_cke_cntrl),
          .C(clk180)
          )/* synthesis syn_useioff = 1 */;
      
      OBUF cke_obuf
        (
         .I(ddr_cke_q[cke_i]),
         .O(ddr_cke[cke_i])
         );
      
    end
  endgenerate
  
  // -----------------------------------------------------------------------
  // ODT Generate
  // Purpose: Generate vectorized ODT signal based on ODT_WIDTH parameter.
  // -----------------------------------------------------------------------
  
  genvar odt_i;
  generate
    for(odt_i = 0; odt_i < ODT_WIDTH; odt_i = odt_i+1) begin: gen_odt
      
      OBUF odt_obuf
        (
         .I(ddr_odt_cntrl[odt_i]),
         .O(ddr_odt[odt_i])
         );
      
    end
  endgenerate
  
  IBUF rst_ibuf  
    (
     .I(rst_dqs_div_in),
     .O(rst_dqs_div)
     );
  
  OBUF rst_obuf  
    (
     .I(rst_dqs_div_int),
     .O(rst_dqs_div_out)
     );
  
endmodule




