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
//Purpose: IOB logic of Static Phy for MPMC
//Reference:
//Revision History:
//
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

//-----------------------------------------------------------------------------
// Module name:      static_phy_iobs
// Description:      Static Phy IOB instantiations.
// Verilog-standard: Verilog 2001
//-----------------------------------------------------------------------------
module static_phy_iobs #
  (
   parameter         FAMILY        = "virtex2p",
   parameter integer BANK_WIDTH    = 2,
   parameter integer CKE_WIDTH     = 1,
   parameter integer COL_WIDTH     = 10,
   parameter integer CS_NUM        = 1,
   parameter integer CS_WIDTH      = 1,
   parameter integer ODT_WIDTH     = 2,
   parameter integer ROW_WIDTH     = 13,   
   parameter integer CLK_WIDTH     = 1,
   parameter integer DM_WIDTH      = 2,
   parameter integer DQS_WIDTH     = 2,
   parameter integer DQ_WIDTH      = 16,
   parameter integer DQSN_ENABLE   = 1, 
   parameter integer DDR2_ENABLE   = 1
   )   
  (
   // System Signals
   input  wire           clk0,
   input  wire           clk90,
   input  wire           clk0_rddata,
   input  wire           rst0,
   input  wire           rst90,
   input  wire           rddata_clk_sel,   // 0 -> pipeline rddata on clk180
                                           // 1 -> pipeline rddata on clk0
   input  wire           rddata_swap_rise, // 0 -> first data in rise position
                                           // 1 -> first data in fall position
   // Interface between Core and Phy
   input  wire [ROW_WIDTH-1:0]  ctrl_addr,
   input  wire [BANK_WIDTH-1:0] ctrl_ba,
   input  wire                  ctrl_ras_n,
   input  wire                  ctrl_cas_n,
   input  wire                  ctrl_we_n,
   input  wire [CS_NUM-1:0]     ctrl_cs_n,
   input  wire                  odt,
   input  wire [ROW_WIDTH-1:0]  phy_init_addr,
   input  wire [BANK_WIDTH-1:0] phy_init_ba,
   input  wire                  phy_init_ras_n,
   input  wire                  phy_init_cas_n,
   input  wire                  phy_init_we_n,
   input  wire [CS_NUM-1:0]     phy_init_cs_n,
   input  wire [CKE_WIDTH-1:0]  phy_init_cke,
   input  wire                  phy_init_done,
   input  wire [DQ_WIDTH-1:0]   wr_data_rise,
   input  wire [DQ_WIDTH-1:0]   wr_data_fall,   
   input  wire [DM_WIDTH-1:0]   mask_data_rise,
   input  wire [DM_WIDTH-1:0]   mask_data_fall,
   output reg [DQ_WIDTH-1:0]    rd_data_rise,
   output reg [DQ_WIDTH-1:0]    rd_data_fall,   
   input  wire [DQ_WIDTH-1:0]   dq_oe_n,
   input  wire [DQS_WIDTH-1:0]  dqs_oe_n,
   input  wire [DQS_WIDTH-1:0]  dqs_rst_n,
   // Memory signals
   output wire [ROW_WIDTH-1:0]  ddr_addr,
   output wire [BANK_WIDTH-1:0] ddr_ba,
   output wire                  ddr_ras_n,
   output wire                  ddr_cas_n,
   output wire                  ddr_we_n,
   output wire [CKE_WIDTH-1:0]  ddr_cke,
   output wire [CS_WIDTH-1:0]   ddr_cs_n,
   output wire [ODT_WIDTH-1:0]  ddr_odt,
   output wire [CLK_WIDTH-1:0]  ddr_ck,
   output wire [CLK_WIDTH-1:0]  ddr_ck_n,
   output wire [DM_WIDTH-1:0]   ddr_dm,
   inout  wire [DQS_WIDTH-1:0]  ddr_dqs,
   inout  wire [DQS_WIDTH-1:0]  ddr_dqs_n,
   inout  wire [DQ_WIDTH-1:0]   ddr_dq
   );
  
   wire [ROW_WIDTH-1:0]      addr_mux;
   wire [BANK_WIDTH-1:0]     ba_mux;
   wire                      cas_n_mux;
   wire [CS_NUM-1:0]         cs_n_mux;
   wire [CS_WIDTH-1:0]       cs_n_mux_tmp;
   wire                      ras_n_mux;
   wire                      we_n_mux;
   wire [CLK_WIDTH-1:0]      ddr_ck_q;
   reg [DQS_WIDTH-1:0]       dqs_rst_n_r = 0;
   wire [DQS_WIDTH-1:0]      dqs_out;
   wire [DQS_WIDTH-1:0]      dqs_oe_n_r;
   wire [DM_WIDTH-1:0]       dm_out;
   wire [DQ_WIDTH-1:0]       dq_out;
   wire [DQ_WIDTH-1:0]       dq_in;
   wire [DQ_WIDTH-1:0]       dq_oe_n_r;
   
   wire [DQ_WIDTH-1:0]       rd_data_rise_in;
   wire [DQ_WIDTH-1:0]       rd_data_fall_in;
   reg [DQ_WIDTH-1:0]        rd_data_rise_clk0 = 0;
   reg [DQ_WIDTH-1:0]        rd_data_fall_clk0 = 0;
   reg [DQ_WIDTH-1:0]        rd_data_fall_clk0_d1 = 0;
   reg [DQ_WIDTH-1:0]        rd_data_rise_clk180 = 0;
   reg [DQ_WIDTH-1:0]        rd_data_fall_clk180 = 0;
   reg [DQ_WIDTH-1:0]        rd_data_fall_clk180_d1 = 0;
   

   // MUX to choose from either PHY or controller for SDRAM control
   assign addr_mux  = (phy_init_done) ? ctrl_addr  : phy_init_addr;
   assign ba_mux    = (phy_init_done) ? ctrl_ba    : phy_init_ba;
   assign cas_n_mux = (phy_init_done) ? ctrl_cas_n : phy_init_cas_n;
   assign cs_n_mux  = (phy_init_done) ? ctrl_cs_n  : phy_init_cs_n;
   assign ras_n_mux = (phy_init_done) ? ctrl_ras_n : phy_init_ras_n;
   assign we_n_mux  = (phy_init_done) ? ctrl_we_n  : phy_init_we_n;

   // Output flop instantiation
   // NOTE: Make sure all control/address flops are placed in IOBs
  // RAS: = 1 at reset
  (* IOB = "FORCE" *) FDS   u_ff_ras_n 
    (
     .Q   (ddr_ras_n),
     .C   (clk0),
     .D   (ras_n_mux),
     .S   (rst0)
     );
     
  // CAS: = 1 at reset
  (* IOB = "FORCE" *) FDS   u_ff_cas_n
    (
     .Q   (ddr_cas_n),
     .C   (clk0),
     .D   (cas_n_mux),
     .S   (rst0)
     );

  // WE: = 1 at reset
  (* IOB = "FORCE" *) FDS   u_ff_we_n
    (
     .Q   (ddr_we_n),
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
         .Q   (ddr_cke[cke_i]),
         .C   (clk0),
         .R   (rst0),
         .D   (phy_init_cke[cke_i])
         );
    end
  endgenerate

  // chip select: = 1 at reset
  assign cs_n_mux_tmp = {CS_WIDTH/CS_NUM{cs_n_mux}};
  genvar cs_i;
  generate 
    for(cs_i = 0; cs_i < CS_WIDTH; cs_i = cs_i + 1) begin: gen_cs_n
      (* IOB = "FORCE" *) FDS   u_ff_cs_n
        (
         .Q   (ddr_cs_n[cs_i]),
         .C   (clk0),
         .D   (cs_n_mux_tmp[cs_i]),
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
         .Q   (ddr_addr[addr_i]),
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
         .Q   (ddr_ba[ba_i]),
         .C   (clk0),
         .D   (ba_mux[ba_i])
         );
    end
  endgenerate

  // ODT control = 0 at reset
  genvar odt_i_rep;
  genvar odt_i;
  generate
     if (DDR2_ENABLE == 1) begin : gen_odt
        for (odt_i_rep = 0; odt_i_rep < ODT_WIDTH/CS_NUM; odt_i_rep = odt_i_rep + 1) begin: rep_odt
          for (odt_i = 0; odt_i < CS_NUM; odt_i = odt_i + 1) begin: rep_odt2
            (* IOB = "FORCE" *) FDR   u_ff_cke
              (
               .Q   (ddr_odt[odt_i_rep*CS_NUM+odt_i]),
               .C   (clk0),
               .R   (rst0),
               .D   (odt & ~cs_n_mux[odt_i])
               );
          end
        end
     end
     else begin : gen_noodt
        assign ddr_odt = {ODT_WIDTH{1'b0}};
     end
  endgenerate
  
  //***************************************************************************
  // Memory clock generation
  //***************************************************************************
  genvar ck_i;
  generate 
    for(ck_i = 0; ck_i < CLK_WIDTH; ck_i = ck_i+1) begin: gen_ck
       if ((FAMILY == "virtex4") || (FAMILY == "virtex5")) begin : gen_oddr
          ODDR #
            (
             .SRTYPE       ("SYNC"),
             .DDR_CLK_EDGE ("OPPOSITE_EDGE")
             )
            u_oddr_ck_i 
              (
               .Q   (ddr_ck_q[ck_i]),
               .C   (clk0),
               .CE  (1'b1),
               .D1  (1'b0),
               .D2  (1'b1),
               .R   (1'b0),
               .S   (1'b0)
               );
       end
       else begin : gen_fddrrse
          FDDRRSE
            u_oddr_ck_i
              (
               .Q  (ddr_ck_q[ck_i]), 
               .C0 (clk0), 
               .C1 (~clk0), 
               .CE (1'b1),
               .D0 (1'b0), 
               .D1 (1'b1), 
               .R  (1'b0), 
               .S  (1'b0)
               );
       end
         
      // Can insert ODELAY here if required
      if ((FAMILY == "virtex4")  || (FAMILY == "virtex5") || 
          (FAMILY == "spartan3a") || (FAMILY == "spartan3e")) begin : gen_obufds
         OBUFDS u_obuf_ck_i
           (
            .I   (ddr_ck_q[ck_i]),
            .O   (ddr_ck[ck_i]),
            .OB  (ddr_ck_n[ck_i])
            );
      end
      if (FAMILY == "virtex2p" || FAMILY == "spartan3") begin : gen_obuf
         wire [CLK_WIDTH-1:0] ddr_ck_n_q;
         FDDRRSE
           u_oddr_ck_i
             (
              .Q  (ddr_ck_n_q[ck_i]), 
              .C0 (clk0), 
              .C1 (~clk0), 
              .CE (1'b1),
              .D0 (1'b1), 
              .D1 (1'b0), 
              .R  (1'b0), 
              .S  (1'b0)
              );
         OBUF u_obuf_ck_i
           (
            .I   (ddr_ck_q[ck_i]),
            .O   (ddr_ck[ck_i])
            );
         OBUF u_obuf_ck_n_i
           (
            .I   (ddr_ck_n_q[ck_i]),
            .O   (ddr_ck_n[ck_i])
            );
      end
    end
  endgenerate

  //***************************************************************************
  // DQS instances
  //***************************************************************************

  genvar dqs_i;
  generate
    for(dqs_i = 0; dqs_i < DQS_WIDTH; dqs_i = dqs_i+1) begin: gen_dqs
       always @(negedge clk0)
         dqs_rst_n_r[dqs_i] <= dqs_rst_n[dqs_i];
   
       if ((FAMILY == "virtex4") || (FAMILY == "virtex5")) begin : gen_oddr
          ODDR #
            (
             .SRTYPE("SYNC"),
             .DDR_CLK_EDGE("OPPOSITE_EDGE")
             )
            u_oddr_dqs
              (
               .Q  (dqs_out[dqs_i]),
               .C  (~clk0),
               .CE (1'b1),
               .D1 (dqs_rst_n_r[dqs_i]), // keep output deasserted for write preamble
               .D2 (1'b0),
               .R  (1'b0),
               .S  (1'b0)
               );
       end
       else begin : gen_fddrrse
          FDDRRSE
            u_oddr_dqs
              (
               .Q  (dqs_out[dqs_i]), 
               .C0 (~clk0), 
               .C1 (clk0), 
               .CE (1'b1),
               .D0 (dqs_rst_n_r[dqs_i]), 
               .D1 (1'b0), 
               .R  (1'b0), 
               .S  (1'b0)
               );
       end
       (* IOB = "FORCE" *) FDS u_tri_state_dqs 
         (
          .D (dqs_oe_n[dqs_i]),
          .Q (dqs_oe_n_r[dqs_i]),
          .C (~clk0),
          .S (1'b0)
          );
       if (DQSN_ENABLE == 1)
         begin : gen_dqsn_diff
            if ((FAMILY == "virtex4")  || (FAMILY == "virtex5")   ||
                (FAMILY == "spartan3") || (FAMILY == "spartan3a") ||
                (FAMILY == "spartan3e")) begin : gen_obufds
               IOBUFDS iobuf_dqs 
                 (
                  .O   (),
                  .IO  (ddr_dqs[dqs_i]),
                  .IOB (ddr_dqs_n[dqs_i]),
                  .I   (dqs_out[dqs_i]),
                  .T   (dqs_oe_n_r[dqs_i])
                  );
            end
            if (FAMILY == "virtex2p") begin : gen_obuf
               wire [DQS_WIDTH-1:0] dqs_out_n;
               FDDRRSE
                 u_oddr_dqs
                   (
                    .Q  (dqs_out_n[dqs_i]), 
                    .C0 (~clk0), 
                    .C1 (clk0), 
                    .CE (1'b1),
                    .D0 (~dqs_rst_n_r[dqs_i]), 
                    .D1 (1'b1), 
                    .R  (1'b0), 
                    .S  (1'b0)
                    );
               IOBUF iobuf_dqs 
                 (
                  .O   (),
                  .IO  (ddr_dqs[dqs_i]),
                  .I   (dqs_out[dqs_i]),
                  .T   (dqs_oe_n_r[dqs_i])
                  );
               IOBUF iobuf_dqs_n 
                 (
                  .O   (),
                  .IO  (ddr_dqs_n[dqs_i]),
                  .I   (dqs_out_n[dqs_i]),
                  .T   (dqs_oe_n_r[dqs_i])
                  );
            end
         end
       else
         begin : gen_dqsn_nodiff
            IOBUF iobuf_dqs
              (
               
               .IO       (ddr_dqs[dqs_i]),
               .I        (dqs_out[dqs_i]),
               .T        (dqs_oe_n_r[dqs_i]),
               .O        ()
               );
            assign ddr_dqs_n = 1'b1;
         end
    end 
  endgenerate

  //***************************************************************************
  // DM instances
  //***************************************************************************

  genvar dm_i;
  generate
    for(dm_i = 0; dm_i < DM_WIDTH; dm_i = dm_i+1) begin: gen_dm
       if ((FAMILY == "virtex4") || (FAMILY == "virtex5")) begin : gen_oddr
          ODDR #
            (
             .SRTYPE("SYNC"),
             .DDR_CLK_EDGE("SAME_EDGE")
             )
            u_oddr_dm 
              (
               .Q  (dm_out[dm_i]),
               .C  (clk90),
               .CE (1'b1),
               .D1 (mask_data_rise[dm_i]),
               .D2 (mask_data_fall[dm_i]),
               .R  (1'b0),
               .S  (1'b0)
               );
       end
       else begin : gen_fddrrse
          reg mask_data_fall_tmp;
          always @(posedge clk90)
            mask_data_fall_tmp <= mask_data_fall[dm_i];
          FDDRRSE
            u_oddr_dm
              (
               .Q  (dm_out[dm_i]), 
               .C0 (clk90), 
               .C1 (~clk90), 
               .CE (1'b1),
               .D0 (mask_data_rise[dm_i]), 
               .D1 (mask_data_fall_tmp), 
               .R  (1'b0), 
               .S  (1'b0)
               );
       end
       OBUF u_obuf_dm 
         (
          .I (dm_out[dm_i]),
          .O (ddr_dm[dm_i])
          );
    end
  endgenerate

  //***************************************************************************
  // DQ IOB instances
  //***************************************************************************

  genvar dq_i;
  generate
    for(dq_i = 0; dq_i < DQ_WIDTH; dq_i = dq_i+1) begin: gen_dq
       // on a write, rising edge of DQS corresponds to rising edge of CLK180 
       // (aka falling edge of CLK0 -> rising edge DQS). We also know:
       //  1. data must be driven 1/4 clk cycle before corresponding DQS edge
       //  2. first rising DQS edge driven on falling edge of CLK0
       //  3. rising data must be driven 1/4 cycle before falling edge of CLK0
       //  4. therefore, rising data driven on rising edge of CLK90
       if ((FAMILY == "virtex4") || (FAMILY == "virtex5")) begin : gen_oddr
          ODDR #
            (
             .SRTYPE("SYNC"),
             .DDR_CLK_EDGE("SAME_EDGE")
             )
            u_oddr_dq 
              (
               .Q  (dq_out[dq_i]),
               .C  (clk90),
               .CE (1'b1),
               .D1 (wr_data_rise[dq_i]),
               .D2 (wr_data_fall[dq_i]),
               .R  (1'b0),
               .S  (1'b0)
               );
       end
       else begin : gen_fddrrse
          reg wr_data_fall_tmp;
          always @(posedge clk90)
            wr_data_fall_tmp <= wr_data_fall[dq_i];
          FDDRRSE
            u_oddr_dq
              (
               .Q  (dq_out[dq_i]), 
               .C0 (clk90), 
               .C1 (~clk90), 
               .CE (1'b1),
               .D0 (wr_data_rise[dq_i]), 
               .D1 (wr_data_fall_tmp), 
               .R  (1'b0), 
               .S  (1'b0)
               );
       end
       // make sure output is tri-state during reset (DQ_OE_N_R = 1)
       (* IOB = "FORCE" *) FDS u_tri_state_dq 
         (
          .D (dq_oe_n[dq_i]),
          .S (1'b0),
          .C (clk90),
          .Q (dq_oe_n_r[dq_i])
          );  
       IOBUF u_iobuf_dq 
         (
          .I  (dq_out[dq_i]),
          .T  (dq_oe_n_r[dq_i]),
          .IO (ddr_dq[dq_i]),
          .O  (dq_in[dq_i])
          );
       if ((FAMILY == "virtex4") || (FAMILY == "virtex5")) begin : gen_iddr
          IDDR #
            (
             .SRTYPE       ("SYNC"),
             .DDR_CLK_EDGE ("SAME_EDGE_PIPELINED")
             )
            iddr_dq
              (
               .Q1   (rd_data_rise_in[dq_i]),
               .Q2   (rd_data_fall_in[dq_i]),
               .C    (clk0_rddata),
               .CE   (1'b1),
               .D    (dq_in[dq_i]),
               .R    (1'b0),
               .S    (1'b0)
               );
       end
       else begin : gen_fd
          wire rd_data_rise_d1;
          wire rd_data_fall_d1;
          reg  rd_data_rise_in_reg;
          reg  rd_data_fall_in_reg;
          assign rd_data_rise_in[dq_i] = rd_data_rise_in_reg;
          assign rd_data_fall_in[dq_i] = rd_data_fall_in_reg;
          always @(posedge clk0_rddata) begin
             rd_data_rise_in_reg <= rd_data_rise_d1;
             rd_data_fall_in_reg <= rd_data_fall_d1;
          end
          FD
            iddr_dq_0 
              (
               .Q   (rd_data_rise_d1), 
               .C   (clk0_rddata), 
               .D   (dq_in[dq_i])
               );
          FD
            iddr_dq_1
              (
               .Q   (rd_data_fall_d1), 
               .C   (~clk0_rddata), 
               .D   (dq_in[dq_i])
               );
       end
    end
  endgenerate
  always @(posedge clk0) begin
     rd_data_rise_clk0    <= rd_data_rise_in;
     rd_data_fall_clk0    <= rd_data_fall_in;
     rd_data_fall_clk0_d1 <= rd_data_fall_clk0;
  end
  always @(negedge clk0) begin
     rd_data_rise_clk180    <= rd_data_rise_in;
     rd_data_fall_clk180    <= rd_data_fall_in;
     rd_data_fall_clk180_d1 <= rd_data_fall_clk180;
  end
  always @(posedge clk0) begin
     if (rddata_clk_sel) begin
        if (rddata_swap_rise) begin
           rd_data_rise <= rd_data_fall_clk0_d1;
           rd_data_fall <= rd_data_rise_clk0;
        end
        else begin
           rd_data_rise <= rd_data_rise_clk0;
           rd_data_fall <= rd_data_fall_clk0;
        end
     end
     else begin
        if (rddata_swap_rise) begin
           rd_data_rise <= rd_data_fall_clk180_d1;
           rd_data_fall <= rd_data_rise_clk180;
        end
        else begin
           rd_data_rise <= rd_data_rise_clk180;
           rd_data_fall <= rd_data_fall_clk180;
        end
     end
  end
  
endmodule // static_phy_iobs

