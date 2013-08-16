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
//Purpose: MPMC Address Path
//
//Reference:
//Revision History:
//
//-----------------------------------------------------------------------------
`timescale 1ns/1ns


module mpmc_addr_path (
   // System Signals
   Clk0,                         // I
   Clk90,                        // I
   Rst,                          // I
   Rst270,                       // I
   // Phy Interface Signals
   AP_PhyIF_BankAddr,            // O [C_MEM_BANKADDR_WIDTH-1:0]
   AP_PhyIF_Addr,                // O [C_MEM_ADDR_WIDTH-1:0]
   AP_PhyIF_CS_n,                // O [C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS-1:0]
   // Port Interface Signals
   PI_Addr,                      // I [C_PI_ADDR_WIDTH*C_NUM_PORTS-1:0]
   // EEPROM Serial Presence Detect Signals
   SPD_AP_Total_Offset,          // I [8*C_MEM_NUM_DIMMS-1:0]
   SPD_AP_DIMM_Offset,           // I [8*C_MEM_NUM_DIMMS-1:0]
   SPD_AP_Rank_Offset,           // I [8*C_MEM_NUM_DIMMS-1:0]
   SPD_AP_Bank_Offset,           // I [8*C_MEM_NUM_DIMMS-1:0]
   SPD_AP_Row_Offset,            // I [8*C_MEM_NUM_DIMMS-1:0]
   SPD_AP_Col_Offset,            // I [8*C_MEM_NUM_DIMMS-1:0]
   // Address Decode for Control Path
   AP_Ctrl_Addr,                 // O [C_PI_ADDR_WIDTH-1:0]
   // Control Signals
   Ctrl_AP_PI_Addr_CE,           // I [C_NUM_PORTS-1:0]
   Ctrl_AP_Port_Select,          // I [C_ARB_PORT_ENCODING_WIDTH-1:0]
   Ctrl_AP_Pipeline1_CE,         // I
   Ctrl_AP_Row_Col_Sel,          // I
   Ctrl_AP_Col_Cnt_Load,         // I
   Ctrl_AP_Col_Cnt_Enable,       // I
   Ctrl_AP_Col_W,                // I
   Ctrl_AP_Col_DW,               // I
   Ctrl_AP_Col_CL4,              // I
   Ctrl_AP_Col_CL8,              // I
   Ctrl_AP_Col_B16,              // I
   Ctrl_AP_Col_B32,              // I
   Ctrl_AP_Col_B64,              // I
   Ctrl_AP_Col_Burst_Length,              // I
   Ctrl_AP_Precharge_Addr10,     // I
   Ctrl_AP_OTF_Addr12,           // I
   Ctrl_AP_Assert_All_CS         // I
);

   parameter C_FAMILY         = "virtex4";
   parameter C_USE_MIG_S3_PHY = 0;
   parameter C_USE_STATIC_PHY = 1'b0;
   
   // Memory Parameters
   parameter C_NUM_PORTS = 8;              // Allowed Values: 1-8
   parameter C_PI_ADDR_WIDTH = 32;         // Allowed Values: 32, 36
   parameter C_MEM_ADDR_WIDTH = 13;        // Allowed Values: 13
   parameter C_MEM_BANKADDR_WIDTH = 2;     // Allowed Values: 2
   parameter C_MEM_DATA_WIDTH = 32;        // Allowed Values: 8,16,32,64,72
   parameter C_MEM_BURST_LENGTH = 4;       // Allowed Values: 2,4,8

   // Extra Pipeline Stages 
   parameter C_AP_PIPELINE1 = 1'b1; // Allowed Values: 0,1
   parameter C_AP_PIPELINE2 = 1'b1; // Allowed Values: 0,1

   // Memory Parameters
   parameter C_MEM_NUM_DIMMS = 1; // Allowed Values: 1,2
   parameter C_MEM_NUM_RANKS = 1; // Allowed Values: 1,2
   parameter C_MEM_SUPPORTED_TOTAL_OFFSETS = 32'h08000000;
   parameter C_MEM_SUPPORTED_DIMM_OFFSETS  = 32'h08000000;
   parameter C_MEM_SUPPORTED_RANK_OFFSETS  = 32'h08000000;
   parameter C_MEM_SUPPORTED_BANK_OFFSETS  = 32'h02000000;
   parameter C_MEM_SUPPORTED_ROW_OFFSETS   = 32'h00001000;
   parameter C_MEM_SUPPORTED_COL_OFFSETS   = 32'h00000004;

   // Temporary Memory Parameters
   parameter C_USE_TEMP_PARAMETERS = 1;
   parameter C_MEM_DIMM0_TOTAL_OFFSET = 27;
   parameter C_MEM_DIMM0_DIMM_OFFSET  = 27;
   parameter C_MEM_DIMM0_RANK_OFFSET  = 27;
   parameter C_MEM_DIMM0_BANK_OFFSET  = 25;
   parameter C_MEM_DIMM0_ROW_OFFSET   = 12;
   parameter C_MEM_DIMM0_COL_OFFSET   = 2;
   parameter C_MEM_DIMM1_TOTAL_OFFSET = 27;
   parameter C_MEM_DIMM1_DIMM_OFFSET  = 27;
   parameter C_MEM_DIMM1_RANK_OFFSET  = 27;
   parameter C_MEM_DIMM1_BANK_OFFSET  = 25;
   parameter C_MEM_DIMM1_ROW_OFFSET   = 12;
   parameter C_MEM_DIMM1_COL_OFFSET   = 2;

   parameter C_IS_DDR = 1'b1;              // Allowed Values: 0,1 
   parameter C_MEM_TYPE = "DDR3";          // Allowed Values: SDRAM, DDR, 
                                           //   DDR2, DDR3
   parameter C_NCK_PER_CLK             = 1;
   parameter C_ARB_PORT_ENCODING_WIDTH = 3;

   
   
   localparam P_MEM_DATA_WIDTH_SDR = C_IS_DDR ? C_MEM_DATA_WIDTH*2*C_NCK_PER_CLK:
                                                C_MEM_DATA_WIDTH;

   // System Signals
   input                                            Clk0;
   input                                            Clk90;
   input                                            Rst;
   input                                            Rst270;
   // Memory Signals (To/From Memory Pins)
   output [C_MEM_BANKADDR_WIDTH-1:0]                AP_PhyIF_BankAddr;
   output [C_MEM_ADDR_WIDTH-1:0]                    AP_PhyIF_Addr;
   output [C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS-1:0]     AP_PhyIF_CS_n;
   // Port Interface Signals
   input  [C_PI_ADDR_WIDTH*C_NUM_PORTS-1:0]         PI_Addr;
   // EEPROM Serial Presence Detect Signals
   input  [8*C_MEM_NUM_DIMMS-1:0]                   SPD_AP_Total_Offset;
   input  [8*C_MEM_NUM_DIMMS-1:0]                   SPD_AP_DIMM_Offset;
   input  [8*C_MEM_NUM_DIMMS-1:0]                   SPD_AP_Rank_Offset;
   input  [8*C_MEM_NUM_DIMMS-1:0]                   SPD_AP_Bank_Offset;
   input  [8*C_MEM_NUM_DIMMS-1:0]                   SPD_AP_Row_Offset;
   input  [8*C_MEM_NUM_DIMMS-1:0]                   SPD_AP_Col_Offset;
   // Address Decode for Control Path
   output [C_PI_ADDR_WIDTH-1:0]                     AP_Ctrl_Addr;
   // Control Signals
   input  [C_NUM_PORTS-1:0]                         Ctrl_AP_PI_Addr_CE;
   input  [C_ARB_PORT_ENCODING_WIDTH-1:0]           Ctrl_AP_Port_Select;
   input                                            Ctrl_AP_Pipeline1_CE;
   input                                            Ctrl_AP_Row_Col_Sel;
   input                                            Ctrl_AP_Col_Cnt_Load;
   input                                            Ctrl_AP_Col_Cnt_Enable;
   input                                            Ctrl_AP_Col_W;
   input                                            Ctrl_AP_Col_DW;
   input                                            Ctrl_AP_Col_CL4;
   input                                            Ctrl_AP_Col_CL8;
   input                                            Ctrl_AP_Col_B16;
   input                                            Ctrl_AP_Col_B32;
   input                                            Ctrl_AP_Col_B64;
   input [3:0]                                      Ctrl_AP_Col_Burst_Length;
   input                                            Ctrl_AP_Precharge_Addr10;
   input                                            Ctrl_AP_OTF_Addr12;
   input                                            Ctrl_AP_Assert_All_CS;
   
   reg  [C_MEM_BANKADDR_WIDTH-1:0]             AP_PhyIF_BankAddr;
   reg  [C_MEM_ADDR_WIDTH-1:0]                 AP_PhyIF_Addr;
   reg  [C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS-1:0]  AP_PhyIF_CS;
   
   reg  [C_PI_ADDR_WIDTH*C_NUM_PORTS-1:0]      Addr_Reg;
   reg  [C_PI_ADDR_WIDTH-1:0]                  Addr_Mux;
   reg  [C_PI_ADDR_WIDTH-1:0]                  Addr_Pipeline1;
   reg  [C_PI_ADDR_WIDTH-1:0]                  Addr_Aligned;

   wire                                        Swap_DIMM_Offset;
   wire [7:0]                                  DIMM_Offset;
   wire [7:0]                                  Rank_Offset;
   wire [7:0]                                  Bank_Offset;
   wire [7:0]                                  Row_Offset;
   wire [7:0]                                  Col_Offset;

   reg                                         DIMM_Addr;
   reg                                         Rank_Addr;
   reg  [C_MEM_BANKADDR_WIDTH-1:0]             Bank_Addr;
   reg  [C_MEM_ADDR_WIDTH-1:0]                 Row_Addr;
   reg  [C_MEM_ADDR_WIDTH-2:0]                 Col_Addr;

   reg  [C_MEM_ADDR_WIDTH-2:0]                 Col_Cnt;
   wire [C_MEM_ADDR_WIDTH-1:0]                 Col_Addr_Full;
   wire [C_MEM_ADDR_WIDTH-1:0]                 Row_Col_Mux_Out;

   wire [C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS-1:0]  Dimm_Addr_Final;
   wire [C_MEM_NUM_RANKS-1:0]                 Rank_Addr_Final;   
   reg  [C_MEM_BANKADDR_WIDTH-1:0]             Bank_Addr_Final;
   reg  [C_MEM_ADDR_WIDTH-1:0]                 Row_Col_Final;
   
   genvar  i;
   integer j;
   

   // Set Address to Control path
   assign AP_Ctrl_Addr = Addr_Pipeline1;
   
   // Generate registers for address buses
   generate
      for (i = 0; i < C_NUM_PORTS; i = i + 1) begin : addr_reg
         always @(posedge Clk0)
            if (Rst) Addr_Reg[(i+1)*C_PI_ADDR_WIDTH-1:i*C_PI_ADDR_WIDTH] <= 0;
            else if (Ctrl_AP_PI_Addr_CE[i]) Addr_Reg[(i+1)*C_PI_ADDR_WIDTH-1:i*C_PI_ADDR_WIDTH] <= PI_Addr[(i+1)*C_PI_ADDR_WIDTH-1:i*C_PI_ADDR_WIDTH];
      end
   endgenerate


   // Generate mux to select address
   always @(Ctrl_AP_Port_Select or Addr_Reg) begin
      Addr_Mux <= 'bx;
      for (j = 4'd0; j < C_NUM_PORTS; j = j + 1'd1) begin : addr_mux
         if (Ctrl_AP_Port_Select == j) Addr_Mux <= Addr_Reg >> j*C_PI_ADDR_WIDTH;
      end
   end

   
   // Pipeline1 Register
   generate
      if (C_AP_PIPELINE1) begin : pipeline1_addr_reg
         always @(posedge Clk0)
           if (Rst) Addr_Pipeline1 <= 0;
           else if (Ctrl_AP_Pipeline1_CE) Addr_Pipeline1 <= Addr_Mux;
      end
      else begin : pipeline1_addr_wire
         always @(Addr_Mux) Addr_Pipeline1 <= Addr_Mux;
      end
   endgenerate


   // Align Address to 64-bit or 128-bit boundary
   generate
      if (C_MEM_TYPE == "DDR3" && C_NCK_PER_CLK == 2) begin : gen_addr_pipeline1_ddr3
        always @(*)
          // QWORD covers all cases for DWIDTH = 32
         if (C_MEM_DATA_WIDTH == 32) begin : dw32_align
            Addr_Aligned = {Addr_Pipeline1[C_PI_ADDR_WIDTH-1:4], 4'b0};
          end
          // Artificially align transfer to QWORD if CL8 Transfer to keep
          // linear rdwdaddr (e.g. 0,1,2,3,4,5,6,7 or 4,5,6,7,0,1,2,3)
          else if (C_MEM_DATA_WIDTH == 16) begin : dw16_align
            Addr_Aligned = {Addr_Pipeline1[C_PI_ADDR_WIDTH-1:4], 
                            Addr_Pipeline1[3] & ~Ctrl_AP_Col_CL8, 3'b0};
          end
          else if (C_MEM_DATA_WIDTH == 8) begin : dw8_align
            Addr_Aligned = {Addr_Pipeline1[C_PI_ADDR_WIDTH-1:3], 
                //            Addr_Pipeline1[3] & ~Ctrl_AP_Col_CL8, // Align to Dword, if CL8 align to Qword
                            Addr_Pipeline1[2] & Ctrl_AP_Col_W,  // Align to word on word transfer
                            2'b0};
          end
      end else if (C_IS_DDR) begin : gen_addr_pipeline1_ddr
        always @(*)
         if (((P_MEM_DATA_WIDTH_SDR == 32) & (C_MEM_BURST_LENGTH == 8)) | 
             ((P_MEM_DATA_WIDTH_SDR == 64) & (C_MEM_BURST_LENGTH == 4))) begin : zero_cl8
            Addr_Aligned = {Addr_Pipeline1[C_PI_ADDR_WIDTH-1:4], Addr_Pipeline1[3] & ~Ctrl_AP_Col_CL8, 3'b0};
         end
         else if ((P_MEM_DATA_WIDTH_SDR == 64) & (C_MEM_BURST_LENGTH == 8)) begin : zero_cl4
            Addr_Aligned = {Addr_Pipeline1[C_PI_ADDR_WIDTH-1:4], Addr_Pipeline1[3] & ~Ctrl_AP_Col_CL4, 3'b0};
         end
         else if ((P_MEM_DATA_WIDTH_SDR == 128) & ((C_MEM_BURST_LENGTH == 2) | (C_MEM_BURST_LENGTH == 4))) begin : zero_64
            Addr_Aligned = {Addr_Pipeline1[C_PI_ADDR_WIDTH-1:4], 4'b0};
         end
         else if ((P_MEM_DATA_WIDTH_SDR == 128) & (C_MEM_BURST_LENGTH == 8)) begin : zero_cl4_8
            Addr_Aligned = {Addr_Pipeline1[C_PI_ADDR_WIDTH-1:5], Addr_Pipeline1[4] & (~Ctrl_AP_Col_CL4 & ~Ctrl_AP_Col_CL8), 4'b0};
          //  Hack to support OTF  on DDR3 32 bit memory
/*            Addr_Aligned = {Addr_Pipeline1[C_PI_ADDR_WIDTH-1:5], Addr_Pipeline1[4] & (~Ctrl_AP_Col_CL8), 4'b0};*/
/*            Addr_Aligned = {Addr_Pipeline1[C_PI_ADDR_WIDTH-1:4], 4'b0};*/
         end
         else if ((P_MEM_DATA_WIDTH_SDR == 32) | (P_MEM_DATA_WIDTH_SDR == 16)) begin : word_align
            Addr_Aligned = {Addr_Pipeline1[C_PI_ADDR_WIDTH-1:3], (Ctrl_AP_Col_W ? Addr_Pipeline1[2] : 1'b0), 2'b0};
         end
         else begin : doubleword_align
            Addr_Aligned = {Addr_Pipeline1[C_PI_ADDR_WIDTH-1:3], 3'b0};
         end
      end
      else begin : gen_addr_pipeline1_sdr
        always @(*)
         if ((P_MEM_DATA_WIDTH_SDR == 64) & (C_MEM_BURST_LENGTH == 4)) begin : zero_cl8_cl4
            Addr_Aligned = {Addr_Pipeline1[C_PI_ADDR_WIDTH-1:4], Addr_Pipeline1[3] & ~Ctrl_AP_Col_CL8 & ~Ctrl_AP_Col_CL4, 3'b0};
         end
         else if ((P_MEM_DATA_WIDTH_SDR == 32) & (C_MEM_BURST_LENGTH == 4)) begin : zero_cl8
            Addr_Aligned = {Addr_Pipeline1[C_PI_ADDR_WIDTH-1:4], Addr_Pipeline1[3] & ~Ctrl_AP_Col_CL8, Addr_Pipeline1[2] & Ctrl_AP_Col_W, 2'b0};
         end
         else if ((P_MEM_DATA_WIDTH_SDR == 16) & (C_MEM_BURST_LENGTH == 4)) begin : word_align_16
            Addr_Aligned = {Addr_Pipeline1[C_PI_ADDR_WIDTH-1:3], (Ctrl_AP_Col_W ? Addr_Pipeline1[2] : 1'b0), 2'b0};
         end
         else if ((P_MEM_DATA_WIDTH_SDR == 8) & (C_MEM_BURST_LENGTH == 4)) begin : word_align_8
            Addr_Aligned = {Addr_Pipeline1[C_PI_ADDR_WIDTH-1:3], (Ctrl_AP_Col_W ? Addr_Pipeline1[2] : 1'b0), 2'b0};
         end
         else begin : doubleword_align
            Addr_Aligned = {Addr_Pipeline1[C_PI_ADDR_WIDTH-1:3], 3'b0};
         end
      end
   endgenerate
   
   
   // Swap Memory Decode (Hardcoded for 1 or 2 DIMMs only)
   generate
      if (C_MEM_NUM_DIMMS == 1) begin : no_swap
         assign Swap_DIMM_Offset = 0;
      end
      else if (C_MEM_NUM_DIMMS == 2) begin : swap
         assign Swap_DIMM_Offset = SPD_AP_DIMM_Offset[15:8] > SPD_AP_DIMM_Offset[7:0];
      end
   endgenerate


   // Generate DIMM Offset (Hardcoded for 1 or 2 DIMMs only)
   generate
      if (C_MEM_NUM_DIMMS == 1) begin : wire_offset
         assign DIMM_Offset = SPD_AP_DIMM_Offset;
      end
      else if (C_MEM_NUM_DIMMS == 2) begin : mux_offset
         assign DIMM_Offset = Swap_DIMM_Offset ? SPD_AP_DIMM_Offset[15:8] : SPD_AP_DIMM_Offset[7:0];
      end
   endgenerate

   
   // Decode DIMM Address
   always @(Addr_Aligned or DIMM_Offset or Swap_DIMM_Offset) begin
      if (C_MEM_NUM_DIMMS == 1) DIMM_Addr <= 0;
      else if (C_MEM_SUPPORTED_DIMM_OFFSETS[DIMM_Offset]) DIMM_Addr <= (Addr_Aligned >> DIMM_Offset) ^ Swap_DIMM_Offset;
      else DIMM_Addr <= 'bx;
   end


   // Mux Rank Offset
   assign Rank_Offset = SPD_AP_Rank_Offset >> 8 * DIMM_Addr;
   
   // Offset Rank Address
   always @(Addr_Aligned or Rank_Offset) begin
      if (C_MEM_SUPPORTED_RANK_OFFSETS[Rank_Offset]) Rank_Addr <= (Addr_Aligned >> Rank_Offset);
      else Rank_Addr <= 'bx;
   end


   // Mux Bank Offset
   assign Bank_Offset = SPD_AP_Bank_Offset >> 8 * DIMM_Addr;
   
   // Offset Bank Address
   always @(Addr_Aligned or Bank_Offset) begin
      if (C_MEM_SUPPORTED_BANK_OFFSETS[Bank_Offset]) Bank_Addr <= (Addr_Aligned >> Bank_Offset);
      else Bank_Addr <= 'bx;
   end

   
   // Mux Row Offset
   assign Row_Offset = SPD_AP_Row_Offset >> 8 * DIMM_Addr;

   // Offset Row Address
   always @(Addr_Aligned or Row_Offset) begin
      if (C_MEM_SUPPORTED_ROW_OFFSETS[Row_Offset]) Row_Addr <= (Addr_Aligned >> Row_Offset);
      else Row_Addr <= 'bx;
   end

   
   // Mux Col Offset
   assign Col_Offset = SPD_AP_Col_Offset >> 8 * DIMM_Addr;

   // Offset Column Address
   always @(Addr_Aligned or Col_Offset) begin
      if (C_MEM_SUPPORTED_COL_OFFSETS[Col_Offset]) Col_Addr <= (Addr_Aligned >> Col_Offset);
      else Col_Addr <= 'bx;
   end
   
   
   // Column Counter
   generate 
      if (C_IS_DDR) begin : gen_col_cnt_ddr
         always @(posedge Clk0) begin
            if (Rst) Col_Cnt <= 0;
            else if (Ctrl_AP_Col_Cnt_Load) Col_Cnt <= Col_Addr;
            else if (Ctrl_AP_Col_Cnt_Enable) begin
               if ((C_MEM_DATA_WIDTH == 8) & (C_MEM_BURST_LENGTH == 4)) begin
                  if      (Ctrl_AP_Col_DW)  Col_Cnt[2:2] <= Col_Cnt[2:2] + 1;
                  else if (Ctrl_AP_Col_CL4) Col_Cnt[3:2] <= Col_Cnt[3:2] + 1;
                  else if (Ctrl_AP_Col_CL8) Col_Cnt[4:2] <= Col_Cnt[4:2] + 1;
                  else if (Ctrl_AP_Col_B16) Col_Cnt[5:2] <= Col_Cnt[5:2] + 1;
                  else if (Ctrl_AP_Col_B32) Col_Cnt[6:2] <= Col_Cnt[6:2] + 1;
                  else if (Ctrl_AP_Col_B64) Col_Cnt[7:2] <= Col_Cnt[7:2] + 1;
               end
               else if ((C_MEM_DATA_WIDTH == 8) & (C_MEM_BURST_LENGTH == 8)) begin
                  if      (Ctrl_AP_Col_CL4) Col_Cnt[3:3] <= Col_Cnt[3:3] + 1;
                  else if (Ctrl_AP_Col_CL8) Col_Cnt[4:3] <= Col_Cnt[4:3] + 1;
                  else if (Ctrl_AP_Col_B16) Col_Cnt[5:3] <= Col_Cnt[5:3] + 1;
                  else if (Ctrl_AP_Col_B32) Col_Cnt[6:3] <= Col_Cnt[6:3] + 1;
                  else if (Ctrl_AP_Col_B64) Col_Cnt[7:3] <= Col_Cnt[7:3] + 1;
               end
               else if ((C_MEM_DATA_WIDTH == 16) & (C_MEM_BURST_LENGTH == 4)) begin
                  if      (Ctrl_AP_Col_CL4) Col_Cnt[2:2] <= Col_Cnt[2:2] + 1;
                  else if (Ctrl_AP_Col_CL8) Col_Cnt[3:2] <= Col_Cnt[3:2] + 1;
                  else if (Ctrl_AP_Col_B16) Col_Cnt[4:2] <= Col_Cnt[4:2] + 1;
                  else if (Ctrl_AP_Col_B32) Col_Cnt[5:2] <= Col_Cnt[5:2] + 1;
                  else if (Ctrl_AP_Col_B64) Col_Cnt[6:2] <= Col_Cnt[6:2] + 1;
               end
               else if ((C_MEM_DATA_WIDTH == 16) & (C_MEM_BURST_LENGTH == 8)) begin
                  if      (Ctrl_AP_Col_CL8) Col_Cnt[3:3] <= Col_Cnt[3:3] + 1;
                  else if (Ctrl_AP_Col_B16) Col_Cnt[4:3] <= Col_Cnt[4:3] + 1;
                  else if (Ctrl_AP_Col_B32) Col_Cnt[5:3] <= Col_Cnt[5:3] + 1;
                  else if (Ctrl_AP_Col_B64) Col_Cnt[6:3] <= Col_Cnt[6:3] + 1;
               end
               else if ((C_MEM_DATA_WIDTH == 32) & (C_MEM_BURST_LENGTH == 4)) begin
                  if      (Ctrl_AP_Col_CL8) Col_Cnt[2:2] <= Col_Cnt[2:2] + 1;
                  else if (Ctrl_AP_Col_B16) Col_Cnt[3:2] <= Col_Cnt[3:2] + 1;
                  else if (Ctrl_AP_Col_B32) Col_Cnt[4:2] <= Col_Cnt[4:2] + 1;
                  else if (Ctrl_AP_Col_B64) Col_Cnt[5:2] <= Col_Cnt[5:2] + 1;
               end
               else if ((C_MEM_DATA_WIDTH == 32) & (C_MEM_BURST_LENGTH == 8)) begin
                  if      (Ctrl_AP_Col_B16) Col_Cnt[3:3] <= Col_Cnt[3:3] + 1;
                  else if (Ctrl_AP_Col_B32) Col_Cnt[4:3] <= Col_Cnt[4:3] + 1;
                  else if (Ctrl_AP_Col_B64) Col_Cnt[5:3] <= Col_Cnt[5:3] + 1;
               end         
               else if ((C_MEM_DATA_WIDTH == 64) & (C_MEM_BURST_LENGTH == 4)) begin
                       if (Ctrl_AP_Col_B16) Col_Cnt[2:2] <= Col_Cnt[2:2] + 1;
                  else if (Ctrl_AP_Col_B32) Col_Cnt[3:2] <= Col_Cnt[3:2] + 1;
                  else if (Ctrl_AP_Col_B64) Col_Cnt[4:2] <= Col_Cnt[4:2] + 1;
               end
               else if ((C_MEM_DATA_WIDTH == 64) & (C_MEM_BURST_LENGTH == 8)) begin 
                  if      (Ctrl_AP_Col_B32) Col_Cnt[3:3] <= Col_Cnt[3:3] + 1;
                  else if (Ctrl_AP_Col_B64) Col_Cnt[4:3] <= Col_Cnt[4:3] + 1;
               end
            end
         end
      end
      else begin : gen_col_cnt_sdr
         always @(posedge Clk0) begin
            if (Rst) Col_Cnt <= 0;
            else if (Ctrl_AP_Col_Cnt_Load) Col_Cnt <= Col_Addr;
            else if (Ctrl_AP_Col_Cnt_Enable) begin
               if ((P_MEM_DATA_WIDTH_SDR == 8) & (C_MEM_BURST_LENGTH == 2)) begin
                  if      (Ctrl_AP_Col_W)   Col_Cnt[1:1] <= Col_Cnt[1:1] + 1;
                  else if (Ctrl_AP_Col_DW)  Col_Cnt[2:1] <= Col_Cnt[2:1] + 1;
                  else if (Ctrl_AP_Col_CL4) Col_Cnt[3:1] <= Col_Cnt[3:1] + 1;
                  else if (Ctrl_AP_Col_CL8) Col_Cnt[4:1] <= Col_Cnt[4:1] + 1;
                  else if (Ctrl_AP_Col_B16) Col_Cnt[5:1] <= Col_Cnt[5:1] + 1;
                  else if (Ctrl_AP_Col_B32) Col_Cnt[6:1] <= Col_Cnt[6:1] + 1;
                  else if (Ctrl_AP_Col_B64) Col_Cnt[7:1] <= Col_Cnt[7:1] + 1;
               end
               else if ((P_MEM_DATA_WIDTH_SDR == 8) & (C_MEM_BURST_LENGTH == 4)) begin
                  if      (Ctrl_AP_Col_DW)  Col_Cnt[2:2] <= Col_Cnt[2:2] + 1;
                  else if (Ctrl_AP_Col_CL4) Col_Cnt[3:2] <= Col_Cnt[3:2] + 1;
                  else if (Ctrl_AP_Col_CL8) Col_Cnt[4:2] <= Col_Cnt[4:2] + 1;
                  else if (Ctrl_AP_Col_B16) Col_Cnt[5:2] <= Col_Cnt[5:2] + 1;
                  else if (Ctrl_AP_Col_B32) Col_Cnt[6:2] <= Col_Cnt[6:2] + 1;
                  else if (Ctrl_AP_Col_B64) Col_Cnt[7:2] <= Col_Cnt[7:2] + 1;
               end
               else if ((P_MEM_DATA_WIDTH_SDR == 8) & (C_MEM_BURST_LENGTH == 8)) begin
                  if      (Ctrl_AP_Col_CL4) Col_Cnt[3:3] <= Col_Cnt[3:3] + 1;
                  else if (Ctrl_AP_Col_CL8) Col_Cnt[4:3] <= Col_Cnt[4:3] + 1;
                  else if (Ctrl_AP_Col_B16) Col_Cnt[5:3] <= Col_Cnt[5:3] + 1;
                  else if (Ctrl_AP_Col_B32) Col_Cnt[6:3] <= Col_Cnt[6:3] + 1;
                  else if (Ctrl_AP_Col_B64) Col_Cnt[7:3] <= Col_Cnt[7:3] + 1;
               end
               else if ((P_MEM_DATA_WIDTH_SDR == 16) & (C_MEM_BURST_LENGTH == 2)) begin
                  if      (Ctrl_AP_Col_DW)  Col_Cnt[1:1] <= Col_Cnt[1:1] + 1;
                  else if (Ctrl_AP_Col_CL4) Col_Cnt[2:1] <= Col_Cnt[2:1] + 1;
                  else if (Ctrl_AP_Col_CL8) Col_Cnt[3:1] <= Col_Cnt[3:1] + 1;
                  else if (Ctrl_AP_Col_B16) Col_Cnt[4:1] <= Col_Cnt[4:1] + 1;
                  else if (Ctrl_AP_Col_B32) Col_Cnt[5:1] <= Col_Cnt[5:1] + 1;
                  else if (Ctrl_AP_Col_B64) Col_Cnt[6:1] <= Col_Cnt[6:1] + 1;
               end
               else if ((P_MEM_DATA_WIDTH_SDR == 16) & (C_MEM_BURST_LENGTH == 4)) begin
                  if      (Ctrl_AP_Col_CL4) Col_Cnt[2:2] <= Col_Cnt[2:2] + 1;
                  else if (Ctrl_AP_Col_CL8) Col_Cnt[3:2] <= Col_Cnt[3:2] + 1;
                  else if (Ctrl_AP_Col_B16) Col_Cnt[4:2] <= Col_Cnt[4:2] + 1;
                  else if (Ctrl_AP_Col_B32) Col_Cnt[5:2] <= Col_Cnt[5:2] + 1;
                  else if (Ctrl_AP_Col_B64) Col_Cnt[6:2] <= Col_Cnt[6:2] + 1;
               end
               else if ((P_MEM_DATA_WIDTH_SDR == 16) & (C_MEM_BURST_LENGTH == 8)) begin
                  if      (Ctrl_AP_Col_CL8) Col_Cnt[3:3] <= Col_Cnt[3:3] + 1;
                  else if (Ctrl_AP_Col_B16) Col_Cnt[4:3] <= Col_Cnt[4:3] + 1;
                  else if (Ctrl_AP_Col_B32) Col_Cnt[5:3] <= Col_Cnt[5:3] + 1;
                  else if (Ctrl_AP_Col_B64) Col_Cnt[6:3] <= Col_Cnt[6:3] + 1;
               end
               else if ((P_MEM_DATA_WIDTH_SDR == 32) & (C_MEM_BURST_LENGTH == 2)) begin
                  if      (Ctrl_AP_Col_CL4) Col_Cnt[1:1] <= Col_Cnt[1:1] + 1;
                  else if (Ctrl_AP_Col_CL8) Col_Cnt[2:1] <= Col_Cnt[2:1] + 1;
                  else if (Ctrl_AP_Col_B16) Col_Cnt[3:1] <= Col_Cnt[3:1] + 1;
                  else if (Ctrl_AP_Col_B32) Col_Cnt[4:1] <= Col_Cnt[4:1] + 1;
                  else if (Ctrl_AP_Col_B64) Col_Cnt[5:1] <= Col_Cnt[5:1] + 1;
               end
               else if ((P_MEM_DATA_WIDTH_SDR == 32) & (C_MEM_BURST_LENGTH == 4)) begin
                  if      (Ctrl_AP_Col_CL8) Col_Cnt[2:2] <= Col_Cnt[2:2] + 1;
                  else if (Ctrl_AP_Col_B16) Col_Cnt[3:2] <= Col_Cnt[3:2] + 1;
                  else if (Ctrl_AP_Col_B32) Col_Cnt[4:2] <= Col_Cnt[4:2] + 1;
                  else if (Ctrl_AP_Col_B64) Col_Cnt[5:2] <= Col_Cnt[5:2] + 1;
               end
               else if ((P_MEM_DATA_WIDTH_SDR == 32) & (C_MEM_BURST_LENGTH == 8)) begin
                  if      (Ctrl_AP_Col_B16) Col_Cnt[3:3] <= Col_Cnt[3:3] + 1;
                  else if (Ctrl_AP_Col_B32) Col_Cnt[4:3] <= Col_Cnt[4:3] + 1;
                  else if (Ctrl_AP_Col_B64) Col_Cnt[5:3] <= Col_Cnt[5:3] + 1;
               end         
               else if ((P_MEM_DATA_WIDTH_SDR == 64) & (C_MEM_BURST_LENGTH == 2)) begin
                  if      (Ctrl_AP_Col_CL8) Col_Cnt[1:1] <= Col_Cnt[1:1] + 1;
                  else if (Ctrl_AP_Col_B16) Col_Cnt[2:1] <= Col_Cnt[2:1] + 1;
                  else if (Ctrl_AP_Col_B32) Col_Cnt[3:1] <= Col_Cnt[3:1] + 1;
                  else if (Ctrl_AP_Col_B64) Col_Cnt[4:1] <= Col_Cnt[4:1] + 1;
               end
               else if ((P_MEM_DATA_WIDTH_SDR == 64) & (C_MEM_BURST_LENGTH == 4)) begin
                  if      (Ctrl_AP_Col_B16) Col_Cnt[2:2] <= Col_Cnt[2:2] + 1;
                  else if (Ctrl_AP_Col_B32) Col_Cnt[3:2] <= Col_Cnt[3:2] + 1;
                  else if (Ctrl_AP_Col_B64) Col_Cnt[4:2] <= Col_Cnt[4:2] + 1;
               end
               else if ((P_MEM_DATA_WIDTH_SDR == 64) & (C_MEM_BURST_LENGTH == 8)) begin 
                  if      (Ctrl_AP_Col_B32) Col_Cnt[3:3] <= Col_Cnt[3:3] + 1;
                  else if (Ctrl_AP_Col_B64) Col_Cnt[4:3] <= Col_Cnt[4:3] + 1;
               end
               else if ((P_MEM_DATA_WIDTH_SDR == 128) & (C_MEM_BURST_LENGTH == 2)) begin 
                  if      (Ctrl_AP_Col_B16) Col_Cnt[1:1] <= Col_Cnt[1:1] + 1;
                  else if (Ctrl_AP_Col_B32) Col_Cnt[2:1] <= Col_Cnt[2:1] + 1;
                  else if (Ctrl_AP_Col_B64) Col_Cnt[3:1] <= Col_Cnt[3:1] + 1;
               end
               else if ((P_MEM_DATA_WIDTH_SDR == 128) & (C_MEM_BURST_LENGTH == 4)) begin
                  if      (Ctrl_AP_Col_B32) Col_Cnt[2:2] <= Col_Cnt[2:2] + 1;
                  else if (Ctrl_AP_Col_B64) Col_Cnt[3:2] <= Col_Cnt[3:2] + 1;
               end
               else if ((P_MEM_DATA_WIDTH_SDR == 128) & (C_MEM_BURST_LENGTH == 8)) begin 
                  if      (Ctrl_AP_Col_B64) Col_Cnt[3:3] <= Col_Cnt[3:3] + 1;
               end
            end
         end
      end
   endgenerate
   
   

// Wire together column address
   generate
    if (C_MEM_TYPE == "DDR3") begin : ddr3_col
      if (C_MEM_ADDR_WIDTH == 13) begin : col_addr_12
        assign Col_Addr_Full = {Ctrl_AP_OTF_Addr12, Col_Cnt[11], 
                                Ctrl_AP_Precharge_Addr10, Col_Cnt[9:0]};
      end else begin : col_addr
        assign Col_Addr_Full = {Col_Cnt[C_MEM_ADDR_WIDTH-3:11], Ctrl_AP_OTF_Addr12, 
                                Col_Cnt[10], Ctrl_AP_Precharge_Addr10, Col_Cnt[9:0]};
      end
    end 
    else begin : ddr2_and_older_col
      if (C_MEM_ADDR_WIDTH == 11) begin : col_addr_11
        assign Col_Addr_Full = {Ctrl_AP_Precharge_Addr10, Col_Cnt[9:0]};
      end else begin : col_addr
        assign Col_Addr_Full = {Col_Cnt[C_MEM_ADDR_WIDTH-2:10], Ctrl_AP_Precharge_Addr10, Col_Cnt[9:0]};
      end
    end
   endgenerate

   // Row / Column Mux
   assign Row_Col_Mux_Out = Ctrl_AP_Row_Col_Sel ? Row_Addr : Col_Addr_Full;

   
   // Generate for rank bits
   generate
      if (C_MEM_NUM_RANKS == 2) begin : rank_bits
         assign Rank_Addr_Final = {Rank_Addr, ~Rank_Addr};
      end
      else begin : rank_wire
         assign Rank_Addr_Final = 1'b1;
      end
   endgenerate
   

   // Generate for multiple dimms
   generate
      for (i = 0; i < C_MEM_NUM_DIMMS; i = i + 1) begin : dimm_logic
         assign Dimm_Addr_Final[(i+1)*C_MEM_NUM_RANKS-1:i*C_MEM_NUM_RANKS] = Ctrl_AP_Assert_All_CS ? 2'b11 : (DIMM_Addr == i) ? Rank_Addr_Final : 0;
      end
   endgenerate
   
   
   // Mux for mode register values for bank bits
   always @(Bank_Addr) begin
      Bank_Addr_Final <= Bank_Addr;
   end

   
   // Mux for mode register values for address bits
   always @(Row_Col_Mux_Out) begin
      Row_Col_Final <= Row_Col_Mux_Out;
   end


   // Pipeline2 Rank/Dimm Address Register
    
  generate
     if (C_AP_PIPELINE2) begin : pipeline2_ra_reg
       if (C_USE_MIG_S3_PHY) begin : gen_s3
           always @(negedge Clk90)
             if (Rst270) AP_PhyIF_CS <= 0;
             else AP_PhyIF_CS <= Dimm_Addr_Final;
       end
       else begin : gen_normal
           always @(posedge Clk0)
             if (Rst) AP_PhyIF_CS <= 0;
             else AP_PhyIF_CS <= Dimm_Addr_Final;
       end
     end
     else begin : pipeline2_ra_wire
       always @(Dimm_Addr_Final) AP_PhyIF_CS <= Dimm_Addr_Final;
     end
  endgenerate

   assign AP_PhyIF_CS_n = ~AP_PhyIF_CS;
   
   // Pipeline2 Bank Address Register
    generate
      if (C_AP_PIPELINE2) begin : pipeline2_ba_reg
        if (C_USE_MIG_S3_PHY) begin : gen_s3
           always @(negedge Clk90)
             if (Rst270) AP_PhyIF_BankAddr <= 0;
             else AP_PhyIF_BankAddr <= Bank_Addr_Final;
        end
        else begin : gen_normal
           always @(posedge Clk0)
             if (Rst) AP_PhyIF_BankAddr <= 0;
             else AP_PhyIF_BankAddr <= Bank_Addr_Final;
         end
     end
     else begin : pipeline2_ba_wire
        always @(Bank_Addr_Final) AP_PhyIF_BankAddr <= Bank_Addr_Final;
     end
  endgenerate

   // Pipeline2 Address Register
  
   generate
      if (C_AP_PIPELINE2) begin : pipeline2_rc_reg
        if (C_USE_MIG_S3_PHY) begin : gen_s3
           always @(negedge Clk90)
             if (Rst270) AP_PhyIF_Addr <= 0;
             else AP_PhyIF_Addr <= Row_Col_Final;
        end
        else begin : gen_normal
           always @(posedge Clk0)
             if (Rst) AP_PhyIF_Addr <= 0;
             else AP_PhyIF_Addr <= Row_Col_Final;
        end
     end
     else begin : pipeline2_rc_wire
        always @(Row_Col_Final) AP_PhyIF_Addr <= Row_Col_Final;
     end
  endgenerate
 
endmodule
