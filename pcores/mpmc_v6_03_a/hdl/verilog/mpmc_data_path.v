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
// MPMC Data Path
//-------------------------------------------------------------------------

// Description:    
//   Data Path for MPMC
//
// Structure:
//   mpmc_data_path
//     mpmc_write_fifo
//       mpmc_bram_fifo
//         mpmc_ramb16_sx_sx
//       mpmc_srl_fifo
//     mpmc_read_fifo
//       mpmc_bram_fifo
//         mpmc_ramb16_sx_sx
//       mpmc_srl_fifo
//     
//--------------------------------------------------------------------------
//
// History:
//   06/15/2007 Initial Version
//
//--------------------------------------------------------------------------
`timescale 1ns/1ns
module mpmc_data_path #
  (
   parameter         C_FAMILY                          = "virtex4",
   parameter         C_USE_INIT_PUSH                   = 1'b1,
   parameter         C_PI_WRFIFO_TYPE                  = 16'hFFFF,
   parameter         C_WRFIFO_TML_PIPELINE             = 1'b0,
   parameter         C_WRFIFO_PI_PIPELINE              = 8'hFF,
   parameter         C_WRFIFO_MEM_PIPELINE             = 8'hFF,
   parameter         C_PI_RDFIFO_TYPE                  = 16'hFFFF,
   parameter integer C_RDFIFO_MAX_FANOUT               = 0,
   parameter         C_RDFIFO_PI_PIPELINE              = 8'hFF,
   parameter         C_RDFIFO_MEM_PIPELINE             = 8'hFF,
   parameter integer C_NUM_PORTS                       = 8,
   parameter         C_IS_DDR                          = 1'b1,
   parameter integer C_MEM_DATA_WIDTH                  = 128,
   parameter integer C_PI_ADDR_WIDTH                   = 32,
   parameter integer C_PIX_DATA_WIDTH_MAX              = 64,
   parameter         C_PI_DATA_WIDTH                   = 8'hFF,
   parameter         C_INCLUDE_ECC_SUPPORT             = 0,
   parameter         C_CTRL_DP_WRFIFO_WHICHPORT_REP    = 1,
   parameter         C_PORT_FOR_WRITE_TRAINING_PATTERN = 3'b000,
   parameter         C_ARB_PORT_ENCODING_WIDTH         = 3'b000
   )
  (
   // Clocks and Resets
   input                                      Clk,
   input                                      Clk_WrFIFO_TML,
   input  [C_NUM_PORTS*2-1:0]                 Rst,
   // Port Interface Control Signal Inputs
   input  [C_NUM_PORTS-1:0]                   PI_AddrAck,
   input  [C_NUM_PORTS-1:0]                   PI_RNW,
   input  [C_NUM_PORTS*4-1:0]                 PI_Size,
   input  [C_NUM_PORTS*C_PI_ADDR_WIDTH-1:0]   PI_Addr,
   // Read FIFO Control Signal Inputs
   input  [C_NUM_PORTS-1:0]                   PI_RdFIFO_Flush,
   input                                      Ctrl_DP_RdFIFO_Push,
   input  [C_NUM_PORTS-1:0]                   Ctrl_DP_RdFIFO_WhichPort_Decode,
   input  [C_NUM_PORTS-1:0]                   PI_RdFIFO_Pop,
   // Read FIFO Control Signal Outputs
   output [C_NUM_PORTS-1:0]                   PI_RdFIFO_Empty,
   output [C_NUM_PORTS-1:0]                   DP_Ctrl_RdFIFO_AlmostFull,
   // Read FIFO Data Signals
   input  [C_MEM_DATA_WIDTH-1:0]              PhyIF_DP_DQ_I,
   output [C_NUM_PORTS*C_PIX_DATA_WIDTH_MAX-1:0] PI_RdFIFO_Data,
   output [C_NUM_PORTS*4-1:0]                 PI_RdFIFO_RdWdAddr,
   // Write Training Pattern Signals
   // Assumes that InitPush and related Pop do not happen on the same cycle.
   // Assumes that InitPush and Push do not happen on the same cycle.
   input                                      InitPush,
   input [C_MEM_DATA_WIDTH-1:0]               InitData,
   // Write FIFO Control Signal Inputs
   input  [C_NUM_PORTS-1:0]                   PI_WrFIFO_Flush,
   input  [C_NUM_PORTS-1:0]                   PI_WrFIFO_Push,
   input  [C_NUM_PORTS-1:0]                   Ctrl_PhyIF_Force_DM,
   input  [C_NUM_PORTS-1:0]                   Ctrl_DP_WrFIFO_Pop,
   input  [C_ARB_PORT_ENCODING_WIDTH*C_CTRL_DP_WRFIFO_WHICHPORT_REP-1:0] Ctrl_DP_WrFIFO_WhichPort,
   input  [C_NUM_PORTS-1:0]                   Ctrl_DP_WrFIFO_WhichPort_Decode,
   input  [C_NUM_PORTS-1:0]                   PhyIF_Ctrl_InitDone,
   // Write FIFO Control Signal Outputs
   output [C_NUM_PORTS-1:0]                   DP_Ctrl_WrFIFO_Empty,
   output [C_NUM_PORTS-1:0]                   PI_WrFIFO_AlmostFull,
   // Write FIFO Data Signals
   input  [C_NUM_PORTS*C_PIX_DATA_WIDTH_MAX-1:0]   PI_WrFIFO_Data,
   input  [C_NUM_PORTS*C_PIX_DATA_WIDTH_MAX/8-1:0] PI_WrFIFO_BE,
   output [C_MEM_DATA_WIDTH-1:0]              DP_PhyIF_DQ_O,
   output [C_MEM_DATA_WIDTH/8-1:0]            DP_PhyIF_BE_O
   );
   
   wire [C_NUM_PORTS*C_MEM_DATA_WIDTH-1:0]    wrfifo_data_o;
   wire [C_NUM_PORTS*C_MEM_DATA_WIDTH/8-1:0]  wrfifo_be_o;
   wire [C_MEM_DATA_WIDTH-1:0]                DP_PhyIF_DQ_O_i1;
   wire [C_MEM_DATA_WIDTH/8-1:0]              DP_PhyIF_BE_O_i1;
   reg [C_MEM_DATA_WIDTH-1:0]                 DP_PhyIF_DQ_O_i2;
   reg [C_MEM_DATA_WIDTH/8-1:0]               DP_PhyIF_BE_O_i2;
   wire [C_NUM_PORTS*C_MEM_DATA_WIDTH-1:0]    rdfifo_data_i;
   wire [C_NUM_PORTS-1:0]                     rdfifo_push_i;
   reg [C_NUM_PORTS-1:0]                      PI_RdFIFO_Flush_tmp;
   
   genvar i;
   genvar j;
   genvar k;
   
   generate
      if (C_WRFIFO_TML_PIPELINE == 0)  begin : gen_no_tml_pipeline
         if (C_IS_DDR == 0 & C_INCLUDE_ECC_SUPPORT == 1) begin : gen_ecc
             always @ (*) begin             
               DP_PhyIF_DQ_O_i2 <= DP_PhyIF_DQ_O_i1;
               DP_PhyIF_BE_O_i2 <= DP_PhyIF_BE_O_i1;
             end
         end
         else begin : gen_noecc
             always @(posedge Clk_WrFIFO_TML) begin
               DP_PhyIF_DQ_O_i2 <= DP_PhyIF_DQ_O_i1;
               DP_PhyIF_BE_O_i2 <= DP_PhyIF_BE_O_i1;
             end
         end
      end
      else begin : gen_tml_pipeline
         if (C_INCLUDE_ECC_SUPPORT == 1) begin : gen_ecc
            always @(posedge Clk) begin
               DP_PhyIF_DQ_O_i2 <= DP_PhyIF_DQ_O_i1;
               DP_PhyIF_BE_O_i2 <= DP_PhyIF_BE_O_i1;
            end
         end
         else begin : gen_noecc
            reg [C_MEM_DATA_WIDTH-1:0]   DP_PhyIF_DQ_O_i1a;
            reg [C_MEM_DATA_WIDTH/8-1:0] DP_PhyIF_BE_O_i1a;
            always @(posedge Clk) begin
               DP_PhyIF_DQ_O_i1a <= DP_PhyIF_DQ_O_i1;
               DP_PhyIF_BE_O_i1a <= DP_PhyIF_BE_O_i1;
            end
            always @(posedge Clk_WrFIFO_TML) begin
               DP_PhyIF_DQ_O_i2 <= DP_PhyIF_DQ_O_i1a;
               DP_PhyIF_BE_O_i2 <= DP_PhyIF_BE_O_i1a;
            end
         end
      end
   endgenerate
   assign DP_PhyIF_DQ_O = DP_PhyIF_DQ_O_i2;
   assign DP_PhyIF_BE_O = DP_PhyIF_BE_O_i2;
   generate
      for (i=0;i<C_NUM_PORTS;i=i+1) begin : gen_write_fifos
         if (C_PI_WRFIFO_TYPE[(i+1)*2-1:i*2] == 2'b00) 
           begin : gen_fifos_disabled
              // Tie off Write FIFO outputs
              assign DP_Ctrl_WrFIFO_Empty[i] = 1'b1;
              assign PI_WrFIFO_AlmostFull[i] = 1'b1;
              assign wrfifo_data_o[(i+1)*C_MEM_DATA_WIDTH-1:
                                   i*C_MEM_DATA_WIDTH] = {C_MEM_DATA_WIDTH{1'b0}};
              assign wrfifo_be_o[(i+1)*C_MEM_DATA_WIDTH/8-1:
                                 i*C_MEM_DATA_WIDTH/8] = {C_MEM_DATA_WIDTH/8{1'b0}};
           end
         else begin : gen_fifos
            reg PhyIF_Ctrl_InitDone_d1;
            always @(posedge Clk) begin
               PhyIF_Ctrl_InitDone_d1 <= PhyIF_Ctrl_InitDone[i];
            end
            wire [((C_PI_DATA_WIDTH[i]==1'b1)?64:32)-1:0]   PI_WrFIFO_Data_tmp;
            wire [((C_PI_DATA_WIDTH[i]==1'b1)?64:32)/8-1:0] PI_WrFIFO_BE_tmp;
            assign PI_WrFIFO_Data_tmp = 
               PI_WrFIFO_Data[i*C_PIX_DATA_WIDTH_MAX+(C_PI_DATA_WIDTH[i]?63:31):
                              i*C_PIX_DATA_WIDTH_MAX];
            assign PI_WrFIFO_BE_tmp =
               PI_WrFIFO_BE[i*C_PIX_DATA_WIDTH_MAX/8+(C_PI_DATA_WIDTH[i]?7:3):
                            i*C_PIX_DATA_WIDTH_MAX/8];
                               
            // Instantiate Write FIFOs
            mpmc_write_fifo #
              (
               .C_FAMILY         (C_FAMILY),
               .C_FIFO_TYPE      (C_PI_WRFIFO_TYPE[(i+1)*2-1:i*2]),
               .C_PI_PIPELINE    (C_WRFIFO_PI_PIPELINE[i]),
               .C_MEM_PIPELINE   (C_WRFIFO_MEM_PIPELINE[i]),
               .C_PI_ADDR_WIDTH  (C_PI_ADDR_WIDTH),
               .C_PI_DATA_WIDTH  ((C_PI_DATA_WIDTH[i]==1'b1) ? 64 : 32),
               .C_MEM_DATA_WIDTH (C_MEM_DATA_WIDTH),
               .C_USE_INIT_PUSH  (C_USE_INIT_PUSH)
               )
              mpmc_write_fifo_0
                (
                 .Clk        (Clk),
                 .Rst        (Rst[i*2]),
                 .AddrAck    (PI_AddrAck[i]),
                 .RNW        (PI_RNW[i]),
                 .Size       (PI_Size[(i+1)*4-1:i*4]),
                 .Addr       (PI_Addr[(i+1)*C_PI_ADDR_WIDTH-1:
                                      i*C_PI_ADDR_WIDTH]),
                 .InitPush   ((C_PORT_FOR_WRITE_TRAINING_PATTERN==i) ? 
                              InitPush : 1'b0),
                 .InitData   ((C_PORT_FOR_WRITE_TRAINING_PATTERN==i) ? 
                              InitData : {C_MEM_DATA_WIDTH{1'b0}}),
                 .InitDone   (PhyIF_Ctrl_InitDone_d1),
                 .Flush      (PI_WrFIFO_Flush[i]),
                 .Push       (PI_WrFIFO_Push[i]),
                 .Pop        (~Ctrl_PhyIF_Force_DM[i] &
                              Ctrl_DP_WrFIFO_Pop[i] & 
                              Ctrl_DP_WrFIFO_WhichPort_Decode[i]),
                 .BE_Rst     (Ctrl_PhyIF_Force_DM[i] & 
                              Ctrl_DP_WrFIFO_WhichPort_Decode[i]),
                 .Empty      (DP_Ctrl_WrFIFO_Empty[i]),
                 .AlmostFull (PI_WrFIFO_AlmostFull[i]),
                 .PushData   (PI_WrFIFO_Data_tmp),
                 .PushBE     (PI_WrFIFO_BE_tmp),
                 .PopData    (wrfifo_data_o[(i+1)*C_MEM_DATA_WIDTH-1:
                                            i*C_MEM_DATA_WIDTH]),
                 .PopBE      (wrfifo_be_o[(i+1)*C_MEM_DATA_WIDTH/8-1:
                                          i*C_MEM_DATA_WIDTH/8])
                 );
         end
      end
   endgenerate
   generate
     // Apply Write FIFO timing management logic
     for (j=0;j<C_CTRL_DP_WRFIFO_WHICHPORT_REP;j=j+1) begin : gen_rep
       wire [C_NUM_PORTS*C_MEM_DATA_WIDTH/
             C_CTRL_DP_WRFIFO_WHICHPORT_REP-1:0] mux_data_in;
       wire [C_NUM_PORTS*C_MEM_DATA_WIDTH/8/
             C_CTRL_DP_WRFIFO_WHICHPORT_REP-1:0] mux_be_in;
       for (k=0;k<C_NUM_PORTS;k=k+1) begin : gen_mux_data_in
         assign mux_data_in[(k+1)*C_MEM_DATA_WIDTH/
                            C_CTRL_DP_WRFIFO_WHICHPORT_REP - 1:
                            k*C_MEM_DATA_WIDTH/
                            C_CTRL_DP_WRFIFO_WHICHPORT_REP] =
                   wrfifo_data_o[k*C_MEM_DATA_WIDTH+
                                 (j+1)*C_MEM_DATA_WIDTH/
                                 C_CTRL_DP_WRFIFO_WHICHPORT_REP-1:
                                 k*C_MEM_DATA_WIDTH+
                                 j*C_MEM_DATA_WIDTH/
                                 C_CTRL_DP_WRFIFO_WHICHPORT_REP];
         assign mux_be_in[(k+1)*C_MEM_DATA_WIDTH/8/
                          C_CTRL_DP_WRFIFO_WHICHPORT_REP - 1:
                          k*C_MEM_DATA_WIDTH/8/
                          C_CTRL_DP_WRFIFO_WHICHPORT_REP] =
                   wrfifo_be_o[k*C_MEM_DATA_WIDTH/8+
                               (j+1)*C_MEM_DATA_WIDTH/8/
                               C_CTRL_DP_WRFIFO_WHICHPORT_REP-1:
                               k*C_MEM_DATA_WIDTH/8+
                               j*C_MEM_DATA_WIDTH/8/
                               C_CTRL_DP_WRFIFO_WHICHPORT_REP];                                    
       end
       if ((C_WRFIFO_MEM_PIPELINE[0] && (C_PI_WRFIFO_TYPE[1:0] != 2'b00)
            && (C_NUM_PORTS >= 1)) ||
           (C_WRFIFO_MEM_PIPELINE[1] && (C_PI_WRFIFO_TYPE[3:2] != 2'b00)
            && (C_NUM_PORTS >= 2)) ||
           (C_WRFIFO_MEM_PIPELINE[2] && (C_PI_WRFIFO_TYPE[5:4] != 2'b00)
            && (C_NUM_PORTS >= 3)) ||
           (C_WRFIFO_MEM_PIPELINE[3] && (C_PI_WRFIFO_TYPE[7:6] != 2'b00)
            && (C_NUM_PORTS >= 4)) ||
           (C_WRFIFO_MEM_PIPELINE[4] && (C_PI_WRFIFO_TYPE[9:8] != 2'b00)
            && (C_NUM_PORTS >= 5)) ||
           (C_WRFIFO_MEM_PIPELINE[5] && (C_PI_WRFIFO_TYPE[11:10] != 2'b00)
            && (C_NUM_PORTS >= 6)) ||
           (C_WRFIFO_MEM_PIPELINE[6] && (C_PI_WRFIFO_TYPE[13:12] != 2'b00)
            && (C_NUM_PORTS >= 7)) ||
           (C_WRFIFO_MEM_PIPELINE[7] && (C_PI_WRFIFO_TYPE[15:14] != 2'b00)
            && (C_NUM_PORTS >= 8))) begin : gen_ormux
         mpmc_srl_fifo_nto1_ormux #
           (
            .C_RATIO         (C_NUM_PORTS),
            .C_SEL_WIDTH     (C_ARB_PORT_ENCODING_WIDTH),
            .C_DATAOUT_WIDTH (C_MEM_DATA_WIDTH/
                              C_CTRL_DP_WRFIFO_WHICHPORT_REP)
            )
           gen_wrfifo_data_0
             (
              .Sel (Ctrl_DP_WrFIFO_WhichPort[(j+1)*C_ARB_PORT_ENCODING_WIDTH-1:j*C_ARB_PORT_ENCODING_WIDTH]),
              .In  (mux_data_in),
              .Out (DP_PhyIF_DQ_O_i1[(j+1)*C_MEM_DATA_WIDTH/
                                     C_CTRL_DP_WRFIFO_WHICHPORT_REP-1:
                                     j*C_MEM_DATA_WIDTH/
                                     C_CTRL_DP_WRFIFO_WHICHPORT_REP])
              );
         mpmc_srl_fifo_nto1_ormux #
           (
            .C_RATIO         (C_NUM_PORTS),
            .C_SEL_WIDTH     (C_ARB_PORT_ENCODING_WIDTH),
               .C_DATAOUT_WIDTH (C_MEM_DATA_WIDTH/8/C_CTRL_DP_WRFIFO_WHICHPORT_REP)
            )
           gen_wrfifo_be_0
             (
              .Sel (Ctrl_DP_WrFIFO_WhichPort[(j+1)*C_ARB_PORT_ENCODING_WIDTH-1:j*C_ARB_PORT_ENCODING_WIDTH]),
              .In  (mux_be_in),
              .Out (DP_PhyIF_BE_O_i1[(j+1)*C_MEM_DATA_WIDTH/8/
                                     C_CTRL_DP_WRFIFO_WHICHPORT_REP-1:
                                     j*C_MEM_DATA_WIDTH/8/
                                     C_CTRL_DP_WRFIFO_WHICHPORT_REP])
              );
       end else begin : gen_mux
         mpmc_srl_fifo_nto1_mux #
           (
            .C_RATIO         (C_NUM_PORTS),
            .C_SEL_WIDTH     (C_ARB_PORT_ENCODING_WIDTH),
            .C_DATAOUT_WIDTH (C_MEM_DATA_WIDTH/
                              C_CTRL_DP_WRFIFO_WHICHPORT_REP)
            )
           gen_wrfifo_data_0
             (
              .Sel (Ctrl_DP_WrFIFO_WhichPort[(j+1)*C_ARB_PORT_ENCODING_WIDTH-1:j*C_ARB_PORT_ENCODING_WIDTH]),
              .In  (mux_data_in),
              .Out (DP_PhyIF_DQ_O_i1[(j+1)*C_MEM_DATA_WIDTH/
                                     C_CTRL_DP_WRFIFO_WHICHPORT_REP-1:
                                     j*C_MEM_DATA_WIDTH/
                                     C_CTRL_DP_WRFIFO_WHICHPORT_REP])
              );
         mpmc_srl_fifo_nto1_mux #
           (
            .C_RATIO         (C_NUM_PORTS),
            .C_SEL_WIDTH     (C_ARB_PORT_ENCODING_WIDTH),
            .C_DATAOUT_WIDTH (C_MEM_DATA_WIDTH/8/C_CTRL_DP_WRFIFO_WHICHPORT_REP)
            )
           gen_wrfifo_be_0
             (
              .Sel (Ctrl_DP_WrFIFO_WhichPort[(j+1)*C_ARB_PORT_ENCODING_WIDTH-1:j*C_ARB_PORT_ENCODING_WIDTH]),
              .In  (mux_be_in),
              .Out (DP_PhyIF_BE_O_i1[(j+1)*C_MEM_DATA_WIDTH/8/
                                     C_CTRL_DP_WRFIFO_WHICHPORT_REP-1:
                                     j*C_MEM_DATA_WIDTH/8/
                                     C_CTRL_DP_WRFIFO_WHICHPORT_REP])
              );
       end
     end
     // SPECIAL CASE: Requires mods to mpmc_core.v
     // IF TML Pipeline enabled, and ECC enabled, cannot assert pop
     // early enough, so eliminate TML Pipeline.
   endgenerate
   generate
      // Apply Read FIFO timing management logic
      if (C_RDFIFO_MAX_FANOUT == 0) begin : gen_rdfifo_maxfanout0
         for (i=0;i<C_NUM_PORTS;i=i+1) begin : gen_rep_phyif_dp_dq_i
            assign rdfifo_data_i[(i+1)*C_MEM_DATA_WIDTH-1:
                                 i*C_MEM_DATA_WIDTH]
                                    = PhyIF_DP_DQ_I;
            assign rdfifo_push_i[i] = Ctrl_DP_RdFIFO_Push &
                                      Ctrl_DP_RdFIFO_WhichPort_Decode[i];
         end
      end
      else if (C_RDFIFO_MAX_FANOUT == 1) begin : gen_rdfifo_maxfanout1
         (* equivalent_register_removal = "no" *) 
         reg [C_NUM_PORTS*C_MEM_DATA_WIDTH-1:0] rdfifo_data_i_tmp;
         (* equivalent_register_removal = "no" *) 
         reg [C_NUM_PORTS-1:0]                  rdfifo_push_i_tmp;
         for (i=0;i<C_NUM_PORTS;i=i+1) begin : gen_rep_phyif_dp_dq_i
            always @(posedge Clk) begin
               rdfifo_data_i_tmp[(i+1)*C_MEM_DATA_WIDTH-1:
                                 i*C_MEM_DATA_WIDTH]
                                    <= PhyIF_DP_DQ_I;
            end
            assign rdfifo_data_i[(i+1)*C_MEM_DATA_WIDTH-1:
                                 i*C_MEM_DATA_WIDTH]
              = rdfifo_data_i_tmp[(i+1)*C_MEM_DATA_WIDTH-1:
                                  i*C_MEM_DATA_WIDTH];
            always @(posedge Clk) begin
               rdfifo_push_i_tmp[i] = Ctrl_DP_RdFIFO_Push &
                                      Ctrl_DP_RdFIFO_WhichPort_Decode[i];
            end
            assign rdfifo_push_i[i] = rdfifo_push_i_tmp[i];
         end
      end
      else if (C_RDFIFO_MAX_FANOUT == 2) begin : gen_rdfifo_maxfanout2
         (* equivalent_register_removal = "no" *) 
         reg [4*C_MEM_DATA_WIDTH-1:0] rdfifo_data_i_tmp;
         (* equivalent_register_removal = "no" *) 
         reg [C_NUM_PORTS-1:0]        rdfifo_push_i_tmp;
         for (i=0;i<C_NUM_PORTS;i=i+1) begin : gen_rep_rdfifo_push_i
            always @(posedge Clk) begin
               rdfifo_push_i_tmp[i] = Ctrl_DP_RdFIFO_Push &
                                      Ctrl_DP_RdFIFO_WhichPort_Decode[i];
            end
            assign rdfifo_push_i[i] = rdfifo_push_i_tmp[i];
         end
         for (i=0;i<C_NUM_PORTS;i=i+2) begin : gen_rep_phyif_dp_dq_i1
            always @(posedge Clk) begin
               rdfifo_data_i_tmp[(i/2+1)*C_MEM_DATA_WIDTH-1:
                                 i/2*C_MEM_DATA_WIDTH]
                                    <= PhyIF_DP_DQ_I;
            end
         end
         for (i=0;i<C_NUM_PORTS;i=i+2) begin : gen_rep_phyif_dp_dq_i2
            assign rdfifo_data_i[(i+1)*C_MEM_DATA_WIDTH-1:
                                 i*C_MEM_DATA_WIDTH]
                         = rdfifo_data_i_tmp[(i/2+1)*C_MEM_DATA_WIDTH-1:
                                             i/2*C_MEM_DATA_WIDTH];
         end
         for (i=1;i<C_NUM_PORTS;i=i+2) begin : gen_rep_phyif_dp_dq_i3
            assign rdfifo_data_i[(i+1)*C_MEM_DATA_WIDTH-1:
                                 i*C_MEM_DATA_WIDTH]
                         = rdfifo_data_i_tmp[((i-1)/2+1)*C_MEM_DATA_WIDTH-1:
                                             (i-1)/2*C_MEM_DATA_WIDTH];
         end
      end
      else if (C_RDFIFO_MAX_FANOUT == 4) begin : gen_rdfifo_maxfanout4
         (* equivalent_register_removal = "no" *) 
         reg [2*C_MEM_DATA_WIDTH-1:0] rdfifo_data_i_tmp;
         (* equivalent_register_removal = "no" *) 
         reg [C_NUM_PORTS-1:0]        rdfifo_push_i_tmp;
         for (i=0;i<C_NUM_PORTS;i=i+1) begin : gen_rep_rdfifo_push_i
            always @(posedge Clk) begin
               rdfifo_push_i_tmp[i] = Ctrl_DP_RdFIFO_Push &
                                      Ctrl_DP_RdFIFO_WhichPort_Decode[i];
            end
            assign rdfifo_push_i[i] = rdfifo_push_i_tmp[i];
         end
         for (i=0;i<C_NUM_PORTS;i=i+4) begin : gen_rep_phyif_dp_dq_i1
            always @(posedge Clk) begin
               rdfifo_data_i_tmp[(i/4+1)*C_MEM_DATA_WIDTH-1:
                                 i/4*C_MEM_DATA_WIDTH]
                          <= PhyIF_DP_DQ_I;
            end
         end
         for (i=0;i<C_NUM_PORTS;i=i+4) begin : gen_rep_phyif_dp_dq_2
            assign rdfifo_data_i[(i+1)*C_MEM_DATA_WIDTH-1:
                                 i*C_MEM_DATA_WIDTH]
                            = rdfifo_data_i_tmp[(i/4+1)*C_MEM_DATA_WIDTH-1:
                                                i/4*C_MEM_DATA_WIDTH];
         end
         for (i=1;i<C_NUM_PORTS;i=i+4) begin : gen_rep_phyif_dp_dq_i3
            assign rdfifo_data_i[(i+1)*C_MEM_DATA_WIDTH-1:
                                 i*C_MEM_DATA_WIDTH]
                            = rdfifo_data_i_tmp[((i-1)/4+1)*C_MEM_DATA_WIDTH-1:
                                                (i-1)/4*C_MEM_DATA_WIDTH];
         end
         for (i=2;i<C_NUM_PORTS;i=i+4) begin : gen_rep_phyif_dp_dq_i4
            assign rdfifo_data_i[(i+1)*C_MEM_DATA_WIDTH-1:
                                 i*C_MEM_DATA_WIDTH]
                            = rdfifo_data_i_tmp[((i-2)/4+1)*C_MEM_DATA_WIDTH-1:
                                                (i-2)/4*C_MEM_DATA_WIDTH];
         end
         for (i=3;i<C_NUM_PORTS;i=i+4) begin : gen_rep_phyif_dp_dq_i5
            assign rdfifo_data_i[(i+1)*C_MEM_DATA_WIDTH-1:
                                 i*C_MEM_DATA_WIDTH]
                            = rdfifo_data_i_tmp[((i-3)/4+1)*C_MEM_DATA_WIDTH-1:
                                                (i-3)/4*C_MEM_DATA_WIDTH];
         end
      end
      else if (C_RDFIFO_MAX_FANOUT == 8) begin : gen_rdfifo_maxfanout8
         (* equivalent_register_removal = "no" *) 
         reg [C_MEM_DATA_WIDTH-1:0] rdfifo_data_i_tmp;
         (* equivalent_register_removal = "no" *) 
         reg [C_NUM_PORTS-1:0]      rdfifo_push_i_tmp;
         for (i=0;i<C_NUM_PORTS;i=i+1) begin : gen_rep_rdfifo_push_i
            always @(posedge Clk) begin
               rdfifo_push_i_tmp[i] = Ctrl_DP_RdFIFO_Push &
                                      Ctrl_DP_RdFIFO_WhichPort_Decode[i];
            end
            assign rdfifo_push_i[i] = rdfifo_push_i_tmp[i];
         end
         always @(posedge Clk) begin
            rdfifo_data_i_tmp[C_MEM_DATA_WIDTH-1:0] <= PhyIF_DP_DQ_I;
         end
         for (i=0;i<C_NUM_PORTS;i=i+1) begin : gen_rep_phyif_dp_dq_i
            assign rdfifo_data_i[(i+1)*C_MEM_DATA_WIDTH-1:
                                 i*C_MEM_DATA_WIDTH]
                            = rdfifo_data_i_tmp[C_MEM_DATA_WIDTH-1:0];
         end
      end
      // Instantiate Read FIFOs
      for (i=0;i<C_NUM_PORTS;i=i+1) begin : gen_read_fifos
         always @(posedge Clk) begin
           if (Rst[i*2+1])
             PI_RdFIFO_Flush_tmp[i] <= 1'b0;
	   else
	     PI_RdFIFO_Flush_tmp[i] <= 
		      ~(PI_RdFIFO_Flush_tmp[i] & ~rdfifo_push_i[i]) & 
		      (PI_RdFIFO_Flush[i] | PI_RdFIFO_Flush_tmp[i]);
         end
         if (C_PI_RDFIFO_TYPE[(i+1)*2-1:i*2] == 2'b00) 
           begin : gen_fifos_disabled
              // Tie off Read FIFO outputs
              assign PI_RdFIFO_Empty[i] = 1'b1;
              assign DP_Ctrl_RdFIFO_AlmostFull[i] = 1'b0;
           end
         else begin : gen_fifos
            wire [((C_PI_DATA_WIDTH[i]==1'b1)?64:32)-1:0] PI_RdFIFO_Data_tmp;
            assign PI_RdFIFO_Data[(i+1)*C_PIX_DATA_WIDTH_MAX-1:
                                  i*C_PIX_DATA_WIDTH_MAX] = PI_RdFIFO_Data_tmp;
            mpmc_read_fifo #
              (
               .C_FAMILY         (C_FAMILY),
               .C_FIFO_TYPE      (C_PI_RDFIFO_TYPE[(i+1)*2-1:i*2]),
               .C_PI_PIPELINE    (C_RDFIFO_PI_PIPELINE[i]),
               .C_MEM_PIPELINE   (C_RDFIFO_MEM_PIPELINE[i]),
               .C_PI_ADDR_WIDTH  (C_PI_ADDR_WIDTH),
               .C_PI_DATA_WIDTH  ((C_PI_DATA_WIDTH[i]==1'b1) ? 64 : 32),
               .C_MEM_DATA_WIDTH (C_MEM_DATA_WIDTH),
               .C_IS_DDR         (C_IS_DDR)
               )
              mpmc_read_fifo_0
                (
                 .Clk               (Clk),
                 .Rst               (Rst[i*2+1]),
                 .AddrAck           (PI_AddrAck[i]),
                 .RNW               (PI_RNW[i]),
                 .Size              (PI_Size[(i+1)*4-1:i*4]),
                 .Addr              (PI_Addr[(i+1)*C_PI_ADDR_WIDTH-1:
                                             i*C_PI_ADDR_WIDTH]),
                 .Flush             (PI_RdFIFO_Flush_tmp[i] | PI_RdFIFO_Flush[i]),
                 .Push              (rdfifo_push_i[i]),
                 .Pop               (PI_RdFIFO_Pop[i]),
                 .Empty             (PI_RdFIFO_Empty[i]),
                 .AlmostFull        (DP_Ctrl_RdFIFO_AlmostFull[i]),
                 .PushData          (rdfifo_data_i[(i+1)*C_MEM_DATA_WIDTH-1:
                                                   i*C_MEM_DATA_WIDTH]),
                 .PopData           (PI_RdFIFO_Data_tmp),
                 .RdWdAddr          (PI_RdFIFO_RdWdAddr[(i+1)*4-1:i*4])
                 );
         end
      end
   endgenerate
endmodule // mpmc_data_path


