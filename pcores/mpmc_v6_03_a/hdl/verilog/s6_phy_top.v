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

module s6_phy_top
#(
  parameter C_MEM_TYPE                  = "INVALID",
  parameter C_PORT_CONFIG                 = 1,
  parameter C_MEM_PART_NUM_COL_BITS       = 0,
  parameter C_ARB0_NUM_SLOTS              = 0,
  parameter C_MEM_ADDR_ORDER              = "BANK_ROW_COLUMN",
  parameter C_MEM_CALIBRATION_MODE        = 1,
  parameter C_MEM_CALIBRATION_DELAY       = "QUARTER",
  parameter C_MEM_CALIBRATION_SOFT_IP     = "TRUE",
  parameter C_MEM_SKIP_IN_TERM_CAL        = 1'b0,
  parameter C_MEM_SKIP_DYNAMIC_CAL        = 1'b0,
  parameter C_MEM_SKIP_DYN_IN_TERM        = 1'b1,
  parameter C_MEM_CALIBRATION_BYPASS      = "NO",
  parameter C_SIMULATION                  = "FALSE",
  parameter C_MCB_DRP_CLK_PRESENT         = 0,
  parameter C_MEM_TZQINIT_MAXCNT          = 10'h200,
  parameter C_MPMC_CLK_MEM_2X_PERIOD_PS   = 1,
  parameter C_NUM_PORTS                 = 8,        // Allowed Values: 1-8
  parameter C_MEM_PA_SR                 = "FULL",
  parameter C_MEM_CAS_WR_LATENCY        = 5,
  parameter C_MEM_AUTO_SR               = "ENABLED",
  parameter C_MEM_HIGH_TEMP_SR          = "NORMAL",
  parameter C_MEM_DYNAMIC_WRITE_ODT     = "OFF",
  parameter C_MEM_CAS_LATENCY0          = 2,        // Allowed Values: integer
  parameter C_MEM_BURST_LENGTH          = 8,        // Allowed Values: 2,4,8
  parameter C_MEM_ODT_TYPE              = 0,
  parameter C_MEM_REDUCED_DRV           = 0,
  parameter C_MEM_PART_TRAS             = 0,
  parameter C_MEM_PART_TRCD             = 0,
  parameter C_MEM_PART_TREFI            = 0,
  parameter C_MEM_PART_TWR              = 0,
  parameter C_MEM_PART_TRP              = 0,
  parameter C_MEM_PART_TRFC             = 0,
  parameter C_MEM_PART_TWTR             = 0,
  parameter C_MEM_PART_TRTP             = 0,
  parameter C_MEM_DQSN_ENABLE           = 1,
  parameter C_MEM_ADDR_WIDTH            = 13,       // Allowed Values: 12-16
  parameter C_MEM_BANKADDR_WIDTH        = 2,        // Allowed Values: 2,3
  parameter C_MEM_DATA_WIDTH            = 32,       // Allowed Values: 32,64
  parameter C_PIX_ADDR_WIDTH_MAX        = 32,
  parameter C_PIX_DATA_WIDTH_MAX        = 64,
  parameter C_PI_DATA_WIDTH             = 8'hFF,
  parameter C_PIX_BE_WIDTH_MAX          = 8,
  parameter C_PIX_RDWDADDR_WIDTH_MAX    = 4,

  parameter C_ARB0_ALGO               = "ROUND_ROBIN",
  parameter C_ARB_BRAM_INIT_00        = 256'h0,

  // Port Parameters
  parameter C_PIM0_BASETYPE           = 0,
  parameter C_PI0_ADDR_WIDTH          = 32,      // Allowed Values: 32
  parameter C_PI0_DATA_WIDTH          = 64,      // Allowed Values: 64
  parameter C_PI0_BE_WIDTH            = C_PI0_DATA_WIDTH/8,
  parameter C_PI0_RDWDADDR_WIDTH      = 4,       // Allowed Values: 4,5
  parameter C_PIM1_BASETYPE           = 0,
  parameter C_PI1_ADDR_WIDTH        = 32,      // Allowed Values: 32
  parameter C_PI1_DATA_WIDTH        = 64,      // Allowed Values: 64
  parameter C_PI1_BE_WIDTH          = C_PI1_DATA_WIDTH/8,
  parameter C_PI1_RDWDADDR_WIDTH    = 4,       // Allowed Values: 4,5
  parameter C_PIM2_BASETYPE           = 0,
  parameter C_PI2_ADDR_WIDTH        = 32,      // Allowed Values: 32
  parameter C_PI2_DATA_WIDTH        = 64,      // Allowed Values: 64
  parameter C_PI2_BE_WIDTH          = C_PI2_DATA_WIDTH/8,
  parameter C_PI2_RDWDADDR_WIDTH    = 4,       // Allowed Values: 4,5
  parameter C_PIM3_BASETYPE           = 0,
  parameter C_PI3_ADDR_WIDTH        = 32,      // Allowed Values: 32
  parameter C_PI3_DATA_WIDTH        = 64,      // Allowed Values: 64
  parameter C_PI3_BE_WIDTH          = C_PI3_DATA_WIDTH/8,
  parameter C_PI3_RDWDADDR_WIDTH    = 4,       // Allowed Values: 4,5
  parameter C_PIM4_BASETYPE           = 0,
  parameter C_PI4_ADDR_WIDTH        = 32,      // Allowed Values: 32
  parameter C_PI4_DATA_WIDTH        = 64,      // Allowed Values: 64
  parameter C_PI4_BE_WIDTH          = C_PI4_DATA_WIDTH/8,
  parameter C_PI4_RDWDADDR_WIDTH    = 4,       // Allowed Values: 4,5
  parameter C_PIM5_BASETYPE           = 0,
  parameter C_PI5_ADDR_WIDTH        = 32,      // Allowed Values: 32
  parameter C_PI5_DATA_WIDTH        = 64,      // Allowed Values: 64
  parameter C_PI5_BE_WIDTH          = C_PI5_DATA_WIDTH/8,
  parameter C_PI5_RDWDADDR_WIDTH    = 4,       // Allowed Values: 4,5
  parameter C_PI6_ADDR_WIDTH        = 32,      // Allowed Values: 32
  parameter C_PI6_DATA_WIDTH        = 64,      // Allowed Values: 64
  parameter C_PI6_BE_WIDTH          = C_PI6_DATA_WIDTH/8,
  parameter C_PI6_RDWDADDR_WIDTH    = 4,       // Allowed Values: 4,5
  parameter C_PI7_ADDR_WIDTH        = 32,      // Allowed Values: 32
  parameter C_PI7_DATA_WIDTH        = 64,      // Allowed Values: 64
  parameter C_PI7_BE_WIDTH          = C_PI7_DATA_WIDTH/8,
  parameter C_PI7_RDWDADDR_WIDTH    = 4,       // Allowed Values: 4,5
  parameter C_MCB_LDQSP_TAP_DELAY_VAL  = 0,  // 0 to 255 inclusive
  parameter C_MCB_UDQSP_TAP_DELAY_VAL  = 0,  // 0 to 255 inclusive
  parameter C_MCB_LDQSN_TAP_DELAY_VAL  = 0,  // 0 to 255 inclusive
  parameter C_MCB_UDQSN_TAP_DELAY_VAL  = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ0_TAP_DELAY_VAL    = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ1_TAP_DELAY_VAL    = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ2_TAP_DELAY_VAL    = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ3_TAP_DELAY_VAL    = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ4_TAP_DELAY_VAL    = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ5_TAP_DELAY_VAL    = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ6_TAP_DELAY_VAL    = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ7_TAP_DELAY_VAL    = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ8_TAP_DELAY_VAL    = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ9_TAP_DELAY_VAL    = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ10_TAP_DELAY_VAL   = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ11_TAP_DELAY_VAL   = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ12_TAP_DELAY_VAL   = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ13_TAP_DELAY_VAL   = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ14_TAP_DELAY_VAL   = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ15_TAP_DELAY_VAL   = 0  // 0 to 255 inclusive
)
(
  // System Signals
  input  wire                                   Clk0,
  input  wire                                   MCB_DRP_Clk,
  input  wire                                   sysclk_2x,
  input  wire                                   sysclk_2x_180,
  input  wire                                   pll_ce_0,
  input  wire                                   pll_ce_90,
  input  wire                                   pll_lock,
  input  wire                                   Rst,
  output wire                                   mcbx_InitDone,
  
  // Spartan6
  output wire [C_MEM_ADDR_WIDTH-1:0]            mcbx_dram_addr,
  output wire [C_MEM_BANKADDR_WIDTH-1:0]        mcbx_dram_ba,
  output wire                                   mcbx_dram_ras_n,
  output wire                                   mcbx_dram_cas_n,
  output wire                                   mcbx_dram_we_n,
                                  
  output wire                                   mcbx_dram_cke,
  output wire                                   mcbx_dram_clk,
  output wire                                   mcbx_dram_clk_n,
  inout  wire [C_MEM_DATA_WIDTH-1:0]            mcbx_dram_dq,
  inout  wire                                   mcbx_dram_dqs,
  inout  wire                                   mcbx_dram_dqs_n,
  inout  wire                                   mcbx_dram_udqs,
  inout  wire                                   mcbx_dram_udqs_n,
  
  output wire                                   mcbx_dram_udm,
  output wire                                   mcbx_dram_ldm,
  output wire                                   mcbx_dram_odt,
  output wire                                   mcbx_dram_ddr3_rst,
  
  // Spartan6 Calibration signals
  input  wire                                   selfrefresh_enter,
  output wire                                   selfrefresh_mode,
  input  wire                                   calib_recal,
  inout  wire                                   rzq,
  inout  wire                                   zio,
  
  // Native MCB ports.
  input  wire                                   MCB0_cmd_clk,
  input  wire                                   MCB0_cmd_en,
  input  wire [2:0]                             MCB0_cmd_instr,
  input  wire [5:0]                             MCB0_cmd_bl,
  input  wire [29:0]                            MCB0_cmd_byte_addr,
  output wire                                   MCB0_cmd_empty,
  output wire                                   MCB0_cmd_full,
  input  wire                                   MCB0_wr_clk,
  input  wire                                   MCB0_wr_en,
  input  wire [C_PI0_DATA_WIDTH/8-1:0]          MCB0_wr_mask,
  input  wire [C_PI0_DATA_WIDTH-1:0]            MCB0_wr_data,
  output wire                                   MCB0_wr_full,
  output wire                                   MCB0_wr_empty,
  output wire [6:0]                             MCB0_wr_count,
  output wire                                   MCB0_wr_underrun,
  output wire                                   MCB0_wr_error,
  input  wire                                   MCB0_rd_clk,
  input  wire                                   MCB0_rd_en,
  output wire [C_PI0_DATA_WIDTH-1:0]            MCB0_rd_data,
  output wire                                   MCB0_rd_full,
  output wire                                   MCB0_rd_empty,
  output wire [6:0]                             MCB0_rd_count,
  output wire                                   MCB0_rd_overflow,
  output wire                                   MCB0_rd_error,
  input  wire                                   MCB1_cmd_clk,
  input  wire                                   MCB1_cmd_en,
  input  wire [2:0]                             MCB1_cmd_instr,
  input  wire [5:0]                             MCB1_cmd_bl,
  input  wire [29:0]                            MCB1_cmd_byte_addr,
  output wire                                   MCB1_cmd_empty,
  output wire                                   MCB1_cmd_full,
  input  wire                                   MCB1_wr_clk,
  input  wire                                   MCB1_wr_en,
  input  wire [C_PI1_DATA_WIDTH/8-1:0]          MCB1_wr_mask,
  input  wire [C_PI1_DATA_WIDTH-1:0]            MCB1_wr_data,
  output wire                                   MCB1_wr_full,
  output wire                                   MCB1_wr_empty,
  output wire [6:0]                             MCB1_wr_count,
  output wire                                   MCB1_wr_underrun,
  output wire                                   MCB1_wr_error,
  input  wire                                   MCB1_rd_clk,
  input  wire                                   MCB1_rd_en,
  output wire [C_PI1_DATA_WIDTH-1:0]            MCB1_rd_data,
  output wire                                   MCB1_rd_full,
  output wire                                   MCB1_rd_empty,
  output wire [6:0]                             MCB1_rd_count,
  output wire                                   MCB1_rd_overflow,
  output wire                                   MCB1_rd_error,
  input  wire                                   MCB2_cmd_clk,
  input  wire                                   MCB2_cmd_en,
  input  wire [2:0]                             MCB2_cmd_instr,
  input  wire [5:0]                             MCB2_cmd_bl,
  input  wire [29:0]                            MCB2_cmd_byte_addr,
  output wire                                   MCB2_cmd_empty,
  output wire                                   MCB2_cmd_full,
  input  wire                                   MCB2_wr_clk,
  input  wire                                   MCB2_wr_en,
  input  wire [C_PI2_DATA_WIDTH/8-1:0]          MCB2_wr_mask,
  input  wire [C_PI2_DATA_WIDTH-1:0]            MCB2_wr_data,
  output wire                                   MCB2_wr_full,
  output wire                                   MCB2_wr_empty,
  output wire [6:0]                             MCB2_wr_count,
  output wire                                   MCB2_wr_underrun,
  output wire                                   MCB2_wr_error,
  input  wire                                   MCB2_rd_clk,
  input  wire                                   MCB2_rd_en,
  output wire [C_PI2_DATA_WIDTH-1:0]            MCB2_rd_data,
  output wire                                   MCB2_rd_full,
  output wire                                   MCB2_rd_empty,
  output wire [6:0]                             MCB2_rd_count,
  output wire                                   MCB2_rd_overflow,
  output wire                                   MCB2_rd_error,
  input  wire                                   MCB3_cmd_clk,
  input  wire                                   MCB3_cmd_en,
  input  wire [2:0]                             MCB3_cmd_instr,
  input  wire [5:0]                             MCB3_cmd_bl,
  input  wire [29:0]                            MCB3_cmd_byte_addr,
  output wire                                   MCB3_cmd_empty,
  output wire                                   MCB3_cmd_full,
  input  wire                                   MCB3_wr_clk,
  input  wire                                   MCB3_wr_en,
  input  wire [C_PI3_DATA_WIDTH/8-1:0]          MCB3_wr_mask,
  input  wire [C_PI3_DATA_WIDTH-1:0]            MCB3_wr_data,
  output wire                                   MCB3_wr_full,
  output wire                                   MCB3_wr_empty,
  output wire [6:0]                             MCB3_wr_count,
  output wire                                   MCB3_wr_underrun,
  output wire                                   MCB3_wr_error,
  input  wire                                   MCB3_rd_clk,
  input  wire                                   MCB3_rd_en,
  output wire [C_PI3_DATA_WIDTH-1:0]            MCB3_rd_data,
  output wire                                   MCB3_rd_full,
  output wire                                   MCB3_rd_empty,
  output wire [6:0]                             MCB3_rd_count,
  output wire                                   MCB3_rd_overflow,
  output wire                                   MCB3_rd_error,
  input  wire                                   MCB4_cmd_clk,
  input  wire                                   MCB4_cmd_en,
  input  wire [2:0]                             MCB4_cmd_instr,
  input  wire [5:0]                             MCB4_cmd_bl,
  input  wire [29:0]                            MCB4_cmd_byte_addr,
  output wire                                   MCB4_cmd_empty,
  output wire                                   MCB4_cmd_full,
  input  wire                                   MCB4_wr_clk,
  input  wire                                   MCB4_wr_en,
  input  wire [3:0]                             MCB4_wr_mask,
  input  wire [31:0]                            MCB4_wr_data,
  output wire                                   MCB4_wr_full,
  output wire                                   MCB4_wr_empty,
  output wire [6:0]                             MCB4_wr_count,
  output wire                                   MCB4_wr_underrun,
  output wire                                   MCB4_wr_error,
  input  wire                                   MCB4_rd_clk,
  input  wire                                   MCB4_rd_en,
  output wire [31:0]                            MCB4_rd_data,
  output wire                                   MCB4_rd_full,
  output wire                                   MCB4_rd_empty,
  output wire [6:0]                             MCB4_rd_count,
  output wire                                   MCB4_rd_overflow,
  output wire                                   MCB4_rd_error,
  input  wire                                   MCB5_cmd_clk,
  input  wire                                   MCB5_cmd_en,
  input  wire [2:0]                             MCB5_cmd_instr,
  input  wire [5:0]                             MCB5_cmd_bl,
  input  wire [29:0]                            MCB5_cmd_byte_addr,
  output wire                                   MCB5_cmd_empty,
  output wire                                   MCB5_cmd_full,
  input  wire                                   MCB5_wr_clk,
  input  wire                                   MCB5_wr_en,
  input  wire [3:0]                             MCB5_wr_mask,
  input  wire [31:0]                            MCB5_wr_data,
  output wire                                   MCB5_wr_full,
  output wire                                   MCB5_wr_empty,
  output wire [6:0]                             MCB5_wr_count,
  output wire                                   MCB5_wr_underrun,
  output wire                                   MCB5_wr_error,
  input  wire                                   MCB5_rd_clk,
  input  wire                                   MCB5_rd_en,
  output wire [31:0]                            MCB5_rd_data,
  output wire                                   MCB5_rd_full,
  output wire                                   MCB5_rd_empty,
  output wire [6:0]                             MCB5_rd_count,
  output wire                                   MCB5_rd_overflow,
  output wire                                   MCB5_rd_error,
  
  // Port 0
  // Port Interface Status Signals
  output wire [C_NUM_PORTS-1:0]                        PI_InitDone,
  // Port Interface Request/Acknowledge/Address Signals
  input  wire [C_NUM_PORTS*C_PIX_ADDR_WIDTH_MAX-1:0]   PI_Addr,
  input  wire [C_NUM_PORTS-1:0]                        PI_AddrReq,
  output wire [C_NUM_PORTS-1:0]                        PI_AddrAck,
  input  wire [C_NUM_PORTS-1:0]                        PI_RNW,
  input  wire [C_NUM_PORTS*4-1:0]                      PI_Size,
  input  wire [C_NUM_PORTS-1:0]                        PI_RdModWr,
  // Port Interface Data Signals
  input  wire [C_NUM_PORTS*C_PIX_DATA_WIDTH_MAX-1:0]   PI_WrFIFO_Data,
  input  wire [C_NUM_PORTS*C_PIX_BE_WIDTH_MAX-1:0]     PI_WrFIFO_BE,
  input  wire [C_NUM_PORTS-1:0]                        PI_WrFIFO_Push,
  output wire [C_NUM_PORTS*C_PIX_DATA_WIDTH_MAX-1:0]   PI_RdFIFO_Data,
  input  wire [C_NUM_PORTS-1:0]                        PI_RdFIFO_Pop,
  output wire [C_NUM_PORTS*C_PIX_RDWDADDR_WIDTH_MAX-1:0]   PI_RdFIFO_RdWdAddr,
  // Port Interface FIFO control/status
  output wire [C_NUM_PORTS-1:0]                        PI_WrFIFO_Empty,
  output wire [C_NUM_PORTS-1:0]                        PI_WrFIFO_AlmostFull,
  input  wire [C_NUM_PORTS-1:0]                        PI_WrFIFO_Flush,
  output wire [C_NUM_PORTS-1:0]                        PI_RdFIFO_Empty,
  input  wire [C_NUM_PORTS-1:0]                        PI_RdFIFO_Flush
);

  localparam P_MEM_CALIBRATION_MODE      = (C_MEM_CALIBRATION_MODE == 1) ? "CALIBRATION" : "NOCALIBRATION";
  localparam P_MEM_TZQINIT_MAXCNT        = C_MEM_TZQINIT_MAXCNT - 16;

  
  // Generate local MCB parameters for the selected memory type.
  localparam P_PORT_CONFIG_2             = (C_PIM2_BASETYPE == 9) ? "_W32" : "_R32";
  
  localparam P_PORT_CONFIG_3             = (C_PIM3_BASETYPE == 9) ? "_W32" : "_R32";
  
  localparam P_PORT_CONFIG_4             = (C_PIM4_BASETYPE == 9) ? "_W32" : "_R32";

  localparam P_PORT_CONFIG_5             = (C_PIM5_BASETYPE == 9) ? "_W32" : "_R32";
  
  localparam P_PORT_CONFIG               = (C_PORT_CONFIG == 4) ? "B128" :
                                           (C_PORT_CONFIG == 3) ? "B64_B64" :
                                           (C_PORT_CONFIG == 2) ? "B64_B32_B32" :
                                           (C_PORT_CONFIG == 1) ? "B32_B32_B32_B32" : 
                                           (C_PORT_CONFIG == 0) ? {"B32_B32", 
                                                                   P_PORT_CONFIG_2, P_PORT_CONFIG_3, 
                                                                   P_PORT_CONFIG_4, P_PORT_CONFIG_5} : 
                                                                  "B32_B32_B32_B32";

  localparam P_PORT_ENABLE               = { (C_PORT_CONFIG == 0) && (C_NUM_PORTS > 5) && (C_PIM5_BASETYPE != 0),
                                             (C_PORT_CONFIG == 0) && (C_NUM_PORTS > 4) && (C_PIM4_BASETYPE != 0),
                                             (C_PORT_CONFIG <= 1) && (C_NUM_PORTS > 3) && (C_PIM3_BASETYPE != 0),
                                             (C_PORT_CONFIG <= 2) && (C_NUM_PORTS > 2) && (C_PIM2_BASETYPE != 0),
                                             (C_PORT_CONFIG <= 3) && (C_NUM_PORTS > 1) && (C_PIM1_BASETYPE != 0),
                                             (C_PORT_CONFIG <= 4) && (C_NUM_PORTS > 0) && (C_PIM0_BASETYPE != 0)};
  localparam P_USR_INTERFACE_MODE        = "NATIVE";
  localparam C_P0_DATA_PORT_SIZE         = (C_PORT_CONFIG == 4) ? 128 : 
                                           (C_PORT_CONFIG >= 2) ? 64 : 
                                           32; 
                                            
  localparam C_P1_DATA_PORT_SIZE         = (C_PORT_CONFIG == 3) ? 64 : 
                                           32; 
                                           
  localparam P_ARB0_NUM_SLOTS            = (C_ARB0_ALGO == "CUSTOM") ? C_ARB0_NUM_SLOTS :
                                           (C_NUM_PORTS == 5)         ? 10 :
                                           12;
                                           
  localparam [17:0] P_ARB_FIXED_BASE     = (C_PORT_CONFIG == 4) ? 18'o777770 :
                                           (C_PORT_CONFIG == 3) ? 18'o777720 :
                                           (C_PORT_CONFIG == 2) ? 18'o777420 :
                                           (C_PORT_CONFIG == 1) ? 18'o774210 :
                                           (C_NUM_PORTS == 5)    ? 18'o743210 :
                                           18'o543210;
                                            
  localparam [17:0] P_ARB_TIME_SLOT_0    = (C_ARB0_ALGO == "CUSTOM") ? C_ARB_BRAM_INIT_00[0 +: 18] :
                                           (C_ARB0_ALGO == "FIXED")  ? P_ARB_FIXED_BASE :
                                           (C_PORT_CONFIG == 4)      ? 18'o777770 :
                                           (C_PORT_CONFIG == 3)      ? 18'o777720 :
                                           (C_PORT_CONFIG == 2)      ? 18'o777420 :
                                           (C_PORT_CONFIG == 1)      ? 18'o774210 :
                                           (C_NUM_PORTS == 5)        ? 18'o743210 :
                                           18'o543210;
  localparam [17:0] P_ARB_TIME_SLOT_1    = (C_ARB0_ALGO == "CUSTOM") ? C_ARB_BRAM_INIT_00[18 +: 18] :
                                           (C_ARB0_ALGO == "FIXED")  ? P_ARB_FIXED_BASE :
                                           (C_PORT_CONFIG == 4)      ? 18'o777770 :
                                           (C_PORT_CONFIG == 3)      ? 18'o777702 :
                                           (C_PORT_CONFIG == 2)      ? 18'o777042 :
                                           (C_PORT_CONFIG == 1)      ? 18'o770421 :
                                           (C_NUM_PORTS == 5)        ? 18'o704321 :
                                           18'o054321;
  localparam [17:0] P_ARB_TIME_SLOT_2    = (C_ARB0_ALGO == "CUSTOM") ? C_ARB_BRAM_INIT_00[36 +: 18] :
                                           (C_ARB0_ALGO == "FIXED")  ? P_ARB_FIXED_BASE :
                                           (C_PORT_CONFIG == 4)      ? 18'o777770 :
                                           (C_PORT_CONFIG == 3)      ? 18'o777720 :
                                           (C_PORT_CONFIG == 2)      ? 18'o777204 :
                                           (C_PORT_CONFIG == 1)      ? 18'o771042 :
                                           (C_NUM_PORTS == 5)        ? 18'o710432 :
                                           18'o105432;
  localparam [17:0] P_ARB_TIME_SLOT_3    = (C_ARB0_ALGO == "CUSTOM") ? C_ARB_BRAM_INIT_00[54 +: 18] :
                                           (C_ARB0_ALGO == "FIXED")  ? P_ARB_FIXED_BASE :
                                           (C_PORT_CONFIG == 4)      ? 18'o777770 :
                                           (C_PORT_CONFIG == 3)      ? 18'o777702 :
                                           (C_PORT_CONFIG == 2)      ? 18'o777420 :
                                           (C_PORT_CONFIG == 1)      ? 18'o772104 :
                                           (C_NUM_PORTS == 5)        ? 18'o721043 :
                                           18'o210543;
  localparam [17:0] P_ARB_TIME_SLOT_4    = (C_ARB0_ALGO == "CUSTOM") ? C_ARB_BRAM_INIT_00[72 +: 18] :
                                           (C_ARB0_ALGO == "FIXED")  ? P_ARB_FIXED_BASE :
                                           (C_PORT_CONFIG == 4)      ? 18'o777770 :
                                           (C_PORT_CONFIG == 3)      ? 18'o777720 :
                                           (C_PORT_CONFIG == 2)      ? 18'o777042 :
                                           (C_PORT_CONFIG == 1)      ? 18'o774210 :
                                           (C_NUM_PORTS == 5)        ? 18'o732104 :
                                           18'o321054;
  localparam [17:0] P_ARB_TIME_SLOT_5    = (C_ARB0_ALGO == "CUSTOM") ? C_ARB_BRAM_INIT_00[90 +: 18] :
                                           (C_ARB0_ALGO == "FIXED")  ? P_ARB_FIXED_BASE :
                                           (C_PORT_CONFIG == 4)      ? 18'o777770 :
                                           (C_PORT_CONFIG == 3)      ? 18'o777702 :
                                           (C_PORT_CONFIG == 2)      ? 18'o777204 :
                                           (C_PORT_CONFIG == 1)      ? 18'o770421 :
                                           (C_NUM_PORTS == 5)        ? 18'o743210 :
                                           18'o432105;
  localparam [17:0] P_ARB_TIME_SLOT_6    = (C_ARB0_ALGO == "CUSTOM") ? C_ARB_BRAM_INIT_00[108 +: 18] :
                                           (C_ARB0_ALGO == "FIXED")  ? P_ARB_FIXED_BASE :
                                           (C_PORT_CONFIG == 4)      ? 18'o777770 :
                                           (C_PORT_CONFIG == 3)      ? 18'o777720 :
                                           (C_PORT_CONFIG == 2)      ? 18'o777204 :
                                           (C_PORT_CONFIG == 1)      ? 18'o771042 :
                                           (C_NUM_PORTS == 5)        ? 18'o704321 :
                                           18'o543210;
  localparam [17:0] P_ARB_TIME_SLOT_7    = (C_ARB0_ALGO == "CUSTOM") ? C_ARB_BRAM_INIT_00[126 +: 18] :
                                           (C_ARB0_ALGO == "FIXED")  ? P_ARB_FIXED_BASE :
                                           (C_PORT_CONFIG == 4)      ? 18'o777770 :
                                           (C_PORT_CONFIG == 3)      ? 18'o777702 :
                                           (C_PORT_CONFIG == 2)      ? 18'o777042 :
                                           (C_PORT_CONFIG == 1)      ? 18'o772104 :
                                           (C_NUM_PORTS == 5)        ? 18'o710432 :
                                           18'o054321;
  localparam [17:0] P_ARB_TIME_SLOT_8    = (C_ARB0_ALGO == "CUSTOM") ? C_ARB_BRAM_INIT_00[144 +: 18] :
                                           (C_ARB0_ALGO == "FIXED")  ? P_ARB_FIXED_BASE :
                                           (C_PORT_CONFIG == 4)      ? 18'o777770 :
                                           (C_PORT_CONFIG == 3)      ? 18'o777720 :
                                           (C_PORT_CONFIG == 2)      ? 18'o777204 :
                                           (C_PORT_CONFIG == 1)      ? 18'o774210 :
                                           (C_NUM_PORTS == 5)        ? 18'o721043 :
                                           18'o105432;
  localparam [17:0] P_ARB_TIME_SLOT_9    = (C_ARB0_ALGO == "CUSTOM") ? C_ARB_BRAM_INIT_00[162 +: 18] :
                                           (C_ARB0_ALGO == "FIXED")  ? P_ARB_FIXED_BASE :
                                           (C_PORT_CONFIG == 4)      ? 18'o777770 :
                                           (C_PORT_CONFIG == 3)      ? 18'o777702 :
                                           (C_PORT_CONFIG == 2)      ? 18'o777204 :
                                           (C_PORT_CONFIG == 1)      ? 18'o770421 :
                                           (C_NUM_PORTS == 5)        ? 18'o732104 :
                                           18'o210543;
  localparam [17:0] P_ARB_TIME_SLOT_10   = (C_ARB0_ALGO == "CUSTOM") ? C_ARB_BRAM_INIT_00[180 +: 18] :
                                           (C_ARB0_ALGO == "FIXED")  ? P_ARB_FIXED_BASE :
                                           (C_PORT_CONFIG == 4)      ? 18'o777770 :
                                           (C_PORT_CONFIG == 3)      ? 18'o777720 :
                                           (C_PORT_CONFIG == 2)      ? 18'o777042 :
                                           (C_PORT_CONFIG == 1)      ? 18'o771042 :
                                           (C_NUM_PORTS == 5)        ? 18'o743210 :
                                           18'o321054;
  localparam [17:0] P_ARB_TIME_SLOT_11   = (C_ARB0_ALGO == "CUSTOM") ? C_ARB_BRAM_INIT_00[198 +: 18] :
                                           (C_ARB0_ALGO == "FIXED")  ? P_ARB_FIXED_BASE :
                                           (C_PORT_CONFIG == 4)      ? 18'o777770 :
                                           (C_PORT_CONFIG == 3)      ? 18'o777702 :
                                           (C_PORT_CONFIG == 2)      ? 18'o777204 :
                                           (C_PORT_CONFIG == 1)      ? 18'o772104 :
                                           (C_NUM_PORTS == 5)        ? 18'o704321 :
                                           18'o432105;

  localparam P_MEM_CALIBRATION_RA        = {C_MEM_ADDR_WIDTH{1'b1}};
  localparam P_MEM_CALIBRATION_BA        = {C_MEM_BANKADDR_WIDTH{1'b1}};
  localparam P_MEM_CALIBRATION_CA        = {C_MEM_PART_NUM_COL_BITS{1'b1}} - C_MEM_BURST_LENGTH + 1;
  localparam P_MEM_TYPE                  = (C_MEM_TYPE == "LPDDR") ? "MDDR": C_MEM_TYPE;
  localparam P_MEM_DDR3_CAS_LATENCY      = (P_MEM_TYPE == "DDR3") ? C_MEM_CAS_LATENCY0 : 7;
  
  localparam P_MEM_MOBILE_PA_SR          = (P_MEM_TYPE == "LPDDR" && C_MEM_PA_SR == 1) ? "HALF" : "FULL";
  
  localparam P_MEM_DDR1_2_ODS            = (C_MEM_REDUCED_DRV == 0) ? "FULL" : "REDUCED";
  
  localparam P_MEM_DDR3_ODS              = (C_MEM_REDUCED_DRV == 0) ? "DIV6" : 
                                           "DIV7";
  
  localparam P_MEM_MDDR_ODS              = (C_MEM_REDUCED_DRV == 0) ? "FULL" : 
                                           (C_MEM_REDUCED_DRV == 1) ? "HALF" : 
                                           (C_MEM_REDUCED_DRV == 2) ? "QUARTER" : 
                                           "THREEQUARTERS";
  
  localparam P_MEM_DDR2_RTT              = (C_MEM_ODT_TYPE == 0)  ? "OFF" :
                                           (C_MEM_ODT_TYPE == 1)  ? "75OHMS" : 
                                           (C_MEM_ODT_TYPE == 2)  ? "150OHMS" :
                                           "50OHMS";
  
  localparam P_MEM_DDR3_RTT              = (C_MEM_ODT_TYPE == 0)  ? "OFF" :  
                                           (C_MEM_ODT_TYPE == 1)  ? "DIV4" :  
                                           (C_MEM_ODT_TYPE == 2)  ? "DIV2" :  
                                           (C_MEM_ODT_TYPE == 3)  ? "DIV6" :  
                                           (C_MEM_ODT_TYPE == 4)  ? "DIV12" : 
                                           "DIV8";
                                           
  localparam P_MEM_DDR2_DIFF_DQS_EN      = (P_MEM_TYPE != "DDR2") ? "YES" :
                                           (C_MEM_DQSN_ENABLE)    ? "YES" : 
                                           "NO";
  // DDR2/DDR3 requires this value to be hardcoded to "FULL" 
  localparam P_MEM_DDR2_3_PA_SR          = "FULL";
  
  localparam P_MEM_DDR3_CAS_WR_LATENCY   = (P_MEM_TYPE == "DDR3") ? C_MEM_CAS_WR_LATENCY : 5;
  
  localparam P_MEM_DDR3_AUTO_SR          = (P_MEM_TYPE == "DDR3") ? C_MEM_AUTO_SR : "ENABLED";
  
  localparam P_MEM_DDR2_3_HIGH_TEMP_SR   = (P_MEM_TYPE == "DDR2" || P_MEM_TYPE == "DDR3") ? C_MEM_HIGH_TEMP_SR : "NORMAL";
  
  localparam P_MEM_DDR3_DYN_WRT_ODT      = (P_MEM_TYPE == "DDR3") ? C_MEM_DYNAMIC_WRITE_ODT : "OFF";
  
  wire                                   p0_cmd_clk_i;
  wire                                   p0_cmd_en_i;
  wire [2:0]                             p0_cmd_instr_i;
  wire [5:0]                             p0_cmd_bl_i;
  wire [29:0]                            p0_cmd_byte_addr_i;
  wire                                   p0_cmd_empty_i;
  wire                                   p0_cmd_full_i;
  wire                                   p0_wr_clk_i;
  wire                                   p0_wr_en_i;
  wire [C_P0_DATA_PORT_SIZE/8-1:0]       p0_wr_mask_i;
  wire [C_P0_DATA_PORT_SIZE-1:0]         p0_wr_data_i;
  wire                                   p0_wr_full_i;
  wire                                   p0_wr_empty_i;
  wire [6:0]                             p0_wr_count_i;
  wire                                   p0_wr_underrun_i;
  wire                                   p0_wr_error_i;
  wire                                   p0_rd_clk_i;
  wire                                   p0_rd_en_i;
  wire [C_P0_DATA_PORT_SIZE-1:0]         p0_rd_data_i;
  wire                                   p0_rd_full_i;
  wire                                   p0_rd_empty_i;
  wire [6:0]                             p0_rd_count_i;
  wire                                   p0_rd_overflow_i;
  wire                                   p0_rd_error_i;

  wire                                   p1_cmd_clk_i;
  wire                                   p1_cmd_en_i;
  wire [2:0]                             p1_cmd_instr_i;
  wire [5:0]                             p1_cmd_bl_i;
  wire [29:0]                            p1_cmd_byte_addr_i;
  wire                                   p1_cmd_empty_i;
  wire                                   p1_cmd_full_i;
  wire                                   p1_wr_clk_i;
  wire                                   p1_wr_en_i;
  wire [C_P1_DATA_PORT_SIZE/8-1:0]       p1_wr_mask_i;
  wire [C_P1_DATA_PORT_SIZE-1:0]         p1_wr_data_i;
  wire                                   p1_wr_full_i;
  wire                                   p1_wr_empty_i;
  wire [6:0]                             p1_wr_count_i;
  wire                                   p1_wr_underrun_i;
  wire                                   p1_wr_error_i;
  wire                                   p1_rd_clk_i;
  wire                                   p1_rd_en_i;
  wire [C_P1_DATA_PORT_SIZE-1:0]         p1_rd_data_i;
  wire                                   p1_rd_full_i;
  wire                                   p1_rd_empty_i;
  wire [6:0]                             p1_rd_count_i;
  wire                                   p1_rd_overflow_i;
  wire                                   p1_rd_error_i;

  wire                                   p2_cmd_clk_i;
  wire                                   p2_cmd_en_i;
  wire [2:0]                             p2_cmd_instr_i;
  wire [5:0]                             p2_cmd_bl_i;
  wire [29:0]                            p2_cmd_byte_addr_i;
  wire                                   p2_cmd_empty_i;
  wire                                   p2_cmd_full_i;
  wire                                   p2_wr_clk_i;
  wire                                   p2_wr_en_i;
  wire [3:0]                             p2_wr_mask_i;
  wire [31:0]                            p2_wr_data_i;
  wire                                   p2_wr_full_i;
  wire                                   p2_wr_empty_i;
  wire [6:0]                             p2_wr_count_i;
  wire                                   p2_wr_underrun_i;
  wire                                   p2_wr_error_i;
  wire                                   p2_rd_clk_i;
  wire                                   p2_rd_en_i;
  wire [31:0]                            p2_rd_data_i;
  wire                                   p2_rd_full_i;
  wire                                   p2_rd_empty_i;
  wire [6:0]                             p2_rd_count_i;
  wire                                   p2_rd_overflow_i;
  wire                                   p2_rd_error_i;

  wire                                   p3_cmd_clk_i;
  wire                                   p3_cmd_en_i;
  wire [2:0]                             p3_cmd_instr_i;
  wire [5:0]                             p3_cmd_bl_i;
  wire [29:0]                            p3_cmd_byte_addr_i;
  wire                                   p3_cmd_empty_i;
  wire                                   p3_cmd_full_i;
  wire                                   p3_wr_clk_i;
  wire                                   p3_wr_en_i;
  wire [3:0]                             p3_wr_mask_i;
  wire [31:0]                            p3_wr_data_i;
  wire                                   p3_wr_full_i;
  wire                                   p3_wr_empty_i;
  wire [6:0]                             p3_wr_count_i;
  wire                                   p3_wr_underrun_i;
  wire                                   p3_wr_error_i;
  wire                                   p3_rd_clk_i;
  wire                                   p3_rd_en_i;
  wire [31:0]                            p3_rd_data_i;
  wire                                   p3_rd_full_i;
  wire                                   p3_rd_empty_i;
  wire [6:0]                             p3_rd_count_i;
  wire                                   p3_rd_overflow_i;
  wire                                   p3_rd_error_i;

  wire                                   p4_cmd_clk_i;
  wire                                   p4_cmd_en_i;
  wire [2:0]                             p4_cmd_instr_i;
  wire [5:0]                             p4_cmd_bl_i;
  wire [29:0]                            p4_cmd_byte_addr_i;
  wire                                   p4_cmd_empty_i;
  wire                                   p4_cmd_full_i;
  wire                                   p4_wr_clk_i;
  wire                                   p4_wr_en_i;
  wire [3:0]                             p4_wr_mask_i;
  wire [31:0]                            p4_wr_data_i;
  wire                                   p4_wr_full_i;
  wire                                   p4_wr_empty_i;
  wire [6:0]                             p4_wr_count_i;
  wire                                   p4_wr_underrun_i;
  wire                                   p4_wr_error_i;
  wire                                   p4_rd_clk_i;
  wire                                   p4_rd_en_i;
  wire [31:0]                            p4_rd_data_i;
  wire                                   p4_rd_full_i;
  wire                                   p4_rd_empty_i;
  wire [6:0]                             p4_rd_count_i;
  wire                                   p4_rd_overflow_i;
  wire                                   p4_rd_error_i;

  wire                                   p5_cmd_clk_i;
  wire                                   p5_cmd_en_i;
  wire [2:0]                             p5_cmd_instr_i;
  wire [5:0]                             p5_cmd_bl_i;
  wire [29:0]                            p5_cmd_byte_addr_i;
  wire                                   p5_cmd_empty_i;
  wire                                   p5_cmd_full_i;
  wire                                   p5_wr_clk_i;
  wire                                   p5_wr_en_i;
  wire [3:0]                             p5_wr_mask_i;
  wire [31:0]                            p5_wr_data_i;
  wire                                   p5_wr_full_i;
  wire                                   p5_wr_empty_i;
  wire [6:0]                             p5_wr_count_i;
  wire                                   p5_wr_underrun_i;
  wire                                   p5_wr_error_i;
  wire                                   p5_rd_clk_i;
  wire                                   p5_rd_en_i;
  wire [31:0]                            p5_rd_data_i;
  wire                                   p5_rd_full_i;
  wire                                   p5_rd_empty_i;
  wire [6:0]                             p5_rd_count_i;
  wire                                   p5_rd_overflow_i;
  wire                                   p5_rd_error_i;
  
  wire                                   uo_done_cal;
  reg                                    uo_done_cal_d1;
  reg                                    uo_done_cal_d2;
  reg                                    rst_d1;
  reg                                    rst_d2;
  
  genvar  port_cnt;
  wire [5:0]                              expanded_PI_InitDone;
  // Port Interface Request/Acknowledge/Address Signals
  wire [6*C_PIX_ADDR_WIDTH_MAX-1:0]       expanded_PI_Addr;
  wire [5:0]                              expanded_PI_AddrReq;
  wire [5:0]                              expanded_PI_AddrAck;
  wire [5:0]                              expanded_PI_RNW;
  wire [6*4-1:0]                          expanded_PI_Size;
  wire [6:0]                              expanded_PI_RdModWr;
  // Port Interface Data Signals
  wire [6*C_PIX_DATA_WIDTH_MAX-1:0]       expanded_PI_WrFIFO_Data;
  wire [6*C_PIX_BE_WIDTH_MAX-1:0]         expanded_PI_WrFIFO_BE;
  wire [5:0]                              expanded_PI_WrFIFO_Push;
  wire [6*C_PIX_DATA_WIDTH_MAX-1:0]       expanded_PI_RdFIFO_Data;
  wire [5:0]                              expanded_PI_RdFIFO_Pop;
  wire [6*C_PIX_RDWDADDR_WIDTH_MAX-1:0]   expanded_PI_RdFIFO_RdWdAddr;
  // Port Interface FIFO control/status
  wire [5:0]                              expanded_PI_WrFIFO_Empty;
  wire [5:0]                              expanded_PI_WrFIFO_AlmostFull;
  wire [5:0]                              expanded_PI_WrFIFO_Flush;
  wire [5:0]                              expanded_PI_RdFIFO_Empty;
  wire [5:0]                              expanded_PI_RdFIFO_Flush;
  wire                                    ui_clk;

  assign ui_clk = (C_MCB_DRP_CLK_PRESENT) ? MCB_DRP_Clk : Clk0;
  assign  mcbx_InitDone = uo_done_cal;
  
  // Double Flop the output done_cal signal if we need to synchronize the signal  
  always @(posedge Clk0) begin
    uo_done_cal_d1 <= uo_done_cal;
    uo_done_cal_d2 <= uo_done_cal_d1;
  end

  // Flop the input reset to soft cal in case we need to synchronize
  always @(posedge ui_clk) begin
    rst_d1 <= Rst; 
    rst_d2 <= rst_d1; 
  end
  


  /////////////////////////////////////////////////////////////////////////////
  //Expand and contract NPI bus
  generate
    for (port_cnt = 0; port_cnt < 6; port_cnt = port_cnt + 1) begin : PCNT
      if (port_cnt < C_NUM_PORTS) begin : NON_PORT
        /////////////////////////////////////////////////////////////////////////////
        //Outbound
        assign PI_InitDone[port_cnt] = expanded_PI_InitDone[port_cnt];
        assign PI_AddrAck[port_cnt] = expanded_PI_AddrAck[port_cnt];
        assign PI_RdFIFO_Data[port_cnt*C_PIX_DATA_WIDTH_MAX +: C_PIX_DATA_WIDTH_MAX] = expanded_PI_RdFIFO_Data[port_cnt*C_PIX_DATA_WIDTH_MAX +: C_PIX_DATA_WIDTH_MAX];
        assign PI_RdFIFO_RdWdAddr[port_cnt*C_PIX_RDWDADDR_WIDTH_MAX +: C_PIX_RDWDADDR_WIDTH_MAX] = expanded_PI_RdFIFO_RdWdAddr[port_cnt*C_PIX_RDWDADDR_WIDTH_MAX +: C_PIX_RDWDADDR_WIDTH_MAX];
        assign PI_WrFIFO_Empty[port_cnt] = expanded_PI_WrFIFO_Empty[port_cnt];
        assign PI_WrFIFO_AlmostFull[port_cnt] = expanded_PI_WrFIFO_AlmostFull[port_cnt];
        assign PI_RdFIFO_Empty[port_cnt] = expanded_PI_RdFIFO_Empty[port_cnt];
        /////////////////////////////////////////////////////////////////////////////
        //Inbound
        assign expanded_PI_Addr[port_cnt*C_PIX_ADDR_WIDTH_MAX +: C_PIX_ADDR_WIDTH_MAX] = PI_Addr[port_cnt*C_PIX_ADDR_WIDTH_MAX +: C_PIX_ADDR_WIDTH_MAX];
        assign expanded_PI_AddrReq[port_cnt] = PI_AddrReq[port_cnt];
        assign expanded_PI_RNW[port_cnt] = PI_RNW[port_cnt];
        assign expanded_PI_Size[port_cnt*4 +: 4] = PI_Size[port_cnt*4 +: 4];
        assign expanded_PI_RdModWr[port_cnt] = PI_RdModWr[port_cnt];
        assign expanded_PI_WrFIFO_Data[port_cnt*C_PIX_DATA_WIDTH_MAX +: C_PIX_DATA_WIDTH_MAX] = PI_WrFIFO_Data[port_cnt*C_PIX_DATA_WIDTH_MAX +: C_PIX_DATA_WIDTH_MAX];
        assign expanded_PI_WrFIFO_BE[port_cnt*C_PIX_BE_WIDTH_MAX +: C_PIX_BE_WIDTH_MAX] = PI_WrFIFO_BE[port_cnt*C_PIX_BE_WIDTH_MAX +: C_PIX_BE_WIDTH_MAX];
        assign expanded_PI_WrFIFO_Push[port_cnt] = PI_WrFIFO_Push[port_cnt];
        assign expanded_PI_RdFIFO_Pop[port_cnt] = PI_RdFIFO_Pop[port_cnt];
        assign expanded_PI_WrFIFO_Flush[port_cnt] = PI_WrFIFO_Flush[port_cnt];
        assign expanded_PI_RdFIFO_Flush[port_cnt] = PI_RdFIFO_Flush[port_cnt];
      end else begin : PORT
        /////////////////////////////////////////////////////////////////////////////
        //Tieoffs
        assign expanded_PI_Addr[port_cnt*C_PIX_ADDR_WIDTH_MAX +: C_PIX_ADDR_WIDTH_MAX] = {C_PIX_ADDR_WIDTH_MAX{1'b0}};
        assign expanded_PI_AddrReq[port_cnt] = 1'b0;
        assign expanded_PI_RNW[port_cnt] = 1'b0;
        assign expanded_PI_Size[port_cnt*4 +: 4] = 4'h0;
        assign expanded_PI_RdModWr[port_cnt] = 1'b0;
        assign expanded_PI_WrFIFO_Data[port_cnt*C_PIX_DATA_WIDTH_MAX +: C_PIX_DATA_WIDTH_MAX] = {C_PIX_DATA_WIDTH_MAX{1'b0}};
        assign expanded_PI_WrFIFO_BE[port_cnt*C_PIX_BE_WIDTH_MAX +: C_PIX_BE_WIDTH_MAX] = {C_PIX_BE_WIDTH_MAX{1'b0}};
        assign expanded_PI_WrFIFO_Push[port_cnt] = 1'b0;
        assign expanded_PI_RdFIFO_Pop[port_cnt] = 1'b0;
        assign expanded_PI_WrFIFO_Flush[port_cnt] = 1'b0;
        assign expanded_PI_RdFIFO_Flush[port_cnt] = 1'b0;
      end
    end
  endgenerate
  
  // Select Native MCB or NPI bridge
  generate
    if (C_NUM_PORTS > 0 && C_PIM0_BASETYPE == 7) 
      begin : NATIVE_MCB_INST_0
        assign p0_cmd_clk_i       = MCB0_cmd_clk;
        assign p0_cmd_en_i        = MCB0_cmd_en;
        assign p0_cmd_instr_i     = MCB0_cmd_instr;
        assign p0_cmd_bl_i        = MCB0_cmd_bl;
        assign p0_cmd_byte_addr_i = MCB0_cmd_byte_addr;
        assign MCB0_cmd_empty     = p0_cmd_empty_i;
        assign MCB0_cmd_full      = p0_cmd_full_i;
        
        assign p0_wr_clk_i        = MCB0_wr_clk;
        assign p0_wr_en_i         = MCB0_wr_en;
        assign p0_wr_mask_i       = MCB0_wr_mask;
        assign p0_wr_data_i       = MCB0_wr_data;
        assign MCB0_wr_full       = p0_wr_full_i;
        assign MCB0_wr_empty      = p0_wr_empty_i;
        assign MCB0_wr_count      = p0_wr_count_i;
        assign MCB0_wr_underrun   = p0_wr_underrun_i;
        assign MCB0_wr_error      = p0_wr_error_i;
        
        assign p0_rd_clk_i        = MCB0_rd_clk;
        assign p0_rd_en_i         = MCB0_rd_en;
        assign MCB0_rd_data       = p0_rd_data_i;
        assign MCB0_rd_full       = p0_rd_full_i;
        assign MCB0_rd_empty      = p0_rd_empty_i;
        assign MCB0_rd_count      = p0_rd_count_i;
        assign MCB0_rd_overflow   = p0_rd_overflow_i;
        assign MCB0_rd_error      = p0_rd_error_i;
        
        assign expanded_PI_RdFIFO_Data[0*C_PIX_DATA_WIDTH_MAX +: 
                              (C_PI_DATA_WIDTH[0]?64:32)]              = {(C_PI_DATA_WIDTH[0]?64:32){1'b0}};
        assign expanded_PI_RdFIFO_RdWdAddr[0*C_PIX_RDWDADDR_WIDTH_MAX +:
                                  C_PIX_RDWDADDR_WIDTH_MAX]            = {C_PIX_RDWDADDR_WIDTH_MAX{1'b0}};
        assign expanded_PI_WrFIFO_Empty[0]                             = 1'b1;
        assign expanded_PI_WrFIFO_AlmostFull[0]                        = 1'b0;
        assign expanded_PI_RdFIFO_Empty[0]                             = 1'b1;
        assign expanded_PI_InitDone[0]                                 = uo_done_cal;
        assign expanded_PI_AddrAck[0]                                  = 1'b0;
      end
    else if (C_NUM_PORTS > 0 && C_PIM0_BASETYPE != 0)
      begin : NPI_BRIDGE_INST_0
        mpmc_npi2mcb #
          (
           .C_PI_ADDR_WIDTH             (C_PIX_ADDR_WIDTH_MAX),
           .C_PI_BASETYPE               (C_PIM0_BASETYPE),
           .C_PI_DATA_WIDTH             (C_PI_DATA_WIDTH[0]?64:32),
           .C_PI_BE_WIDTH               (C_PI_DATA_WIDTH[0]?8:4),
           .C_PI_RDWDADDR_WIDTH         (C_PIX_RDWDADDR_WIDTH_MAX)
           )
          mpmc_npi2mcb_0
            (
             .Clk_MPMC                  (Clk0),
             .Rst_MPMC                  (Rst),
  
             .PI_Addr                   (expanded_PI_Addr[0*C_PIX_ADDR_WIDTH_MAX +: C_PIX_ADDR_WIDTH_MAX]),
             .PI_AddrReq                (expanded_PI_AddrReq[0]),
             .PI_AddrAck                (expanded_PI_AddrAck[0]),
             .PI_RNW                    (expanded_PI_RNW[0]),
             .PI_RdModWr                (expanded_PI_RdModWr[0]),
             .PI_Size                   (expanded_PI_Size[(0+1)*4-1:0*4]),
             .PI_InitDone               (expanded_PI_InitDone[0]),
             .PI_WrFIFO_Data            (expanded_PI_WrFIFO_Data[0*C_PIX_DATA_WIDTH_MAX +: (C_PI_DATA_WIDTH[0]?64:32)]),
             .PI_WrFIFO_BE              (expanded_PI_WrFIFO_BE[0*C_PIX_BE_WIDTH_MAX +: (C_PI_DATA_WIDTH[0]?8:4)]),
             .PI_WrFIFO_Push            (expanded_PI_WrFIFO_Push[0]),
             .PI_RdFIFO_Data            (expanded_PI_RdFIFO_Data[0*C_PIX_DATA_WIDTH_MAX +: (C_PI_DATA_WIDTH[0]?64:32)]),
             .PI_RdFIFO_Pop             (expanded_PI_RdFIFO_Pop[0]),
             .PI_RdFIFO_RdWdAddr        (expanded_PI_RdFIFO_RdWdAddr[0*C_PIX_RDWDADDR_WIDTH_MAX +:
                                                            C_PIX_RDWDADDR_WIDTH_MAX]),
             .PI_WrFIFO_AlmostFull      (expanded_PI_WrFIFO_AlmostFull[0]),
             .PI_WrFIFO_Flush           (expanded_PI_WrFIFO_Flush[0]),
             .PI_WrFIFO_Empty           (expanded_PI_WrFIFO_Empty[0]),
             .PI_RdFIFO_Empty           (expanded_PI_RdFIFO_Empty[0]),
             .PI_RdFIFO_Flush           (expanded_PI_RdFIFO_Flush[0]),
             .PI_Error                  (), // Not used
            
             ///////////////////////////////////////
             
             .MCB_cmd_clk               (p0_cmd_clk_i),
             .MCB_cmd_en                (p0_cmd_en_i),
             .MCB_cmd_instr             (p0_cmd_instr_i),
             .MCB_cmd_bl                (p0_cmd_bl_i),
             .MCB_cmd_byte_addr         (p0_cmd_byte_addr_i),
             .MCB_cmd_empty             (p0_cmd_empty_i),
             .MCB_cmd_full              (p0_cmd_full_i),
            
             ///////////////////////////////////////
            
             .MCB_wr_clk                (p0_wr_clk_i),
             .MCB_wr_en                 (p0_wr_en_i),
             .MCB_wr_mask               (p0_wr_mask_i),
             .MCB_wr_data               (p0_wr_data_i),
             .MCB_wr_full               (p0_wr_full_i),
             .MCB_wr_empty              (p0_wr_empty_i),
             .MCB_wr_count              (p0_wr_count_i),
             .MCB_wr_underrun           (p0_wr_underrun_i),
             .MCB_wr_error              (p0_wr_error_i),
            
             .MCB_rd_clk                (p0_rd_clk_i),
             .MCB_rd_en                 (p0_rd_en_i),
             .MCB_rd_data               (p0_rd_data_i),
             .MCB_rd_full               (p0_rd_full_i),
             .MCB_rd_empty              (p0_rd_empty_i),
             .MCB_rd_count              (p0_rd_count_i),
             .MCB_rd_overflow           (p0_rd_overflow_i),
             .MCB_rd_error              (p0_rd_error_i),
             .MCB_calib_done            (uo_done_cal_d2)
             );
      end
    else
      begin : TIE_OFF_0
        // External native MCB port tie-off.
        assign MCB0_cmd_empty    = 1'b0;
        assign MCB0_cmd_full     = 1'b0;
        assign MCB0_wr_full      = 1'b0;
        assign MCB0_wr_empty     = 1'b0;
        assign MCB0_wr_count     = 7'b0;
        assign MCB0_wr_underrun  = 1'b0;
        assign MCB0_wr_error     = 1'b0;
        assign MCB0_rd_data      = {C_P0_DATA_PORT_SIZE{1'b0}};
        assign MCB0_rd_full      = 1'b0;
        assign MCB0_rd_empty     = 1'b0;
        assign MCB0_rd_count     = 7'b0;
        assign MCB0_rd_overflow  = 1'b0;
        assign MCB0_rd_error     = 1'b0;
        
        // Internal MCB tie-offs.
        assign p0_cmd_clk_i        = 1'b0;
        assign p0_cmd_en_i         = 1'b0;
        assign p0_cmd_instr_i      = 3'b0;
        assign p0_cmd_bl_i         = 6'b0;
        assign p0_cmd_byte_addr_i  = 30'b0;
        assign p0_wr_clk_i         = 1'b0;
        assign p0_wr_en_i          = 1'b0;
        assign p0_wr_mask_i        = {C_P0_DATA_PORT_SIZE/8{1'b0}};
        assign p0_wr_data_i        = {C_P0_DATA_PORT_SIZE{1'b0}};
        assign p0_rd_clk_i         = 1'b0;
        assign p0_rd_en_i          = 1'b0;
      end
  endgenerate
      
  generate
    if (C_NUM_PORTS > 1 && C_PIM1_BASETYPE == 7) 
      begin : NATIVE_MCB_INST_1
        assign p1_cmd_clk_i       = MCB1_cmd_clk;
        assign p1_cmd_en_i        = MCB1_cmd_en;
        assign p1_cmd_instr_i     = MCB1_cmd_instr;
        assign p1_cmd_bl_i        = MCB1_cmd_bl;
        assign p1_cmd_byte_addr_i = MCB1_cmd_byte_addr;
        assign MCB1_cmd_empty     = p1_cmd_empty_i;
        assign MCB1_cmd_full      = p1_cmd_full_i;
        
        assign p1_wr_clk_i        = MCB1_wr_clk;
        assign p1_wr_en_i         = MCB1_wr_en;
        assign p1_wr_mask_i       = MCB1_wr_mask;
        assign p1_wr_data_i       = MCB1_wr_data;
        assign MCB1_wr_full       = p1_wr_full_i;
        assign MCB1_wr_empty      = p1_wr_empty_i;
        assign MCB1_wr_count      = p1_wr_count_i;
        assign MCB1_wr_underrun   = p1_wr_underrun_i;
        assign MCB1_wr_error      = p1_wr_error_i;
        
        assign p1_rd_clk_i        = MCB1_rd_clk;
        assign p1_rd_en_i         = MCB1_rd_en;
        assign MCB1_rd_data       = p1_rd_data_i;
        assign MCB1_rd_full       = p1_rd_full_i;
        assign MCB1_rd_empty      = p1_rd_empty_i;
        assign MCB1_rd_count      = p1_rd_count_i;
        assign MCB1_rd_overflow   = p1_rd_overflow_i;
        assign MCB1_rd_error      = p1_rd_error_i;
        
        assign expanded_PI_AddrAck[1]                                  = 1'b0;
        assign expanded_PI_RdFIFO_Data[1*C_PIX_DATA_WIDTH_MAX +: 
                              (C_PI_DATA_WIDTH[1]?64:32)]              = {(C_PI_DATA_WIDTH[1]?64:32){1'b0}};
        assign expanded_PI_RdFIFO_RdWdAddr[1*C_PIX_RDWDADDR_WIDTH_MAX +:
                                  C_PIX_RDWDADDR_WIDTH_MAX]            = {C_PIX_RDWDADDR_WIDTH_MAX{1'b0}};
        assign expanded_PI_WrFIFO_Empty[1]                             = 1'b1;
        assign expanded_PI_WrFIFO_AlmostFull[1]                        = 1'b0;
        assign expanded_PI_RdFIFO_Empty[1]                             = 1'b1;
        assign expanded_PI_InitDone[1]                                 = uo_done_cal;
      end
    else if (C_NUM_PORTS > 0 && C_PIM1_BASETYPE != 0)
      begin : NPI_BRIDGE_INST_1
        mpmc_npi2mcb #
          (
           .C_PI_ADDR_WIDTH             (C_PIX_ADDR_WIDTH_MAX),
           .C_PI_BASETYPE               (C_PIM1_BASETYPE),
           .C_PI_DATA_WIDTH             (C_PI_DATA_WIDTH[1]?64:32),
           .C_PI_BE_WIDTH               (C_PI_DATA_WIDTH[1]?8:4),
           .C_PI_RDWDADDR_WIDTH         (C_PIX_RDWDADDR_WIDTH_MAX)
           )
          mpmc_npi2mcb_1
            (
             .Clk_MPMC                  (Clk0),
             .Rst_MPMC                  (Rst),
  
             .PI_Addr                   (expanded_PI_Addr[1*C_PIX_ADDR_WIDTH_MAX +: C_PIX_ADDR_WIDTH_MAX]),
             .PI_AddrReq                (expanded_PI_AddrReq[1]),
             .PI_AddrAck                (expanded_PI_AddrAck[1]),
             .PI_RNW                    (expanded_PI_RNW[1]),
             .PI_RdModWr                (expanded_PI_RdModWr[1]),
             .PI_Size                   (expanded_PI_Size[(1+1)*4-1:1*4]),
             .PI_InitDone               (expanded_PI_InitDone[1]),
             .PI_WrFIFO_Data            (expanded_PI_WrFIFO_Data[1*C_PIX_DATA_WIDTH_MAX +: (C_PI_DATA_WIDTH[1]?64:32)]),
             .PI_WrFIFO_BE              (expanded_PI_WrFIFO_BE[1*C_PIX_BE_WIDTH_MAX +: (C_PI_DATA_WIDTH[1]?8:4)]),
             .PI_WrFIFO_Push            (expanded_PI_WrFIFO_Push[1]),
             .PI_RdFIFO_Data            (expanded_PI_RdFIFO_Data[1*C_PIX_DATA_WIDTH_MAX +: (C_PI_DATA_WIDTH[1]?64:32)]),
             .PI_RdFIFO_Pop             (expanded_PI_RdFIFO_Pop[1]),
             .PI_RdFIFO_RdWdAddr        (expanded_PI_RdFIFO_RdWdAddr[1*C_PIX_RDWDADDR_WIDTH_MAX +:
                                                            C_PIX_RDWDADDR_WIDTH_MAX]),
             .PI_WrFIFO_AlmostFull      (expanded_PI_WrFIFO_AlmostFull[1]),
             .PI_WrFIFO_Flush           (expanded_PI_WrFIFO_Flush[1]),
             .PI_WrFIFO_Empty           (expanded_PI_WrFIFO_Empty[1]),
             .PI_RdFIFO_Empty           (expanded_PI_RdFIFO_Empty[1]),
             .PI_RdFIFO_Flush           (expanded_PI_RdFIFO_Flush[1]),
             .PI_Error                  (), // Not used
            
             ///////////////////////////////////////
             
             .MCB_cmd_clk               (p1_cmd_clk_i),
             .MCB_cmd_en                (p1_cmd_en_i),
             .MCB_cmd_instr             (p1_cmd_instr_i),
             .MCB_cmd_bl                (p1_cmd_bl_i),
             .MCB_cmd_byte_addr         (p1_cmd_byte_addr_i),
             .MCB_cmd_empty             (p1_cmd_empty_i),
             .MCB_cmd_full              (p1_cmd_full_i),
            
             ///////////////////////////////////////
            
             .MCB_wr_clk                (p1_wr_clk_i),
             .MCB_wr_en                 (p1_wr_en_i),
             .MCB_wr_mask               (p1_wr_mask_i),
             .MCB_wr_data               (p1_wr_data_i),
             .MCB_wr_full               (p1_wr_full_i),
             .MCB_wr_empty              (p1_wr_empty_i),
             .MCB_wr_count              (p1_wr_count_i),
             .MCB_wr_underrun           (p1_wr_underrun_i),
             .MCB_wr_error              (p1_wr_error_i),
            
             .MCB_rd_clk                (p1_rd_clk_i),
             .MCB_rd_en                 (p1_rd_en_i),
             .MCB_rd_data               (p1_rd_data_i),
             .MCB_rd_full               (p1_rd_full_i),
             .MCB_rd_empty              (p1_rd_empty_i),
             .MCB_rd_count              (p1_rd_count_i),
             .MCB_rd_overflow           (p1_rd_overflow_i),
             .MCB_rd_error              (p1_rd_error_i),
             .MCB_calib_done            (uo_done_cal_d2)
             );
      end
    else
      begin : TIE_OFF_1
        // External native MCB port tie-off.
        assign MCB1_cmd_empty    = 1'b0;
        assign MCB1_cmd_full     = 1'b0;
        assign MCB1_wr_full      = 1'b0;
        assign MCB1_wr_empty     = 1'b0;
        assign MCB1_wr_count     = 7'b0;
        assign MCB1_wr_underrun  = 1'b0;
        assign MCB1_wr_error     = 1'b0;
        assign MCB1_rd_data      = {C_P1_DATA_PORT_SIZE{1'b0}};
        assign MCB1_rd_full      = 1'b0;
        assign MCB1_rd_empty     = 1'b0;
        assign MCB1_rd_count     = 7'b0;
        assign MCB1_rd_overflow  = 1'b0;
        assign MCB1_rd_error     = 1'b0;
        
        // Internal MCB tie-offs.
        assign p1_cmd_clk_i        = 1'b0;
        assign p1_cmd_en_i         = 1'b0;
        assign p1_cmd_instr_i      = 3'b0;
        assign p1_cmd_bl_i         = 6'b0;
        assign p1_cmd_byte_addr_i  = 30'b0;
        assign p1_wr_clk_i         = 1'b0;
        assign p1_wr_en_i          = 1'b0;
        assign p1_wr_mask_i        = {C_P0_DATA_PORT_SIZE/8{1'b0}};
        assign p1_wr_data_i        = {C_P1_DATA_PORT_SIZE{1'b0}};
        assign p1_rd_clk_i         = 1'b0;
        assign p1_rd_en_i          = 1'b0;
      end
  endgenerate
    
  generate
    if (C_NUM_PORTS > 2 && (C_PIM2_BASETYPE == 7) || (C_PIM2_BASETYPE == 8) || (C_PIM2_BASETYPE == 9))
      begin : NATIVE_MCB_INST_2
        assign p2_cmd_clk_i       = MCB2_cmd_clk;
        assign p2_cmd_en_i        = MCB2_cmd_en;
        assign p2_cmd_instr_i     = MCB2_cmd_instr;
        assign p2_cmd_bl_i        = MCB2_cmd_bl;
        assign p2_cmd_byte_addr_i = MCB2_cmd_byte_addr;
        assign MCB2_cmd_empty     = p2_cmd_empty_i;
        assign MCB2_cmd_full      = p2_cmd_full_i;
        
        assign p2_wr_clk_i        = MCB2_wr_clk;
        assign p2_wr_en_i         = MCB2_wr_en;
        assign p2_wr_mask_i       = MCB2_wr_mask;
        assign p2_wr_data_i       = MCB2_wr_data;
        assign MCB2_wr_full       = p2_wr_full_i;
        assign MCB2_wr_empty      = p2_wr_empty_i;
        assign MCB2_wr_count      = p2_wr_count_i;
        assign MCB2_wr_underrun   = p2_wr_underrun_i;
        assign MCB2_wr_error      = p2_wr_error_i;
        
        assign p2_rd_clk_i        = MCB2_rd_clk;
        assign p2_rd_en_i         = MCB2_rd_en;
        assign MCB2_rd_data       = p2_rd_data_i;
        assign MCB2_rd_full       = p2_rd_full_i;
        assign MCB2_rd_empty      = p2_rd_empty_i;
        assign MCB2_rd_count      = p2_rd_count_i;
        assign MCB2_rd_overflow   = p2_rd_overflow_i;
        assign MCB2_rd_error      = p2_rd_error_i;
        
        assign expanded_PI_AddrAck[2]                                  = 1'b0;
        assign expanded_PI_RdFIFO_Data[2*C_PIX_DATA_WIDTH_MAX +: 
                              (C_PI_DATA_WIDTH[2]?64:32)]              = {(C_PI_DATA_WIDTH[2]?64:32){1'b0}};
        assign expanded_PI_RdFIFO_RdWdAddr[2*C_PIX_RDWDADDR_WIDTH_MAX +:
                                  C_PIX_RDWDADDR_WIDTH_MAX]            = {C_PIX_RDWDADDR_WIDTH_MAX{1'b0}};
        assign expanded_PI_WrFIFO_Empty[2]                             = 1'b1;
        assign expanded_PI_WrFIFO_AlmostFull[2]                        = 1'b0;
        assign expanded_PI_RdFIFO_Empty[2]                             = 1'b1;
        assign expanded_PI_InitDone[2]                                 = uo_done_cal;
      end
    else if (C_NUM_PORTS > 0 && C_PIM2_BASETYPE != 0)
      begin : NPI_BRIDGE_INST_2
        mpmc_npi2mcb #
          (
           .C_PI_ADDR_WIDTH             (C_PIX_ADDR_WIDTH_MAX),
           .C_PI_BASETYPE               (C_PIM2_BASETYPE),
           .C_PI_DATA_WIDTH             (C_PI_DATA_WIDTH[2]?64:32),
           .C_PI_BE_WIDTH               (C_PI_DATA_WIDTH[2]?8:4),
           .C_PI_RDWDADDR_WIDTH         (C_PIX_RDWDADDR_WIDTH_MAX)
           )
          mpmc_npi2mcb_2
            (
             .Clk_MPMC                  (Clk0),
             .Rst_MPMC                  (Rst),
  
             .PI_Addr                   (expanded_PI_Addr[2*C_PIX_ADDR_WIDTH_MAX +: C_PIX_ADDR_WIDTH_MAX]),
             .PI_AddrReq                (expanded_PI_AddrReq[2]),
             .PI_AddrAck                (expanded_PI_AddrAck[2]),
             .PI_RNW                    (expanded_PI_RNW[2]),
             .PI_RdModWr                (expanded_PI_RdModWr[2]),
             .PI_Size                   (expanded_PI_Size[(2+1)*4-1:2*4]),
             .PI_InitDone               (expanded_PI_InitDone[2]),
             .PI_WrFIFO_Data            (expanded_PI_WrFIFO_Data[2*C_PIX_DATA_WIDTH_MAX +: (C_PI_DATA_WIDTH[2]?64:32)]),
             .PI_WrFIFO_BE              (expanded_PI_WrFIFO_BE[2*C_PIX_BE_WIDTH_MAX +: (C_PI_DATA_WIDTH[2]?8:4)]),
             .PI_WrFIFO_Push            (expanded_PI_WrFIFO_Push[2]),
             .PI_RdFIFO_Data            (expanded_PI_RdFIFO_Data[2*C_PIX_DATA_WIDTH_MAX +: (C_PI_DATA_WIDTH[2]?64:32)]),
             .PI_RdFIFO_Pop             (expanded_PI_RdFIFO_Pop[2]),
             .PI_RdFIFO_RdWdAddr        (expanded_PI_RdFIFO_RdWdAddr[2*C_PIX_RDWDADDR_WIDTH_MAX +:
                                                            C_PIX_RDWDADDR_WIDTH_MAX]),
             .PI_WrFIFO_AlmostFull      (expanded_PI_WrFIFO_AlmostFull[2]),
             .PI_WrFIFO_Flush           (expanded_PI_WrFIFO_Flush[2]),
             .PI_WrFIFO_Empty           (expanded_PI_WrFIFO_Empty[2]),
             .PI_RdFIFO_Empty           (expanded_PI_RdFIFO_Empty[2]),
             .PI_RdFIFO_Flush           (expanded_PI_RdFIFO_Flush[2]),
             .PI_Error                  (), // Not used
            
             ///////////////////////////////////////
             
             .MCB_cmd_clk               (p2_cmd_clk_i),
             .MCB_cmd_en                (p2_cmd_en_i),
             .MCB_cmd_instr             (p2_cmd_instr_i),
             .MCB_cmd_bl                (p2_cmd_bl_i),
             .MCB_cmd_byte_addr         (p2_cmd_byte_addr_i),
             .MCB_cmd_empty             (p2_cmd_empty_i),
             .MCB_cmd_full              (p2_cmd_full_i),
            
             ///////////////////////////////////////
            
             .MCB_wr_clk                (p2_wr_clk_i),
             .MCB_wr_en                 (p2_wr_en_i),
             .MCB_wr_mask               (p2_wr_mask_i),
             .MCB_wr_data               (p2_wr_data_i),
             .MCB_wr_full               (p2_wr_full_i),
             .MCB_wr_empty              (p2_wr_empty_i),
             .MCB_wr_count              (p2_wr_count_i),
             .MCB_wr_underrun           (p2_wr_underrun_i),
             .MCB_wr_error              (p2_wr_error_i),
            
             .MCB_rd_clk                (p2_rd_clk_i),
             .MCB_rd_en                 (p2_rd_en_i),
             .MCB_rd_data               (p2_rd_data_i),
             .MCB_rd_full               (p2_rd_full_i),
             .MCB_rd_empty              (p2_rd_empty_i),
             .MCB_rd_count              (p2_rd_count_i),
             .MCB_rd_overflow           (p2_rd_overflow_i),
             .MCB_rd_error              (p2_rd_error_i),
             .MCB_calib_done            (uo_done_cal_d2)
             );
      end
    else
      begin : TIE_OFF_2
        // External native MCB port tie-off.
        assign MCB2_cmd_empty    = 1'b0;
        assign MCB2_cmd_full     = 1'b0;
        assign MCB2_wr_full      = 1'b0;
        assign MCB2_wr_empty     = 1'b0;
        assign MCB2_wr_count     = 7'b0;
        assign MCB2_wr_underrun  = 1'b0;
        assign MCB2_wr_error     = 1'b0;
        assign MCB2_rd_data      = 32'b0;
        assign MCB2_rd_full      = 1'b0;
        assign MCB2_rd_empty     = 1'b0;
        assign MCB2_rd_count     = 7'b0;
        assign MCB2_rd_overflow  = 1'b0;
        assign MCB2_rd_error     = 1'b0;
        
        // Internal MCB tie-offs.
        assign p2_cmd_clk_i        = 1'b0;
        assign p2_cmd_en_i         = 1'b0;
        assign p2_cmd_instr_i      = 3'b0;
        assign p2_cmd_bl_i         = 6'b0;
        assign p2_cmd_byte_addr_i  = 30'b0;
        assign p2_wr_clk_i         = 1'b0;
        assign p2_wr_en_i          = 1'b0;
        assign p2_wr_mask_i        = 4'b0;
        assign p2_wr_data_i        = 32'b0;
        assign p2_rd_clk_i         = 1'b0;
        assign p2_rd_en_i          = 1'b0;
      end
  endgenerate
    
  generate
    if (C_NUM_PORTS > 3 && (C_PIM3_BASETYPE == 7) || (C_PIM3_BASETYPE == 8) || (C_PIM3_BASETYPE == 9))
      begin : NATIVE_MCB_INST_3
        assign p3_cmd_clk_i       = MCB3_cmd_clk;
        assign p3_cmd_en_i        = MCB3_cmd_en;
        assign p3_cmd_instr_i     = MCB3_cmd_instr;
        assign p3_cmd_bl_i        = MCB3_cmd_bl;
        assign p3_cmd_byte_addr_i = MCB3_cmd_byte_addr;
        assign MCB3_cmd_empty     = p3_cmd_empty_i;
        assign MCB3_cmd_full      = p3_cmd_full_i;
        
        assign p3_wr_clk_i        = MCB3_wr_clk;
        assign p3_wr_en_i         = MCB3_wr_en;
        assign p3_wr_mask_i       = MCB3_wr_mask;
        assign p3_wr_data_i       = MCB3_wr_data;
        assign MCB3_wr_full       = p3_wr_full_i;
        assign MCB3_wr_empty      = p3_wr_empty_i;
        assign MCB3_wr_count      = p3_wr_count_i;
        assign MCB3_wr_underrun   = p3_wr_underrun_i;
        assign MCB3_wr_error      = p3_wr_error_i;
        
        assign p3_rd_clk_i        = MCB3_rd_clk;
        assign p3_rd_en_i         = MCB3_rd_en;
        assign MCB3_rd_data       = p3_rd_data_i;
        assign MCB3_rd_full       = p3_rd_full_i;
        assign MCB3_rd_empty      = p3_rd_empty_i;
        assign MCB3_rd_count      = p3_rd_count_i;
        assign MCB3_rd_overflow   = p3_rd_overflow_i;
        assign MCB3_rd_error      = p3_rd_error_i;
        
        assign expanded_PI_AddrAck[3]                                  = 1'b0;
        assign expanded_PI_RdFIFO_Data[3*C_PIX_DATA_WIDTH_MAX +: 
                              (C_PI_DATA_WIDTH[3]?64:32)]              = {(C_PI_DATA_WIDTH[3]?64:32){1'b0}};
        assign expanded_PI_RdFIFO_RdWdAddr[3*C_PIX_RDWDADDR_WIDTH_MAX +:
                                  C_PIX_RDWDADDR_WIDTH_MAX]            = {C_PIX_RDWDADDR_WIDTH_MAX{1'b0}};
        assign expanded_PI_WrFIFO_Empty[3]                             = 1'b1;
        assign expanded_PI_WrFIFO_AlmostFull[3]                        = 1'b0;
        assign expanded_PI_RdFIFO_Empty[3]                             = 1'b1;
        assign expanded_PI_InitDone[3]                                 = uo_done_cal;
      end
    else if (C_NUM_PORTS > 0 && C_PIM3_BASETYPE != 0)
      begin : NPI_BRIDGE_INST_3
        mpmc_npi2mcb #
          (
           .C_PI_ADDR_WIDTH             (C_PIX_ADDR_WIDTH_MAX),
           .C_PI_BASETYPE               (C_PIM3_BASETYPE),
           .C_PI_DATA_WIDTH             (C_PI_DATA_WIDTH[3]?64:32),
           .C_PI_BE_WIDTH               (C_PI_DATA_WIDTH[3]?8:4),
           .C_PI_RDWDADDR_WIDTH         (C_PIX_RDWDADDR_WIDTH_MAX)
           )
          mpmc_npi2mcb_3
            (
             .Clk_MPMC                  (Clk0),
             .Rst_MPMC                  (Rst),
  
             .PI_Addr                   (expanded_PI_Addr[3*C_PIX_ADDR_WIDTH_MAX +: C_PIX_ADDR_WIDTH_MAX]),
             .PI_AddrReq                (expanded_PI_AddrReq[3]),
             .PI_AddrAck                (expanded_PI_AddrAck[3]),
             .PI_RNW                    (expanded_PI_RNW[3]),
             .PI_RdModWr                (expanded_PI_RdModWr[3]),
             .PI_Size                   (expanded_PI_Size[(3+1)*4-1:3*4]),
             .PI_InitDone               (expanded_PI_InitDone[3]),
             .PI_WrFIFO_Data            (expanded_PI_WrFIFO_Data[3*C_PIX_DATA_WIDTH_MAX +: (C_PI_DATA_WIDTH[3]?64:32)]),
             .PI_WrFIFO_BE              (expanded_PI_WrFIFO_BE[3*C_PIX_BE_WIDTH_MAX +: (C_PI_DATA_WIDTH[3]?8:4)]),
             .PI_WrFIFO_Push            (expanded_PI_WrFIFO_Push[3]),
             .PI_RdFIFO_Data            (expanded_PI_RdFIFO_Data[3*C_PIX_DATA_WIDTH_MAX +: (C_PI_DATA_WIDTH[3]?64:32)]),
             .PI_RdFIFO_Pop             (expanded_PI_RdFIFO_Pop[3]),
             .PI_RdFIFO_RdWdAddr        (expanded_PI_RdFIFO_RdWdAddr[3*C_PIX_RDWDADDR_WIDTH_MAX +:
                                                            C_PIX_RDWDADDR_WIDTH_MAX]),
             .PI_WrFIFO_AlmostFull      (expanded_PI_WrFIFO_AlmostFull[3]),
             .PI_WrFIFO_Flush           (expanded_PI_WrFIFO_Flush[3]),
             .PI_WrFIFO_Empty           (expanded_PI_WrFIFO_Empty[3]),
             .PI_RdFIFO_Empty           (expanded_PI_RdFIFO_Empty[3]),
             .PI_RdFIFO_Flush           (expanded_PI_RdFIFO_Flush[3]),
             .PI_Error                  (), // Not used
            
             ///////////////////////////////////////
             
             .MCB_cmd_clk               (p3_cmd_clk_i),
             .MCB_cmd_en                (p3_cmd_en_i),
             .MCB_cmd_instr             (p3_cmd_instr_i),
             .MCB_cmd_bl                (p3_cmd_bl_i),
             .MCB_cmd_byte_addr         (p3_cmd_byte_addr_i),
             .MCB_cmd_empty             (p3_cmd_empty_i),
             .MCB_cmd_full              (p3_cmd_full_i),
            
             ///////////////////////////////////////
            
             .MCB_wr_clk                (p3_wr_clk_i),
             .MCB_wr_en                 (p3_wr_en_i),
             .MCB_wr_mask               (p3_wr_mask_i),
             .MCB_wr_data               (p3_wr_data_i),
             .MCB_wr_full               (p3_wr_full_i),
             .MCB_wr_empty              (p3_wr_empty_i),
             .MCB_wr_count              (p3_wr_count_i),
             .MCB_wr_underrun           (p3_wr_underrun_i),
             .MCB_wr_error              (p3_wr_error_i),
            
             .MCB_rd_clk                (p3_rd_clk_i),
             .MCB_rd_en                 (p3_rd_en_i),
             .MCB_rd_data               (p3_rd_data_i),
             .MCB_rd_full               (p3_rd_full_i),
             .MCB_rd_empty              (p3_rd_empty_i),
             .MCB_rd_count              (p3_rd_count_i),
             .MCB_rd_overflow           (p3_rd_overflow_i),
             .MCB_rd_error              (p3_rd_error_i),
             .MCB_calib_done            (uo_done_cal_d2)
             );
      end
    else
      begin : TIE_OFF_3
        // External native MCB port tie-off.
        assign MCB3_cmd_empty    = 1'b0;
        assign MCB3_cmd_full     = 1'b0;
        assign MCB3_wr_full      = 1'b0;
        assign MCB3_wr_empty     = 1'b0;
        assign MCB3_wr_count     = 7'b0;
        assign MCB3_wr_underrun  = 1'b0;
        assign MCB3_wr_error     = 1'b0;
        assign MCB3_rd_data      = 32'b0;
        assign MCB3_rd_full      = 1'b0;
        assign MCB3_rd_empty     = 1'b0;
        assign MCB3_rd_count     = 7'b0;
        assign MCB3_rd_overflow  = 1'b0;
        assign MCB3_rd_error     = 1'b0;
        
        // Internal MCB tie-offs.
        assign p3_cmd_clk_i        = 1'b0;
        assign p3_cmd_en_i         = 1'b0;
        assign p3_cmd_instr_i      = 3'b0;
        assign p3_cmd_bl_i         = 6'b0;
        assign p3_cmd_byte_addr_i  = 30'b0;
        assign p3_wr_clk_i         = 1'b0;
        assign p3_wr_en_i          = 1'b0;
        assign p3_wr_mask_i        = 4'b0;
        assign p3_wr_data_i        = 32'b0;
        assign p3_rd_clk_i         = 1'b0;
        assign p3_rd_en_i          = 1'b0;
      end
  endgenerate
    
  generate
    if (C_NUM_PORTS > 4 && (C_PIM4_BASETYPE == 7) || (C_PIM4_BASETYPE == 8) || (C_PIM4_BASETYPE == 9))
      begin : NATIVE_MCB_INST_4
        assign p4_cmd_clk_i       = MCB4_cmd_clk;
        assign p4_cmd_en_i        = MCB4_cmd_en;
        assign p4_cmd_instr_i     = MCB4_cmd_instr;
        assign p4_cmd_bl_i        = MCB4_cmd_bl;
        assign p4_cmd_byte_addr_i = MCB4_cmd_byte_addr;
        assign MCB4_cmd_empty     = p4_cmd_empty_i;
        assign MCB4_cmd_full      = p4_cmd_full_i;
        
        assign p4_wr_clk_i        = MCB4_wr_clk;
        assign p4_wr_en_i         = MCB4_wr_en;
        assign p4_wr_mask_i       = MCB4_wr_mask;
        assign p4_wr_data_i       = MCB4_wr_data;
        assign MCB4_wr_full       = p4_wr_full_i;
        assign MCB4_wr_empty      = p4_wr_empty_i;
        assign MCB4_wr_count      = p4_wr_count_i;
        assign MCB4_wr_underrun   = p4_wr_underrun_i;
        assign MCB4_wr_error      = p4_wr_error_i;
        
        assign p4_rd_clk_i        = MCB4_rd_clk;
        assign p4_rd_en_i         = MCB4_rd_en;
        assign MCB4_rd_data       = p4_rd_data_i;
        assign MCB4_rd_full       = p4_rd_full_i;
        assign MCB4_rd_empty      = p4_rd_empty_i;
        assign MCB4_rd_count      = p4_rd_count_i;
        assign MCB4_rd_overflow   = p4_rd_overflow_i;
        assign MCB4_rd_error      = p4_rd_error_i;
        
        assign expanded_PI_AddrAck[4]                                  = 1'b0;
        assign expanded_PI_RdFIFO_Data[4*C_PIX_DATA_WIDTH_MAX +: 
                              (C_PI_DATA_WIDTH[4]?64:32)]              = {(C_PI_DATA_WIDTH[4]?64:32){1'b0}};
        assign expanded_PI_RdFIFO_RdWdAddr[4*C_PIX_RDWDADDR_WIDTH_MAX +:
                                  C_PIX_RDWDADDR_WIDTH_MAX]            = {C_PIX_RDWDADDR_WIDTH_MAX{1'b0}};
        assign expanded_PI_WrFIFO_Empty[4]                             = 1'b1;
        assign expanded_PI_WrFIFO_AlmostFull[4]                        = 1'b0;
        assign expanded_PI_RdFIFO_Empty[4]                             = 1'b1;
        assign expanded_PI_InitDone[4]                                 = uo_done_cal;
      end
    else if (C_NUM_PORTS > 0 && C_PIM4_BASETYPE != 0)
      begin : NPI_BRIDGE_INST_4
        mpmc_npi2mcb #
          (
           .C_PI_ADDR_WIDTH             (C_PIX_ADDR_WIDTH_MAX),
           .C_PI_BASETYPE               (C_PIM4_BASETYPE),
           .C_PI_DATA_WIDTH             (32),
           .C_PI_BE_WIDTH               (4),
           .C_PI_RDWDADDR_WIDTH         (C_PIX_RDWDADDR_WIDTH_MAX)
           )
          mpmc_npi2mcb_4
            (
             .Clk_MPMC                  (Clk0),
             .Rst_MPMC                  (Rst),
  
             .PI_Addr                   (expanded_PI_Addr[4*C_PIX_ADDR_WIDTH_MAX +: C_PIX_ADDR_WIDTH_MAX]),
             .PI_AddrReq                (expanded_PI_AddrReq[4]),
             .PI_AddrAck                (expanded_PI_AddrAck[4]),
             .PI_RNW                    (expanded_PI_RNW[4]),
             .PI_RdModWr                (expanded_PI_RdModWr[4]),
             .PI_Size                   (expanded_PI_Size[(4+1)*4-1:4*4]),
             .PI_InitDone               (expanded_PI_InitDone[4]),
             .PI_WrFIFO_Data            (expanded_PI_WrFIFO_Data[4*C_PIX_DATA_WIDTH_MAX +: 32]),
             .PI_WrFIFO_BE              (expanded_PI_WrFIFO_BE[4*C_PIX_BE_WIDTH_MAX +: (C_PI_DATA_WIDTH[4]?8:4)]),
             .PI_WrFIFO_Push            (expanded_PI_WrFIFO_Push[4]),
             .PI_RdFIFO_Data            (expanded_PI_RdFIFO_Data[4*C_PIX_DATA_WIDTH_MAX +: 32]),
             .PI_RdFIFO_Pop             (expanded_PI_RdFIFO_Pop[4]),
             .PI_RdFIFO_RdWdAddr        (expanded_PI_RdFIFO_RdWdAddr[4*C_PIX_RDWDADDR_WIDTH_MAX +:
                                                            C_PIX_RDWDADDR_WIDTH_MAX]),
             .PI_WrFIFO_AlmostFull      (expanded_PI_WrFIFO_AlmostFull[4]),
             .PI_WrFIFO_Flush           (expanded_PI_WrFIFO_Flush[4]),
             .PI_WrFIFO_Empty           (expanded_PI_WrFIFO_Empty[4]),
             .PI_RdFIFO_Empty           (expanded_PI_RdFIFO_Empty[4]),
             .PI_RdFIFO_Flush           (expanded_PI_RdFIFO_Flush[4]),
             .PI_Error                  (), // Not used
            
             ///////////////////////////////////////
             
             .MCB_cmd_clk               (p4_cmd_clk_i),
             .MCB_cmd_en                (p4_cmd_en_i),
             .MCB_cmd_instr             (p4_cmd_instr_i),
             .MCB_cmd_bl                (p4_cmd_bl_i),
             .MCB_cmd_byte_addr         (p4_cmd_byte_addr_i),
             .MCB_cmd_empty             (p4_cmd_empty_i),
             .MCB_cmd_full              (p4_cmd_full_i),
            
             ///////////////////////////////////////
            
             .MCB_wr_clk                (p4_wr_clk_i),
             .MCB_wr_en                 (p4_wr_en_i),
             .MCB_wr_mask               (p4_wr_mask_i),
             .MCB_wr_data               (p4_wr_data_i),
             .MCB_wr_full               (p4_wr_full_i),
             .MCB_wr_empty              (p4_wr_empty_i),
             .MCB_wr_count              (p4_wr_count_i),
             .MCB_wr_underrun           (p4_wr_underrun_i),
             .MCB_wr_error              (p4_wr_error_i),
            
             .MCB_rd_clk                (p4_rd_clk_i),
             .MCB_rd_en                 (p4_rd_en_i),
             .MCB_rd_data               (p4_rd_data_i),
             .MCB_rd_full               (p4_rd_full_i),
             .MCB_rd_empty              (p4_rd_empty_i),
             .MCB_rd_count              (p4_rd_count_i),
             .MCB_rd_overflow           (p4_rd_overflow_i),
             .MCB_rd_error              (p4_rd_error_i),
             .MCB_calib_done            (uo_done_cal_d2)
             );
      end
    else
      begin : TIE_OFF_4
        // External native MCB port tie-off.
        assign MCB4_cmd_empty    = 1'b0;
        assign MCB4_cmd_full     = 1'b0;
        assign MCB4_wr_full      = 1'b0;
        assign MCB4_wr_empty     = 1'b0;
        assign MCB4_wr_count     = 7'b0;
        assign MCB4_wr_underrun  = 1'b0;
        assign MCB4_wr_error     = 1'b0;
        assign MCB4_rd_data      = 32'b0;
        assign MCB4_rd_full      = 1'b0;
        assign MCB4_rd_empty     = 1'b0;
        assign MCB4_rd_count     = 7'b0;
        assign MCB4_rd_overflow  = 1'b0;
        assign MCB4_rd_error     = 1'b0;
        
        // Internal MCB tie-offs.
        assign p4_cmd_clk_i        = 1'b0;
        assign p4_cmd_en_i         = 1'b0;
        assign p4_cmd_instr_i      = 3'b0;
        assign p4_cmd_bl_i         = 6'b0;
        assign p4_cmd_byte_addr_i  = 30'b0;
        assign p4_wr_clk_i         = 1'b0;
        assign p4_wr_en_i          = 1'b0;
        assign p4_wr_mask_i        = 4'b0;
        assign p4_wr_data_i        = 32'b0;
        assign p4_rd_clk_i         = 1'b0;
        assign p4_rd_en_i          = 1'b0;
      end
  endgenerate
    
  generate
    if (C_NUM_PORTS > 5 && (C_PIM5_BASETYPE == 8) || (C_PIM5_BASETYPE == 9))
      begin : NATIVE_MCB_INST_5
        assign p5_cmd_clk_i       = MCB5_cmd_clk;
        assign p5_cmd_en_i        = MCB5_cmd_en;
        assign p5_cmd_instr_i     = MCB5_cmd_instr;
        assign p5_cmd_bl_i        = MCB5_cmd_bl;
        assign p5_cmd_byte_addr_i = MCB5_cmd_byte_addr;
        assign MCB5_cmd_empty     = p5_cmd_empty_i;
        assign MCB5_cmd_full      = p5_cmd_full_i;
        
        assign p5_wr_clk_i        = MCB5_wr_clk;
        assign p5_wr_en_i         = MCB5_wr_en;
        assign p5_wr_mask_i       = MCB5_wr_mask;
        assign p5_wr_data_i       = MCB5_wr_data;
        assign MCB5_wr_full       = p5_wr_full_i;
        assign MCB5_wr_empty      = p5_wr_empty_i;
        assign MCB5_wr_count      = p5_wr_count_i;
        assign MCB5_wr_underrun   = p5_wr_underrun_i;
        assign MCB5_wr_error      = p5_wr_error_i;
        
        assign p5_rd_clk_i        = MCB5_rd_clk;
        assign p5_rd_en_i         = MCB5_rd_en;
        assign MCB5_rd_data       = p5_rd_data_i;
        assign MCB5_rd_full       = p5_rd_full_i;
        assign MCB5_rd_empty      = p5_rd_empty_i;
        assign MCB5_rd_count      = p5_rd_count_i;
        assign MCB5_rd_overflow   = p5_rd_overflow_i;
        assign MCB5_rd_error      = p5_rd_error_i;
        
        assign expanded_PI_AddrAck[5]                                  = 1'b0;
        assign expanded_PI_RdFIFO_Data[5*C_PIX_DATA_WIDTH_MAX +: 
                              (C_PI_DATA_WIDTH[5]?64:32)]              = {(C_PI_DATA_WIDTH[5]?64:32){1'b0}};
        assign expanded_PI_RdFIFO_RdWdAddr[5*C_PIX_RDWDADDR_WIDTH_MAX +:
                                  C_PIX_RDWDADDR_WIDTH_MAX]            = {C_PIX_RDWDADDR_WIDTH_MAX{1'b0}};
        assign expanded_PI_WrFIFO_Empty[5]                             = 1'b1;
        assign expanded_PI_WrFIFO_AlmostFull[5]                        = 1'b0;
        assign expanded_PI_RdFIFO_Empty[5]                             = 1'b1;
        assign expanded_PI_InitDone[5]                                 = uo_done_cal;
      end
    else if (C_NUM_PORTS > 0 && C_PIM5_BASETYPE != 0)
      begin : NPI_BRIDGE_INST_5
        mpmc_npi2mcb #
          (
           .C_PI_ADDR_WIDTH             (C_PIX_ADDR_WIDTH_MAX),
           .C_PI_BASETYPE               (C_PIM5_BASETYPE),
           .C_PI_DATA_WIDTH             (32),
           .C_PI_BE_WIDTH               (4),
           .C_PI_RDWDADDR_WIDTH         (C_PIX_RDWDADDR_WIDTH_MAX)
           )
          mpmc_npi2mcb_5
            (
             .Clk_MPMC                  (Clk0),
             .Rst_MPMC                  (Rst),
  
             .PI_Addr                   (expanded_PI_Addr[5*C_PIX_ADDR_WIDTH_MAX +: C_PIX_ADDR_WIDTH_MAX]),
             .PI_AddrReq                (expanded_PI_AddrReq[5]),
             .PI_AddrAck                (expanded_PI_AddrAck[5]),
             .PI_RNW                    (expanded_PI_RNW[5]),
             .PI_RdModWr                (expanded_PI_RdModWr[5]),
             .PI_Size                   (expanded_PI_Size[(5+1)*4-1:5*4]),
             .PI_InitDone               (expanded_PI_InitDone[5]),
             .PI_WrFIFO_Data            (expanded_PI_WrFIFO_Data[5*C_PIX_DATA_WIDTH_MAX +: 32]),
             .PI_WrFIFO_BE              (expanded_PI_WrFIFO_BE[5*C_PIX_BE_WIDTH_MAX +: 4]),
             .PI_WrFIFO_Push            (expanded_PI_WrFIFO_Push[5]),
             .PI_RdFIFO_Data            (expanded_PI_RdFIFO_Data[5*C_PIX_DATA_WIDTH_MAX +: 32]),
             .PI_RdFIFO_Pop             (expanded_PI_RdFIFO_Pop[5]),
             .PI_RdFIFO_RdWdAddr        (expanded_PI_RdFIFO_RdWdAddr[5*C_PIX_RDWDADDR_WIDTH_MAX +:
                                                            C_PIX_RDWDADDR_WIDTH_MAX]),
             .PI_WrFIFO_AlmostFull      (expanded_PI_WrFIFO_AlmostFull[5]),
             .PI_WrFIFO_Flush           (expanded_PI_WrFIFO_Flush[5]),
             .PI_WrFIFO_Empty           (expanded_PI_WrFIFO_Empty[5]),
             .PI_RdFIFO_Empty           (expanded_PI_RdFIFO_Empty[5]),
             .PI_RdFIFO_Flush           (expanded_PI_RdFIFO_Flush[5]),
             .PI_Error                  (), // Not used
            
             ///////////////////////////////////////
             
             .MCB_cmd_clk               (p5_cmd_clk_i),
             .MCB_cmd_en                (p5_cmd_en_i),
             .MCB_cmd_instr             (p5_cmd_instr_i),
             .MCB_cmd_bl                (p5_cmd_bl_i),
             .MCB_cmd_byte_addr         (p5_cmd_byte_addr_i),
             .MCB_cmd_empty             (p5_cmd_empty_i),
             .MCB_cmd_full              (p5_cmd_full_i),
            
             ///////////////////////////////////////
            
             .MCB_wr_clk                (p5_wr_clk_i),
             .MCB_wr_en                 (p5_wr_en_i),
             .MCB_wr_mask               (p5_wr_mask_i),
             .MCB_wr_data               (p5_wr_data_i),
             .MCB_wr_full               (p5_wr_full_i),
             .MCB_wr_empty              (p5_wr_empty_i),
             .MCB_wr_count              (p5_wr_count_i),
             .MCB_wr_underrun           (p5_wr_underrun_i),
             .MCB_wr_error              (p5_wr_error_i),
            
             .MCB_rd_clk                (p5_rd_clk_i),
             .MCB_rd_en                 (p5_rd_en_i),
             .MCB_rd_data               (p5_rd_data_i),
             .MCB_rd_full               (p5_rd_full_i),
             .MCB_rd_empty              (p5_rd_empty_i),
             .MCB_rd_count              (p5_rd_count_i),
             .MCB_rd_overflow           (p5_rd_overflow_i),
             .MCB_rd_error              (p5_rd_error_i),
             .MCB_calib_done            (uo_done_cal_d2)
             );
      end
    else
      begin : TIE_OFF_5
        // External native MCB port tie-off.
        assign MCB5_cmd_empty    = 1'b0;
        assign MCB5_cmd_full     = 1'b0;
        assign MCB5_wr_full      = 1'b0;
        assign MCB5_wr_empty     = 1'b0;
        assign MCB5_wr_count     = 7'b0;
        assign MCB5_wr_underrun  = 1'b0;
        assign MCB5_wr_error     = 1'b0;
        assign MCB5_rd_data      = 32'b0;
        assign MCB5_rd_full      = 1'b0;
        assign MCB5_rd_empty     = 1'b0;
        assign MCB5_rd_count     = 7'b0;
        assign MCB5_rd_overflow  = 1'b0;
        assign MCB5_rd_error     = 1'b0;
        
        // Internal MCB tie-offs.
        assign p5_cmd_clk_i        = 1'b0;
        assign p5_cmd_en_i         = 1'b0;
        assign p5_cmd_instr_i      = 3'b0;
        assign p5_cmd_bl_i         = 6'b0;
        assign p5_cmd_byte_addr_i  = 30'b0;
        assign p5_wr_clk_i         = 1'b0;
        assign p5_wr_en_i          = 1'b0;
        assign p5_wr_mask_i        = 4'b0;
        assign p5_wr_data_i        = 32'b0;
        assign p5_rd_clk_i         = 1'b0;
        assign p5_rd_en_i          = 1'b0;
      end
  endgenerate
    
  // Instantiate Hard memeory controller wrapper.
  mcb_raw_wrapper #
    (
     .C_MEMCLK_PERIOD             (C_MPMC_CLK_MEM_2X_PERIOD_PS * 2),
     .C_PORT_ENABLE               (P_PORT_ENABLE),
     .C_MEM_ADDR_ORDER            (C_MEM_ADDR_ORDER),
     .C_USR_INTERFACE_MODE        (P_USR_INTERFACE_MODE),
     .C_ARB_NUM_TIME_SLOTS        (P_ARB0_NUM_SLOTS),
     .C_ARB_TIME_SLOT_0           (P_ARB_TIME_SLOT_0),
     .C_ARB_TIME_SLOT_1           (P_ARB_TIME_SLOT_1),
     .C_ARB_TIME_SLOT_2           (P_ARB_TIME_SLOT_2),
     .C_ARB_TIME_SLOT_3           (P_ARB_TIME_SLOT_3),
     .C_ARB_TIME_SLOT_4           (P_ARB_TIME_SLOT_4),
     .C_ARB_TIME_SLOT_5           (P_ARB_TIME_SLOT_5),
     .C_ARB_TIME_SLOT_6           (P_ARB_TIME_SLOT_6),
     .C_ARB_TIME_SLOT_7           (P_ARB_TIME_SLOT_7),
     .C_ARB_TIME_SLOT_8           (P_ARB_TIME_SLOT_8),
     .C_ARB_TIME_SLOT_9           (P_ARB_TIME_SLOT_9),
     .C_ARB_TIME_SLOT_10          (P_ARB_TIME_SLOT_10),
     .C_ARB_TIME_SLOT_11          (P_ARB_TIME_SLOT_11),
     .C_PORT_CONFIG               (P_PORT_CONFIG),
     .C_MEM_TRAS                  (C_MEM_PART_TRAS),
     .C_MEM_TRCD                  (C_MEM_PART_TRCD),
     .C_MEM_TREFI                 (C_MEM_PART_TREFI),
     .C_MEM_TRFC                  (C_MEM_PART_TRFC),
     .C_MEM_TRP                   (C_MEM_PART_TRP),
     .C_MEM_TWR                   (C_MEM_PART_TWR),
     .C_MEM_TRTP                  (C_MEM_PART_TRTP),
     .C_MEM_TWTR                  (C_MEM_PART_TWTR),
     .C_NUM_DQ_PINS               (C_MEM_DATA_WIDTH),
     .C_MEM_TYPE                  (P_MEM_TYPE),
     .C_MEM_BURST_LEN             (C_MEM_BURST_LENGTH),
     .C_MEM_CAS_LATENCY           (C_MEM_CAS_LATENCY0),
     .C_MEM_ADDR_WIDTH            (C_MEM_ADDR_WIDTH),
     .C_MEM_BANKADDR_WIDTH        (C_MEM_BANKADDR_WIDTH),
     .C_MEM_NUM_COL_BITS          (C_MEM_PART_NUM_COL_BITS),
     
     .C_MEM_DDR3_CAS_LATENCY      (P_MEM_DDR3_CAS_LATENCY),
     .C_MEM_MOBILE_PA_SR          (P_MEM_MOBILE_PA_SR),
     .C_MEM_DDR1_2_ODS            (P_MEM_DDR1_2_ODS),
     .C_MEM_DDR3_ODS              (P_MEM_DDR3_ODS),
     .C_MEM_DDR2_RTT              (P_MEM_DDR2_RTT),
     .C_MEM_DDR3_RTT              (P_MEM_DDR3_RTT),
     .C_MEM_MDDR_ODS              (P_MEM_MDDR_ODS),
     .C_MEM_DDR2_DIFF_DQS_EN      (P_MEM_DDR2_DIFF_DQS_EN),
     .C_MEM_DDR2_3_PA_SR          (P_MEM_DDR2_3_PA_SR),
     .C_MEM_DDR3_CAS_WR_LATENCY   (P_MEM_DDR3_CAS_WR_LATENCY),
     .C_MEM_DDR3_AUTO_SR          (P_MEM_DDR3_AUTO_SR),
     .C_MEM_DDR2_3_HIGH_TEMP_SR   (P_MEM_DDR2_3_HIGH_TEMP_SR),
     .C_MEM_DDR3_DYN_WRT_ODT      (P_MEM_DDR3_DYN_WRT_ODT),

     .C_CALIB_SOFT_IP             (C_MEM_CALIBRATION_SOFT_IP),
     .C_SKIP_IN_TERM_CAL          (C_MEM_SKIP_IN_TERM_CAL),
     .C_SKIP_DYNAMIC_CAL          (C_MEM_SKIP_DYNAMIC_CAL),
     .C_SKIP_DYN_IN_TERM          (C_MEM_SKIP_DYN_IN_TERM),
     .C_MC_CALIB_BYPASS           (C_MEM_CALIBRATION_BYPASS),
     .C_MEM_TZQINIT_MAXCNT        (P_MEM_TZQINIT_MAXCNT),
     .C_MC_CALIBRATION_RA         (P_MEM_CALIBRATION_RA),
     .C_MC_CALIBRATION_BA         (P_MEM_CALIBRATION_BA),
     .C_MC_CALIBRATION_CA         (P_MEM_CALIBRATION_CA),
     .C_MC_CALIBRATION_MODE       (P_MEM_CALIBRATION_MODE),
     .C_MC_CALIBRATION_DELAY      (C_MEM_CALIBRATION_DELAY),
     .C_SIMULATION                (C_SIMULATION),
     .C_P0_MASK_SIZE              (C_P0_DATA_PORT_SIZE / 8),
     .C_P0_DATA_PORT_SIZE         (C_P0_DATA_PORT_SIZE),
     .C_P1_MASK_SIZE              (C_P1_DATA_PORT_SIZE / 8),
     .C_P1_DATA_PORT_SIZE         (C_P1_DATA_PORT_SIZE),
  
     .LDQSP_TAP_DELAY_VAL         (C_MCB_LDQSP_TAP_DELAY_VAL),  // 0 to 255 inclusive
     .UDQSP_TAP_DELAY_VAL         (C_MCB_UDQSP_TAP_DELAY_VAL),  // 0 to 255 inclusive
     .LDQSN_TAP_DELAY_VAL         (C_MCB_LDQSN_TAP_DELAY_VAL),  // 0 to 255 inclusive
     .UDQSN_TAP_DELAY_VAL         (C_MCB_UDQSN_TAP_DELAY_VAL),  // 0 to 255 inclusive
     .DQ0_TAP_DELAY_VAL           (C_MCB_DQ0_TAP_DELAY_VAL),  // 0 to 255 inclusive
     .DQ1_TAP_DELAY_VAL           (C_MCB_DQ1_TAP_DELAY_VAL),  // 0 to 255 inclusive
     .DQ2_TAP_DELAY_VAL           (C_MCB_DQ2_TAP_DELAY_VAL),  // 0 to 255 inclusive
     .DQ3_TAP_DELAY_VAL           (C_MCB_DQ3_TAP_DELAY_VAL),  // 0 to 255 inclusive
     .DQ4_TAP_DELAY_VAL           (C_MCB_DQ4_TAP_DELAY_VAL),  // 0 to 255 inclusive
     .DQ5_TAP_DELAY_VAL           (C_MCB_DQ5_TAP_DELAY_VAL),  // 0 to 255 inclusive
     .DQ6_TAP_DELAY_VAL           (C_MCB_DQ6_TAP_DELAY_VAL),  // 0 to 255 inclusive
     .DQ7_TAP_DELAY_VAL           (C_MCB_DQ7_TAP_DELAY_VAL),  // 0 to 255 inclusive
     .DQ8_TAP_DELAY_VAL           (C_MCB_DQ8_TAP_DELAY_VAL),  // 0 to 255 inclusive
     .DQ9_TAP_DELAY_VAL           (C_MCB_DQ9_TAP_DELAY_VAL),  // 0 to 255 inclusive
     .DQ10_TAP_DELAY_VAL          (C_MCB_DQ10_TAP_DELAY_VAL),  // 0 to 255 inclusive
     .DQ11_TAP_DELAY_VAL          (C_MCB_DQ11_TAP_DELAY_VAL),  // 0 to 255 inclusive
     .DQ12_TAP_DELAY_VAL          (C_MCB_DQ12_TAP_DELAY_VAL),  // 0 to 255 inclusive
     .DQ13_TAP_DELAY_VAL          (C_MCB_DQ13_TAP_DELAY_VAL),  // 0 to 255 inclusive
     .DQ14_TAP_DELAY_VAL          (C_MCB_DQ14_TAP_DELAY_VAL),  // 0 to 255 inclusive
     .DQ15_TAP_DELAY_VAL          (C_MCB_DQ15_TAP_DELAY_VAL)  // 0 to 255 inclusive
     )
    mpmc_mcb_raw_wrapper_0
      (
       .sysclk_2x         (sysclk_2x),
       .sysclk_2x_180     (sysclk_2x_180),
       .pll_ce_0          (pll_ce_0),
       .pll_ce_90         (pll_ce_90),
       .pll_lock          (pll_lock),
       .sys_rst           (rst_d2),
      
       //****************************
       //User Port0 Interface Signals
            
       // cmd port signals
       .p0_arb_en         (1'b1),
       .p0_cmd_clk        (p0_cmd_clk_i),
       .p0_cmd_en         (p0_cmd_en_i),
       .p0_cmd_instr      (p0_cmd_instr_i),
       .p0_cmd_bl         (p0_cmd_bl_i),
       .p0_cmd_byte_addr  (p0_cmd_byte_addr_i),
       .p0_cmd_empty      (p0_cmd_empty_i),
       .p0_cmd_full       (p0_cmd_full_i),
      
       // Data Wr Port signals
       .p0_wr_clk         (p0_wr_clk_i),
       .p0_wr_en          (p0_wr_en_i),
       .p0_wr_mask        (p0_wr_mask_i),
       .p0_wr_data        (p0_wr_data_i),
       .p0_wr_full        (p0_wr_full_i),
       .p0_wr_empty       (p0_wr_empty_i),
       .p0_wr_count       (p0_wr_count_i),
       .p0_wr_underrun    (p0_wr_underrun_i),
       .p0_wr_error       (p0_wr_error_i),
      
       //Data Rd Port signals
       .p0_rd_clk         (p0_rd_clk_i),
       .p0_rd_en          (p0_rd_en_i),
       .p0_rd_data        (p0_rd_data_i),
       .p0_rd_full        (p0_rd_full_i),
       .p0_rd_empty       (p0_rd_empty_i),
       .p0_rd_count       (p0_rd_count_i),
       .p0_rd_overflow    (p0_rd_overflow_i),
       .p0_rd_error       (p0_rd_error_i),
      
       //****************************
       //User Port1 Interface Signals
            
       // cmd port signals
       .p1_arb_en         (1'b1),
       .p1_cmd_clk        (p1_cmd_clk_i),
       .p1_cmd_en         (p1_cmd_en_i),
       .p1_cmd_instr      (p1_cmd_instr_i),
       .p1_cmd_bl         (p1_cmd_bl_i),
       .p1_cmd_byte_addr  (p1_cmd_byte_addr_i),
       .p1_cmd_empty      (p1_cmd_empty_i),
       .p1_cmd_full       (p1_cmd_full_i),
      
       // Data Wr Port signals
       .p1_wr_clk         (p1_wr_clk_i),
       .p1_wr_en          (p1_wr_en_i),
       .p1_wr_mask        (p1_wr_mask_i),
       .p1_wr_data        (p1_wr_data_i),
       .p1_wr_full        (p1_wr_full_i),
       .p1_wr_empty       (p1_wr_empty_i),
       .p1_wr_count       (p1_wr_count_i),
       .p1_wr_underrun    (p1_wr_underrun_i),
       .p1_wr_error       (p1_wr_error_i),
      
       //Data Rd Port signals
       .p1_rd_clk         (p1_rd_clk_i),
       .p1_rd_en          (p1_rd_en_i),
       .p1_rd_data        (p1_rd_data_i),
       .p1_rd_full        (p1_rd_full_i),
       .p1_rd_empty       (p1_rd_empty_i),
       .p1_rd_count       (p1_rd_count_i),
       .p1_rd_overflow    (p1_rd_overflow_i),
       .p1_rd_error       (p1_rd_error_i),
      
       //****************************
       //User Port2 Interface Signals
            
       // cmd port signals
       .p2_arb_en         (1'b1),
       .p2_cmd_clk        (p2_cmd_clk_i),
       .p2_cmd_en         (p2_cmd_en_i),
       .p2_cmd_instr      (p2_cmd_instr_i),
       .p2_cmd_bl         (p2_cmd_bl_i),
       .p2_cmd_byte_addr  (p2_cmd_byte_addr_i),
       .p2_cmd_empty      (p2_cmd_empty_i),
       .p2_cmd_full       (p2_cmd_full_i),
      
       // Data Wr Port signals
       .p2_wr_clk         (p2_wr_clk_i),
       .p2_wr_en          (p2_wr_en_i),
       .p2_wr_mask        (p2_wr_mask_i),
       .p2_wr_data        (p2_wr_data_i),
       .p2_wr_full        (p2_wr_full_i),
       .p2_wr_empty       (p2_wr_empty_i),
       .p2_wr_count       (p2_wr_count_i),
       .p2_wr_underrun    (p2_wr_underrun_i),
       .p2_wr_error       (p2_wr_error_i),
      
       //Data Rd Port signals
       .p2_rd_clk         (p2_rd_clk_i),
       .p2_rd_en          (p2_rd_en_i),
       .p2_rd_data        (p2_rd_data_i),
       .p2_rd_full        (p2_rd_full_i),
       .p2_rd_empty       (p2_rd_empty_i),
       .p2_rd_count       (p2_rd_count_i),
       .p2_rd_overflow    (p2_rd_overflow_i),
       .p2_rd_error       (p2_rd_error_i),
      
       //****************************
       //User Port3 Interface Signals
            
       // cmd port signals
       .p3_arb_en         (1'b1),
       .p3_cmd_clk        (p3_cmd_clk_i),
       .p3_cmd_en         (p3_cmd_en_i),
       .p3_cmd_instr      (p3_cmd_instr_i),
       .p3_cmd_bl         (p3_cmd_bl_i),
       .p3_cmd_byte_addr  (p3_cmd_byte_addr_i),
       .p3_cmd_empty      (p3_cmd_empty_i),
       .p3_cmd_full       (p3_cmd_full_i),
      
       // Data Wr Port signals
       .p3_wr_clk         (p3_wr_clk_i),
       .p3_wr_en          (p3_wr_en_i),
       .p3_wr_mask        (p3_wr_mask_i),
       .p3_wr_data        (p3_wr_data_i),
       .p3_wr_full        (p3_wr_full_i),
       .p3_wr_empty       (p3_wr_empty_i),
       .p3_wr_count       (p3_wr_count_i),
       .p3_wr_underrun    (p3_wr_underrun_i),
       .p3_wr_error       (p3_wr_error_i),
      
       //Data Rd Port signals
       .p3_rd_clk         (p3_rd_clk_i),
       .p3_rd_en          (p3_rd_en_i),
       .p3_rd_data        (p3_rd_data_i),
       .p3_rd_full        (p3_rd_full_i),
       .p3_rd_empty       (p3_rd_empty_i),
       .p3_rd_count       (p3_rd_count_i),
       .p3_rd_overflow    (p3_rd_overflow_i),
       .p3_rd_error       (p3_rd_error_i),
      
       //****************************
       //User Port4 Interface Signals
            
       // cmd port signals
       .p4_arb_en         (1'b1),
       .p4_cmd_clk        (p4_cmd_clk_i),
       .p4_cmd_en         (p4_cmd_en_i),
       .p4_cmd_instr      (p4_cmd_instr_i),
       .p4_cmd_bl         (p4_cmd_bl_i),
       .p4_cmd_byte_addr  (p4_cmd_byte_addr_i),
       .p4_cmd_empty      (p4_cmd_empty_i),
       .p4_cmd_full       (p4_cmd_full_i),
      
       // Data Wr Port signals
       .p4_wr_clk         (p4_wr_clk_i),
       .p4_wr_en          (p4_wr_en_i),
       .p4_wr_mask        (p4_wr_mask_i),
       .p4_wr_data        (p4_wr_data_i),
       .p4_wr_full        (p4_wr_full_i),
       .p4_wr_empty       (p4_wr_empty_i),
       .p4_wr_count       (p4_wr_count_i),
       .p4_wr_underrun    (p4_wr_underrun_i),
       .p4_wr_error       (p4_wr_error_i),
      
       //Data Rd Port signals
       .p4_rd_clk         (p4_rd_clk_i),
       .p4_rd_en          (p4_rd_en_i),
       .p4_rd_data        (p4_rd_data_i),
       .p4_rd_full        (p4_rd_full_i),
       .p4_rd_empty       (p4_rd_empty_i),
       .p4_rd_count       (p4_rd_count_i),
       .p4_rd_overflow    (p4_rd_overflow_i),
       .p4_rd_error       (p4_rd_error_i),
      
       //****************************
       //User Port5 Interface Signals
            
       // cmd port signals
       .p5_arb_en         (1'b1),
       .p5_cmd_clk        (p5_cmd_clk_i),
       .p5_cmd_en         (p5_cmd_en_i),
       .p5_cmd_instr      (p5_cmd_instr_i),
       .p5_cmd_bl         (p5_cmd_bl_i),
       .p5_cmd_byte_addr  (p5_cmd_byte_addr_i),
       .p5_cmd_empty      (p5_cmd_empty_i),
       .p5_cmd_full       (p5_cmd_full_i),
      
       // Data Wr Port signals
       .p5_wr_clk         (p5_wr_clk_i),
       .p5_wr_en          (p5_wr_en_i),
       .p5_wr_mask        (p5_wr_mask_i),
       .p5_wr_data        (p5_wr_data_i),
       .p5_wr_full        (p5_wr_full_i),
       .p5_wr_empty       (p5_wr_empty_i),
       .p5_wr_count       (p5_wr_count_i),
       .p5_wr_underrun    (p5_wr_underrun_i),
       .p5_wr_error       (p5_wr_error_i),
      
       //Data Rd Port signals
       .p5_rd_clk         (p5_rd_clk_i),
       .p5_rd_en          (p5_rd_en_i),
       .p5_rd_data        (p5_rd_data_i),
       .p5_rd_full        (p5_rd_full_i),
       .p5_rd_empty       (p5_rd_empty_i),
       .p5_rd_count       (p5_rd_count_i),
       .p5_rd_overflow    (p5_rd_overflow_i),
       .p5_rd_error       (p5_rd_error_i),
      
       //*****************************************************
       // memory interface signals    
       .mcbx_dram_addr      (mcbx_dram_addr),
       .mcbx_dram_ba        (mcbx_dram_ba),
       .mcbx_dram_ras_n     (mcbx_dram_ras_n),
       .mcbx_dram_cas_n     (mcbx_dram_cas_n),
       .mcbx_dram_we_n      (mcbx_dram_we_n),
      
       .mcbx_dram_cke       (mcbx_dram_cke),
       .mcbx_dram_clk       (mcbx_dram_clk),
       .mcbx_dram_clk_n     (mcbx_dram_clk_n),
       .mcbx_dram_dq        (mcbx_dram_dq),
       .mcbx_dram_dqs       (mcbx_dram_dqs),
       .mcbx_dram_dqs_n     (mcbx_dram_dqs_n),
       .mcbx_dram_udqs      (mcbx_dram_udqs),
       .mcbx_dram_udqs_n    (mcbx_dram_udqs_n),
      
       .mcbx_dram_udm       (mcbx_dram_udm),
       .mcbx_dram_ldm       (mcbx_dram_ldm),
       .mcbx_dram_odt       (mcbx_dram_odt),
       .mcbx_dram_ddr3_rst  (mcbx_dram_ddr3_rst),
       
       // Calibration signals
       .calib_recal       (calib_recal),
       .rzq               (rzq),
       .zio               (zio),
      
       // these signals are for dynamic Calibration IP
       .ui_read           (1'b0),
       .ui_add            (1'b0),
       .ui_cs             (1'b0),
       .ui_clk            (ui_clk),
       .ui_sdi            (1'b0),
       .ui_addr           (5'b0),
       .ui_broadcast      (1'b0),
       .ui_drp_update     (1'b0),
       .ui_done_cal       (1'b1),
       .ui_cmd            (1'b0),
       .ui_cmd_in         (1'b0),
       .ui_cmd_en         (1'b0),
       .ui_dqcount        (4'b0),
       .ui_dq_lower_dec   (1'b0),
       .ui_dq_lower_inc   (1'b0),
       .ui_dq_upper_dec   (1'b0),
       .ui_dq_upper_inc   (1'b0),
       .ui_udqs_inc       (1'b0),
       .ui_udqs_dec       (1'b0),
       .ui_ldqs_inc       (1'b0),
       .ui_ldqs_dec       (1'b0),
       .uo_data           (),
       .uo_data_valid     (),
       .uo_done_cal       (uo_done_cal),
       .uo_cmd_ready_in   (),
       .uo_refrsh_flag    (),
       .uo_cal_start      (),
       .uo_sdo            (),
       .status            (),
       .selfrefresh_enter (selfrefresh_enter),
       .selfrefresh_mode  (selfrefresh_mode)
       );  
      
   
endmodule // s6_phy_top

`default_nettype wire
