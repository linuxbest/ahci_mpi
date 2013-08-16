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

module mpmc_core
#(
  parameter C_FAMILY                          = "virtex4",
  parameter C_USE_MIG_S3_PHY                  = 1'b0,
  parameter C_USE_MIG_V4_PHY                  = 1'b0,
  parameter C_USE_MIG_V5_PHY                  = 1'b0,
  parameter C_USE_MIG_V6_PHY                  = 1'b0,
  parameter C_USE_MCB_S6_PHY                  = 1'b0,
  parameter C_IODELAY_GRP                     = "NOT_SET",
  parameter C_SPEEDGRADE_INT                  = 2,
  parameter C_MEM_TYPE                        = "INVALID",
  parameter C_SKIP_INIT_DELAY                 = 1'b0,
  parameter C_FAST_CALIBRATION                = 1'b0,
  parameter C_MMCM_ADV_PS_WA                  = "ON",
  parameter C_DEBUG_REG_ENABLE                = 1'b0,
  parameter C_USE_STATIC_PHY                  = 1'b0,
  parameter C_STATIC_PHY_RDDATA_CLK_SEL       = 1'b0,
  parameter C_STATIC_PHY_RDDATA_SWAP_RISE     = 1'b0,
  parameter C_STATIC_PHY_RDEN_DELAY           = 4'h0,
  parameter C_PORT_CONFIG                     = 1,
  parameter C_MEM_PART_NUM_COL_BITS           = 0,
  parameter C_ARB0_NUM_SLOTS                  = 0,
  parameter C_MEM_ADDR_ORDER                  = "BANK_ROW_COLUMN",
  parameter C_MEM_CALIBRATION_MODE            = 1,
  parameter C_MEM_CALIBRATION_DELAY           = "HALF",
  parameter C_MEM_CALIBRATION_SOFT_IP         = "TRUE",
  parameter C_MEM_SKIP_IN_TERM_CAL            = 1'b1,
  parameter C_MEM_SKIP_DYNAMIC_CAL            = 1'b1,
  parameter C_MEM_SKIP_DYN_IN_TERM            = 1'b1,
  parameter C_MEM_CALIBRATION_BYPASS          = "NO",
  parameter C_MCB_DRP_CLK_PRESENT             = 0,
  parameter C_MEM_TZQINIT_MAXCNT              = 10'h200,
  parameter C_MPMC_CLK_MEM_2X_PERIOD_PS       = 1,
  parameter C_MCB_USE_EXTERNAL_BUFPLL         = 0,
  parameter C_INCLUDE_ECC_SUPPORT             = 0,
  parameter C_INCLUDE_ECC_TEST                = 1,
  parameter C_ECC_DEFAULT_ON                  = 1,
  parameter C_ECC_SEC_THRESHOLD               = 1,
  parameter C_ECC_DEC_THRESHOLD               = 1,
  parameter C_ECC_PEC_THRESHOLD               = 1,
  parameter C_IS_DDR                          = 1'b1,     // Allowed Values: 0,1
  parameter C_SPECIAL_BOARD                   = 0,
  parameter C_NUM_PORTS                       = 8,        // Allowed Values: 1-8
  parameter C_MEM_PA_SR                       = "FULL",
  parameter C_MEM_CAS_WR_LATENCY              = 5,
  parameter C_MEM_AUTO_SR                     = "ENABLED",
  parameter C_MEM_HIGH_TEMP_SR                = "NORMAL",
  parameter C_MEM_DYNAMIC_WRITE_ODT           = "OFF",
  parameter C_MEM_WRLVL                       = 0,
  parameter C_IDELAY_CLK_FREQ                 = "DEFAULT",
  parameter C_MEM_PHASE_DETECT                = "DEFAULT",
  parameter C_MEM_IBUF_LPWR_MODE              = "DEFAULT",
  parameter C_MEM_IODELAY_HP_MODE             = "DEFAULT",
  parameter C_MEM_SIM_INIT_OPTION             = "DEFAULT",
  parameter C_MEM_SIM_CAL_OPTION              = "DEFAULT",
  parameter C_MEM_CAL_WIDTH                   = "DEFAULT",
  parameter C_MEM_NDQS_COL0                   = 0,
  parameter C_MEM_NDQS_COL1                   = 0,
  parameter C_MEM_NDQS_COL2                   = 0,
  parameter C_MEM_NDQS_COL3                   = 0,
  parameter C_MEM_DQS_LOC_COL0                = 144'h00000000000000000000000000000000,
  parameter C_MEM_DQS_LOC_COL1                = 144'h00000000000000000000000000000000,
  parameter C_MEM_DQS_LOC_COL2                = 144'h00000000000000000000000000000000,
  parameter C_MEM_DQS_LOC_COL3                = 144'h00000000000000000000000000000000,
  parameter C_MEM_DQS_IO_COL                  = 18'b0,
  parameter C_MEM_DQ_IO_MS                    = 72'b0,
  parameter C_MEM_DQS_MATCHED                 = 1'b0,     // Allowed Values: 0,1
  parameter C_MEM_CAS_LATENCY0                = 2,        // Allowed Values: integer
  parameter C_MEM_CAS_LATENCY1                = 2,        // Allowed Values: integer
  parameter C_MEM_BURST_LENGTH                = 8,        // Allowed Values: 2,4,8
  parameter C_MEM_ADDITIVE_LATENCY            = 0,
  parameter C_MEM_ODT_TYPE                    = 0,
  parameter C_MEM_REDUCED_DRV                 = 0,
  parameter C_MEM_REG_DIMM                    = 0,
  parameter C_MPMC_CLK_PERIOD                 = 5000,
  parameter C_MEM_PART_TRAS                   = 0,
  parameter C_MEM_PART_TRCD                   = 0,
  parameter C_MEM_PART_TREFI                  = 0,
  parameter C_MEM_PART_TWR                    = 0,
  parameter C_MEM_PART_TRP                    = 0,
  parameter C_MEM_PART_TRFC                   = 0,
  parameter C_MEM_PART_TWTR                   = 0,
  parameter C_MEM_PART_TRTP                   = 0,
  parameter C_MEM_PART_TPRDI                  = 0,
  parameter C_MEM_PART_TZQI                   = 0,
  parameter C_MEM_DDR2_ENABLE                 = 1,
  parameter C_MEM_DQSN_ENABLE                 = 1,
  parameter C_MEM_DQS_GATE_EN                 = 0,
  parameter C_MEM_IDEL_HIGH_PERF              = "FALSE",
  parameter C_MEM_CLK_WIDTH                   = 1,        // Allowed Values: integer
  parameter C_MEM_ODT_WIDTH                   = 1,        // Allowed Values: integer
  parameter C_MEM_CE_WIDTH                    = 1,        // Allowed Values: integer
  parameter C_MEM_CS_N_WIDTH                  = 1,        // Allowed Values: integer
  parameter C_MEM_ADDR_WIDTH                  = 13,       // Allowed Values: 12-16
  parameter C_MEM_BANKADDR_WIDTH              = 2,        // Allowed Values: 2,3
  parameter C_MEM_DATA_WIDTH                  = 32,       // Allowed Values: 32,64
  parameter C_MEM_DATA_WIDTH_INT              = 32,       // Allowed Values: 32,64
  parameter C_ECC_DATA_WIDTH                  = 0,
  parameter C_ECC_DATA_WIDTH_INT              = 0,
  parameter C_ECC_DM_WIDTH                    = 0,
  parameter C_ECC_DM_WIDTH_INT                = 0,
  parameter C_ECC_DQS_WIDTH                   = 0,
  parameter C_ECC_DQS_WIDTH_INT               = 0,
  parameter C_MEM_DM_WIDTH                    = 4,
  parameter C_MEM_DM_WIDTH_INT                = 4,
  parameter C_MEM_DQS_WIDTH                   = 4,
  parameter C_MEM_DQS_WIDTH_INT               = 4,
  parameter C_MEM_BITS_DATA_PER_DQS           = 8,        // Allowed Values: 4,8,16,32,64
  parameter C_MEM_NUM_DIMMS                   = 1,        // Allowed Values: 1,2
  parameter C_MEM_NUM_RANKS                   = 1,        // Allowed Values: 1,2
  parameter C_MEM_SUPPORTED_TOTAL_OFFSETS     = 32'h08000000,
  parameter C_MEM_SUPPORTED_DIMM_OFFSETS      = 32'h08000000,
  parameter C_MEM_SUPPORTED_RANK_OFFSETS      = 32'h08000000,
  parameter C_MEM_SUPPORTED_BANK_OFFSETS      = 32'h02000000,
  parameter C_MEM_SUPPORTED_ROW_OFFSETS       = 32'h00001000,
  parameter C_MEM_SUPPORTED_COL_OFFSETS       = 32'h00000004,
  parameter C_WR_TRAINING_PORT                = 3'b001,
  parameter C_PIX_ADDR_WIDTH_MAX              = 32,
  parameter C_PIX_DATA_WIDTH_MAX              = 64,
  parameter C_PI_DATA_WIDTH                   = 8'hFF,
  parameter C_PI_RD_FIFO_TYPE                 = 16'hFFFF,
  parameter C_PI_WR_FIFO_TYPE                 = 16'hFFFF,
  parameter C_RD_FIFO_APP_PIPELINE            = 8'hFF,
  parameter C_RD_FIFO_MEM_PIPELINE            = 8'hFF,
  parameter C_WR_FIFO_APP_PIPELINE            = 8'hFF,
  parameter C_WR_FIFO_MEM_PIPELINE            = 8'hFF,
  parameter C_PIX_BE_WIDTH_MAX                = 8,
  parameter C_PIX_RDWDADDR_WIDTH_MAX          = 4,
  parameter C_WR_DATAPATH_TML_PIPELINE        = 0,    // Allowed Values: 0, 1
  parameter C_RD_DATAPATH_TML_MAX_FANOUT      = 0,
  parameter C_AP_PIPELINE1                    = 1,        // Allowed Values: 0,1
  parameter C_AP_PIPELINE2                    = 1,        // Allowed Values: 0,1
  parameter C_NUM_CTRL_SIGNALS                = 36,       // Allowed Values: 1-36
  parameter C_PIPELINE_ADDRACK                = 8'h00,    // Allowed Values: 8'h00-8'hFF, each
  // bit corresponds to an individual
  // port.
  parameter C_CP_PIPELINE                     = 1,        // Allowed Values: 0-1
  parameter C_ARB_PIPELINE                    = 0,        // Allowed Values: 0-1
  parameter C_MAX_REQ_ALLOWED                 = 1,        // Allowed Values: Any integer
                                        
  parameter C_REQ_PENDING_CNTR_WIDTH          = 2,        // Allowed Values: Such that
  // counter does not overflow
  // when max pending
  // instructions are
  // acknowledged

  parameter C_REFRESH_CNT_MAX                 = 1560,     // Allowed Values: Any interger
  parameter C_REFRESH_CNT_WIDTH               = 11,       // Allowed Values: Large enough to support C_REFRESH_CNT_MAX
  parameter C_MAINT_PRESCALER_DIV             = 0,
  parameter C_REFRESH_TIMER_DIV               = 0,
  parameter C_PERIODIC_RD_TIMER_DIV           = 0,
  parameter C_MAINT_PRESCALER_PERIOD_NS       = 0,
  parameter C_ZQ_TIMER_DIV                    = 0,

  parameter C_ECC_NUM_REG                     = 10,
  parameter C_STATIC_PHY_NUM_REG              = 10,

  parameter C_WORD_WRITE_SEQ                  = 0,
  parameter C_WORD_READ_SEQ                   = 0,
  parameter C_DOUBLEWORD_WRITE_SEQ            = 0,
  parameter C_DOUBLEWORD_READ_SEQ             = 0,
  parameter C_CL4_WRITE_SEQ                   = 0,
  parameter C_CL4_READ_SEQ                    = 0,
  parameter C_CL8_WRITE_SEQ                   = 0,
  parameter C_CL8_READ_SEQ                    = 0,
  parameter C_B16_WRITE_SEQ                   = 0,
  parameter C_B16_READ_SEQ                    = 0,
  parameter C_B32_WRITE_SEQ                   = 0,
  parameter C_B32_READ_SEQ                    = 0,
  parameter C_B64_WRITE_SEQ                   = 0,
  parameter C_B64_READ_SEQ                    = 0,
  parameter C_NOP_SEQ                         = 0,
  parameter C_REFH_SEQ                        = 0,
  parameter C_NCK_PER_CLK                     = 0,
  parameter C_TWR                             = 0,
  parameter C_CTRL_COMPLETE_INDEX             = 0,
  parameter C_CTRL_IS_WRITE_INDEX             = 0,
  parameter C_CTRL_PHYIF_RAS_N_INDEX          = 0,
  parameter C_CTRL_PHYIF_CAS_N_INDEX          = 0,
  parameter C_CTRL_PHYIF_WE_N_INDEX           = 0,
  parameter C_CTRL_RMW_INDEX                  = 0,
  parameter C_CTRL_SKIP_0_INDEX               = 0,
  parameter C_CTRL_PHYIF_DQS_O_INDEX          = 0,
  parameter C_CTRL_SKIP_1_INDEX               = 0,
  parameter C_CTRL_DP_RDFIFO_PUSH_INDEX       = 0,
  parameter C_CTRL_SKIP_2_INDEX               = 0,
  parameter C_CTRL_AP_COL_CNT_LOAD_INDEX      = 0,
  parameter C_CTRL_AP_COL_CNT_ENABLE_INDEX    = 0,
  parameter C_CTRL_AP_PRECHARGE_ADDR10_INDEX  = 0,
  parameter C_CTRL_AP_ROW_COL_SEL_INDEX       = 0,
  parameter C_CTRL_PHYIF_FORCE_DM_INDEX       = 0,
  parameter C_CTRL_REPEAT4_INDEX              = 0,
  parameter C_CTRL_DFI_RAS_N_0_INDEX          = 0,
  parameter C_CTRL_DFI_CAS_N_0_INDEX          = 0,
  parameter C_CTRL_DFI_WE_N_0_INDEX           = 0,
  parameter C_CTRL_DFI_RAS_N_1_INDEX          = 0,
  parameter C_CTRL_DFI_CAS_N_1_INDEX          = 0,
  parameter C_CTRL_DFI_WE_N_1_INDEX           = 0,
  parameter C_CTRL_DP_WRFIFO_POP_INDEX        = 0,
  parameter C_CTRL_DFI_WRDATA_EN_INDEX        = 0,
  parameter C_CTRL_DFI_RDDATA_EN_INDEX        = 0,
  parameter C_CTRL_AP_OTF_ADDR12_INDEX        = 0,
  parameter C_CTRL_ARB_RDMODWR_DELAY          = 0,
  parameter C_CTRL_AP_COL_DELAY               = 0,
  parameter C_CTRL_AP_PI_ADDR_CE_DELAY        = 0,
  parameter C_CTRL_AP_PORT_SELECT_DELAY       = 0,
  parameter C_CTRL_AP_PIPELINE1_CE_DELAY      = 0,
  parameter C_CTRL_DP_LOAD_RDWDADDR_DELAY     = 0,
  parameter C_CTRL_DP_RDFIFO_WHICHPORT_DELAY  = 0,
  parameter C_CTRL_DP_SIZE_DELAY              = 0,
  parameter C_CTRL_DP_WRFIFO_WHICHPORT_DELAY  = 0,
  parameter C_CTRL_PHYIF_DUMMYREADSTART_DELAY = 0,
  parameter C_CTRL_Q0_DELAY                   = 0,
  parameter C_CTRL_Q1_DELAY                   = 0,
  parameter C_CTRL_Q2_DELAY                   = 0,
  parameter C_CTRL_Q3_DELAY                   = 0,
  parameter C_CTRL_Q4_DELAY                   = 0,
  parameter C_CTRL_Q5_DELAY                   = 0,
  parameter C_CTRL_Q6_DELAY                   = 0,
  parameter C_CTRL_Q7_DELAY                   = 0,
  parameter C_CTRL_Q8_DELAY                   = 0,
  parameter C_CTRL_Q9_DELAY                   = 0,
  parameter C_CTRL_Q10_DELAY                  = 0,
  parameter C_CTRL_Q11_DELAY                  = 0,
  parameter C_CTRL_Q12_DELAY                  = 0,
  parameter C_CTRL_Q13_DELAY                  = 0,
  parameter C_CTRL_Q14_DELAY                  = 0,
  parameter C_CTRL_Q15_DELAY                  = 0,
  parameter C_CTRL_Q16_DELAY                  = 0,
  parameter C_CTRL_Q17_DELAY                  = 0,
  parameter C_CTRL_Q18_DELAY                  = 0,
  parameter C_CTRL_Q19_DELAY                  = 0,
  parameter C_CTRL_Q20_DELAY                  = 0,
  parameter C_CTRL_Q21_DELAY                  = 0,
  parameter C_CTRL_Q22_DELAY                  = 0,
  parameter C_CTRL_Q23_DELAY                  = 0,
  parameter C_CTRL_Q24_DELAY                  = 0,
  parameter C_CTRL_Q25_DELAY                  = 0,
  parameter C_CTRL_Q26_DELAY                  = 0,
  parameter C_CTRL_Q27_DELAY                  = 0,
  parameter C_CTRL_Q28_DELAY                  = 0,
  parameter C_CTRL_Q29_DELAY                  = 0,
  parameter C_CTRL_Q30_DELAY                  = 0,
  parameter C_CTRL_Q31_DELAY                  = 0,
  parameter C_CTRL_Q32_DELAY                  = 0,
  parameter C_CTRL_Q33_DELAY                  = 0,
  parameter C_CTRL_Q34_DELAY                  = 0,
  parameter C_CTRL_Q35_DELAY                  = 0,
  parameter C_ARB0_ALGO                       = "ROUND_ROBIN",
  parameter C_BASEADDR_ARB0                   = 9'h0,
  parameter C_HIGHADDR_ARB0                   = 9'h0,
  parameter C_BASEADDR_ARB1                   = 9'h0,
  parameter C_HIGHADDR_ARB1                   = 9'h0,
  parameter C_BASEADDR_ARB2                   = 9'h0,
  parameter C_HIGHADDR_ARB2                   = 9'h0,
  parameter C_BASEADDR_ARB3                   = 9'h0,
  parameter C_HIGHADDR_ARB3                   = 9'h0,
  parameter C_BASEADDR_ARB4                   = 9'h0,
  parameter C_HIGHADDR_ARB4                   = 9'h0,
  parameter C_BASEADDR_ARB5                   = 9'h0,
  parameter C_HIGHADDR_ARB5                   = 9'h0,
  parameter C_BASEADDR_ARB6                   = 9'h0,
  parameter C_HIGHADDR_ARB6                   = 9'h0,
  parameter C_BASEADDR_ARB7                   = 9'h0,
  parameter C_HIGHADDR_ARB7                   = 9'h0,
  parameter C_BASEADDR_ARB8                   = 9'h0,
  parameter C_HIGHADDR_ARB8                   = 9'h0,
  parameter C_BASEADDR_ARB9                   = 9'h0,
  parameter C_HIGHADDR_ARB9                   = 9'h0,
  parameter C_BASEADDR_ARB10                  = 9'h0,
  parameter C_HIGHADDR_ARB10                  = 9'h0,
  parameter C_BASEADDR_ARB11                  = 9'h0,
  parameter C_HIGHADDR_ARB11                  = 9'h0,
  parameter C_BASEADDR_ARB12                  = 9'h0,
  parameter C_HIGHADDR_ARB12                  = 9'h0,
  parameter C_BASEADDR_ARB13                  = 9'h0,
  parameter C_HIGHADDR_ARB13                  = 9'h0,
  parameter C_BASEADDR_ARB14                  = 9'h0,
  parameter C_HIGHADDR_ARB14                  = 9'h0,
  parameter C_BASEADDR_ARB15                  = 9'h0,
  parameter C_HIGHADDR_ARB15                  = 9'h0,
  parameter C_ARB_BRAM_SRVAL_A                = 36'h0,
  parameter C_ARB_BRAM_SRVAL_B                = 36'h0,
  parameter C_ARB_BRAM_INIT_00                = 256'h0,
  parameter C_ARB_BRAM_INIT_01                = 256'h0,
  parameter C_ARB_BRAM_INIT_02                = 256'h0,
  parameter C_ARB_BRAM_INIT_03                = 256'h0,
  parameter C_ARB_BRAM_INIT_04                = 256'h0,
  parameter C_ARB_BRAM_INIT_05                = 256'h0,
  parameter C_ARB_BRAM_INIT_06                = 256'h0,
  parameter C_ARB_BRAM_INIT_07                = 256'h0,
  parameter C_ARB_BRAM_INIT_08                = 256'h0,
  parameter C_ARB_BRAM_INIT_09                = 256'h0,
  parameter C_ARB_BRAM_INIT_0A                = 256'h0,
  parameter C_ARB_BRAM_INIT_0B                = 256'h0,
  parameter C_ARB_BRAM_INIT_0C                = 256'h0,
  parameter C_ARB_BRAM_INIT_0D                = 256'h0,
  parameter C_ARB_BRAM_INIT_0E                = 256'h0,
  parameter C_ARB_BRAM_INIT_0F                = 256'h0,
  parameter C_ARB_BRAM_INIT_10                = 256'h0,
  parameter C_ARB_BRAM_INIT_11                = 256'h0,
  parameter C_ARB_BRAM_INIT_12                = 256'h0,
  parameter C_ARB_BRAM_INIT_13                = 256'h0,
  parameter C_ARB_BRAM_INIT_14                = 256'h0,
  parameter C_ARB_BRAM_INIT_15                = 256'h0,
  parameter C_ARB_BRAM_INIT_16                = 256'h0,
  parameter C_ARB_BRAM_INIT_17                = 256'h0,
  parameter C_ARB_BRAM_INIT_18                = 256'h0,
  parameter C_ARB_BRAM_INIT_19                = 256'h0,
  parameter C_ARB_BRAM_INIT_1A                = 256'h0,
  parameter C_ARB_BRAM_INIT_1B                = 256'h0,
  parameter C_ARB_BRAM_INIT_1C                = 256'h0,
  parameter C_ARB_BRAM_INIT_1D                = 256'h0,
  parameter C_ARB_BRAM_INIT_1E                = 256'h0,
  parameter C_ARB_BRAM_INIT_1F                = 256'h0,
  parameter C_ARB_BRAM_INIT_20                = 256'h0,
  parameter C_ARB_BRAM_INIT_21                = 256'h0,
  parameter C_ARB_BRAM_INIT_22                = 256'h0,
  parameter C_ARB_BRAM_INIT_23                = 256'h0,
  parameter C_ARB_BRAM_INIT_24                = 256'h0,
  parameter C_ARB_BRAM_INIT_25                = 256'h0,
  parameter C_ARB_BRAM_INIT_26                = 256'h0,
  parameter C_ARB_BRAM_INIT_27                = 256'h0,
  parameter C_ARB_BRAM_INIT_28                = 256'h0,
  parameter C_ARB_BRAM_INIT_29                = 256'h0,
  parameter C_ARB_BRAM_INIT_2A                = 256'h0,
  parameter C_ARB_BRAM_INIT_2B                = 256'h0,
  parameter C_ARB_BRAM_INIT_2C                = 256'h0,
  parameter C_ARB_BRAM_INIT_2D                = 256'h0,
  parameter C_ARB_BRAM_INIT_2E                = 256'h0,
  parameter C_ARB_BRAM_INIT_2F                = 256'h0,
  parameter C_ARB_BRAM_INIT_30                = 256'h0,
  parameter C_ARB_BRAM_INIT_31                = 256'h0,
  parameter C_ARB_BRAM_INIT_32                = 256'h0,
  parameter C_ARB_BRAM_INIT_33                = 256'h0,
  parameter C_ARB_BRAM_INIT_34                = 256'h0,
  parameter C_ARB_BRAM_INIT_35                = 256'h0,
  parameter C_ARB_BRAM_INIT_36                = 256'h0,
  parameter C_ARB_BRAM_INIT_37                = 256'h0,
  parameter C_ARB_BRAM_INIT_38                = 256'h0,
  parameter C_ARB_BRAM_INIT_39                = 256'h0,
  parameter C_ARB_BRAM_INIT_3A                = 256'h0,
  parameter C_ARB_BRAM_INIT_3B                = 256'h0,
  parameter C_ARB_BRAM_INIT_3C                = 256'h0,
  parameter C_ARB_BRAM_INIT_3D                = 256'h0,
  parameter C_ARB_BRAM_INIT_3E                = 256'h0,
  parameter C_ARB_BRAM_INIT_3F                = 256'h0,
  parameter C_ARB_BRAM_INITP_00               = 256'h0,
  parameter C_ARB_BRAM_INITP_01               = 256'h0,
  parameter C_ARB_BRAM_INITP_02               = 256'h0,
  parameter C_ARB_BRAM_INITP_03               = 256'h0,
  parameter C_ARB_BRAM_INITP_04               = 256'h0,
  parameter C_ARB_BRAM_INITP_05               = 256'h0,
  parameter C_ARB_BRAM_INITP_06               = 256'h0,
  parameter C_ARB_BRAM_INITP_07               = 256'h0,
  parameter C_USE_FIXED_BASEADDR_CTRL         = 0,
  parameter C_B16_REPEAT_CNT                  = 0,
  parameter C_B32_REPEAT_CNT                  = 0,
  parameter C_B64_REPEAT_CNT                  = 0,
  parameter C_ZQCS_REPEAT_CNT                 = 0,
  parameter C_BASEADDR_CTRL0                  = 9'h0,
  parameter C_HIGHADDR_CTRL0                  = 9'h0,
  parameter C_BASEADDR_CTRL1                  = 9'h0,
  parameter C_HIGHADDR_CTRL1                  = 9'h0,
  parameter C_BASEADDR_CTRL2                  = 9'h0,
  parameter C_HIGHADDR_CTRL2                  = 9'h0,
  parameter C_BASEADDR_CTRL3                  = 9'h0,
  parameter C_HIGHADDR_CTRL3                  = 9'h0,
  parameter C_BASEADDR_CTRL4                  = 9'h0,
  parameter C_HIGHADDR_CTRL4                  = 9'h0,
  parameter C_BASEADDR_CTRL5                  = 9'h0,
  parameter C_HIGHADDR_CTRL5                  = 9'h0,
  parameter C_BASEADDR_CTRL6                  = 9'h0,
  parameter C_HIGHADDR_CTRL6                  = 9'h0,
  parameter C_BASEADDR_CTRL7                  = 9'h0,
  parameter C_HIGHADDR_CTRL7                  = 9'h0,
  parameter C_BASEADDR_CTRL8                  = 9'h0,
  parameter C_HIGHADDR_CTRL8                  = 9'h0,
  parameter C_BASEADDR_CTRL9                  = 9'h0,
  parameter C_HIGHADDR_CTRL9                  = 9'h0,
  parameter C_BASEADDR_CTRL10                 = 9'h0,
  parameter C_HIGHADDR_CTRL10                 = 9'h0,
  parameter C_BASEADDR_CTRL11                 = 9'h0,
  parameter C_HIGHADDR_CTRL11                 = 9'h0,
  parameter C_BASEADDR_CTRL12                 = 9'h0,
  parameter C_HIGHADDR_CTRL12                 = 9'h0,
  parameter C_BASEADDR_CTRL13                 = 9'h0,
  parameter C_HIGHADDR_CTRL13                 = 9'h0,
  parameter C_BASEADDR_CTRL14                 = 9'h0,
  parameter C_HIGHADDR_CTRL14                 = 9'h0,
  parameter C_BASEADDR_CTRL15                 = 9'h0,
  parameter C_HIGHADDR_CTRL15                 = 9'h0,
  parameter C_BASEADDR_CTRL16                 = 9'h0,
  parameter C_HIGHADDR_CTRL16                 = 9'h0,
  // Ctrl_path_table params
  parameter C_CTRL_BRAM_SRVAL                 = 36'h0,
  parameter C_CTRL_BRAM_INIT_00               = 256'h0,
  parameter C_CTRL_BRAM_INIT_01               = 256'h0,
  parameter C_CTRL_BRAM_INIT_02               = 256'h0,
  parameter C_CTRL_BRAM_INIT_03               = 256'h0,
  parameter C_CTRL_BRAM_INIT_04               = 256'h0,
  parameter C_CTRL_BRAM_INIT_05               = 256'h0,
  parameter C_CTRL_BRAM_INIT_06               = 256'h0,
  parameter C_CTRL_BRAM_INIT_07               = 256'h0,
  parameter C_CTRL_BRAM_INIT_08               = 256'h0,
  parameter C_CTRL_BRAM_INIT_09               = 256'h0,
  parameter C_CTRL_BRAM_INIT_0A               = 256'h0,
  parameter C_CTRL_BRAM_INIT_0B               = 256'h0,
  parameter C_CTRL_BRAM_INIT_0C               = 256'h0,
  parameter C_CTRL_BRAM_INIT_0D               = 256'h0,
  parameter C_CTRL_BRAM_INIT_0E               = 256'h0,
  parameter C_CTRL_BRAM_INIT_0F               = 256'h0,
  parameter C_CTRL_BRAM_INIT_10               = 256'h0,
  parameter C_CTRL_BRAM_INIT_11               = 256'h0,
  parameter C_CTRL_BRAM_INIT_12               = 256'h0,
  parameter C_CTRL_BRAM_INIT_13               = 256'h0,
  parameter C_CTRL_BRAM_INIT_14               = 256'h0,
  parameter C_CTRL_BRAM_INIT_15               = 256'h0,
  parameter C_CTRL_BRAM_INIT_16               = 256'h0,
  parameter C_CTRL_BRAM_INIT_17               = 256'h0,
  parameter C_CTRL_BRAM_INIT_18               = 256'h0,
  parameter C_CTRL_BRAM_INIT_19               = 256'h0,
  parameter C_CTRL_BRAM_INIT_1A               = 256'h0,
  parameter C_CTRL_BRAM_INIT_1B               = 256'h0,
  parameter C_CTRL_BRAM_INIT_1C               = 256'h0,
  parameter C_CTRL_BRAM_INIT_1D               = 256'h0,
  parameter C_CTRL_BRAM_INIT_1E               = 256'h0,
  parameter C_CTRL_BRAM_INIT_1F               = 256'h0,
  parameter C_CTRL_BRAM_INIT_20               = 256'h0,
  parameter C_CTRL_BRAM_INIT_21               = 256'h0,
  parameter C_CTRL_BRAM_INIT_22               = 256'h0,
  parameter C_CTRL_BRAM_INIT_23               = 256'h0,
  parameter C_CTRL_BRAM_INIT_24               = 256'h0,
  parameter C_CTRL_BRAM_INIT_25               = 256'h0,
  parameter C_CTRL_BRAM_INIT_26               = 256'h0,
  parameter C_CTRL_BRAM_INIT_27               = 256'h0,
  parameter C_CTRL_BRAM_INIT_28               = 256'h0,
  parameter C_CTRL_BRAM_INIT_29               = 256'h0,
  parameter C_CTRL_BRAM_INIT_2A               = 256'h0,
  parameter C_CTRL_BRAM_INIT_2B               = 256'h0,
  parameter C_CTRL_BRAM_INIT_2C               = 256'h0,
  parameter C_CTRL_BRAM_INIT_2D               = 256'h0,
  parameter C_CTRL_BRAM_INIT_2E               = 256'h0,
  parameter C_CTRL_BRAM_INIT_2F               = 256'h0,
  parameter C_CTRL_BRAM_INIT_30               = 256'h0,
  parameter C_CTRL_BRAM_INIT_31               = 256'h0,
  parameter C_CTRL_BRAM_INIT_32               = 256'h0,
  parameter C_CTRL_BRAM_INIT_33               = 256'h0,
  parameter C_CTRL_BRAM_INIT_34               = 256'h0,
  parameter C_CTRL_BRAM_INIT_35               = 256'h0,
  parameter C_CTRL_BRAM_INIT_36               = 256'h0,
  parameter C_CTRL_BRAM_INIT_37               = 256'h0,
  parameter C_CTRL_BRAM_INIT_38               = 256'h0,
  parameter C_CTRL_BRAM_INIT_39               = 256'h0,
  parameter C_CTRL_BRAM_INIT_3A               = 256'h0,
  parameter C_CTRL_BRAM_INIT_3B               = 256'h0,
  parameter C_CTRL_BRAM_INIT_3C               = 256'h0,
  parameter C_CTRL_BRAM_INIT_3D               = 256'h0,
  parameter C_CTRL_BRAM_INIT_3E               = 256'h0,
  parameter C_CTRL_BRAM_INIT_3F               = 256'h0,
  parameter C_CTRL_BRAM_INITP_00              = 256'h0,
  parameter C_CTRL_BRAM_INITP_01              = 256'h0,
  parameter C_CTRL_BRAM_INITP_02              = 256'h0,
  parameter C_CTRL_BRAM_INITP_03              = 256'h0,
  parameter C_CTRL_BRAM_INITP_04              = 256'h0,
  parameter C_CTRL_BRAM_INITP_05              = 256'h0,
  parameter C_CTRL_BRAM_INITP_06              = 256'h0,
  parameter C_CTRL_BRAM_INITP_07              = 256'h0,
  parameter C_SKIP_1_VALUE                    = 9'h0,
  parameter C_SKIP_2_VALUE                    = 9'h0,
  parameter C_SKIP_3_VALUE                    = 9'h0,
  parameter C_SKIP_4_VALUE                    = 9'h0,
  parameter C_SKIP_5_VALUE                    = 9'h0,
  parameter C_SKIP_6_VALUE                    = 9'h0,
  parameter C_SKIP_7_VALUE                    = 9'h0,

  // Port Parameters
  parameter C_PIM0_BASETYPE                   = 0,
  parameter C_PI0_ADDR_WIDTH                  = 32,      // Allowed Values: 32
  parameter C_PI0_DATA_WIDTH                  = 64,      // Allowed Values: 64
  parameter C_PI0_BE_WIDTH                    = C_PI0_DATA_WIDTH/8,
  parameter C_PI0_RDWDADDR_WIDTH              = 4,       // Allowed Values: 4,5
  parameter C_PIM1_BASETYPE                   = 0,
  parameter C_PI1_ADDR_WIDTH                  = 32,      // Allowed Values: 32
  parameter C_PI1_DATA_WIDTH                  = 64,      // Allowed Values: 64
  parameter C_PI1_BE_WIDTH                    = C_PI1_DATA_WIDTH/8,
  parameter C_PI1_RDWDADDR_WIDTH              = 4,       // Allowed Values: 4,5
  parameter C_PIM2_BASETYPE                   = 0,
  parameter C_PI2_ADDR_WIDTH                  = 32,      // Allowed Values: 32
  parameter C_PI2_DATA_WIDTH                  = 64,      // Allowed Values: 64
  parameter C_PI2_BE_WIDTH                    = C_PI2_DATA_WIDTH/8,
  parameter C_PI2_RDWDADDR_WIDTH              = 4,       // Allowed Values: 4,5
  parameter C_PIM3_BASETYPE                   = 0,
  parameter C_PI3_ADDR_WIDTH                  = 32,      // Allowed Values: 32
  parameter C_PI3_DATA_WIDTH                  = 64,      // Allowed Values: 64
  parameter C_PI3_BE_WIDTH                    = C_PI3_DATA_WIDTH/8,
  parameter C_PI3_RDWDADDR_WIDTH              = 4,       // Allowed Values: 4,5
  parameter C_PIM4_BASETYPE                   = 0,
  parameter C_PI4_ADDR_WIDTH                  = 32,      // Allowed Values: 32
  parameter C_PI4_DATA_WIDTH                  = 64,      // Allowed Values: 64
  parameter C_PI4_BE_WIDTH                    = C_PI4_DATA_WIDTH/8,
  parameter C_PI4_RDWDADDR_WIDTH              = 4,       // Allowed Values: 4,5
  parameter C_PIM5_BASETYPE                   = 0,
  parameter C_PI5_ADDR_WIDTH                  = 32,      // Allowed Values: 32
  parameter C_PI5_DATA_WIDTH                  = 64,      // Allowed Values: 64
  parameter C_PI5_BE_WIDTH                    = C_PI5_DATA_WIDTH/8,
  parameter C_PI5_RDWDADDR_WIDTH              = 4,       // Allowed Values: 4,5
  parameter C_PI6_ADDR_WIDTH                  = 32,      // Allowed Values: 32
  parameter C_PI6_DATA_WIDTH                  = 64,      // Allowed Values: 64
  parameter C_PI6_BE_WIDTH                    = C_PI6_DATA_WIDTH/8,
  parameter C_PI6_RDWDADDR_WIDTH              = 4,       // Allowed Values: 4,5
  parameter C_PI7_ADDR_WIDTH                  = 32,      // Allowed Values: 32
  parameter C_PI7_DATA_WIDTH                  = 64,      // Allowed Values: 64
  parameter C_PI7_BE_WIDTH                    = C_PI7_DATA_WIDTH/8,
  parameter C_PI7_RDWDADDR_WIDTH              = 4,       // Allowed Values: 4,5
  parameter C_MCB_LDQSP_TAP_DELAY_VAL         = 0,  // 0 to 255 inclusive
  parameter C_MCB_UDQSP_TAP_DELAY_VAL         = 0,  // 0 to 255 inclusive
  parameter C_MCB_LDQSN_TAP_DELAY_VAL         = 0,  // 0 to 255 inclusive
  parameter C_MCB_UDQSN_TAP_DELAY_VAL         = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ0_TAP_DELAY_VAL           = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ1_TAP_DELAY_VAL           = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ2_TAP_DELAY_VAL           = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ3_TAP_DELAY_VAL           = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ4_TAP_DELAY_VAL           = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ5_TAP_DELAY_VAL           = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ6_TAP_DELAY_VAL           = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ7_TAP_DELAY_VAL           = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ8_TAP_DELAY_VAL           = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ9_TAP_DELAY_VAL           = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ10_TAP_DELAY_VAL          = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ11_TAP_DELAY_VAL          = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ12_TAP_DELAY_VAL          = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ13_TAP_DELAY_VAL          = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ14_TAP_DELAY_VAL          = 0,  // 0 to 255 inclusive
  parameter C_MCB_DQ15_TAP_DELAY_VAL          = 0,  // 0 to 255 inclusive
  parameter integer C_TBY4TAPVALUE            = (C_MPMC_CLK_PERIOD/4)/78.125
)
(
  // System Signals
  input  wire                                          Clk0,
  input  wire                                          Clk0_DIV2,
  input  wire                                          Clk90,
  input  wire                                          Clk_200MHz,
  input  wire                                          Clk_Mem,
  input  wire                                          Clk_Mem_2x,
  input  wire                                          Clk_Mem_2x_180,
  input  wire                                          Clk_Mem_2x_CE0,
  input  wire                                          Clk_Mem_2x_CE90,
  output wire                                          Clk_Mem_2x_bufpll_o,
  output wire                                          Clk_Mem_2x_180_bufpll_o,
  output wire                                          Clk_Mem_2x_CE0_bufpll_o,
  output wire                                          Clk_Mem_2x_CE90_bufpll_o,
  input  wire                                          Clk_Rd_Base,
  input  wire                                          pll_locked,
  output wire                                          pll_lock,
  output reg                                           InitDone = 1'b0,
  input  wire [C_NUM_PORTS*2+4:0]                      Rst,
  input  wire                                          Rst90,
  input  wire                                          Rst270,
  output wire                                          ECC_Intr,
  output wire                                          DCM_PSEN,
  output wire                                          DCM_PSINCDEC,
  input  wire                                          DCM_PSDONE,
  input  wire                                          MCB_DRP_Clk,
  input  wire                                          Idelayctrl_Rdy_I,
  input  wire                                          Idelayctrl_Rdy_O,
  
  // Memory Interface Signals
  output wire [C_MEM_CLK_WIDTH-1:0]                    Mem_Clk_O,
  output wire [C_MEM_CLK_WIDTH-1:0]                    Mem_Clk_n_O,
  output wire [C_MEM_CE_WIDTH-1:0]                     Mem_CE_O,
  output wire [C_MEM_CS_N_WIDTH-1:0]                   Mem_CS_n_O,
  output wire [C_MEM_ODT_WIDTH-1:0]                    Mem_ODT_O,
  output wire                                          Mem_RAS_n_O,
  output wire                                          Mem_CAS_n_O,
  output wire                                          Mem_WE_n_O,
  output wire [C_MEM_BANKADDR_WIDTH-1:0]               Mem_BankAddr_O,
  output wire [C_MEM_ADDR_WIDTH-1:0]                   Mem_Addr_O,
  output wire [C_ECC_DM_WIDTH+C_MEM_DM_WIDTH-1:0]      Mem_DM_O,
  output wire                                          Mem_Reset_n_O,
  output wire                                          Mem_DQS_Div_O,
  input  wire                                          Mem_DQS_Div_I,
  inout  wire [C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH-1:0]  DDR3_DQ,
  inout  wire [C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH-1:0]    DDR3_DQS,
  inout  wire [C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH-1:0]    DDR3_DQS_n,
  inout  wire [C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH-1:0]  DDR2_DQ,
  inout  wire [C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH-1:0]    DDR2_DQS,
  inout  wire [C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH-1:0]    DDR2_DQS_n,
  inout  wire [C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH-1:0]  DDR_DQ,
  inout  wire [C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH-1:0]    DDR_DQS,
  inout  wire [C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH-1:0]  SDRAM_DQ,
  
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
  input  wire [C_PI4_DATA_WIDTH/8-1:0]          MCB4_wr_mask,
  input  wire [C_PI4_DATA_WIDTH-1:0]            MCB4_wr_data,
  output wire                                   MCB4_wr_full,
  output wire                                   MCB4_wr_empty,
  output wire [6:0]                             MCB4_wr_count,
  output wire                                   MCB4_wr_underrun,
  output wire                                   MCB4_wr_error,
  input  wire                                   MCB4_rd_clk,
  input  wire                                   MCB4_rd_en,
  output wire [C_PI4_DATA_WIDTH-1:0]            MCB4_rd_data,
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
  input  wire [C_PI5_DATA_WIDTH/8-1:0]          MCB5_wr_mask,
  input  wire [C_PI5_DATA_WIDTH-1:0]            MCB5_wr_data,
  output wire                                   MCB5_wr_full,
  output wire                                   MCB5_wr_empty,
  output wire [6:0]                             MCB5_wr_count,
  output wire                                   MCB5_wr_underrun,
  output wire                                   MCB5_wr_error,
  input  wire                                   MCB5_rd_clk,
  input  wire                                   MCB5_rd_en,
  output wire [C_PI5_DATA_WIDTH-1:0]            MCB5_rd_data,
  output wire                                   MCB5_rd_full,
  output wire                                   MCB5_rd_empty,
  output wire [6:0]                             MCB5_rd_count,
  output wire                                   MCB5_rd_overflow,
  output wire                                   MCB5_rd_error,

  // MPMC_CTRL signals
  input  wire [0:31]                                   Debug_Ctrl_Addr,
  input  wire                                          Debug_Ctrl_WE,
  input  wire [0:31]                                   Debug_Ctrl_In,
  output wire [0:31]                                   Debug_Ctrl_Out,
  input  wire  [C_ECC_NUM_REG-1:0]                     ECC_Reg_CE,
  input  wire  [31:0]                                  ECC_Reg_In,
  output wire [C_ECC_NUM_REG*32-1:0]                   ECC_Reg_Out,
  input  wire  [C_STATIC_PHY_NUM_REG-1:0]              Static_Phy_Reg_CE,
  input  wire  [31:0]                                  Static_Phy_Reg_In,
  output wire [C_STATIC_PHY_NUM_REG*32-1:0]            Static_Phy_Reg_Out,
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

  localparam C_INIT0_STALL          = 0;
  localparam C_INIT1_STALL          = 0;
  localparam C_INIT2_STALL          = 0;
  localparam C_ECC_ENCODE_PIPELINE  = 1'b1;
  localparam C_ECC_DECODE_PIPELINE  = 1'b1;
  
   
  localparam C_RAMB_SIM_COLLISION_CHECK = "NONE";
  localparam C_ARB_PORT_ENCODING_WIDTH       = (C_NUM_PORTS <= 2) ? 1 :
                                               (C_NUM_PORTS <= 4) ? 2 :
                                               3;
  localparam C_ARB_PATTERN_TYPE_WIDTH        = 4; // Allowed Values: 4
  localparam C_ARB_PATTERN_TYPE_DECODE_WIDTH = 16; // Allowed Values: 16
  localparam C_ARB_SEQUENCE_ENCODING_WIDTH   = 4; // Allowed Values: 4
  localparam C_ARB_BRAM_ADDR_WIDTH           = 9; // Allowed Values: 9
  
  localparam C_WR_FIFO_MEM_PIPELINE_SINGLE = 
             (C_PI_WR_FIFO_TYPE[ 0 +: 2] != "00") ? C_WR_FIFO_MEM_PIPELINE[0] :
             (C_PI_WR_FIFO_TYPE[ 2 +: 2] != "00") ? C_WR_FIFO_MEM_PIPELINE[1] :
             (C_PI_WR_FIFO_TYPE[ 4 +: 2] != "00") ? C_WR_FIFO_MEM_PIPELINE[2] :
             (C_PI_WR_FIFO_TYPE[ 6 +: 2] != "00") ? C_WR_FIFO_MEM_PIPELINE[3] :
             (C_PI_WR_FIFO_TYPE[ 8 +: 2] != "00") ? C_WR_FIFO_MEM_PIPELINE[4] :
             (C_PI_WR_FIFO_TYPE[10 +: 2] != "00") ? C_WR_FIFO_MEM_PIPELINE[5] :
             (C_PI_WR_FIFO_TYPE[12 +: 2] != "00") ? C_WR_FIFO_MEM_PIPELINE[6] :
                                                    C_WR_FIFO_MEM_PIPELINE[7];

  localparam C_CTRL_DP_WRFIFO_WHICHPORT_REP = (C_MEM_DATA_WIDTH_INT<16) ? 
                                              1 : C_MEM_DATA_WIDTH_INT/16;
  localparam RDF_PUSH_BITS = ( C_MEM_TYPE == "SDRAM" ? 1 : (C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH));    
  localparam P_WDF_RDEN_EARLY            = (C_WR_FIFO_MEM_PIPELINE_SINGLE == 1);
  localparam P_DELAY_PHYIF_DP_WRFIFO_POP = (C_WR_DATAPATH_TML_PIPELINE == 0);
  
  // V5 Phy Interface
  localparam P_ECC_DQ_BITS  = (C_ECC_DATA_WIDTH==0)  ? 0 : 1;
  localparam P_DQ_BITS      = (C_MEM_DATA_WIDTH==1)  ? 1 :
                             (C_MEM_DATA_WIDTH==2)  ? 1 :
                             (C_MEM_DATA_WIDTH==4)  ? 2 :
                             (C_MEM_DATA_WIDTH==8)  ? 3 :
                             (C_MEM_DATA_WIDTH==16) ? 4 :
                             (C_MEM_DATA_WIDTH==32) ? 5 :
                             (C_MEM_DATA_WIDTH==64) ? 6 :
                                                      7;
  localparam P_ECC_DQS_BITS = (C_ECC_DQS_WIDTH==0)  ? 0 : 1;
  localparam P_DQS_BITS     = (C_MEM_DQS_WIDTH==1)  ? 1 :
                             (C_MEM_DQS_WIDTH==2)  ? 1 :
                             (C_MEM_DQS_WIDTH==4)  ? 2 :
                             (C_MEM_DQS_WIDTH==8)  ? 3 :
                             (C_MEM_DQS_WIDTH==16) ? 4:
                             (C_MEM_DQS_WIDTH==32) ? 5 :
                             (C_MEM_DQS_WIDTH==64) ? 6 :
                                                     7;

  localparam P_CS_BITS      = (C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS) <= 1 ? 0 : 
                              (C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS) <= 2 ? 1 : 
                              (C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS) <= 4 ? 2 : 
                              (C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS) <= 8 ? 3 : 
                              (C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS) <= 16 ? 4 : 
                              (C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS) <= 32 ? 5 : 
                              6;

  localparam P_HIGH_PERFORMANCE_MODE = "TRUE";

  // Generate local MCB related parameters.
  localparam C_BUFPLL_0_LOCK_SRC         = "LOCK_TO_0";

  // Begin V6 DDRx PHY Parameters
  localparam P_TCQ              = 100;
  localparam P_REFCLK_FREQ      = C_IDELAY_CLK_FREQ == "DEFAULT" ? 200.0 : 300.0; // IODELAY Reference Clock freq (MHz)
  localparam P_SLOT_0_CONFIG    = 8'b0000_0001;
  localparam P_SLOT_1_CONFIG    = 8'b0000_0000;
  localparam P_NCS_PER_RANK     = C_MEM_CS_N_WIDTH/C_MEM_NUM_RANKS;     // # of unique CS outputs per rank
  localparam P_RANK_WIDTH       = C_MEM_NUM_RANKS == 1 ? 1 :            // log2(CS_WIDTH)
                                  C_MEM_NUM_RANKS == 2 ? 1 :            
                                  C_MEM_NUM_RANKS == 4 ? 2 :            
                                  C_MEM_NUM_RANKS == 8 ? 3 :            
                                  0;                                    // Error setting
  localparam P_CS_WIDTH         = C_MEM_NUM_RANKS;                      // # of DRAM ranks
  localparam P_MEM_CAL_WIDTH    = (C_MEM_CAL_WIDTH != "DEFAULT") ? C_MEM_CAL_WIDTH : C_SKIP_INIT_DELAY ? "HALF" : "FULL";  // # of DRAM ranks to be calibrated
  localparam P_CALIB_ROW_ADD    = 16'hFFFF;
  localparam P_CALIB_COL_ADD    = 12'hF00;
  localparam P_CALIB_BA_ADD     = 3'h7;
  localparam P_AL               = C_MEM_ADDITIVE_LATENCY == 0 ? "0" :   // Additive Latency option
                                  C_MEM_ADDITIVE_LATENCY == 1 ? "CL-1" :
                                  C_MEM_ADDITIVE_LATENCY == 2 ? "CL-2" :
                                  "0";
  localparam P_BURST_MODE       = (C_MEM_TYPE == "DDR3") ? "OTF" : "4"; // Burst length
  localparam P_BURST_TYPE       = "SEQ";                                // Burst type
  localparam P_OUTPUT_DRV       = C_MEM_REDUCED_DRV ? "LOW" : "HIGH";   // DRAM reduced output drive option
  localparam P_REG_CTRL         = C_MEM_REG_DIMM ? "ON" : "OFF";        // "ON" for registered DIMM
  localparam P_DDR2_RTT_NOM     = C_MEM_ODT_TYPE == 1 ? "75" :          // ODT Nominal termination value
                                  C_MEM_ODT_TYPE == 2 ? "150"  :
                                  C_MEM_ODT_TYPE == 3 ? "50"  :
                                  "0";
  localparam P_DDR2_RTT_WR      = "0";                                  // ODT Write termination value
  localparam P_DDR3_RTT_NOM     = C_MEM_ODT_TYPE == 1 ? "60" :         // ODT termination value
                                  C_MEM_ODT_TYPE == 2 ? "120"  :
                                  C_MEM_ODT_TYPE == 3 ? "40"  :
                                  C_MEM_ODT_TYPE == 4 ? "20"  :
                                  C_MEM_ODT_TYPE == 5 ? "30"  :
                                  "0";
  localparam P_DDR3_RTT_WR      = "0";                                    // ODT Write termination value
  localparam P_MEM_WRLVL        = (C_MEM_TYPE == "DDR2") ? "OFF" :      // Enable write leveling
                                  C_MEM_WRLVL ? "ON" : "OFF";
  localparam P_PHASE_DETECT     = (C_MEM_PHASE_DETECT != "DEFAULT") ? C_MEM_PHASE_DETECT : "ON";    // Enable read phase detector
  localparam P_IBUF_LPWR_MODE   = (C_MEM_IBUF_LPWR_MODE != "DEFAULT") ? C_MEM_IBUF_LPWR_MODE : "OFF";                                // Input buffer low power mode
  localparam P_IODELAY_HP_MODE  = (C_MEM_IODELAY_HP_MODE != "DEFAULT") ? C_MEM_IODELAY_HP_MODE : "ON";                                 // IODELAY High Performance Mode
  localparam P_USE_DM_PORT      = 1;
  localparam P_SIM_INIT_OPTION  = (C_MEM_SIM_INIT_OPTION != "DEFAULT") ? C_MEM_SIM_INIT_OPTION : "NONE";   // Skip various initialization steps
  localparam P_SIM_CAL_OPTION   = (C_MEM_SIM_CAL_OPTION != "DEFAULT") ? C_MEM_SIM_CAL_OPTION : "NONE";      // Skip various calibration steps
  localparam P_SIM_BYPASS_INIT_CAL = C_SKIP_INIT_DELAY ? "FAST" : "OFF";

  // Spartan-6 simulation only parameter for faster sim
  localparam P_SIMULATION = (C_SKIP_INIT_DELAY == 1) ? "TRUE" : "FALSE";

  // Round up for clk reset delay to ensure that CLKDIV reset deassertion
  // occurs at same time or after CLK reset deassertion (still need to
  // consider route delay - add one or two extra cycles to be sure!)
  localparam P_RST_DIV_SYNC_NUM = 8;                    
  // End V6 DDRx PHY Parameters

  localparam P_USE_INIT_PUSH    = C_USE_MIG_V4_PHY || (C_USE_MIG_V5_PHY && C_MEM_TYPE == "DDR");
  
  // Bused Port Interface Request/Acknowledge/Address Signals
  // Signals Between Modules
  wire                                        ctrl_dp_wrfifo_pop;
  wire                                        Clk_WrFIFO_TML;
  wire                                        Ctrl_Is_Write;
  wire                                        Ctrl_PhyIF_RAS_n;
  wire                                        Ctrl_PhyIF_CAS_n;
  wire                                        Ctrl_PhyIF_WE_n;
  wire [C_MEM_BANKADDR_WIDTH-1:0]             AP_PhyIF_BankAddr;
  wire [C_MEM_ADDR_WIDTH-1:0]                 AP_PhyIF_Addr;
  wire [C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS-1:0]  AP_PhyIF_CS_n;
  wire                                        Ctrl_Periodic_Rd_Mask;
  wire                                        Ctrl_PhyIF_RAS_n_i;
  wire                                        Ctrl_PhyIF_CAS_n_i;
  wire                                        Ctrl_PhyIF_WE_n_i;
  wire [C_MEM_BANKADDR_WIDTH-1:0]             AP_PhyIF_BankAddr_i;
  wire [C_MEM_ADDR_WIDTH-1:0]                 AP_PhyIF_Addr_i;
  wire [C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS-1:0]  AP_PhyIF_CS_n_i;
  wire [C_MEM_DATA_WIDTH_INT-1:0]             PhyIF_DP_DQ_I;
  wire [C_ECC_DATA_WIDTH*(C_IS_DDR+1)+C_MEM_DATA_WIDTH_INT-1:0] rd_data;
  wire [C_MEM_DATA_WIDTH_INT-1:0]             DP_PhyIF_DQ_O;
  wire [C_ECC_DATA_WIDTH*(C_IS_DDR+1)+C_MEM_DATA_WIDTH_INT-1:0] wdf_data;
  wire [C_MEM_DM_WIDTH_INT-1:0]               DP_PhyIF_BE_O;
  wire                                        Ctrl_RMW;
  wire                                        Ctrl_PhyIF_DQS_O;
  wire [C_MEM_DM_WIDTH_INT-1:0]               Ctrl_PhyIF_Force_DM;
  reg  [C_NUM_PORTS-1:0]                      Ctrl_PhyIF_Force_DM_d1;
  // synthesis attribute equivalent_register_removal of Ctrl_PhyIF_Force_DM_d1 is "no"
  reg  [C_NUM_PORTS-1:0]                      Ctrl_PhyIF_Force_DM_d1_i;
  wire                                        PhyIF_Ctrl_InitDone_tmp;
  reg                                         PhyIF_Ctrl_InitDone_tmp_d1a = 1'b0;
  // synthesis attribute equivalent_register_removal of PhyIF_Ctrl_InitDone_tmp_d1a is "no"
  reg                                         PhyIF_Ctrl_InitDone_tmp_d1b = 1'b0;
  // synthesis attribute equivalent_register_removal of PhyIF_Ctrl_InitDone_tmp_d1b is "no"
  reg [19:0]                                  PhyIF_Ctrl_InitDone = 20'b0;
  // synthesis attribute equivalent_register_removal of PhyIF_Ctrl_InitDone is "no"
  reg                                         PhyIF_Ctrl_InitDone_270 = 1'b0;
  // synthesis attribute equivalent_register_removal of PhyIF_Ctrl_InitDone_270 is "no"
  //   reg                                         InitDone;
  // synthesis attribute equivalent_register_removal of InitDone is "no"
  reg                                         InitDone_i = 1'b0;
  // synthesis attribute equivalent_register_removal of InitDone_i is "no"
  reg [C_NUM_PORTS-1:0]                       InitDone_i2 = {C_NUM_PORTS{1'b0}};
  // synthesis attribute equivalent_register_removal of InitDone_i2 is "no"
  wire                                        Ctrl_Refresh_Flag;

  wire [C_STATIC_PHY_NUM_REG*32-1:0]          static_phy_reg_out_i;
  wire [8*C_MEM_NUM_DIMMS-1:0]                SPD_AP_Total_Offset;
  wire [8*C_MEM_NUM_DIMMS-1:0]                SPD_AP_DIMM_Offset;
  wire [8*C_MEM_NUM_DIMMS-1:0]                SPD_AP_Rank_Offset;
  wire [8*C_MEM_NUM_DIMMS-1:0]                SPD_AP_Bank_Offset;
  wire [8*C_MEM_NUM_DIMMS-1:0]                SPD_AP_Row_Offset;
  wire [8*C_MEM_NUM_DIMMS-1:0]                SPD_AP_Col_Offset;
  wire [31:0]                                 AP_Ctrl_Addr;
  wire [3:0]                                  Ctrl_ECC_RdFIFO_Size;
  wire [3:0]                                  Ctrl_ECC_RdFIFO_Size_i;
  wire                                        Ctrl_ECC_RdFIFO_RNW;
  wire                                        Ctrl_ECC_RdFIFO_RNW_i;
  wire [31:0]                                 Ctrl_ECC_RdFIFO_Addr;
  wire [C_NUM_PORTS-1:0]                      Ctrl_AP_PI_Addr_CE;
  wire [C_ARB_PORT_ENCODING_WIDTH-1:0]        Ctrl_AP_Port_Select;
  wire                                        Ctrl_AP_Row_Col_Sel;
  wire                                        Ctrl_AP_Col_Cnt_Load;
  wire                                        Ctrl_AP_Col_Cnt_Enable;
  wire                                        Ctrl_AP_Col_W;
  wire                                        Ctrl_AP_Col_DW;
  wire                                        Ctrl_AP_Col_CL4;
  wire                                        Ctrl_AP_Col_CL8;
  wire                                        Ctrl_AP_Col_B16;
  wire                                        Ctrl_AP_Col_B32;
  wire                                        Ctrl_AP_Col_B64;
  wire [3:0]                                  Ctrl_AP_Col_Burst_Length;
  wire                                        Ctrl_AP_Precharge_Addr10;
  wire                                        Ctrl_AP_OTF_Addr12;
  wire                                        Ctrl_AP_Assert_All_CS;
  wire                                        Ctrl_AP_Pipeline1_CE;
  
  wire [C_ARB_SEQUENCE_ENCODING_WIDTH-1:0]    Arb_Sequence;
  wire                                        Arb_LoadSequence;
  wire                                        Arb_PatternStart;

  wire [RDF_PUSH_BITS-1:0]                    PhyIF_DP_RdFIFO_Push_tmp; 
  wire                                        PhyIF_DP_RdFIFO_Push; 
  wire                                        Ctrl_DP_RdFIFO_Push; 
  wire [C_NUM_PORTS-1:0]                      Ctrl_DP_RdFIFO_WhichPort_Decode;
  wire [C_NUM_PORTS-1:0]                      Ctrl_DP_RdFIFO_WhichPort_Decode_i;
  wire [C_NUM_PORTS-1:0]                      DP_Ctrl_RdFIFO_AlmostFull;
  wire [C_NUM_PORTS-1:0]                      PhyIF_DP_WrFIFO_Pop;
  reg  [C_NUM_PORTS-1:0]                      PhyIF_DP_WrFIFO_Pop_i;
  wire [C_ARB_PORT_ENCODING_WIDTH*C_CTRL_DP_WRFIFO_WHICHPORT_REP-1:0] Ctrl_DP_WrFIFO_WhichPort;
  wire [C_NUM_PORTS-1:0]                      Ctrl_DP_WrFIFO_WhichPort_Decode;
  wire [C_NUM_PORTS-1:0]                      DP_Ctrl_WrFIFO_Empty;

  wire [63:0]                                 PhyIF_Init_Data_tmp;
  wire [C_MEM_DATA_WIDTH_INT-1:0]             PhyIF_Init_Data;
  wire [C_MEM_DATA_WIDTH_INT-1:0]             PhyIF_Init_Data_reorder;
  wire                                        PhyIF_Init_Push_tmp;
  wire                                        PhyIF_Init_Push;

  wire [C_ECC_DM_WIDTH_INT+C_MEM_DM_WIDTH_INT-1:0] wdf_mask_data;

  wire                                        rst_phy;
  wire                                        rst90_phy;
  
  wire [4:0]                                      dbg_calib_delay_sel;
  wire                                            dbg_calib_phase_cnt;
  wire [4:0]                                      dbg_calib_cnt;
  wire [5:0]                                      dbg_calib_rst_calib;
  wire                                            dbg_calib_trans_onedtct;
  wire                                            dbg_calib_trans_twodtct;
  wire                                            dbg_calib_enb_trans_two_dtct;
  wire                                             vio_out_dqs_en;
  wire [4:0]                                       vio_out_dqs;
  wire                                             vio_out_rst_dqs_div_en;
  wire [4:0]                                       vio_out_rst_dqs_div;
  wire [(((C_MEM_TYPE=="DDR2") || (C_USE_MIG_V4_PHY)) ? 
         (C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH)*5-1 : 
         (C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH)*2-1):0] dbg_calib_rden_dly_value;
  wire [(C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH)-1:0]     dbg_calib_rden_dly_en;
  wire [(((C_MEM_TYPE=="DDR2") || (C_USE_MIG_V4_PHY)) ? 
         (C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH)*5-1 : 
         (C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH)*2-1):0] dbg_calib_rden_dly;
  wire [(C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH)-1:0]     dbg_calib_rd_data_sel_value;
  wire [(C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH)-1:0]     dbg_calib_rd_data_sel_en;
  wire [(C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH)-1:0]     dbg_calib_rd_data_sel;
  wire [(C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH)*6-1:0]   dbg_calib_dqs_tap_cnt;
  wire [(C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH)*6-1:0] dbg_calib_dq_tap_cnt;
  wire                                             dbg_idel_up_all;
  wire                                             dbg_idel_down_all;
  wire                                             dbg_sel_all_idel_dq;
  wire                                             dbg_sel_all_idel_dqs;
  wire                                             dbg_sel_all_idel_gate;
  wire                                             dbg_idel_up_dq;
  wire                                             dbg_idel_down_dq;
  wire [P_ECC_DQ_BITS+P_DQ_BITS-1:0]               dbg_sel_idel_dq;
  wire                                             dbg_idel_up_dqs;
  wire                                             dbg_idel_down_dqs;
  wire [P_ECC_DQS_BITS+P_DQS_BITS:0]               dbg_sel_idel_dqs;
  wire                                             dbg_idel_up_gate;
  wire                                             dbg_idel_down_gate;
  wire [P_ECC_DQS_BITS+P_DQS_BITS:0]               dbg_sel_idel_gate;
  wire [(C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH)-1:0]     dbg_calib_delay_rd_fall_value;
  wire [(C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH)-1:0]     dbg_calib_delay_rd_fall_en;
  wire [(C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH)-1:0]     dbg_calib_delay_rd_fall;
  wire [(C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH)-1:0]   dbg_calib_dq_delay_en_value;
  wire [(C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH)-1:0]   dbg_calib_dq_delay_en_en;
  wire [(C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH)-1:0]   dbg_calib_dq_delay_en;
  wire [(C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH):0]       dbg_calib_done_v4;
  wire [(C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH):0]       dbg_calib_err_v4;
  wire                                             dbg_calib_sel_done;
  wire [(C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH)*8-1:0]   dbg_calib_dq_in_byte_align_value;
  wire [(C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH)-1:0]     dbg_calib_dq_in_byte_align_en;
  wire [(C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH)*8-1:0]   dbg_calib_dq_in_byte_align;
  wire [(C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH)-1:0]     dbg_calib_cal_first_loop_value;
  wire [(C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH)-1:0]     dbg_calib_cal_first_loop_en;
  wire [(C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH)-1:0]     dbg_calib_cal_first_loop;
  wire [((C_MEM_TYPE=="DDR2") ? 
         (C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH)*5-1 : 
         (C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH)*2-1):0] dbg_calib_gate_dly_value;
  wire [(C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH)-1:0]     dbg_calib_gate_dly_en;
  wire [((C_MEM_TYPE=="DDR2") ? 
         (C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH)*5-1 : 
         (C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH)*2-1):0] dbg_calib_gate_dly;
  wire [3:0]                                       dbg_calib_done_v5;
  wire [3:0]                                       dbg_calib_err_v5;
  wire [6:0]                                       dbg_calib_bit_err_index = 7'h00;
  wire [(C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH)*6-1:0]   dbg_calib_gate_tap_cnt;
  
  wire                                             ecc_byte_access_en;
  wire [7:0]                                       ecc_write_data0;
  wire [7:0]                                       ecc_write_data1;
  wire [7:0]                                       ecc_write_data2;
  wire [7:0]                                       ecc_write_data3;
  reg  [7:0]                                       ecc_read_data0;
  reg  [7:0]                                       ecc_read_data1;
  reg  [7:0]                                       ecc_read_data2;
  reg  [7:0]                                       ecc_read_data3;
  wire                                             mcbx_InitDone;
  wire [C_NCK_PER_CLK-1:0]                         ctrl_dfi_ras_n;
  wire [C_NCK_PER_CLK-1:0]                         ctrl_dfi_cas_n;
  wire [C_NCK_PER_CLK-1:0]                         ctrl_dfi_we_n;
  wire [C_NCK_PER_CLK-1:0]                         ctrl_dfi_odt;
  wire [C_NCK_PER_CLK-1:0]                         ctrl_dfi_ce;
  wire                                             ctrl_dfi_wrdata_en;
  wire                                             ctrl_dfi_rddata_en;
  wire                                             ctrl_dfi_rddata_valid;
  
  genvar i;
  
  generate
    if (C_USE_MCB_S6_PHY) 
      begin : gen_spartan6_tie_off
        // Tie-off unused signals for Spartan-6.
        always @(posedge Clk0) InitDone <= mcbx_InitDone;
        assign ECC_Intr        = 1'b0;
        assign ECC_Reg_Out     = {C_ECC_NUM_REG{1'b0}};
        assign Debug_Ctrl_Out  = 32'h0;
        assign DCM_PSEN        = 1'b0;
        assign DCM_PSINCDEC    = 1'b0;
        assign Mem_Clk_O       = {C_MEM_CLK_WIDTH{1'b0}};
        assign Mem_Clk_n_O     = {C_MEM_CLK_WIDTH{1'b0}};
        assign Mem_CE_O        = {C_MEM_CE_WIDTH{1'b0}};
        assign Mem_CS_n_O      = {C_MEM_CS_N_WIDTH{1'b0}};
        assign Mem_ODT_O       = {C_MEM_ODT_WIDTH{1'b0}};
        assign Mem_RAS_n_O     = 1'b0;
        assign Mem_CAS_n_O     = 1'b0;
        assign Mem_WE_n_O      = 1'b0;
        assign Mem_BankAddr_O  = {C_MEM_BANKADDR_WIDTH{1'b0}};
        assign Mem_Addr_O      = {C_MEM_ADDR_WIDTH{1'b0}};
        assign Mem_DM_O        = {C_ECC_DM_WIDTH+C_MEM_DM_WIDTH{1'b0}};
        assign Mem_DQS_Div_O   = 1'b0;
      end
    else begin : gen_normal_phy_mapping
      /////////////////////////////////////////////////////////////////
      // This generate statement vecorizes the port interface inputs
      // based on the number of ports attached to the MPMC.
      /////////////////////////////////////////////////////////////////
      
       if      (C_MEM_DATA_WIDTH_INT ==   8) begin : gen_reorder_initdata_8bit
          assign PhyIF_Init_Data_reorder = {PhyIF_Init_Data_tmp[11:8],
                                            PhyIF_Init_Data_tmp[3:0]};
       end
       else if (C_MEM_DATA_WIDTH_INT ==  16) begin : gen_reorder_initdata_16bit
          assign PhyIF_Init_Data_reorder = PhyIF_Init_Data_tmp[15:0];
       end
       else if (C_MEM_DATA_WIDTH_INT ==  32) begin : gen_reorder_initdata_32bit
          assign PhyIF_Init_Data_reorder = {PhyIF_Init_Data_tmp[31:24],
                                            PhyIF_Init_Data_tmp[15:8],
                                            PhyIF_Init_Data_tmp[23:16],
                                            PhyIF_Init_Data_tmp[7:0]};
       end
       else if (C_MEM_DATA_WIDTH_INT ==  64) begin : gen_reorder_initdata_64bit
          assign PhyIF_Init_Data_reorder = {PhyIF_Init_Data_tmp[63:56],
                                            PhyIF_Init_Data_tmp[47:40],
                                            PhyIF_Init_Data_tmp[31:24],
                                            PhyIF_Init_Data_tmp[15:8],
                                            PhyIF_Init_Data_tmp[55:48],
                                            PhyIF_Init_Data_tmp[39:32],
                                            PhyIF_Init_Data_tmp[23:16],
                                            PhyIF_Init_Data_tmp[7:0]};
       end
       else if (C_MEM_DATA_WIDTH_INT == 128) begin : gen_reorder_initdata_128bit
          assign PhyIF_Init_Data_reorder = {PhyIF_Init_Data_tmp[63:56],
                                            PhyIF_Init_Data_tmp[47:40],
                                            PhyIF_Init_Data_tmp[31:24],
                                            PhyIF_Init_Data_tmp[15:8],
                                            PhyIF_Init_Data_tmp[63:56],
                                            PhyIF_Init_Data_tmp[47:40],
                                            PhyIF_Init_Data_tmp[31:24],
                                            PhyIF_Init_Data_tmp[15:8],
                                            PhyIF_Init_Data_tmp[55:48],
                                            PhyIF_Init_Data_tmp[39:32],
                                            PhyIF_Init_Data_tmp[23:16],
                                            PhyIF_Init_Data_tmp[7:0],
                                            PhyIF_Init_Data_tmp[55:48],
                                            PhyIF_Init_Data_tmp[39:32],
                                            PhyIF_Init_Data_tmp[23:16],
                                            PhyIF_Init_Data_tmp[7:0]};
       end
    
  
    
       if (P_USE_INIT_PUSH) begin : gen_phyif_initdata
          reg [C_MEM_DATA_WIDTH_INT-1:0] PhyIF_Init_Data_i;
          reg                            PhyIF_Init_Push_i;
          always @(posedge Clk0)
            begin
               PhyIF_Init_Data_i <= PhyIF_Init_Data_reorder;
               PhyIF_Init_Push_i <= PhyIF_Init_Push_tmp; 
            end
          assign PhyIF_Init_Data = PhyIF_Init_Data_i;
          assign PhyIF_Init_Push = PhyIF_Init_Push_i;
       end
       else begin : gen_no_init_push
          assign PhyIF_Init_Data = {C_MEM_DATA_WIDTH_INT{1'b0}};
          assign PhyIF_Init_Push = 1'b0;
       end
    
    
    
       if (C_INCLUDE_ECC_SUPPORT == 0)
         begin : gen_noecc
            assign PhyIF_DP_RdFIFO_Push = PhyIF_DP_RdFIFO_Push_tmp[0];
            assign Ctrl_DP_RdFIFO_WhichPort_Decode_i = Ctrl_DP_RdFIFO_WhichPort_Decode;
            assign PhyIF_DP_DQ_I = rd_data;
            assign wdf_mask_data = ~DP_PhyIF_BE_O;
            assign ECC_Intr = 1'b0; 
            assign ECC_Reg_Out = {C_ECC_NUM_REG{1'b0}};
  
            for (i=0;i<C_MEM_DATA_WIDTH_INT/8;i=i+1)
              begin : gen_wdf_data
                 assign wdf_data[(i+1)*8-1:i*8] = DP_PhyIF_DQ_O[(i+1)*8-1:i*8];
              end
         end
       else
         begin : gen_ecc
           ecc_top
           #(
             .C_FAMILY                 (C_FAMILY),
             .C_USE_MIG_S3_PHY         (C_USE_MIG_S3_PHY),
             .C_USE_MIG_V4_PHY         (C_USE_MIG_V4_PHY),
             .C_USE_MIG_V5_PHY         (C_USE_MIG_V5_PHY),
             .C_USE_MIG_V6_PHY         (C_USE_MIG_V6_PHY),
             .C_USE_INIT_PUSH          (P_USE_INIT_PUSH),
             .C_WR_DATAPATH_TML_PIPELINE(C_WR_DATAPATH_TML_PIPELINE),
             .C_NUM_PORTS              (C_NUM_PORTS),
             .C_USE_STATIC_PHY         (C_USE_STATIC_PHY),
             .C_IS_DDR                 (C_IS_DDR),
             .C_MEM_TYPE               (C_MEM_TYPE),
             .C_MEM_DATA_WIDTH         (C_MEM_DATA_WIDTH),
             .C_MEM_DATA_WIDTH_INT     (C_MEM_DATA_WIDTH_INT),
             .C_MEM_DQS_WIDTH          (C_MEM_DQS_WIDTH),
             .C_MEM_DM_WIDTH_INT       (C_MEM_DM_WIDTH_INT),
             .C_ECC_DATA_WIDTH         (C_ECC_DATA_WIDTH),
             .C_ECC_DATA_WIDTH_INT     (C_ECC_DATA_WIDTH_INT),
             .C_ECC_DQS_WIDTH          (C_ECC_DQS_WIDTH),
             .C_ECC_DM_WIDTH_INT       (C_ECC_DM_WIDTH_INT),
             .C_ECC_DECODE_PIPELINE    (C_ECC_DECODE_PIPELINE),
             .C_ECC_ENCODE_PIPELINE    (C_ECC_ENCODE_PIPELINE),
             .C_ECC_DEFAULT_ON         (C_ECC_DEFAULT_ON),
             .C_ECC_SEC_THRESHOLD      (C_ECC_SEC_THRESHOLD),
             .C_ECC_DEC_THRESHOLD      (C_ECC_DEC_THRESHOLD),
             .C_ECC_PEC_THRESHOLD      (C_ECC_PEC_THRESHOLD),
             .C_INCLUDE_ECC_TEST       (((C_INCLUDE_ECC_TEST==1) || 
                                         (C_DEBUG_REG_ENABLE==1)) ? 1 : 0),
             .C_WR_FIFO_MEM_PIPELINE_SINGLE (C_WR_FIFO_MEM_PIPELINE_SINGLE),
             .C_ECC_NUM_REG            (C_ECC_NUM_REG),
             .C_WDF_RDEN_EARLY         (P_WDF_RDEN_EARLY),
             .RDF_PUSH_BITS            (RDF_PUSH_BITS),
             .C_DELAY_PHYIF_DP_WRFIFO_POP (P_DELAY_PHYIF_DP_WRFIFO_POP)
           )
           ecc_top_0
           (
             .Clk0                     (Clk0),
             .Clk90                    (Clk90),
             .Clk_WrFIFO_TML           (Clk_WrFIFO_TML),
             .Rst                      (Rst[C_NUM_PORTS*2+4]),
             .InitDone                 (InitDone),
             .Bypass_Decode            (ecc_byte_access_en),
             .ecc_write_data0          (ecc_write_data0),
             .ecc_write_data1          (ecc_write_data1),
             .ecc_write_data2          (ecc_write_data2),
             .ecc_write_data3          (ecc_write_data3),
             .Ctrl_DP_RdFIFO_WhichPort_Decode (Ctrl_DP_RdFIFO_WhichPort_Decode),
             .Ctrl_ECC_RdFIFO_Size_i   (Ctrl_ECC_RdFIFO_Size_i),
             .Ctrl_ECC_RdFIFO_RNW_i    (Ctrl_ECC_RdFIFO_RNW_i),
             .Ctrl_ECC_RdFIFO_Addr     (Ctrl_ECC_RdFIFO_Addr),
             .Ctrl_ECC_RdFIFO_Size     (Ctrl_ECC_RdFIFO_Size),
             .Ctrl_ECC_RdFIFO_RNW      (Ctrl_ECC_RdFIFO_RNW),
             .Ctrl_RMW                 (Ctrl_RMW),
             .Ctrl_DP_RdFIFO_WhichPort_Decode_i (Ctrl_DP_RdFIFO_WhichPort_Decode_i),
             .DP_PhyIF_BE_O            (DP_PhyIF_BE_O),
             .DP_PhyIF_DQ_O            (DP_PhyIF_DQ_O),
             .PhyIF_DP_RdFIFO_Push_tmp (PhyIF_DP_RdFIFO_Push_tmp), 
             .PhyIF_Ctrl_InitDone_19   (PhyIF_Ctrl_InitDone[19]),
             .PhyIF_DP_WrFIFO_Pop_i    (PhyIF_DP_WrFIFO_Pop_i),
             .PhyIF_DP_WrFIFO_Pop      (PhyIF_DP_WrFIFO_Pop),
             .PhyIF_Ctrl_InitDone_270  (PhyIF_Ctrl_InitDone_270),
             .PhyIF_DP_RdFIFO_Push     (PhyIF_DP_RdFIFO_Push),
             .PhyIF_DP_DQ_I            (PhyIF_DP_DQ_I),
             .rd_data                  (rd_data),
             .wdf_data                 (wdf_data),
             .wdf_mask_data            (wdf_mask_data),
             .ECC_Reg_In               (ECC_Reg_In),
             .ECC_Reg_CE               (ECC_Reg_CE),
             .ECC_Intr                 (ECC_Intr),
             .ECC_Reg_Out              (ECC_Reg_Out)
           );
         end
        
    
      always @(posedge Clk0) 
        begin
           PhyIF_Ctrl_InitDone_tmp_d1a <= PhyIF_Ctrl_InitDone_tmp;
           PhyIF_Ctrl_InitDone <= {20{PhyIF_Ctrl_InitDone_tmp_d1a}};
           InitDone_i  <= PhyIF_Ctrl_InitDone[0];
           InitDone_i2 <= {C_NUM_PORTS{InitDone_i}};
           InitDone    <= InitDone_i;
        end
      always @(posedge Clk_WrFIFO_TML) 
        begin
           PhyIF_Ctrl_InitDone_tmp_d1b <= PhyIF_Ctrl_InitDone_tmp;
           PhyIF_Ctrl_InitDone_270 <= PhyIF_Ctrl_InitDone_tmp_d1b;
        end
    
      assign PI_InitDone = InitDone_i2;
      assign PI_WrFIFO_Empty = DP_Ctrl_WrFIFO_Empty;
    
      // Ties off the static Phy Reg if it's not being used
      assign Static_Phy_Reg_Out = (C_USE_STATIC_PHY == 1) ? static_phy_reg_out_i : 
                                                            {C_STATIC_PHY_NUM_REG{1'b0}};
    
       // Timing improvement for write path.  8:1 mux now has a full cycle,
       // rather than 3/4 cycle.
       
        reg                                       Ctrl_PhyIF_RAS_n_i2;
        reg                                       Ctrl_PhyIF_CAS_n_i2;
        reg                                       Ctrl_PhyIF_WE_n_i2;
        reg [C_MEM_BANKADDR_WIDTH-1:0]            AP_PhyIF_BankAddr_i2;
        reg [C_MEM_ADDR_WIDTH-1:0]                AP_PhyIF_Addr_i2;
        reg [C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS-1:0] AP_PhyIF_CS_n_i2;
        reg                                       Ctrl_Is_Write_i;
        if ((C_USE_MIG_S3_PHY) && (C_INCLUDE_ECC_SUPPORT == 0)) begin : gen_s3
          always @(posedge Clk_WrFIFO_TML) begin
            Ctrl_Is_Write_i      <= Ctrl_Is_Write;
            Ctrl_PhyIF_RAS_n_i2  <= Ctrl_PhyIF_RAS_n_i;
            Ctrl_PhyIF_CAS_n_i2  <= Ctrl_PhyIF_CAS_n_i;
            Ctrl_PhyIF_WE_n_i2   <= Ctrl_PhyIF_WE_n_i;
            AP_PhyIF_BankAddr_i2 <= AP_PhyIF_BankAddr_i;
            AP_PhyIF_Addr_i2     <= AP_PhyIF_Addr_i;
            AP_PhyIF_CS_n_i2     <= AP_PhyIF_CS_n_i;
          end
        end
        else if ((C_USE_MIG_S3_PHY) && (C_INCLUDE_ECC_SUPPORT == 1)) begin : gen_s3
          //always @(*) begin
          always @(negedge Clk90) begin
            Ctrl_Is_Write_i      <= Ctrl_Is_Write;
            Ctrl_PhyIF_RAS_n_i2  <= Ctrl_PhyIF_RAS_n_i;
            Ctrl_PhyIF_CAS_n_i2  <= Ctrl_PhyIF_CAS_n_i;
            Ctrl_PhyIF_WE_n_i2   <= Ctrl_PhyIF_WE_n_i;
            AP_PhyIF_BankAddr_i2 <= AP_PhyIF_BankAddr_i;
            AP_PhyIF_Addr_i2     <= AP_PhyIF_Addr_i;
            AP_PhyIF_CS_n_i2     <= AP_PhyIF_CS_n_i;
          end
        end
        else begin : gen_normal
          always @(posedge Clk0) begin
            Ctrl_Is_Write_i      <= Ctrl_Is_Write;
            Ctrl_PhyIF_RAS_n_i2  <= Ctrl_PhyIF_RAS_n_i;
            Ctrl_PhyIF_CAS_n_i2  <= Ctrl_PhyIF_CAS_n_i;
            Ctrl_PhyIF_WE_n_i2   <= Ctrl_PhyIF_WE_n_i;
            AP_PhyIF_BankAddr_i2 <= AP_PhyIF_BankAddr_i;
            AP_PhyIF_Addr_i2     <= AP_PhyIF_Addr_i;
            AP_PhyIF_CS_n_i2     <= AP_PhyIF_CS_n_i;
          end
        end     
        assign Ctrl_PhyIF_RAS_n  = Ctrl_Is_Write_i ? Ctrl_PhyIF_RAS_n_i2 :
                                                     Ctrl_PhyIF_RAS_n_i;
        assign Ctrl_PhyIF_CAS_n  = Ctrl_Is_Write_i ? Ctrl_PhyIF_CAS_n_i2 :
                                                     Ctrl_PhyIF_CAS_n_i;
        assign Ctrl_PhyIF_WE_n   = Ctrl_Is_Write_i ? Ctrl_PhyIF_WE_n_i2 :
                                                     Ctrl_PhyIF_WE_n_i;
        assign AP_PhyIF_BankAddr = Ctrl_Is_Write_i ? AP_PhyIF_BankAddr_i2 :
                                                     AP_PhyIF_BankAddr_i;
        assign AP_PhyIF_Addr     = Ctrl_Is_Write_i ? AP_PhyIF_Addr_i2 :
                                                     AP_PhyIF_Addr_i;
        assign AP_PhyIF_CS_n     = Ctrl_Is_Write_i ? AP_PhyIF_CS_n_i2 :
                                                      AP_PhyIF_CS_n_i;
      
       
      // Instantiate PHY Debug registers.
       
        if (C_DEBUG_REG_ENABLE == 1) begin : gen_debug_reg
          assign dbg_idel_up_all        = 0;
          assign dbg_idel_down_all      = 0;
          assign dbg_sel_all_idel_dq    = 0;
          assign dbg_sel_all_idel_dqs   = 0;
          assign dbg_sel_all_idel_gate  = 0;
          mpmc_debug_ctrl_reg #
            (
             .C_FAMILY             (C_FAMILY),
             .C_USE_MIG_S3_PHY     (C_USE_MIG_S3_PHY),
             .C_USE_MIG_V4_PHY     (C_USE_MIG_V4_PHY),
             .C_USE_MIG_V5_PHY     (C_USE_MIG_V5_PHY),
             .C_USE_MIG_V6_PHY     (C_USE_MIG_V6_PHY),
             .C_MEM_TYPE           (C_MEM_TYPE),
             .C_INCLUDE_ECC_SUPPORT(C_INCLUDE_ECC_SUPPORT),
             .C_NUM_DQ_BITS        (C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH),
             .C_NUM_DQS_BITS       (C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH),
             .C_ENC_DQ_BITS        (P_ECC_DQ_BITS+P_DQ_BITS),
             .C_ENC_DQS_BITS       (P_ECC_DQS_BITS+P_DQS_BITS)
             )
            mpmc_debug_ctrl_reg_0
              (
               .Clk                          (Clk0),
               .Clk90                        (Clk90),
               .Rst                          (Rst[C_NUM_PORTS*2+1]),
               .Rst_Phy                      (rst_phy),
               .Rst90_Phy                    (rst90_phy),
               // Global debug Signals
               .Idelayctrl_Rdy_I             (Idelayctrl_Rdy_I),
               .Idelayctrl_Rdy_O             (Idelayctrl_Rdy_O),
               .InitDone                     (InitDone),
               // MIG S3 only debug Signals
               .dbg_calib_delay_sel          (dbg_calib_delay_sel),
               .dbg_calib_phase_cnt          (dbg_calib_phase_cnt),
               .dbg_calib_cnt                (dbg_calib_cnt),
               .dbg_calib_rst_calib          (dbg_calib_rst_calib),
               .dbg_calib_trans_onedtct      (dbg_calib_trans_onedtct),
               .dbg_calib_trans_twodtct      (dbg_calib_trans_twodtct),
               .dbg_calib_enb_trans_two_dtct (dbg_calib_enb_trans_two_dtct),
               .vio_out_dqs_en               (vio_out_dqs_en),
               .vio_out_dqs                  (vio_out_dqs),
               .vio_out_rst_dqs_div_en       (vio_out_rst_dqs_div_en),
               .vio_out_rst_dqs_div          (vio_out_rst_dqs_div),
               // MIG V4 and V5 debug Signals
               .dbg_calib_rden_dly_value     (dbg_calib_rden_dly_value),
               .dbg_calib_rden_dly_en        (dbg_calib_rden_dly_en),
               .dbg_calib_rden_dly           (dbg_calib_rden_dly),
               .dbg_calib_rd_data_sel_value  (dbg_calib_rd_data_sel_value),
               .dbg_calib_rd_data_sel_en     (dbg_calib_rd_data_sel_en),
               .dbg_calib_rd_data_sel        (dbg_calib_rd_data_sel),
               .dbg_calib_dqs_tap_cnt        (dbg_calib_dqs_tap_cnt),
               .dbg_calib_dq_tap_cnt         (dbg_calib_dq_tap_cnt),
               .dbg_idel_up_dq               (dbg_idel_up_dq),
               .dbg_idel_down_dq             (dbg_idel_down_dq),
               .dbg_sel_idel_dq              (dbg_sel_idel_dq),
               .dbg_idel_up_dqs              (dbg_idel_up_dqs),
               .dbg_idel_down_dqs            (dbg_idel_down_dqs),
               .dbg_sel_idel_dqs             (dbg_sel_idel_dqs),
               .dbg_idel_up_gate             (dbg_idel_up_gate),
               .dbg_idel_down_gate           (dbg_idel_down_gate),
               .dbg_sel_idel_gate            (dbg_sel_idel_gate),
               // MIG V4 only debug Signals
               .dbg_calib_delay_rd_fall_value   (dbg_calib_delay_rd_fall_value),
               .dbg_calib_delay_rd_fall_en      (dbg_calib_delay_rd_fall_en),
               .dbg_calib_delay_rd_fall         (dbg_calib_delay_rd_fall),
               .dbg_calib_dq_delay_en_value     (dbg_calib_dq_delay_en_value),
               .dbg_calib_dq_delay_en_en        (dbg_calib_dq_delay_en_en),
               .dbg_calib_dq_delay_en           (dbg_calib_dq_delay_en),
               .dbg_calib_done_v4               (dbg_calib_done_v4),
               .dbg_calib_err_v4                (dbg_calib_err_v4),
               .dbg_calib_sel_done              (dbg_calib_sel_done),
               .dbg_calib_dq_in_byte_align_value(dbg_calib_dq_in_byte_align_value),
               .dbg_calib_dq_in_byte_align_en   (dbg_calib_dq_in_byte_align_en),
               .dbg_calib_dq_in_byte_align      (dbg_calib_dq_in_byte_align),
               .dbg_calib_cal_first_loop_value  (dbg_calib_cal_first_loop_value),
               .dbg_calib_cal_first_loop_en     (dbg_calib_cal_first_loop_en),
               .dbg_calib_cal_first_loop        (dbg_calib_cal_first_loop),
               // MIG V5 only debug Signals
               .dbg_calib_gate_dly_value     (dbg_calib_gate_dly_value),
               .dbg_calib_gate_dly_en        (dbg_calib_gate_dly_en),
               .dbg_calib_gate_dly           (dbg_calib_gate_dly),
               .dbg_calib_done_v5            (dbg_calib_done_v5),
               .dbg_calib_err_v5             (dbg_calib_err_v5),
               .dbg_calib_bit_err_index      (dbg_calib_bit_err_index),
               .dbg_calib_gate_tap_cnt       (dbg_calib_gate_tap_cnt),
               // ECC SW Calibration signals
               .ecc_byte_access_en           (ecc_byte_access_en),
               .ecc_write_data0              (ecc_write_data0),
               .ecc_write_data1              (ecc_write_data1),
               .ecc_write_data2              (ecc_write_data2),
               .ecc_write_data3              (ecc_write_data3),
               .ecc_read_data0               (ecc_read_data0),
               .ecc_read_data1               (ecc_read_data1),
               .ecc_read_data2               (ecc_read_data2),
               .ecc_read_data3               (ecc_read_data3),
               // Signals from/to mpmc_ctrl_if
               .Debug_Ctrl_Addr              (Debug_Ctrl_Addr),
               .Debug_Ctrl_WE                (Debug_Ctrl_WE),
               .Debug_Ctrl_In                (Debug_Ctrl_In),
               .Debug_Ctrl_Out               (Debug_Ctrl_Out)
               );
        end else begin : gen_no_debug_reg
          reg rst_phy_i;
          reg rst90_phy_i;
          assign rst_phy = rst_phy_i;
          assign rst90_phy = rst90_phy_i;
          always @(posedge Clk0) rst_phy_i <= Rst[C_NUM_PORTS*2+1];
          always @(posedge Clk90) rst90_phy_i <= Rst90;
          assign vio_out_dqs_en         = 0;
          assign vio_out_dqs            = 0;
          assign vio_out_rst_dqs_div_en = 0;
          assign vio_out_rst_dqs_div    = 0;
          assign dbg_idel_up_all        = 0;
          assign dbg_idel_down_all      = 0;
          assign dbg_sel_all_idel_dq    = 0;
          assign dbg_sel_all_idel_dqs   = 0;
          assign dbg_sel_all_idel_gate  = 0;
          assign dbg_idel_up_dq         = 0;
          assign dbg_idel_down_dq       = 0;
          assign dbg_sel_idel_dq        = 0;
          assign dbg_idel_up_dqs        = 0;
          assign dbg_idel_down_dqs      = 0;
          assign dbg_sel_idel_dqs       = 0;
          assign dbg_idel_up_gate       = 0;
          assign dbg_idel_down_gate     = 0;
          assign dbg_sel_idel_gate      = 0;
          assign Debug_Ctrl_Out         = 32'h0;
          assign ecc_byte_access_en     = 0;
          assign ecc_write_data0        = 8'h00;
          assign ecc_write_data1        = 8'h00;
          assign ecc_write_data2        = 8'h00;
          assign ecc_write_data3        = 8'h00;
        end
      
     end
  endgenerate

/* We need to tie off the bidirection signals that aren't being used  in the 
phy layer to pass through synthesis */
generate
  if (C_USE_MCB_S6_PHY == 0) begin : no_mcb_phy
    assign mcbx_dram_dq     = {C_MEM_DATA_WIDTH{1'b0}};
    assign mcbx_dram_dqs    = 0;
    assign mcbx_dram_dqs_n  = 0;
    assign mcbx_dram_udqs   = 0;
    assign mcbx_dram_udqs_n = 0;
    assign zio              = 0;
    assign rzq              = 0;
  end
  if (C_MEM_TYPE != "DDR3" || C_USE_MCB_S6_PHY == 1) begin : no_ddr3_phy
    assign DDR3_DQ   = {(C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH){1'b0}};
    assign DDR3_DQS  = {(C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH){1'b0}};
    assign DDR3_DQS_n  = {(C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH){1'b0}};
  end
  if (C_MEM_TYPE != "DDR2" || C_USE_MCB_S6_PHY == 1) begin : no_ddr2_phy
    assign DDR2_DQ   = {(C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH){1'b0}};
    assign DDR2_DQS  = {(C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH){1'b0}};
    assign DDR2_DQS_n  = {(C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH){1'b0}};
  end
  if (C_MEM_TYPE != "DDR" || C_USE_MCB_S6_PHY == 1) begin : no_ddr_phy
    assign DDR_DQ   = {(C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH){1'b0}};
    assign DDR_DQS  = {(C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH){1'b0}};
  end
  if (C_MEM_TYPE != "SDRAM" || C_USE_MCB_S6_PHY == 1) begin : no_sdram_phy
    assign SDRAM_DQ = {(C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH){1'b0}};
  end
endgenerate

/* Instantiate the Phy Layer */
  generate
    if (C_USE_MCB_S6_PHY) 
      begin : gen_spartan6_mcb
        wire                                   ioclk0;
        wire                                   ioclk180;
        wire                                   pll_ce_0;
        wire                                   pll_ce_90;
        wire                                   gclk;
        
        if (C_MCB_USE_EXTERNAL_BUFPLL == 0) begin : gen_spartan6_bufpll_mcb
          assign gclk = (C_MCB_DRP_CLK_PRESENT) ? MCB_DRP_Clk : Clk0;
          // Instantiate the PLL for MCB.
          BUFPLL_MCB #
            (
             .DIVIDE   (2),
             .LOCK_SRC (C_BUFPLL_0_LOCK_SRC) 
             ) 
            bufpll_0
              (
               .IOCLK0       (ioclk0), 
               .IOCLK1       (ioclk180), 
               .GCLK         (gclk),
               .LOCK         (pll_lock),
               .LOCKED       (pll_locked),
               .SERDESSTROBE0(pll_ce_0), 
               .SERDESSTROBE1(pll_ce_90), 
               .PLLIN0       (Clk_Mem_2x), 
               .PLLIN1       (Clk_Mem_2x_180)  
               ); 
        end else begin : gen_spartan6_no_bufpll_mcb
          // Use external bufpll_mcb.
          assign ioclk0     = Clk_Mem_2x;
          assign ioclk180   = Clk_Mem_2x_180;
          assign pll_ce_0   = Clk_Mem_2x_CE0;
          assign pll_ce_90  = Clk_Mem_2x_CE90;
          assign pll_lock = pll_locked;
          
        end
        
        assign Clk_Mem_2x_bufpll_o      = ioclk0;
        assign Clk_Mem_2x_180_bufpll_o  = ioclk180;
        assign Clk_Mem_2x_CE0_bufpll_o  = pll_ce_0;
        assign Clk_Mem_2x_CE90_bufpll_o = pll_ce_90;

        // Instantiate Spartan-6 Phy Wrapper.
        s6_phy_top #
          (
           .C_MEM_TYPE                         (C_MEM_TYPE),
           .C_PORT_CONFIG                      (C_PORT_CONFIG),
           .C_MEM_PART_NUM_COL_BITS            (C_MEM_PART_NUM_COL_BITS),
           .C_ARB0_NUM_SLOTS                   (C_ARB0_NUM_SLOTS),
           .C_MEM_ADDR_ORDER                   (C_MEM_ADDR_ORDER),
           .C_MEM_CALIBRATION_MODE             (C_MEM_CALIBRATION_MODE),
           .C_MEM_CALIBRATION_DELAY            (C_MEM_CALIBRATION_DELAY),
           .C_MEM_CALIBRATION_SOFT_IP          (C_MEM_CALIBRATION_SOFT_IP),
           .C_MEM_SKIP_IN_TERM_CAL             (C_MEM_SKIP_IN_TERM_CAL),
           .C_MEM_SKIP_DYNAMIC_CAL             (C_MEM_SKIP_DYNAMIC_CAL),
           .C_MEM_SKIP_DYN_IN_TERM             (C_MEM_SKIP_DYN_IN_TERM),
           .C_MEM_CALIBRATION_BYPASS           (C_MEM_CALIBRATION_BYPASS),
           .C_SIMULATION                       (P_SIMULATION),
           .C_MCB_DRP_CLK_PRESENT              (C_MCB_DRP_CLK_PRESENT),
           .C_MEM_TZQINIT_MAXCNT               (C_MEM_TZQINIT_MAXCNT),
           .C_MPMC_CLK_MEM_2X_PERIOD_PS        (C_MPMC_CLK_MEM_2X_PERIOD_PS),
           .C_NUM_PORTS                        (C_NUM_PORTS),
           .C_MEM_PA_SR                        (C_MEM_PA_SR),
           .C_MEM_CAS_WR_LATENCY               (C_MEM_CAS_WR_LATENCY),
           .C_MEM_AUTO_SR                      (C_MEM_AUTO_SR),
           .C_MEM_HIGH_TEMP_SR                 (C_MEM_HIGH_TEMP_SR),
           .C_MEM_DYNAMIC_WRITE_ODT            (C_MEM_DYNAMIC_WRITE_ODT),
           .C_MEM_CAS_LATENCY0                 (C_MEM_CAS_LATENCY0),
           .C_MEM_BURST_LENGTH                 (C_MEM_BURST_LENGTH),
           .C_MEM_ODT_TYPE                     (C_MEM_ODT_TYPE),
           .C_MEM_REDUCED_DRV                  (C_MEM_REDUCED_DRV),
           .C_MEM_PART_TRAS                    (C_MEM_PART_TRAS),
           .C_MEM_PART_TRCD                    (C_MEM_PART_TRCD),
           .C_MEM_PART_TREFI                   (C_MEM_PART_TREFI),
           .C_MEM_PART_TRP                     (C_MEM_PART_TRP),
           .C_MEM_PART_TRFC                    (C_MEM_PART_TRFC),
           .C_MEM_PART_TWR                     (C_MEM_PART_TWR),
           .C_MEM_PART_TWTR                    (C_MEM_PART_TWTR),
           .C_MEM_PART_TRTP                    (C_MEM_PART_TRTP),
           .C_MEM_DQSN_ENABLE                  (C_MEM_DQSN_ENABLE),
           .C_MEM_ADDR_WIDTH                   (C_MEM_ADDR_WIDTH),
           .C_MEM_BANKADDR_WIDTH               (C_MEM_BANKADDR_WIDTH),
           .C_MEM_DATA_WIDTH                   (C_MEM_DATA_WIDTH),
           .C_PIX_ADDR_WIDTH_MAX               (C_PIX_ADDR_WIDTH_MAX),
           .C_PIX_DATA_WIDTH_MAX               (C_PIX_DATA_WIDTH_MAX),
           .C_PI_DATA_WIDTH                    (C_PI_DATA_WIDTH),
           .C_PIX_BE_WIDTH_MAX                 (C_PIX_BE_WIDTH_MAX),
           .C_PIX_RDWDADDR_WIDTH_MAX           (C_PIX_RDWDADDR_WIDTH_MAX),
                                               
           .C_ARB0_ALGO                        (C_ARB0_ALGO),
           .C_ARB_BRAM_INIT_00                 (C_ARB_BRAM_INIT_00),
        
           // Port Parameters
           // Port 0
           .C_PIM0_BASETYPE                    (C_PIM0_BASETYPE),
           .C_PI0_ADDR_WIDTH                   (C_PI0_ADDR_WIDTH),
           .C_PI0_DATA_WIDTH                   (C_PI0_DATA_WIDTH),
           .C_PI0_BE_WIDTH                     (C_PI0_BE_WIDTH),
           .C_PI0_RDWDADDR_WIDTH               (C_PI0_RDWDADDR_WIDTH),
           // Port 1
           .C_PIM1_BASETYPE                    (C_PIM1_BASETYPE),
           .C_PI1_ADDR_WIDTH                   (C_PI1_ADDR_WIDTH),
           .C_PI1_DATA_WIDTH                   (C_PI1_DATA_WIDTH),
           .C_PI1_BE_WIDTH                     (C_PI1_BE_WIDTH),
           .C_PI1_RDWDADDR_WIDTH               (C_PI1_RDWDADDR_WIDTH),
           // Port 2
           .C_PIM2_BASETYPE                    (C_PIM2_BASETYPE),
           .C_PI2_ADDR_WIDTH                   (C_PI2_ADDR_WIDTH),
           .C_PI2_DATA_WIDTH                   (C_PI2_DATA_WIDTH),
           .C_PI2_BE_WIDTH                     (C_PI2_BE_WIDTH),
           .C_PI2_RDWDADDR_WIDTH               (C_PI2_RDWDADDR_WIDTH),
           // Port 3
           .C_PIM3_BASETYPE                    (C_PIM3_BASETYPE),
           .C_PI3_ADDR_WIDTH                   (C_PI3_ADDR_WIDTH),
           .C_PI3_DATA_WIDTH                   (C_PI3_DATA_WIDTH),
           .C_PI3_BE_WIDTH                     (C_PI3_BE_WIDTH),
           .C_PI3_RDWDADDR_WIDTH               (C_PI3_RDWDADDR_WIDTH),
           // Port 4
           .C_PIM4_BASETYPE                    (C_PIM4_BASETYPE),
           .C_PI4_ADDR_WIDTH                   (C_PI4_ADDR_WIDTH),
           .C_PI4_DATA_WIDTH                   (C_PI4_DATA_WIDTH),
           .C_PI4_BE_WIDTH                     (C_PI4_BE_WIDTH),
           .C_PI4_RDWDADDR_WIDTH               (C_PI4_RDWDADDR_WIDTH),
           // Port 5
           .C_PIM5_BASETYPE                    (C_PIM5_BASETYPE),
           .C_PI5_ADDR_WIDTH                   (C_PI5_ADDR_WIDTH),
           .C_PI5_DATA_WIDTH                   (C_PI5_DATA_WIDTH),
           .C_PI5_BE_WIDTH                     (C_PI5_BE_WIDTH),
           .C_PI5_RDWDADDR_WIDTH               (C_PI5_RDWDADDR_WIDTH),
           // Port 6
           .C_PI6_ADDR_WIDTH                   (C_PI6_ADDR_WIDTH),
           .C_PI6_DATA_WIDTH                   (C_PI6_DATA_WIDTH),
           .C_PI6_BE_WIDTH                     (C_PI6_BE_WIDTH),
           .C_PI6_RDWDADDR_WIDTH               (C_PI6_RDWDADDR_WIDTH),
           // Port 7
           .C_PI7_ADDR_WIDTH                   (C_PI7_ADDR_WIDTH),
           .C_PI7_DATA_WIDTH                   (C_PI7_DATA_WIDTH),
           .C_PI7_BE_WIDTH                     (C_PI7_BE_WIDTH),
           .C_PI7_RDWDADDR_WIDTH               (C_PI7_RDWDADDR_WIDTH),
           
           .C_MCB_LDQSP_TAP_DELAY_VAL          (C_MCB_LDQSP_TAP_DELAY_VAL),  // 0 to 255 inclusive
           .C_MCB_UDQSP_TAP_DELAY_VAL          (C_MCB_UDQSP_TAP_DELAY_VAL),  // 0 to 255 inclusive
           .C_MCB_LDQSN_TAP_DELAY_VAL          (C_MCB_LDQSN_TAP_DELAY_VAL),  // 0 to 255 inclusive
           .C_MCB_UDQSN_TAP_DELAY_VAL          (C_MCB_UDQSN_TAP_DELAY_VAL),  // 0 to 255 inclusive
           .C_MCB_DQ0_TAP_DELAY_VAL            (C_MCB_DQ0_TAP_DELAY_VAL),  // 0 to 255 inclusive
           .C_MCB_DQ1_TAP_DELAY_VAL            (C_MCB_DQ1_TAP_DELAY_VAL),  // 0 to 255 inclusive
           .C_MCB_DQ2_TAP_DELAY_VAL            (C_MCB_DQ2_TAP_DELAY_VAL),  // 0 to 255 inclusive
           .C_MCB_DQ3_TAP_DELAY_VAL            (C_MCB_DQ3_TAP_DELAY_VAL),  // 0 to 255 inclusive
           .C_MCB_DQ4_TAP_DELAY_VAL            (C_MCB_DQ4_TAP_DELAY_VAL),  // 0 to 255 inclusive
           .C_MCB_DQ5_TAP_DELAY_VAL            (C_MCB_DQ5_TAP_DELAY_VAL),  // 0 to 255 inclusive
           .C_MCB_DQ6_TAP_DELAY_VAL            (C_MCB_DQ6_TAP_DELAY_VAL),  // 0 to 255 inclusive
           .C_MCB_DQ7_TAP_DELAY_VAL            (C_MCB_DQ7_TAP_DELAY_VAL),  // 0 to 255 inclusive
           .C_MCB_DQ8_TAP_DELAY_VAL            (C_MCB_DQ8_TAP_DELAY_VAL),  // 0 to 255 inclusive
           .C_MCB_DQ9_TAP_DELAY_VAL            (C_MCB_DQ9_TAP_DELAY_VAL),  // 0 to 255 inclusive
           .C_MCB_DQ10_TAP_DELAY_VAL           (C_MCB_DQ10_TAP_DELAY_VAL),  // 0 to 255 inclusive
           .C_MCB_DQ11_TAP_DELAY_VAL           (C_MCB_DQ11_TAP_DELAY_VAL),  // 0 to 255 inclusive
           .C_MCB_DQ12_TAP_DELAY_VAL           (C_MCB_DQ12_TAP_DELAY_VAL),  // 0 to 255 inclusive
           .C_MCB_DQ13_TAP_DELAY_VAL           (C_MCB_DQ13_TAP_DELAY_VAL),  // 0 to 255 inclusive
           .C_MCB_DQ14_TAP_DELAY_VAL           (C_MCB_DQ14_TAP_DELAY_VAL),  // 0 to 255 inclusive
           .C_MCB_DQ15_TAP_DELAY_VAL           (C_MCB_DQ15_TAP_DELAY_VAL)  // 0 to 255 inclusive
           )
          s6_phy_top_if
            (
             // System Signals
             .Clk0                      (Clk0),
             .MCB_DRP_Clk               (MCB_DRP_Clk) ,
             .sysclk_2x                 (ioclk0), 
             .sysclk_2x_180             (ioclk180), 
             .pll_ce_0                  (pll_ce_0), 
             .pll_ce_90                 (pll_ce_90), 
             .pll_lock                  (pll_lock),
             .Rst                       (Rst[C_NUM_PORTS*2+1]),
             .mcbx_InitDone             (mcbx_InitDone),
          
             // Spartan6
             .mcbx_dram_addr            (mcbx_dram_addr),
             .mcbx_dram_ba              (mcbx_dram_ba),
             .mcbx_dram_ras_n           (mcbx_dram_ras_n),
             .mcbx_dram_cas_n           (mcbx_dram_cas_n),
             .mcbx_dram_we_n            (mcbx_dram_we_n),
             
             .mcbx_dram_cke             (mcbx_dram_cke),
             .mcbx_dram_clk             (mcbx_dram_clk),
             .mcbx_dram_clk_n           (mcbx_dram_clk_n),
             .mcbx_dram_dq              (mcbx_dram_dq),
             .mcbx_dram_dqs             (mcbx_dram_dqs),
             .mcbx_dram_dqs_n           (mcbx_dram_dqs_n),
             .mcbx_dram_udqs            (mcbx_dram_udqs),
             .mcbx_dram_udqs_n          (mcbx_dram_udqs_n),
             
             .mcbx_dram_udm             (mcbx_dram_udm),
             .mcbx_dram_ldm             (mcbx_dram_ldm),
             .mcbx_dram_odt             (mcbx_dram_odt),
             .mcbx_dram_ddr3_rst        (mcbx_dram_ddr3_rst),
          
             // Spartan6 Calibration signals
             .selfrefresh_enter         (selfrefresh_enter),
             .selfrefresh_mode          (selfrefresh_mode),
             .calib_recal               (calib_recal),
             .rzq                       (rzq),
             .zio                       (zio),
          
             // Native MCB ports.
             .MCB0_cmd_clk              (MCB0_cmd_clk),
             .MCB0_cmd_en               (MCB0_cmd_en),
             .MCB0_cmd_instr            (MCB0_cmd_instr),
             .MCB0_cmd_bl               (MCB0_cmd_bl),
             .MCB0_cmd_byte_addr        (MCB0_cmd_byte_addr),
             .MCB0_cmd_empty            (MCB0_cmd_empty),
             .MCB0_cmd_full             (MCB0_cmd_full),
             .MCB0_wr_clk               (MCB0_wr_clk),
             .MCB0_wr_en                (MCB0_wr_en),
             .MCB0_wr_mask              (MCB0_wr_mask),
             .MCB0_wr_data              (MCB0_wr_data),
             .MCB0_wr_full              (MCB0_wr_full),
             .MCB0_wr_empty             (MCB0_wr_empty),
             .MCB0_wr_count             (MCB0_wr_count),
             .MCB0_wr_underrun          (MCB0_wr_underrun),
             .MCB0_wr_error             (MCB0_wr_error),
             .MCB0_rd_clk               (MCB0_rd_clk),
             .MCB0_rd_en                (MCB0_rd_en),
             .MCB0_rd_data              (MCB0_rd_data),
             .MCB0_rd_full              (MCB0_rd_full),
             .MCB0_rd_empty             (MCB0_rd_empty),
             .MCB0_rd_count             (MCB0_rd_count),
             .MCB0_rd_overflow          (MCB0_rd_overflow),
             .MCB0_rd_error             (MCB0_rd_error),
             .MCB1_cmd_clk              (MCB1_cmd_clk),
             .MCB1_cmd_en               (MCB1_cmd_en),
             .MCB1_cmd_instr            (MCB1_cmd_instr),
             .MCB1_cmd_bl               (MCB1_cmd_bl),
             .MCB1_cmd_byte_addr        (MCB1_cmd_byte_addr),
             .MCB1_cmd_empty            (MCB1_cmd_empty),
             .MCB1_cmd_full             (MCB1_cmd_full),
             .MCB1_wr_clk               (MCB1_wr_clk),
             .MCB1_wr_en                (MCB1_wr_en),
             .MCB1_wr_mask              (MCB1_wr_mask),
             .MCB1_wr_data              (MCB1_wr_data),
             .MCB1_wr_full              (MCB1_wr_full),
             .MCB1_wr_empty             (MCB1_wr_empty),
             .MCB1_wr_count             (MCB1_wr_count),
             .MCB1_wr_underrun          (MCB1_wr_underrun),
             .MCB1_wr_error             (MCB1_wr_error),
             .MCB1_rd_clk               (MCB1_rd_clk),
             .MCB1_rd_en                (MCB1_rd_en),
             .MCB1_rd_data              (MCB1_rd_data),
             .MCB1_rd_full              (MCB1_rd_full),
             .MCB1_rd_empty             (MCB1_rd_empty),
             .MCB1_rd_count             (MCB1_rd_count),
             .MCB1_rd_overflow          (MCB1_rd_overflow),
             .MCB1_rd_error             (MCB1_rd_error),
             .MCB2_cmd_clk              (MCB2_cmd_clk),
             .MCB2_cmd_en               (MCB2_cmd_en),
             .MCB2_cmd_instr            (MCB2_cmd_instr),
             .MCB2_cmd_bl               (MCB2_cmd_bl),
             .MCB2_cmd_byte_addr        (MCB2_cmd_byte_addr),
             .MCB2_cmd_empty            (MCB2_cmd_empty),
             .MCB2_cmd_full             (MCB2_cmd_full),
             .MCB2_wr_clk               (MCB2_wr_clk),
             .MCB2_wr_en                (MCB2_wr_en),
             .MCB2_wr_mask              (MCB2_wr_mask),
             .MCB2_wr_data              (MCB2_wr_data),
             .MCB2_wr_full              (MCB2_wr_full),
             .MCB2_wr_empty             (MCB2_wr_empty),
             .MCB2_wr_count             (MCB2_wr_count),
             .MCB2_wr_underrun          (MCB2_wr_underrun),
             .MCB2_wr_error             (MCB2_wr_error),
             .MCB2_rd_clk               (MCB2_rd_clk),
             .MCB2_rd_en                (MCB2_rd_en),
             .MCB2_rd_data              (MCB2_rd_data),
             .MCB2_rd_full              (MCB2_rd_full),
             .MCB2_rd_empty             (MCB2_rd_empty),
             .MCB2_rd_count             (MCB2_rd_count),
             .MCB2_rd_overflow          (MCB2_rd_overflow),
             .MCB2_rd_error             (MCB2_rd_error),
             .MCB3_cmd_clk              (MCB3_cmd_clk),
             .MCB3_cmd_en               (MCB3_cmd_en),
             .MCB3_cmd_instr            (MCB3_cmd_instr),
             .MCB3_cmd_bl               (MCB3_cmd_bl),
             .MCB3_cmd_byte_addr        (MCB3_cmd_byte_addr),
             .MCB3_cmd_empty            (MCB3_cmd_empty),
             .MCB3_cmd_full             (MCB3_cmd_full),
             .MCB3_wr_clk               (MCB3_wr_clk),
             .MCB3_wr_en                (MCB3_wr_en),
             .MCB3_wr_mask              (MCB3_wr_mask),
             .MCB3_wr_data              (MCB3_wr_data),
             .MCB3_wr_full              (MCB3_wr_full),
             .MCB3_wr_empty             (MCB3_wr_empty),
             .MCB3_wr_count             (MCB3_wr_count),
             .MCB3_wr_underrun          (MCB3_wr_underrun),
             .MCB3_wr_error             (MCB3_wr_error),
             .MCB3_rd_clk               (MCB3_rd_clk),
             .MCB3_rd_en                (MCB3_rd_en),
             .MCB3_rd_data              (MCB3_rd_data),
             .MCB3_rd_full              (MCB3_rd_full),
             .MCB3_rd_empty             (MCB3_rd_empty),
             .MCB3_rd_count             (MCB3_rd_count),
             .MCB3_rd_overflow          (MCB3_rd_overflow),
             .MCB3_rd_error             (MCB3_rd_error),
             .MCB4_cmd_clk              (MCB4_cmd_clk),
             .MCB4_cmd_en               (MCB4_cmd_en),
             .MCB4_cmd_instr            (MCB4_cmd_instr),
             .MCB4_cmd_bl               (MCB4_cmd_bl),
             .MCB4_cmd_byte_addr        (MCB4_cmd_byte_addr),
             .MCB4_cmd_empty            (MCB4_cmd_empty),
             .MCB4_cmd_full             (MCB4_cmd_full),
             .MCB4_wr_clk               (MCB4_wr_clk),
             .MCB4_wr_en                (MCB4_wr_en),
             .MCB4_wr_mask              (MCB4_wr_mask[3:0]),
             .MCB4_wr_data              (MCB4_wr_data[31:0]),
             .MCB4_wr_full              (MCB4_wr_full),
             .MCB4_wr_empty             (MCB4_wr_empty),
             .MCB4_wr_count             (MCB4_wr_count),
             .MCB4_wr_underrun          (MCB4_wr_underrun),
             .MCB4_wr_error             (MCB4_wr_error),
             .MCB4_rd_clk               (MCB4_rd_clk),
             .MCB4_rd_en                (MCB4_rd_en),
             .MCB4_rd_data              (MCB4_rd_data[31:0]),
             .MCB4_rd_full              (MCB4_rd_full),
             .MCB4_rd_empty             (MCB4_rd_empty),
             .MCB4_rd_count             (MCB4_rd_count),
             .MCB4_rd_overflow          (MCB4_rd_overflow),
             .MCB4_rd_error             (MCB4_rd_error),
             .MCB5_cmd_clk              (MCB5_cmd_clk),
             .MCB5_cmd_en               (MCB5_cmd_en),
             .MCB5_cmd_instr            (MCB5_cmd_instr),
             .MCB5_cmd_bl               (MCB5_cmd_bl),
             .MCB5_cmd_byte_addr        (MCB5_cmd_byte_addr),
             .MCB5_cmd_empty            (MCB5_cmd_empty),
             .MCB5_cmd_full             (MCB5_cmd_full),
             .MCB5_wr_clk               (MCB5_wr_clk),
             .MCB5_wr_en                (MCB5_wr_en),
             .MCB5_wr_mask              (MCB5_wr_mask[3:0]),
             .MCB5_wr_data              (MCB5_wr_data[31:0]),
             .MCB5_wr_full              (MCB5_wr_full),
             .MCB5_wr_empty             (MCB5_wr_empty),
             .MCB5_wr_count             (MCB5_wr_count),
             .MCB5_wr_underrun          (MCB5_wr_underrun),
             .MCB5_wr_error             (MCB5_wr_error),
             .MCB5_rd_clk               (MCB5_rd_clk),
             .MCB5_rd_en                (MCB5_rd_en),
             .MCB5_rd_data              (MCB5_rd_data[31:0]),
             .MCB5_rd_full              (MCB5_rd_full),
             .MCB5_rd_empty             (MCB5_rd_empty),
             .MCB5_rd_count             (MCB5_rd_count),
             .MCB5_rd_overflow          (MCB5_rd_overflow),
             .MCB5_rd_error             (MCB5_rd_error),
           
             // Port 0
             // Port Interface Status Signals
             .PI_InitDone               (PI_InitDone),
             // Port Interface Request/Acknowledge/Address Signals
             .PI_Addr                   (PI_Addr),
             .PI_AddrReq                (PI_AddrReq),
             .PI_AddrAck                (PI_AddrAck),
             .PI_RNW                    (PI_RNW),
             .PI_Size                   (PI_Size),
             .PI_RdModWr                (PI_RdModWr),
             // Port Interface Data Signals
             .PI_WrFIFO_Data            (PI_WrFIFO_Data),
             .PI_WrFIFO_BE              (PI_WrFIFO_BE),
             .PI_WrFIFO_Push            (PI_WrFIFO_Push),
             .PI_RdFIFO_Data            (PI_RdFIFO_Data),
             .PI_RdFIFO_Pop             (PI_RdFIFO_Pop),
             .PI_RdFIFO_RdWdAddr        (PI_RdFIFO_RdWdAddr),
             // Port Interface FIFO control/status
             .PI_WrFIFO_Empty           (PI_WrFIFO_Empty),
             .PI_WrFIFO_AlmostFull      (PI_WrFIFO_AlmostFull),
             .PI_WrFIFO_Flush           (PI_WrFIFO_Flush),
             .PI_RdFIFO_Empty           (PI_RdFIFO_Empty),
             .PI_RdFIFO_Flush           (PI_RdFIFO_Flush)
             );
        
      end
    else if (C_USE_STATIC_PHY==1 && C_MEM_TYPE == "DDR2") 
      begin : gen_static_phy_ddr2
        static_phy_top #
          (
           .FAMILY         (C_FAMILY),
           //*****************************************************************
           .C_RDDATA_CLK_SEL   (C_STATIC_PHY_RDDATA_CLK_SEL),
           .C_RDDATA_SWAP_RISE (C_STATIC_PHY_RDDATA_SWAP_RISE),
           .C_RDEN_DELAY       (C_STATIC_PHY_RDEN_DELAY),
           .C_NUM_REG          (C_STATIC_PHY_NUM_REG),
           //*****************************************************************
           .WDF_RDEN_EARLY (P_WDF_RDEN_EARLY),
           .ECC_ENABLE     (C_INCLUDE_ECC_SUPPORT),
           .ADDITIVE_LAT   (C_MEM_ADDITIVE_LATENCY),
           .BURST_LEN      (C_MEM_BURST_LENGTH),
           .BURST_TYPE     (0),
           .CAS_LAT        (C_MEM_CAS_LATENCY0),
           .DQSN_ENABLE    (C_MEM_DQSN_ENABLE),
           .ODT_TYPE       (C_MEM_ODT_TYPE),
           .REDUCE_DRV     (C_MEM_REDUCED_DRV),
           .REG_ENABLE     (C_MEM_REG_DIMM),
           .DDR2_ENABLE    (C_MEM_DDR2_ENABLE),
           .WDF_RDEN_WIDTH (C_NUM_PORTS),
           .BANK_WIDTH     (C_MEM_BANKADDR_WIDTH),
           .CLK_WIDTH      (C_MEM_CLK_WIDTH),
           .CKE_WIDTH      (C_MEM_CE_WIDTH),
           .COL_WIDTH      (C_MEM_ADDR_WIDTH),
           .CS_WIDTH       (C_MEM_CS_N_WIDTH),
           .DM_WIDTH       (C_ECC_DM_WIDTH+C_MEM_DM_WIDTH),
           .DQ_WIDTH       (C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH),
           .DQS_WIDTH      (C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH),
           .DQ_PER_DQS     (C_MEM_DATA_WIDTH/C_MEM_DQS_WIDTH),
           .ODT_WIDTH      (C_MEM_ODT_WIDTH),
           .ROW_WIDTH      (C_MEM_ADDR_WIDTH),
           .CS_NUM         (C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS),
           .CLK_PERIOD     (C_MPMC_CLK_PERIOD),
           .SIM_ONLY       (C_SKIP_INIT_DELAY)
           )
          mpmc_phy_if_0
            (
             // Clocks/Resets
             .clk0              (Clk0),
             .clk90             (Clk90),
             .rst0              (rst_phy),
             .rst90             (rst90_phy),
             .clk0_rddata       (Clk_Mem),
             .dcm_en            (DCM_PSEN),
             .dcm_incdec        (DCM_PSINCDEC),
             .dcm_done          (DCM_PSDONE),
             .reg_ce            (Static_Phy_Reg_CE),
             .reg_in            (Static_Phy_Reg_In),
             .reg_out           (static_phy_reg_out_i),
             // Initialization Signals
             .phy_init_done     (PhyIF_Ctrl_InitDone_tmp), // Set to 0 from 
                                                     // rst until end of init 
                                                     // and calibration.
             .ctrl_ref_flag     (Ctrl_Refresh_Flag), // One cycle high pulse
                                                     // every time refresh 
                                                     // is requested.
                                                     // Memory Control Signals
             .ctrl_addr         (AP_PhyIF_Addr),     // Pre IOB FF mem 
                                                     // address.
             .ctrl_ba           (AP_PhyIF_BankAddr), // Pre IOB FF mem 
                                                     // bank address.
             .ctrl_ras_n        (Ctrl_PhyIF_RAS_n),  // Pre IOB FF mem RAS.
             .ctrl_cas_n        (Ctrl_PhyIF_CAS_n),  // Pre IOB FF mem CAS.
             .ctrl_we_n         (Ctrl_PhyIF_WE_n),   // Pre IOB FF mem WE.
             .ctrl_cs_n         (AP_PhyIF_CS_n),     // Pre IOB FF mem CS.
             // Memory Write Signals
             .ctrl_wren         (Ctrl_PhyIF_DQS_O),  // Indicator that DQS
                                                     // should toggle.
             .wdf_data          (wdf_data),          // Pre IOB FF write 
                                                     // data.
             .wdf_mask_data     (wdf_mask_data),     // Pre IOB FF write 
                                                     // data mask.
             .wdf_rden          (PhyIF_DP_WrFIFO_Pop), // Write FIFO pop.
             // Memory Read Signals
             .ctrl_rden         (Ctrl_DP_RdFIFO_Push), // Pulse high for number
                                                     // of cycles read push 
                                                     // will be asserted. Needs
                                                     // to be high one cycle 
                                                     // befor ctrl_<ras/cas/we>
                                                     // indicate read.
             .phy_calib_rden    (PhyIF_DP_RdFIFO_Push_tmp), // Rd FIFO push.
             .rd_data_rise      (rd_data[C_ECC_DATA_WIDTH+
                                         C_MEM_DATA_WIDTH_INT/2-1:0]), 
                                                     // Post IOB FF LSB read 
                                                     // data.
             .rd_data_fall      (rd_data[C_ECC_DATA_WIDTH*2+
                                         C_MEM_DATA_WIDTH_INT-1:
                                         C_ECC_DATA_WIDTH+
                                         C_MEM_DATA_WIDTH_INT/2]),
                                                     // Post IOB FF MSB read 
                                                     // data.
             // Memory I/Os
             .ddr_ck            (Mem_Clk_O),      // Post IOB FF mem clock.
             .ddr_ck_n          (Mem_Clk_n_O),    // Post IOB FF mem inverse
                                                  // clock.
             .ddr_addr          (Mem_Addr_O),     // Post IOB FF mem address
             .ddr_ba            (Mem_BankAddr_O), // Post IOB FF mem bank 
                                                  // address.
             .ddr_ras_n         (Mem_RAS_n_O),    // Post IOB FF mem RAS.
             .ddr_cas_n         (Mem_CAS_n_O),    // Post IOB FF mem CAS.
             .ddr_we_n          (Mem_WE_n_O),     // Post IOB FF mem WE.
             .ddr_cs_n          (Mem_CS_n_O),     // Post IOB FF mem CS.
             .ddr_cke           (Mem_CE_O),       // Post IOB FF mem CKE.
             .ddr_odt           (Mem_ODT_O),      // Post IOB FF mem ODT.
             .ddr_dm            (Mem_DM_O),       // Post IOB FF mem data 
                                                  // mask.
             .ddr_dqs           (DDR2_DQS),       // Post IOB FF mem data 
                                                  // strobe.
             .ddr_dqs_n         (DDR2_DQS_n),     // Post IOB FF mem data 
                                                  // strobe.
             .ddr_dq            (DDR2_DQ)         // Post IOB FF mem data.
             );
      end
    else if (C_USE_STATIC_PHY==1 && C_MEM_TYPE == "DDR")
      begin : gen_static_phy_ddr
        static_phy_top #
          (
           .FAMILY         (C_FAMILY),
           //******************************************************************
           .C_RDDATA_CLK_SEL   (C_STATIC_PHY_RDDATA_CLK_SEL),
           .C_RDDATA_SWAP_RISE (C_STATIC_PHY_RDDATA_SWAP_RISE),
           .C_RDEN_DELAY       (C_STATIC_PHY_RDEN_DELAY),
           .C_NUM_REG          (C_STATIC_PHY_NUM_REG),
           //******************************************************************
           .WDF_RDEN_EARLY (P_WDF_RDEN_EARLY),
           .ECC_ENABLE     (C_INCLUDE_ECC_SUPPORT),
           .ADDITIVE_LAT   (C_MEM_ADDITIVE_LATENCY),
           .BURST_LEN      (C_MEM_BURST_LENGTH),
           .BURST_TYPE     (0),
           .CAS_LAT        (C_MEM_CAS_LATENCY0),
           .DQSN_ENABLE    (C_MEM_DQSN_ENABLE),
           .ODT_TYPE       (C_MEM_ODT_TYPE),
           .REDUCE_DRV     (C_MEM_REDUCED_DRV),
           .REG_ENABLE     (C_MEM_REG_DIMM),
           .DDR2_ENABLE    (C_MEM_DDR2_ENABLE),
           .WDF_RDEN_WIDTH (C_NUM_PORTS),
           .BANK_WIDTH     (C_MEM_BANKADDR_WIDTH),
           .CLK_WIDTH      (C_MEM_CLK_WIDTH),
           .CKE_WIDTH      (C_MEM_CE_WIDTH),
           .COL_WIDTH      (C_MEM_ADDR_WIDTH),
           .CS_WIDTH       (C_MEM_CS_N_WIDTH),
           .DM_WIDTH       (C_ECC_DM_WIDTH+C_MEM_DM_WIDTH),
           .DQ_WIDTH       (C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH),
           .DQS_WIDTH      (C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH),
           .DQ_PER_DQS     (C_MEM_DATA_WIDTH/C_MEM_DQS_WIDTH),
           .ODT_WIDTH      (C_MEM_ODT_WIDTH),
           .ROW_WIDTH      (C_MEM_ADDR_WIDTH),
           .CS_NUM         (C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS),
           .CLK_PERIOD     (C_MPMC_CLK_PERIOD),
           .SIM_ONLY       (C_SKIP_INIT_DELAY)
           )
          mpmc_phy_if_0
            (
             // Clocks/Resets
             .clk0              (Clk0),
             .clk90             (Clk90),
             .rst0              (rst_phy),
             .rst90             (rst90_phy),
             .clk0_rddata       (Clk_Mem),
             .dcm_en            (DCM_PSEN),
             .dcm_incdec        (DCM_PSINCDEC),
             .dcm_done          (DCM_PSDONE),
             .reg_ce            (Static_Phy_Reg_CE),
             .reg_in            (Static_Phy_Reg_In),
             .reg_out           (static_phy_reg_out_i),
             // Initialization Signals
             .phy_init_done     (PhyIF_Ctrl_InitDone_tmp), // Set to 0 from rst
                                                     // until end of init and 
                                                     // calibration.
             .ctrl_ref_flag     (Ctrl_Refresh_Flag), // One cycle high pulse
                                                     // every time refresh 
                                                     // is requested.
             // Memory Control Signals
             .ctrl_addr         (AP_PhyIF_Addr),     // Pre IOB FF mem 
                                                     // address.
             .ctrl_ba           (AP_PhyIF_BankAddr), // Pre IOB FF mem 
                                                     // bank address.
             .ctrl_ras_n        (Ctrl_PhyIF_RAS_n),  // Pre IOB FF mem RAS.
             .ctrl_cas_n        (Ctrl_PhyIF_CAS_n),  // Pre IOB FF mem CAS.
             .ctrl_we_n         (Ctrl_PhyIF_WE_n),   // Pre IOB FF mem WE.
             .ctrl_cs_n         (AP_PhyIF_CS_n),     // Pre IOB FF mem CS.
             // Memory Write Signals
             .ctrl_wren         (Ctrl_PhyIF_DQS_O),  // Indicator that DQS
                                                     // should toggle.
             .wdf_data          (wdf_data),          // Pre IOB FF write data.
             .wdf_mask_data     (wdf_mask_data),     // Pre IOB FF write data
                                                     // mask.
             .wdf_rden          (PhyIF_DP_WrFIFO_Pop),// Write FIFO pop.
             // Memory Read Signals
             .ctrl_rden         (Ctrl_DP_RdFIFO_Push),// Pulse high for number 
                                                     // of cycles read push 
                                                     // will be // asserted.  
                                                     // Needs to be high one 
                                                     // cycle before 
                                                     // ctrl_<ras/cas/we> 
                                                     // indicate read.
             .phy_calib_rden    (PhyIF_DP_RdFIFO_Push_tmp),// Rd FIFO push.
             .rd_data_rise      (rd_data[C_ECC_DATA_WIDTH+
                                         C_MEM_DATA_WIDTH_INT/2-1:0]), 
                                                     // Post IOB FF LSB read 
                                                     // data.
             .rd_data_fall      (rd_data[C_ECC_DATA_WIDTH*2+
                                         C_MEM_DATA_WIDTH_INT-1:
                                         C_ECC_DATA_WIDTH+
                                         C_MEM_DATA_WIDTH_INT/2]), 
                                                     // Post IOB FF MSB read 
                                                     // data.
             // Memory I/Os
             .ddr_ck            (Mem_Clk_O),      // Post IOB FF mem clock.
             .ddr_ck_n          (Mem_Clk_n_O),    // Post IOB FF mem inverse
                                                  // clock.
             .ddr_addr          (Mem_Addr_O),     // Post IOB FF mem address
             .ddr_ba            (Mem_BankAddr_O), // Post IOB FF mem bank 
                                                  // address.
             .ddr_ras_n         (Mem_RAS_n_O),    // Post IOB FF mem RAS.
             .ddr_cas_n         (Mem_CAS_n_O),    // Post IOB FF mem CAS.
             .ddr_we_n          (Mem_WE_n_O),     // Post IOB FF mem WE.
             .ddr_cs_n          (Mem_CS_n_O),     // Post IOB FF mem CS.
             .ddr_cke           (Mem_CE_O),       // Post IOB FF mem CKE.
             .ddr_odt           (Mem_ODT_O),      // Post IOB FF mem ODT.
             .ddr_dm            (Mem_DM_O),       // Post IOB FF mem data mask.
             .ddr_dqs           (DDR_DQS),        // Post IOB FF mem data 
                                                  // strobe.
             .ddr_dqs_n         (),
             .ddr_dq            (DDR_DQ)          // Post IOB FF mem data.
             );
      end
    else if (C_USE_MIG_V6_PHY && C_MEM_TYPE == "DDR3")
      begin : gen_v6_ddr3_phy
        wire [7:0]                    slot_0_present;             
        wire [7:0]                    slot_1_present;             
        reg  [3:0]                    arb_patternstart_d;         
        reg                           first_phy_io_config_issued; 
        reg                           phy_io_config_last;         
        reg                           phy_io_config_strobe;       
        wire [C_MEM_NUM_RANKS:0]      phy_io_config;              

        // PHY Debug signals
        wire [5*C_MEM_DQS_WIDTH-1:0]  dbg_wr_dqs_tap_set;
        wire [5*C_MEM_DQS_WIDTH-1:0]  dbg_wr_dq_tap_set;
        wire                          dbg_wr_tap_set_en;
        wire                          dbg_idel_up_all;            
        wire                          dbg_idel_down_all;          
        wire                          dbg_idel_up_cpt;            
        wire                          dbg_idel_down_cpt;          
        wire                          dbg_idel_up_rsync;          
        wire                          dbg_idel_down_rsync;        
        wire [P_DQS_BITS-1:0]         dbg_sel_idel_cpt;           
        wire                          dbg_sel_all_idel_cpt;       
        wire [P_DQS_BITS-1:0]         dbg_sel_idel_rsync;         
        wire                          dbg_sel_all_idel_rsync;     
        // Phase Detector
        wire                          dbg_pd_off;                 
        wire                          dbg_pd_maintain_off;        
        wire                          dbg_pd_maintain_0_only; 
        wire                          dbg_pd_inc_cpt;         
        wire                          dbg_pd_dec_cpt;         
        wire                          dbg_pd_inc_dqs;         
        wire                          dbg_pd_dec_dqs;         
        wire                          dbg_pd_disab_hyst;      
        wire                          dbg_pd_disab_hyst_0;    
        wire [3:0]                    dbg_pd_msb_sel;         
        wire [P_DQS_BITS-1:0]         dbg_pd_byte_sel;        
        wire                          dbg_inc_rd_fps;
        wire                          dbg_dec_rd_fps;


        // Assing slot present inputs 
        assign slot_0_present              = 8'b000_0001;
        assign slot_1_present              = 8'b000_0000;

        //assign all 0s to dbg ports input
        assign dbg_wr_dqs_tap_set          = 'b0;
        assign dbg_wr_dq_tap_set           = 'b0;
        assign dbg_wr_tap_set_en           = 'b0;
        assign dbg_idel_up_all             = 'b0;
        assign dbg_idel_down_all           = 'b0;
        assign dbg_idel_up_cpt             = 'b0;
        assign dbg_idel_down_cpt           = 'b0;
        assign dbg_idel_up_rsync           = 'b0;
        assign dbg_idel_down_rsync         = 'b0;
        assign dbg_sel_idel_cpt            = 'b0;
        assign dbg_sel_all_idel_cpt        = 'b0;
        assign dbg_sel_idel_rsync          = 'b0;
        assign dbg_sel_all_idel_rsync      = 'b0;
        assign dbg_pd_off                  = 'b0;
        assign dbg_pd_maintain_off         = 'b0;
        assign dbg_pd_maintain_0_only      = 'b0;
        assign dbg_pd_inc_cpt              = 'b0;
        assign dbg_pd_dec_cpt              = 'b0;
        assign dbg_pd_inc_dqs              = 'b0;
        assign dbg_pd_dec_dqs              = 'b0;
        assign dbg_pd_disab_hyst           = 'b0;
        assign dbg_pd_disab_hyst_0         = 'b0;
        assign dbg_pd_msb_sel              = 'b0;
        assign dbg_pd_byte_sel             = 'b0;
        assign dbg_inc_rd_fps              = 'b0;
        assign dbg_dec_rd_fps              = 'b0;

        assign PhyIF_DP_RdFIFO_Push_tmp[0] = ctrl_dfi_rddata_valid & ~Ctrl_Periodic_Rd_Mask;
        assign PhyIF_DP_WrFIFO_Pop = Ctrl_DP_WrFIFO_WhichPort_Decode & {C_NUM_PORTS{ctrl_dp_wrfifo_pop}};

        // Generate phy_io_config Strobe

        // Save status on whether we have issued an io config strobe.
        // Save status on the last io_config issued;
        always @(posedge Clk0) begin
          if (Rst) begin
            first_phy_io_config_issued <= 1'b0;
            phy_io_config_last  <= 1'b0;
          end
          else if (phy_io_config_strobe) begin
            first_phy_io_config_issued <= 1'b1;
            phy_io_config_last  <= phy_io_config[C_MEM_NUM_RANKS];
          end
        end

        // Generate strobe if transaction has started and this is our first
        // transaction or we are switching from reads to writes or write to
        // reads
        always @(posedge Clk0) begin 
          phy_io_config_strobe <= arb_patternstart_d[3] && (~first_phy_io_config_issued
                                  || (phy_io_config_last ^ phy_io_config[C_MEM_NUM_RANKS]));
        end
            
        // Delay Arb_PatternStart
        always @(posedge Clk0) begin 
          arb_patternstart_d[0] <= Arb_PatternStart;
          arb_patternstart_d[1] <= arb_patternstart_d[0];
          arb_patternstart_d[2] <= arb_patternstart_d[1];
          arb_patternstart_d[3] <= arb_patternstart_d[2];
        end
        // TODO: Update this when we support multiple ranks.
        assign phy_io_config = {Ctrl_Is_Write, {C_MEM_NUM_RANKS{1'b0}}};

        v6_ddrx_top #
          (
           .TCQ                               (P_TCQ),  
           .REFCLK_FREQ                       (P_REFCLK_FREQ),
           .nCS_PER_RANK                      (P_NCS_PER_RANK),
           .CAL_WIDTH                         (P_MEM_CAL_WIDTH), 
           .CS_WIDTH                          (P_CS_WIDTH),
           .nCK_PER_CLK                       (C_NCK_PER_CLK),    
           .CKE_WIDTH                         (C_MEM_CE_WIDTH),
           .DRAM_TYPE                         (C_MEM_TYPE),
           .SLOT_0_CONFIG                     (P_SLOT_0_CONFIG),
           .SLOT_1_CONFIG                     (P_SLOT_1_CONFIG),
           .CLK_PERIOD                        (C_MPMC_CLK_PERIOD),
           .BANK_WIDTH                        (C_MEM_BANKADDR_WIDTH),
           .CK_WIDTH                          (C_MEM_CLK_WIDTH),
           .COL_WIDTH                         (C_MEM_PART_NUM_COL_BITS),
           .DQ_CNT_WIDTH                      (P_DQ_BITS),
           .DM_WIDTH                          (C_MEM_DM_WIDTH),
           .DQ_WIDTH                          (C_MEM_DATA_WIDTH),
           .DQS_CNT_WIDTH                     (P_DQS_BITS),
           .DQS_WIDTH                         (C_MEM_DQS_WIDTH),
           .DRAM_WIDTH                        (C_MEM_BITS_DATA_PER_DQS),
           .ROW_WIDTH                         (C_MEM_ADDR_WIDTH),
           .RANK_WIDTH                        (P_RANK_WIDTH),
           .AL                                (P_AL),
           .BURST_MODE                        (P_BURST_MODE),
           .BURST_TYPE                        (P_BURST_TYPE),
           .nAL                               (),
           .nCL                               (C_MEM_CAS_LATENCY0),
           .nCWL                              (C_MEM_CAS_WR_LATENCY),
           .tRFC                              (C_MEM_PART_TRFC),
           .OUTPUT_DRV                        (P_OUTPUT_DRV),
           .REG_CTRL                          (P_REG_CTRL),
           .RTT_NOM                           (P_DDR3_RTT_NOM),
           .RTT_WR                            (P_DDR2_RTT_WR),
           .WRLVL                             (P_MEM_WRLVL),
           .PHASE_DETECT                      (P_PHASE_DETECT),
           .IODELAY_HP_MODE                   (P_IODELAY_HP_MODE),
           .IODELAY_GRP                       (C_IODELAY_GRP),
           .SIM_INIT_OPTION                   (P_SIM_INIT_OPTION),
           .SIM_CAL_OPTION                    (P_SIM_CAL_OPTION),
           .nDQS_COL0                         (C_MEM_NDQS_COL0),
           .nDQS_COL1                         (C_MEM_NDQS_COL1),
           .nDQS_COL2                         (C_MEM_NDQS_COL2),
           .nDQS_COL3                         (C_MEM_NDQS_COL3),
           .DQS_LOC_COL0                      (C_MEM_DQS_LOC_COL0),
           .DQS_LOC_COL1                      (C_MEM_DQS_LOC_COL1),
           .DQS_LOC_COL2                      (C_MEM_DQS_LOC_COL2),
           .DQS_LOC_COL3                      (C_MEM_DQS_LOC_COL3),     
           .USE_DM_PORT                       (P_USE_DM_PORT),
           .SIM_BYPASS_INIT_CAL               (P_SIM_BYPASS_INIT_CAL),
           .DEBUG_PORT                        ("OFF"),
           .CALIB_ROW_ADD                     (P_CALIB_ROW_ADD),
           .CALIB_COL_ADD                     (P_CALIB_COL_ADD),
           .CALIB_BA_ADD                      (P_CALIB_BA_ADD)
           )

          mpmc_phy_if_0 
            (
              // System Inputs
             .clk_mem                         (Clk_Mem),
             .clk                             (Clk0),
             .clk_rd_base                     (Clk_Rd_Base),
             .rst                             (rst_phy),
             // Slot present inputs
             .slot_0_present                  (slot_0_present),
             .slot_1_present                  (slot_1_present),
             // DFI Control/Address
             .dfi_address0                    (AP_PhyIF_Addr_i),
             .dfi_address1                    (AP_PhyIF_Addr_i),
             .dfi_bank0                       (AP_PhyIF_BankAddr_i),
             .dfi_bank1                       (AP_PhyIF_BankAddr_i),
             .dfi_ras_n0                      (ctrl_dfi_ras_n[0]),
             .dfi_ras_n1                      (ctrl_dfi_ras_n[1]),
             .dfi_cas_n0                      (ctrl_dfi_cas_n[0]),
             .dfi_cas_n1                      (ctrl_dfi_cas_n[1]),
             .dfi_we_n0                       (ctrl_dfi_we_n[0]),
             .dfi_we_n1                       (ctrl_dfi_we_n[1]),
             // TODO: Update this when we support multiple Ranks (remove [0], check widths)
             .dfi_cs_n0                       ({P_CS_WIDTH*P_NCS_PER_RANK{AP_PhyIF_CS_n_i[0]}}),    
             .dfi_cs_n1                       ({P_CS_WIDTH*P_NCS_PER_RANK{AP_PhyIF_CS_n_i[0]}}),
             .dfi_cke0                        ({C_MEM_CE_WIDTH{ctrl_dfi_ce[0]}}),
             .dfi_cke1                        ({C_MEM_CE_WIDTH{ctrl_dfi_ce[1]}}),
             .dfi_reset_n                     (~Rst[0]),
             .dfi_odt0                        ({P_CS_WIDTH*P_NCS_PER_RANK{ctrl_dfi_odt[0]}}),
             .dfi_odt1                        ({P_CS_WIDTH*P_NCS_PER_RANK{ctrl_dfi_odt[1]}}),
             // DFI Write
             .dfi_wrdata_en                   (ctrl_dfi_wrdata_en),
             .dfi_wrdata                      (wdf_data),
             .dfi_wrdata_mask                 (wdf_mask_data), 
             // DFI Read
             .dfi_rddata_en                   (ctrl_dfi_rddata_en),
             .dfi_rddata                      (rd_data),    
             .dfi_rddata_valid                (ctrl_dfi_rddata_valid),
             // DFI Initializiation Status / ClLK Disable
             .dfi_dram_clk_disable            (1'b0),
             .dfi_init_complete               (PhyIF_Ctrl_InitDone_tmp),
             // Sideband Signals
             .io_config_strobe                (phy_io_config_strobe),
             .io_config                       (phy_io_config),
             // DDR3 Output Interface
             .ddr_ck_p                        (Mem_Clk_O),
             .ddr_ck_n                        (Mem_Clk_n_O),
             .ddr_addr                        (Mem_Addr_O),
             .ddr_ba                          (Mem_BankAddr_O),
             .ddr_ras_n                       (Mem_RAS_n_O),
             .ddr_cas_n                       (Mem_CAS_n_O),
             .ddr_we_n                        (Mem_WE_n_O),
             .ddr_cs_n                        (Mem_CS_n_O),
             .ddr_cke                         (Mem_CE_O),
             .ddr_odt                         (Mem_ODT_O),
             .ddr_reset_n                     (Mem_Reset_n_O),
             .ddr_parity                      (),
             .ddr_dm                          (Mem_DM_O),
             .ddr_dqs_p                       (DDR3_DQS),
             .ddr_dqs_n                       (DDR3_DQS_n),
             .ddr_dq                          (DDR3_DQ),
             .pd_PSEN                         (DCM_PSEN),       
             .pd_PSINCDEC                     (DCM_PSINCDEC),   
             .pd_PSDONE                       (DCM_PSDONE),
             // Debug Ports
             // Write leveling logic
             .dbg_wr_dqs_tap_set              (),
             .dbg_wr_dq_tap_set               (),
             .dbg_wr_tap_set_en               (),  
             .dbg_wrlvl_start                 (),
             .dbg_wrlvl_done                  (),
             .dbg_wrlvl_err                   (),
             .dbg_wl_dqs_inverted             (),
             .dbg_wr_calib_clk_delay          (),
             .dbg_wl_odelay_dqs_tap_cnt       (),
             .dbg_wl_odelay_dq_tap_cnt        (),
             .dbg_tap_cnt_during_wrlvl        (),
             .dbg_wl_edge_detect_valid        (),
             .dbg_rd_data_edge_detect         (),
             // Read Leveling Logic
             .dbg_rdlvl_start                 (),
             .dbg_rdlvl_done                  (),
             .dbg_rdlvl_err                   (),
             .dbg_cpt_first_edge_cnt          (),
             .dbg_cpt_second_edge_cnt         (),
             .dbg_rd_bitslip_cnt              (),
             .dbg_rd_clkdly_cnt               (),
             .dbg_rd_active_dly               (),
             .dbg_rd_data                     (),
             // Delay Control
             .dbg_idel_up_all                 (dbg_idel_up_all),
             .dbg_idel_down_all               (dbg_idel_down_all),
             .dbg_idel_up_cpt                 (dbg_idel_up_cpt),
             .dbg_idel_down_cpt               (dbg_idel_down_cpt),
             .dbg_idel_up_rsync               (dbg_idel_up_rsync),
             .dbg_idel_down_rsync             (dbg_idel_down_rsync),
             .dbg_sel_idel_cpt                (dbg_sel_idel_cpt),
             .dbg_sel_all_idel_cpt            (dbg_sel_all_idel_cpt),
             .dbg_sel_idel_rsync              (dbg_sel_idel_rsync),
             .dbg_sel_all_idel_rsync          (dbg_sel_all_idel_rsync),
             .dbg_cpt_tap_cnt                 (),
             .dbg_rsync_tap_cnt               (),
             .dbg_dqs_tap_cnt                 (),
             .dbg_dq_tap_cnt                  (),
             // Phase detector
             .dbg_pd_off                      (dbg_pd_off),
             .dbg_pd_maintain_off             (dbg_pd_maintain_off),
             .dbg_pd_maintain_0_only          (dbg_pd_maintain_0_only),
             .dbg_pd_inc_cpt                  (dbg_pd_inc_cpt),
             .dbg_pd_dec_cpt                  (dbg_pd_dec_cpt),
             .dbg_pd_inc_dqs                  (dbg_pd_inc_dqs),
             .dbg_pd_dec_dqs                  (dbg_pd_dec_dqs),
             .dbg_pd_disab_hyst               (dbg_pd_disab_hyst),
             .dbg_pd_disab_hyst_0             (dbg_pd_disab_hyst_0),
             .dbg_pd_msb_sel                  (dbg_pd_msb_sel),
             .dbg_pd_byte_sel                 (dbg_pd_byte_sel),
             .dbg_inc_rd_fps                  (dbg_inc_rd_fps),
             .dbg_dec_rd_fps                  (dbg_dec_rd_fps),

             .dbg_phy_pd                      (),
             .dbg_phy_read                    (),
             .dbg_phy_rdlvl                   (),
             .dbg_phy_top                     ()
           );
     end
    else if (C_USE_MIG_V6_PHY && C_MEM_TYPE == "DDR2")
      begin : gen_v6_ddr2_phy
        wire [7:0]                    slot_0_present;             
        wire [7:0]                    slot_1_present;             
        reg  [3:0]                    arb_patternstart_d;         
        reg                           first_phy_io_config_issued; 
        reg                           phy_io_config_last;         
        reg                           phy_io_config_strobe;       
        wire [C_MEM_NUM_RANKS:0]      phy_io_config;              

        // PHY Debug signals
        wire [5*C_MEM_DQS_WIDTH-1:0]  dbg_wr_dqs_tap_set;
        wire [5*C_MEM_DQS_WIDTH-1:0]  dbg_wr_dq_tap_set;
        wire                          dbg_wr_tap_set_en;
        wire                          dbg_idel_up_all;            
        wire                          dbg_idel_down_all;          
        wire                          dbg_idel_up_cpt;            
        wire                          dbg_idel_down_cpt;          
        wire                          dbg_idel_up_rsync;          
        wire                          dbg_idel_down_rsync;        
        wire [P_DQS_BITS-1:0]         dbg_sel_idel_cpt;           
        wire                          dbg_sel_all_idel_cpt;       
        wire [P_DQS_BITS-1:0]         dbg_sel_idel_rsync;         
        wire                          dbg_sel_all_idel_rsync;     
        // Phase Detector
        wire                          dbg_pd_off;                 
        wire                          dbg_pd_maintain_off;        
        wire                          dbg_pd_maintain_0_only; 
        wire                          dbg_pd_inc_cpt;         
        wire                          dbg_pd_dec_cpt;         
        wire                          dbg_pd_inc_dqs;         
        wire                          dbg_pd_dec_dqs;         
        wire                          dbg_pd_disab_hyst;      
        wire                          dbg_pd_disab_hyst_0;    
        wire [3:0]                    dbg_pd_msb_sel;         
        wire [P_DQS_BITS-1:0]         dbg_pd_byte_sel;        
        wire                          dbg_inc_rd_fps;
        wire                          dbg_dec_rd_fps;


        // Assing slot present inputs 
        assign slot_0_present              = 8'b000_0001;
        assign slot_1_present              = 8'b000_0000;

        //assign all 0s to dbg ports input
        assign dbg_wr_dqs_tap_set          = 'b0;
        assign dbg_wr_dq_tap_set           = 'b0;
        assign dbg_wr_tap_set_en           = 'b0;
        assign dbg_idel_up_all             = 'b0;
        assign dbg_idel_down_all           = 'b0;
        assign dbg_idel_up_cpt             = 'b0;
        assign dbg_idel_down_cpt           = 'b0;
        assign dbg_idel_up_rsync           = 'b0;
        assign dbg_idel_down_rsync         = 'b0;
        assign dbg_sel_idel_cpt            = 'b0;
        assign dbg_sel_all_idel_cpt        = 'b0;
        assign dbg_sel_idel_rsync          = 'b0;
        assign dbg_sel_all_idel_rsync      = 'b0;
        assign dbg_pd_off                  = 'b0;
        assign dbg_pd_maintain_off         = 'b0;
        assign dbg_pd_maintain_0_only      = 'b0;
        assign dbg_pd_inc_cpt              = 'b0;
        assign dbg_pd_dec_cpt              = 'b0;
        assign dbg_pd_inc_dqs              = 'b0;
        assign dbg_pd_dec_dqs              = 'b0;
        assign dbg_pd_disab_hyst           = 'b0;
        assign dbg_pd_disab_hyst_0         = 'b0;
        assign dbg_pd_msb_sel              = 'b0;
        assign dbg_pd_byte_sel             = 'b0;
        assign dbg_inc_rd_fps              = 'b0;
        assign dbg_dec_rd_fps              = 'b0;

        assign PhyIF_DP_RdFIFO_Push_tmp[0] = ctrl_dfi_rddata_valid & ~Ctrl_Periodic_Rd_Mask;
        assign PhyIF_DP_WrFIFO_Pop = Ctrl_DP_WrFIFO_WhichPort_Decode & {C_NUM_PORTS{ctrl_dp_wrfifo_pop}};

        // Generate phy_io_config Strobe

        // Save status on whether we have issued an io config strobe.
        // Save status on the last io_config issued;
        always @(posedge Clk0) begin
          if (Rst) begin
            first_phy_io_config_issued <= 1'b0;
            phy_io_config_last  <= 1'b0;
          end
          else if (phy_io_config_strobe) begin
            first_phy_io_config_issued <= 1'b1;
            phy_io_config_last  <= phy_io_config[C_MEM_NUM_RANKS];
          end
        end

        // Generate strobe if transaction has started and this is our first
        // transaction or we are switching from reads to writes or write to
        // reads
        always @(posedge Clk0) begin 
          phy_io_config_strobe <= arb_patternstart_d[3] && (~first_phy_io_config_issued
                                  || (phy_io_config_last ^ phy_io_config[C_MEM_NUM_RANKS]));
        end
            
        // Delay Arb_PatternStart
        always @(posedge Clk0) begin 
          arb_patternstart_d[0] <= Arb_PatternStart;
          arb_patternstart_d[1] <= arb_patternstart_d[0];
          arb_patternstart_d[2] <= arb_patternstart_d[1];
          arb_patternstart_d[3] <= arb_patternstart_d[2];
        end
        // TODO: Update this when we support multiple ranks.
        assign phy_io_config = {Ctrl_Is_Write, {C_MEM_NUM_RANKS{1'b0}}};

        v6_ddrx_top #
          (
           .TCQ                               (P_TCQ),  
           .REFCLK_FREQ                       (P_REFCLK_FREQ),
           .nCS_PER_RANK                      (P_NCS_PER_RANK),
           .CAL_WIDTH                         (P_MEM_CAL_WIDTH), 
           .CS_WIDTH                          (P_CS_WIDTH),
           .nCK_PER_CLK                       (C_NCK_PER_CLK),    
           .CKE_WIDTH                         (C_MEM_CE_WIDTH),
           .DRAM_TYPE                         (C_MEM_TYPE),
           .SLOT_0_CONFIG                     (P_SLOT_0_CONFIG),
           .SLOT_1_CONFIG                     (P_SLOT_1_CONFIG),
           .CLK_PERIOD                        (C_MPMC_CLK_PERIOD),
           .BANK_WIDTH                        (C_MEM_BANKADDR_WIDTH),
           .CK_WIDTH                          (C_MEM_CLK_WIDTH),
           .COL_WIDTH                         (C_MEM_PART_NUM_COL_BITS),
           .DQ_CNT_WIDTH                      (P_DQ_BITS),
           .DM_WIDTH                          (C_MEM_DM_WIDTH),
           .DQ_WIDTH                          (C_MEM_DATA_WIDTH),
           .DQS_CNT_WIDTH                     (P_DQS_BITS),
           .DQS_WIDTH                         (C_MEM_DQS_WIDTH),
           .DRAM_WIDTH                        (C_MEM_BITS_DATA_PER_DQS),
           .ROW_WIDTH                         (C_MEM_ADDR_WIDTH),
           .RANK_WIDTH                        (P_RANK_WIDTH),
           .AL                                (P_AL),
           .BURST_MODE                        (P_BURST_MODE),
           .BURST_TYPE                        (P_BURST_TYPE),
           .nAL                               (),
           .nCL                               (C_MEM_CAS_LATENCY0),
           .nCWL                              (C_MEM_CAS_WR_LATENCY),
           .tRFC                              (C_MEM_PART_TRFC),
           .OUTPUT_DRV                        (P_OUTPUT_DRV),
           .REG_CTRL                          (P_REG_CTRL),
           .RTT_NOM                           (P_DDR2_RTT_NOM),
           .RTT_WR                            (P_DDR2_RTT_WR),
           .WRLVL                             (P_MEM_WRLVL),
           .PHASE_DETECT                      (P_PHASE_DETECT),
           .IODELAY_HP_MODE                   (P_IODELAY_HP_MODE),
           .IODELAY_GRP                       (C_IODELAY_GRP),
           .SIM_INIT_OPTION                   (P_SIM_INIT_OPTION),
           .SIM_CAL_OPTION                    (P_SIM_CAL_OPTION),
           .nDQS_COL0                         (C_MEM_NDQS_COL0),
           .nDQS_COL1                         (C_MEM_NDQS_COL1),
           .nDQS_COL2                         (C_MEM_NDQS_COL2),
           .nDQS_COL3                         (C_MEM_NDQS_COL3),
           .DQS_LOC_COL0                      (C_MEM_DQS_LOC_COL0),
           .DQS_LOC_COL1                      (C_MEM_DQS_LOC_COL1),
           .DQS_LOC_COL2                      (C_MEM_DQS_LOC_COL2),
           .DQS_LOC_COL3                      (C_MEM_DQS_LOC_COL3),     
           .USE_DM_PORT                       (P_USE_DM_PORT),
           .SIM_BYPASS_INIT_CAL               (P_SIM_BYPASS_INIT_CAL),
           .DEBUG_PORT                        ("OFF"),
           .CALIB_ROW_ADD                     (P_CALIB_ROW_ADD),
           .CALIB_COL_ADD                     (P_CALIB_COL_ADD),
           .CALIB_BA_ADD                      (P_CALIB_BA_ADD)
           )
          mpmc_phy_if_0 
            (
              // System Inputs
             .clk_mem                         (Clk_Mem),
             .clk                             (Clk0),
             .clk_rd_base                     (Clk_Rd_Base),
             .rst                             (rst_phy),
             // Slot present inputs
             .slot_0_present                  (slot_0_present),
             .slot_1_present                  (slot_1_present),
             // DFI Control/Address
             .dfi_address0                    (AP_PhyIF_Addr_i),
             .dfi_address1                    (AP_PhyIF_Addr_i),
             .dfi_bank0                       (AP_PhyIF_BankAddr_i),
             .dfi_bank1                       (AP_PhyIF_BankAddr_i),
             .dfi_ras_n0                      (ctrl_dfi_ras_n[0]),
             .dfi_ras_n1                      (ctrl_dfi_ras_n[1]),
             .dfi_cas_n0                      (ctrl_dfi_cas_n[0]),
             .dfi_cas_n1                      (ctrl_dfi_cas_n[1]),
             .dfi_we_n0                       (ctrl_dfi_we_n[0]),
             .dfi_we_n1                       (ctrl_dfi_we_n[1]),
             // TODO: Update this when we support multiple Ranks (remove [0], check widths)
             .dfi_cs_n0                       ({P_CS_WIDTH*P_NCS_PER_RANK{AP_PhyIF_CS_n_i[0]}}),    
             .dfi_cs_n1                       ({P_CS_WIDTH*P_NCS_PER_RANK{AP_PhyIF_CS_n_i[0]}}),
             .dfi_cke0                        ({C_MEM_CE_WIDTH{ctrl_dfi_ce[0]}}),
             .dfi_cke1                        ({C_MEM_CE_WIDTH{ctrl_dfi_ce[1]}}),
             .dfi_reset_n                     (~Rst[0]),
             .dfi_odt0                        ({P_CS_WIDTH*P_NCS_PER_RANK{ctrl_dfi_odt[0]}}),
             .dfi_odt1                        ({P_CS_WIDTH*P_NCS_PER_RANK{ctrl_dfi_odt[1]}}),
             // DFI Write
             .dfi_wrdata_en                   (ctrl_dfi_wrdata_en),
             .dfi_wrdata                      (wdf_data),
             .dfi_wrdata_mask                 (wdf_mask_data), 
             // DFI Read
             .dfi_rddata_en                   (ctrl_dfi_rddata_en),
             .dfi_rddata                      (rd_data),    
             .dfi_rddata_valid                (ctrl_dfi_rddata_valid),
             // DFI Initializiation Status / ClLK Disable
             .dfi_dram_clk_disable            (1'b0),
             .dfi_init_complete               (PhyIF_Ctrl_InitDone_tmp),
             // Sideband Signals
             .io_config_strobe                (phy_io_config_strobe),
             .io_config                       (phy_io_config),
             // DDR3 Output Interface
             .ddr_ck_p                        (Mem_Clk_O),
             .ddr_ck_n                        (Mem_Clk_n_O),
             .ddr_addr                        (Mem_Addr_O),
             .ddr_ba                          (Mem_BankAddr_O),
             .ddr_ras_n                       (Mem_RAS_n_O),
             .ddr_cas_n                       (Mem_CAS_n_O),
             .ddr_we_n                        (Mem_WE_n_O),
             .ddr_cs_n                        (Mem_CS_n_O),
             .ddr_cke                         (Mem_CE_O),
             .ddr_odt                         (Mem_ODT_O),
             .ddr_reset_n                     (Mem_Reset_n_O),
             .ddr_parity                      (),
             .ddr_dm                          (Mem_DM_O),
             .ddr_dqs_p                       (DDR2_DQS),
             .ddr_dqs_n                       (DDR2_DQS_n),
             .ddr_dq                          (DDR2_DQ),
             .pd_PSEN                         (DCM_PSEN),       
             .pd_PSINCDEC                     (DCM_PSINCDEC),   
             .pd_PSDONE                       (DCM_PSDONE),
             // Debug Ports
             // Write leveling logic
             .dbg_wr_dqs_tap_set              (),
             .dbg_wr_dq_tap_set               (),
             .dbg_wr_tap_set_en               (),  
             .dbg_wrlvl_start                 (),
             .dbg_wrlvl_done                  (),
             .dbg_wrlvl_err                   (),
             .dbg_wl_dqs_inverted             (),
             .dbg_wr_calib_clk_delay          (),
             .dbg_wl_odelay_dqs_tap_cnt       (),
             .dbg_wl_odelay_dq_tap_cnt        (),
             .dbg_tap_cnt_during_wrlvl        (),
             .dbg_wl_edge_detect_valid        (),
             .dbg_rd_data_edge_detect         (),
             // Read Leveling Logic
             .dbg_rdlvl_start                 (),
             .dbg_rdlvl_done                  (),
             .dbg_rdlvl_err                   (),
             .dbg_cpt_first_edge_cnt          (),
             .dbg_cpt_second_edge_cnt         (),
             .dbg_rd_bitslip_cnt              (),
             .dbg_rd_clkdly_cnt               (),
             .dbg_rd_active_dly               (),
             .dbg_rd_data                     (),
             // Delay Control
             .dbg_idel_up_all                 (dbg_idel_up_all),
             .dbg_idel_down_all               (dbg_idel_down_all),
             .dbg_idel_up_cpt                 (dbg_idel_up_cpt),
             .dbg_idel_down_cpt               (dbg_idel_down_cpt),
             .dbg_idel_up_rsync               (dbg_idel_up_rsync),
             .dbg_idel_down_rsync             (dbg_idel_down_rsync),
             .dbg_sel_idel_cpt                (dbg_sel_idel_cpt),
             .dbg_sel_all_idel_cpt            (dbg_sel_all_idel_cpt),
             .dbg_sel_idel_rsync              (dbg_sel_idel_rsync),
             .dbg_sel_all_idel_rsync          (dbg_sel_all_idel_rsync),
             .dbg_cpt_tap_cnt                 (),
             .dbg_rsync_tap_cnt               (),
             .dbg_dqs_tap_cnt                 (),
             .dbg_dq_tap_cnt                  (),
             // Phase detector
             .dbg_pd_off                      (dbg_pd_off),
             .dbg_pd_maintain_off             (dbg_pd_maintain_off),
             .dbg_pd_maintain_0_only          (dbg_pd_maintain_0_only),
             .dbg_pd_inc_cpt                  (dbg_pd_inc_cpt),
             .dbg_pd_dec_cpt                  (dbg_pd_dec_cpt),
             .dbg_pd_inc_dqs                  (dbg_pd_inc_dqs),
             .dbg_pd_dec_dqs                  (dbg_pd_dec_dqs),
             .dbg_pd_disab_hyst               (dbg_pd_disab_hyst),
             .dbg_pd_disab_hyst_0             (dbg_pd_disab_hyst_0),
             .dbg_pd_msb_sel                  (dbg_pd_msb_sel),
             .dbg_pd_byte_sel                 (dbg_pd_byte_sel),
             .dbg_inc_rd_fps                  (dbg_inc_rd_fps),
             .dbg_dec_rd_fps                  (dbg_dec_rd_fps),

             .dbg_phy_pd                      (),
             .dbg_phy_read                    (),
             .dbg_phy_rdlvl                   (),
             .dbg_phy_top                     ()
           );
      end
    else if (C_USE_MIG_V5_PHY && C_MEM_TYPE == "DDR2")
      begin : gen_v5_ddr2_phy
        wire [C_ECC_DATA_WIDTH*(C_IS_DDR+1)+
              C_MEM_DATA_WIDTH_INT-1:0] rd_data_tmp;
        reg  [C_ECC_DATA_WIDTH*(C_IS_DDR+1)+
              C_MEM_DATA_WIDTH_INT-1:0] rd_data_d1;
        reg  [C_ECC_DATA_WIDTH*(C_IS_DDR+1)+
              C_MEM_DATA_WIDTH_INT-1:0] wdf_data_debug;
        reg  [C_ECC_DM_WIDTH*(C_IS_DDR+1)+
              C_MEM_DM_WIDTH_INT-1:0] wdf_mask_data_debug;
        wire [RDF_PUSH_BITS-1:0] PhyIF_DP_RdFIFO_Push_tmp2; 
        reg  Ctrl_DP_RdFIFO_Push_d1;
        reg  rd_data_toggle;
        
        
        if (C_DEBUG_REG_ENABLE == 1) begin : gen_debug
          if (C_INCLUDE_ECC_SUPPORT == 1) begin : gen_ecc

            always @(posedge Clk0) begin
              rd_data_d1 <= rd_data;
              if (PhyIF_DP_RdFIFO_Push_tmp[0] == 1'b0)
                rd_data_toggle <= 1'b0;
              else
                rd_data_toggle <= ~rd_data_toggle;
              if (Rst) begin
                ecc_read_data0 <= {C_ECC_DATA_WIDTH{1'b0}};
                ecc_read_data1 <= {C_ECC_DATA_WIDTH{1'b0}};
              end else if ((rd_data_toggle == 1'b0) && (PhyIF_DP_RdFIFO_Push_tmp[0] == 1'b1)) begin
                ecc_read_data0 <= rd_data_d1[C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH-1:C_MEM_DATA_WIDTH];
                ecc_read_data1 <= rd_data_d1[C_ECC_DATA_WIDTH*2+C_MEM_DATA_WIDTH*2-1:C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH*2];
              end
              if (Rst) begin
                ecc_read_data2 <= {C_ECC_DATA_WIDTH{1'b0}};
                ecc_read_data3 <= {C_ECC_DATA_WIDTH{1'b0}};
              end else if ((rd_data_toggle == 1'b1) && (PhyIF_DP_RdFIFO_Push_tmp[0] == 1'b1)) begin
                ecc_read_data2 <= rd_data_d1[C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH-1:C_MEM_DATA_WIDTH];
                ecc_read_data3 <= rd_data_d1[C_ECC_DATA_WIDTH*2+C_MEM_DATA_WIDTH*2-1:C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH*2];
              end
            end
            end
          end
          always @(*) begin
            wdf_data_debug = wdf_data;
            wdf_mask_data_debug = wdf_mask_data;
          end

        always @(posedge Clk0)
          Ctrl_DP_RdFIFO_Push_d1 <= Ctrl_DP_RdFIFO_Push;
  
        mpmc_realign_bytes #
          (
           .C_IS_DDR      (C_IS_DDR),
           .C_DATA_WIDTH  ((C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH)*(C_IS_DDR+1)),
           .C_DELAY_WIDTH (5)
           )
          mpmc_realign_bytes_0
            (
             .Clk        (Clk0),
             .Data_Delay (dbg_calib_rden_dly),
             .Data_In    (rd_data_tmp),
             .Data_Out   (rd_data),
             .Push_In    (PhyIF_DP_RdFIFO_Push_tmp2),
             .Push_Out   (PhyIF_DP_RdFIFO_Push_tmp)
             );
  
        v5_phy_top_ddr2 #
          (
           .BANK_WIDTH            (C_MEM_BANKADDR_WIDTH),
           .CLK_WIDTH             (C_MEM_CLK_WIDTH),
           .CKE_WIDTH             (C_MEM_CE_WIDTH),
           .COL_WIDTH             (C_MEM_ADDR_WIDTH),
           .CS_BITS               (P_CS_BITS),
           .CS_NUM                (C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS),
           .CS_WIDTH              (C_MEM_CS_N_WIDTH),
           .USE_DM_PORT           (1),
           .DM_WIDTH              (C_ECC_DM_WIDTH+C_MEM_DM_WIDTH),
           .DQ_WIDTH              (C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH),
           .DQ_BITS               (P_ECC_DQ_BITS+P_DQ_BITS),
           .DQ_PER_DQS            (C_MEM_DATA_WIDTH/C_MEM_DQS_WIDTH),
           .DQS_WIDTH             (C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH),
           .DQS_BITS              (P_ECC_DQS_BITS+P_DQS_BITS),
           .HIGH_PERFORMANCE_MODE (P_HIGH_PERFORMANCE_MODE),
           .IODELAY_GRP           (C_IODELAY_GRP),
           .ODT_WIDTH             (C_MEM_ODT_WIDTH),
           .ROW_WIDTH             (C_MEM_ADDR_WIDTH),
           .ADDITIVE_LAT          (C_MEM_ADDITIVE_LATENCY),
           .TWO_T_TIME_EN         (0),
           .BURST_LEN             (C_MEM_BURST_LENGTH),
           .BURST_TYPE            (0),
           .CAS_LAT               (C_MEM_CAS_LATENCY0),
           .TWR                   (C_TWR),
           .ECC_ENABLE            (C_INCLUDE_ECC_SUPPORT),
           .ODT_TYPE              (C_MEM_ODT_TYPE),
           .DDR_TYPE              (C_MEM_DDR2_ENABLE),
           .REDUCE_DRV            (C_MEM_REDUCED_DRV),
           .REG_ENABLE            (C_MEM_REG_DIMM),
           .CLK_PERIOD            (C_MPMC_CLK_PERIOD),
           .SIM_ONLY              (C_SKIP_INIT_DELAY),
           .DEBUG_EN              (C_DEBUG_REG_ENABLE),
           .DQS_IO_COL            (C_MEM_DQS_IO_COL),
           .DQ_IO_MS              (C_MEM_DQ_IO_MS),
           .FPGA_SPEED_GRADE      (C_SPEEDGRADE_INT),
           .WDF_RDEN_EARLY        (P_WDF_RDEN_EARLY),
           .WDF_RDEN_WIDTH        (C_NUM_PORTS)
           )
          mpmc_phy_if_0 
            (
             // Clocks/Resets
             .clk0               (Clk0),
             .clk90              (Clk90),
             .clkdiv0            (Clk0_DIV2),
             .rst0               (rst_phy),
             .rst90              (rst90_phy),
             .rstdiv0            (rst_phy),
             // Memory Control Signals
             .ctrl_wren          (Ctrl_PhyIF_DQS_O),  // Indicator that DQS 
                                                      // should toggle.
             .ctrl_addr          (AP_PhyIF_Addr),     // Pre IOB FF memory 
                                                      // address.
             .ctrl_ba            (AP_PhyIF_BankAddr), // Pre IOB FF memory 
                                                      // bank address.
             .ctrl_ras_n         (Ctrl_PhyIF_RAS_n),  // Pre IOB FF memory RAS.
             .ctrl_cas_n         (Ctrl_PhyIF_CAS_n),  // Pre IOB FF memory CAS.
             .ctrl_we_n          (Ctrl_PhyIF_WE_n),   // Pre IOB FF memory WE.
             .ctrl_cs_n          (AP_PhyIF_CS_n),     // Pre IOB FF memory CS.
             .ctrl_rden          (C_INCLUDE_ECC_SUPPORT ? 
                                  Ctrl_DP_RdFIFO_Push_d1 : 
                                  Ctrl_DP_RdFIFO_Push),// Pulse high for 
                                                      // number of cycles read 
                                                      // push will be asserted.
                                                      // Needs to be high one 
                                                      // cycle before
                                                      // ctrl_<ras/cas/we> 
                                                      // indicate read.
             .ctrl_ref_flag      (Ctrl_Refresh_Flag), // One cycle high pulse 
                                                      // every time refresh is 
                                                      // requested.
             // Memory Write Signals
             .wdf_data           (wdf_data_debug),     // Pre IOB FF write data
             .wdf_mask_data      (wdf_mask_data_debug),// Pre IOB FF write data
                                                       // mask.
             .wdf_rden           (PhyIF_DP_WrFIFO_Pop),// Wr FIFO pop signal.
             // Initialization Signals
             .phy_init_done      (PhyIF_Ctrl_InitDone_tmp),// Set to 0 from 
                                                      // reset until end of 
                                                      // initialization and 
                                                      // calibration.
             // Memory Read Signals
             .phy_calib_rden     (PhyIF_DP_RdFIFO_Push_tmp2),// Read FIFO push.
             .phy_calib_rden_sel (),
             .rd_data_rise      (rd_data_tmp[C_ECC_DATA_WIDTH+
                                             C_MEM_DATA_WIDTH_INT/2-1:0]),
                                                      // Post IOB FF LSB read 
                                                      // data.
             .rd_data_fall      (rd_data_tmp[C_ECC_DATA_WIDTH*2+
                                             C_MEM_DATA_WIDTH_INT-1:
                                             C_ECC_DATA_WIDTH+
                                             C_MEM_DATA_WIDTH_INT/2]),
                                                      // Post IOB FF MSB read 
                                                      // data.
             // Memory I/Os
             .ddr_ck            (Mem_Clk_O),      // Post IOB FF memory clock.
             .ddr_ck_n          (Mem_Clk_n_O),    // Post IOB FF memory inverse
                                                  // clock.
             .ddr_addr          (Mem_Addr_O),     // Post IOB FF memory addr.
             .ddr_ba            (Mem_BankAddr_O), // Post IOB FF memory bank 
                                                  // address.
             .ddr_ras_n         (Mem_RAS_n_O),    // Post IOB FF memory RAS.
             .ddr_cas_n         (Mem_CAS_n_O),    // Post IOB FF memory CAS.
             .ddr_we_n          (Mem_WE_n_O),     // Post IOB FF memory WE.
             .ddr_cs_n          (Mem_CS_n_O),     // Post IOB FF memory CS.
             .ddr_cke           (Mem_CE_O),       // Post IOB FF memory CKE.
             .ddr_odt           (Mem_ODT_O),      // Post IOB FF memory ODT.
             .ddr_dm            (Mem_DM_O),       // Post IOB FF memory data 
                                                  // mask.
             .ddr_dqs           (DDR2_DQS),       // Post IOB FF memory data 
                                                  // strobe.
             .ddr_dqs_n         (DDR2_DQS_n),     // Post IOB FF memory inverse
                                                  // data strobe.
             .ddr_dq            (DDR2_DQ),        // Post IOB FF memory data.
             // Debug signals
             .dbg_idel_up_all        (dbg_idel_up_all),
             .dbg_idel_down_all      (dbg_idel_down_all),
             .dbg_idel_up_dq         (dbg_idel_up_dq),
             .dbg_idel_down_dq       (dbg_idel_down_dq),
             .dbg_idel_up_dqs        (dbg_idel_up_dqs),
             .dbg_idel_down_dqs      (dbg_idel_down_dqs),
             .dbg_idel_up_gate       (dbg_idel_up_gate),
             .dbg_idel_down_gate     (dbg_idel_down_gate),
             .dbg_sel_idel_dq        (dbg_sel_idel_dq),
             .dbg_sel_all_idel_dq    (dbg_sel_all_idel_dq),
             .dbg_sel_idel_dqs       (dbg_sel_idel_dqs),
             .dbg_sel_all_idel_dqs   (dbg_sel_all_idel_dqs),
             .dbg_sel_idel_gate      (dbg_sel_idel_gate),
             .dbg_sel_all_idel_gate  (dbg_sel_all_idel_gate),
             .dbg_calib_done         (dbg_calib_done_v5),
             .dbg_calib_err          (dbg_calib_err_v5),
             .dbg_calib_dq_tap_cnt   (dbg_calib_dq_tap_cnt),
             .dbg_calib_dqs_tap_cnt  (dbg_calib_dqs_tap_cnt),
             .dbg_calib_gate_tap_cnt (dbg_calib_gate_tap_cnt),
             .dbg_calib_rd_data_sel_value (dbg_calib_rd_data_sel_value),
             .dbg_calib_rd_data_sel_en    (dbg_calib_rd_data_sel_en),
             .dbg_calib_rd_data_sel       (dbg_calib_rd_data_sel),
             .dbg_calib_rden_dly_value    (dbg_calib_rden_dly_value),
             .dbg_calib_rden_dly_en       (dbg_calib_rden_dly_en),
             .dbg_calib_rden_dly          (dbg_calib_rden_dly),
             .dbg_calib_gate_dly_value    (dbg_calib_gate_dly_value),
             .dbg_calib_gate_dly_en       (dbg_calib_gate_dly_en),
             .dbg_calib_gate_dly          (dbg_calib_gate_dly)
             );
        end // block: gen_ddr2_phy
    else if (C_USE_MIG_V5_PHY && C_MEM_TYPE == "DDR")
      begin : gen_v5_ddr_phy
        wire [C_ECC_DATA_WIDTH*(C_IS_DDR+1)+
              C_MEM_DATA_WIDTH_INT-1:0] rd_data_tmp;
        wire [RDF_PUSH_BITS-1:0] PhyIF_DP_RdFIFO_Push_tmp2; 
        reg  [C_ECC_DATA_WIDTH*(C_IS_DDR+1)+
              C_MEM_DATA_WIDTH_INT-1:0] rd_data_d1;
        reg  [C_ECC_DATA_WIDTH*(C_IS_DDR+1)+
              C_MEM_DATA_WIDTH_INT-1:0] wdf_data_debug;
        reg  [C_ECC_DM_WIDTH*(C_IS_DDR+1)+
              C_MEM_DM_WIDTH_INT-1:0] wdf_mask_data_debug;
        reg  Ctrl_DP_RdFIFO_Push_d1;
        reg  rd_data_toggle;
        
        
        if (C_DEBUG_REG_ENABLE == 1) begin : gen_debug
          if (C_INCLUDE_ECC_SUPPORT == 1) begin : gen_ecc
            always @(posedge Clk0) begin
              rd_data_d1 <= rd_data;
              if (PhyIF_DP_RdFIFO_Push_tmp[0] == 1'b0)
                rd_data_toggle <= 1'b0;
              else
                rd_data_toggle <= ~rd_data_toggle;
              if (Rst) begin
                ecc_read_data0 <= {C_ECC_DATA_WIDTH{1'b0}};
                ecc_read_data1 <= {C_ECC_DATA_WIDTH{1'b0}};
              end else if ((rd_data_toggle == 1'b0) && (PhyIF_DP_RdFIFO_Push_tmp[0] == 1'b1)) begin
                ecc_read_data0 <= rd_data_d1[C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH-1:C_MEM_DATA_WIDTH];
                ecc_read_data1 <= rd_data_d1[C_ECC_DATA_WIDTH*2+C_MEM_DATA_WIDTH*2-1:C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH*2];
              end
              if (Rst) begin
                ecc_read_data2 <= {C_ECC_DATA_WIDTH{1'b0}};
                ecc_read_data3 <= {C_ECC_DATA_WIDTH{1'b0}};
              end else if ((rd_data_toggle == 1'b1) && (PhyIF_DP_RdFIFO_Push_tmp[0] == 1'b1)) begin
                ecc_read_data2 <= rd_data_d1[C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH-1:C_MEM_DATA_WIDTH];
                ecc_read_data3 <= rd_data_d1[C_ECC_DATA_WIDTH*2+C_MEM_DATA_WIDTH*2-1:C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH*2];
              end
            end
            end
          end
          always @(*) begin
            wdf_data_debug = wdf_data;
            wdf_mask_data_debug = wdf_mask_data;
          end

        mpmc_realign_bytes #
          (
           .C_IS_DDR      (C_IS_DDR),
           .C_DATA_WIDTH  ((C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH)*(C_IS_DDR+1)),
           .C_DELAY_WIDTH (2)
           )
          mpmc_realign_bytes_0
            (
             .Clk        (Clk0),
             .Data_Delay (dbg_calib_rden_dly),
             .Data_In    (rd_data_tmp),
             .Data_Out   (rd_data),
             .Push_In    (PhyIF_DP_RdFIFO_Push_tmp2),
             .Push_Out   (PhyIF_DP_RdFIFO_Push_tmp)
             );
  
        assign dbg_calib_rd_data_sel = {C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH{1'b0}};
        v5_phy_top_ddr1 #
          (
           .BANK_WIDTH            (C_MEM_BANKADDR_WIDTH),
           .CLK_WIDTH             (C_MEM_CLK_WIDTH),
           .CKE_WIDTH             (C_MEM_CE_WIDTH),
           .COL_WIDTH             (C_MEM_ADDR_WIDTH),
           .CS_NUM                (C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS),
           .CS_WIDTH              (C_MEM_CS_N_WIDTH),
           .USE_DM_PORT           (1),
           .DM_WIDTH              (C_ECC_DM_WIDTH+C_MEM_DM_WIDTH),
           .DQ_WIDTH              (C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH),
           .DQ_BITS               (P_ECC_DQ_BITS+P_DQ_BITS),
           .DQ_PER_DQS            (C_MEM_DATA_WIDTH/C_MEM_DQS_WIDTH),
           .DQS_BITS              (P_ECC_DQS_BITS+P_DQS_BITS),
           .DQS_WIDTH             (C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH),
           .HIGH_PERFORMANCE_MODE ("TRUE"),
           .IODELAY_GRP           (C_IODELAY_GRP),
           .ODT_WIDTH             (C_MEM_ODT_WIDTH),
           .ROW_WIDTH             (C_MEM_ADDR_WIDTH),
           .ADDITIVE_LAT          (C_MEM_ADDITIVE_LATENCY),
           .BURST_LEN             (C_MEM_BURST_LENGTH),
           .BURST_TYPE            (0),
           .CAS_LAT               (C_MEM_CAS_LATENCY0),
           .ECC_ENABLE            (C_INCLUDE_ECC_SUPPORT),
           .ODT_TYPE              (C_MEM_ODT_TYPE),
           .REDUCE_DRV            (C_MEM_REDUCED_DRV),
           .REG_ENABLE            (C_MEM_REG_DIMM),
           .CLK_PERIOD            (C_MPMC_CLK_PERIOD),
           .DDR2_ENABLE           (C_MEM_DDR2_ENABLE),
           .DQS_GATE_EN           (C_MEM_DQS_GATE_EN),
           .SIM_ONLY              (C_SKIP_INIT_DELAY),
           .WDF_RDEN_EARLY        (P_WDF_RDEN_EARLY),
           .WDF_RDEN_WIDTH        (C_NUM_PORTS),
           .DEBUG_EN              (C_DEBUG_REG_ENABLE)
           )
          mpmc_phy_if_0 
            (
             // Clocks/Resets
             .clk0              (Clk0),
             .clk90             (Clk90),
             .rst0              (rst_phy),
             .rst90             (rst90_phy),
             // Memory Control Signals
             .ctrl_wren         (Ctrl_PhyIF_DQS_O),  // Indicator that DQS 
                                                     // should toggle.
             .ctrl_addr         (AP_PhyIF_Addr),     // Pre IOB FF memory addr.
             .ctrl_ba           (AP_PhyIF_BankAddr), // Pre IOB FF memory bank 
                                                     // address.
             .ctrl_ras_n        (Ctrl_PhyIF_RAS_n),  // Pre IOB FF memory RAS.
             .ctrl_cas_n        (Ctrl_PhyIF_CAS_n),  // Pre IOB FF memory CAS.
             .ctrl_we_n         (Ctrl_PhyIF_WE_n),   // Pre IOB FF memory WE.
             .ctrl_cs_n         (AP_PhyIF_CS_n),     // Pre IOB FF memory CS.
             .ctrl_rden         (Ctrl_DP_RdFIFO_Push),// Pulse high for number 
                                                     // of cycles read push 
                                                     // will be asserted.  
                                                     // Needs to be high one 
                                                     // cycle before 
                                                     // ctrl_<ras/cas/we> 
                                                     // indicate read.
             .ctrl_ref_flag     (Ctrl_Refresh_Flag), // One cycle high pulse 
                                                     // every time refresh is 
                                                     // requested.
             // Memory Write Signals
             .wdf_data          (wdf_data_debug),     // Pre IOB FF write data.
             .wdf_mask_data     (wdf_mask_data_debug),// Pre IOB FF write data 
                                                      // mask.
             .wdf_rden          (PhyIF_DP_WrFIFO_Pop),// Write FIFO pop signal.
             // Initialization Signals
             .phy_init_done     (PhyIF_Ctrl_InitDone_tmp),// Set to 0 from 
                                                     // reset until end of 
                                                     // initialization and 
                                                     // calibration.
             // Memory Read Signals
             .phy_calib_rden    (PhyIF_DP_RdFIFO_Push_tmp2),// Read FIFO push.
             .phy_init_wdf_wren (PhyIF_Init_Push_tmp),// Push signal for 
                                                     // phy_init_wdf_data.
             .phy_init_wdf_data (PhyIF_Init_Data_tmp),// Write training pattern
                                                     // to be pushed into
                                                     //write FIFO's during 
                                                     // initialization
             .rd_data_rise      (rd_data_tmp[C_ECC_DATA_WIDTH+
                                             C_MEM_DATA_WIDTH_INT/2-1:0]),
                                                     // Post IOB FF LSB read 
                                                     // data.
             .rd_data_fall      (rd_data_tmp[C_ECC_DATA_WIDTH*2+
                                             C_MEM_DATA_WIDTH_INT-1:
                                             C_ECC_DATA_WIDTH+
                                             C_MEM_DATA_WIDTH_INT/2]),
                                                     // Post IOB FF MSB read 
                                                     // data.
             // Memory I/Os
             .ddr_ck            (Mem_Clk_O),      // Post IOB FF memory clock.
             .ddr_ck_n          (Mem_Clk_n_O),    // Post IOB FF memory inverse
                                                  // clock.
             .ddr_addr          (Mem_Addr_O),     // Post IOB FF memory address
             .ddr_ba            (Mem_BankAddr_O), // Post IOB FF memory bank 
                                                  // address.
             .ddr_ras_n         (Mem_RAS_n_O),    // Post IOB FF memory RAS.
             .ddr_cas_n         (Mem_CAS_n_O),    // Post IOB FF memory CAS.
             .ddr_we_n          (Mem_WE_n_O),     // Post IOB FF memory WE.
             .ddr_cs_n          (Mem_CS_n_O),     // Post IOB FF memory CS.
             .ddr_cke           (Mem_CE_O),       // Post IOB FF memory CKE.
             .ddr_odt           (Mem_ODT_O),      // Post IOB FF memory ODT.
             .ddr_dm            (Mem_DM_O),       // Post IOB FF memory data 
                                                  // mask.
             .ddr_dqs           (DDR_DQS),        // Post IOB FF memory data 
                                                  // strobe.
             .ddr_dqs_n         (), 
             .ddr_dq            (DDR_DQ),         // Post IOB FF memory data.
             // Debug signals
             .dbg_idel_up_all        (dbg_idel_up_all),
             .dbg_idel_down_all      (dbg_idel_down_all),
             .dbg_idel_up_dq         (dbg_idel_up_dq),
             .dbg_idel_down_dq       (dbg_idel_down_dq),
             .dbg_idel_up_dqs        (dbg_idel_up_dqs),
             .dbg_idel_down_dqs      (dbg_idel_down_dqs),
             .dbg_idel_up_gate       (dbg_idel_up_gate),
             .dbg_idel_down_gate     (dbg_idel_down_gate),
             .dbg_sel_idel_dq        (dbg_sel_idel_dq),
             .dbg_sel_all_idel_dq    (dbg_sel_all_idel_dq),
             .dbg_sel_idel_dqs       (dbg_sel_idel_dqs),
             .dbg_sel_all_idel_dqs   (dbg_sel_all_idel_dqs),
             .dbg_sel_idel_gate      (dbg_sel_idel_gate),
             .dbg_sel_all_idel_gate  (dbg_sel_all_idel_gate),
             .dbg_calib_done           (dbg_calib_done_v5),
             .dbg_calib_err            (dbg_calib_err_v5),
             .dbg_calib_dq_tap_cnt     (dbg_calib_dq_tap_cnt),
             .dbg_calib_dqs_tap_cnt    (dbg_calib_dqs_tap_cnt),
             .dbg_calib_gate_tap_cnt   (dbg_calib_gate_tap_cnt),
             .dbg_calib_rden_dly_value (dbg_calib_rden_dly_value),
             .dbg_calib_rden_dly_en    (dbg_calib_rden_dly_en),
             .dbg_calib_rden_dly       (dbg_calib_rden_dly),
             .dbg_calib_gate_dly_value (dbg_calib_gate_dly_value),
             .dbg_calib_gate_dly_en    (dbg_calib_gate_dly_en),
             .dbg_calib_gate_dly       (dbg_calib_gate_dly)
             );
      end
    else if (C_USE_MIG_V4_PHY && C_MEM_TYPE == "DDR2")
      begin : gen_v4_ddr2_phy
        reg  [C_ECC_DATA_WIDTH*(C_IS_DDR+1)+
              C_MEM_DATA_WIDTH_INT-1:0] rd_data_d1;
        reg  [C_ECC_DATA_WIDTH*(C_IS_DDR+1)+
              C_MEM_DATA_WIDTH_INT-1:0] wdf_data_debug;
        reg  [C_ECC_DM_WIDTH*(C_IS_DDR+1)+
              C_MEM_DM_WIDTH_INT-1:0] wdf_mask_data_debug;
        reg  Ctrl_DP_RdFIFO_Push_d1;
        reg  rd_data_toggle;
        
        
        if (C_DEBUG_REG_ENABLE == 1) begin : gen_debug
          if (C_INCLUDE_ECC_SUPPORT == 1) begin : gen_ecc
            always @(posedge Clk0) begin
              rd_data_d1 <= rd_data;
              if (PhyIF_DP_RdFIFO_Push_tmp[0] == 1'b0)
                rd_data_toggle <= 1'b0;
              else
                rd_data_toggle <= ~rd_data_toggle;
              if (Rst) begin
                ecc_read_data0 <= {C_ECC_DATA_WIDTH{1'b0}};
                ecc_read_data1 <= {C_ECC_DATA_WIDTH{1'b0}};
              end else if ((rd_data_toggle == 1'b0) && (PhyIF_DP_RdFIFO_Push_tmp[0] == 1'b1)) begin
                ecc_read_data0 <= rd_data_d1[C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH-1:C_MEM_DATA_WIDTH];
                ecc_read_data1 <= rd_data_d1[C_ECC_DATA_WIDTH*2+C_MEM_DATA_WIDTH*2-1:C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH*2];
              end
              if (Rst) begin
                ecc_read_data2 <= {C_ECC_DATA_WIDTH{1'b0}};
                ecc_read_data3 <= {C_ECC_DATA_WIDTH{1'b0}};
              end else if ((rd_data_toggle == 1'b1) && (PhyIF_DP_RdFIFO_Push_tmp[0] == 1'b1)) begin
                ecc_read_data2 <= rd_data_d1[C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH-1:C_MEM_DATA_WIDTH];
                ecc_read_data3 <= rd_data_d1[C_ECC_DATA_WIDTH*2+C_MEM_DATA_WIDTH*2-1:C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH*2];
              end
            end
          end
        end

        always @(*) begin
          wdf_data_debug = wdf_data;
          wdf_mask_data_debug = wdf_mask_data;
        end

        v4_phy_top #
          (
           .TBY4TAPVALUE        (C_TBY4TAPVALUE),
           .WDF_RDEN_EARLY      (P_WDF_RDEN_EARLY),
           .WDF_RDEN_WIDTH      (C_NUM_PORTS),
           .BANK_WIDTH          (C_MEM_BANKADDR_WIDTH),
           .CLK_WIDTH           (C_MEM_CLK_WIDTH),
           .CKE_WIDTH           (C_MEM_CE_WIDTH),
           .COL_WIDTH           (C_MEM_ADDR_WIDTH),
           .CS_NUM              (C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS),
           .CS_WIDTH            (C_MEM_CS_N_WIDTH),
           .DM_WIDTH            (C_ECC_DM_WIDTH+C_MEM_DM_WIDTH),
           .DQS_WIDTH           (C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH),
           .DQS_BITS            (P_ECC_DQS_BITS+P_DQS_BITS),
           .DQ_WIDTH            (C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH),
           .DQ_BITS             (P_ECC_DQ_BITS+P_DQ_BITS),
           .DQ_PER_DQS          (C_MEM_DATA_WIDTH/C_MEM_DQS_WIDTH),
           .ODT_WIDTH           (C_MEM_ODT_WIDTH),
           .ROW_WIDTH           (C_MEM_ADDR_WIDTH),
           .ADDITIVE_LAT        (C_MEM_ADDITIVE_LATENCY),
           .BURST_LEN           (C_MEM_BURST_LENGTH),
           .BURST_TYPE          (0),
           .CAS_LAT             (C_MEM_CAS_LATENCY0),
           .ECC_ENABLE          (C_INCLUDE_ECC_SUPPORT),
           .ECC_ENCODE_PIPELINE (C_ECC_ENCODE_PIPELINE),
           .DQSN_ENABLE         (C_MEM_DQSN_ENABLE),
           .ODT_TYPE            (C_MEM_ODT_TYPE),
           .REDUCE_DRV          (C_MEM_REDUCED_DRV),
           .REG_ENABLE          (C_MEM_REG_DIMM),
           .TWR                 (C_TWR),
           .CLK_PERIOD          (C_MPMC_CLK_PERIOD),
           .DDR2_ENABLE         (C_MEM_DDR2_ENABLE),
           .DQS_GATE_EN         (C_MEM_DQS_GATE_EN),
           .IDEL_HIGH_PERF      (C_MEM_IDEL_HIGH_PERF),
           .SIM_ONLY            (C_SKIP_INIT_DELAY),
           .DEBUG_EN            (C_DEBUG_REG_ENABLE)
           )
          mpmc_phy_if_0 
            (
             // Clocks/Resets
             .clk0              (Clk0),
             .clk90             (Clk90),
             .rst0              (rst_phy),
             .rst90             (rst90_phy),
             // Initialization Signals
             .phy_init_wdf_wren (PhyIF_Init_Push_tmp),// Push signal for 
                                                     // phy_init_wdf_data.
             .phy_init_wdf_data (PhyIF_Init_Data_tmp),// Write training pattern
                                                     // to be pushed into write
                                                     // FIFO's during 
                                                     // initialization
             .phy_init_done     (PhyIF_Ctrl_InitDone_tmp),// Set to 0 from 
                                                     // reset until end of 
                                                     // initialization and 
                                                     // calibration.
             .ctrl_ref_flag     (Ctrl_Refresh_Flag), // One cycle high pulse 
                                                     // every time refresh is 
                                                     // requested.
             // Memory Control Signals
             .ctrl_addr         (AP_PhyIF_Addr),     // Pre IOB FF mem address.
             .ctrl_ba           (AP_PhyIF_BankAddr), // Pre IOB FF mem bank 
                                                     // address.
             .ctrl_ras_n        (Ctrl_PhyIF_RAS_n),  // Pre IOB FF memory RAS.
             .ctrl_cas_n        (Ctrl_PhyIF_CAS_n),  // Pre IOB FF memory CAS.
             .ctrl_we_n         (Ctrl_PhyIF_WE_n),   // Pre IOB FF memory WE.
             .ctrl_cs_n         (AP_PhyIF_CS_n),     // Pre IOB FF memory CS.
             // Memory Write Signals
             .ctrl_wren         (Ctrl_PhyIF_DQS_O),   // Indicator that DQS 
                                                      // should toggle.
             .wdf_data          (wdf_data_debug),     // Pre IOB FF write data.
             .wdf_mask_data     (wdf_mask_data_debug),// Pre IOB FF write data 
                                                      // mask.
             .wdf_rden          (PhyIF_DP_WrFIFO_Pop),// Write FIFO pop signal.
             // Memory Read Signals
             .ctrl_rden         (Ctrl_DP_RdFIFO_Push),// Pulse high for number 
                                                     // of cycles read push 
                                                     // will be asserted.  
                                                     // Needs to be high one 
                                                     // cycle before 
                                                     // ctrl_<ras/cas/we> 
                                                     // indicate read.
             .phy_calib_rden    (PhyIF_DP_RdFIFO_Push_tmp),// Read FIFO push.
             .rd_data_rise      (rd_data[C_ECC_DATA_WIDTH+
                                         C_MEM_DATA_WIDTH_INT/2-1:0]),
                                                     // Post IOB FF LSB read 
                                                     // data.
             .rd_data_fall      (rd_data[C_ECC_DATA_WIDTH*2+
                                         C_MEM_DATA_WIDTH_INT-1:
                                         C_ECC_DATA_WIDTH+
                                         C_MEM_DATA_WIDTH_INT/2]),
                                                     // Post IOB FF MSB read 
                                                     // data.
             // Memory I/Os
             .ddr_ck            (Mem_Clk_O),      // Post IOB FF memory clock.
             .ddr_ck_n          (Mem_Clk_n_O),    // Post IOB FF memory inverse
                                                  // clock.
             .ddr_addr          (Mem_Addr_O),     // Post IOB FF memory addr.
             .ddr_ba            (Mem_BankAddr_O), // Post IOB FF memory bank 
                                                  // address.
             .ddr_ras_n         (Mem_RAS_n_O),    // Post IOB FF memory RAS.
             .ddr_cas_n         (Mem_CAS_n_O),    // Post IOB FF memory CAS.
             .ddr_we_n          (Mem_WE_n_O),     // Post IOB FF memory WE.
             .ddr_cs_n          (Mem_CS_n_O),     // Post IOB FF memory CS.
             .ddr_cke           (Mem_CE_O),       // Post IOB FF memory CKE.
             .ddr_odt           (Mem_ODT_O),      // Post IOB FF memory ODT.
             .ddr_dm            (Mem_DM_O),       // Post IOB FF memory data 
                                                  // mask.
             .ddr_dqs           (DDR2_DQS),       // Post IOB FF memory data 
                                                  // strobe.
             .ddr_dqs_n         (DDR2_DQS_n),     // Post IOB FF memory inverse
                                                  // data strobe.
             .ddr_dq            (DDR2_DQ),        // Post IOB FF memory data.
             // Debug signals
             .dbg_idel_up_dq                (dbg_idel_up_dq),
             .dbg_idel_down_dq              (dbg_idel_down_dq),
             .dbg_sel_idel_dq               (dbg_sel_idel_dq),
             .dbg_calib_done                (dbg_calib_done_v4),
             .dbg_calib_err                 (dbg_calib_err_v4),
             .dbg_calib_dq_tap_cnt          (dbg_calib_dq_tap_cnt),
             .dbg_calib_rd_data_sel_value   (dbg_calib_rd_data_sel_value),
             .dbg_calib_rd_data_sel_en      (dbg_calib_rd_data_sel_en),
             .dbg_calib_rd_data_sel         (dbg_calib_rd_data_sel),
             .dbg_calib_rden_dly_value      (dbg_calib_rden_dly_value),
             .dbg_calib_rden_dly_en         (dbg_calib_rden_dly_en),
             .dbg_calib_rden_dly            (dbg_calib_rden_dly),
             .dbg_calib_delay_rd_fall_value (dbg_calib_delay_rd_fall_value),
             .dbg_calib_delay_rd_fall_en    (dbg_calib_delay_rd_fall_en),
             .dbg_calib_delay_rd_fall       (dbg_calib_delay_rd_fall),
             .dbg_calib_dq_delay_en_value   (dbg_calib_dq_delay_en_value),
             .dbg_calib_dq_delay_en_en      (dbg_calib_dq_delay_en_en),
             .dbg_calib_dq_delay_en         (dbg_calib_dq_delay_en),
             .dbg_calib_sel_done            (dbg_calib_sel_done),
             .dbg_calib_dq_in_byte_align_value(dbg_calib_dq_in_byte_align_value),
             .dbg_calib_dq_in_byte_align_en (dbg_calib_dq_in_byte_align_en),
             .dbg_calib_dq_in_byte_align    (dbg_calib_dq_in_byte_align),
             .dbg_calib_cal_first_loop_value(dbg_calib_cal_first_loop_value),
             .dbg_calib_cal_first_loop_en   (dbg_calib_cal_first_loop_en),
             .dbg_calib_cal_first_loop      (dbg_calib_cal_first_loop)
             );
      end
    else if (C_USE_MIG_V4_PHY && C_MEM_TYPE == "DDR")
      begin : gen_v4_ddr_phy
        reg  [C_ECC_DATA_WIDTH*(C_IS_DDR+1)+
              C_MEM_DATA_WIDTH_INT-1:0] rd_data_d1;
        reg  [C_ECC_DATA_WIDTH*(C_IS_DDR+1)+
              C_MEM_DATA_WIDTH_INT-1:0] wdf_data_debug;
        reg  [C_ECC_DM_WIDTH*(C_IS_DDR+1)+
              C_MEM_DM_WIDTH_INT-1:0] wdf_mask_data_debug;
        reg  Ctrl_DP_RdFIFO_Push_d1;
        reg  rd_data_toggle;
        
        
        if (C_DEBUG_REG_ENABLE == 1) begin : gen_debug
          if (C_INCLUDE_ECC_SUPPORT == 1) begin : gen_ecc
            always @(posedge Clk0) begin
              rd_data_d1 <= rd_data;
              if (PhyIF_DP_RdFIFO_Push_tmp[0] == 1'b0)
                rd_data_toggle <= 1'b0;
              else
                rd_data_toggle <= ~rd_data_toggle;
              if (Rst) begin
                ecc_read_data0 <= {C_ECC_DATA_WIDTH{1'b0}};
                ecc_read_data1 <= {C_ECC_DATA_WIDTH{1'b0}};
              end else if ((rd_data_toggle == 1'b0) && (PhyIF_DP_RdFIFO_Push_tmp[0] == 1'b1)) begin
                ecc_read_data0 <= rd_data_d1[C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH-1:C_MEM_DATA_WIDTH];
                ecc_read_data1 <= rd_data_d1[C_ECC_DATA_WIDTH*2+C_MEM_DATA_WIDTH*2-1:C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH*2];
              end
              if (Rst) begin
                ecc_read_data2 <= {C_ECC_DATA_WIDTH{1'b0}};
                ecc_read_data3 <= {C_ECC_DATA_WIDTH{1'b0}};
              end else if ((rd_data_toggle == 1'b1) && (PhyIF_DP_RdFIFO_Push_tmp[0] == 1'b1)) begin
                ecc_read_data2 <= rd_data_d1[C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH-1:C_MEM_DATA_WIDTH];
                ecc_read_data3 <= rd_data_d1[C_ECC_DATA_WIDTH*2+C_MEM_DATA_WIDTH*2-1:C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH*2];
              end
            end
            end
          end

          always @(*) begin
            wdf_data_debug = wdf_data;
            wdf_mask_data_debug = wdf_mask_data;
          end

        v4_phy_top #
          (
           .TBY4TAPVALUE        (C_TBY4TAPVALUE),
           .WDF_RDEN_EARLY      (P_WDF_RDEN_EARLY),
           .WDF_RDEN_WIDTH      (C_NUM_PORTS),
           .BANK_WIDTH          (C_MEM_BANKADDR_WIDTH),
           .CLK_WIDTH           (C_MEM_CLK_WIDTH),
           .CKE_WIDTH           (C_MEM_CE_WIDTH),
           .COL_WIDTH           (C_MEM_ADDR_WIDTH),
           .CS_NUM              (C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS),
           .CS_WIDTH            (C_MEM_CS_N_WIDTH),
           .DM_WIDTH            (C_ECC_DM_WIDTH+C_MEM_DM_WIDTH),
           .DQS_WIDTH           (C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH),
           .DQS_BITS            (P_ECC_DQS_BITS+P_DQS_BITS),
           .DQ_WIDTH            (C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH),
           .DQ_BITS             (P_ECC_DQ_BITS+P_DQ_BITS),
           .DQ_PER_DQS          (C_MEM_DATA_WIDTH/C_MEM_DQS_WIDTH),
           .ODT_WIDTH           (C_MEM_ODT_WIDTH),
           .ROW_WIDTH           (C_MEM_ADDR_WIDTH),
           .ADDITIVE_LAT        (C_MEM_ADDITIVE_LATENCY),
           .BURST_LEN           (C_MEM_BURST_LENGTH),
           .BURST_TYPE          (0),
           .CAS_LAT             (C_MEM_CAS_LATENCY0),
           .ECC_ENABLE          (C_INCLUDE_ECC_SUPPORT),
           .ECC_ENCODE_PIPELINE (C_ECC_ENCODE_PIPELINE),
           .DQSN_ENABLE         (C_MEM_DQSN_ENABLE),
           .ODT_TYPE            (C_MEM_ODT_TYPE),
           .REDUCE_DRV          (C_MEM_REDUCED_DRV),
           .REG_ENABLE          (C_MEM_REG_DIMM),
           .TWR                 (C_TWR),
           .CLK_PERIOD          (C_MPMC_CLK_PERIOD),
           .DDR2_ENABLE         (C_MEM_DDR2_ENABLE),
           .DQS_GATE_EN         (C_MEM_DQS_GATE_EN),
           .IDEL_HIGH_PERF      (C_MEM_IDEL_HIGH_PERF),
           .SIM_ONLY            (C_SKIP_INIT_DELAY),
           .DEBUG_EN            (C_DEBUG_REG_ENABLE)
           )
          mpmc_phy_if_0 
            (
             // Clocks/Resets
             .clk0              (Clk0),
             .clk90             (Clk90),
             .rst0              (rst_phy),
             .rst90             (rst90_phy),
             // Initialization Signals
             .phy_init_wdf_wren (PhyIF_Init_Push_tmp),// Push signal for 
                                                     // phy_init_wdf_data.
             .phy_init_wdf_data (PhyIF_Init_Data_tmp),// Write training pattern
                                                     // to be pushed into
                                                     // write FIFO's during 
                                                     // initialization
             .phy_init_done     (PhyIF_Ctrl_InitDone_tmp),// Set to 0 from 
                                                     // reset until end of 
                                                     // initialization and 
                                                     // calibration.
             .ctrl_ref_flag     (Ctrl_Refresh_Flag), // One cycle high pulse 
                                                     // every time refresh is 
                                                     // requested.
             // Memory Control Signals
             .ctrl_addr         (AP_PhyIF_Addr),     // Pre IOB FF mem address.
             .ctrl_ba           (AP_PhyIF_BankAddr), // Pre IOB FF memory bank 
                                                     // address.
             .ctrl_ras_n        (Ctrl_PhyIF_RAS_n),  // Pre IOB FF memory RAS.
             .ctrl_cas_n        (Ctrl_PhyIF_CAS_n),  // Pre IOB FF memory CAS.
             .ctrl_we_n         (Ctrl_PhyIF_WE_n),   // Pre IOB FF memory WE.
             .ctrl_cs_n         (AP_PhyIF_CS_n),     // Pre IOB FF memory CS.
             // Memory Write Signals
             .ctrl_wren         (Ctrl_PhyIF_DQS_O),   // Indicator that DQS 
                                                      // should toggle.
             .wdf_data          (wdf_data_debug),     // Pre IOB FF write data.
             .wdf_mask_data     (wdf_mask_data_debug),// Pre IOB FF write data 
                                                      // mask.
             .wdf_rden          (PhyIF_DP_WrFIFO_Pop),// Write FIFO pop signal.
             // Memory Read Signals
             .ctrl_rden         (Ctrl_DP_RdFIFO_Push),// Pulse high for number 
                                                     // of cycles read push 
                                                     // will be asserted.  
                                                     // Needs to be high one 
                                                     // cycle before 
                                                     // ctrl_<ras/cas/we> 
                                                     // indicate read.
             .phy_calib_rden    (PhyIF_DP_RdFIFO_Push_tmp),// Read FIFO push.
             .rd_data_rise      (rd_data[C_ECC_DATA_WIDTH+
                                         C_MEM_DATA_WIDTH_INT/2-1:0]),
                                                     // Post IOB FF LSB read 
                                                     // data.
             .rd_data_fall      (rd_data[C_ECC_DATA_WIDTH*2+
                                         C_MEM_DATA_WIDTH_INT-1:
                                         C_ECC_DATA_WIDTH+
                                         C_MEM_DATA_WIDTH_INT/2]),
                                                     // Post IOB FF MSB read 
                                                     // data.
             // Memory I/Os
             .ddr_ck            (Mem_Clk_O),      // Post IOB FF memory clock.
             .ddr_ck_n          (Mem_Clk_n_O),    // Post IOB FF memory inverse
                                                  // clock.
             .ddr_addr          (Mem_Addr_O),     // Post IOB FF mem address.
             .ddr_ba            (Mem_BankAddr_O), // Post IOB FF memory bank 
                                                  // address.
             .ddr_ras_n         (Mem_RAS_n_O),    // Post IOB FF memory RAS.
             .ddr_cas_n         (Mem_CAS_n_O),    // Post IOB FF memory CAS.
             .ddr_we_n          (Mem_WE_n_O),     // Post IOB FF memory WE.
             .ddr_cs_n          (Mem_CS_n_O),     // Post IOB FF memory CS.
             .ddr_cke           (Mem_CE_O),       // Post IOB FF memory CKE.
             .ddr_odt           (Mem_ODT_O),      // Post IOB FF memory ODT.
             .ddr_dm            (Mem_DM_O),       // Post IOB FF memory data 
                                                  // mask.
             .ddr_dqs           (DDR_DQS),        // Post IOB FF memory data 
                                                  // strobe.
             .ddr_dqs_n         (), 
             .ddr_dq            (DDR_DQ),         // Post IOB FF memory data.
             // Debug signals
             .dbg_idel_up_dq                (dbg_idel_up_dq),
             .dbg_idel_down_dq              (dbg_idel_down_dq),
             .dbg_sel_idel_dq               (dbg_sel_idel_dq),
             .dbg_calib_done                (dbg_calib_done_v4),
             .dbg_calib_err                 (dbg_calib_err_v4),
             .dbg_calib_dq_tap_cnt          (dbg_calib_dq_tap_cnt),
             .dbg_calib_rd_data_sel_value   (dbg_calib_rd_data_sel_value),
             .dbg_calib_rd_data_sel_en      (dbg_calib_rd_data_sel_en),
             .dbg_calib_rd_data_sel         (dbg_calib_rd_data_sel),
             .dbg_calib_rden_dly_value      (dbg_calib_rden_dly_value),
             .dbg_calib_rden_dly_en         (dbg_calib_rden_dly_en),
             .dbg_calib_rden_dly            (dbg_calib_rden_dly),
             .dbg_calib_delay_rd_fall_value (dbg_calib_delay_rd_fall_value),
             .dbg_calib_delay_rd_fall_en    (dbg_calib_delay_rd_fall_en),
             .dbg_calib_delay_rd_fall       (dbg_calib_delay_rd_fall),
             .dbg_calib_dq_delay_en_value   (dbg_calib_dq_delay_en_value),
             .dbg_calib_dq_delay_en_en      (dbg_calib_dq_delay_en_en),
             .dbg_calib_dq_delay_en         (dbg_calib_dq_delay_en),
             .dbg_calib_sel_done            (dbg_calib_sel_done),
             .dbg_calib_dq_in_byte_align_value(dbg_calib_dq_in_byte_align_value),
             .dbg_calib_dq_in_byte_align_en (dbg_calib_dq_in_byte_align_en),
             .dbg_calib_dq_in_byte_align    (dbg_calib_dq_in_byte_align),
             .dbg_calib_cal_first_loop_value(dbg_calib_cal_first_loop_value),
             .dbg_calib_cal_first_loop_en   (dbg_calib_cal_first_loop_en),
             .dbg_calib_cal_first_loop      (dbg_calib_cal_first_loop)
             );
      end
    else if (C_USE_MIG_S3_PHY && C_MEM_TYPE == "DDR2")
      begin : gen_s3_ddr2_phy
        reg                                       ctrl_wren_i;
        reg [C_MEM_ADDR_WIDTH-1:0]                ctrl_addr_i;
        reg [C_MEM_BANKADDR_WIDTH-1:0]            ctrl_ba_i;
        reg                                       ctrl_ras_n_i;
        reg                                       ctrl_cas_n_i;
        reg                                       ctrl_we_n_i;
        reg [C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS-1:0] ctrl_cs_n_i;
        reg                                       ctrl_rden_i;
        if (C_INCLUDE_ECC_SUPPORT == 1) begin : gen_ecc
          reg                                       Ctrl_DP_RdFIFO_Push_d1;
          always @(posedge Clk0) begin
            Ctrl_DP_RdFIFO_Push_d1 <= Ctrl_DP_RdFIFO_Push;
            ctrl_wren_i  <= Ctrl_PhyIF_DQS_O;
            ctrl_rden_i <= Ctrl_Is_Write ? Ctrl_DP_RdFIFO_Push_d1 :
                                           Ctrl_DP_RdFIFO_Push;
          end
          always @(negedge Clk90) begin
            ctrl_addr_i  <= AP_PhyIF_Addr;
            ctrl_ba_i    <= AP_PhyIF_BankAddr;
            ctrl_ras_n_i <= Ctrl_PhyIF_RAS_n;
            ctrl_cas_n_i <= Ctrl_PhyIF_CAS_n;
            ctrl_we_n_i  <= Ctrl_PhyIF_WE_n;
            ctrl_cs_n_i  <= AP_PhyIF_CS_n;
          end
        end else begin : gen_noecc
          always @(*) begin
            ctrl_wren_i  <= Ctrl_PhyIF_DQS_O;
            ctrl_rden_i  <= Ctrl_DP_RdFIFO_Push;
            ctrl_addr_i  <= AP_PhyIF_Addr;
            ctrl_ba_i    <= AP_PhyIF_BankAddr;
            ctrl_ras_n_i <= Ctrl_PhyIF_RAS_n;
            ctrl_cas_n_i <= Ctrl_PhyIF_CAS_n;
            ctrl_we_n_i  <= Ctrl_PhyIF_WE_n;
            ctrl_cs_n_i  <= AP_PhyIF_CS_n;
          end
        end
        s3_phy_top #
          (
           .BANK_WIDTH     (C_MEM_BANKADDR_WIDTH),
           .ROW_WIDTH      (C_MEM_ADDR_WIDTH),
           .COL_WIDTH      (C_MEM_ADDR_WIDTH),
           .CLK_WIDTH      (C_MEM_CLK_WIDTH),
           .CKE_WIDTH      (C_MEM_CE_WIDTH),
           .CS_NUM         (C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS),
           .CS_WIDTH       (C_MEM_CS_N_WIDTH),
           .DM_WIDTH       (C_ECC_DM_WIDTH+C_MEM_DM_WIDTH),
           //.DQ_BITS        (P_DQ_BITS),
           .DQ_BITS        (C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH),
           .DQ_PER_DQS     (C_MEM_DATA_WIDTH/C_MEM_DQS_WIDTH),
           .DQS_BITS       (P_ECC_DQS_BITS+P_DQS_BITS),
           .DQS_WIDTH      (C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH),
           .DQSN_ENABLE    (C_MEM_DQSN_ENABLE),
           .ODT_WIDTH      (C_MEM_ODT_WIDTH),
           .ADDITIVE_LAT   (C_MEM_ADDITIVE_LATENCY),
           .BURST_LEN      (C_MEM_BURST_LENGTH),
           .BURST_TYPE     (0),
           .CAS_LAT        (C_MEM_CAS_LATENCY0),
           .ECC_ENABLE     (C_INCLUDE_ECC_SUPPORT),
           .ODT_TYPE       (C_MEM_ODT_TYPE),
           .REDUCE_DRV     (C_MEM_REDUCED_DRV),
           .REG_ENABLE     (C_MEM_REG_DIMM),
           .TWR            (C_TWR),
           .CLK_PERIOD     (C_MPMC_CLK_PERIOD),
           .DDR2_ENABLE    (C_MEM_DDR2_ENABLE),
           .DQS_GATE_EN    (C_MEM_DQS_GATE_EN),
           .IDEL_HIGH_PERF (C_MEM_IDEL_HIGH_PERF),
           .WDF_RDEN_WIDTH (C_NUM_PORTS),
           .WDF_RDEN_EARLY (P_WDF_RDEN_EARLY),
           .SIM_ONLY       (C_SKIP_INIT_DELAY),
           .C_FAMILY       (C_FAMILY),
           .C_SPECIAL_BOARD(C_SPECIAL_BOARD),
           .C_DEBUG_EN     (C_DEBUG_REG_ENABLE)
           )
          mpmc_phy_if_0 
            (
             .clk0              (Clk0),
             .clk90             (Clk90),
             .rst0              (rst_phy),
             .rst90             (rst90_phy),
             .ctrl_wren         (ctrl_wren_i),  // Indicator that DQS should toggle.
             .ctrl_addr         (ctrl_addr_i),  // Pre IOB FF memory address.
             .ctrl_ba           (ctrl_ba_i), // Pre IOB FF memory bank address.
             .ctrl_ras_n        (ctrl_ras_n_i), // Pre IOB FF memory RAS.
             .ctrl_cas_n        (ctrl_cas_n_i), // Pre IOB FF memory CAS.
             .ctrl_we_n         (ctrl_we_n_i),  // Pre IOB FF memory WE.
             .ctrl_cs_n         (ctrl_cs_n_i),  // Pre IOB FF memory CS.
             .ctrl_rden         (ctrl_rden_i),  // Pulse high for number of cycles read push will be asserted.  Needs to be high one cycle before ctrl_<ras/cas/we> indicate read.
             .ctrl_ref_flag     (Ctrl_Refresh_Flag),// One cycle high pulse every time refresh is requested.
             .wdf_data          (wdf_data),         // Pre IOB FF write data.
             .wdf_mask_data     (wdf_mask_data),    // Pre IOB FF write data mask.
             .wdf_rden          (PhyIF_DP_WrFIFO_Pop),// Write FIFO pop signal.
             .phy_init_done     (PhyIF_Ctrl_InitDone_tmp),// Set to 0 from 
                                                    // reset until end of 
                                                    // initialization and 
                                                    // calibration.
             .phy_calib_rden    (PhyIF_DP_RdFIFO_Push_tmp),// Read FIFO push.
             .rd_data_rise      (rd_data[C_ECC_DATA_WIDTH+
                                         C_MEM_DATA_WIDTH_INT/2-1:0]),
                                                    // Post IOB FF LSB rd data.
             .rd_data_fall      (rd_data[C_ECC_DATA_WIDTH*2+
                                         C_MEM_DATA_WIDTH_INT-1:
                                         C_ECC_DATA_WIDTH+
                                         C_MEM_DATA_WIDTH_INT/2]),
                                                    // Post IOB FF MSB rd data.
             .ddr_ck            (Mem_Clk_O),     // Post IOB FF memory clock.
             .ddr_ck_n          (Mem_Clk_n_O),   // Post IOB FF memory inverse 
                                                 // clock.
             .ddr_addr          (Mem_Addr_O),    // Post IOB FF memory address.
             .ddr_ba            (Mem_BankAddr_O),// Post IOB FF memory bank 
                                                 // address.
             .ddr_ras_n         (Mem_RAS_n_O),   // Post IOB FF memory RAS.
             .ddr_cas_n         (Mem_CAS_n_O),   // Post IOB FF memory CAS.
             .ddr_we_n          (Mem_WE_n_O),    // Post IOB FF memory WE.
             .ddr_cs_n          (Mem_CS_n_O),    // Post IOB FF memory CS.
             .ddr_cke           (Mem_CE_O),      // Post IOB FF memory CKE.
             .ddr_odt           (Mem_ODT_O),     // Post IOB FF memory ODT.
             .ddr_dm            (Mem_DM_O),      // Post IOB FF memory data 
                                                 // mask.
             .ddr_dqs           (DDR2_DQS),      // Post IOB FF memory data 
                                                 // strobe.
             .ddr_dqs_n         (DDR2_DQS_n),    // Post IOB FF memory inverse 
                                                 // data strobe.
             .ddr_dq            (DDR2_DQ),       // Post IOB FF memory data.
             .rst_dqs_div_out   (Mem_DQS_Div_O), // Post IOB DQS for calib
             .rst_dqs_div_in    (Mem_DQS_Div_I), // Input feedback from 
                                                 // Mem_dqs_div_out
             .dbg_delay_sel          (dbg_calib_delay_sel),
             .dbg_rst_calib          (dbg_calib_rst_calib),
             .dbg_phase_cnt          (dbg_calib_phase_cnt),
             .dbg_cnt                (dbg_calib_cnt),
             .dbg_trans_onedtct      (dbg_calib_trans_onedtct),
             .dbg_trans_twodtct      (dbg_calib_trans_twodtct),
             .dbg_enb_trans_two_dtct (dbg_calib_enb_trans_two_dtct),
             .vio_out_dqs            (vio_out_dqs),
             .vio_out_dqs_en         (vio_out_dqs_en),
             .vio_out_rst_dqs_div    (vio_out_rst_dqs_div),
             .vio_out_rst_dqs_div_en (vio_out_rst_dqs_div_en)
             );
      end
    else if (C_USE_MIG_S3_PHY && C_MEM_TYPE == "DDR")
      begin : gen_s3_ddr_phy
        reg                                       ctrl_wren_i;
        reg [C_MEM_ADDR_WIDTH-1:0]                ctrl_addr_i;
        reg [C_MEM_BANKADDR_WIDTH-1:0]            ctrl_ba_i;
        reg                                       ctrl_ras_n_i;
        reg                                       ctrl_cas_n_i;
        reg                                       ctrl_we_n_i;
        reg [C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS-1:0] ctrl_cs_n_i;
        reg                                       ctrl_rden_i;
        if (C_INCLUDE_ECC_SUPPORT == 1) begin : gen_ecc
          reg                                       Ctrl_DP_RdFIFO_Push_d1;
          always @(posedge Clk0) begin
            Ctrl_DP_RdFIFO_Push_d1 <= Ctrl_DP_RdFIFO_Push;
            ctrl_wren_i  <= Ctrl_PhyIF_DQS_O;
            ctrl_rden_i <= Ctrl_Is_Write ? Ctrl_DP_RdFIFO_Push_d1 :
                                           Ctrl_DP_RdFIFO_Push;
          end
          always @(negedge Clk90) begin
            ctrl_addr_i  <= AP_PhyIF_Addr;
            ctrl_ba_i    <= AP_PhyIF_BankAddr;
            ctrl_ras_n_i <= Ctrl_PhyIF_RAS_n;
            ctrl_cas_n_i <= Ctrl_PhyIF_CAS_n;
            ctrl_we_n_i  <= Ctrl_PhyIF_WE_n;
            ctrl_cs_n_i  <= AP_PhyIF_CS_n;
          end
        end else begin : gen_noecc
          always @(*) begin
            ctrl_wren_i  <= Ctrl_PhyIF_DQS_O;
            ctrl_rden_i  <= Ctrl_DP_RdFIFO_Push;
            ctrl_addr_i  <= AP_PhyIF_Addr;
            ctrl_ba_i    <= AP_PhyIF_BankAddr;
            ctrl_ras_n_i <= Ctrl_PhyIF_RAS_n;
            ctrl_cas_n_i <= Ctrl_PhyIF_CAS_n;
            ctrl_we_n_i  <= Ctrl_PhyIF_WE_n;
            ctrl_cs_n_i  <= AP_PhyIF_CS_n;
          end
        end
        s3_phy_top #
          (
           .BANK_WIDTH     (C_MEM_BANKADDR_WIDTH),
           .ROW_WIDTH      (C_MEM_ADDR_WIDTH),
           .COL_WIDTH      (C_MEM_ADDR_WIDTH),
           .CLK_WIDTH      (C_MEM_CLK_WIDTH),
           .CKE_WIDTH      (C_MEM_CE_WIDTH),
           .CS_NUM         (C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS),
           .CS_WIDTH       (C_MEM_CS_N_WIDTH),
           .DM_WIDTH       (C_ECC_DM_WIDTH+C_MEM_DM_WIDTH),
           //.DQ_BITS        (P_DQ_BITS),
           .DQ_BITS        (C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH),
           .DQ_PER_DQS     (C_MEM_DATA_WIDTH/C_MEM_DQS_WIDTH),
           .DQS_BITS       (P_ECC_DQS_BITS+P_DQS_BITS),
           .DQS_WIDTH      (C_ECC_DQS_WIDTH+C_MEM_DQS_WIDTH),
           .DQSN_ENABLE    (C_MEM_DQSN_ENABLE),
           .ODT_WIDTH      (C_MEM_ODT_WIDTH),
           .ADDITIVE_LAT   (C_MEM_ADDITIVE_LATENCY),
           .BURST_LEN      (C_MEM_BURST_LENGTH),
           .BURST_TYPE     (0),
           .CAS_LAT        (C_MEM_CAS_LATENCY0),
           .ECC_ENABLE     (C_INCLUDE_ECC_SUPPORT),
           .ODT_TYPE       (C_MEM_ODT_TYPE),
           .REDUCE_DRV     (C_MEM_REDUCED_DRV),
           .REG_ENABLE     (C_MEM_REG_DIMM),
           .TWR            (C_TWR),
           .CLK_PERIOD     (C_MPMC_CLK_PERIOD),
           .DDR2_ENABLE    (C_MEM_DDR2_ENABLE),
           .DQS_GATE_EN    (C_MEM_DQS_GATE_EN),
           .IDEL_HIGH_PERF (C_MEM_IDEL_HIGH_PERF),
           .WDF_RDEN_WIDTH (C_NUM_PORTS),
           .WDF_RDEN_EARLY (P_WDF_RDEN_EARLY),
           .SIM_ONLY       (C_SKIP_INIT_DELAY),
           .C_FAMILY       (C_FAMILY),
           .C_SPECIAL_BOARD(C_SPECIAL_BOARD),
           .C_DEBUG_EN     (C_DEBUG_REG_ENABLE)
           )
          mpmc_phy_if_0 
            (
             .clk0              (Clk0),
             .clk90             (Clk90),
             .rst0              (rst_phy),
             .rst90             (rst90_phy),
             .ctrl_wren         (ctrl_wren_i),      // Indicator that DQS 
                                                    // should toggle.
             .ctrl_addr         (ctrl_addr_i),      // Pre IOB FF mem address.
             .ctrl_ba           (ctrl_ba_i),        // Pre IOB FF memory bank 
                                                    // address.
             .ctrl_ras_n        (ctrl_ras_n_i),     // Pre IOB FF memory RAS.
             .ctrl_cas_n        (ctrl_cas_n_i),     // Pre IOB FF memory CAS.
             .ctrl_we_n         (ctrl_we_n_i),      // Pre IOB FF memory WE.
             .ctrl_cs_n         (ctrl_cs_n_i),      // Pre IOB FF memory CS.
             .ctrl_rden         (ctrl_rden_i),      // Pulse high for number 
                                                    // of cycles read push will
                                                    // be asserted.  Needs to 
                                                    // be high one cycle before
                                                    // ctrl_<ras/cas/we> 
                                                    // indicate read.
             .ctrl_ref_flag     (Ctrl_Refresh_Flag),// One cycle high pulse 
                                                    // every time refresh is 
                                                    // requested.
             .wdf_data          (wdf_data),         // Pre IOB FF write data.
             .wdf_mask_data     (wdf_mask_data),    // Pre IOB FF write data 
                                                    // mask.
             .wdf_rden          (PhyIF_DP_WrFIFO_Pop),// Write FIFO pop signal.
             .phy_init_done     (PhyIF_Ctrl_InitDone_tmp),// Set to 0 from 
                                                    // reset until end of 
                                                    // initialization and 
                                                    // calibration.
             .phy_calib_rden    (PhyIF_DP_RdFIFO_Push_tmp),// Read FIFO push.
             .rd_data_rise      (rd_data[C_ECC_DATA_WIDTH+
                                         C_MEM_DATA_WIDTH_INT/2-1:0]),
                                                    // Post IOB FF LSB rd data.
             .rd_data_fall      (rd_data[C_ECC_DATA_WIDTH*2+
                                         C_MEM_DATA_WIDTH_INT-1:
                                         C_ECC_DATA_WIDTH+
                                         C_MEM_DATA_WIDTH_INT/2]),
                                                    // Post IOB FF MSB rd data.
             .ddr_ck            (Mem_Clk_O),     // Post IOB FF memory clock.
             .ddr_ck_n          (Mem_Clk_n_O),   // Post IOB FF memory inverse 
                                                 // clock.
             .ddr_addr          (Mem_Addr_O),    // Post IOB FF memory address.
             .ddr_ba            (Mem_BankAddr_O),// Post IOB FF memory bank 
                                                 // address.
             .ddr_ras_n         (Mem_RAS_n_O),   // Post IOB FF memory RAS.
             .ddr_cas_n         (Mem_CAS_n_O),   // Post IOB FF memory CAS.
             .ddr_we_n          (Mem_WE_n_O),    // Post IOB FF memory WE.
             .ddr_cs_n          (Mem_CS_n_O),    // Post IOB FF memory CS.
             .ddr_cke           (Mem_CE_O),      // Post IOB FF memory CKE.
             .ddr_odt           (Mem_ODT_O),     // Post IOB FF memory ODT.
             .ddr_dm            (Mem_DM_O),      // Post IOB FF memory data 
                                                 // mask.
             .ddr_dqs           (DDR_DQS),       // Post IOB FF memory data 
                                                 // strobe.
             .ddr_dqs_n         (),              // Post IOB FF memory inverse 
                                                 // data strobe.
             .ddr_dq            (DDR_DQ),        // Post IOB FF memory data.
             .rst_dqs_div_out   (Mem_DQS_Div_O), // Post IOB DQS for calib
             .rst_dqs_div_in    (Mem_DQS_Div_I), // Input feedback from 
                                                 // Mem_dqs_div_out
             .dbg_delay_sel          (dbg_calib_delay_sel),
             .dbg_rst_calib          (dbg_calib_rst_calib),
             .dbg_phase_cnt          (dbg_calib_phase_cnt),
             .dbg_cnt                (dbg_calib_cnt),
             .dbg_trans_onedtct      (dbg_calib_trans_onedtct),
             .dbg_trans_twodtct      (dbg_calib_trans_twodtct),
             .dbg_enb_trans_two_dtct (dbg_calib_enb_trans_two_dtct),
             .vio_out_dqs            (vio_out_dqs),
             .vio_out_dqs_en         (vio_out_dqs_en),
             .vio_out_rst_dqs_div    (vio_out_rst_dqs_div),
             .vio_out_rst_dqs_div_en (vio_out_rst_dqs_div_en)
             );
      end
    else if ( C_MEM_TYPE == "SDRAM" )
      begin : gen_sdram_phy
        phy_top_sdram #
          (
           .C_FAMILY            (C_FAMILY),
           //*****************************************************************
           .C_RDDATA_CLK_SEL    (C_STATIC_PHY_RDDATA_CLK_SEL),
           .C_RDDATA_SWAP_RISE  (C_STATIC_PHY_RDDATA_SWAP_RISE),
           .C_RDEN_DELAY        (C_STATIC_PHY_RDEN_DELAY),
           .C_NUM_REG           (C_STATIC_PHY_NUM_REG),
           //*****************************************************************
           .WDF_RDEN_EARLY      (P_WDF_RDEN_EARLY),
           .WDF_RDEN_WIDTH      (C_NUM_PORTS),
           .BANK_WIDTH          (C_MEM_BANKADDR_WIDTH),
           .CLK_WIDTH           (C_MEM_CLK_WIDTH),
           .CKE_WIDTH           (C_MEM_CE_WIDTH),
           .COL_WIDTH           (C_MEM_ADDR_WIDTH),
           .CS_NUM              (C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS),
           .CS_WIDTH            (C_MEM_CS_N_WIDTH),
           .DM_WIDTH            (C_ECC_DM_WIDTH+C_MEM_DM_WIDTH),
           .DQ_WIDTH            (C_ECC_DATA_WIDTH+C_MEM_DATA_WIDTH),
           .ROW_WIDTH           (C_MEM_ADDR_WIDTH),
           .BURST_LEN           (C_MEM_BURST_LENGTH),
           .BURST_TYPE          (0),
           .CAS_LAT             (C_MEM_CAS_LATENCY0),
           .ECC_ENABLE          (C_INCLUDE_ECC_SUPPORT),
           .REG_ENABLE          (C_MEM_REG_DIMM),
           .SIM_ONLY            (C_SKIP_INIT_DELAY)
           )
          mpmc_phy_if_0 
            (
             // Clocks/Resets
             .clk0              (Clk0),
             .rst0              (rst_phy),
             .clk0_rddata       (Clk_Mem),
             .dcm_en            (DCM_PSEN),
             .dcm_incdec        (DCM_PSINCDEC),
             .dcm_done          (DCM_PSDONE),
             .reg_ce            (Static_Phy_Reg_CE),
             .reg_in            (Static_Phy_Reg_In),
             .reg_out           (static_phy_reg_out_i),

             // Initialization Signals
             .phy_init_done     (PhyIF_Ctrl_InitDone_tmp),// Set to 0 from 
                                                    // reset until end of 
                                                    // initialization and 
                                                    // calibration.
             .ctrl_ref_flag     (Ctrl_Refresh_Flag),// One cycle high pulse 
                                                    // every time refresh is 
                                                    // requested.
             // Memory Control Signals
             .ctrl_addr         (AP_PhyIF_Addr),    // Pre IOB FF mem address.
             .ctrl_ba           (AP_PhyIF_BankAddr),// Pre IOB FF memory bank 
                                                    // address.
             .ctrl_ras_n        (Ctrl_PhyIF_RAS_n), // Pre IOB FF memory RAS.
             .ctrl_cas_n        (Ctrl_PhyIF_CAS_n), // Pre IOB FF memory CAS.
             .ctrl_we_n         (Ctrl_PhyIF_WE_n),  // Pre IOB FF memory WE.
             .ctrl_cs_n         (AP_PhyIF_CS_n),    // Pre IOB FF memory CS.
             // Memory Write Signals
             .ctrl_wren         (Ctrl_PhyIF_DQS_O), // Indicator that DQS 
                                                    // should toggle.
             .wdf_data          (wdf_data),         // Pre IOB FF write data.
             .wdf_mask_data     (wdf_mask_data),    // Pre IOB FF write data 
                                                    // mask.
             .wdf_rden          (PhyIF_DP_WrFIFO_Pop),// Write FIFO pop signal.
             // Memory Read Signals
             .ctrl_rden         (Ctrl_DP_RdFIFO_Push),// Pulse high for number 
                                                    // of cycles read push will
                                                    // be asserted. Needs to be
                                                    // high one cycle before 
                                                    // ctrl_<ras/cas/we> 
                                                    // indicate read.
             .phy_calib_rden    (PhyIF_DP_RdFIFO_Push_tmp),// Read FIFO push .
             .rd_data_rise      (rd_data[C_ECC_DATA_WIDTH+
                                         C_MEM_DATA_WIDTH_INT-1:0]),
                                                    // Post IOB FF LSB rd data.
             // Memory I/Os
             .sdram_ck          (Mem_Clk_O),     // Post IOB FF memory clock.
             .sdram_addr        (Mem_Addr_O),    // Post IOB FF memory address.
             .sdram_ba          (Mem_BankAddr_O),// Post IOB FF memory bank 
                                                 // address.
             .sdram_ras_n       (Mem_RAS_n_O),   // Post IOB FF memory RAS.
             .sdram_cas_n       (Mem_CAS_n_O),   // Post IOB FF memory CAS.
             .sdram_we_n        (Mem_WE_n_O),    // Post IOB FF memory WE.
             .sdram_cs_n        (Mem_CS_n_O),    // Post IOB FF memory CS.
             .sdram_cke         (Mem_CE_O),      // Post IOB FF memory CKE.
             .sdram_dm          (Mem_DM_O),      // Post IOB FF memory data 
                                                 // mask.
             .sdram_dq          (SDRAM_DQ)       // Post IOB FF memory data.
             );
      end        
    
  endgenerate

 
   // Address Path
   function [7:0] decode_offset;
      input [31:0] n;
      reg [8:0] j;
      begin
         for (j = 0; j < 32; j = j + 1) begin
            if (n[j]) decode_offset = j;
         end
      end   
   endfunction

   generate
    if (C_USE_MCB_S6_PHY == 0) 
      begin : gen_paths
        if (C_MEM_NUM_DIMMS==2)
          begin : SPD_Offsets_2_DIMMS
             assign SPD_AP_Total_Offset = {decode_offset(C_MEM_SUPPORTED_TOTAL_OFFSETS),decode_offset(C_MEM_SUPPORTED_TOTAL_OFFSETS)};
             assign SPD_AP_DIMM_Offset  = {decode_offset(C_MEM_SUPPORTED_DIMM_OFFSETS),decode_offset(C_MEM_SUPPORTED_DIMM_OFFSETS)};
             assign SPD_AP_Rank_Offset  = {decode_offset(C_MEM_SUPPORTED_RANK_OFFSETS),decode_offset(C_MEM_SUPPORTED_RANK_OFFSETS)};
             assign SPD_AP_Bank_Offset  = {decode_offset(C_MEM_SUPPORTED_BANK_OFFSETS),decode_offset(C_MEM_SUPPORTED_BANK_OFFSETS)};
             assign SPD_AP_Row_Offset   = {decode_offset(C_MEM_SUPPORTED_ROW_OFFSETS),decode_offset(C_MEM_SUPPORTED_ROW_OFFSETS)};
             assign SPD_AP_Col_Offset   = {decode_offset(C_MEM_SUPPORTED_COL_OFFSETS),decode_offset(C_MEM_SUPPORTED_COL_OFFSETS)};
          end
        else
          begin : SPD_Offsets_1_DIMMS
             assign SPD_AP_Total_Offset = decode_offset(C_MEM_SUPPORTED_TOTAL_OFFSETS);
             assign SPD_AP_DIMM_Offset  = decode_offset(C_MEM_SUPPORTED_DIMM_OFFSETS);
             assign SPD_AP_Rank_Offset  = decode_offset(C_MEM_SUPPORTED_RANK_OFFSETS);
             assign SPD_AP_Bank_Offset  = decode_offset(C_MEM_SUPPORTED_BANK_OFFSETS);
             assign SPD_AP_Row_Offset   = decode_offset(C_MEM_SUPPORTED_ROW_OFFSETS);
             assign SPD_AP_Col_Offset   = decode_offset(C_MEM_SUPPORTED_COL_OFFSETS);
          end
     
        mpmc_addr_path #(
            .C_FAMILY(C_FAMILY),
            .C_USE_MIG_S3_PHY(C_USE_MIG_S3_PHY),
            .C_USE_STATIC_PHY(C_USE_STATIC_PHY),
            .C_NUM_PORTS(C_NUM_PORTS),
            .C_PI_ADDR_WIDTH(C_PIX_ADDR_WIDTH_MAX),
            .C_MEM_ADDR_WIDTH(C_MEM_ADDR_WIDTH),
            .C_MEM_BANKADDR_WIDTH(C_MEM_BANKADDR_WIDTH),
            .C_MEM_DATA_WIDTH(C_MEM_DATA_WIDTH),
            .C_MEM_BURST_LENGTH(C_MEM_BURST_LENGTH),
            .C_AP_PIPELINE1(C_AP_PIPELINE1),
            .C_AP_PIPELINE2(C_AP_PIPELINE2),
            .C_MEM_NUM_DIMMS(C_MEM_NUM_DIMMS),
            .C_MEM_NUM_RANKS(C_MEM_NUM_RANKS),
            .C_MEM_SUPPORTED_TOTAL_OFFSETS(C_MEM_SUPPORTED_TOTAL_OFFSETS),
            .C_MEM_SUPPORTED_DIMM_OFFSETS(C_MEM_SUPPORTED_DIMM_OFFSETS),
            .C_MEM_SUPPORTED_RANK_OFFSETS(C_MEM_SUPPORTED_RANK_OFFSETS),
            .C_MEM_SUPPORTED_BANK_OFFSETS(C_MEM_SUPPORTED_BANK_OFFSETS),
            .C_MEM_SUPPORTED_ROW_OFFSETS(C_MEM_SUPPORTED_ROW_OFFSETS),
            .C_MEM_SUPPORTED_COL_OFFSETS(C_MEM_SUPPORTED_COL_OFFSETS),
            .C_IS_DDR(C_IS_DDR),
            .C_MEM_TYPE(C_MEM_TYPE),
            .C_NCK_PER_CLK(C_NCK_PER_CLK),
            .C_ARB_PORT_ENCODING_WIDTH(C_ARB_PORT_ENCODING_WIDTH)
         )
           mpmc_addr_path_0 (
            // System Signals
            .Clk0(Clk0),                                              // I
            .Clk90(Clk90),                                            // I
            .Rst(Rst[C_NUM_PORTS*2+2]),                                                // I
            .Rst270(Rst270),                                          // I
            // Memory Signals (To/From Memory Pins)
            .AP_PhyIF_BankAddr(AP_PhyIF_BankAddr_i),                  // O [C_MEM_BANKADDR_WIDTH-1:0]
            .AP_PhyIF_Addr(AP_PhyIF_Addr_i),                          // O [C_MEM_ADDR_WIDTH-1:0]
            .AP_PhyIF_CS_n(AP_PhyIF_CS_n_i),                          // O [C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS-1:0]
            // Port Interface Signals
            .PI_Addr(PI_Addr),                                        // I [C_PI_ADDR_WIDTH*C_NUM_PORTS-1:0]
            // EEPROM Serial Presence Detect Signals
            .SPD_AP_Total_Offset(SPD_AP_Total_Offset),                // I [8*C_MEM_NUM_DIMMS-1:0]
            .SPD_AP_DIMM_Offset(SPD_AP_DIMM_Offset),                  // I [8*C_MEM_NUM_DIMMS-1:0]
            .SPD_AP_Rank_Offset(SPD_AP_Rank_Offset),                  // I [8*C_MEM_NUM_DIMMS-1:0]
            .SPD_AP_Bank_Offset(SPD_AP_Bank_Offset),                  // I [8*C_MEM_NUM_DIMMS-1:0]
            .SPD_AP_Row_Offset(SPD_AP_Row_Offset),                    // I [8*C_MEM_NUM_DIMMS-1:0]
            .SPD_AP_Col_Offset(SPD_AP_Col_Offset),                    // I [8*C_MEM_NUM_DIMMS-1:0]
            // Address Decode for Control Path
            .AP_Ctrl_Addr(AP_Ctrl_Addr),                              // O [C_PI_ADDR_WIDTH-1:0]
            // Control Signals
            .Ctrl_AP_PI_Addr_CE(Ctrl_AP_PI_Addr_CE),                  // I [C_NUM_PORTS-1:0]
            .Ctrl_AP_Port_Select(Ctrl_AP_Port_Select),                // I [C_ARB_PORT_ENCODING_WIDTH-1:0]
            .Ctrl_AP_Pipeline1_CE(Ctrl_AP_Pipeline1_CE),              // I
            .Ctrl_AP_Row_Col_Sel(Ctrl_AP_Row_Col_Sel),                // I
            .Ctrl_AP_Col_Cnt_Load(Ctrl_AP_Col_Cnt_Load),              // I
            .Ctrl_AP_Col_Cnt_Enable(Ctrl_AP_Col_Cnt_Enable),          // I
            .Ctrl_AP_Col_W(Ctrl_AP_Col_W),                            // I
            .Ctrl_AP_Col_DW(Ctrl_AP_Col_DW),                          // I
            .Ctrl_AP_Col_CL4(Ctrl_AP_Col_CL4),                        // I
            .Ctrl_AP_Col_CL8(Ctrl_AP_Col_CL8),                        // I
            .Ctrl_AP_Col_B16(Ctrl_AP_Col_B16),                        // I
            .Ctrl_AP_Col_B32(Ctrl_AP_Col_B32),                        // I
            .Ctrl_AP_Col_B64(Ctrl_AP_Col_B64),                        // I
            .Ctrl_AP_Col_Burst_Length(Ctrl_AP_Col_Burst_Length),      // I
            .Ctrl_AP_Precharge_Addr10(Ctrl_AP_Precharge_Addr10),      // I
            .Ctrl_AP_OTF_Addr12(Ctrl_AP_OTF_Addr12),                  // I
            .Ctrl_AP_Assert_All_CS(Ctrl_AP_Assert_All_CS)             // I
        ); 
  
        // Control Path
        assign Arb_Sequence = 0;
        assign Arb_LoadSequence = 0;
        mpmc_ctrl_path 
           #(
             .C_FAMILY                     (C_FAMILY),
             .C_USE_STATIC_PHY             (C_USE_STATIC_PHY),
             .C_USE_MIG_S3_PHY             (C_USE_MIG_S3_PHY),
             .C_USE_MIG_V4_PHY             (C_USE_MIG_V4_PHY),
             .C_USE_MIG_V5_PHY             (C_USE_MIG_V5_PHY),
             .C_USE_MIG_V6_PHY             (C_USE_MIG_V6_PHY),
             .C_USE_INIT_PUSH              (P_USE_INIT_PUSH),
             .C_MEM_TYPE                   (C_MEM_TYPE),
             .C_MEM_CAS_LATENCY            (C_MEM_CAS_LATENCY0),
             .C_INCLUDE_ECC_SUPPORT        (C_INCLUDE_ECC_SUPPORT),
             .C_ECC_ENCODE_PIPELINE        (C_ECC_ENCODE_PIPELINE),
             .C_MEM_DDR2_ENABLE            (C_MEM_DDR2_ENABLE),
             .C_NUM_PORTS                  (C_NUM_PORTS),
             .C_NUM_CTRL_SIGNALS           (C_NUM_CTRL_SIGNALS),
             .C_PIPELINE_ADDRACK           (C_PIPELINE_ADDRACK),
             .C_CP_PIPELINE                (C_CP_PIPELINE),
             .C_ARB_PIPELINE               (C_ARB_PIPELINE),
             .C_MAX_REQ_ALLOWED            (C_MAX_REQ_ALLOWED),
             .C_REQ_PENDING_CNTR_WIDTH     (C_REQ_PENDING_CNTR_WIDTH),
             .C_REFRESH_CNT_MAX            (C_REFRESH_CNT_MAX),
             .C_REFRESH_CNT_WIDTH          (C_REFRESH_CNT_WIDTH),
             .C_MAINT_PRESCALER_DIV        (C_MAINT_PRESCALER_DIV             ) ,
             .C_REFRESH_TIMER_DIV          (C_REFRESH_TIMER_DIV               ) ,
             .C_PERIODIC_RD_TIMER_DIV      (C_PERIODIC_RD_TIMER_DIV           ) ,
             .C_MAINT_PRESCALER_PERIOD_NS  (C_MAINT_PRESCALER_PERIOD_NS       ) ,
             .C_ZQ_TIMER_DIV               (C_ZQ_TIMER_DIV                    ) ,
             .C_MEM_REG_DIMM               (C_MEM_REG_DIMM),
             .C_IS_DDR                     (C_IS_DDR),
             .C_MEM_DATA_WIDTH             (C_MEM_DATA_WIDTH),
             .C_MEM_DM_WIDTH               (C_MEM_DM_WIDTH),
             .C_MEM_DQS_WIDTH              (C_MEM_DQS_WIDTH),
             .C_PI_DATA_WIDTH              (C_PI_DATA_WIDTH),
             .C_WR_FIFO_MEM_PIPELINE       (C_WR_FIFO_MEM_PIPELINE_SINGLE),
             .C_PORT_FOR_WRITE_TRAINING_PATTERN  (C_WR_TRAINING_PORT),
             .C_AP_PIPELINE1                 (C_AP_PIPELINE1),
             .C_NCK_PER_CLK                  (C_NCK_PER_CLK),    
             .C_CTRL_COMPLETE_INDEX          (C_CTRL_COMPLETE_INDEX),
             .C_CTRL_IS_WRITE_INDEX          (C_CTRL_IS_WRITE_INDEX),
             .C_CTRL_PHYIF_RAS_N_INDEX       (C_CTRL_PHYIF_RAS_N_INDEX),
             .C_CTRL_PHYIF_CAS_N_INDEX       (C_CTRL_PHYIF_CAS_N_INDEX),
             .C_CTRL_PHYIF_WE_N_INDEX        (C_CTRL_PHYIF_WE_N_INDEX),
             .C_CTRL_RMW_INDEX               (C_CTRL_RMW_INDEX),
             .C_CTRL_SKIP_0_INDEX            (C_CTRL_SKIP_0_INDEX),
             .C_CTRL_PHYIF_DQS_O_INDEX       (C_CTRL_PHYIF_DQS_O_INDEX),
             .C_CTRL_SKIP_1_INDEX            (C_CTRL_SKIP_1_INDEX),
             .C_CTRL_DP_RDFIFO_PUSH_INDEX    (C_CTRL_DP_RDFIFO_PUSH_INDEX),
             .C_CTRL_SKIP_2_INDEX            (C_CTRL_SKIP_2_INDEX),
             .C_CTRL_AP_COL_CNT_LOAD_INDEX   (C_CTRL_AP_COL_CNT_LOAD_INDEX),
             .C_CTRL_AP_COL_CNT_ENABLE_INDEX (C_CTRL_AP_COL_CNT_ENABLE_INDEX),
             .C_CTRL_AP_PRECHARGE_ADDR10_INDEX(C_CTRL_AP_PRECHARGE_ADDR10_INDEX),
             .C_CTRL_AP_ROW_COL_SEL_INDEX    (C_CTRL_AP_ROW_COL_SEL_INDEX),
             .C_CTRL_PHYIF_FORCE_DM_INDEX    (C_CTRL_PHYIF_FORCE_DM_INDEX),
             .C_CTRL_REPEAT4_INDEX           (C_CTRL_REPEAT4_INDEX),
             .C_CTRL_DFI_RAS_N_0_INDEX       (C_CTRL_DFI_RAS_N_0_INDEX),
             .C_CTRL_DFI_CAS_N_0_INDEX       (C_CTRL_DFI_CAS_N_0_INDEX),
             .C_CTRL_DFI_WE_N_0_INDEX        (C_CTRL_DFI_WE_N_0_INDEX),
             .C_CTRL_DFI_RAS_N_1_INDEX       (C_CTRL_DFI_RAS_N_1_INDEX),
             .C_CTRL_DFI_CAS_N_1_INDEX       (C_CTRL_DFI_CAS_N_1_INDEX),
             .C_CTRL_DFI_WE_N_1_INDEX        (C_CTRL_DFI_WE_N_1_INDEX),
             .C_CTRL_DP_WRFIFO_POP_INDEX     (C_CTRL_DP_WRFIFO_POP_INDEX),
             .C_CTRL_DFI_WRDATA_EN_INDEX     (C_CTRL_DFI_WRDATA_EN_INDEX),
             .C_CTRL_DFI_RDDATA_EN_INDEX     (C_CTRL_DFI_RDDATA_EN_INDEX),
             .C_CTRL_AP_OTF_ADDR12_INDEX     (C_CTRL_AP_OTF_ADDR12_INDEX),
             .C_BURST_LENGTH                 (C_MEM_BURST_LENGTH),
             .C_INIT0_STALL                  (C_INIT0_STALL),
             .C_INIT1_STALL                  (C_INIT1_STALL),
             .C_INIT2_STALL                  (C_INIT2_STALL),
             .C_WORD_WRITE_SEQ               (C_WORD_WRITE_SEQ),
             .C_WORD_READ_SEQ                (C_WORD_READ_SEQ),
             .C_DOUBLEWORD_WRITE_SEQ         (C_DOUBLEWORD_WRITE_SEQ),
             .C_DOUBLEWORD_READ_SEQ          (C_DOUBLEWORD_READ_SEQ),
             .C_CL4_WRITE_SEQ                (C_CL4_WRITE_SEQ),
             .C_CL4_READ_SEQ                 (C_CL4_READ_SEQ),
             .C_CL8_WRITE_SEQ                (C_CL8_WRITE_SEQ),
             .C_CL8_READ_SEQ                 (C_CL8_READ_SEQ),
             .C_B16_WRITE_SEQ                (C_B16_WRITE_SEQ),
             .C_B16_READ_SEQ                 (C_B16_READ_SEQ),
             .C_B32_WRITE_SEQ                (C_B32_WRITE_SEQ),
             .C_B32_READ_SEQ                 (C_B32_READ_SEQ),
             .C_B64_WRITE_SEQ                (C_B64_WRITE_SEQ),
             .C_B64_READ_SEQ                 (C_B64_READ_SEQ),
             .C_NOP_SEQ                      (C_NOP_SEQ),
             .C_REFH_SEQ                     (C_REFH_SEQ),
             .C_CTRL_ARB_RDMODWR_DELAY       (C_CTRL_ARB_RDMODWR_DELAY),
             .C_CTRL_AP_COL_DELAY            (C_CTRL_AP_COL_DELAY),
             .C_CTRL_AP_PI_ADDR_CE_DELAY     (C_CTRL_AP_PI_ADDR_CE_DELAY),
             .C_CTRL_AP_PORT_SELECT_DELAY    (C_CTRL_AP_PORT_SELECT_DELAY),
             .C_CTRL_AP_PIPELINE1_CE_DELAY   (C_CTRL_AP_PIPELINE1_CE_DELAY),
             .C_CTRL_DP_RDFIFO_WHICHPORT_DELAY (C_CTRL_DP_RDFIFO_WHICHPORT_DELAY),
             .C_CTRL_DP_SIZE_DELAY           (C_CTRL_DP_SIZE_DELAY),
             .C_CTRL_DP_WRFIFO_WHICHPORT_REP (C_CTRL_DP_WRFIFO_WHICHPORT_REP),
             .C_CTRL_DP_WRFIFO_WHICHPORT_DELAY (C_CTRL_DP_WRFIFO_WHICHPORT_DELAY),
             .C_CTRL_PHYIF_DUMMYREADSTART_DELAY (C_CTRL_PHYIF_DUMMYREADSTART_DELAY),
             .C_CTRL_Q0_DELAY                (C_CTRL_Q0_DELAY),
             .C_CTRL_Q1_DELAY                (C_CTRL_Q1_DELAY),
             .C_CTRL_Q2_DELAY                (C_CTRL_Q2_DELAY),
             .C_CTRL_Q3_DELAY                (C_CTRL_Q3_DELAY),
             .C_CTRL_Q4_DELAY                (C_CTRL_Q4_DELAY),
             .C_CTRL_Q5_DELAY                (C_CTRL_Q5_DELAY),
             .C_CTRL_Q6_DELAY                (C_CTRL_Q6_DELAY),
             .C_CTRL_Q7_DELAY                (C_CTRL_Q7_DELAY),
             .C_CTRL_Q8_DELAY                (C_CTRL_Q8_DELAY),
             .C_CTRL_Q9_DELAY                (C_CTRL_Q9_DELAY),
             .C_CTRL_Q10_DELAY               (C_CTRL_Q10_DELAY),
             .C_CTRL_Q11_DELAY               (C_CTRL_Q11_DELAY),
             .C_CTRL_Q12_DELAY               (C_CTRL_Q12_DELAY),
             .C_CTRL_Q13_DELAY               (C_CTRL_Q13_DELAY),
             .C_CTRL_Q14_DELAY               (C_CTRL_Q14_DELAY),
             .C_CTRL_Q15_DELAY               (C_CTRL_Q15_DELAY),
             .C_CTRL_Q16_DELAY               (C_CTRL_Q16_DELAY),
             .C_CTRL_Q17_DELAY               (C_CTRL_Q17_DELAY),
             .C_CTRL_Q18_DELAY               (C_CTRL_Q18_DELAY),
             .C_CTRL_Q19_DELAY               (C_CTRL_Q19_DELAY),
             .C_CTRL_Q20_DELAY               (C_CTRL_Q20_DELAY),
             .C_CTRL_Q21_DELAY               (C_CTRL_Q21_DELAY),
             .C_CTRL_Q22_DELAY               (C_CTRL_Q22_DELAY),
             .C_CTRL_Q23_DELAY               (C_CTRL_Q23_DELAY),
             .C_CTRL_Q24_DELAY               (C_CTRL_Q24_DELAY),
             .C_CTRL_Q25_DELAY               (C_CTRL_Q25_DELAY),
             .C_CTRL_Q26_DELAY               (C_CTRL_Q26_DELAY),
             .C_CTRL_Q27_DELAY               (C_CTRL_Q27_DELAY),
             .C_CTRL_Q28_DELAY               (C_CTRL_Q28_DELAY),
             .C_CTRL_Q29_DELAY               (C_CTRL_Q29_DELAY),
             .C_CTRL_Q30_DELAY               (C_CTRL_Q30_DELAY),
             .C_CTRL_Q31_DELAY               (C_CTRL_Q31_DELAY),
             .C_CTRL_Q32_DELAY               (C_CTRL_Q32_DELAY),
             .C_CTRL_Q33_DELAY               (C_CTRL_Q33_DELAY),
             .C_CTRL_Q34_DELAY               (C_CTRL_Q34_DELAY),
             .C_CTRL_Q35_DELAY               (C_CTRL_Q35_DELAY),
             .C_ARB0_ALGO                    (C_ARB0_ALGO),
             .C_BASEADDR_ARB0                (C_BASEADDR_ARB0),
             .C_HIGHADDR_ARB0                (C_HIGHADDR_ARB0),
             .C_BASEADDR_ARB1                (C_BASEADDR_ARB1),
             .C_HIGHADDR_ARB1                (C_HIGHADDR_ARB1),
             .C_BASEADDR_ARB2                (C_BASEADDR_ARB2),
             .C_HIGHADDR_ARB2                (C_HIGHADDR_ARB2),
             .C_BASEADDR_ARB3                (C_BASEADDR_ARB3),
             .C_HIGHADDR_ARB3                (C_HIGHADDR_ARB3),
             .C_BASEADDR_ARB4                (C_BASEADDR_ARB4),
             .C_HIGHADDR_ARB4                (C_HIGHADDR_ARB4),
             .C_BASEADDR_ARB5                (C_BASEADDR_ARB5),
             .C_HIGHADDR_ARB5                (C_HIGHADDR_ARB5),
             .C_BASEADDR_ARB6                (C_BASEADDR_ARB6),
             .C_HIGHADDR_ARB6                (C_HIGHADDR_ARB6),
             .C_BASEADDR_ARB7                (C_BASEADDR_ARB7),
             .C_HIGHADDR_ARB7                (C_HIGHADDR_ARB7),
             .C_BASEADDR_ARB8                (C_BASEADDR_ARB8),
             .C_HIGHADDR_ARB8                (C_HIGHADDR_ARB8),
             .C_BASEADDR_ARB9                (C_BASEADDR_ARB9),
             .C_HIGHADDR_ARB9                (C_HIGHADDR_ARB9),
             .C_BASEADDR_ARB10               (C_BASEADDR_ARB10),
             .C_HIGHADDR_ARB10               (C_HIGHADDR_ARB10),
             .C_BASEADDR_ARB11               (C_BASEADDR_ARB11),
             .C_HIGHADDR_ARB11               (C_HIGHADDR_ARB11),
             .C_BASEADDR_ARB12               (C_BASEADDR_ARB12),
             .C_HIGHADDR_ARB12               (C_HIGHADDR_ARB12),
             .C_BASEADDR_ARB13               (C_BASEADDR_ARB13),
             .C_HIGHADDR_ARB13               (C_HIGHADDR_ARB13),
             .C_BASEADDR_ARB14               (C_BASEADDR_ARB14),
             .C_HIGHADDR_ARB14               (C_HIGHADDR_ARB14),
             .C_BASEADDR_ARB15               (C_BASEADDR_ARB15),
             .C_HIGHADDR_ARB15               (C_HIGHADDR_ARB15),
             .C_ARB_BRAM_SRVAL_A             (C_ARB_BRAM_SRVAL_A),
             .C_ARB_BRAM_SRVAL_B             (C_ARB_BRAM_SRVAL_B),
             .C_ARB_BRAM_INIT_00             (C_ARB_BRAM_INIT_00),
             .C_ARB_BRAM_INIT_01             (C_ARB_BRAM_INIT_01),
             .C_ARB_BRAM_INIT_02             (C_ARB_BRAM_INIT_02),
             .C_ARB_BRAM_INIT_03             (C_ARB_BRAM_INIT_03),
             .C_ARB_BRAM_INIT_04             (C_ARB_BRAM_INIT_04),
             .C_ARB_BRAM_INIT_05             (C_ARB_BRAM_INIT_05),
             .C_ARB_BRAM_INIT_06             (C_ARB_BRAM_INIT_06),
             .C_ARB_BRAM_INIT_07             (C_ARB_BRAM_INIT_07),
             .C_ARB_BRAM_INIT_08             (C_ARB_BRAM_INIT_08),
             .C_ARB_BRAM_INIT_09             (C_ARB_BRAM_INIT_09),
             .C_ARB_BRAM_INIT_0A             (C_ARB_BRAM_INIT_0A),
             .C_ARB_BRAM_INIT_0B             (C_ARB_BRAM_INIT_0B),
             .C_ARB_BRAM_INIT_0C             (C_ARB_BRAM_INIT_0C),
             .C_ARB_BRAM_INIT_0D             (C_ARB_BRAM_INIT_0D),
             .C_ARB_BRAM_INIT_0E             (C_ARB_BRAM_INIT_0E),
             .C_ARB_BRAM_INIT_0F             (C_ARB_BRAM_INIT_0F),
             .C_ARB_BRAM_INIT_10             (C_ARB_BRAM_INIT_10),
             .C_ARB_BRAM_INIT_11             (C_ARB_BRAM_INIT_11),
             .C_ARB_BRAM_INIT_12             (C_ARB_BRAM_INIT_12),
             .C_ARB_BRAM_INIT_13             (C_ARB_BRAM_INIT_13),
             .C_ARB_BRAM_INIT_14             (C_ARB_BRAM_INIT_14),
             .C_ARB_BRAM_INIT_15             (C_ARB_BRAM_INIT_15),
             .C_ARB_BRAM_INIT_16             (C_ARB_BRAM_INIT_16),
             .C_ARB_BRAM_INIT_17             (C_ARB_BRAM_INIT_17),
             .C_ARB_BRAM_INIT_18             (C_ARB_BRAM_INIT_18),
             .C_ARB_BRAM_INIT_19             (C_ARB_BRAM_INIT_19),
             .C_ARB_BRAM_INIT_1A             (C_ARB_BRAM_INIT_1A),
             .C_ARB_BRAM_INIT_1B             (C_ARB_BRAM_INIT_1B),
             .C_ARB_BRAM_INIT_1C             (C_ARB_BRAM_INIT_1C),
             .C_ARB_BRAM_INIT_1D             (C_ARB_BRAM_INIT_1D),
             .C_ARB_BRAM_INIT_1E             (C_ARB_BRAM_INIT_1E),
             .C_ARB_BRAM_INIT_1F             (C_ARB_BRAM_INIT_1F),
             .C_ARB_BRAM_INIT_20             (C_ARB_BRAM_INIT_20),
             .C_ARB_BRAM_INIT_21             (C_ARB_BRAM_INIT_21),
             .C_ARB_BRAM_INIT_22             (C_ARB_BRAM_INIT_22),
             .C_ARB_BRAM_INIT_23             (C_ARB_BRAM_INIT_23),
             .C_ARB_BRAM_INIT_24             (C_ARB_BRAM_INIT_24),
             .C_ARB_BRAM_INIT_25             (C_ARB_BRAM_INIT_25),
             .C_ARB_BRAM_INIT_26             (C_ARB_BRAM_INIT_26),
             .C_ARB_BRAM_INIT_27             (C_ARB_BRAM_INIT_27),
             .C_ARB_BRAM_INIT_28             (C_ARB_BRAM_INIT_28),
             .C_ARB_BRAM_INIT_29             (C_ARB_BRAM_INIT_29),
             .C_ARB_BRAM_INIT_2A             (C_ARB_BRAM_INIT_2A),
             .C_ARB_BRAM_INIT_2B             (C_ARB_BRAM_INIT_2B),
             .C_ARB_BRAM_INIT_2C             (C_ARB_BRAM_INIT_2C),
             .C_ARB_BRAM_INIT_2D             (C_ARB_BRAM_INIT_2D),
             .C_ARB_BRAM_INIT_2E             (C_ARB_BRAM_INIT_2E),
             .C_ARB_BRAM_INIT_2F             (C_ARB_BRAM_INIT_2F),
             .C_ARB_BRAM_INIT_30             (C_ARB_BRAM_INIT_30),
             .C_ARB_BRAM_INIT_31             (C_ARB_BRAM_INIT_31),
             .C_ARB_BRAM_INIT_32             (C_ARB_BRAM_INIT_32),
             .C_ARB_BRAM_INIT_33             (C_ARB_BRAM_INIT_33),
             .C_ARB_BRAM_INIT_34             (C_ARB_BRAM_INIT_34),
             .C_ARB_BRAM_INIT_35             (C_ARB_BRAM_INIT_35),
             .C_ARB_BRAM_INIT_36             (C_ARB_BRAM_INIT_36),
             .C_ARB_BRAM_INIT_37             (C_ARB_BRAM_INIT_37),
             .C_ARB_BRAM_INIT_38             (C_ARB_BRAM_INIT_38),
             .C_ARB_BRAM_INIT_39             (C_ARB_BRAM_INIT_39),
             .C_ARB_BRAM_INIT_3A             (C_ARB_BRAM_INIT_3A),
             .C_ARB_BRAM_INIT_3B             (C_ARB_BRAM_INIT_3B),
             .C_ARB_BRAM_INIT_3C             (C_ARB_BRAM_INIT_3C),
             .C_ARB_BRAM_INIT_3D             (C_ARB_BRAM_INIT_3D),
             .C_ARB_BRAM_INIT_3E             (C_ARB_BRAM_INIT_3E),
             .C_ARB_BRAM_INIT_3F             (C_ARB_BRAM_INIT_3F),
             .C_ARB_BRAM_INITP_00            (C_ARB_BRAM_INITP_00),
             .C_ARB_BRAM_INITP_01            (C_ARB_BRAM_INITP_01),
             .C_ARB_BRAM_INITP_02            (C_ARB_BRAM_INITP_02),
             .C_ARB_BRAM_INITP_03            (C_ARB_BRAM_INITP_03),
             .C_ARB_BRAM_INITP_04            (C_ARB_BRAM_INITP_04),
             .C_ARB_BRAM_INITP_05            (C_ARB_BRAM_INITP_05),
             .C_ARB_BRAM_INITP_06            (C_ARB_BRAM_INITP_06),
             .C_ARB_BRAM_INITP_07            (C_ARB_BRAM_INITP_07),
             .C_USE_FIXED_BASEADDR_CTRL      (C_USE_FIXED_BASEADDR_CTRL),
             .C_B16_REPEAT_CNT               (C_B16_REPEAT_CNT),
             .C_B32_REPEAT_CNT               (C_B32_REPEAT_CNT),
             .C_B64_REPEAT_CNT               (C_B64_REPEAT_CNT),
             .C_ZQCS_REPEAT_CNT              (C_ZQCS_REPEAT_CNT),
             .C_BASEADDR_CTRL0               (C_BASEADDR_CTRL0),
             .C_HIGHADDR_CTRL0               (C_HIGHADDR_CTRL0),
             .C_BASEADDR_CTRL1               (C_BASEADDR_CTRL1),
             .C_HIGHADDR_CTRL1               (C_HIGHADDR_CTRL1),
             .C_BASEADDR_CTRL2               (C_BASEADDR_CTRL2),
             .C_HIGHADDR_CTRL2               (C_HIGHADDR_CTRL2),
             .C_BASEADDR_CTRL3               (C_BASEADDR_CTRL3),
             .C_HIGHADDR_CTRL3               (C_HIGHADDR_CTRL3),
             .C_BASEADDR_CTRL4               (C_BASEADDR_CTRL4),
             .C_HIGHADDR_CTRL4               (C_HIGHADDR_CTRL4),
             .C_BASEADDR_CTRL5               (C_BASEADDR_CTRL5),
             .C_HIGHADDR_CTRL5               (C_HIGHADDR_CTRL5),
             .C_BASEADDR_CTRL6               (C_BASEADDR_CTRL6),
             .C_HIGHADDR_CTRL6               (C_HIGHADDR_CTRL6),
             .C_BASEADDR_CTRL7               (C_BASEADDR_CTRL7),
             .C_HIGHADDR_CTRL7               (C_HIGHADDR_CTRL7),
             .C_BASEADDR_CTRL8               (C_BASEADDR_CTRL8),
             .C_HIGHADDR_CTRL8               (C_HIGHADDR_CTRL8),
             .C_BASEADDR_CTRL9               (C_BASEADDR_CTRL9),
             .C_HIGHADDR_CTRL9               (C_HIGHADDR_CTRL9),
             .C_BASEADDR_CTRL10              (C_BASEADDR_CTRL10),
             .C_HIGHADDR_CTRL10              (C_HIGHADDR_CTRL10),
             .C_BASEADDR_CTRL11              (C_BASEADDR_CTRL11),
             .C_HIGHADDR_CTRL11              (C_HIGHADDR_CTRL11),
             .C_BASEADDR_CTRL12              (C_BASEADDR_CTRL12),
             .C_HIGHADDR_CTRL12              (C_HIGHADDR_CTRL12),
             .C_BASEADDR_CTRL13              (C_BASEADDR_CTRL13),
             .C_HIGHADDR_CTRL13              (C_HIGHADDR_CTRL13),
             .C_BASEADDR_CTRL14              (C_BASEADDR_CTRL14),
             .C_HIGHADDR_CTRL14              (C_HIGHADDR_CTRL14),
             .C_BASEADDR_CTRL15              (C_BASEADDR_CTRL15),
             .C_HIGHADDR_CTRL15              (C_HIGHADDR_CTRL15),
             .C_BASEADDR_CTRL16              (C_BASEADDR_CTRL16),
             .C_HIGHADDR_CTRL16              (C_HIGHADDR_CTRL16),
             .C_CTRL_BRAM_SRVAL            (C_CTRL_BRAM_SRVAL),
             .C_CTRL_BRAM_INIT_00          (C_CTRL_BRAM_INIT_00),
             .C_CTRL_BRAM_INIT_01          (C_CTRL_BRAM_INIT_01),
             .C_CTRL_BRAM_INIT_02          (C_CTRL_BRAM_INIT_02),
             .C_CTRL_BRAM_INIT_03          (C_CTRL_BRAM_INIT_03),
             .C_CTRL_BRAM_INIT_04          (C_CTRL_BRAM_INIT_04),
             .C_CTRL_BRAM_INIT_05          (C_CTRL_BRAM_INIT_05),
             .C_CTRL_BRAM_INIT_06          (C_CTRL_BRAM_INIT_06),
             .C_CTRL_BRAM_INIT_07          (C_CTRL_BRAM_INIT_07),
             .C_CTRL_BRAM_INIT_08          (C_CTRL_BRAM_INIT_08),
             .C_CTRL_BRAM_INIT_09          (C_CTRL_BRAM_INIT_09),
             .C_CTRL_BRAM_INIT_0A          (C_CTRL_BRAM_INIT_0A),
             .C_CTRL_BRAM_INIT_0B          (C_CTRL_BRAM_INIT_0B),
             .C_CTRL_BRAM_INIT_0C          (C_CTRL_BRAM_INIT_0C),
             .C_CTRL_BRAM_INIT_0D          (C_CTRL_BRAM_INIT_0D),
             .C_CTRL_BRAM_INIT_0E          (C_CTRL_BRAM_INIT_0E),
             .C_CTRL_BRAM_INIT_0F          (C_CTRL_BRAM_INIT_0F),
             .C_CTRL_BRAM_INIT_10          (C_CTRL_BRAM_INIT_10),
             .C_CTRL_BRAM_INIT_11          (C_CTRL_BRAM_INIT_11),
             .C_CTRL_BRAM_INIT_12          (C_CTRL_BRAM_INIT_12),
             .C_CTRL_BRAM_INIT_13          (C_CTRL_BRAM_INIT_13),
             .C_CTRL_BRAM_INIT_14          (C_CTRL_BRAM_INIT_14),
             .C_CTRL_BRAM_INIT_15          (C_CTRL_BRAM_INIT_15),
             .C_CTRL_BRAM_INIT_16          (C_CTRL_BRAM_INIT_16),
             .C_CTRL_BRAM_INIT_17          (C_CTRL_BRAM_INIT_17),
             .C_CTRL_BRAM_INIT_18          (C_CTRL_BRAM_INIT_18),
             .C_CTRL_BRAM_INIT_19          (C_CTRL_BRAM_INIT_19),
             .C_CTRL_BRAM_INIT_1A          (C_CTRL_BRAM_INIT_1A),
             .C_CTRL_BRAM_INIT_1B          (C_CTRL_BRAM_INIT_1B),
             .C_CTRL_BRAM_INIT_1C          (C_CTRL_BRAM_INIT_1C),
             .C_CTRL_BRAM_INIT_1D          (C_CTRL_BRAM_INIT_1D),
             .C_CTRL_BRAM_INIT_1E          (C_CTRL_BRAM_INIT_1E),
             .C_CTRL_BRAM_INIT_1F          (C_CTRL_BRAM_INIT_1F),
             .C_CTRL_BRAM_INIT_20          (C_CTRL_BRAM_INIT_20),
             .C_CTRL_BRAM_INIT_21          (C_CTRL_BRAM_INIT_21),
             .C_CTRL_BRAM_INIT_22          (C_CTRL_BRAM_INIT_22),
             .C_CTRL_BRAM_INIT_23          (C_CTRL_BRAM_INIT_23),
             .C_CTRL_BRAM_INIT_24          (C_CTRL_BRAM_INIT_24),
             .C_CTRL_BRAM_INIT_25          (C_CTRL_BRAM_INIT_25),
             .C_CTRL_BRAM_INIT_26          (C_CTRL_BRAM_INIT_26),
             .C_CTRL_BRAM_INIT_27          (C_CTRL_BRAM_INIT_27),
             .C_CTRL_BRAM_INIT_28          (C_CTRL_BRAM_INIT_28),
             .C_CTRL_BRAM_INIT_29          (C_CTRL_BRAM_INIT_29),
             .C_CTRL_BRAM_INIT_2A          (C_CTRL_BRAM_INIT_2A),
             .C_CTRL_BRAM_INIT_2B          (C_CTRL_BRAM_INIT_2B),
             .C_CTRL_BRAM_INIT_2C          (C_CTRL_BRAM_INIT_2C),
             .C_CTRL_BRAM_INIT_2D          (C_CTRL_BRAM_INIT_2D),
             .C_CTRL_BRAM_INIT_2E          (C_CTRL_BRAM_INIT_2E),
             .C_CTRL_BRAM_INIT_2F          (C_CTRL_BRAM_INIT_2F),
             .C_CTRL_BRAM_INIT_30          (C_CTRL_BRAM_INIT_30),
             .C_CTRL_BRAM_INIT_31          (C_CTRL_BRAM_INIT_31),
             .C_CTRL_BRAM_INIT_32          (C_CTRL_BRAM_INIT_32),
             .C_CTRL_BRAM_INIT_33          (C_CTRL_BRAM_INIT_33),
             .C_CTRL_BRAM_INIT_34          (C_CTRL_BRAM_INIT_34),
             .C_CTRL_BRAM_INIT_35          (C_CTRL_BRAM_INIT_35),
             .C_CTRL_BRAM_INIT_36          (C_CTRL_BRAM_INIT_36),
             .C_CTRL_BRAM_INIT_37          (C_CTRL_BRAM_INIT_37),
             .C_CTRL_BRAM_INIT_38          (C_CTRL_BRAM_INIT_38),
             .C_CTRL_BRAM_INIT_39          (C_CTRL_BRAM_INIT_39),
             .C_CTRL_BRAM_INIT_3A          (C_CTRL_BRAM_INIT_3A),
             .C_CTRL_BRAM_INIT_3B          (C_CTRL_BRAM_INIT_3B),
             .C_CTRL_BRAM_INIT_3C          (C_CTRL_BRAM_INIT_3C),
             .C_CTRL_BRAM_INIT_3D          (C_CTRL_BRAM_INIT_3D),
             .C_CTRL_BRAM_INIT_3E          (C_CTRL_BRAM_INIT_3E),
             .C_CTRL_BRAM_INIT_3F          (C_CTRL_BRAM_INIT_3F),
             .C_CTRL_BRAM_INITP_00         (C_CTRL_BRAM_INITP_00),
             .C_CTRL_BRAM_INITP_01         (C_CTRL_BRAM_INITP_01),
             .C_CTRL_BRAM_INITP_02         (C_CTRL_BRAM_INITP_02),
             .C_CTRL_BRAM_INITP_03         (C_CTRL_BRAM_INITP_03),
             .C_CTRL_BRAM_INITP_04         (C_CTRL_BRAM_INITP_04),
             .C_CTRL_BRAM_INITP_05         (C_CTRL_BRAM_INITP_05),
             .C_CTRL_BRAM_INITP_06         (C_CTRL_BRAM_INITP_06),
             .C_CTRL_BRAM_INITP_07         (C_CTRL_BRAM_INITP_07),
             .C_SKIP_1_VALUE               (C_SKIP_1_VALUE),
             .C_SKIP_2_VALUE               (C_SKIP_2_VALUE),
             .C_SKIP_3_VALUE               (C_SKIP_3_VALUE),
             .C_SKIP_4_VALUE               (C_SKIP_4_VALUE),
             .C_SKIP_5_VALUE               (C_SKIP_5_VALUE),
             .C_SKIP_6_VALUE               (C_SKIP_6_VALUE),
             .C_SKIP_7_VALUE               (C_SKIP_7_VALUE),
             .C_ARB_SEQUENCE_ENCODING_WIDTH(C_ARB_SEQUENCE_ENCODING_WIDTH),
             .C_ARB_PORT_ENCODING_WIDTH    (C_ARB_PORT_ENCODING_WIDTH),
             .C_MEM_DM_WIDTH_INT           (C_MEM_DM_WIDTH_INT),
             .C_MEM_PHASE_DETECT           (P_PHASE_DETECT),
             .C_MEM_ODT_TYPE               (C_MEM_ODT_TYPE)
         )
           mpmc_ctrl_path_0 
             (
              .Clk                       (Clk0),
              .Clk90                     (Clk90),
              .Rst                       (Rst[C_NUM_PORTS*2+3]),
              .PI_AddrReq                (PI_AddrReq),
              .PI_Size                   (PI_Size),
              .PI_RNW                    (PI_RNW),
              .PI_RdModWr                (PI_RdModWr),
              .PI_AddrAck                (PI_AddrAck),
              .AP_Ctrl_Addr              (AP_Ctrl_Addr),                // I [31:0]
              .Ctrl_ECC_RdFIFO_Size      (Ctrl_ECC_RdFIFO_Size_i),      // O [3:0]
              .Ctrl_ECC_RdFIFO_RNW       (Ctrl_ECC_RdFIFO_RNW_i),       // O
              .Ctrl_ECC_RdFIFO_Addr      (Ctrl_ECC_RdFIFO_Addr),        // O [31:0]
              .Ctrl_AP_Col_W             (Ctrl_AP_Col_W),               // O
              .Ctrl_AP_Col_DW            (Ctrl_AP_Col_DW),              // O
              .Ctrl_AP_Col_CL4           (Ctrl_AP_Col_CL4),             // O
              .Ctrl_AP_Col_CL8           (Ctrl_AP_Col_CL8),             // O
              .Ctrl_AP_Col_B16           (Ctrl_AP_Col_B16),             // O
              .Ctrl_AP_Col_B32           (Ctrl_AP_Col_B32),             // O
              .Ctrl_AP_Col_B64           (Ctrl_AP_Col_B64),             // O
              .Ctrl_AP_Col_Burst_Length  (Ctrl_AP_Col_Burst_Length),    // O
              .Ctrl_AP_PI_Addr_CE        (Ctrl_AP_PI_Addr_CE),          // O [C_NUM_PORTS-1:0]
              .Ctrl_AP_Port_Select       (Ctrl_AP_Port_Select),         // O [C_ARB_PORT_ENCODING_WIDTH-1:0]
              .Ctrl_AP_Col_Cnt_Load      (Ctrl_AP_Col_Cnt_Load),        // O
              .Ctrl_AP_Col_Cnt_Enable    (Ctrl_AP_Col_Cnt_Enable),      // O
              .Ctrl_AP_Precharge_Addr10  (Ctrl_AP_Precharge_Addr10),    // O
              .Ctrl_AP_OTF_Addr12        (Ctrl_AP_OTF_Addr12),          // O
              .Ctrl_AP_Row_Col_Sel       (Ctrl_AP_Row_Col_Sel),         // O
              .Ctrl_AP_Pipeline1_CE      (Ctrl_AP_Pipeline1_CE),        // O
              .Ctrl_AP_Assert_All_CS     (Ctrl_AP_Assert_All_CS),       // O
              .DP_Ctrl_RdFIFO_AlmostFull (DP_Ctrl_RdFIFO_AlmostFull),   // I [C_NUM_PORTS-1:0]
              .Ctrl_DP_RdFIFO_WhichPort_Decode  (Ctrl_DP_RdFIFO_WhichPort_Decode),    // O [C_ARB_PORT_ENCODING_WIDTH-1:0]
              .Ctrl_DP_WrFIFO_WhichPort  (Ctrl_DP_WrFIFO_WhichPort),    // O [C_ARB_PORT_ENCODING_WIDTH-1:0]
              .Ctrl_DP_WrFIFO_WhichPort_Decode (Ctrl_DP_WrFIFO_WhichPort_Decode), // O [C_NUM_PORTS-1:0]
              .Ctrl_DP_RdFIFO_Push       (Ctrl_DP_RdFIFO_Push),    // O
              .Ctrl_DP_WrFIFO_Pop        (ctrl_dp_wrfifo_pop),      // O
              .PhyIF_Ctrl_InitDone       (PhyIF_Ctrl_InitDone[18]),// I
              .Ctrl_Periodic_Rd_Mask     (Ctrl_Periodic_Rd_Mask),          // O
              .Ctrl_PhyIF_RAS_n          (Ctrl_PhyIF_RAS_n_i),          // O
              .Ctrl_PhyIF_CAS_n          (Ctrl_PhyIF_CAS_n_i),          // O
              .Ctrl_PhyIF_WE_n           (Ctrl_PhyIF_WE_n_i),           // O
              .Ctrl_Is_Write             (Ctrl_Is_Write),               // O
              .Ctrl_RMW                  (Ctrl_RMW),                    // O
              .Ctrl_PhyIF_DQS_O          (Ctrl_PhyIF_DQS_O),            // O
              .Ctrl_PhyIF_Force_DM       (Ctrl_PhyIF_Force_DM),         // O
              .Ctrl_Refresh_Flag         (Ctrl_Refresh_Flag),           // O
              .Arb_Sequence              (Arb_Sequence),
              .Arb_LoadSequence          (Arb_LoadSequence),
              .Arb_PatternStart          (Arb_PatternStart),
              .Ctrl_DFI_RAS_n            (ctrl_dfi_ras_n),
              .Ctrl_DFI_CAS_n            (ctrl_dfi_cas_n),
              .Ctrl_DFI_WE_n             (ctrl_dfi_we_n),
              .Ctrl_DFI_ODT              (ctrl_dfi_odt),
              .Ctrl_DFI_CE               (ctrl_dfi_ce),
              .Ctrl_DFI_WrData_En        (ctrl_dfi_wrdata_en),
              .Ctrl_DFI_RdData_En        (ctrl_dfi_rddata_en)
              );
  
     
        if (P_DELAY_PHYIF_DP_WRFIFO_POP == 1) begin : gen_reg_PhyIF_DP_WrFIFO_Pop
           always @(posedge Clk0) begin
              PhyIF_DP_WrFIFO_Pop_i    <= PhyIF_DP_WrFIFO_Pop;
              Ctrl_PhyIF_Force_DM_d1_i <= Ctrl_PhyIF_Force_DM_d1;
           end
        end
        else begin : gen_noreg_PhyIF_DP_WrFIFO_Pop
           always @(*) begin
              PhyIF_DP_WrFIFO_Pop_i    <= PhyIF_DP_WrFIFO_Pop;
              Ctrl_PhyIF_Force_DM_d1_i <= Ctrl_PhyIF_Force_DM_d1;
           end
        end
     
     
        always @(posedge Clk0)
          Ctrl_PhyIF_Force_DM_d1 <= {C_NUM_PORTS{Ctrl_PhyIF_Force_DM[0]}};
      
        wire [C_NUM_PORTS-1:0] PhyIF_Ctrl_InitDone_DP;
         
        if (C_USE_MIG_S3_PHY == 1 || (C_USE_STATIC_PHY==1) || (C_IS_DDR==0)) begin : gen_phyif_ctrl_initdone_dp_spartan
           assign PhyIF_Ctrl_InitDone_DP = {C_NUM_PORTS{1'b1}};
        end
        else begin  : gen_phyif_ctrl_initdone_dp_nonspartan
           assign PhyIF_Ctrl_InitDone_DP = PhyIF_Ctrl_InitDone[C_NUM_PORTS+9:10];
        end
     
        // SPECIAL CASE: See data_path.v
        // IF TML Pipeline enabled, and ECC enabled, cannot assert pop
        // early enough, so eliminate TML Pipeline inside of data path code.
        // mpmc_core will need to assume that TML Pipeline is set when calculating
        // when to pop data.
      
        assign Clk_WrFIFO_TML = (C_USE_MIG_S3_PHY == 1 && C_INCLUDE_ECC_SUPPORT == 0) 
                                ? ~Clk90 : 
                                (C_USE_MIG_V6_PHY == 1) ? Clk0 : ~Clk0;
     
        mpmc_data_path #
           (
            .C_FAMILY                          (C_FAMILY),
            .C_USE_INIT_PUSH                   (P_USE_INIT_PUSH),
            .C_PI_WRFIFO_TYPE                  (C_PI_WR_FIFO_TYPE),
            .C_WRFIFO_TML_PIPELINE             (C_WR_DATAPATH_TML_PIPELINE),
            .C_WRFIFO_PI_PIPELINE              (C_WR_FIFO_APP_PIPELINE),
            .C_WRFIFO_MEM_PIPELINE             (C_WR_FIFO_MEM_PIPELINE),
            .C_PI_RDFIFO_TYPE                  (C_PI_RD_FIFO_TYPE),
            .C_RDFIFO_MAX_FANOUT               (C_RD_DATAPATH_TML_MAX_FANOUT),
            .C_RDFIFO_PI_PIPELINE              (C_RD_FIFO_APP_PIPELINE),
            .C_RDFIFO_MEM_PIPELINE             (C_RD_FIFO_MEM_PIPELINE),
            .C_NUM_PORTS                       (C_NUM_PORTS),
            .C_IS_DDR                          (C_IS_DDR),
            .C_MEM_DATA_WIDTH                  (C_MEM_DATA_WIDTH_INT),
            .C_PI_ADDR_WIDTH                   (C_PIX_ADDR_WIDTH_MAX),
            .C_PI_DATA_WIDTH                   (C_PI_DATA_WIDTH),
            .C_PIX_DATA_WIDTH_MAX              (C_PIX_DATA_WIDTH_MAX),
            .C_INCLUDE_ECC_SUPPORT             (C_INCLUDE_ECC_SUPPORT),
            .C_CTRL_DP_WRFIFO_WHICHPORT_REP    (C_CTRL_DP_WRFIFO_WHICHPORT_REP),
            .C_PORT_FOR_WRITE_TRAINING_PATTERN (C_WR_TRAINING_PORT),
            .C_ARB_PORT_ENCODING_WIDTH         (C_ARB_PORT_ENCODING_WIDTH)

            )
           mpmc_data_path_0
             (
              .Clk                             (Clk0),
              .Clk_WrFIFO_TML                  (Clk_WrFIFO_TML),
              .Rst                             (Rst[C_NUM_PORTS*2-1:0]),
              .PI_AddrAck                      (PI_AddrAck),
              .PI_RNW                          (PI_RNW),
              .PI_Size                         (PI_Size),
              .PI_Addr                         (PI_Addr),
              .PI_RdFIFO_Flush                 (PI_RdFIFO_Flush),
              .Ctrl_DP_RdFIFO_Push             (PhyIF_DP_RdFIFO_Push),
              .Ctrl_DP_RdFIFO_WhichPort_Decode (Ctrl_DP_RdFIFO_WhichPort_Decode_i),
              .PI_RdFIFO_Pop                   (PI_RdFIFO_Pop),
              .PI_RdFIFO_Empty                 (PI_RdFIFO_Empty),
              .DP_Ctrl_RdFIFO_AlmostFull       (DP_Ctrl_RdFIFO_AlmostFull),
              .PhyIF_DP_DQ_I                   (PhyIF_DP_DQ_I),
              .PI_RdFIFO_Data                  (PI_RdFIFO_Data),
              .PI_RdFIFO_RdWdAddr              (PI_RdFIFO_RdWdAddr),
              .InitPush                        (PhyIF_Init_Push),
              .InitData                        (PhyIF_Init_Data),
              .PI_WrFIFO_Flush                 (PI_WrFIFO_Flush),
              .PI_WrFIFO_Push                  (PI_WrFIFO_Push),
              .Ctrl_PhyIF_Force_DM             (Ctrl_PhyIF_Force_DM_d1_i),
              .Ctrl_DP_WrFIFO_Pop              (PhyIF_DP_WrFIFO_Pop_i),
              .Ctrl_DP_WrFIFO_WhichPort        (Ctrl_DP_WrFIFO_WhichPort),
              .Ctrl_DP_WrFIFO_WhichPort_Decode (Ctrl_DP_WrFIFO_WhichPort_Decode),
              .PhyIF_Ctrl_InitDone             (PhyIF_Ctrl_InitDone_DP),
              .DP_Ctrl_WrFIFO_Empty            (DP_Ctrl_WrFIFO_Empty),
              .PI_WrFIFO_AlmostFull            (PI_WrFIFO_AlmostFull),
              .PI_WrFIFO_Data                  (PI_WrFIFO_Data),
              .PI_WrFIFO_BE                    (PI_WrFIFO_BE),
              .DP_PhyIF_DQ_O                   (DP_PhyIF_DQ_O),
              .DP_PhyIF_BE_O                   (DP_PhyIF_BE_O)
              );
     
    end
  endgenerate
   
endmodule // mpmc_core

`default_nettype wire
