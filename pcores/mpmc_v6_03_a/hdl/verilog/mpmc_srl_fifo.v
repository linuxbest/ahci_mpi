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

module mpmc_srl_fifo #
  (
   parameter         C_FAMILY            = "virtex4",
   parameter         C_USE_INIT_PUSH     = 1'b1,
   parameter         C_INPUT_PIPELINE    = 1'b1,
   parameter         C_OUTPUT_PIPELINE   = 1'b1,
   parameter integer C_ADDR_WIDTH        =   13,
   parameter integer C_INPUT_DATA_WIDTH  =  128,
   parameter integer C_OUTPUT_DATA_WIDTH =   64,
   parameter         C_DIRECTION         = "write"
   )
  (
   // Input Clock/Rst
   input                              Clk,
   input                              Rst,
   // Used for Special Cases
   input                              SpecialCaseXfer,
   // Write Side
   input [C_ADDR_WIDTH-1:0]           PushAddr,
   input                              Push,
   input [C_INPUT_DATA_WIDTH-1:0]     PushData,
   input [C_INPUT_DATA_WIDTH/8-1:0]   PushParity,
   // Write Training Pattern Signals
   // Assumes that InitPush and related Pop do not happen on the same cycle.
   // Assumes that InitPush and Push do not happen on the same cycle.
   input                              InitDone,
   input                              InitPush,
   input [C_OUTPUT_DATA_WIDTH-1:0]    InitData,
   // Read Side
   input [C_ADDR_WIDTH-1:0]           PopAddr,
   input                              Pop,
   input                              ParityRst,
   output [C_OUTPUT_DATA_WIDTH-1:0]   PopData,
   output [C_OUTPUT_DATA_WIDTH/8-1:0] PopParity
   );

  localparam P_FIFO_ADDR_WIDTH = (C_FAMILY == "virtex5" || C_FAMILY == "virtex6") ? 5 : 4;
  localparam P_FIFO_DEPTH   = 2**C_ADDR_WIDTH;
  localparam P_NUM_SRLS_TMP = (C_FAMILY == "virtex5" || C_FAMILY == "virtex6") ? P_FIFO_DEPTH*8/32 :
                                                                                 P_FIFO_DEPTH*8/16 ;
  localparam P_NUM_SRLS     = (C_INPUT_DATA_WIDTH > C_OUTPUT_DATA_WIDTH) ?
                              ((C_INPUT_DATA_WIDTH > P_NUM_SRLS_TMP) ?
                               C_INPUT_DATA_WIDTH : P_NUM_SRLS_TMP) :
                              ((C_OUTPUT_DATA_WIDTH > P_NUM_SRLS_TMP) ?
                               C_OUTPUT_DATA_WIDTH : P_NUM_SRLS_TMP);
  localparam P_SRL_RES      = ((C_INPUT_DATA_WIDTH >= 16) && 
                               (C_OUTPUT_DATA_WIDTH >= 16)) ?
                              P_NUM_SRLS/16 : 
                              P_NUM_SRLS/8;
  localparam P_SRL_INPUT_REP = ((C_INPUT_DATA_WIDTH >= 16) && 
                               (C_OUTPUT_DATA_WIDTH >= 16)) ?
                               C_INPUT_DATA_WIDTH/16 : 
                               C_INPUT_DATA_WIDTH/8;
  localparam P_SRL_OUTPUT_REP = ((C_INPUT_DATA_WIDTH >= 16) && 
                                 (C_OUTPUT_DATA_WIDTH >= 16)) ?
                                C_OUTPUT_DATA_WIDTH/16 : 
                                C_OUTPUT_DATA_WIDTH/8;
  localparam P_PUSHADDR_STARTBIT = (C_INPUT_DATA_WIDTH ==   8) ? 0 :
                                   (C_INPUT_DATA_WIDTH ==  16) ? 1 :
                                   (C_INPUT_DATA_WIDTH ==  32) ? 2 :
                                   (C_INPUT_DATA_WIDTH ==  64) ? 3 :
                                   (C_INPUT_DATA_WIDTH == 128) ? 4 : 0;
  localparam P_INITPUSHADDR_STARTBIT = (C_OUTPUT_DATA_WIDTH ==   8) ? 0 :
                                       (C_OUTPUT_DATA_WIDTH ==  16) ? 1 :
                                       (C_OUTPUT_DATA_WIDTH ==  32) ? 2 :
                                       (C_OUTPUT_DATA_WIDTH ==  64) ? 3 :
                                       (C_OUTPUT_DATA_WIDTH == 128) ? 4 : 0;
  localparam P_POPADDR_STARTBIT = (C_OUTPUT_DATA_WIDTH ==   8) ? 0 :
                                  (C_OUTPUT_DATA_WIDTH ==  16) ? 1 :
                                  (C_OUTPUT_DATA_WIDTH ==  32) ? 2 :
                                  (C_OUTPUT_DATA_WIDTH ==  64) ? 3 :
                                  (C_OUTPUT_DATA_WIDTH == 128) ? 4 : 0;
  localparam P_ADDR_ENDBIT = (P_NUM_SRLS ==    8) ? 0 :
                             (P_NUM_SRLS ==   16) ? 0 :
                             (P_NUM_SRLS ==   32) ? 1 :
                             (P_NUM_SRLS ==   64) ? 2 :
                             (P_NUM_SRLS ==  128) ? 3 :
                             (P_NUM_SRLS ==  256) ? 4 :
                             (P_NUM_SRLS ==  512) ? 5 :
                             (P_NUM_SRLS == 1024) ? 6 : 0;
  localparam P_SEL_WIDTH   = (P_NUM_SRLS/C_OUTPUT_DATA_WIDTH ==  1) ? 1 :
                             (P_NUM_SRLS/C_OUTPUT_DATA_WIDTH ==  2) ? 1 :
                             (P_NUM_SRLS/C_OUTPUT_DATA_WIDTH ==  4) ? 2 :
                             (P_NUM_SRLS/C_OUTPUT_DATA_WIDTH ==  8) ? 3 :
                             (P_NUM_SRLS/C_OUTPUT_DATA_WIDTH == 16) ? 4 : 0;
  
  wire [P_SRL_RES-1:0]                   Push_tmp;
  wire [P_SRL_RES-1:0]                   Push_final /* synthesis syn_keep=1 */;
  wire [P_SRL_RES-1:0]                   Push_r;
  wire [C_ADDR_WIDTH-1:0]                PushAddr_r;
  wire [C_INPUT_DATA_WIDTH-1:0]          PushData_r;
  wire [P_NUM_SRLS-1:0]                  PushData_r_tmp;
  wire [P_NUM_SRLS-1:0]                  PushData_r_final;
  wire [C_INPUT_DATA_WIDTH/8-1:0]        PushParity_r;
  wire [P_NUM_SRLS/8-1:0]                PushParity_r_final;
  wire [C_OUTPUT_DATA_WIDTH-1:0]         InitData_r;

  wire [P_FIFO_ADDR_WIDTH*P_SRL_RES-1:0] fifoaddr /* synthesis syn_keep=1 */;
  
  wire [P_SRL_RES-1:0]                   Pop_tmp;
  wire [P_SRL_RES-1:0]                   Pop_final /* synthesis syn_keep=1 */;
  
  wire [P_NUM_SRLS-1:0]                  PopData_r0;
  reg [P_NUM_SRLS-1:0]                   PopData_r1;
  wire [C_OUTPUT_DATA_WIDTH-1:0]         PopData_r;
  wire [P_NUM_SRLS/8-1:0]                PopParity_r0;
  reg [P_NUM_SRLS/8-1:0]                 PopParity_r1;
  wire [C_OUTPUT_DATA_WIDTH/8-1:0]       PopParity_r;
  
  reg                                    ParityRst_r1;
  reg [C_ADDR_WIDTH-1:0]                 PopAddr_r1;
  
  genvar i;
  genvar j;
  
  // Instantiate push logic
  mpmc_srl_fifo_gen_push_tmp #
    (
     .C_SRL_RES           (P_SRL_RES),
     .C_SRL_INPUT_REP     (P_SRL_INPUT_REP),
     .C_NUM_SRLS          (P_NUM_SRLS),
     .C_ADDR_WIDTH        (C_ADDR_WIDTH),
     .C_INPUT_DATA_WIDTH  (C_INPUT_DATA_WIDTH),
     .C_ADDR_ENDBIT       (P_ADDR_ENDBIT),
     .C_PUSHADDR_STARTBIT (P_PUSHADDR_STARTBIT)
     )
    gen_push_tmp_0
      (
       .Push     (Push),
       .PushAddr (PushAddr),
       .Push_tmp (Push_tmp)
       );
  
  generate
    if ((C_DIRECTION == "write") && 
        (((C_INPUT_DATA_WIDTH==32) && (C_OUTPUT_DATA_WIDTH== 64)) ||
         ((C_INPUT_DATA_WIDTH==32) && (C_OUTPUT_DATA_WIDTH==128)) ||
         ((C_INPUT_DATA_WIDTH==64) && (C_OUTPUT_DATA_WIDTH==128)))) 
      begin : gen_write_push_sc
        wire [P_SRL_RES-1:0] Push_sc_tmp;
        if (C_USE_INIT_PUSH) begin : gen_initpush
          wire [P_SRL_RES-1:0] InitPush_tmp;
          mpmc_srl_fifo_gen_push_tmp #
            (
             .C_SRL_RES           (P_SRL_RES),
             .C_SRL_INPUT_REP     (P_SRL_OUTPUT_REP),
             .C_NUM_SRLS          (P_NUM_SRLS),
             .C_ADDR_WIDTH        (C_ADDR_WIDTH),
             .C_INPUT_DATA_WIDTH  (C_OUTPUT_DATA_WIDTH),
             .C_ADDR_ENDBIT       (P_ADDR_ENDBIT),
             .C_PUSHADDR_STARTBIT (P_INITPUSHADDR_STARTBIT)
             )
            gen_initpush_tmp_0
              (
               .Push     (InitPush),
               .PushAddr (PushAddr),
               .Push_tmp (InitPush_tmp)
               );
          assign Push_final = InitDone ? (SpecialCaseXfer ? Push_sc_tmp :
                                                            Push_tmp) :
                                          InitPush_tmp;
        end else begin : gen_normal
          assign Push_final = SpecialCaseXfer ? Push_sc_tmp : Push_tmp;
        end
        mpmc_srl_fifo_gen_push_tmp #
          (
           .C_SRL_RES           (P_SRL_RES),
           .C_SRL_INPUT_REP     (P_SRL_OUTPUT_REP),
           .C_NUM_SRLS          (P_NUM_SRLS),
           .C_ADDR_WIDTH        (C_ADDR_WIDTH),
           .C_INPUT_DATA_WIDTH  (C_OUTPUT_DATA_WIDTH),
           .C_ADDR_ENDBIT       (P_ADDR_ENDBIT),
           .C_PUSHADDR_STARTBIT (P_POPADDR_STARTBIT)
           )
          gen_push_sc_tmp_0
            (
             .Push     (Push),
             .PushAddr (PushAddr),
             .Push_tmp (Push_sc_tmp)
             );
      end
    else begin : gen_write_push_nosc
      if (C_DIRECTION == "write") begin : gen_write
        if (C_USE_INIT_PUSH) begin : gen_initpush
          wire [P_SRL_RES-1:0] InitPush_tmp;
          mpmc_srl_fifo_gen_push_tmp #
            (
             .C_SRL_RES           (P_SRL_RES),
             .C_SRL_INPUT_REP     (P_SRL_OUTPUT_REP),
             .C_NUM_SRLS          (P_NUM_SRLS),
             .C_ADDR_WIDTH        (C_ADDR_WIDTH),
             .C_INPUT_DATA_WIDTH  (C_OUTPUT_DATA_WIDTH),
             .C_ADDR_ENDBIT       (P_ADDR_ENDBIT),
             .C_PUSHADDR_STARTBIT (P_INITPUSHADDR_STARTBIT)
             )
            gen_initpush_tmp_0
              (
               .Push     (InitPush),
               .PushAddr (PushAddr),
               .Push_tmp (InitPush_tmp)
               );
          assign Push_final = InitDone ? Push_tmp : InitPush_tmp;
        end else begin : gen_normal
          assign Push_final = Push_tmp;
        end
      end
      else begin : gen_read
        assign Push_final = Push_tmp;
      end
    end
  endgenerate

  // Instantiate optional input pipeline register.
  mpmc_srl_fifo_gen_input_pipeline #
    (
     .C_INPUT_PIPELINE    (C_INPUT_PIPELINE),
     .C_DIRECTION         (C_DIRECTION),
     .C_SRL_RES           (P_SRL_RES),
     .C_ADDR_WIDTH        (C_ADDR_WIDTH),
     .C_INPUT_DATA_WIDTH  (C_INPUT_DATA_WIDTH),
     .C_OUTPUT_DATA_WIDTH (C_OUTPUT_DATA_WIDTH)
     )
    gen_input_pipeline_0
      (
       .Clk               (Clk),
       .Push              (Push_final),
       .PushAddr          (PushAddr),
       .PushData          (PushData),
       .PushParity        (PushParity),
       .InitData          (InitData),
       .Push_r            (Push_r),
       .PushAddr_r        (PushAddr_r),
       .PushData_r        (PushData_r),
       .PushParity_r      (PushParity_r),
       .InitData_r        (InitData_r)
       );
  
  // Replicate Data
  generate
    reg [P_SRL_RES-1:0] Push_tmp_r;
    for (i=0;i<P_NUM_SRLS/C_INPUT_DATA_WIDTH;i=i+1) begin : gen_rep_pushdata
      assign PushData_r_tmp[(i+1)*C_INPUT_DATA_WIDTH-1:
                            i*C_INPUT_DATA_WIDTH] = PushData_r;
    end
    if (C_DIRECTION == "write") begin : gen_write_pushdata
      wire [P_NUM_SRLS/8-1:0] PushParity_r_tmp;
      if (C_USE_INIT_PUSH) begin : gen_initpush
        wire [P_NUM_SRLS-1:0]   InitData_r_tmp;
        for (i=0;i<P_NUM_SRLS/C_OUTPUT_DATA_WIDTH;i=i+1) 
          begin : gen_rep_initdata
            assign InitData_r_tmp[(i+1)*C_OUTPUT_DATA_WIDTH-1:
                                  i*C_OUTPUT_DATA_WIDTH] = InitData_r;
          end
        for (i=0;i<P_NUM_SRLS;i=i+1) begin : gen_rep_data_final
          assign PushData_r_final[i] = InitDone ? PushData_r_tmp[i] :
                                                  InitData_r_tmp[i];
        end
      end else begin : gen_normal
        for (i=0;i<P_NUM_SRLS;i=i+1) begin : gen_rep_data_final
          assign PushData_r_final[i] = PushData_r_tmp[i];
        end
      end
      if (((C_INPUT_DATA_WIDTH==32) && (C_OUTPUT_DATA_WIDTH== 64)) ||
          ((C_INPUT_DATA_WIDTH==32) && (C_OUTPUT_DATA_WIDTH==128)) ||
          ((C_INPUT_DATA_WIDTH==64) && (C_OUTPUT_DATA_WIDTH==128))) 
        begin : gen_push_tmp_r_sc
          if (C_INPUT_PIPELINE == 1) begin : gen_push_tmp_r
            always @(posedge Clk) 
              Push_tmp_r <= Push_tmp;
          end else begin : gen_push_tmp_r0
            always @(*) 
              Push_tmp_r <= Push_tmp;
          end
          for (i=0;i<P_NUM_SRLS/C_INPUT_DATA_WIDTH;i=i+1) 
            begin : gen_rep_parity
              for (j=0;j<P_SRL_INPUT_REP;j=j+1) begin : gen_rep
                assign PushParity_r_tmp[i*C_INPUT_DATA_WIDTH/8 +
                                        (j+1)*C_INPUT_DATA_WIDTH/8/
                                        P_SRL_INPUT_REP - 1:
                                        i*C_INPUT_DATA_WIDTH/8 +
                                        j*C_INPUT_DATA_WIDTH/8/
                                        P_SRL_INPUT_REP] = 
                              Push_tmp_r[i*P_SRL_INPUT_REP+j] ? 
                                   PushParity_r[(j+1)*C_INPUT_DATA_WIDTH/8/
                                                P_SRL_INPUT_REP-1:
                                                j*C_INPUT_DATA_WIDTH/8/
                                                P_SRL_INPUT_REP] : 
                                   {C_INPUT_DATA_WIDTH/8/
                                    P_SRL_INPUT_REP{1'b0}};
              end
            end
        end else begin : gen_push_tmp_r_nosc
          for (i=0;i<P_NUM_SRLS/C_INPUT_DATA_WIDTH;i=i+1) 
            begin : gen_rep_parity
              assign PushParity_r_tmp[(i+1)*C_INPUT_DATA_WIDTH/8-1:
                                      i*C_INPUT_DATA_WIDTH/8] = PushParity_r;
            end
        end
      assign PushParity_r_final = InitDone ? PushParity_r_tmp : 
                                             {P_NUM_SRLS/8{1'b1}};
    end
    else begin : gen_read_pushdata
      assign PushData_r_final   = PushData_r_tmp;
      assign PushParity_r_final = {P_NUM_SRLS/8{1'b0}};
    end
  endgenerate

  // Instantiate optional output pipeline register.
  mpmc_srl_fifo_gen_output_pipeline #
    (
     .C_OUTPUT_PIPELINE   (C_OUTPUT_PIPELINE),
     .C_OUTPUT_DATA_WIDTH (C_OUTPUT_DATA_WIDTH),
     .C_DIRECTION         (C_DIRECTION)
     )
    gen_output_pipeline_0
      (
       .Clk         (Clk),
       .Pop         (Pop),
       .PopData_r   (PopData_r),
       .PopParity_r (PopParity_r),
       .ParityRst_r (ParityRst_r1),
       .PopData     (PopData),
       .PopParity   (PopParity)
       );
  

  // Instantiate logic for FIFO address generation
  generate
    for (i=0;i<P_SRL_RES;i=i+1) begin : gen_fifoaddr
      mpmc_srl_fifo_gen_fifoaddr #
        (
         .C_FIFO_ADDR_WIDTH (P_FIFO_ADDR_WIDTH)
         )
        gen_fifoaddr_0
          (
           .Rst      (Rst),
           .Clk      (Clk),
           .Push     (Push_r[i]),
           .Pop      (Pop_final[i]),
           .FIFOAddr (fifoaddr[(i+1)*P_FIFO_ADDR_WIDTH-1:i*P_FIFO_ADDR_WIDTH])
           );
    end
  endgenerate
  
  // Instantiate pop logic
  mpmc_srl_fifo_gen_push_tmp #
    (
     .C_SRL_RES           (P_SRL_RES),
     .C_SRL_INPUT_REP     (P_SRL_OUTPUT_REP),
     .C_NUM_SRLS          (P_NUM_SRLS),
     .C_ADDR_WIDTH        (C_ADDR_WIDTH),
     .C_INPUT_DATA_WIDTH  (C_OUTPUT_DATA_WIDTH),
     .C_ADDR_ENDBIT       (P_ADDR_ENDBIT),
     .C_PUSHADDR_STARTBIT (P_POPADDR_STARTBIT)
     )
    gen_pop_tmp_0
      (
       .Push     (Pop),
       .PushAddr (PopAddr),
       .Push_tmp (Pop_tmp)
       );
  
  generate
    if ((C_DIRECTION == "read") && 
        (((C_INPUT_DATA_WIDTH== 64) && (C_OUTPUT_DATA_WIDTH==32)) ||
         ((C_INPUT_DATA_WIDTH==128) && (C_OUTPUT_DATA_WIDTH==32)) ||
         ((C_INPUT_DATA_WIDTH==128) && (C_OUTPUT_DATA_WIDTH==64)))) 
      begin : gen_read_pop_sc
        wire [P_SRL_RES-1:0] Pop_sc_tmp;
        mpmc_srl_fifo_gen_push_tmp #
          (
           .C_SRL_RES           (P_SRL_RES),
           .C_SRL_INPUT_REP     (P_SRL_INPUT_REP),
           .C_NUM_SRLS          (P_NUM_SRLS),
           .C_ADDR_WIDTH        (C_ADDR_WIDTH),
           .C_INPUT_DATA_WIDTH  (C_INPUT_DATA_WIDTH),
           .C_ADDR_ENDBIT       (P_ADDR_ENDBIT),
           .C_PUSHADDR_STARTBIT (P_PUSHADDR_STARTBIT)
           )
          gen_pop_sc_tmp_0
            (
             .Push     (Pop),
             .PushAddr (PopAddr),
             .Push_tmp (Pop_sc_tmp)
             );
        assign Pop_final = SpecialCaseXfer ? Pop_sc_tmp :
                                             Pop_tmp;
      end
    else begin : gen_read_pop_nosc
      assign Pop_final = Pop_tmp;
    end
  endgenerate

  // Instantiate logic for SRL output mux selection
  mpmc_srl_fifo_nto1_mux #
    (
     .C_RATIO         (P_NUM_SRLS/C_OUTPUT_DATA_WIDTH),
     .C_SEL_WIDTH     (P_SEL_WIDTH),
     .C_DATAOUT_WIDTH (C_OUTPUT_DATA_WIDTH)
     )
    nto1_mux_0
      (
       .Sel (PopAddr_r1[P_POPADDR_STARTBIT+P_SEL_WIDTH-1:
                        P_POPADDR_STARTBIT]),
       .In  (PopData_r1),
       .Out (PopData_r)
       );
  mpmc_srl_fifo_nto1_mux #
    (
     .C_RATIO         (P_NUM_SRLS/C_OUTPUT_DATA_WIDTH),
     .C_SEL_WIDTH     (P_SEL_WIDTH),
     .C_DATAOUT_WIDTH (C_OUTPUT_DATA_WIDTH/8)
     )
    nto1_mux_par0
      (
       .Sel (PopAddr_r1[P_POPADDR_STARTBIT+P_SEL_WIDTH-1:
                        P_POPADDR_STARTBIT]),
       .In  (PopParity_r1),
       .Out (PopParity_r)
       );

  // Instantiate SRLs
  generate
    if (C_FAMILY == "virtex5" || C_FAMILY == "virtex6") begin : gen_srl32s
      for (i=0;i<P_SRL_RES;i=i+1) begin : gen_res
        for (j=0;j<P_NUM_SRLS/P_SRL_RES;j=j+1) begin : gen_bit
          SRLC32E
            srl_fifos_0
              (
               .CLK (Clk),
               .A   (fifoaddr[(i+1)*P_FIFO_ADDR_WIDTH-1:i*P_FIFO_ADDR_WIDTH]),
               .CE  (Push_r[i]),
               .D   (PushData_r_final[i*P_NUM_SRLS/P_SRL_RES+j]),
               .Q   (PopData_r0[i*P_NUM_SRLS/P_SRL_RES+j]),
               .Q31 ()
               );
        end
        for (j=0;j<P_NUM_SRLS/8/P_SRL_RES;j=j+1) begin : gen_bit_par
          SRLC32E
            srl_fifos_0
              (
               .CLK (Clk),
               .A   (fifoaddr[(i+1)*P_FIFO_ADDR_WIDTH-1:i*P_FIFO_ADDR_WIDTH]),
               .CE  (Push_r[i]),
               .D   (PushParity_r_final[i*P_NUM_SRLS/8/P_SRL_RES+j]),
               .Q   (PopParity_r0[i*P_NUM_SRLS/8/P_SRL_RES+j]),
               .Q31 ()
               );
        end
      end
    end
    else begin : gen_srl16s
      for (i=0;i<P_SRL_RES;i=i+1) begin : gen_res
        for (j=0;j<P_NUM_SRLS/P_SRL_RES;j=j+1) begin : gen_bit
          SRLC16E
            srl_fifos_0
              (
               .CLK (Clk),
               .A0  (fifoaddr[i*P_FIFO_ADDR_WIDTH+0]),
               .A1  (fifoaddr[i*P_FIFO_ADDR_WIDTH+1]),
               .A2  (fifoaddr[i*P_FIFO_ADDR_WIDTH+2]),
               .A3  (fifoaddr[i*P_FIFO_ADDR_WIDTH+3]),
               .CE  (Push_r[i]),
               .D   (PushData_r_final[i*P_NUM_SRLS/P_SRL_RES+j]),
               .Q   (PopData_r0[i*P_NUM_SRLS/P_SRL_RES+j]),
               .Q15 ()
               );
        end
        for (j=0;j<P_NUM_SRLS/8/P_SRL_RES;j=j+1) begin : gen_bit_par
          SRLC16E
            srl_fifos_0
              (
               .CLK (Clk),
               .A0  (fifoaddr[i*P_FIFO_ADDR_WIDTH+0]),
               .A1  (fifoaddr[i*P_FIFO_ADDR_WIDTH+1]),
               .A2  (fifoaddr[i*P_FIFO_ADDR_WIDTH+2]),
               .A3  (fifoaddr[i*P_FIFO_ADDR_WIDTH+3]),
               .CE  (Push_r[i]),
               .D   (PushParity_r_final[i*P_NUM_SRLS/8/P_SRL_RES+j]),
               .Q   (PopParity_r0[i*P_NUM_SRLS/8/P_SRL_RES+j]),
               .Q15 ()
               );
        end
      end
    end
  endgenerate
  always @(posedge Clk) begin
    PopData_r1   <= PopData_r0;
    PopParity_r1 <= PopParity_r0;
    ParityRst_r1 <= ParityRst;
    PopAddr_r1   <= PopAddr;
  end
  
endmodule // mpmc_srl_fifo

