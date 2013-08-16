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

`timescale 1ns/1ns
`default_nettype none

module ecc_top
#(
  parameter C_FAMILY                        = "virtex5",
  parameter C_USE_MIG_S3_PHY                = 0,
  parameter C_USE_MIG_V4_PHY                = 0,
  parameter C_USE_MIG_V5_PHY                = 0,
  parameter C_USE_MIG_V6_PHY                = 0,
  parameter C_USE_INIT_PUSH                 = 0,
  parameter C_WR_DATAPATH_TML_PIPELINE      = 0,
  parameter C_NUM_PORTS                     = 1,
  parameter C_USE_STATIC_PHY                = 1'b0,
  parameter C_IS_DDR                        = 1'b1,
  parameter C_MEM_TYPE                      = "DDR",
  parameter C_MEM_DATA_WIDTH                = 8,
  parameter C_MEM_DATA_WIDTH_INT            = 16,
  parameter C_MEM_DQS_WIDTH                 = 1,
  parameter C_MEM_DM_WIDTH_INT              = 1,
  parameter C_ECC_DATA_WIDTH                = 8,
  parameter C_ECC_DATA_WIDTH_INT            = 5,
  parameter C_ECC_DQS_WIDTH                 = 1,
  parameter C_ECC_DM_WIDTH_INT              = 1,
  parameter C_ECC_DECODE_PIPELINE           = 1,
  parameter C_ECC_ENCODE_PIPELINE           = 1,
  parameter C_ECC_DEFAULT_ON                = 1,
  parameter C_ECC_SEC_THRESHOLD             = 1,
  parameter C_ECC_DEC_THRESHOLD             = 1,
  parameter C_ECC_PEC_THRESHOLD             = 1,
  parameter C_INCLUDE_ECC_TEST              = 1,
  parameter C_WR_FIFO_MEM_PIPELINE_SINGLE   = 1,
  parameter C_ECC_NUM_REG                   = 1,
  parameter C_WDF_RDEN_EARLY                = 1,
  parameter RDF_PUSH_BITS                   = 1,
  parameter C_DELAY_PHYIF_DP_WRFIFO_POP     = 1
)
(
  input  wire                       Clk0,
  input  wire                       Clk90,
  input  wire                       Clk_WrFIFO_TML,
  input  wire                       Rst,
  input  wire                       InitDone,
  input  wire                       Bypass_Decode,
  input  wire [7:0]                 ecc_write_data0,
  input  wire [7:0]                 ecc_write_data1,
  input  wire [7:0]                 ecc_write_data2,
  input  wire [7:0]                 ecc_write_data3,

  input  wire [C_NUM_PORTS-1:0]     Ctrl_DP_RdFIFO_WhichPort_Decode,
  input  wire [3:0]                 Ctrl_ECC_RdFIFO_Size_i,
  input  wire                       Ctrl_ECC_RdFIFO_RNW_i,
  input  wire [31:0]                Ctrl_ECC_RdFIFO_Addr,
  output reg  [3:0]                 Ctrl_ECC_RdFIFO_Size,
  output reg                        Ctrl_ECC_RdFIFO_RNW,
  input  wire                       Ctrl_RMW,
  output reg  [C_NUM_PORTS-1:0]     Ctrl_DP_RdFIFO_WhichPort_Decode_i,

  input  wire [C_MEM_DM_WIDTH_INT-1:0] DP_PhyIF_BE_O,
  input  wire [C_MEM_DATA_WIDTH_INT-1:0] DP_PhyIF_DQ_O,
  input  wire [RDF_PUSH_BITS-1:0]   PhyIF_DP_RdFIFO_Push_tmp, 
  input  wire                       PhyIF_Ctrl_InitDone_19,
  input  wire [C_NUM_PORTS-1:0]     PhyIF_DP_WrFIFO_Pop_i,
  input  wire [C_NUM_PORTS-1:0]     PhyIF_DP_WrFIFO_Pop,
  input  wire                       PhyIF_Ctrl_InitDone_270,
  output reg                        PhyIF_DP_RdFIFO_Push,
  output wire [C_MEM_DATA_WIDTH_INT-1:0] PhyIF_DP_DQ_I,

  input  wire [C_ECC_DATA_WIDTH*(C_IS_DDR+1)+C_MEM_DATA_WIDTH_INT-1:0] rd_data,
  output wire [C_ECC_DATA_WIDTH*(C_IS_DDR+1)+C_MEM_DATA_WIDTH_INT-1:0] wdf_data,
  output reg  [C_ECC_DM_WIDTH_INT+C_MEM_DM_WIDTH_INT-1:0] wdf_mask_data = {(C_ECC_DM_WIDTH_INT+C_MEM_DM_WIDTH_INT){1'b0}},

  input  wire [31:0]                ECC_Reg_In,
  input  wire [C_ECC_NUM_REG-1:0]   ECC_Reg_CE,
  output wire                       ECC_Intr,
  output wire [C_ECC_NUM_REG*32-1:0]ECC_Reg_Out
);

  wire [C_MEM_DATA_WIDTH_INT-1:0]   RMW_PhyIF_DQ_O;
  wire [C_MEM_DATA_WIDTH_INT-1:0]   ECC_EncIn_DQ_O;
  wire [2:0]                        ECC_Force_Error;
  wire [2:0]                        ECC_Data_Error_0;
  wire [2:0]                        ECC_Data_Error_i0;
  wire [2:0]                        ECC_Data_Error_1;
  wire [2:0]                        ECC_Data_Error_i1;
  wire [7:0]                        ECC_Err_Synd_0;
  wire [7:0]                        ECC_Err_Synd_1;
  wire                              ECC_Encode_En;
  wire                              ECC_Decode_En;
  wire [C_MEM_DATA_WIDTH_INT-1:0]   PhyIF_DP_DQ_I_tmp;
  reg                               PhyIF_DP_RdFIFO_Push_d1 = 0;
  reg                               PhyIF_DP_RdFIFO_Push_RMW_i = 0;
  reg                               PhyIF_DP_RdFIFO_Push_RMW_i2 = 0;
  reg [3:0]                         Ctrl_ECC_RdFIFO_Size_i2 = 0;
  reg [3:0]                         Ctrl_ECC_RdFIFO_Size_i3 = 0;
  reg [3:0]                         Ctrl_ECC_RdFIFO_Size_i4 = 0;
  reg                               Ctrl_ECC_RdFIFO_RNW_i2 = 0;
  reg                               Ctrl_ECC_RdFIFO_RNW_i3 = 0;
  reg                               Ctrl_ECC_RdFIFO_RNW_i4 = 0;
  reg                               PhyIF_DP_RdFIFO_Push_i = 0;
  reg                               PhyIF_DP_RdFIFO_Push_i1 = 0;
  reg [C_NUM_PORTS-1:0]             Ctrl_DP_RdFIFO_WhichPort_Decode_i1 = 0;
  reg [C_NUM_PORTS-1:0]             Ctrl_DP_RdFIFO_WhichPort_Decode_i2 = 0;
  reg [C_NUM_PORTS-1:0]             Ctrl_DP_RdFIFO_WhichPort_Decode_i3 = 0;
  reg [C_NUM_PORTS-1:0]             Ctrl_DP_RdFIFO_WhichPort_Decode_i4 = 0;
  reg [C_ECC_DATA_WIDTH*(C_IS_DDR+1)+C_MEM_DATA_WIDTH_INT-1:0] rd_data_d1 = 0;
  reg [C_ECC_DATA_WIDTH*(C_IS_DDR+1)+C_MEM_DATA_WIDTH_INT-1:0] rd_data_d2 = 0;
  reg [C_ECC_DATA_WIDTH*(C_IS_DDR+1)+C_MEM_DATA_WIDTH_INT-1:0] rd_data_d3 = 0;
  reg                               PhyIF_DP_WrFIFO_Pop_d1 = 0;
  reg                               PhyIF_DP_WrFIFO_Pop_d2 = 0;
  reg                               PhyIF_DP_WrFIFO_Pop_d3 = 0;
  wire                              ECC_Shift_CE;
  reg                               PhyIF_DP_RdFIFO_Push_RMW = 0;
  reg [C_MEM_DM_WIDTH_INT-1:0]      DP_PhyIF_BE_O_d1 = 0;
  reg                               PhyIF_DP_WrFIFO_Pop_RMW = 0;
  reg [31:0]                        Ctrl_ECC_RdFIFO_Addr_precise;
  reg                               Ctrl_RMW_d1;
  reg                               Ctrl_RMW_d2;
  reg                               Ctrl_RMW_d3;
  reg                               Ctrl_RMW_d2_i1;
  reg                               Ctrl_RMW_d2_i2;
  reg                               Ctrl_RMW_d2_i3;
  reg                               Ctrl_RMW_d2_i4;
  wire [C_ECC_DATA_WIDTH*(C_IS_DDR+1)+C_MEM_DATA_WIDTH_INT-1:0] wdf_data_tmp;

  reg  wdf_data_toggle_i3a;
  reg  wdf_data_toggle_i3b;
  reg  wdf_data_toggle_i1;
  reg  wdf_data_toggle_i2;
  reg  wdf_data_toggle_i3;
  reg  wdf_data_toggle_i4;
  reg  wdf_data_toggle;
  

  always @(posedge Clk0) begin
    if (PhyIF_DP_WrFIFO_Pop[0] == 1'b0) begin
      wdf_data_toggle_i1 <= 1'b0;
    end else begin
      wdf_data_toggle_i1 <= ~wdf_data_toggle_i1;
    end
    wdf_data_toggle_i2 <= wdf_data_toggle_i1;
    wdf_data_toggle_i3a <= wdf_data_toggle_i3;
    wdf_data_toggle_i3b <= wdf_data_toggle_i3a;
    wdf_data_toggle_i4 <= wdf_data_toggle_i3b;
  end

  ///////////////////////////////////////////////////////////////////////////
  //If the PIPELINE is set this should be a flop
  generate 
    if (C_WR_FIFO_MEM_PIPELINE_SINGLE) begin : gen_mempipe
      always @(posedge Clk0) begin
        wdf_data_toggle_i3 <= wdf_data_toggle_i2;
      end
    end else begin : gen_nomempipe
      always @(*) begin
        wdf_data_toggle_i3 = wdf_data_toggle_i2;
      end
    end

    if (C_WR_DATAPATH_TML_PIPELINE == 0)  begin : gen_no_tml_pipeline
      if (C_IS_DDR == 0) begin : gen_ddr
        always @ (*) begin             
          wdf_data_toggle = wdf_data_toggle_i3b;
        end
      end else begin : gen_noddr
        always @(posedge Clk_WrFIFO_TML) begin
          wdf_data_toggle <= wdf_data_toggle_i3b;
        end
      end
    end else begin : gen_tml_pipeline
      always @(posedge Clk0) begin
        wdf_data_toggle <= wdf_data_toggle_i3b;
      end
    end
  endgenerate

  genvar i;
  
  always @(posedge Clk0)
    begin
      PhyIF_DP_RdFIFO_Push_d1 <= PhyIF_DP_RdFIFO_Push;
      Ctrl_RMW_d1 <= Ctrl_RMW;
      Ctrl_RMW_d2 <= Ctrl_RMW_d1;
      Ctrl_RMW_d3 <= Ctrl_RMW_d2_i4;
    end

  generate
    if (C_ECC_DECODE_PIPELINE == 1)
      begin : gen_ctrl_dp_rdfifo_push_pipeline
        always @(posedge Clk0)
          begin
            PhyIF_DP_RdFIFO_Push_RMW     <= PhyIF_DP_RdFIFO_Push_RMW_i2;
            PhyIF_DP_RdFIFO_Push         <= PhyIF_DP_RdFIFO_Push_i;
            Ctrl_DP_RdFIFO_WhichPort_Decode_i <=Ctrl_DP_RdFIFO_WhichPort_Decode_i4;
            Ctrl_ECC_RdFIFO_Size         <= Ctrl_ECC_RdFIFO_Size_i4;
            Ctrl_ECC_RdFIFO_RNW          <= Ctrl_ECC_RdFIFO_RNW_i4;
          end
      end
    else
      begin : gen_ctrl_dp_rdfifo_push_nopipeline
        always @(*)
          begin
            PhyIF_DP_RdFIFO_Push_RMW     <= PhyIF_DP_RdFIFO_Push_RMW_i2;
            PhyIF_DP_RdFIFO_Push         <= PhyIF_DP_RdFIFO_Push_i;
            Ctrl_DP_RdFIFO_WhichPort_Decode_i <=Ctrl_DP_RdFIFO_WhichPort_Decode_i4;
            Ctrl_ECC_RdFIFO_Size         <= Ctrl_ECC_RdFIFO_Size_i4;
            Ctrl_ECC_RdFIFO_RNW          <= Ctrl_ECC_RdFIFO_RNW_i4;
          end
      end
  endgenerate 

  always @(posedge Clk0)
    if (Rst | ~(PhyIF_DP_RdFIFO_Push | PhyIF_DP_RdFIFO_Push_RMW))
      Ctrl_ECC_RdFIFO_Addr_precise <= Ctrl_ECC_RdFIFO_Addr;
    else if (PhyIF_DP_RdFIFO_Push | PhyIF_DP_RdFIFO_Push_RMW)
      Ctrl_ECC_RdFIFO_Addr_precise <= Ctrl_ECC_RdFIFO_Addr_precise 
                                      + C_MEM_DATA_WIDTH_INT/8;

  mpmc_ecc_control #
    (
     .C_ECC_DEFAULT_ON    (C_ECC_DEFAULT_ON),
     .C_ECC_SEC_THRESHOLD (C_ECC_SEC_THRESHOLD),
     .C_ECC_DEC_THRESHOLD (C_ECC_DEC_THRESHOLD),
     .C_ECC_PEC_THRESHOLD (C_ECC_PEC_THRESHOLD)
     )
    mpmc_ecc_control_0
      (
       .Clk           (Clk0),
       .Rst           (Rst),
       .ECC_Intr      (ECC_Intr),
       .ECC_Reg_In    (ECC_Reg_In),
       .ECCCR_Wr      (ECC_Reg_CE[0]),
       .ECCCR         (ECC_Reg_Out[0*32 +:32]),
       .ECCSR_Clr     (ECC_Reg_CE[1]),
       .ECCSR         (ECC_Reg_Out[1*32 +:32]),
       .ECCSEC_Clr    (ECC_Reg_CE[2]),
       .ECCSEC        (ECC_Reg_Out[2*32 +:32]),
       .ECCDEC_Clr    (ECC_Reg_CE[3]),
       .ECCDEC        (ECC_Reg_Out[3*32 +:32]),
       .ECCPEC_Clr    (ECC_Reg_CE[4]),
       .ECCPEC        (ECC_Reg_Out[4*32 +:32]),
       .Data_Addr     (Ctrl_ECC_RdFIFO_Addr_precise),
       .ECCADDR       (ECC_Reg_Out[5*32 +:32]),
       .DGIE_Wr       (ECC_Reg_CE[7]),
       .DGIE          (ECC_Reg_Out[7*32 +:32]),
       .IPISR_Wr      (ECC_Reg_CE[8]),
       .IPISR         (ECC_Reg_Out[8*32 +:32]),
       .IPIER_Wr      (ECC_Reg_CE[9]),
       .IPIER         (ECC_Reg_Out[9*32 +:32]),
       .Force_Error   (ECC_Force_Error),
       .Bypass_Decode (Bypass_Decode),
       .Decode_En     (ECC_Decode_En),
       .Encode_En     (ECC_Encode_En),
       .Data_Error_0  (ECC_Data_Error_0),
       .Data_Error_1  (ECC_Data_Error_1),
       .Err_Size      (Ctrl_ECC_RdFIFO_Size),
       .Err_RNW       (Ctrl_ECC_RdFIFO_RNW),
       .Err_Synd_0    (ECC_Err_Synd_0),
       .Err_Synd_1    (ECC_Err_Synd_1)
       );

  // Tie off hole in ECC reg to zero
  assign ECC_Reg_Out[6*32 +:32] = 32'b0;
  
  always @(posedge Clk0) begin
    PhyIF_DP_RdFIFO_Push_RMW_i  <= PhyIF_DP_RdFIFO_Push_tmp[0] & Ctrl_RMW_d3 
                                   & PhyIF_Ctrl_InitDone_19;
    PhyIF_DP_RdFIFO_Push_RMW_i2 <= PhyIF_DP_RdFIFO_Push_RMW_i;
  end
 
  generate
    if (C_DELAY_PHYIF_DP_WRFIFO_POP == 1)
      begin : gen_rmw_pop_nopipe
         always @(*) begin
           PhyIF_DP_WrFIFO_Pop_RMW <= PhyIF_DP_WrFIFO_Pop_i[0] & Ctrl_RMW 
                                      & PhyIF_Ctrl_InitDone_19;
         end
      end
    else
      begin : gen_rmw_pop_pipe
         always @(posedge Clk0) begin
           PhyIF_DP_WrFIFO_Pop_RMW <= PhyIF_DP_WrFIFO_Pop_i[0] & Ctrl_RMW 
                                      & PhyIF_Ctrl_InitDone_19;
         end
      end
  endgenerate

  generate 
    if (C_INCLUDE_ECC_TEST == 1)
      begin : gen_wdf_mask_data_ecc_test
        if (C_MEM_TYPE == "SDRAM") 
          begin : gen_sdram
            always @(posedge Clk_WrFIFO_TML)
              wdf_mask_data <= 
                            (ECC_Encode_En | ~PhyIF_Ctrl_InitDone_19) ? 
                               {C_ECC_DM_WIDTH_INT+C_MEM_DM_WIDTH_INT{1'b0}} : 
                               {{C_ECC_DM_WIDTH_INT{1'b1}},{C_MEM_DM_WIDTH_INT{1'b0}}};
          end 
        else
          begin : gen_ddr
            always @(posedge Clk_WrFIFO_TML)
              wdf_mask_data <= (ECC_Encode_En | ~PhyIF_Ctrl_InitDone_19) ? 
                               {C_ECC_DM_WIDTH_INT+C_MEM_DM_WIDTH_INT{1'b0}} : 
                               {2{{{C_ECC_DM_WIDTH_INT/2{1'b1}},{C_MEM_DM_WIDTH_INT/2{1'b0}}}}};
          end
      end
    else
      begin : gen_wdf_mask_data
         always @(posedge Clk_WrFIFO_TML)
           wdf_mask_data <= {C_ECC_DM_WIDTH_INT+C_MEM_DM_WIDTH_INT{1'b0}};
      end
  endgenerate
  
  always @(posedge Clk0)
  begin
    PhyIF_DP_WrFIFO_Pop_d1 <= PhyIF_DP_WrFIFO_Pop_i[0];
    PhyIF_DP_WrFIFO_Pop_d2 <= PhyIF_DP_WrFIFO_Pop_d1;
    PhyIF_DP_WrFIFO_Pop_d3 <= PhyIF_DP_WrFIFO_Pop_d2;
  end

  assign ECC_Shift_CE = (C_DELAY_PHYIF_DP_WRFIFO_POP) ? PhyIF_DP_WrFIFO_Pop_d2
                                                      : PhyIF_DP_WrFIFO_Pop_d3;

  always @(posedge Clk0)
    begin
      DP_PhyIF_BE_O_d1 <= DP_PhyIF_BE_O;
    end
  generate
    if (C_USE_MIG_S3_PHY) begin : gen_s3
      always @(posedge Clk0) begin
        PhyIF_DP_RdFIFO_Push_i1 <= PhyIF_DP_RdFIFO_Push_tmp[0] & ~Ctrl_RMW_d3;
        PhyIF_DP_RdFIFO_Push_i <= PhyIF_DP_RdFIFO_Push_i1;
        Ctrl_DP_RdFIFO_WhichPort_Decode_i1 <= Ctrl_DP_RdFIFO_WhichPort_Decode;
        Ctrl_DP_RdFIFO_WhichPort_Decode_i2 <= Ctrl_DP_RdFIFO_WhichPort_Decode_i1;
        Ctrl_DP_RdFIFO_WhichPort_Decode_i3 <= Ctrl_DP_RdFIFO_WhichPort_Decode_i2;
        Ctrl_DP_RdFIFO_WhichPort_Decode_i4 <= Ctrl_DP_RdFIFO_WhichPort_Decode_i3;
        Ctrl_RMW_d2_i1 <= Ctrl_RMW_d2;
        Ctrl_RMW_d2_i2 <= Ctrl_RMW_d2_i1;
        Ctrl_RMW_d2_i3 <= Ctrl_RMW_d2_i2;
        Ctrl_RMW_d2_i4 <= Ctrl_RMW_d2_i3;
        Ctrl_ECC_RdFIFO_Size_i2 <= Ctrl_ECC_RdFIFO_Size_i;
        Ctrl_ECC_RdFIFO_Size_i3 <= Ctrl_ECC_RdFIFO_Size_i2;
        Ctrl_ECC_RdFIFO_Size_i4 <= Ctrl_ECC_RdFIFO_Size_i3;
        Ctrl_ECC_RdFIFO_RNW_i2  <= Ctrl_ECC_RdFIFO_RNW_i;
        Ctrl_ECC_RdFIFO_RNW_i3  <= Ctrl_ECC_RdFIFO_RNW_i2;
        Ctrl_ECC_RdFIFO_RNW_i4  <= Ctrl_ECC_RdFIFO_RNW_i3;
      end
    end else begin : gen_nons3
      always @(*) begin
        Ctrl_DP_RdFIFO_WhichPort_Decode_i4 <= Ctrl_DP_RdFIFO_WhichPort_Decode;
        Ctrl_RMW_d2_i4 <= Ctrl_RMW_d2;
        Ctrl_ECC_RdFIFO_Size_i4 <= Ctrl_ECC_RdFIFO_Size_i; 
        Ctrl_ECC_RdFIFO_RNW_i4  <= Ctrl_ECC_RdFIFO_RNW_i;
     end
      always @(posedge Clk0) begin
        PhyIF_DP_RdFIFO_Push_i <= PhyIF_DP_RdFIFO_Push_tmp[0] & ~Ctrl_RMW_d3;
      end
    end
  endgenerate
    
  generate
    for (i=0;i<C_MEM_DATA_WIDTH_INT/8;i=i+1)
      begin : gen_wdf_data
        assign ECC_EncIn_DQ_O[(i+1)*8-1:i*8] = (Ctrl_RMW_d3 && ~DP_PhyIF_BE_O[i]) ? 
                 RMW_PhyIF_DQ_O[(i+1)*8-1:i*8] : DP_PhyIF_DQ_O[(i+1)*8-1:i*8];
      end
  endgenerate

  mpmc_rmw_fifo #
    (
     .C_FAMILY         (C_FAMILY),
     .C_WDF_RDEN_EARLY (C_WDF_RDEN_EARLY),
     .C_DATA_WIDTH     (C_MEM_DATA_WIDTH_INT)
     )
    mpmc_rmw_fifo_0
      (
       .Clk  (Clk0),
       .Rst  (Rst),
       .Push (PhyIF_DP_RdFIFO_Push_RMW),
       .Pop  (PhyIF_DP_WrFIFO_Pop_RMW),
       .D    (PhyIF_DP_DQ_I),
       .Q    (RMW_PhyIF_DQ_O)
       );

  generate
    if (C_USE_INIT_PUSH == 0) begin : gen_wdf_data_nowritetraingpattern
        assign wdf_data = wdf_data_tmp;
      end
    else 
      begin : gen_wdf_data_withwritetraingpattern
        assign wdf_data[C_ECC_DATA_WIDTH*2+C_MEM_DATA_WIDTH_INT-1:
                        C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH_INT] = 
               PhyIF_Ctrl_InitDone_270 ?
               wdf_data_tmp[C_ECC_DATA_WIDTH*2+C_MEM_DATA_WIDTH_INT-1:
                            C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH_INT] :
               wdf_data_tmp[C_ECC_DATA_WIDTH*2+C_MEM_DATA_WIDTH_INT/2-1:
                            C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH_INT/2];
        assign wdf_data[C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH_INT-1:
                        C_ECC_DATA_WIDTH+(C_MEM_DATA_WIDTH_INT/2)] = 
               wdf_data_tmp[C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH_INT-1:
                            C_ECC_DATA_WIDTH+(C_MEM_DATA_WIDTH_INT/2)];
        assign wdf_data[C_ECC_DATA_WIDTH+(C_MEM_DATA_WIDTH_INT/2)-1:
                        C_MEM_DATA_WIDTH_INT/2] = 
               PhyIF_Ctrl_InitDone_270 ? 
               wdf_data_tmp[C_ECC_DATA_WIDTH+(C_MEM_DATA_WIDTH_INT/2)-1:
                            C_MEM_DATA_WIDTH_INT/2]:
               wdf_data_tmp[C_ECC_DATA_WIDTH-1:0];
        assign wdf_data[C_MEM_DATA_WIDTH_INT/2-1:0] = 
               wdf_data_tmp[C_MEM_DATA_WIDTH_INT/2-1:0];
      end
  endgenerate

  always @(posedge Clk0)
    begin
      rd_data_d1 <= rd_data;
      rd_data_d2 <= rd_data_d1;       
      rd_data_d3 <= rd_data_d2;       
    end

  generate
    if (C_INCLUDE_ECC_TEST == 1)
      begin : gen_phyif_dp_dq_i_ecc_test
        reg [2:0] ECC_Decode_En_d1;
        // synthesis attribute equivalent_register_removal of ECC_Decode_En_d1 is "no"
        
        always @(posedge Clk0)
          ECC_Decode_En_d1 <= {3{ECC_Decode_En}};

        if (C_ECC_ENCODE_PIPELINE == 1)
          begin : gen_ecc_pipeline
            if (C_MEM_TYPE == "SDRAM") begin : gen_sdram
               assign PhyIF_DP_DQ_I = 
                      ECC_Decode_En_d1[0] ? 
                      PhyIF_DP_DQ_I_tmp[C_MEM_DATA_WIDTH_INT-1:0] : 
                      rd_data_d3[C_MEM_DATA_WIDTH_INT-1:0];
            end else begin : gen_ddr
               assign PhyIF_DP_DQ_I[C_MEM_DATA_WIDTH_INT/2-1:0] = 
                      ECC_Decode_En_d1[0] ? 
                      PhyIF_DP_DQ_I_tmp[C_MEM_DATA_WIDTH_INT/2-1:0] : 
                      rd_data_d3[C_MEM_DATA_WIDTH_INT/2-1:0];
               assign PhyIF_DP_DQ_I[C_MEM_DATA_WIDTH_INT-1:C_MEM_DATA_WIDTH_INT/2] = 
                      ECC_Decode_En_d1[1] ?
                      PhyIF_DP_DQ_I_tmp[C_MEM_DATA_WIDTH_INT-1:C_MEM_DATA_WIDTH_INT/2] :
                      rd_data_d3[C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH_INT-1:
                                 C_ECC_DATA_WIDTH+(C_MEM_DATA_WIDTH_INT/2)];                    
            end
          end
        else
          begin : gen_ecc_nopipeline
            if (C_MEM_TYPE == "SDRAM") begin : gen_sdram
               assign PhyIF_DP_DQ_I = 
                      ECC_Decode_En_d1[0] ? 
                      PhyIF_DP_DQ_I_tmp[C_MEM_DATA_WIDTH_INT-1:0] : 
                      rd_data_d2[C_MEM_DATA_WIDTH_INT-1:0];
            end else begin : gen_ddr
               assign PhyIF_DP_DQ_I[C_MEM_DATA_WIDTH_INT/2-1:0] = 
                      ECC_Decode_En_d1[0] ? 
                      PhyIF_DP_DQ_I_tmp[C_MEM_DATA_WIDTH_INT/2-1:0] : 
                      rd_data_d2[C_MEM_DATA_WIDTH_INT/2-1:0];
               assign PhyIF_DP_DQ_I[C_MEM_DATA_WIDTH_INT-1:C_MEM_DATA_WIDTH_INT/2] = 
                      ECC_Decode_En_d1[1] ?
                      PhyIF_DP_DQ_I_tmp[C_MEM_DATA_WIDTH_INT-1:C_MEM_DATA_WIDTH_INT/2] :
                      rd_data_d2[C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH_INT-1:
                                 C_ECC_DATA_WIDTH+(C_MEM_DATA_WIDTH_INT/2)];                    
            end
          end

        assign ECC_Data_Error_0 = ECC_Data_Error_i0 & 
                                {3{PhyIF_DP_RdFIFO_Push_RMW | PhyIF_DP_RdFIFO_Push}} & 
                                {3{ECC_Decode_En_d1[2]}};

        assign ECC_Data_Error_1 = ECC_Data_Error_i1 & 
                                {3{PhyIF_DP_RdFIFO_Push_RMW | PhyIF_DP_RdFIFO_Push}} & 
                                {3{ECC_Decode_En_d1[2]}};

      end
  else
    begin : gen_phyif_dp_dq_i_ecc_test
       assign PhyIF_DP_DQ_I[C_MEM_DATA_WIDTH_INT/2-1:0] = PhyIF_DP_DQ_I_tmp[C_MEM_DATA_WIDTH_INT/2-1:0];
       assign PhyIF_DP_DQ_I[C_MEM_DATA_WIDTH_INT-1:C_MEM_DATA_WIDTH_INT/2] = PhyIF_DP_DQ_I_tmp[C_MEM_DATA_WIDTH_INT-1:C_MEM_DATA_WIDTH_INT/2];
       assign ECC_Data_Error_0 = ECC_Data_Error_i0 & 
                               {3{PhyIF_DP_RdFIFO_Push_RMW | PhyIF_DP_RdFIFO_Push}} & 
                               {3{ECC_Decode_En}};
       assign ECC_Data_Error_1 = ECC_Data_Error_i1 & 
                               {3{PhyIF_DP_RdFIFO_Push_RMW | PhyIF_DP_RdFIFO_Push}} & 
                               {3{ECC_Decode_En}};
    end
  endgenerate

  wire [7:0] write_bypass_data_02 = (wdf_data_toggle) ? ecc_write_data2 : ecc_write_data0;
  wire [7:0] write_bypass_data_13 = (wdf_data_toggle) ? ecc_write_data3 : ecc_write_data1;

  generate
    if ( C_MEM_TYPE == "SDRAM" )
      begin : gen_ecc_sdram
        assign ECC_Data_Error_i1 = 3'b0;
        assign ECC_Err_Synd_1 = 8'b0;
        mpmc_ecc_encode #
          (
           .C_DATA_BIT_WIDTH   (C_MEM_DATA_WIDTH_INT),
           .C_PARITY_BIT_WIDTH (C_ECC_DATA_WIDTH_INT),
           .C_ECC_ENC_PIPELINE (C_ECC_ENCODE_PIPELINE),
           .C_FAMILY           (C_FAMILY)
           )
          mpmc_ecc_encode_0
            (
             .Clk                 (~Clk0),
             .Rst                 (Rst),
             .Enc_In              (ECC_EncIn_DQ_O),
             .Bypass_Decode       (Bypass_Decode),
             .write_bypass_data   (ecc_write_data0),
             
             .Force_Error         (C_INCLUDE_ECC_TEST ? (ECC_Encode_En & InitDone ? ECC_Force_Error : 3'b0) : 3'b0),
             .Shift_CE            (ECC_Shift_CE),
             .Enc_Out             (wdf_data_tmp[C_MEM_DATA_WIDTH_INT-1:0]),
             .Parity_Out          (wdf_data_tmp[C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH_INT-1:C_MEM_DATA_WIDTH_INT])
             );

        mpmc_ecc_decode #
          (
           .C_DATA_BIT_WIDTH   (C_MEM_DATA_WIDTH_INT),
           .C_PARITY_BIT_WIDTH (C_ECC_DATA_WIDTH_INT),
           .C_ECC_DEC_PIPELINE (C_ECC_DECODE_PIPELINE),
           .C_FAMILY           (C_FAMILY)
           )
          mpmc_ecc_decode_0
            (
             .Clk       (Clk0),
             .Rst       (Rst),
             .Dec_In    (rd_data[C_MEM_DATA_WIDTH_INT-1:0]),
             .Parity_In (rd_data[C_ECC_DATA_WIDTH_INT+C_MEM_DATA_WIDTH_INT-1:
                                 C_MEM_DATA_WIDTH_INT]),
             .Error     (ECC_Data_Error_i0),
             .Dec_Out   (PhyIF_DP_DQ_I_tmp),
             .Syndrome  (ECC_Err_Synd_0)
             );
      end
    else
      begin : gen_ecc_ddr
    
         mpmc_ecc_encode #
           (
            .C_DATA_BIT_WIDTH   (C_MEM_DATA_WIDTH_INT/2),
            .C_PARITY_BIT_WIDTH (C_ECC_DATA_WIDTH_INT/2),
            .C_ECC_ENC_PIPELINE (C_ECC_ENCODE_PIPELINE),
            .C_FAMILY           (C_FAMILY)
            )
           mpmc_ecc_encode_0
             (
              .Clk                 (~Clk90),
              .Rst                 (Rst),
              .Bypass_Decode       (Bypass_Decode),
              .write_bypass_data   (write_bypass_data_02),
              .Enc_In              (ECC_EncIn_DQ_O[C_MEM_DATA_WIDTH_INT/2-1:0]),
              .Force_Error         (C_INCLUDE_ECC_TEST & InitDone ? ECC_Force_Error : 3'b0),
              .Shift_CE            (ECC_Shift_CE),
              .Enc_Out             (wdf_data_tmp[C_MEM_DATA_WIDTH_INT/2-1:0]),
              .Parity_Out          (wdf_data_tmp[C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH_INT/2-1:
                                                 C_MEM_DATA_WIDTH_INT/2])
              );
         mpmc_ecc_encode #
           (
            .C_DATA_BIT_WIDTH   (C_MEM_DATA_WIDTH_INT/2),
            .C_PARITY_BIT_WIDTH (C_ECC_DATA_WIDTH_INT/2),
            .C_ECC_ENC_PIPELINE (C_ECC_ENCODE_PIPELINE),
            .C_FAMILY           (C_FAMILY)
            )
           mpmc_ecc_encode_1
             (
              .Clk                 (~Clk90),
              .Rst                 (Rst),
              .Bypass_Decode       (Bypass_Decode),
              .write_bypass_data   (write_bypass_data_13),
              .Enc_In              (ECC_EncIn_DQ_O[C_MEM_DATA_WIDTH_INT-1:C_MEM_DATA_WIDTH_INT/2]),
              .Force_Error         (C_INCLUDE_ECC_TEST & InitDone ? ECC_Force_Error : 3'b0),
              .Shift_CE            (ECC_Shift_CE),
              .Enc_Out             (wdf_data_tmp[C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH_INT-1:
                                                 C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH_INT/2]),
              .Parity_Out          (wdf_data_tmp[C_ECC_DATA_WIDTH+C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH_INT-1:
                                                 C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH_INT])
              );
    
         mpmc_ecc_decode #
           (
            .C_DATA_BIT_WIDTH   (C_MEM_DATA_WIDTH_INT/2),
            .C_PARITY_BIT_WIDTH (C_ECC_DATA_WIDTH_INT/2),
            .C_ECC_DEC_PIPELINE (C_ECC_DECODE_PIPELINE),
            .C_FAMILY           (C_FAMILY)
            )
           mpmc_ecc_decode_0
             (
              .Clk       (Clk0),
              .Rst       (Rst),
              .Dec_In    (rd_data[C_MEM_DATA_WIDTH_INT/2-1:0]),
              .Parity_In (rd_data[(C_ECC_DATA_WIDTH_INT+C_MEM_DATA_WIDTH_INT)/2-1:
                                  C_MEM_DATA_WIDTH_INT/2]),
              .Error     (ECC_Data_Error_i0),
              .Dec_Out   (PhyIF_DP_DQ_I_tmp[C_MEM_DATA_WIDTH_INT/2-1:0]),
              .Syndrome  (ECC_Err_Synd_0)
              );
         mpmc_ecc_decode #
           (
            .C_DATA_BIT_WIDTH   (C_MEM_DATA_WIDTH_INT/2),
            .C_PARITY_BIT_WIDTH (C_ECC_DATA_WIDTH_INT/2),
            .C_ECC_DEC_PIPELINE (C_ECC_DECODE_PIPELINE),
            .C_FAMILY           (C_FAMILY)
            )
           mpmc_ecc_decode_1
             (
              .Clk       (Clk0),
              .Rst       (Rst),
              .Dec_In    (rd_data[C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH_INT-1:
                                  C_ECC_DATA_WIDTH+(C_MEM_DATA_WIDTH_INT/2)]),
              .Parity_In (rd_data[C_ECC_DATA_WIDTH_INT/2+C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH_INT-1:
                                  C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH_INT]),
              .Error     (ECC_Data_Error_i1),
              .Dec_Out   (PhyIF_DP_DQ_I_tmp[C_MEM_DATA_WIDTH_INT-1:C_MEM_DATA_WIDTH_INT/2]),
              .Syndrome  (ECC_Err_Synd_1)
              );
      end
  endgenerate
endmodule  // ecc_top

`default_nettype wire
