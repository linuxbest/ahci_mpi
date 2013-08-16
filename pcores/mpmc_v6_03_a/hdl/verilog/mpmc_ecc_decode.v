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
// Filename:         mpmc_dec_encode.v                                       
// Description:      This module will decode a 64, 32, 16 or 8 bit data signal
//                    using hamming codes to verify the data to the parity bits
//                    It takes two cycles to decode w/o pipeline and 3 cyles   
//                    with the pipeline.  It will correct single bit errors and
//                    detect but not correct double bit errors.  Detectable    
//                    bit errors greater than 2 will be report as double bit   
//                    errors.  It will report if the error is none, single     
//                    data error, single parity error, or two or more errors,  
//                    if the output is 000, 001, 100, 010, respectively.  Based    
//                    off xapp645, please see this document for more details.  
// Verilog-standard: Verilog 2001
//-------------------------------------------------------------------------
// Author:      CJC 
// History:
//  CJC       02/27/2007      - Initial EDK Release
//-------------------------------------------------------------------------

`timescale 1ns/100ps

module mpmc_ecc_decode 
  #(
    parameter integer C_DATA_BIT_WIDTH = 64,     // Valid values: 8, 16, 32, 64
    parameter integer C_PARITY_BIT_WIDTH = 8,    // Valid values: 5-8
    parameter integer C_ECC_DEC_PIPELINE = 1,
    parameter C_FAMILY = "Virtex4"
  )
  (
    input  wire                          Clk, 
    input  wire                          Rst, 
    input  wire [C_DATA_BIT_WIDTH-1:0]   Dec_In, 
    input  wire [C_PARITY_BIT_WIDTH-1:0] Parity_In,
    output reg  [2:0]                    Error = 0,
    output reg  [C_DATA_BIT_WIDTH-1:0]   Dec_Out = 0, 
    output reg  [7:0]                    Syndrome = 0

  );

  reg  [C_DATA_BIT_WIDTH-1:0]       decin_reg = 0;
  reg  [C_PARITY_BIT_WIDTH-1:0]     parity_in_reg = 0;
  wire [7:0]                        syndrome_p1;
  wire [7:0]                        syndrome_chk;
  reg  [7:0]                        syndrome_i = 0;
  reg  [6:0]                        syndrome_single = 0;
  reg  [C_DATA_BIT_WIDTH-1:0]       decin_reg_i = 0;
  reg  [2:0]                        error_i = 0;
  reg  [63:0]                       mask = 0;

  // Registerd Inputs
  always @(posedge Clk)
    begin : Registered_Inputs
     decin_reg <= Dec_In;
     parity_in_reg <= Parity_In ; 
    end 

  // Syndrome Generator
  // Syndrome is always 8 bits, we will 0 extend the left side to match 
  assign syndrome_p1 = syndrome_chk ^ { {8-C_PARITY_BIT_WIDTH{1'b0}}, parity_in_reg} ;
  generate 
    if (C_DATA_BIT_WIDTH == 64) begin : ecc_syn64bit
      assign syndrome_chk[0] = decin_reg[0]  ^ decin_reg[1]  ^ decin_reg[3]  ^ decin_reg[4]  ^ decin_reg[6]  ^ decin_reg[8]  ^ decin_reg[10] ^ decin_reg[11] ^ decin_reg[13] ^ decin_reg[15] ^ decin_reg[17] ^ decin_reg[19] ^ decin_reg[21] ^ decin_reg[23] ^ decin_reg[25] ^ decin_reg[26] ^ decin_reg[28] ^ decin_reg[30] ^ decin_reg[32] ^ decin_reg[34] ^ decin_reg[36] ^ decin_reg[38] ^ decin_reg[40] ^ decin_reg[42] ^ decin_reg[44] ^ decin_reg[46] ^ decin_reg[48] ^ decin_reg[50] ^ decin_reg[52] ^ decin_reg[54] ^ decin_reg[56] ^ decin_reg[57] ^ decin_reg[59] ^ decin_reg[61] ^ decin_reg[63] ;
      assign syndrome_chk[1] = decin_reg[0]  ^ decin_reg[2]  ^ decin_reg[3]  ^ decin_reg[5]  ^ decin_reg[6]  ^ decin_reg[9]  ^ decin_reg[10] ^ decin_reg[12] ^ decin_reg[13] ^ decin_reg[16] ^ decin_reg[17] ^ decin_reg[20] ^ decin_reg[21] ^ decin_reg[24] ^ decin_reg[25] ^ decin_reg[27] ^ decin_reg[28] ^ decin_reg[31] ^ decin_reg[32] ^ decin_reg[35] ^ decin_reg[36] ^ decin_reg[39] ^ decin_reg[40] ^ decin_reg[43] ^ decin_reg[44] ^ decin_reg[47] ^ decin_reg[48] ^ decin_reg[51] ^ decin_reg[52] ^ decin_reg[55] ^ decin_reg[56] ^ decin_reg[58] ^ decin_reg[59] ^ decin_reg[62] ^ decin_reg[63] ;
      assign syndrome_chk[2] = decin_reg[1]  ^ decin_reg[2]  ^ decin_reg[3]  ^ decin_reg[7]  ^ decin_reg[8]  ^ decin_reg[9]  ^ decin_reg[10] ^ decin_reg[14] ^ decin_reg[15] ^ decin_reg[16] ^ decin_reg[17] ^ decin_reg[22] ^ decin_reg[23] ^ decin_reg[24] ^ decin_reg[25] ^ decin_reg[29] ^ decin_reg[30] ^ decin_reg[31] ^ decin_reg[32] ^ decin_reg[37] ^ decin_reg[38] ^ decin_reg[39] ^ decin_reg[40] ^ decin_reg[45] ^ decin_reg[46] ^ decin_reg[47] ^ decin_reg[48] ^ decin_reg[53] ^ decin_reg[54] ^ decin_reg[55] ^ decin_reg[56] ^ decin_reg[60] ^ decin_reg[61] ^ decin_reg[62] ^ decin_reg[63] ;
      assign syndrome_chk[3] = decin_reg[4]  ^ decin_reg[5]  ^ decin_reg[6]  ^ decin_reg[7]  ^ decin_reg[8]  ^ decin_reg[9]  ^ decin_reg[10] ^ decin_reg[18] ^ decin_reg[19] ^ decin_reg[20] ^ decin_reg[21] ^ decin_reg[22] ^ decin_reg[23] ^ decin_reg[24] ^ decin_reg[25] ^ decin_reg[33] ^ decin_reg[34] ^ decin_reg[35] ^ decin_reg[36] ^ decin_reg[37] ^ decin_reg[38] ^ decin_reg[39] ^ decin_reg[40] ^ decin_reg[49] ^ decin_reg[50] ^ decin_reg[51] ^ decin_reg[52] ^ decin_reg[53] ^ decin_reg[54] ^ decin_reg[55] ^ decin_reg[56] ;
      assign syndrome_chk[4] = decin_reg[11] ^ decin_reg[12] ^ decin_reg[13] ^ decin_reg[14] ^ decin_reg[15] ^ decin_reg[16] ^ decin_reg[17] ^ decin_reg[18] ^ decin_reg[19] ^ decin_reg[20] ^ decin_reg[21] ^ decin_reg[22] ^ decin_reg[23] ^ decin_reg[24] ^ decin_reg[25] ^ decin_reg[41] ^ decin_reg[42] ^ decin_reg[43] ^ decin_reg[44] ^ decin_reg[45] ^ decin_reg[46] ^ decin_reg[47] ^ decin_reg[48] ^ decin_reg[49] ^ decin_reg[50] ^ decin_reg[51] ^ decin_reg[52] ^ decin_reg[53] ^ decin_reg[54] ^ decin_reg[55] ^ decin_reg[56] ;
      assign syndrome_chk[5] = decin_reg[26] ^ decin_reg[27] ^ decin_reg[28] ^ decin_reg[29] ^ decin_reg[30] ^ decin_reg[31] ^ decin_reg[32] ^ decin_reg[33] ^ decin_reg[34] ^ decin_reg[35] ^ decin_reg[36] ^ decin_reg[37] ^ decin_reg[38] ^ decin_reg[39] ^ decin_reg[40] ^ decin_reg[41] ^ decin_reg[42] ^ decin_reg[43] ^ decin_reg[44] ^ decin_reg[45] ^ decin_reg[46] ^ decin_reg[47] ^ decin_reg[48] ^ decin_reg[49] ^ decin_reg[50] ^ decin_reg[51] ^ decin_reg[52] ^ decin_reg[53] ^ decin_reg[54] ^ decin_reg[55] ^ decin_reg[56] ;
      assign syndrome_chk[6] = decin_reg[57] ^ decin_reg[58] ^ decin_reg[59] ^ decin_reg[60] ^ decin_reg[61] ^ decin_reg[62] ^ decin_reg[63] ;
      assign syndrome_chk[7] = decin_reg[0]  ^ decin_reg[1]  ^ decin_reg[2]  ^ decin_reg[3]  ^ decin_reg[4]  ^ decin_reg[5]  ^ decin_reg[6]  ^ decin_reg[7]  ^ decin_reg[8]  ^ decin_reg[9]  ^ decin_reg[10] ^ decin_reg[11] ^ decin_reg[12] ^ decin_reg[13] ^ decin_reg[14] ^ decin_reg[15] ^ decin_reg[16] ^ decin_reg[17] ^ decin_reg[18] ^ decin_reg[19] ^ decin_reg[20] ^ decin_reg[21] ^ decin_reg[22] ^ decin_reg[23] ^ decin_reg[24] ^ decin_reg[25] ^ decin_reg[26] ^ decin_reg[27] ^ decin_reg[28] ^ decin_reg[29] ^ decin_reg[30] ^ decin_reg[31] ^ decin_reg[32] ^ decin_reg[33] ^ decin_reg[34] ^ decin_reg[35] ^ decin_reg[36] ^ decin_reg[37] ^ decin_reg[38] ^ decin_reg[39] ^ decin_reg[40] ^ decin_reg[41] ^ decin_reg[42] ^ decin_reg[43] ^ decin_reg[44] ^ decin_reg[45] ^ decin_reg[46] ^ decin_reg[47] ^ decin_reg[48] ^ decin_reg[49] ^ decin_reg[50] ^ decin_reg[51] ^ decin_reg[52] ^ decin_reg[53] ^ decin_reg[54] ^ decin_reg[55] ^ decin_reg[56] ^ decin_reg[57] ^ decin_reg[58] ^ decin_reg[59] ^ decin_reg[60] ^ decin_reg[61] ^ decin_reg[62] ^ decin_reg[63] ^ parity_in_reg[6]  ^ parity_in_reg[5]  ^ parity_in_reg[4]  ^ parity_in_reg[3]  ^ parity_in_reg[2]  ^ parity_in_reg[1]  ^ parity_in_reg[0] ;
    end
    else if (C_DATA_BIT_WIDTH == 32) begin : ecc_syn32bit
      assign syndrome_chk[0] = decin_reg[0]  ^ decin_reg[1]  ^ decin_reg[3]  ^ decin_reg[4]  ^ decin_reg[6]  ^ decin_reg[8]  ^ decin_reg[10] ^ decin_reg[11] ^ decin_reg[13] ^ decin_reg[15] ^ decin_reg[17] ^ decin_reg[19] ^ decin_reg[21] ^ decin_reg[23] ^ decin_reg[25] ^ decin_reg[26] ^ decin_reg[28] ^ decin_reg[30] ; 
      assign syndrome_chk[1] = decin_reg[0]  ^ decin_reg[2]  ^ decin_reg[3]  ^ decin_reg[5]  ^ decin_reg[6]  ^ decin_reg[9]  ^ decin_reg[10] ^ decin_reg[12] ^ decin_reg[13] ^ decin_reg[16] ^ decin_reg[17] ^ decin_reg[20] ^ decin_reg[21] ^ decin_reg[24] ^ decin_reg[25] ^ decin_reg[27] ^ decin_reg[28] ^ decin_reg[31] ;
      assign syndrome_chk[2] = decin_reg[1]  ^ decin_reg[2]  ^ decin_reg[3]  ^ decin_reg[7]  ^ decin_reg[8]  ^ decin_reg[9]  ^ decin_reg[10] ^ decin_reg[14] ^ decin_reg[15] ^ decin_reg[16] ^ decin_reg[17] ^ decin_reg[22] ^ decin_reg[23] ^ decin_reg[24] ^ decin_reg[25] ^ decin_reg[29] ^ decin_reg[30] ^ decin_reg[31] ;
      assign syndrome_chk[3] = decin_reg[4]  ^ decin_reg[5]  ^ decin_reg[6]  ^ decin_reg[7]  ^ decin_reg[8]  ^ decin_reg[9]  ^ decin_reg[10] ^ decin_reg[18] ^ decin_reg[19] ^ decin_reg[20] ^ decin_reg[21] ^ decin_reg[22] ^ decin_reg[23] ^ decin_reg[24] ^ decin_reg[25] ;
      assign syndrome_chk[4] = decin_reg[11] ^ decin_reg[12] ^ decin_reg[13] ^ decin_reg[14] ^ decin_reg[15] ^ decin_reg[16] ^ decin_reg[17] ^ decin_reg[18] ^ decin_reg[19] ^ decin_reg[20] ^ decin_reg[21] ^ decin_reg[22] ^ decin_reg[23] ^ decin_reg[24] ^ decin_reg[25] ;
      assign syndrome_chk[5] = decin_reg[26] ^ decin_reg[27] ^ decin_reg[28] ^ decin_reg[29] ^ decin_reg[30] ^ decin_reg[31] ;
      assign syndrome_chk[6] = decin_reg[0]  ^ decin_reg[1]  ^ decin_reg[2]  ^ decin_reg[3]  ^ decin_reg[4]  ^ decin_reg[5]  ^ decin_reg[6]  ^ decin_reg[7]  ^ decin_reg[8]  ^ decin_reg[9]  ^ decin_reg[10] ^ decin_reg[11] ^ decin_reg[12] ^ decin_reg[13] ^ decin_reg[14] ^ decin_reg[15] ^ decin_reg[16] ^ decin_reg[17] ^ decin_reg[18] ^ decin_reg[19] ^ decin_reg[20] ^ decin_reg[21] ^ decin_reg[22] ^ decin_reg[23] ^ decin_reg[24] ^ decin_reg[25] ^ decin_reg[26] ^ decin_reg[27] ^ decin_reg[28] ^ decin_reg[29] ^ decin_reg[30] ^ decin_reg[31] ^ parity_in_reg[5]  ^ parity_in_reg[4]  ^ parity_in_reg[3]  ^ parity_in_reg[2]  ^ parity_in_reg[1]  ^ parity_in_reg[0] ;
      assign syndrome_chk[7] = 0;
    end
    else if (C_DATA_BIT_WIDTH == 16) begin : ecc_syn16bit
      assign syndrome_chk[0] = decin_reg[0]  ^ decin_reg[1]  ^ decin_reg[3]  ^ decin_reg[4]  ^ decin_reg[6]  ^ decin_reg[8]  ^ decin_reg[10] ^ decin_reg[11] ^ decin_reg[13] ^ decin_reg[15] ; 
      assign syndrome_chk[1] = decin_reg[0]  ^ decin_reg[2]  ^ decin_reg[3]  ^ decin_reg[5]  ^ decin_reg[6]  ^ decin_reg[9]  ^ decin_reg[10] ^ decin_reg[12] ^ decin_reg[13] ; 
      assign syndrome_chk[2] = decin_reg[1]  ^ decin_reg[2]  ^ decin_reg[3]  ^ decin_reg[7]  ^ decin_reg[8]  ^ decin_reg[9]  ^ decin_reg[10] ^ decin_reg[14] ^ decin_reg[15] ; 
      assign syndrome_chk[3] = decin_reg[4]  ^ decin_reg[5]  ^ decin_reg[6]  ^ decin_reg[7]  ^ decin_reg[8]  ^ decin_reg[9]  ^ decin_reg[10] ; 
      assign syndrome_chk[4] = decin_reg[11] ^ decin_reg[12] ^ decin_reg[13] ^ decin_reg[14] ^ decin_reg[15] ; 
      assign syndrome_chk[5] = decin_reg[0]  ^ decin_reg[1]  ^ decin_reg[2]  ^ decin_reg[3]  ^ decin_reg[4]  ^ decin_reg[5]  ^ decin_reg[6]  ^ decin_reg[7]  ^ decin_reg[8]  ^ decin_reg[9]  ^ decin_reg[10] ^ decin_reg[11] ^ decin_reg[12] ^ decin_reg[13] ^ decin_reg[14] ^ decin_reg[15] ^ parity_in_reg[4]  ^ parity_in_reg[3]  ^ parity_in_reg[2]  ^ parity_in_reg[1]  ^ parity_in_reg[0] ;
      assign syndrome_chk[6] = 0;
      assign syndrome_chk[7] = 0;
    end
    else if (C_DATA_BIT_WIDTH == 8) begin : ecc_syn8bit
      assign syndrome_chk[0] = decin_reg[0]  ^ decin_reg[1]  ^ decin_reg[3]  ^ decin_reg[4]  ^ decin_reg[6] ; 
      assign syndrome_chk[1] = decin_reg[0]  ^ decin_reg[2]  ^ decin_reg[3]  ^ decin_reg[5]  ^ decin_reg[6] ; 
      assign syndrome_chk[2] = decin_reg[1]  ^ decin_reg[2]  ^ decin_reg[3]  ^ decin_reg[7] ; 
      assign syndrome_chk[3] = decin_reg[4]  ^ decin_reg[5]  ^ decin_reg[6]  ^ decin_reg[7] ; 
      assign syndrome_chk[4] = decin_reg[0]  ^ decin_reg[1]  ^ decin_reg[2]  ^ decin_reg[3]  ^ decin_reg[4]  ^ decin_reg[5]  ^ decin_reg[6]  ^ decin_reg[7]  ^ parity_in_reg[3]  ^ parity_in_reg[2]  ^ parity_in_reg[1]  ^ parity_in_reg[0] ;
      assign syndrome_chk[5] = 0;
      assign syndrome_chk[6] = 0;
      assign syndrome_chk[7] = 0;
    end
  endgenerate

  // Optional decode pipeline
  generate 
    if (C_ECC_DEC_PIPELINE == 1) begin : decode_pipeline
      always @(posedge Clk)
        begin
          decin_reg_i <= decin_reg;
          syndrome_i <= syndrome_p1;
          syndrome_single <= {{8-C_PARITY_BIT_WIDTH{1'b0}}, syndrome_p1[C_PARITY_BIT_WIDTH-2:0]};
        end
    end
    else begin : no_decode_pipeline
      always @(*)
        begin 
          decin_reg_i <= decin_reg;
          syndrome_i <= syndrome_p1;
          syndrome_single <= {{8-C_PARITY_BIT_WIDTH{1'b0}}, syndrome_p1[C_PARITY_BIT_WIDTH-2:0]};
        end
    end
  endgenerate

  // Lookup and Mask Generator
  // syndrome error code
  // 00 = no error/data corrected
  // 01 = single data bit error corrected
  // 10 = single parity bit error corrected
  // 11 = double bit error or more uncorrectable error
  generate 
    if (C_DATA_BIT_WIDTH > 8) begin : multi_error_check
      always @(*)
        begin : error_status
          if (~syndrome_i[C_PARITY_BIT_WIDTH-1])   // 0 or 2 errors if  Last check bit is 0
            if (~(|syndrome_i[C_PARITY_BIT_WIDTH-2:0]))
              error_i <= 3'b000 ; // no error 
            else
              error_i <= 3'b010 ; // double error
          else if (syndrome_i[C_PARITY_BIT_WIDTH-2] & (|syndrome_i[C_PARITY_BIT_WIDTH-3:3])) // flag obvious multiple errors
            error_i <= 3'b010 ; // detect multiple errors (flagged as double error)
          else if (syndrome_single == 0 || syndrome_single == 1 || syndrome_single == 2 || syndrome_single == 4 || syndrome_single == 8 || syndrome_single == 16 || syndrome_single == 32 || syndrome_single == 64)
            error_i <= 3'b100 ; // single parity error
          else 
            error_i <= 3'b001 ; // single data error
        end
    end
    else begin : no_multi_error_check
      always @(*)
        begin : error_status
          if (~syndrome_i[C_PARITY_BIT_WIDTH-1])   // 0 or 2 errors if  Last check bit is 0
            if (~(|syndrome_i[C_PARITY_BIT_WIDTH-2:0]))
              error_i <= 3'b000; // no error 
            else
              error_i <= 3'b010; // double error
          else if (syndrome_single == 0 || syndrome_single == 1 || syndrome_single == 2 || syndrome_single == 4 || syndrome_single == 8)
            error_i <= 3'b100; // single parity error
          else 
            error_i <= 3'b001; // single data error
        end
    end
  endgenerate

  // Output registers
  always @(posedge Clk)
    begin
      Error    <= error_i;
      Dec_Out  <= decin_reg_i ^ mask[C_DATA_BIT_WIDTH-1:0];
      Syndrome <= syndrome_i;
    end


  always @(*)
  begin : correction_mask
    case ({~syndrome_i[C_PARITY_BIT_WIDTH-1], syndrome_i[C_PARITY_BIT_WIDTH-2:0]})
      8'b00000011 :
            begin
              mask <= 64'h0000000000000001 ; // 0
            end
      8'b00000101 :
            begin
              mask <= 64'h0000000000000002 ; // 1
            end
      8'b00000110 :
            begin
              mask <= 64'h0000000000000004 ; // 2
            end
      8'b00000111 :
            begin
              mask <= 64'h0000000000000008 ; // 3
            end
      8'b00001001 :
            begin
              mask <= 64'h0000000000000010 ; // 4
            end
      8'b00001010 :
            begin
              mask <= 64'h0000000000000020 ; // 5
            end
      8'b00001011 :
            begin
              mask <= 64'h0000000000000040 ; // 6
            end
      8'b00001100 :
            begin
              mask <= 64'h0000000000000080 ; // 7
            end
      8'b00001101 :
            begin
              mask <= 64'h0000000000000100 ; // 8
            end
      8'b00001110 :
            begin
              mask <= 64'h0000000000000200 ; // 9
            end
      8'b00001111 :
            begin
              mask <= 64'h0000000000000400 ; // 10
            end
      8'b00010001 :
            begin
              mask <= 64'h0000000000000800 ; // 11
            end
      8'b00010010 :
            begin
              mask <= 64'h0000000000001000 ; // 12
            end
      8'b00010011 :
            begin
              mask <= 64'h0000000000002000 ; // 13
            end
      8'b00010100 :
            begin
              mask <= 64'h0000000000004000 ; // 14
            end
      8'b00010101 :
            begin
              mask <= 64'h0000000000008000 ; // 15
            end
      8'b00010110 :
            begin
              mask <= 64'h0000000000010000 ; // 16
            end
      8'b00010111 :
            begin
              mask <= 64'h0000000000020000 ; // 17
            end
      8'b00011000 :
            begin
              mask <= 64'h0000000000040000 ; // 18
            end
      8'b00011001 :
            begin
              mask <= 64'h0000000000080000 ; // 19
            end
      8'b00011010 :
            begin
              mask <= 64'h0000000000100000 ; // 20
            end
      8'b00011011 :
            begin
              mask <= 64'h0000000000200000 ; // 21
            end
      8'b00011100 :
            begin
              mask <= 64'h0000000000400000 ; // 22
            end
      8'b00011101 :
            begin
              mask <= 64'h0000000000800000 ; // 23
            end
      8'b00011110 :
            begin
              mask <= 64'h0000000001000000 ; // 24
            end
      8'b00011111 :
            begin
              mask <= 64'h0000000002000000 ; // 25
            end
      8'b00100001 :
            begin
              mask <= 64'h0000000004000000 ; // 26
            end
      8'b00100010 :
            begin
              mask <= 64'h0000000008000000 ; // 27
            end
      8'b00100011 :
            begin
              mask <= 64'h0000000010000000 ; // 28
            end
      8'b00100100 :
            begin
              mask <= 64'h0000000020000000 ; // 29
            end
      8'b00100101 :
            begin
              mask <= 64'h0000000040000000 ; // 30
            end
      8'b00100110 :
            begin
              mask <= 64'h0000000080000000 ; // 31
            end
      8'b00100111 :
            begin
              mask <= 64'h0000000100000000 ; // 32
            end
      8'b00101000 :
            begin
              mask <= 64'h0000000200000000 ; // 33
            end
      8'b00101001 :
            begin
              mask <= 64'h0000000400000000 ; // 34
            end
      8'b00101010 :
            begin
              mask <= 64'h0000000800000000 ; // 35
            end
      8'b00101011 :
            begin
              mask <= 64'h0000001000000000 ; // 36
            end
      8'b00101100 :
            begin
              mask <= 64'h0000002000000000 ; // 37
            end
      8'b00101101 :
            begin
              mask <= 64'h0000004000000000 ; // 38
            end
      8'b00101110 :
            begin
              mask <= 64'h0000008000000000 ; // 39
            end
      8'b00101111 :
            begin
              mask <= 64'h0000010000000000 ; // 40
            end
      8'b00110000 :
            begin
              mask <= 64'h0000020000000000 ; // 41
            end
      8'b00110001 :
            begin
              mask <= 64'h0000040000000000 ; // 42
            end
      8'b00110010 :
            begin
              mask <= 64'h0000080000000000 ; // 43
            end
      8'b00110011 :
            begin
              mask <= 64'h0000100000000000 ; // 44
            end
      8'b00110100 :
            begin
              mask <= 64'h0000200000000000 ; // 45
            end
      8'b00110101 :
            begin
              mask <= 64'h0000400000000000 ; // 46
            end
      8'b00110110 :
            begin
              mask <= 64'h0000800000000000 ; // 47
            end
      8'b00110111 :
            begin
              mask <= 64'h0001000000000000 ; // 48
            end
      8'b00111000 :
            begin
              mask <= 64'h0002000000000000 ; // 49
            end
      8'b00111001 :
            begin
              mask <= 64'h0004000000000000 ; // 50
            end
      8'b00111010 :
            begin
              mask <= 64'h0008000000000000 ; // 51
            end
      8'b00111011 :
            begin
              mask <= 64'h0010000000000000 ; // 52
            end
      8'b00111100 :
            begin
              mask <= 64'h0020000000000000 ; // 53
            end
      8'b00111101 :
            begin
              mask <= 64'h0040000000000000 ; // 54
            end
      8'b00111110 :
            begin
              mask <= 64'h0080000000000000 ; // 55
            end
      8'b00111111 :
            begin
              mask <= 64'h0100000000000000 ; // 56
            end
      8'b01000001 :
            begin
              mask <= 64'h0200000000000000 ; // 57
            end
      8'b01000010 :
            begin
              mask <= 64'h0400000000000000 ; // 58
            end
      8'b01000011 :
            begin
              mask <= 64'h0800000000000000 ; // 59
            end
      8'b01000100 :
            begin
              mask <= 64'h1000000000000000 ; // 60
            end
      8'b01000101 :
            begin
              mask <= 64'h2000000000000000 ; // 61
            end
      8'b01000110 :
            begin
              mask <= 64'h4000000000000000 ; // 62
            end
      8'b01000111 :
            begin
              mask <= 64'h8000000000000000 ; // 63
            end
      default :
            begin
              mask <= 64'h0000000000000000 ; 
            end
    endcase 
  end 

endmodule
