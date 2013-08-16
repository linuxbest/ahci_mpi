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
//Purpose:
// mpmc_ecc_control - ECC Control/Status module
//-------------------------------------------------------------------------
// Filename:         mpmc_ecc_control.v
// Description:      Contains the status and control registers for ECC on MPMC
//                   These are defined in UG253.  All inputs are little endian,
//                   all outputs to the bus interface are big endian.  All 
//                   internal outputs are little endian.
// Verilog-standard: Verilog 2001
//-------------------------------------------------------------------------
// Author:      CJC 
// History:
//  CJC       03/19/2007      - Initial EDK Release
//-------------------------------------------------------------------------

`timescale 1ns/100ps

module mpmc_ecc_control
  #(
    parameter integer C_ECC_DEFAULT_ON = 1,
    parameter integer C_ECC_SEC_THRESHOLD = 4095,
    parameter integer C_ECC_DEC_THRESHOLD = 4095,
    parameter integer C_ECC_PEC_THRESHOLD = 4095
  )
  (
    ////////////////////
    // Global Signals //
    ////////////////////
    input  wire                     Clk, 
    input  wire                     Rst, 
    // Interrupt signal
    output wire                     ECC_Intr,
    ///////////////////////////////////////////
    // ECC Control Interface related signals //
    ///////////////////////////////////////////
    input  wire [0:31]              ECC_Reg_In,
    // Control Register
    input  wire                     ECCCR_Wr,
    output reg  [0:31]              ECCCR = 0,
    // Status Register
    input  wire                     ECCSR_Clr,
    output reg  [0:31]              ECCSR = 0,
    // Single-Bit Error Count Register
    input  wire                     ECCSEC_Clr,
    output reg  [0:31]              ECCSEC = 0,
    // Double-Bit Error Count Register
    input  wire                     ECCDEC_Clr,
    output reg  [0:31]              ECCDEC = 0,
    // Parity-Bit Error Count Register
    input  wire                     ECCPEC_Clr,
    output reg  [0:31]              ECCPEC = 0,
    // ECC ISC
    input  wire [31:0]              Data_Addr,
    output reg  [0:31]              ECCADDR = 0, 
    // DGIE
    input  wire                     DGIE_Wr,
    output reg  [0:31]              DGIE = 0,
    // IPISR
    input  wire                     IPISR_Wr,
    output reg  [0:31]              IPISR = 0,
    // IPIER
    input  wire                     IPIER_Wr,
    output reg  [0:31]              IPIER = 0,
    ///////////////////////////
    // ECC Data path signals //
    ///////////////////////////
    // Encode Forced errors into the data/parity 
    input  wire                     Bypass_Decode,
    output reg  [2:0]               Force_Error,
    output reg                      Decode_En,    // Decode datapath enable
    output reg                      Encode_En,    // Encode datapath enable
    input  wire [2:0]               Data_Error_0, // Decode Errors 0 
    input  wire [2:0]               Data_Error_1, // Decode Errors 1
    input  wire [3:0]               Err_Size,   // Transaction size 
    input  wire                     Err_RNW,    // Read Or Write
    input  wire [7:0]               Err_Synd_0,   // Output syndrome of the decode
    input  wire [7:0]               Err_Synd_1    // Output syndrome of the decode
);
  // coverage toggle_ignore ECCCR "0"
  // coverage toggle_ignore ECCSR "0-15"

  reg                   err_flagged = 0;

  // ECC Control Register
  // Bits 0-26 are reserved and thus not used to save logic
  generate
    if (C_ECC_DEFAULT_ON == 0)
      begin : ECC_DEFAULT_OFF
        always @(posedge Clk)
          if (Rst) ECCCR <= {30'b0, 1'b0, 1'b0};
          else if (ECCCR_Wr) ECCCR[27:31] <= ECC_Reg_In[27:31];
      end
    else
      begin : ECC_DEFAULT_ON
        always @(posedge Clk)
          if (Rst) ECCCR <= {30'b0, 1'b1, 1'b1};
          else if (ECCCR_Wr) ECCCR[27:31] <= ECC_Reg_In[27:31];
      end
  endgenerate

  always @(posedge Clk)
    begin
       Force_Error[2] <= ECCCR[27];
       Force_Error[1] <= ECCCR[28];
       Force_Error[0] <= ECCCR[29];
       Decode_En      <= ECCCR[30] & ~Bypass_Decode;
       Encode_En      <= ECCCR[31];
    end
   
  // ECC Status Register
  // Bits 0-15 are reserved and thus not used to save logic
  always @(posedge Clk)
    if (Rst | ECCSR_Clr) 
      begin 
        ECCSR <= 0;
        err_flagged <= 0;
      end
    else if (~err_flagged & (| Data_Error_0))
      begin
        err_flagged <= 1;
        ECCSR[16:19] <= Err_Size;
        ECCSR[20]    <= Err_RNW;
        ECCSR[21:28] <= Err_Synd_0;
        ECCSR[29]    <= (Data_Error_0[2]);
        ECCSR[30]    <= (Data_Error_0[1]);
        ECCSR[31]    <= (Data_Error_0[0]);
     end
    else if (~err_flagged & (| Data_Error_1))
      begin
        err_flagged <= 1;
        ECCSR[16:19] <= Err_Size;
        ECCSR[20]    <= Err_RNW;
        ECCSR[21:28] <= Err_Synd_1;
        ECCSR[29]    <= (Data_Error_1[2]);
        ECCSR[30]    <= (Data_Error_1[1]);
        ECCSR[31]    <= (Data_Error_1[0]);
     end

  // Single-Bit Error Count Register
  // Bits 0-19 are reserved and thus not used to save logic
  // Increment by 1 if Data_Error_0 xor Data_Error_1 & ECC_SEC is not all 1's)
  // Increment by 2 if There are two data errors and we can increment by 2
  // else Increment by 1 if ther are two data errors if we can increment by 1
  always @(posedge Clk)
    if (Rst | ECCSEC_Clr)
      ECCSEC <= 0; 
    else if ((Data_Error_0[0] ^ Data_Error_1[0]) & (~& ECCSEC[20:31]))
      ECCSEC[20:31] <= ECCSEC[20:31] + 1'b1;
    else if ((Data_Error_0[0] & Data_Error_1[0]) & (~& ECCSEC[20:30]))
      ECCSEC[20:31] <= ECCSEC[20:31] + 2'd2;
    else if ((Data_Error_0[0] & Data_Error_1[0]) & (~ECCSEC[31]))
      ECCSEC[20:31] <= ECCSEC[20:31] + 1'b1;

  // Double-Bit Error Count Register
  // Bits 0-19 are reserved and thus not used to save logic
  always @(posedge Clk)
    if (Rst | ECCDEC_Clr)
      ECCDEC <= 0; 
    else if ((Data_Error_0[1] ^ Data_Error_1[1]) & (~& ECCDEC[20:31]))
      ECCDEC[20:31] <= ECCDEC[20:31] + 1'b1;
    else if ((Data_Error_0[1] & Data_Error_1[1]) & (~& ECCDEC[20:30]))
      ECCDEC[20:31] <= ECCDEC[20:31] + 2'd2;
    else if ((Data_Error_0[1] & Data_Error_1[1]) & (~ECCDEC[31]))
      ECCDEC[20:31] <= ECCDEC[20:31] + 1'b1;

  // Parity-Bit Error Count Register
  // Bits 0-19 are reserved and thus not used to save logic
  always @(posedge Clk)
    if (Rst | ECCPEC_Clr)
      ECCPEC <= 0; 
    else if ((Data_Error_0[2] ^ Data_Error_1[2]) & (~& ECCPEC[20:31]))
      ECCPEC[20:31] <= ECCPEC[20:31] + 1'b1;
    else if ((Data_Error_0[2] & Data_Error_1[2]) & (~& ECCPEC[20:30]))
      ECCPEC[20:31] <= ECCPEC[20:31] + 2'd2;
    else if ((Data_Error_0[2] & Data_Error_1[2]) & (~ECCPEC[31]))
      ECCPEC[20:31] <= ECCPEC[20:31] + 1'b1;

  // ECC Error Addresss Register
  always @(posedge Clk)
    if (~err_flagged & ((| Data_Error_0) | (| Data_Error_1)))
      ECCADDR <= Data_Addr;

  // ECC Interrupts 
  // Device Global Interrupt Enable Register
  always @(posedge Clk)
    if (Rst) DGIE <= 0;
    else if (DGIE_Wr) DGIE[0] <= ECC_Reg_In[0];

  // IP Interrupt Status Register
  always @(posedge Clk)
    if (Rst)            
      IPISR <= 0;
    else if (IPISR_Wr)  
      IPISR[29:31] <= IPISR[29:31] ^ ECC_Reg_In[29:31];
    else
      begin
        IPISR[29] <= (ECCPEC >= C_ECC_PEC_THRESHOLD) | IPISR[29]; 
        IPISR[30] <= (ECCDEC >= C_ECC_DEC_THRESHOLD) | IPISR[30]; 
        IPISR[31] <= (ECCSEC >= C_ECC_SEC_THRESHOLD) | IPISR[31]; 
      end
    
  // IP Interrupt Enable Register
  always @(posedge Clk)
    if (Rst)            IPIER <= 0;
    else if (IPIER_Wr)  IPIER[29:31] <= ECC_Reg_In[29:31];

  // Generate interrupt if any IPISR is set and corrresponding IPIER is set and 
  // DGIE is set
  assign ECC_Intr = DGIE[0] & (|(IPISR[29:31] & IPIER[29:31]));

endmodule
