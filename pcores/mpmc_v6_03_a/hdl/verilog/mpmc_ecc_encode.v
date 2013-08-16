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
// Filename:         mpmc_ecc_encode.v
// Description:      This module will encode a 64, 32, 16 or 8 bit data signal
//                    using hamming codes to create the parity bits.  It takes 
//                    two cycles to encode w/o pipeline and 3 cyles with the   
//                    pipeline.   It has the ability to force errors for       
//                    testing.  The Force_Error input is defined as:           
//                    +-----------+-------------------------------------------+
//                    |Force_Error|  Description                              |
//                    +-----------+-------------------------------------------+
//                    | 3'b001    | 1 Data error                              |
//                    | 3'b010    | 2 Data Errors                             |
//                    | 3'b100    | 1 Parity error                            |
//                    | 3'b101    | 1 Data/1 Parity error                     |
//                    | Others    | No errors introduced                      |
//                    +-----------+-------------------------------------------+
//                    The Shift_CE signal is used to shift the Error Generation
//                    Bit Vectors.  They are only shifted if Shift_CE is enabld
//                    and a valid Force_Error signal is applied.  Only the 
//                    currently enabled single/double/parity bit vector will 
//                    be shifted.  The Shift_CE is pipelined with the Data and 
//                    is expected to arrive at the same time if you wish to 
//                    shift the register after inserting the error.
//                    Based off of xapp645, please see this document for more  
//                    details.
// Verilog-standard: Verilog 2001
//-------------------------------------------------------------------------
// Author:      CJC 
// History:
//  CJC       02/27/2007      - Initial EDK Release
//-------------------------------------------------------------------------

`timescale 1ns/100ps

module mpmc_ecc_encode 
  #(
    parameter integer C_DATA_BIT_WIDTH = 32,
    parameter integer C_PARITY_BIT_WIDTH = 7,
    parameter integer C_ECC_ENC_PIPELINE = 1,
    parameter C_FAMILY = "Virtex4"
  )
  (
    input  wire                          Clk, 
    input  wire                          Rst, 
    input  wire [C_DATA_BIT_WIDTH-1:0]   Enc_In, 
    input  wire [2:0]                    Force_Error,
    input  wire                          Shift_CE,
    input  wire                          Bypass_Decode,
    input  wire [7:0]                    write_bypass_data,
    output wire [C_DATA_BIT_WIDTH-1:0]   Enc_Out, 
    output wire [7:0]                    Parity_Out
);

  reg  [C_DATA_BIT_WIDTH-1:0]   encin_reg = 0;
  reg  [C_DATA_BIT_WIDTH-1:0]   encin_reg_i = 0;
  reg  [2:0]                    force_error_reg = 0;
  reg  [2:0]                    force_error_reg_i = 0;
  wire [C_PARITY_BIT_WIDTH-1:0] enc_chkbits;
  reg  [C_PARITY_BIT_WIDTH-1:0] enc_chkbits_i;
  reg  [C_DATA_BIT_WIDTH-1:0]   single_data_error;
  reg  [C_DATA_BIT_WIDTH-1:0]   double_data_error;
  reg  [C_PARITY_BIT_WIDTH-1:0] single_parity_error;
  reg  [C_DATA_BIT_WIDTH-1:0]   encout_i = 0;
  reg  [7:0]                    parity_out_i = 0;
  reg                           shift_ce_reg;
  reg                           shift_ce_i;

  wire  [7:0] enc_chkbits_i_expand;
  wire  [7:0] single_parity_error_expand;

  generate
    if (C_PARITY_BIT_WIDTH == 8) begin : PARITY_8
      assign enc_chkbits_i_expand = enc_chkbits_i;
      assign single_parity_error_expand = single_parity_error;
    end else begin : PARITY_LT_8
      assign enc_chkbits_i_expand = {{8-C_PARITY_BIT_WIDTH{1'b0}}, enc_chkbits_i};
      assign single_parity_error_expand = {{8-C_PARITY_BIT_WIDTH{1'b0}}, single_parity_error};
    end
  endgenerate


  // registered Inputs
  always @(posedge Clk)
    begin : Registered_Inputs
      encin_reg <= Enc_In;
      force_error_reg <= Force_Error;
      shift_ce_reg <= Shift_CE;
    end

  // Encoder checkbit generator equations for each possible data width
  generate 
    if (C_DATA_BIT_WIDTH == 64) begin : ecc_chk64bit
      assign enc_chkbits[0] = encin_reg[0]  ^ encin_reg[1]  ^ encin_reg[3]  ^ encin_reg[4]  ^ encin_reg[6]  ^ encin_reg[8]  ^ encin_reg[10] ^ encin_reg[11] ^ encin_reg[13] ^ encin_reg[15] ^ encin_reg[17] ^ encin_reg[19] ^ encin_reg[21] ^ encin_reg[23] ^ encin_reg[25] ^ encin_reg[26] ^ encin_reg[28] ^ encin_reg[30] ^ encin_reg[32] ^ encin_reg[34] ^ encin_reg[36] ^ encin_reg[38] ^ encin_reg[40] ^ encin_reg[42] ^ encin_reg[44] ^ encin_reg[46] ^ encin_reg[48] ^ encin_reg[50] ^ encin_reg[52] ^ encin_reg[54] ^ encin_reg[56] ^ encin_reg[57] ^ encin_reg[59] ^ encin_reg[61] ^ encin_reg[63] ;
      assign enc_chkbits[1] = encin_reg[0]  ^ encin_reg[2]  ^ encin_reg[3]  ^ encin_reg[5]  ^ encin_reg[6]  ^ encin_reg[9]  ^ encin_reg[10] ^ encin_reg[12] ^ encin_reg[13] ^ encin_reg[16] ^ encin_reg[17] ^ encin_reg[20] ^ encin_reg[21] ^ encin_reg[24] ^ encin_reg[25] ^ encin_reg[27] ^ encin_reg[28] ^ encin_reg[31] ^ encin_reg[32] ^ encin_reg[35] ^ encin_reg[36] ^ encin_reg[39] ^ encin_reg[40] ^ encin_reg[43] ^ encin_reg[44] ^ encin_reg[47] ^ encin_reg[48] ^ encin_reg[51] ^ encin_reg[52] ^ encin_reg[55] ^ encin_reg[56] ^ encin_reg[58] ^ encin_reg[59] ^ encin_reg[62] ^ encin_reg[63] ;
      assign enc_chkbits[2] = encin_reg[1]  ^ encin_reg[2]  ^ encin_reg[3]  ^ encin_reg[7]  ^ encin_reg[8]  ^ encin_reg[9]  ^ encin_reg[10] ^ encin_reg[14] ^ encin_reg[15] ^ encin_reg[16] ^ encin_reg[17] ^ encin_reg[22] ^ encin_reg[23] ^ encin_reg[24] ^ encin_reg[25] ^ encin_reg[29] ^ encin_reg[30] ^ encin_reg[31] ^ encin_reg[32] ^ encin_reg[37] ^ encin_reg[38] ^ encin_reg[39] ^ encin_reg[40] ^ encin_reg[45] ^ encin_reg[46] ^ encin_reg[47] ^ encin_reg[48] ^ encin_reg[53] ^ encin_reg[54] ^ encin_reg[55] ^ encin_reg[56] ^ encin_reg[60] ^ encin_reg[61] ^ encin_reg[62] ^ encin_reg[63] ;
      assign enc_chkbits[3] = encin_reg[4]  ^ encin_reg[5]  ^ encin_reg[6]  ^ encin_reg[7]  ^ encin_reg[8]  ^ encin_reg[9]  ^ encin_reg[10] ^ encin_reg[18] ^ encin_reg[19] ^ encin_reg[20] ^ encin_reg[21] ^ encin_reg[22] ^ encin_reg[23] ^ encin_reg[24] ^ encin_reg[25] ^ encin_reg[33] ^ encin_reg[34] ^ encin_reg[35] ^ encin_reg[36] ^ encin_reg[37] ^ encin_reg[38] ^ encin_reg[39] ^ encin_reg[40] ^ encin_reg[49] ^ encin_reg[50] ^ encin_reg[51] ^ encin_reg[52] ^ encin_reg[53] ^ encin_reg[54] ^ encin_reg[55] ^ encin_reg[56] ;
      assign enc_chkbits[4] = encin_reg[11] ^ encin_reg[12] ^ encin_reg[13] ^ encin_reg[14] ^ encin_reg[15] ^ encin_reg[16] ^ encin_reg[17] ^ encin_reg[18] ^ encin_reg[19] ^ encin_reg[20] ^ encin_reg[21] ^ encin_reg[22] ^ encin_reg[23] ^ encin_reg[24] ^ encin_reg[25] ^ encin_reg[41] ^ encin_reg[42] ^ encin_reg[43] ^ encin_reg[44] ^ encin_reg[45] ^ encin_reg[46] ^ encin_reg[47] ^ encin_reg[48] ^ encin_reg[49] ^ encin_reg[50] ^ encin_reg[51] ^ encin_reg[52] ^ encin_reg[53] ^ encin_reg[54] ^ encin_reg[55] ^ encin_reg[56] ;
      assign enc_chkbits[5] = encin_reg[26] ^ encin_reg[27] ^ encin_reg[28] ^ encin_reg[29] ^ encin_reg[30] ^ encin_reg[31] ^ encin_reg[32] ^ encin_reg[33] ^ encin_reg[34] ^ encin_reg[35] ^ encin_reg[36] ^ encin_reg[37] ^ encin_reg[38] ^ encin_reg[39] ^ encin_reg[40] ^ encin_reg[41] ^ encin_reg[42] ^ encin_reg[43] ^ encin_reg[44] ^ encin_reg[45] ^ encin_reg[46] ^ encin_reg[47] ^ encin_reg[48] ^ encin_reg[49] ^ encin_reg[50] ^ encin_reg[51] ^ encin_reg[52] ^ encin_reg[53] ^ encin_reg[54] ^ encin_reg[55] ^ encin_reg[56] ;
      assign enc_chkbits[6] = encin_reg[57] ^ encin_reg[58] ^ encin_reg[59] ^ encin_reg[60] ^ encin_reg[61] ^ encin_reg[62] ^ encin_reg[63] ;
      assign enc_chkbits[7] = encin_reg[0]  ^ encin_reg[1]  ^ encin_reg[2]  ^ encin_reg[3]  ^ encin_reg[4]  ^ encin_reg[5]  ^ encin_reg[6]  ^ encin_reg[7]  ^ encin_reg[8]  ^ encin_reg[9]  ^ encin_reg[10] ^ encin_reg[11] ^ encin_reg[12] ^ encin_reg[13] ^ encin_reg[14] ^ encin_reg[15] ^ encin_reg[16] ^ encin_reg[17] ^ encin_reg[18] ^ encin_reg[19] ^ encin_reg[20] ^ encin_reg[21] ^ encin_reg[22] ^ encin_reg[23] ^ encin_reg[24] ^ encin_reg[25] ^ encin_reg[26] ^ encin_reg[27] ^ encin_reg[28] ^ encin_reg[29] ^ encin_reg[30] ^ encin_reg[31] ^ encin_reg[32] ^ encin_reg[33] ^ encin_reg[34] ^ encin_reg[35] ^ encin_reg[36] ^ encin_reg[37] ^ encin_reg[38] ^ encin_reg[39] ^ encin_reg[40] ^ encin_reg[41] ^ encin_reg[42] ^ encin_reg[43] ^ encin_reg[44] ^ encin_reg[45] ^ encin_reg[46] ^ encin_reg[47] ^ encin_reg[48] ^ encin_reg[49] ^ encin_reg[50] ^ encin_reg[51] ^ encin_reg[52] ^ encin_reg[53] ^ encin_reg[54] ^ encin_reg[55] ^ encin_reg[56] ^ encin_reg[57] ^ encin_reg[58] ^ encin_reg[59] ^ encin_reg[60] ^ encin_reg[61] ^ encin_reg[62] ^ encin_reg[63] ^ enc_chkbits[6]  ^ enc_chkbits[5]  ^ enc_chkbits[4]  ^ enc_chkbits[3]  ^ enc_chkbits[2]  ^ enc_chkbits[1]  ^ enc_chkbits[0] ;
    end
    else if (C_DATA_BIT_WIDTH == 32) begin : ecc_chk32bit
      assign enc_chkbits[0] = encin_reg[0]  ^ encin_reg[1]  ^ encin_reg[3]  ^ encin_reg[4]  ^ encin_reg[6]  ^ encin_reg[8]  ^ encin_reg[10] ^ encin_reg[11] ^ encin_reg[13] ^ encin_reg[15] ^ encin_reg[17] ^ encin_reg[19] ^ encin_reg[21] ^ encin_reg[23] ^ encin_reg[25] ^ encin_reg[26] ^ encin_reg[28] ^ encin_reg[30] ; 
      assign enc_chkbits[1] = encin_reg[0]  ^ encin_reg[2]  ^ encin_reg[3]  ^ encin_reg[5]  ^ encin_reg[6]  ^ encin_reg[9]  ^ encin_reg[10] ^ encin_reg[12] ^ encin_reg[13] ^ encin_reg[16] ^ encin_reg[17] ^ encin_reg[20] ^ encin_reg[21] ^ encin_reg[24] ^ encin_reg[25] ^ encin_reg[27] ^ encin_reg[28] ^ encin_reg[31] ;
      assign enc_chkbits[2] = encin_reg[1]  ^ encin_reg[2]  ^ encin_reg[3]  ^ encin_reg[7]  ^ encin_reg[8]  ^ encin_reg[9]  ^ encin_reg[10] ^ encin_reg[14] ^ encin_reg[15] ^ encin_reg[16] ^ encin_reg[17] ^ encin_reg[22] ^ encin_reg[23] ^ encin_reg[24] ^ encin_reg[25] ^ encin_reg[29] ^ encin_reg[30] ^ encin_reg[31] ;
      assign enc_chkbits[3] = encin_reg[4]  ^ encin_reg[5]  ^ encin_reg[6]  ^ encin_reg[7]  ^ encin_reg[8]  ^ encin_reg[9]  ^ encin_reg[10] ^ encin_reg[18] ^ encin_reg[19] ^ encin_reg[20] ^ encin_reg[21] ^ encin_reg[22] ^ encin_reg[23] ^ encin_reg[24] ^ encin_reg[25] ;
      assign enc_chkbits[4] = encin_reg[11] ^ encin_reg[12] ^ encin_reg[13] ^ encin_reg[14] ^ encin_reg[15] ^ encin_reg[16] ^ encin_reg[17] ^ encin_reg[18] ^ encin_reg[19] ^ encin_reg[20] ^ encin_reg[21] ^ encin_reg[22] ^ encin_reg[23] ^ encin_reg[24] ^ encin_reg[25] ;
      assign enc_chkbits[5] = encin_reg[26] ^ encin_reg[27] ^ encin_reg[28] ^ encin_reg[29] ^ encin_reg[30] ^ encin_reg[31] ;
      assign enc_chkbits[6] = encin_reg[0]  ^ encin_reg[1]  ^ encin_reg[2]  ^ encin_reg[3]  ^ encin_reg[4]  ^ encin_reg[5]  ^ encin_reg[6]  ^ encin_reg[7]  ^ encin_reg[8]  ^ encin_reg[9]  ^ encin_reg[10] ^ encin_reg[11] ^ encin_reg[12] ^ encin_reg[13] ^ encin_reg[14] ^ encin_reg[15] ^ encin_reg[16] ^ encin_reg[17] ^ encin_reg[18] ^ encin_reg[19] ^ encin_reg[20] ^ encin_reg[21] ^ encin_reg[22] ^ encin_reg[23] ^ encin_reg[24] ^ encin_reg[25] ^ encin_reg[26] ^ encin_reg[27] ^ encin_reg[28] ^ encin_reg[29] ^ encin_reg[30] ^ encin_reg[31] ^ enc_chkbits[5]  ^ enc_chkbits[4]  ^ enc_chkbits[3]  ^ enc_chkbits[2]  ^ enc_chkbits[1]  ^ enc_chkbits[0] ;
    end
    else if (C_DATA_BIT_WIDTH == 16) begin : ecc_chk16bit
      assign enc_chkbits[0] = encin_reg[0]  ^ encin_reg[1]  ^ encin_reg[3]  ^ encin_reg[4]  ^ encin_reg[6]  ^ encin_reg[8]  ^ encin_reg[10] ^ encin_reg[11] ^ encin_reg[13] ^ encin_reg[15] ; 
      assign enc_chkbits[1] = encin_reg[0]  ^ encin_reg[2]  ^ encin_reg[3]  ^ encin_reg[5]  ^ encin_reg[6]  ^ encin_reg[9]  ^ encin_reg[10] ^ encin_reg[12] ^ encin_reg[13] ; 
      assign enc_chkbits[2] = encin_reg[1]  ^ encin_reg[2]  ^ encin_reg[3]  ^ encin_reg[7]  ^ encin_reg[8]  ^ encin_reg[9]  ^ encin_reg[10] ^ encin_reg[14] ^ encin_reg[15] ; 
      assign enc_chkbits[3] = encin_reg[4]  ^ encin_reg[5]  ^ encin_reg[6]  ^ encin_reg[7]  ^ encin_reg[8]  ^ encin_reg[9]  ^ encin_reg[10] ; 
      assign enc_chkbits[4] = encin_reg[11] ^ encin_reg[12] ^ encin_reg[13] ^ encin_reg[14] ^ encin_reg[15] ; 
      assign enc_chkbits[5] = encin_reg[0]  ^ encin_reg[1]  ^ encin_reg[2]  ^ encin_reg[3]  ^ encin_reg[4]  ^ encin_reg[5]  ^ encin_reg[6]  ^ encin_reg[7]  ^ encin_reg[8]  ^ encin_reg[9]  ^ encin_reg[10] ^ encin_reg[11] ^ encin_reg[12] ^ encin_reg[13] ^ encin_reg[14] ^ encin_reg[15] ^ enc_chkbits[4]  ^ enc_chkbits[3]  ^ enc_chkbits[2]  ^ enc_chkbits[1]  ^ enc_chkbits[0] ;
    end
    else if (C_DATA_BIT_WIDTH == 8) begin : ecc_chk8bit
      assign enc_chkbits[0] = encin_reg[0]  ^ encin_reg[1]  ^ encin_reg[3]  ^ encin_reg[4]  ^ encin_reg[6] ; 
      assign enc_chkbits[1] = encin_reg[0]  ^ encin_reg[2]  ^ encin_reg[3]  ^ encin_reg[5]  ^ encin_reg[6] ; 
      assign enc_chkbits[2] = encin_reg[1]  ^ encin_reg[2]  ^ encin_reg[3]  ^ encin_reg[7] ; 
      assign enc_chkbits[3] = encin_reg[4]  ^ encin_reg[5]  ^ encin_reg[6]  ^ encin_reg[7] ; 
      assign enc_chkbits[4] = encin_reg[0]  ^ encin_reg[1]  ^ encin_reg[2]  ^ encin_reg[3]  ^ encin_reg[4]  ^ encin_reg[5]  ^ encin_reg[6]  ^ encin_reg[7]  ^ enc_chkbits[3]  ^ enc_chkbits[2]  ^ enc_chkbits[1]  ^ enc_chkbits[0] ;
    end
  endgenerate

  generate 
    if (C_ECC_ENC_PIPELINE == 1) begin : encode_pipeline
      always @(posedge Clk)
        begin
          encin_reg_i <= encin_reg;
          force_error_reg_i <= force_error_reg;
          enc_chkbits_i <= enc_chkbits;
          shift_ce_i <= shift_ce_reg;
        end
    end
    else begin : no_encode_pipeline
      always @(*)
        begin 
          encin_reg_i <= encin_reg;
          force_error_reg_i <= force_error_reg;
          enc_chkbits_i <= enc_chkbits;
          shift_ce_i <= shift_ce_reg;
        end
    end
  endgenerate

  // error generator vectors
  always @(posedge Clk)
    begin : single_data_error_gen
      if (Rst)
        single_data_error <= 1;
      else if (shift_ce_i && force_error_reg_i[0]) begin
        single_data_error[0] <= single_data_error[C_DATA_BIT_WIDTH-1]; 
        single_data_error[C_DATA_BIT_WIDTH-1:1] <= single_data_error[C_DATA_BIT_WIDTH-2:0] ; 
      end 
    end 

  always @(posedge Clk)
    begin : double_data_error_gen
      if (Rst)
        double_data_error <= 3; 
      else if (shift_ce_i && force_error_reg_i[1]) begin
        double_data_error[0] <= double_data_error[C_DATA_BIT_WIDTH-1] ; 
        double_data_error[C_DATA_BIT_WIDTH-1:1] <= double_data_error[C_DATA_BIT_WIDTH-2:0] ; 
      end 
    end 

  always @(posedge Clk)
    begin : single_parity_error_gen
      if (Rst)
        single_parity_error <= 1; 
      else if (shift_ce_i && force_error_reg_i[2]) begin
        single_parity_error[0] <= single_parity_error[C_PARITY_BIT_WIDTH-1]; 
        single_parity_error[C_PARITY_BIT_WIDTH-1:1] <= single_parity_error[C_PARITY_BIT_WIDTH-2:0] ; 
      end 
    end 

  // error vector insertions
  always @(posedge Clk)
    begin : Encoder
      if (Rst)
        begin
          encout_i <= {C_DATA_BIT_WIDTH{1'b0}} ; 
          parity_out_i <= 8'h00 ; 
        end
      else
        begin
          case (force_error_reg_i)
            3'b001 :
              begin
                // 1 bit data error walk-thru
                encout_i <= encin_reg_i ^ single_data_error; 
                parity_out_i <= enc_chkbits_i_expand;
              end
            3'b010 :
              begin
                // 2 bit data error walk-thru
                encout_i <= encin_reg_i ^ double_data_error; 
                parity_out_i <= enc_chkbits_i_expand;
              end
            3'b100 :
              begin
                // 1-bit parity error walk-thru
                encout_i <= encin_reg_i;
                parity_out_i <= enc_chkbits_i_expand ^ single_parity_error_expand ; 
              end
            3'b101 :
              begin
                // 1-bit Data/ 1-bit parity error walk-thru
                encout_i <= encin_reg_i ^ single_data_error; 
                parity_out_i <= enc_chkbits_i_expand ^ single_parity_error_expand ; 
              end
          default :
              begin
                encout_i <= encin_reg_i ; 
                if (Bypass_Decode == 1'b0) begin
                  parity_out_i <= enc_chkbits_i_expand ; 
                end else begin
                  parity_out_i <= write_bypass_data ; 
                end
              end
          endcase 
        end 
    end 

  assign Enc_Out = encout_i;
  assign Parity_Out = parity_out_i;

endmodule
