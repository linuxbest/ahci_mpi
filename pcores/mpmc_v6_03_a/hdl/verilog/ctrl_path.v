//-----------------------------------------------------------------------------
//-- (c) Copyright 2006 - 2010 Xilinx, Inc. All rights reserved.
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
//
// Description: Top level control path.
//   
//--------------------------------------------------------------------------
//
// Structure:
//   mpmc_ctrl_path
//     ctrl_path
//     arbiter
//       arb_acknowledge
//       arb_bram_addr
//       arb_pattern_start
//         arb_req_pending_muxes
//         high_priority_select
//       arb_which_port
//         arb_req_pending_muxes
//         high_priority_select
//       arb_pattern_type
//         arb_pattern_type_muxes
//         arb_pattern_type_fifo
//         high_priority_select
//           mpmc_ctrl_path_fifo (currently used, better for output timing)
//           fifo_4 (not used, better for area)
//             fifo_32_rdcntr
//
//--------------------------------------------------------------------------
// History:
//
//--------------------------------------------------------------------------

`timescale 1ns/1ns
module ctrl_path
  (
   Clk,                   // I
   Rst,                   // I
   Arb_RdModWr,           // I
   Arb_PatternType,       // I [C_ARB_PATTERN_TYPE_WIDTH-1:0]
   Arb_PatternType_Decode,// I [C_ARB_PATTERN_TYPE_DECODE_WIDTH-1:0]
   Arb_PatternStart,      // I
   Ctrl_Idle,             // I
   Ctrl_InitializeMemory, // I
   Ctrl_Stall,            // I
   Ctrl_Complete,         // I
   Ctrl_Skip_Value,       // I
   Ctrl_AP_Col_Cnt_Load,  // I
   Ctrl_Repeat4,          // I
   Periodic_Rd_Req,       // I
   Maint_ZQ_Req,          // I
   Maint_ZQ_WIP,          // I
   Ignore_Complete,       // O
   Ctrl_BRAM_Out,         // O [C_NUM_CTRL_SIGNALS-1:0]
   Assert_All_CS1         // O
   );
   
   parameter C_FAMILY = "virtex4";

   parameter C_IS_DDR = 1'b1;              // Allowed Values: 0,1 

   parameter integer C_INCLUDE_ECC_SUPPORT = 0;
   parameter integer C_SKIP_1_VALUE = 1;
   parameter integer C_SKIP_2_VALUE = 1;
   parameter integer C_SKIP_3_VALUE = 1;
   parameter integer C_SKIP_4_VALUE = 1;
   parameter integer C_SKIP_5_VALUE = 1;   
   parameter integer C_SKIP_6_VALUE = 1;   
   parameter integer C_SKIP_7_VALUE = 1;   
   
   parameter C_ARB_PATTERN_TYPE_WIDTH = 4;  // Allowed Values: 4
   parameter C_ARB_PATTERN_TYPE_DECODE_WIDTH = 16;  // Allowed Values: 16
   parameter C_NUM_CTRL_SIGNALS       = 36; // Allowed Values: 1-36

   parameter C_USE_FIXED_BASEADDR_CTRL = 0;
   parameter C_BASEADDR_CTRL0 = 9'b0_0000_0000;
   parameter C_HIGHADDR_CTRL0 = 9'b0_0001_1111;
   parameter C_BASEADDR_CTRL1 = 9'b0_0010_0000;
   parameter C_HIGHADDR_CTRL1 = 9'b0_0011_1111;
   parameter C_BASEADDR_CTRL2 = 9'b0_0100_0000;
   parameter C_HIGHADDR_CTRL2 = 9'b0_0101_1111;
   parameter C_BASEADDR_CTRL3 = 9'b0_0110_0000;
   parameter C_HIGHADDR_CTRL3 = 9'b0_0111_1111;
   parameter C_BASEADDR_CTRL4 = 9'b0_1000_0000;
   parameter C_HIGHADDR_CTRL4 = 9'b0_1001_1111;
   parameter C_BASEADDR_CTRL5 = 9'b0_1010_0000;
   parameter C_HIGHADDR_CTRL5 = 9'b0_1011_1111;
   parameter C_BASEADDR_CTRL6 = 9'b0_1100_0000;
   parameter C_HIGHADDR_CTRL6 = 9'b0_1101_1111;
   parameter C_BASEADDR_CTRL7 = 9'b0_1110_0000;
   parameter C_HIGHADDR_CTRL7 = 9'b0_1111_1111;
   parameter C_BASEADDR_CTRL8 = 9'b1_0000_0000;
   parameter C_HIGHADDR_CTRL8 = 9'b1_0001_1111;
   parameter C_BASEADDR_CTRL9 = 9'b1_0010_0000;
   parameter C_HIGHADDR_CTRL9 = 9'b1_0011_1111;
   parameter C_BASEADDR_CTRL10 = 9'b1_0100_0000;
   parameter C_HIGHADDR_CTRL10 = 9'b1_0101_1111;
   parameter C_BASEADDR_CTRL11 = 9'b1_0110_0000;
   parameter C_HIGHADDR_CTRL11 = 9'b1_0111_1111;
   parameter C_BASEADDR_CTRL12 = 9'b1_1000_0000;
   parameter C_HIGHADDR_CTRL12 = 9'b1_1001_1111;
   parameter C_BASEADDR_CTRL13 = 9'b1_1010_0000;
   parameter C_HIGHADDR_CTRL13 = 9'b1_1011_1111;
   parameter C_BASEADDR_CTRL14 = 9'b1_1100_0000;
   parameter C_HIGHADDR_CTRL14 = 9'b1_1101_1111;
   parameter C_BASEADDR_CTRL15 = 9'b1_1110_0000;
   parameter C_HIGHADDR_CTRL15 = 9'b1_1111_1111;
   parameter C_BASEADDR_CTRL16 = 9'b1_1110_0000;
   parameter C_HIGHADDR_CTRL16 = 9'b1_1111_1111;

   parameter C_B16_REPEAT_CNT = 0;
   parameter C_B32_REPEAT_CNT = 0;
   parameter C_B64_REPEAT_CNT = 0;
   parameter C_ZQCS_REPEAT_CNT = 0;

   parameter C_WORD_WRITE_SEQ       =  0;
   parameter C_WORD_READ_SEQ        =  1;
   parameter C_DOUBLEWORD_WRITE_SEQ =  2;
   parameter C_DOUBLEWORD_READ_SEQ  =  3;
   parameter C_CL4_WRITE_SEQ        =  4;
   parameter C_CL4_READ_SEQ         =  5;
   parameter C_CL8_WRITE_SEQ        =  6;
   parameter C_CL8_READ_SEQ         =  7;
   parameter C_B16_WRITE_SEQ        =  8;
   parameter C_B16_READ_SEQ         =  9;
   parameter C_B32_WRITE_SEQ        = 10;
   parameter C_B32_READ_SEQ         = 11;
   parameter C_B64_WRITE_SEQ        = 12;
   parameter C_B64_READ_SEQ         = 13;
   parameter C_REFH_SEQ             = 14;
   parameter C_NOP_SEQ              = 15;

   parameter C_CTRL_BRAM_SRVAL    = 36'h0;
   parameter C_CTRL_BRAM_INIT_00  = 256'h0;
   parameter C_CTRL_BRAM_INIT_01  = 256'h0;
   parameter C_CTRL_BRAM_INIT_02  = 256'h0;
   parameter C_CTRL_BRAM_INIT_03  = 256'h0;
   parameter C_CTRL_BRAM_INIT_04  = 256'h0;
   parameter C_CTRL_BRAM_INIT_05  = 256'h0;
   parameter C_CTRL_BRAM_INIT_06  = 256'h0;
   parameter C_CTRL_BRAM_INIT_07  = 256'h0;
   parameter C_CTRL_BRAM_INIT_08  = 256'h0;
   parameter C_CTRL_BRAM_INIT_09  = 256'h0;
   parameter C_CTRL_BRAM_INIT_0A  = 256'h0;
   parameter C_CTRL_BRAM_INIT_0B  = 256'h0;
   parameter C_CTRL_BRAM_INIT_0C  = 256'h0;
   parameter C_CTRL_BRAM_INIT_0D  = 256'h0;
   parameter C_CTRL_BRAM_INIT_0E  = 256'h0;
   parameter C_CTRL_BRAM_INIT_0F  = 256'h0;
   parameter C_CTRL_BRAM_INIT_10  = 256'h0;
   parameter C_CTRL_BRAM_INIT_11  = 256'h0;
   parameter C_CTRL_BRAM_INIT_12  = 256'h0;
   parameter C_CTRL_BRAM_INIT_13  = 256'h0;
   parameter C_CTRL_BRAM_INIT_14  = 256'h0;
   parameter C_CTRL_BRAM_INIT_15  = 256'h0;
   parameter C_CTRL_BRAM_INIT_16  = 256'h0;
   parameter C_CTRL_BRAM_INIT_17  = 256'h0;
   parameter C_CTRL_BRAM_INIT_18  = 256'h0;
   parameter C_CTRL_BRAM_INIT_19  = 256'h0;
   parameter C_CTRL_BRAM_INIT_1A  = 256'h0;
   parameter C_CTRL_BRAM_INIT_1B  = 256'h0;
   parameter C_CTRL_BRAM_INIT_1C  = 256'h0;
   parameter C_CTRL_BRAM_INIT_1D  = 256'h0;
   parameter C_CTRL_BRAM_INIT_1E  = 256'h0;
   parameter C_CTRL_BRAM_INIT_1F  = 256'h0;
   parameter C_CTRL_BRAM_INIT_20  = 256'h0;
   parameter C_CTRL_BRAM_INIT_21  = 256'h0;
   parameter C_CTRL_BRAM_INIT_22  = 256'h0;
   parameter C_CTRL_BRAM_INIT_23  = 256'h0;
   parameter C_CTRL_BRAM_INIT_24  = 256'h0;
   parameter C_CTRL_BRAM_INIT_25  = 256'h0;
   parameter C_CTRL_BRAM_INIT_26  = 256'h0;
   parameter C_CTRL_BRAM_INIT_27  = 256'h0;
   parameter C_CTRL_BRAM_INIT_28  = 256'h0;
   parameter C_CTRL_BRAM_INIT_29  = 256'h0;
   parameter C_CTRL_BRAM_INIT_2A  = 256'h0;
   parameter C_CTRL_BRAM_INIT_2B  = 256'h0;
   parameter C_CTRL_BRAM_INIT_2C  = 256'h0;
   parameter C_CTRL_BRAM_INIT_2D  = 256'h0;
   parameter C_CTRL_BRAM_INIT_2E  = 256'h0;
   parameter C_CTRL_BRAM_INIT_2F  = 256'h0;
   parameter C_CTRL_BRAM_INIT_30  = 256'h0;
   parameter C_CTRL_BRAM_INIT_31  = 256'h0;
   parameter C_CTRL_BRAM_INIT_32  = 256'h0;
   parameter C_CTRL_BRAM_INIT_33  = 256'h0;
   parameter C_CTRL_BRAM_INIT_34  = 256'h0;
   parameter C_CTRL_BRAM_INIT_35  = 256'h0;
   parameter C_CTRL_BRAM_INIT_36  = 256'h0;
   parameter C_CTRL_BRAM_INIT_37  = 256'h0;
   parameter C_CTRL_BRAM_INIT_38  = 256'h0;
   parameter C_CTRL_BRAM_INIT_39  = 256'h0;
   parameter C_CTRL_BRAM_INIT_3A  = 256'h0;
   parameter C_CTRL_BRAM_INIT_3B  = 256'h0;
   parameter C_CTRL_BRAM_INIT_3C  = 256'h0;
   parameter C_CTRL_BRAM_INIT_3D  = 256'h0;
   parameter C_CTRL_BRAM_INIT_3E  = 256'h0;
   parameter C_CTRL_BRAM_INIT_3F  = 256'h0;
   parameter C_CTRL_BRAM_INITP_00 = 256'h0;
   parameter C_CTRL_BRAM_INITP_01 = 256'h0;
   parameter C_CTRL_BRAM_INITP_02 = 256'h0;
   parameter C_CTRL_BRAM_INITP_03 = 256'h0;
   parameter C_CTRL_BRAM_INITP_04 = 256'h0;
   parameter C_CTRL_BRAM_INITP_05 = 256'h0;
   parameter C_CTRL_BRAM_INITP_06 = 256'h0;
   parameter C_CTRL_BRAM_INITP_07 = 256'h0;

   parameter C_CTRL_Q0_DELAY  = 0;
   parameter C_CTRL_Q1_DELAY  = 0;
   parameter C_CTRL_Q2_DELAY  = 0;
   parameter C_CTRL_Q3_DELAY  = 0;
   parameter C_CTRL_Q4_DELAY  = 0;
   parameter C_CTRL_Q5_DELAY  = 0;
   parameter C_CTRL_Q6_DELAY  = 0;
   parameter C_CTRL_Q7_DELAY  = 0;
   parameter C_CTRL_Q8_DELAY  = 0;
   parameter C_CTRL_Q9_DELAY  = 0;
   parameter C_CTRL_Q10_DELAY = 0;
   parameter C_CTRL_Q11_DELAY = 0;
   parameter C_CTRL_Q12_DELAY = 0;
   parameter C_CTRL_Q13_DELAY = 0;
   parameter C_CTRL_Q14_DELAY = 0;
   parameter C_CTRL_Q15_DELAY = 0;
   parameter C_CTRL_Q16_DELAY = 0;
   parameter C_CTRL_Q17_DELAY = 0;
   parameter C_CTRL_Q18_DELAY = 0;
   parameter C_CTRL_Q19_DELAY = 0;
   parameter C_CTRL_Q20_DELAY = 0;
   parameter C_CTRL_Q21_DELAY = 0;
   parameter C_CTRL_Q22_DELAY = 0;
   parameter C_CTRL_Q23_DELAY = 0;
   parameter C_CTRL_Q24_DELAY = 0;
   parameter C_CTRL_Q25_DELAY = 0;
   parameter C_CTRL_Q26_DELAY = 0;
   parameter C_CTRL_Q27_DELAY = 0;
   parameter C_CTRL_Q28_DELAY = 0;
   parameter C_CTRL_Q29_DELAY = 0;
   parameter C_CTRL_Q30_DELAY = 0;
   parameter C_CTRL_Q31_DELAY = 0;
   parameter C_CTRL_Q32_DELAY = 0;
   parameter C_CTRL_Q33_DELAY = 0;
   parameter C_CTRL_Q34_DELAY = 0;
   parameter C_CTRL_Q35_DELAY = 0;
   parameter C_CTRL_IS_WRITE_INDEX = 4'h0;
   parameter C_MEM_TYPE         = "DDR3";
   
   input                                Clk;
   input                                Rst;
   input                                Arb_RdModWr;
   input [C_ARB_PATTERN_TYPE_WIDTH-1:0] Arb_PatternType;
   input [C_ARB_PATTERN_TYPE_DECODE_WIDTH-1:0] Arb_PatternType_Decode;
   input                                Arb_PatternStart;
   input                                Ctrl_Idle;
   input                                Ctrl_InitializeMemory;
   input                                Ctrl_Stall;
   input                                Ctrl_Complete;
   input [2:0]                          Ctrl_Skip_Value;
   input                                Ctrl_AP_Col_Cnt_Load;
   input                                Ctrl_Repeat4;
   input                                Periodic_Rd_Req;
   input                                Maint_ZQ_Req;
   input                                Maint_ZQ_WIP;
   output                               Ignore_Complete;
   output [C_NUM_CTRL_SIGNALS-1:0]      Ctrl_BRAM_Out;
   output                               Assert_All_CS1;

   reg                                  Ignore_Complete;

   reg  [8:0]                           ctrl_addr_cntr_d = 0;
   wire                                 ctrl_addr_cntr_ld;
   wire                                 ctrl_addr_cntr_inc;
   reg [8:0]                            ctrl_bram_addr = 0;
   wire [35:0]                          ctrl_bram_dataout;
   reg                                  ctrl_complete_d1 = 0;
   reg                                  ctrl_complete_d2 = 0;
   reg                                  ctrl_complete_d3 = 0;
   reg                                  ctrl_idle_d1 = 0;
   reg                                  Assert_All_CS_i0 = 0;
   reg [7:0]                            repeat_cntr = 0;
   reg                                  repeat_cmp = 0;
   
   genvar i;

   localparam            P_DLY_WIDTH = 5;
   localparam [((P_DLY_WIDTH*36)-1):0] ctrl_srl16_addr = 
                          {C_CTRL_Q35_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q34_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q33_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q32_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q31_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q30_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q29_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q28_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q27_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q26_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q25_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q24_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q23_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q22_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q21_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q20_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q19_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q18_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q17_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q16_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q15_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q14_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q13_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q12_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q11_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q10_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q9_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q8_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q7_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q6_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q5_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q4_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q3_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q2_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q1_DELAY[(P_DLY_WIDTH-1):0],
                           C_CTRL_Q0_DELAY[(P_DLY_WIDTH-1):0]};

   always @(posedge Clk)
     begin
        ctrl_complete_d1 <= Ctrl_Complete;
        ctrl_complete_d2 <= ctrl_complete_d1;
        ctrl_complete_d3 <= ctrl_complete_d2;
        ctrl_idle_d1 <= Ctrl_Idle;
     end

   // Calculate BRAM address
   assign ctrl_addr_cntr_ld = ctrl_idle_d1 | Arb_PatternStart | ctrl_complete_d3;

   assign ctrl_addr_cntr_inc = ~Ctrl_Stall & (~Ctrl_Idle | ctrl_complete_d2);

   always @(Arb_PatternType) begin
      case (Arb_PatternType)
        0: ctrl_addr_cntr_d <= C_BASEADDR_CTRL0;
        1: ctrl_addr_cntr_d <= C_BASEADDR_CTRL1;
        2: ctrl_addr_cntr_d <= C_BASEADDR_CTRL2;
        3: ctrl_addr_cntr_d <= C_BASEADDR_CTRL3;
        4: ctrl_addr_cntr_d <= C_BASEADDR_CTRL4;
        5: ctrl_addr_cntr_d <= C_BASEADDR_CTRL5;
        6: ctrl_addr_cntr_d <= C_BASEADDR_CTRL6;
        7: ctrl_addr_cntr_d <= C_BASEADDR_CTRL7;
        8: ctrl_addr_cntr_d <= C_BASEADDR_CTRL8;
        9: ctrl_addr_cntr_d <= C_BASEADDR_CTRL9;
        10: ctrl_addr_cntr_d <= C_BASEADDR_CTRL10;
        11: ctrl_addr_cntr_d <= C_BASEADDR_CTRL11;
        12: ctrl_addr_cntr_d <= C_BASEADDR_CTRL12;
        13: ctrl_addr_cntr_d <= C_BASEADDR_CTRL13;
        14: ctrl_addr_cntr_d <= C_BASEADDR_CTRL14;
        15: ctrl_addr_cntr_d <= C_BASEADDR_CTRL15;
      endcase
   end

   always @(posedge Clk) begin
      if (Rst |  Ctrl_AP_Col_Cnt_Load)
        repeat_cntr <= 0;
      else if (Ctrl_Repeat4)
        repeat_cntr <= repeat_cntr + 1'd1;
   end
   
   generate
      if (C_IS_DDR == 1'b0 && C_INCLUDE_ECC_SUPPORT == 1'b1)
        begin : gen_sdram_ecc_repeat_cmp
           always @(posedge Clk) begin
             repeat_cmp <= (Ctrl_Repeat4 && 
                            (((repeat_cntr < C_B16_REPEAT_CNT) && 
                              ((Arb_PatternType_Decode[C_B16_WRITE_SEQ]) ||
                               (Arb_PatternType_Decode[C_B16_READ_SEQ]))) ||
                             ((repeat_cntr < C_B32_REPEAT_CNT) && 
                              ((Arb_PatternType_Decode[C_B32_WRITE_SEQ]) ||
                               (Arb_PatternType_Decode[C_B32_READ_SEQ]))) ||
                             ((repeat_cntr < C_B64_REPEAT_CNT) && 
                              ((Arb_PatternType_Decode[C_B64_WRITE_SEQ]) ||
                               (Arb_PatternType_Decode[C_B64_READ_SEQ])))));
           end   
        end
      else if (C_MEM_TYPE == "DDR3") 
        begin : gen_repeat_cmp_zqcs
           always @(posedge Clk) begin
             repeat_cmp <= (Ctrl_Repeat4 
                            && (repeat_cntr < C_ZQCS_REPEAT_CNT) 
                            && Arb_PatternType_Decode[C_REFH_SEQ]) 
                           && Maint_ZQ_WIP;
           end
        end
      else
        begin : gen_repeat_cmp
           always @(posedge Clk) begin
             repeat_cmp <= (Ctrl_Repeat4 && 
                            (((repeat_cntr < C_B32_REPEAT_CNT) && 
                              ((Arb_PatternType_Decode[C_B32_WRITE_SEQ]) ||
                               (Arb_PatternType_Decode[C_B32_READ_SEQ]))) ||
                             ((repeat_cntr < C_B64_REPEAT_CNT) && 
                              ((Arb_PatternType_Decode[C_B64_WRITE_SEQ]) ||
                               (Arb_PatternType_Decode[C_B64_READ_SEQ])))));
           end
        end
   endgenerate
 
   generate
       if (C_IS_DDR == 1'b0 && C_INCLUDE_ECC_SUPPORT == 1'b1)
         begin : gen_sdram_ecc_ignore_cmp
           always @(posedge Clk) begin
              if (Rst)
                Ignore_Complete = 1'b0;
              else
                Ignore_Complete = 
                    ((((repeat_cntr <= C_B16_REPEAT_CNT) && 
                       ((Arb_PatternType_Decode[C_B16_WRITE_SEQ]) ||
                        (Arb_PatternType_Decode[C_B16_READ_SEQ]))) ||
                      ((repeat_cntr <= C_B32_REPEAT_CNT) && 
                       ((Arb_PatternType_Decode[C_B32_WRITE_SEQ]) ||
                        (Arb_PatternType_Decode[C_B32_READ_SEQ]))) ||
                      ((repeat_cntr <= C_B64_REPEAT_CNT) && 
                       ((Arb_PatternType_Decode[C_B64_WRITE_SEQ]) ||
                        (Arb_PatternType_Decode[C_B64_READ_SEQ])))));
           end
         end
      else if (C_MEM_TYPE == "DDR3") 
        begin : gen_ignore_cmp_zqcs
           always @(posedge Clk) begin
              if (Rst)
                Ignore_Complete = 1'b0;
              else
                Ignore_Complete = 
                    (repeat_cntr <= C_ZQCS_REPEAT_CNT) && (C_ZQCS_REPEAT_CNT !=0) 
                        && Arb_PatternType_Decode[C_REFH_SEQ]
                        && Maint_ZQ_WIP;
           end
        end
       else
         begin : gen_ignore_cmp
           always @(posedge Clk) begin
              if (Rst)
                Ignore_Complete = 1'b0;
              else
                Ignore_Complete = 
                    ((((repeat_cntr <= C_B32_REPEAT_CNT) && C_B32_REPEAT_CNT !=0 &&
                       ((Arb_PatternType_Decode[C_B32_WRITE_SEQ]) ||
                        (Arb_PatternType_Decode[C_B32_READ_SEQ]))) ||
                      ((repeat_cntr <= C_B64_REPEAT_CNT) && C_B64_REPEAT_CNT !=0 &&
                       ((Arb_PatternType_Decode[C_B64_WRITE_SEQ]) ||
                        (Arb_PatternType_Decode[C_B64_READ_SEQ])))));
           end
         end
   endgenerate

   generate
      if (C_INCLUDE_ECC_SUPPORT == 0)
        begin : gen_ctrl_bram_addr_noecc
           always @(posedge Clk) begin
              if (Rst)
                ctrl_bram_addr <= C_BASEADDR_CTRL15;
              else if (ctrl_addr_cntr_ld)
                ctrl_bram_addr <= Periodic_Rd_Req & Arb_PatternStart & Arb_PatternType_Decode[C_REFH_SEQ] ? C_BASEADDR_CTRL1 : 
                                  Maint_ZQ_Req & Arb_PatternStart & Arb_PatternType_Decode[C_REFH_SEQ]? C_BASEADDR_CTRL16 : 
                                  ctrl_addr_cntr_d;
              else if (repeat_cmp)
                ctrl_bram_addr <= ctrl_bram_addr - 2'd3;
              else if (ctrl_addr_cntr_inc)
                ctrl_bram_addr <= ctrl_bram_addr + 1'd1;
              else
                ctrl_bram_addr <= ctrl_bram_addr;
           end
        end
      else
        begin : gen_ctrl_bram_addr_ecc
           wire [2:0] ctrl_skip_value_tmp/* synthesis syn_keep=1 */;
           assign ctrl_skip_value_tmp = Ctrl_Skip_Value & {3{~Arb_RdModWr}};
           always @(posedge Clk) begin
              if (Rst)
                ctrl_bram_addr <= C_BASEADDR_CTRL15;
              else if (ctrl_addr_cntr_ld)
                ctrl_bram_addr <= Periodic_Rd_Req & Arb_PatternStart & Arb_PatternType_Decode[C_REFH_SEQ] ? C_BASEADDR_CTRL1 : 
                                  Maint_ZQ_Req & Arb_PatternStart & Arb_PatternType_Decode[C_REFH_SEQ] ? C_BASEADDR_CTRL16 : 
                                  ctrl_addr_cntr_d;
              else if (repeat_cmp)
                ctrl_bram_addr <= ctrl_bram_addr - 3;
              else if (ctrl_addr_cntr_inc)
                case (ctrl_skip_value_tmp)
                  1: ctrl_bram_addr <= ctrl_bram_addr + C_SKIP_1_VALUE;
                  2: ctrl_bram_addr <= ctrl_bram_addr + C_SKIP_2_VALUE;
                  3: ctrl_bram_addr <= ctrl_bram_addr + C_SKIP_3_VALUE;
                  4: ctrl_bram_addr <= ctrl_bram_addr + C_SKIP_4_VALUE;
                  5: ctrl_bram_addr <= ctrl_bram_addr + C_SKIP_5_VALUE;
                  6: ctrl_bram_addr <= ctrl_bram_addr + C_SKIP_6_VALUE;
                  7: ctrl_bram_addr <= ctrl_bram_addr + C_SKIP_7_VALUE;
                  default: ctrl_bram_addr <= ctrl_bram_addr + 1;
                endcase
              else
                ctrl_bram_addr <= ctrl_bram_addr;
           end
        end
   endgenerate


   // Instantiate BRAM
   RAMB16_S36
   #(
    .SRVAL        (C_CTRL_BRAM_SRVAL),
    .INIT_00      (C_CTRL_BRAM_INIT_00),
    .INIT_01      (C_CTRL_BRAM_INIT_01),
    .INIT_02      (C_CTRL_BRAM_INIT_02),
    .INIT_03      (C_CTRL_BRAM_INIT_03),
    .INIT_04      (C_CTRL_BRAM_INIT_04),
    .INIT_05      (C_CTRL_BRAM_INIT_05),
    .INIT_06      (C_CTRL_BRAM_INIT_06),
    .INIT_07      (C_CTRL_BRAM_INIT_07),
    .INIT_08      (C_CTRL_BRAM_INIT_08),
    .INIT_09      (C_CTRL_BRAM_INIT_09),
    .INIT_0A      (C_CTRL_BRAM_INIT_0A),
    .INIT_0B      (C_CTRL_BRAM_INIT_0B),
    .INIT_0C      (C_CTRL_BRAM_INIT_0C),
    .INIT_0D      (C_CTRL_BRAM_INIT_0D),
    .INIT_0E      (C_CTRL_BRAM_INIT_0E),
    .INIT_0F      (C_CTRL_BRAM_INIT_0F),
    .INIT_10      (C_CTRL_BRAM_INIT_10),
    .INIT_11      (C_CTRL_BRAM_INIT_11),
    .INIT_12      (C_CTRL_BRAM_INIT_12),
    .INIT_13      (C_CTRL_BRAM_INIT_13),
    .INIT_14      (C_CTRL_BRAM_INIT_14),
    .INIT_15      (C_CTRL_BRAM_INIT_15),
    .INIT_16      (C_CTRL_BRAM_INIT_16),
    .INIT_17      (C_CTRL_BRAM_INIT_17),
    .INIT_18      (C_CTRL_BRAM_INIT_18),
    .INIT_19      (C_CTRL_BRAM_INIT_19),
    .INIT_1A      (C_CTRL_BRAM_INIT_1A),
    .INIT_1B      (C_CTRL_BRAM_INIT_1B),
    .INIT_1C      (C_CTRL_BRAM_INIT_1C),
    .INIT_1D      (C_CTRL_BRAM_INIT_1D),
    .INIT_1E      (C_CTRL_BRAM_INIT_1E),
    .INIT_1F      (C_CTRL_BRAM_INIT_1F),
    .INIT_20      (C_CTRL_BRAM_INIT_20),
    .INIT_21      (C_CTRL_BRAM_INIT_21),
    .INIT_22      (C_CTRL_BRAM_INIT_22),
    .INIT_23      (C_CTRL_BRAM_INIT_23),
    .INIT_24      (C_CTRL_BRAM_INIT_24),
    .INIT_25      (C_CTRL_BRAM_INIT_25),
    .INIT_26      (C_CTRL_BRAM_INIT_26),
    .INIT_27      (C_CTRL_BRAM_INIT_27),
    .INIT_28      (C_CTRL_BRAM_INIT_28),
    .INIT_29      (C_CTRL_BRAM_INIT_29),
    .INIT_2A      (C_CTRL_BRAM_INIT_2A),
    .INIT_2B      (C_CTRL_BRAM_INIT_2B),
    .INIT_2C      (C_CTRL_BRAM_INIT_2C),
    .INIT_2D      (C_CTRL_BRAM_INIT_2D),
    .INIT_2E      (C_CTRL_BRAM_INIT_2E),
    .INIT_2F      (C_CTRL_BRAM_INIT_2F),
    .INIT_30      (C_CTRL_BRAM_INIT_30),
    .INIT_31      (C_CTRL_BRAM_INIT_31),
    .INIT_32      (C_CTRL_BRAM_INIT_32),
    .INIT_33      (C_CTRL_BRAM_INIT_33),
    .INIT_34      (C_CTRL_BRAM_INIT_34),
    .INIT_35      (C_CTRL_BRAM_INIT_35),
    .INIT_36      (C_CTRL_BRAM_INIT_36),
    .INIT_37      (C_CTRL_BRAM_INIT_37),
    .INIT_38      (C_CTRL_BRAM_INIT_38),
    .INIT_39      (C_CTRL_BRAM_INIT_39),
    .INIT_3A      (C_CTRL_BRAM_INIT_3A),
    .INIT_3B      (C_CTRL_BRAM_INIT_3B),
    .INIT_3C      (C_CTRL_BRAM_INIT_3C),
    .INIT_3D      (C_CTRL_BRAM_INIT_3D),
    .INIT_3E      (C_CTRL_BRAM_INIT_3E),
    .INIT_3F      (C_CTRL_BRAM_INIT_3F),
    .INITP_00     (C_CTRL_BRAM_INITP_00),
    .INITP_01     (C_CTRL_BRAM_INITP_01),
    .INITP_02     (C_CTRL_BRAM_INITP_02),
    .INITP_03     (C_CTRL_BRAM_INITP_03),
    .INITP_04     (C_CTRL_BRAM_INITP_04),
    .INITP_05     (C_CTRL_BRAM_INITP_05),
    .INITP_06     (C_CTRL_BRAM_INITP_06),
    .INITP_07     (C_CTRL_BRAM_INITP_07)
   )
   CTRL_BRAM_0
   (
     .CLK  (Clk),                      // I
     .ADDR (ctrl_bram_addr),           // I
     .WE   (1'b0),                     // I
     .EN   (1'b1),                     // I
     .SSR  (1'b0),                     // I
     .DI   (32'h0),                    // I
     .DIP  (4'h0),                     // I
     .DO   (ctrl_bram_dataout[31:0]),  // O
     .DOP  (ctrl_bram_dataout[35:32])  // O
   );

   
    generate
      for (i=0;i<36;i=i+1) begin : instantiate_SRLs
         mpmc_srl_delay
           #(
             .C_DELAY (ctrl_srl16_addr[P_DLY_WIDTH*i +: P_DLY_WIDTH])
             )
             mpmc_srl_delay_ctrl_bram_out
               (
                .Clk  (Clk),
                .Data (ctrl_bram_dataout[i]),
                .Q    (Ctrl_BRAM_Out[i])
                );
      end
   endgenerate
       
   always @(posedge Clk)
     begin
       Assert_All_CS_i0 <= ((ctrl_bram_addr >= C_BASEADDR_CTRL14) && (ctrl_bram_addr <= C_HIGHADDR_CTRL14));
     end
   mpmc_srl_delay
     #(
       .C_DELAY (ctrl_srl16_addr[(P_DLY_WIDTH*C_CTRL_IS_WRITE_INDEX) +: P_DLY_WIDTH])
       )
       mpmc_srl_delay_ctrl_bram_out
         (
          .Clk  (Clk),
          .Data (Assert_All_CS_i0),
          .Q    (Assert_All_CS1)
          );
   
endmodule // ctrl_path


